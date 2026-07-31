import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:biblebookapp/Model/product_details_model.dart' as m;
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Model/get_audio_model.dart';
import '../../core/notifiers/download.notifier.dart';

// final List<PurchaseDetails> _purchases = [];

class SubscriptionScreen extends StatefulWidget {
  final String sixMonthPlan;
  final String oneYearPlan;
  final String lifeTimePlan;
  final String checkad;
  final bool fromHomeExitOffer;

  /// When set after products load, selects 0=six month, 1=one year, 2=lifetime.
  /// Used by milestone Lifetime flows only; default keeps existing behavior.
  final int? initialSelectedPlanIndex;

  /// When true, triggers the same existing purchase flow automatically
  /// after products are ready (used by milestone screens).
  final bool autoStartSelectedPlanPurchase;

  /// Transparent host: runs IAP (e.g. milestone Unlock) without showing paywall UI.
  final bool invisiblePurchaseHost;

  const SubscriptionScreen({
    super.key,
    required this.sixMonthPlan,
    required this.oneYearPlan,
    required this.lifeTimePlan,
    required this.checkad,
    this.fromHomeExitOffer = false,
    this.initialSelectedPlanIndex,
    this.autoStartSelectedPlanPurchase = false,
    this.invisiblePurchaseHost = false,
  });

  /// iOS-style slide used for paywall push/pop so back matches forward.
  static const Transition paywallRouteTransition = Transition.cupertino;
  static const Duration paywallRouteDuration = Duration(milliseconds: 350);

  /// Additive: dashboard IAP flag (`is_subscription_enabled` → prefs/controller).
  /// Defaults to enabled when unset so first-launch before API is unchanged.
  static Future<bool> isDashboardIapEnabled() async {
    bool? fromController;
    if (Get.isRegistered<DashBoardController>()) {
      fromController = Get.find<DashBoardController>().isSubscriptionEnabled;
    }
    final fromPrefs =
        await SharPreferences.getBoolean('isSubscriptionEnabled');
    if (fromController == false || fromPrefs == false) return false;
    return true;
  }

  /// Opens paywall on top of the current screen with a smooth slide transition.
  static Future<T?> openPaywallStacked<T>({
    required String sixMonthPlan,
    required String oneYearPlan,
    required String lifeTimePlan,
    required String checkad,
    bool fromHomeExitOffer = false,
  }) async {
    if (!await isDashboardIapEnabled()) {
      debugPrint(
          'SubscriptionScreen: dashboard IAP disabled — skip openPaywallStacked');
      return null;
    }
    return Get.to<T>(
      () => SubscriptionScreen(
        sixMonthPlan: sixMonthPlan,
        oneYearPlan: oneYearPlan,
        lifeTimePlan: lifeTimePlan,
        checkad: checkad,
        fromHomeExitOffer: fromHomeExitOffer,
      ),
      transition: paywallRouteTransition,
      duration: paywallRouteDuration,
    );
  }

  /// Navigate to paywall from home (direct, no exit offer).
  static Future<void> navigateToPaywallFromHome(BuildContext context) async {
    if (!await isDashboardIapEnabled()) {
      debugPrint(
          'SubscriptionScreen: dashboard IAP disabled — skip navigateToPaywallFromHome');
      return;
    }
    final sixMonthPlan = AppApiConstant.resolveSubscriptionProductId(
      await SharPreferences.getString('sixMonthPlan'),
      BibleInfo.sixMonthPlanid,
    );
    final oneYearPlan = AppApiConstant.resolveSubscriptionProductId(
      await SharPreferences.getString('oneYearPlan'),
      BibleInfo.oneYearPlanid,
    );
    final lifeTimePlan = AppApiConstant.resolveSubscriptionProductId(
      await SharPreferences.getString('lifeTimePlan'),
      BibleInfo.lifeTimePlanid,
    );
    await openPaywallStacked(
      sixMonthPlan: sixMonthPlan,
      oneYearPlan: oneYearPlan,
      lifeTimePlan: lifeTimePlan,
      checkad: 'home',
    );
  }

  /// Public entry point to show the exit offer from Home.
  /// Forwards to the state helper while keeping existing logic intact.
  static Future<void> showExitOfferFromHomeScreen(
      BuildContext context, DashBoardController controller) {
    return _SubscriptionScreenState.showExitOfferFromHomeScreen(
        context, controller);
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isPurchaseLoading = false;
//  bool isRestoreLoading = false;
  bool userTap = false;
  int selectedindex = 0;
  List<ProductDetails> _products = [];
  ProductDetails? _exitOfferProduct; // Store exit offer product for purchase
  bool _isExitOfferShowing =
      false; // Track if exit offer is currently being shown
  bool _shouldShowRestoreDialog =
      false; // Track if restore dialog should be shown
  String? _pendingRestoreProductId; // Store product ID for pending restore
  Timer? _loadingTimeoutTimer; // Timer for 6-second loading timeout
  bool _autoPurchaseTriggered = false;
  Set<String> _lastQueriedProductIds = {};
  Set<String> _lastStoreNotFoundIds = {};
  /// Additive: highest restore tier applied in the current Restore session
  /// (3=lifetime, 2=1Y/2Y, 1=6M). Prevents last-write-wins downgrades.
  int _highestRestoredTierApplied = 0;
  /// Additive: most recent restore transaction chosen in this Restore session.
  DateTime? _bestRestoreTransactionAt;
  String? _bestRestoreProductId;
  /// Additive: while true, StoreKit restored products are collected and applied once.
  bool _restoreCollecting = false;
  final List<Map<String, String>> _restoreCollectedProducts = [];
  /// Additive: when applying the one chosen Restore product, ignore prior stored
  /// plan tier (e.g. stale platinum) so the collected best can overwrite it.
  bool _forceApplyCollectedRestoreBest = false;

  /// Bundle prefix shared by 6M/1Y plans (e.g. com.balaklrapps.bibliasagradacatolica).
  String get _planBundlePrefix {
    for (final planId in [_resolvedSixMonthPlanId, _resolvedOneYearPlanId]) {
      final dotIndex = planId.lastIndexOf('.');
      if (dotIndex > 0) {
        return planId.substring(0, dotIndex);
      }
    }
    return BibleInfo.ios_Bundle_Id;
  }

  /// 2Y ID uses the same bundle prefix as 6M/1Y (not a hardcoded Geneva id).
  String get _twoYearPlanId => '$_planBundlePrefix.twoyearadsfree';

  String get _resolvedSixMonthPlanId => AppApiConstant.resolveSubscriptionProductId(
        widget.sixMonthPlan,
        BibleInfo.sixMonthPlanid,
      );

  String get _resolvedOneYearPlanId => AppApiConstant.resolveSubscriptionProductId(
        widget.oneYearPlan,
        BibleInfo.oneYearPlanid,
      );

  String get _resolvedLifeTimePlanId => AppApiConstant.resolveSubscriptionProductId(
        widget.lifeTimePlan,
        BibleInfo.lifeTimePlanid,
      );

  List<String> get _expectedPaywallPlanIds => [
        _resolvedSixMonthPlanId,
        _resolvedOneYearPlanId,
        _resolvedLifeTimePlanId,
      ];

  Set<String> get _paywallQueryProductIds =>
      AppApiConstant.paywallStoreQueryIds(
        sixMonthPlan: _resolvedSixMonthPlanId,
        oneYearPlan: _resolvedOneYearPlanId,
        twoYearPlan: _twoYearPlanId,
        lifeTimePlan: _resolvedLifeTimePlanId,
      );

  bool _isPaywallProductForThisApp(String productId) =>
      productId.startsWith('$_planBundlePrefix.');

  bool _cacheHasPaywallSlot(Iterable<String> productIds, String slot) =>
      productIds.any((id) => id.contains(slot));

  bool _isSixMonthProductId(String productId) =>
      productId == _resolvedSixMonthPlanId ||
      productId == widget.sixMonthPlan ||
      (productId.contains('sixmonth') && _isPaywallProductForThisApp(productId));

  bool _isOneYearProductId(String productId) =>
      productId == _resolvedOneYearPlanId ||
      productId == widget.oneYearPlan ||
      (productId.contains('oneyear') && _isPaywallProductForThisApp(productId));

  bool _isTwoYearProductId(String productId) =>
      productId == _twoYearPlanId ||
      productId == '$_planBundlePrefix.twoyearadfree' ||
      (productId.contains('twoyear') && _isPaywallProductForThisApp(productId));

  bool _isLifetimeProductId(String productId) =>
      productId == _resolvedLifeTimePlanId ||
      productId == widget.lifeTimePlan ||
      (productId.contains('lifetime') && _isPaywallProductForThisApp(productId));

  /// Additive: restore plan rank so a later 6M restore cannot overwrite Lifetime/1Y.
  /// Higher = better. Unknown products = 0 (do not block existing branches).
  int _restoreProductTier(String productId) {
    final id = productId.toString();
    final isExitOfferLifetime =
        id.toLowerCase().contains('lifetime.exitoffer') ||
            id.toLowerCase().contains('exitoffer');
    if (_isLifetimeProductId(id) || isExitOfferLifetime) return 3;
    if (_isTwoYearProductId(id) || _isOneYearProductId(id)) return 2;
    if (_isSixMonthProductId(id)) return 1;
    return 0;
  }

  int _storedSubscriptionPlanTier(String? plan) {
    switch ((plan ?? '').toLowerCase()) {
      case 'platinum':
        return 3;
      case 'gold':
        return 2;
      case 'silver':
        return 1;
      default:
        return 0;
    }
  }

  /// Additive: StoreKit `transactionDate` is often epoch ms/seconds, not ISO-8601.
  /// Without this, all dates look "missing" and Lifetime wins by tier alone.
  DateTime? _parseRestoreTransactionDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final numeric = int.tryParse(trimmed);
    if (numeric == null) return null;
    // Milliseconds since epoch (typical StoreKit / IAP plugin value).
    if (numeric > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    // Seconds since epoch.
    if (numeric > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
    }
    return null;
  }

  /// Additive: true when applying [productId] would downgrade an already-restored higher plan.
  /// Also prefers a newer transaction over an older higher-tier one (e.g. old Lifetime
  /// must not replace a newer 6M/1Y purchase after reinstall Restore).
  Future<bool> _shouldSkipRestoreDowngrade(
    String productId,
    DownloadProvider? downloadProvider, {
    String? transactionDate,
  }) async {
    // Additive: single best product from Restore collection must apply even if
    // prefs still hold a stale higher plan from a previous bad restore.
    if (_forceApplyCollectedRestoreBest) return false;

    final incomingTier = _restoreProductTier(productId);
    if (incomingTier <= 0) return false;

    final incomingDate = _parseRestoreTransactionDate(transactionDate);
    // Additive: a dated restore always beats an undated prior claim (epoch dates
    // used to fail ISO parse, so Lifetime claimed with null date first).
    if (incomingDate != null && _bestRestoreTransactionAt == null) {
      return false;
    }
    if (incomingDate != null && _bestRestoreTransactionAt != null) {
      if (incomingDate.isBefore(_bestRestoreTransactionAt!)) {
        debugPrint(
          'Restore: skip older transaction $productId '
          '($incomingDate < $_bestRestoreTransactionAt)',
        );
        return true;
      }
      if (incomingDate.isAfter(_bestRestoreTransactionAt!)) {
        // Newer purchase/restore wins even if tier is lower.
        return false;
      }
    }

    // Additive: undated Lifetime/exit-offer must not overwrite a dated 6M/1Y.
    if (incomingDate == null &&
        _bestRestoreTransactionAt != null &&
        incomingTier >= 3 &&
        _highestRestoredTierApplied > 0 &&
        _highestRestoredTierApplied < 3) {
      debugPrint(
        'Restore: skip undated lifetime/exit over dated lower plan $productId',
      );
      return true;
    }

    int currentTier = _highestRestoredTierApplied;
    if (downloadProvider != null) {
      final currentPlan = await downloadProvider.getSubscriptionPlan();
      final storedTier = _storedSubscriptionPlanTier(currentPlan);
      if (storedTier > currentTier) currentTier = storedTier;
    }
    if (incomingTier < currentTier) {
      debugPrint(
        'Restore: skip downgrade $productId (tier $incomingTier) '
        '< existing tier $currentTier',
      );
      return true;
    }
    return false;
  }

  void _claimRestoreCandidate(String productId, {String? transactionDate}) {
    final tier = _restoreProductTier(productId);
    if (tier <= 0) return;
    final incomingDate = _parseRestoreTransactionDate(transactionDate);

    if (_bestRestoreProductId == null) {
      _bestRestoreProductId = productId;
      _highestRestoredTierApplied = tier;
      _bestRestoreTransactionAt = incomingDate;
      return;
    }

    // Dated candidate replaces an undated prior claim.
    if (incomingDate != null && _bestRestoreTransactionAt == null) {
      _bestRestoreProductId = productId;
      _highestRestoredTierApplied = tier;
      _bestRestoreTransactionAt = incomingDate;
      return;
    }

    if (incomingDate != null && _bestRestoreTransactionAt != null) {
      if (incomingDate.isAfter(_bestRestoreTransactionAt!)) {
        _bestRestoreProductId = productId;
        _highestRestoredTierApplied = tier;
        _bestRestoreTransactionAt = incomingDate;
        return;
      }
      if (incomingDate.isBefore(_bestRestoreTransactionAt!)) {
        return;
      }
    }

    // Do not let undated higher tier replace a dated lower-tier claim.
    if (incomingDate == null &&
        _bestRestoreTransactionAt != null &&
        tier > _highestRestoredTierApplied) {
      return;
    }

    if (tier > _highestRestoredTierApplied) {
      _bestRestoreProductId = productId;
      _highestRestoredTierApplied = tier;
      _bestRestoreTransactionAt = incomingDate ?? _bestRestoreTransactionAt;
    }
  }

  void _resetRestoreSessionSelection() {
    _highestRestoredTierApplied = 0;
    _bestRestoreTransactionAt = null;
    _bestRestoreProductId = null;
  }

  void _beginRestoreCollection() {
    _resetRestoreSessionSelection();
    _restoreCollectedProducts.clear();
    _restoreCollecting = true;
  }

  void _queueRestoreProduct(String productId, String date) {
    if (_restoreProductTier(productId) <= 0) return;
    _restoreCollectedProducts.add({
      'id': productId,
      'date': date,
    });
    debugPrint(
      'Restore collect: $productId date=$date '
      'parsed=${_parseRestoreTransactionDate(date)}',
    );
  }

  static const MethodChannel _iapMemoryChannel =
      MethodChannel('com.biblebookapp/iap_memory');
  static const String _lastIapProductPrefKey = 'last_iap_product_id';

  /// Additive: remember the plan the user last bought/applied. Keychain keeps
  /// it across delete+reinstall so Restore matches that plan (not highest tier).
  Future<void> _rememberLastIapProduct(String productId) async {
    if (productId.isEmpty || _restoreProductTier(productId) <= 0) return;
    await SharPreferences.setString(_lastIapProductPrefKey, productId);
    if (!Platform.isIOS) return;
    try {
      await _iapMemoryChannel.invokeMethod('setLastIapProduct', {
        'productId': productId,
      });
    } catch (e) {
      debugPrint('iap_memory set failed: $e');
    }
  }

  Future<String?> _readLastIapProduct() async {
    final local = await SharPreferences.getString(_lastIapProductPrefKey);
    if (local != null && local.trim().isNotEmpty) return local.trim();
    if (!Platform.isIOS) return null;
    try {
      final remote =
          await _iapMemoryChannel.invokeMethod<String>('getLastIapProduct');
      if (remote != null && remote.trim().isNotEmpty) {
        await SharPreferences.setString(_lastIapProductPrefKey, remote.trim());
        return remote.trim();
      }
    } catch (e) {
      debugPrint('iap_memory get failed: $e');
    }
    return null;
  }

  /// Additive: among a pool, newest transaction wins; same date → higher tier.
  Map<String, String>? _pickNewestThenHighestTier(
    List<Map<String, String>> items,
  ) {
    Map<String, String>? best;
    DateTime? bestDate;
    var bestTier = -1;

    for (final item in items) {
      final productId = item['id'] ?? '';
      final dateRaw = item['date'] ?? '';
      final tier = _restoreProductTier(productId);
      if (tier <= 0) continue;
      final date = _parseRestoreTransactionDate(dateRaw);

      if (best == null) {
        best = item;
        bestDate = date;
        bestTier = tier;
        continue;
      }

      if (date != null && bestDate == null) {
        best = item;
        bestDate = date;
        bestTier = tier;
        continue;
      }
      if (date == null && bestDate != null) continue;
      if (date != null && bestDate != null) {
        if (date.isAfter(bestDate)) {
          best = item;
          bestDate = date;
          bestTier = tier;
          continue;
        }
        if (date.isBefore(bestDate)) continue;
      }

      if (tier > bestTier) {
        best = item;
        bestDate = date ?? bestDate;
        bestTier = tier;
      }
    }
    return best;
  }

  /// Additive: prefer last bought product (Keychain/prefs); else newest timed;
  /// Lifetime only when no timed plan was restored. Purchase apply unchanged.
  Future<Map<String, String>?> _pickBestCollectedRestoreProduct() async {
    final timed = <Map<String, String>>[];
    final lifetimeOnly = <Map<String, String>>[];
    final byId = <String, Map<String, String>>{};

    for (final item in _restoreCollectedProducts) {
      final productId = item['id'] ?? '';
      final tier = _restoreProductTier(productId);
      if (tier <= 0) continue;
      byId[productId] = item;
      if (tier >= 3) {
        lifetimeOnly.add(item);
      } else {
        timed.add(item);
      }
    }

    final remembered = await _readLastIapProduct();
    if (remembered != null && byId.containsKey(remembered)) {
      debugPrint(
        'Restore pick: prefer last purchased $remembered '
        '(ignored tier/date among ${byId.length} StoreKit product(s))',
      );
      return byId[remembered];
    }

    if (timed.isNotEmpty) {
      final picked = _pickNewestThenHighestTier(timed);
      debugPrint(
        'Restore pick: prefer newest timed ${picked?['id']} '
        '(ignored ${lifetimeOnly.length} lifetime candidate(s); '
        'no remembered product match)',
      );
      return picked;
    }
    return _pickNewestThenHighestTier(lifetimeOnly);
  }

  Future<void> _applyBestCollectedRestore(
    DashBoardController controller,
  ) async {
    final best = await _pickBestCollectedRestoreProduct();
    _restoreCollecting = false;
    if (best == null) {
      EasyLoading.dismiss();
      Constants.showToast('No active subscription available');
      return;
    }
    debugPrint(
      'Restore apply best: ${best['id']} date=${best['date']} '
      'parsed=${_parseRestoreTransactionDate(best['date'])}',
    );
    _resetRestoreSessionSelection();
    _forceApplyCollectedRestoreBest = true;
    try {
      await restorePurchaseHandle(
        best['id'] ?? '',
        best['date'] ?? '',
        controller,
        context: context,
      );
    } finally {
      _forceApplyCollectedRestoreBest = false;
      EasyLoading.dismiss();
    }
  }

  void _sanitizeStalePaywallProducts() {
    final removed = <String>[];
    _products.removeWhere((product) {
      final isStale = !_isPaywallProductForThisApp(product.id);
      if (isStale) {
        removed.add(product.id);
      }
      return isStale;
    });
    if (removed.isNotEmpty) {
      debugPrint(
        '⚠️ Removed stale paywall products from another app bundle: '
        '${removed.join(', ')}',
      );
      debugPrint('   Current app bundle prefix: $_planBundlePrefix');
      debugPrint('   ios_Bundle_Id constant: ${BibleInfo.ios_Bundle_Id}');
    }
  }

  String _productPlanSlotLabel(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('sixmonth')) return '6M';
    if (id.contains('oneyear')) return '1Y';
    if (id.contains('twoyear')) return '2Y';
    if (id.contains('lifetime')) return 'LT';
    return 'unknown';
  }

  int _planSlotForProductId(String productId) {
    if (_isSixMonthProductId(productId)) return 0;
    if (_isOneYearProductId(productId)) return 1;
    // Slot 2 is Lifetime on main paywall (matches initialSelectedPlanIndex docs).
    if (_isLifetimeProductId(productId)) return 2;
    if (_isTwoYearProductId(productId)) return 3;
    return 4;
  }

  int _indexForPlanSlot(int slot) {
    for (var i = 0; i < _products.length; i++) {
      if (_planSlotForProductId(_products[i].id) == slot) {
        return i;
      }
    }
    return selectedindex.clamp(0, _products.length - 1);
  }

  void _applyInitialPlanSelectionIfAny() {
    final idx = widget.initialSelectedPlanIndex;
    if (_products.isEmpty) return;
    if (idx != null) {
      selectedindex = _indexForPlanSlot(idx);
      return;
    }

    // Main paywall default selection: prefer 1-year plan when available.
    // Keep milestone / invisible hosts and exit-offer flows unchanged.
    if (!widget.invisiblePurchaseHost && !widget.fromHomeExitOffer) {
      if (_products.length >= 2) {
        selectedindex = 1;
      } else if (_products.isNotEmpty) {
        selectedindex = 0;
      }
    }
  }

  void _sortProducts() {
    _products.sort((a, b) {
      // Define order: 6 months (0), 1 year (1), lifetime (2), 2 years (3)
      int getOrder(String id) {
        if (_isSixMonthProductId(id)) return 0;
        if (_isOneYearProductId(id)) return 1;
        if (_isLifetimeProductId(id)) return 2;
        if (_isTwoYearProductId(id)) return 3;
        return 4;
      }

      return getOrder(a.id).compareTo(getOrder(b.id));
    });
  }

  Future<void> _autoStartPurchaseIfNeeded() async {
    if (!widget.autoStartSelectedPlanPurchase || _autoPurchaseTriggered) return;
    if (_products.isEmpty) return;
    final idx = selectedindex.clamp(0, _products.length - 1);
    _autoPurchaseTriggered = true;
    await SharPreferences.setString('OpenAd', '1');
    await SharPreferences.setBoolean('startpurches', true);
    _buyProduct(_products[idx]);
  }

  Future<void> _addLifetimeWalletBonus() async {
    final amount = widget.invisiblePurchaseHost ? 1000 : 5000;
    await WalletService.addCredits(amount);
  }

  Future<bool> _tryMarkLifetimeWalletBonusGrantedOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lifetime_wallet_bonus_granted_v1_${widget.checkad}';
      final already = prefs.getBool(key) ?? false;
      if (already) return false;
      await prefs.setBool(key, true);
      return true;
    } catch (_) {
      // If we can't persist, prefer granting rather than missing user credits.
      return true;
    }
  }

  Future<void> _addLifetimeWalletBonusOnce() async {
    final shouldGrant = await _tryMarkLifetimeWalletBonusGrantedOnce();
    if (!shouldGrant) return;
    await _addLifetimeWalletBonus();
  }

  Future<void> _navigateToHomeAfterPurchaseSuccess({
    required bool invisibleHostPopValue,
  }) async {
    if (!mounted) return;
    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
    }
    if (widget.invisiblePurchaseHost) {
      Navigator.of(context).pop(invisibleHostPopValue);
      return;
    }
    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      await provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    if (!mounted) return;
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    Get.offAll(
      () => HomeScreen(
        From: "premium",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ),
    );
  }

  Future<void> _finishAfterLifetimePurchaseSuccess() async {
    await _navigateToHomeAfterPurchaseSuccess(invisibleHostPopValue: true);
  }

  Future<void> _navigateAfterNonLifetimePurchaseSuccess() async {
    if (widget.invisiblePurchaseHost) {
      await _addLifetimeWalletBonusOnce();
    }
    await _navigateToHomeAfterPurchaseSuccess(invisibleHostPopValue: true);
  }

  /// After any paywall subscription succeeds, route to Home (purchase) or streak/home (restore-only).
  Future<void> _completePaywallSubscriptionNavigation({
    required bool startFlag,
    bool lifetimeWalletBonus = false,
    bool invisiblePopSuccess = false,
  }) async {
    if (lifetimeWalletBonus) {
      await _addLifetimeWalletBonusOnce();
    }
    if (widget.invisiblePurchaseHost) {
      _popInvisiblePurchaseHost(invisiblePopSuccess);
      return;
    }
    if (startFlag) {
      await _navigateToHomeAfterPurchaseSuccess(
        invisibleHostPopValue: invisiblePopSuccess,
      );
      return;
    }
    final ctx = context ?? Get.context;
    if (ctx != null) {
      await StreakFlowNavigation.navigateToStreakFlowOrHome(ctx);
    }
  }

  void _popInvisiblePurchaseHost([bool success = false]) {
    if (!mounted || !widget.invisiblePurchaseHost) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(success);
    }
  }

  DownloadProvider? _myProvider;
//// In App Purchase
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
// subscription that listens to a stream of updates to purchase details
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  late Stream<List<PurchaseDetails>> _purchaseUpdatedStream;

  bool _isAvailable = false;

  // checks if a user has purchased a certain product
  PurchaseDetails? _hasUserPurchased(String productID) {
    return null;
  }

  /// Add six months to a given date (or current date if not provided)
  /// Handles month overflow and day adjustments for months with fewer days
  DateTime addSixMonths({DateTime? customDate}) {
    final date = customDate ?? DateTime.now();
    int year = date.year;
    int month = date.month + 6;

    if (month > 12) {
      year += 1;
      month -= 12;
    }

    int day = date.day;

    // Adjust the day if it exceeds the number of days in the target month
    int daysInNewMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInNewMonth) {
      day = daysInNewMonth;
    }

    return DateTime(year, month, day);
  }

  /// Additive: 6-month ad-free duration (aligned with 1Y fixed-days style).
  /// Old restore transaction dates must not produce a past/near-zero duration.
  Duration _resolveSixMonthAdFreeDuration({DateTime? anchorDate}) {
    final computedExpiry = addSixMonths(customDate: anchorDate ?? DateTime.now());
    final diff = computedExpiry.difference(DateTime.now());
    // Keep existing calendar math when it still yields a real future window.
    if (!diff.isNegative && diff.inHours >= 24) {
      return diff;
    }
    debugPrint(
      'Six month: computed duration past/too short ($diff) — '
      'using fixed 183 days',
    );
    return const Duration(days: 183);
  }

  /// Additive: do not replace a longer existing premium expiry with a shorter one
  /// (e.g. fresh 6M purchase overwritten by an older restored 6M transaction).
  Future<bool> _shouldSkipShorterSixMonthExpiry(Duration incoming) async {
    final existing = await SharPreferences.getString(
      SharPreferences.isRewardAdViewTime,
    );
    if (existing == null || existing.isEmpty) return false;
    try {
      final existingExpiry = DateTime.parse(existing);
      final incomingExpiry = DateTime.now().add(incoming);
      if (incomingExpiry.isBefore(existingExpiry)) {
        debugPrint(
          'Six month: skip shorter expiry overwrite '
          '($incomingExpiry < $existingExpiry)',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Six month: expiry compare parse error: $e');
    }
    return false;
  }

  /// Additive: apply 6-month premium unlock without clobbering a better expiry.
  Future<void> _applySixMonthPremium(
    DashBoardController controller, {
    DateTime? anchorDate,
  }) async {
    final diff = _resolveSixMonthAdFreeDuration(anchorDate: anchorDate);
    if (await _shouldSkipShorterSixMonthExpiry(diff)) {
      await controller.refreshPremiumStatusFromPrefs();
      return;
    }
    await controller.disableAd(diff);
  }

  /// Check if user has an active subscription for the given product ID
  Future<bool> _hasActiveSubscriptionForPlan(String productId) async {
    try {
      // Get current subscription plan
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      final subscriptionPlan = await downloadProvider.getSubscriptionPlan();

      // Map product IDs to subscription plans
      String? expectedPlan;
      if (productId == widget.lifeTimePlan) {
        expectedPlan = 'platinum';
      } else if (_isOneYearProductId(productId)) {
        expectedPlan = 'gold';
      } else if (_isSixMonthProductId(productId)) {
        expectedPlan = 'silver';
      }

      // Check if subscription plan matches
      if (subscriptionPlan == null || expectedPlan == null) {
        return false;
      }

      if (subscriptionPlan.toLowerCase() != expectedPlan.toLowerCase()) {
        return false;
      }

      // Check if subscription is still valid (expiry date)
      final expiryDateString =
          await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
      if (expiryDateString == null || expiryDateString.isEmpty) {
        return false;
      }

      try {
        final expiryDate = DateTime.parse(expiryDateString);
        final currentTime = DateTime.now();
        final diffDays = expiryDate.difference(currentTime).inDays;
        // Subscription is valid if expiry date is today or in the future (>= 0)
        return diffDays >= 0;
      } catch (e) {
        debugPrint("Error parsing expiry date: $e");
        return false;
      }
    } catch (e) {
      debugPrint("Error checking active subscription: $e");
      return false;
    }
  }

  /// Show restore dialog if user already has active subscription for the plan
  Future<void> _showRestoreDialog(
      ProductDetails prod, DashBoardController controller) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "You're Already on this Plan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Would You like to Restore it ?",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // Process restore
                  await _restorePurchases(controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CommanColor.lightModePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Yes, Restore",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _buyProduct(ProductDetails prod) async {
    // Additive: block purchase when dashboard IAP is disabled.
    if (!await SubscriptionScreen.isDashboardIapEnabled()) {
      debugPrint(
          'SubscriptionScreen: dashboard IAP disabled — skip _buyProduct');
      return;
    }

    // Check connectivity FIRST before showing loader
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast("No Internet connection");
      return; // Return early - don't show loader or proceed
    }

    // Check if user already has active subscription for this plan
    final hasActiveSubscription = await _hasActiveSubscriptionForPlan(prod.id);
    if (hasActiveSubscription) {
      // Set flag to show restore dialog when purchase stream detects restored status
      _shouldShowRestoreDialog = true;
      _pendingRestoreProductId = prod.id;
      // Show restore dialog immediately
      final controller = Get.find<DashBoardController>();
      await _showRestoreDialog(prod, controller);
      // Reset flags if user cancels
      _shouldShowRestoreDialog = false;
      _pendingRestoreProductId = null;
      return; // Don't proceed with purchase
    }

    if (!userTap) {
      debugPrint("Buy Product");
      try {
        if (mounted) {
          setState(() {
            userTap = true;
          });
        }
        EasyLoading.show();

        // Start 6-second timeout timer for loading
        _loadingTimeoutTimer?.cancel(); // Cancel any existing timer
        _loadingTimeoutTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) {
            debugPrint('IAP Loading timeout - dismissing after 6 seconds');
            EasyLoading.dismiss();
            setState(() {
              userTap = false;
            });
          }
        });

        await SharPreferences.setString('OpenAd', '1');
        await SharPreferences.setBoolean('startpurches', true);

        // Check again before purchase (in case subscription status changed)
        final hasActiveSubscriptionCheck =
            await _hasActiveSubscriptionForPlan(prod.id);
        if (hasActiveSubscriptionCheck) {
          // Set flag to show restore dialog when purchase stream detects restored status
          _shouldShowRestoreDialog = true;
          _pendingRestoreProductId = prod.id;
          _loadingTimeoutTimer?.cancel(); // Cancel timeout timer
          EasyLoading.dismiss();
          if (mounted) {
            setState(() {
              userTap = false;
            });
          }
          final controller = Get.find<DashBoardController>();
          await _showRestoreDialog(prod, controller);
          // Reset flags if user cancels
          _shouldShowRestoreDialog = false;
          _pendingRestoreProductId = null;
          return;
        }

        final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
        _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        // setState(() {
        //   userTap = false;
        // });
      } catch (e) {
        debugPrint('Error: $e');
        _loadingTimeoutTimer?.cancel(); // Cancel timeout timer on error
      } finally {
        // Don't reset userTap here immediately - let timeout or purchase completion handle it
        // This prevents premature reset if user closes system dialog
      }
    }
  }

  /// Mark that paywall has been shown (for first time tracking)
  Future<void> _markPaywallShown() async {
    final hasShownPaywall =
        await SharPreferences.getBoolean('has_shown_paywall_first_time') ??
            false;
    if (!hasShownPaywall) {
      await SharPreferences.setBoolean('has_shown_paywall_first_time', true);
      await SharPreferences.setBoolean('is_first_time_paywall_cancel', true);
    }
    // Store first time user sees paywall (for 3-day gate before exit offer / red dot)
    final firstSeen =
        await SharPreferences.getString('paywall_first_seen_date');
    if (firstSeen == null || firstSeen.isEmpty) {
      await SharPreferences.setString(
          'paywall_first_seen_date', DateTime.now().toIso8601String());
    }
  }

  /// Check if exit offer should be shown and display it (for purchase cancellation)
  Future<void> _checkAndShowExitOffer(DashBoardController controller) async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        Constants.showToast("No internet connection", 5000);
        return;
      }
      // Show exit offer only after 3 days since first paywall view (matches red dot)
      final firstSeenStr =
          await SharPreferences.getString('paywall_first_seen_date');
      if (firstSeenStr != null && firstSeenStr.isNotEmpty) {
        try {
          final firstSeen = DateTime.parse(firstSeenStr);
          if (DateTime.now().difference(firstSeen).inDays < 3) {
            return;
          }
        } catch (_) {}
      }
      final isFirstTimeCancel =
          await SharPreferences.getBoolean('is_first_time_paywall_cancel') ??
              false;

      if (!isFirstTimeCancel) {
        // Not the first time, don't show exit offer
        return;
      }

      // Check if exit offer already shown and if 10 minutes have passed
      final hasShownExitOffer =
          await SharPreferences.getBoolean('has_shown_exit_offer') ?? false;
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');

      if (hasShownExitOffer && exitOfferFirstShownTime != null) {
        // Check if 10 minutes have passed
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final now = DateTime.now();
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            return;
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
        }
      }

      // Check API response for exit offer
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null) {
        // Mark that exit offer has been shown and save timestamp
        if (!hasShownExitOffer) {
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', DateTime.now().toIso8601String());
        }
        await SharPreferences.setBoolean('is_first_time_paywall_cancel', false);

        // Show exit offer bottom sheet
        if (mounted) {
          _showExitOfferBottomSheet(exitOffer);
        }
      } else {
        debugPrint('Exit offer not found in API response');
      }
    } catch (e) {
      debugPrint('Error checking exit offer: $e');
    }
  }

  /// Show exit offer from home screen (checking 10 minute limit).
  /// Exit offer only after 5 days since first paywall view; before that, just open paywall.
  /// When not expired: show exit offer in bottom sheet on Home; Unlock -> IAP, Maybe later -> close.
  /// When expired: show toast and navigate to IAP as usual.
  static Future<void> showExitOfferFromHomeScreen(
      BuildContext context, DashBoardController controller) async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        Constants.showToast("No internet connection", 5000);
        return;
      }
      // Exit offer only after 3 days of app use (first paywall seen); matches red dot
      final paywallFirstSeenStr =
          await SharPreferences.getString('paywall_first_seen_date');
      if (paywallFirstSeenStr == null || paywallFirstSeenStr.isEmpty) {
        await SubscriptionScreen.navigateToPaywallFromHome(context);
        return;
      }
      try {
        final firstSeen = DateTime.parse(paywallFirstSeenStr);
        if (DateTime.now().difference(firstSeen).inDays < 3) {
          await SubscriptionScreen.navigateToPaywallFromHome(context);
          return;
        }
      } catch (_) {
        await SubscriptionScreen.navigateToPaywallFromHome(context);
        return;
      }

      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');
      final now = DateTime.now();
      bool isExpired = false;

      if (exitOfferFirstShownTime != null) {
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            isExpired = true;
            final alreadyNotified = await SharPreferences.getBoolean(
                    'exit_offer_expired_toast_shown') ??
                false;
            if (!alreadyNotified) {
              await SharPreferences.setBoolean(
                  'exit_offer_expired_toast_shown', true);
              Constants.showToast("Limited time offer has expired");
            }
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
          isExpired = true;
          final alreadyNotified = await SharPreferences.getBoolean(
                  'exit_offer_expired_toast_shown') ??
              false;
          if (!alreadyNotified) {
            await SharPreferences.setBoolean(
                'exit_offer_expired_toast_shown', true);
            Constants.showToast("Limited time offer has expired");
          }
        }
      }

      final sixMonthPlan = await SharPreferences.getString('sixMonthPlan') ??
          BibleInfo.sixMonthPlanid;
      final oneYearPlan = await SharPreferences.getString('oneYearPlan') ??
          BibleInfo.oneYearPlanid;
      final lifeTimePlan = await SharPreferences.getString('lifeTimePlan') ??
          BibleInfo.lifeTimePlanid;

      if (isExpired) {
        SubscriptionScreen.openPaywallStacked(
          sixMonthPlan: sixMonthPlan,
          oneYearPlan: oneYearPlan,
          lifeTimePlan: lifeTimePlan,
          checkad: 'home',
        );
        return;
      }

      // Not expired: show exit offer in bottom sheet on Home
      if (exitOfferFirstShownTime == null) {
        await SharPreferences.setBoolean('has_shown_exit_offer', true);
        await SharPreferences.setString(
            'exit_offer_first_shown_time', now.toIso8601String());
      }

      final exitOffer = await getExitOfferFromApiStatic(controller);
      if (exitOffer == null || !context.mounted) {
        SubscriptionScreen.openPaywallStacked(
          sixMonthPlan: sixMonthPlan,
          oneYearPlan: oneYearPlan,
          lifeTimePlan: lifeTimePlan,
          checkad: 'home',
        );
        return;
      }

      String lifetimePrice = "\$24.99";
      String originalLifetimePrice = "\$24.99";
      final productId = exitOffer.identifier ?? lifeTimePlan;
      try {
        final response = await InAppPurchase.instance
            .queryProductDetails(<String>{productId});
        if (response.productDetails.isNotEmpty) {
          lifetimePrice = response.productDetails.first.price;
          originalLifetimePrice = lifetimePrice;
        }
      } catch (_) {}

      final screenWidth = MediaQuery.sizeOf(context).width;
      int remainingSeconds = 600;
      try {
        final stored =
            await SharPreferences.getString('exit_offer_first_shown_time');
        if (stored != null && stored.isNotEmpty) {
          final firstShown = DateTime.parse(stored);
          final diffSeconds = DateTime.now().difference(firstShown).inSeconds;
          remainingSeconds = (600 - diffSeconds).clamp(0, 600);
        }
      } catch (_) {}
      final initialMinutes = remainingSeconds ~/ 60;
      final initialSeconds = remainingSeconds % 60;

      if (!context.mounted) return;
      final homeContext = context;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext sheetContext) {
          return _ExitOfferBottomSheetContent(
            exitOffer: exitOffer,
            lifetimePrice: lifetimePrice,
            originalLifetimePrice: originalLifetimePrice,
            screenWidth: screenWidth,
            initialMinutes: initialMinutes,
            initialSeconds: initialSeconds,
            onUnlockPremium: () {
              // Close bottom sheet first, then route to IAP using Home context
              // so the full SubscriptionScreen opens instead of purchase sheets on the sheet.
              Navigator.of(sheetContext).pop();
              if (homeContext.mounted) {
                SubscriptionScreen.openPaywallStacked(
                  sixMonthPlan: sixMonthPlan,
                  oneYearPlan: oneYearPlan,
                  lifeTimePlan: lifeTimePlan,
                  checkad: 'home',
                  fromHomeExitOffer: false,
                );
              }
            },
            onMaybeLater: () {
              SharPreferences.setBoolean('exit_offer_cooldown_active', true);
              Navigator.of(sheetContext).pop();
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing exit offer from home: $e');
      Constants.showToast("Unable to load offer");
    }
  }

  /// Check if exit offer should be shown before closing/navigating away from paywall
  Future<void> _checkAndShowExitOfferBeforeClose(
      DashBoardController controller) async {
    try {
      debugPrint('🚪 User is closing/navigating away from paywall');
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        Constants.showToast("No internet connection", 5000);
        _navigateAwayFromPaywall();
        return;
      }
      // Show exit offer only after 3 days since first paywall view (matches red dot)
      final firstSeenStr =
          await SharPreferences.getString('paywall_first_seen_date');
      if (firstSeenStr != null && firstSeenStr.isNotEmpty) {
        try {
          final firstSeen = DateTime.parse(firstSeenStr);
          if (DateTime.now().difference(firstSeen).inDays < 3) {
            _navigateAwayFromPaywall();
            return;
          }
        } catch (_) {}
      }
      // First, check if exit offer timer has expired (10 minutes check)
      final hasShownExitOffer =
          await SharPreferences.getBoolean('has_shown_exit_offer') ?? false;
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');

      if (hasShownExitOffer && exitOfferFirstShownTime != null) {
        // Check if 10 minutes have passed
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final now = DateTime.now();
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            debugPrint(
                '⏭️ Exit offer time expired (10 minutes passed), navigating away');
            _navigateAwayFromPaywall();
            return;
          } else {
            // 10 minutes haven't passed yet, show exit offer again
            debugPrint(
                '⏰ Exit offer timer still active (${10 - difference.inMinutes} minutes remaining), showing exit offer again');
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
        }
      }

      // Check if this is first time (for initial setup only)
      final isFirstTimeCancel =
          await SharPreferences.getBoolean('is_first_time_paywall_cancel') ??
              false;
      debugPrint('🔑 Is first time cancel: $isFirstTimeCancel');

      // Check API response for exit offer
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null) {
        debugPrint('✅ Exit offer found! Showing bottom sheet...');
        // Mark that exit offer has been shown and save timestamp (only on first show)
        if (!hasShownExitOffer) {
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', DateTime.now().toIso8601String());
          debugPrint('📝 First time showing exit offer, timestamp saved');
        }
        // Only set first time flag to false on first show (keep existing logic)
        if (isFirstTimeCancel) {
          await SharPreferences.setBoolean(
              'is_first_time_paywall_cancel', false);
        }

        // Show exit offer bottom sheet (will show again if dismissed and clicked again within 10 minutes)
        if (mounted) {
          _showExitOfferBottomSheet(exitOffer);
        } else {
          debugPrint('⚠️ Widget not mounted, cannot show bottom sheet');
          _navigateAwayFromPaywall();
        }
      } else {
        debugPrint('❌ Exit offer not found in API response - navigating away');
        // No exit offer in API, navigate away normally
        _navigateAwayFromPaywall();
      }
    } catch (e) {
      debugPrint('❌ Error checking exit offer before close: $e');
      // On error, navigate away normally
      _navigateAwayFromPaywall();
    }
  }

  /// Navigate away from paywall screen
  Future<void> _navigateAwayFromPaywall() async {
    if (!mounted) return;
    if (_myProvider != null) {
      _myProvider?.enableAd();
    }
    SharPreferences.setBoolean('closead', true);

    if (!mounted) return;
    final nav = Navigator.of(context);

    // Paywall opened on top of an existing screen — pop with GetX so reverse
    // animation matches the forward cupertino slide.
    if (nav.canPop()) {
      Get.back();
      return;
    }

    // Onboarding paywall replaced the stack — continue to streak/home.
    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Get exit offer from API response with fallback to constant data
  Future<GetAudioModelDataSubFields?> _getExitOfferFromApi(
      DashBoardController controller) async {
    try {
      debugPrint('🔍 Checking exit offer in API response...');

      // First try to get from controller's audioData
      GetAudioModel? apiData = controller.audioData.value;
      List<GetAudioModelDataSubFields?>? subFields = apiData.data?.subFields;

      // If controller data is empty, try loading from cached SharedPreferences
      if (subFields == null || subFields.isEmpty) {
        debugPrint(
            '⚠️ Controller audioData is empty, trying to load from cache...');
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedJson = prefs.getString('cached_api_response');

          if (cachedJson != null && cachedJson.isNotEmpty) {
            debugPrint('📦 Found cached API response, parsing...');
            final jsonData = jsonDecode(cachedJson);
            apiData = GetAudioModel.fromJson(jsonData);
            subFields = apiData.data?.subFields;
            debugPrint('✅ Loaded API data from cache successfully');
          } else {
            debugPrint(
                '⚠️ No cached API response found, trying to load API directly...');
            // Try to load API directly if cache doesn't exist
            try {
              final loadedData = await getMusicDetails();
              if (loadedData != null && loadedData.data != null) {
                debugPrint('✅ Successfully loaded API data directly');
                // Cache it for future use
                final jsonString = jsonEncode(loadedData.toJson());
                await prefs.setString('cached_api_response', jsonString);
                // Update controller's data
                controller.audioData.value = loadedData;
                apiData = loadedData;
                subFields = loadedData.data?.subFields;
                debugPrint('✅ API data cached and controller updated');
              } else {
                debugPrint('⚠️ API returned null data');
              }
            } catch (apiError) {
              debugPrint('❌ Error loading API directly: $apiError');
            }
          }
        } catch (cacheError) {
          debugPrint('❌ Error loading from cache: $cacheError');
        }
      }

      debugPrint('📊 SubFields count: ${subFields?.length ?? 0}');

      // Get exit offer ID from SharedPreferences (with fallback to constant)
      final exitOfferId = await SharPreferences.getString('exitOfferPlan') ??
          BibleInfo.exitOfferPlanid;

      if (subFields != null && subFields.isNotEmpty) {
        for (var field in subFields) {
          debugPrint('📋 Field identifier: ${field?.identifier}');
          if (field?.identifier == exitOfferId) {
            debugPrint('✅ Exit offer found!');
            return field;
          }
        }
        debugPrint('⚠️ Exit offer identifier not found in subFields');
      } else {
        debugPrint('⚠️ No subFields found in API response');
      }

      // Fallback to constant data if API and cache both failed
      debugPrint(
          '⚠️ Exit offer not found in API/cache, using constant data as fallback');
      try {
        // Create a fallback exit offer using constant lifetime plan ID
        final fallbackExitOffer = GetAudioModelDataSubFields(
          identifier: BibleInfo.lifeTimePlanid, // Use constant lifetime plan ID
          item_1: "Unlock every Premium Bible feature",
          item_2: "30% Off for the next 10 minutes",
          value: "30",
        );
        debugPrint('✅ Created fallback exit offer with constant data');
        return fallbackExitOffer;
      } catch (e) {
        debugPrint('❌ Error creating fallback exit offer: $e');
      }

      debugPrint('❌ Exit offer not found and fallback failed');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting exit offer from API: $e');
      // Try fallback even on error
      try {
        final fallbackExitOffer = GetAudioModelDataSubFields(
          identifier: BibleInfo.lifeTimePlanid,
          item_1: "Unlock every Premium Bible feature",
          item_2: "30% Off for the next 10 minutes",
          value: "30",
        );
        debugPrint('✅ Created fallback exit offer after error');
        return fallbackExitOffer;
      } catch (fallbackError) {
        debugPrint(
            '❌ Error creating fallback exit offer after error: $fallbackError');
        return null;
      }
    }
  }

  /// Static helper to get exit offer (for showing on Home without SubscriptionScreen instance)
  static Future<GetAudioModelDataSubFields?> getExitOfferFromApiStatic(
      DashBoardController controller) async {
    try {
      GetAudioModel? apiData = controller.audioData.value;
      List<GetAudioModelDataSubFields?>? subFields = apiData.data?.subFields;

      if (subFields == null || subFields.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedJson = prefs.getString('cached_api_response');
          if (cachedJson != null && cachedJson.isNotEmpty) {
            final jsonData = jsonDecode(cachedJson);
            apiData = GetAudioModel.fromJson(jsonData);
            subFields = apiData.data?.subFields;
          } else {
            try {
              final loadedData = await getMusicDetails();
              if (loadedData != null && loadedData.data != null) {
                final jsonString = jsonEncode(loadedData.toJson());
                await prefs.setString('cached_api_response', jsonString);
                controller.audioData.value = loadedData;
                apiData = loadedData;
                subFields = loadedData.data?.subFields;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }

      final exitOfferId = await SharPreferences.getString('exitOfferPlan') ??
          BibleInfo.exitOfferPlanid;

      if (subFields != null && subFields.isNotEmpty) {
        for (var field in subFields) {
          if (field?.identifier == exitOfferId) return field;
        }
      }

      return GetAudioModelDataSubFields(
        identifier: BibleInfo.lifeTimePlanid,
        item_1: "Unlock every Premium Bible feature",
        item_2: "30% Off for the next 10 minutes",
        value: "30",
      );
    } catch (e) {
      debugPrint('getExitOfferFromApiStatic error: $e');
      return GetAudioModelDataSubFields(
        identifier: BibleInfo.lifeTimePlanid,
        item_1: "Unlock every Premium Bible feature",
        item_2: "30% Off for the next 10 minutes",
        value: "30",
      );
    }
  }

  /// Show exit offer bottom sheet
  void _showExitOfferBottomSheet(GetAudioModelDataSubFields exitOffer) async {
    // Prevent showing exit offer multiple times
    if (_isExitOfferShowing) {
      debugPrint(
          '⚠️ Exit offer bottom sheet is already showing, skipping duplicate call');
      return;
    }

    // Mark that exit offer is showing immediately to prevent duplicate calls
    _isExitOfferShowing = true;

    final screenWidth = MediaQuery.of(context).size.width;

    // Debug log for exit offer content
    debugPrint(
        'Exit offer full data -> identifier: ${exitOffer.identifier}, item1: ${exitOffer.item_1}, item2: ${exitOffer.item_2}, value: ${exitOffer.value}');

    // Debug log for all product prices
    try {
      final productSummaries = _products
          .map((p) => '${p.id}: ${p.price.isNotEmpty ? p.price : 'n/a'}')
          .join(' | ');
      debugPrint('Available products -> $productSummaries');
    } catch (e) {
      debugPrint('Error logging products: $e');
    }

    // Calculate remaining countdown based on first shown time
    int remainingSeconds = 600; // 10 minutes default
    try {
      final stored =
          await SharPreferences.getString('exit_offer_first_shown_time');
      if (stored != null && stored.isNotEmpty) {
        final firstShown = DateTime.parse(stored);
        final diffSeconds = DateTime.now().difference(firstShown).inSeconds;
        remainingSeconds = (600 - diffSeconds).clamp(0, 600);
      }
    } catch (_) {}

    final initialMinutes = remainingSeconds ~/ 60;
    final initialSeconds = remainingSeconds % 60;

    // Fetch exit offer product from store using the identifier BEFORE showing bottom sheet
    String exitOfferPrice = "\$24.99"; // Fallback
    String originalLifetimePrice = "\$24.99"; // Fallback

    try {
      // Get the exit offer product ID from the API response
      final exitOfferProductId = exitOffer.identifier;

      if (exitOfferProductId == null || exitOfferProductId.isEmpty) {
        debugPrint(
            '⚠️ Exit offer product ID is null or empty, using lifetime product');
        // Use lifetime product as fallback
        try {
          final lifetimeProduct = _products.firstWhere(
            (product) => product.id == widget.lifeTimePlan,
            orElse: () =>
                _products.isNotEmpty ? _products.first : null as ProductDetails,
          );
          if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
            exitOfferPrice = lifetimeProduct.price;
            _exitOfferProduct = lifetimeProduct; // Store for purchase
          }
        } catch (e) {
          debugPrint('⚠️ Error getting lifetime product: $e');
        }
      } else {
        debugPrint('🔍 Fetching exit offer product: $exitOfferProductId');

        // Query the exit offer product from the store
        final Set<String> exitOfferIds = {exitOfferProductId};
        final ProductDetailsResponse exitOfferResponse =
            await _inAppPurchase.queryProductDetails(exitOfferIds);

        if (exitOfferResponse.productDetails.isNotEmpty) {
          final exitOfferProduct = exitOfferResponse.productDetails.first;
          _exitOfferProduct = exitOfferProduct; // Store for purchase
          exitOfferPrice = exitOfferProduct.price;
          debugPrint('✅ Exit offer product loaded: ${exitOfferProduct.id}');
          debugPrint('💰 EXIT OFFER PRICE: $exitOfferPrice');
        } else {
          debugPrint(
              '⚠️ Exit offer product not found in store, using lifetime product');
          if (exitOfferResponse.error != null) {
            debugPrint('❌ Error: ${exitOfferResponse.error}');
          }
          // Fallback to lifetime product
          try {
            final lifetimeProduct = _products.firstWhere(
              (product) => product.id == widget.lifeTimePlan,
              orElse: () => _products.isNotEmpty
                  ? _products.first
                  : null as ProductDetails,
            );
            if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
              exitOfferPrice = lifetimeProduct.price;
              _exitOfferProduct = lifetimeProduct; // Store for purchase
            }
          } catch (e) {
            debugPrint('⚠️ Error getting lifetime product as fallback: $e');
          }
        }
      }

      // Get original lifetime product price for comparison
      try {
        final lifetimeProduct = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () =>
              _products.isNotEmpty ? _products.first : null as ProductDetails,
        );
        if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
          originalLifetimePrice = lifetimeProduct.price;
          debugPrint('📊 Original Lifetime Price: $originalLifetimePrice');
        }
      } catch (e) {
        debugPrint('⚠️ Error getting original lifetime product price: $e');
      }

      // Print exit offer details
      debugPrint(
          '📊 Exit Offer Data - identifier: ${exitOffer.identifier}, item_1: ${exitOffer.item_1}, item_2: ${exitOffer.item_2}, discount_value: ${exitOffer.value}');
      debugPrint('💰 Final Exit Offer Price: $exitOfferPrice');
      debugPrint('💰 Original Lifetime Price: $originalLifetimePrice');
    } catch (e) {
      debugPrint('❌ Error fetching exit offer product: $e');
      // Fallback to original lifetime product price
      try {
        final lifetimeProduct = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () =>
              _products.isNotEmpty ? _products.first : null as ProductDetails,
        );
        if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
          exitOfferPrice = lifetimeProduct.price;
          _exitOfferProduct = lifetimeProduct; // Store for purchase
        }
      } catch (e2) {
        debugPrint('❌ Error in fallback: $e2');
      }
    }

    final lifetimePrice = exitOfferPrice;

    if (!mounted) {
      _isExitOfferShowing = false; // Reset flag if widget is not mounted
      return;
    }

    // Show bottom sheet after product is fetched
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible:
          false, // Prevent auto-dismiss on iPad - user must take action
      enableDrag: false,
      builder: (BuildContext context) {
        return _ExitOfferBottomSheetContent(
          exitOffer: exitOffer,
          lifetimePrice: lifetimePrice,
          originalLifetimePrice: originalLifetimePrice,
          screenWidth: screenWidth,
          initialMinutes: initialMinutes,
          initialSeconds: initialSeconds,
          onUnlockPremium: () {
            _isExitOfferShowing = false; // Reset flag when dismissed
            Navigator.of(context).pop();
            _handleExitOfferPurchase();
          },
          onMaybeLater: () {
            _isExitOfferShowing = false; // Reset flag when dismissed
            // Mark cooldown active so home icon can show dot for 10 minutes
            SharPreferences.setBoolean('exit_offer_cooldown_active', true);
            Navigator.of(context).pop();
            _navigateAwayFromPaywall();
          },
        );
      },
    ).whenComplete(() {
      // Reset flag when bottom sheet is dismissed (in case of swipe down or back button)
      _isExitOfferShowing = false;
    });
  }

  /// Handle exit offer purchase (lifetime plan)
  Future<void> _handleExitOfferPurchase() async {
    try {
      // Set startpurches flag to true so purchase can be processed
      await SharPreferences.setBoolean('startpurches', true);

      // Use exit offer product if available, otherwise fallback to regular lifetime product
      ProductDetails? productToPurchase = _exitOfferProduct;

      if (productToPurchase == null) {
        debugPrint(
            '⚠️ Exit offer product not available, using regular lifetime product');
        // Fallback to regular lifetime product
        productToPurchase = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () => _products.first,
        );
      } else {
        debugPrint('✅ Using exit offer product: ${productToPurchase.id}');
      }

      // Trigger purchase
      await _buyProduct(productToPurchase);
    } catch (e) {
      debugPrint('Error handling exit offer purchase: $e');
      Constants.showToast('Unable to process purchase. Please try again.');
    }
  }

  Future<void> _verifyPurchases() async {
    PurchaseDetails? purchase = _hasUserPurchased('');
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {}
  }

  restorePurchaseHandle(
      String productId, String date, DashBoardController controller,
      {BuildContext? context}) async {
    await SharPreferences.setString('OpenAd', '1');
    final dataEarly = await SharPreferences.getBoolean('restorepurches');
    final startFlagEarly = await SharPreferences.getBoolean('startpurches');

    DownloadProvider? downloadProviderEarly;
    if (context != null) {
      downloadProviderEarly =
          Provider.of<DownloadProvider>(context, listen: false);
    } else {
      final getContext = Get.context;
      if (getContext != null) {
        downloadProviderEarly =
            Provider.of<DownloadProvider>(getContext, listen: false);
      }
    }

    // Additive: claim/skip before the existing delay so parallel restores
    // keep the newest transaction (and tier only as a same-date tiebreaker).
    if (dataEarly == true || startFlagEarly == true) {
      if (await _shouldSkipRestoreDowngrade(
        productId,
        downloadProviderEarly,
        transactionDate: date,
      )) {
        EasyLoading.dismiss();
        return;
      }
      _claimRestoreCandidate(productId, transactionDate: date);
    }

    final dateTime = _parseRestoreTransactionDate(date) ?? DateTime.now();
    await Future.delayed(Duration(seconds: 2));
    final data = await SharPreferences.getBoolean('restorepurches');
    final startFlag = await SharPreferences.getBoolean('startpurches');
    final successToastMessage =
        (startFlag == true) ? 'Purchase Successful' : 'Restore Successful';
    debugPrint(
      "restore data 1 is $data | startFlag=$startFlag | productId=$productId",
    );
    if (data == true || startFlag == true) {
      // Treat Exit Offer product as lifetime plan for premium unlock flow
      final bool isExitOfferLifetime =
          productId.toString().toLowerCase().contains('lifetime.exitoffer') ||
              productId.toString().toLowerCase().contains('exitoffer');

      // Get DownloadProvider to set subscription plan
      DownloadProvider? downloadProvider = downloadProviderEarly;
      if (downloadProvider == null) {
        if (context != null) {
          downloadProvider =
              Provider.of<DownloadProvider>(context, listen: false);
        } else {
          // Try to get from Get.context as fallback
          final getContext = Get.context;
          if (getContext != null) {
            downloadProvider =
                Provider.of<DownloadProvider>(getContext, listen: false);
          }
        }
      }

      // Additive: re-check after delay (newer/higher candidate may have claimed).
      if (await _shouldSkipRestoreDowngrade(
        productId,
        downloadProvider,
        transactionDate: date,
      )) {
        EasyLoading.dismiss();
        return;
      }
      _claimRestoreCandidate(productId, transactionDate: date);

      // Additive: stamp last Buy product (Keychain) so reinstall Restore
      // prefers that plan — not highest-tier among all StoreKit history.
      if (startFlag == true) {
        await _rememberLastIapProduct(productId);
      }

      // Additive: match Lifetime the same way as 1Y/6M helpers (not exact ID only).
      if (_isLifetimeProductId(productId) || isExitOfferLifetime) {
        if (await _shouldSkipRestoreDowngrade(
          productId,
          downloadProvider,
          transactionDate: date,
        )) {
          EasyLoading.dismiss();
          return;
        }
        await controller.disableAd(const Duration(days: 3650012345));
        // Set subscription plan to platinum for lifetime plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('platinum');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        // StoreKit may report "restored" for already-owned products even in a buy flow.
        // Ensure the milestone wallet bonus is applied once when a buy was initiated.
        if (startFlag == true) {
          await _addLifetimeWalletBonusOnce();
        }
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        await _completePaywallSubscriptionNavigation(
          startFlag: startFlag == true,
          lifetimeWalletBonus: startFlag == true,
          invisiblePopSuccess: true,
        );
        return;
      } else if (_isOneYearProductId(productId)) {
        // Additive: final guard before mutating expiry/plan.
        if (await _shouldSkipRestoreDowngrade(
          productId,
          downloadProvider,
          transactionDate: date,
        )) {
          EasyLoading.dismiss();
          return;
        }
        final dur = DateTime(dateTime.year + 1, dateTime.month, dateTime.day);
        final diff = dur.difference(DateTime.now());
        await controller.disableAd(diff);
        // Set subscription plan to gold for one year plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('gold');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        await _completePaywallSubscriptionNavigation(
          startFlag: startFlag == true,
          lifetimeWalletBonus:
              startFlag == true && widget.invisiblePurchaseHost,
          invisiblePopSuccess: true,
        );
        return;
      } else if (_isTwoYearProductId(productId)) {
        if (await _shouldSkipRestoreDowngrade(
          productId,
          downloadProvider,
          transactionDate: date,
        )) {
          EasyLoading.dismiss();
          return;
        }
        final dur = DateTime(dateTime.year + 2, dateTime.month, dateTime.day);
        final diff = dur.difference(DateTime.now());
        await controller.disableAd(diff);
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('gold');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        await _completePaywallSubscriptionNavigation(
          startFlag: startFlag == true,
          invisiblePopSuccess: true,
        );
        return;
      } else if (_isSixMonthProductId(productId)) {
        if (await _shouldSkipRestoreDowngrade(
          productId,
          downloadProvider,
          transactionDate: date,
        )) {
          EasyLoading.dismiss();
          return;
        }
        await _applySixMonthPremium(controller, anchorDate: dateTime);
        // Set subscription plan to silver for six month plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('silver');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        await _completePaywallSubscriptionNavigation(
          startFlag: startFlag == true,
          invisiblePopSuccess: true,
        );
        return;
      }
    }
    // final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
    //     _inAppPurchase
    //         .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    // await iosPlatformAddition.setDelegate(null);
    // await _subscription?.cancel();

    // await Future.delayed(Duration(seconds: 1));
    // EasyLoading.dismiss();
    // await SharPreferences.setBoolean('closead', true);
    // Get.back();
    // return Get.offAll(() => HomeScreen(
    //       From: "premium",
    //       selectedVerseNumForRead: "",
    //       selectedBookForRead: "",
    //       selectedChapterForRead: "",
    //       selectedBookNameForRead: "",
    //       selectedVerseForRead: "",
    //     ));
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList,
      DashBoardController controller) {
    // ignore: avoid_function_literals_in_foreach_calls
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      debugPrint("Purchase State: ${purchaseDetails.status}");
      await SharPreferences.setString('OpenAd', '1');
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        // Cancel loading timeout timer when purchase completes (success or error)
        _loadingTimeoutTimer?.cancel();

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Error: ${purchaseDetails.error}');
          DebugConsole.log(" purchases error - $purchaseDetails");
          // Reset userTap on error
          if (mounted) {
            EasyLoading.dismiss();
            setState(() {
              userTap = false;
            });
            _popInvisiblePurchaseHost(false);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            final data1 = await SharPreferences.getBoolean('startpurches');
            debugPrint("purchase data 5 is $data1");
            if (data1 == true) {
              if (Platform.isIOS) {
                //  var response =
                http.post(
                  Uri.parse(kDebugMode
                      ? 'https://sandbox.itunes.apple.com/verifyReceipt'
                      : 'https://buy.itunes.apple.com/verifyReceipt'),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: {
                    'receipt-data':
                        purchaseDetails.verificationData.localVerificationData,
                    'exclude-old-transactions': true,
                    'password': controller.sharedSecret
                  },
                );

                // DebugConsole.log(
                //     "  purchases sucess frist : ${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()} - ${response.body}");

                // final data = parseHtmlAndExtractJson(response.body);
                await Future.delayed(Duration(seconds: 1));
                // DebugConsole.log(" purchases sucess - $data");
                await purchaseSubmit(
                    receiptData:
                        '${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()}');
                await SharPreferences.setBoolean("downloadreward", true);
                // Additive: remember Buy product across reinstall Restore.
                await _rememberLastIapProduct(purchaseDetails.productID);
                await Future.delayed(Duration(seconds: 1));
                if (_isSixMonthProductId(purchaseDetails.productID)) {
                  await _applySixMonthPremium(controller);
                  DownloadProvider? downloadProvider = _myProvider;
                  downloadProvider ??= context.mounted
                      ? Provider.of<DownloadProvider>(context, listen: false)
                      : null;
                  if (downloadProvider == null) {
                    final getContext = Get.context;
                    if (getContext != null) {
                      downloadProvider = Provider.of<DownloadProvider>(
                          getContext,
                          listen: false);
                    }
                  }
                  if (downloadProvider != null) {
                    await downloadProvider.setSubscriptionPlan('silver');
                  }
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 2");
                  await _navigateAfterNonLifetimePurchaseSuccess();
                  return;
                } else if (_isOneYearProductId(purchaseDetails.productID)) {
                  await controller.disableAd(const Duration(days: 366));
                  DownloadProvider? downloadProvider = _myProvider;
                  downloadProvider ??= context.mounted
                      ? Provider.of<DownloadProvider>(context, listen: false)
                      : null;
                  if (downloadProvider == null) {
                    final getContext = Get.context;
                    if (getContext != null) {
                      downloadProvider = Provider.of<DownloadProvider>(
                          getContext,
                          listen: false);
                    }
                  }
                  if (downloadProvider != null) {
                    await downloadProvider.setSubscriptionPlan('gold');
                  }
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 3 ");
                  await _navigateAfterNonLifetimePurchaseSuccess();
                  return;
                } else if (_isTwoYearProductId(purchaseDetails.productID)) {
                  await controller.disableAd(const Duration(days: 732));
                  DownloadProvider? downloadProvider = _myProvider;
                  downloadProvider ??= context.mounted
                      ? Provider.of<DownloadProvider>(context, listen: false)
                      : null;
                  if (downloadProvider == null) {
                    final getContext = Get.context;
                    if (getContext != null) {
                      downloadProvider = Provider.of<DownloadProvider>(
                          getContext,
                          listen: false);
                    }
                  }
                  if (downloadProvider != null) {
                    await downloadProvider.setSubscriptionPlan('gold');
                  }
                  await Future.delayed(Duration(seconds: 2));
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 3b (2 year)");
                  await _navigateAfterNonLifetimePurchaseSuccess();
                  return;
                } else if (purchaseDetails.productID == widget.lifeTimePlan) {
                  await controller.disableAd(const Duration(days: 3650012345));
                  // Set subscription plan to platinum for lifetime plan
                  DownloadProvider? downloadProvider = _myProvider;
                  if (downloadProvider == null) {
                    // Try to get from Get.context as fallback
                    final getContext = Get.context;
                    if (getContext != null) {
                      downloadProvider = Provider.of<DownloadProvider>(
                          getContext,
                          listen: false);
                    }
                  }
                  if (downloadProvider != null) {
                    await downloadProvider.setSubscriptionPlan('platinum');
                  }
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  await _addLifetimeWalletBonusOnce();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 4 ");
                  await _finishAfterLifetimePurchaseSuccess();
                  return;
                } else {
                  // Check if this is exit offer purchase
                  final exitOfferId =
                      await SharPreferences.getString('exitOfferPlan') ??
                          BibleInfo.exitOfferPlanid;
                  if (purchaseDetails.productID == exitOfferId ||
                      (_exitOfferProduct != null &&
                          purchaseDetails.productID == _exitOfferProduct!.id)) {
                    // Handle exit offer purchase success
                    await controller
                        .disableAd(const Duration(days: 3650012345));
                    // Set subscription plan to platinum for exit offer (lifetime) purchase
                    DownloadProvider? downloadProvider = _myProvider;
                    if (downloadProvider == null) {
                      // Try to get from Get.context as fallback
                      final getContext = Get.context;
                      if (getContext != null) {
                        downloadProvider = Provider.of<DownloadProvider>(
                            getContext,
                            listen: false);
                      }
                    }
                    if (downloadProvider != null) {
                      await downloadProvider.setSubscriptionPlan('platinum');
                    }
                    await Future.delayed(Duration(seconds: 2));
                    // Complete the purchase for iOS - critical to prevent infinite loading
                    if (Platform.isIOS) {
                      await _inAppPurchase.completePurchase(purchaseDetails);
                    }
                    EasyLoading.dismiss();
                    await _addLifetimeWalletBonusOnce();
                    Constants.showToast('Purchase Successful');
                    await SharPreferences.setBoolean('closead', true);
                    debugPrint(
                        "exit offer purchase success - redirecting to home");
                    await _finishAfterLifetimePurchaseSuccess();
                    return;
                  } else {
                    // Fallback: If product ID doesn't match any known plan, treat as lifetime purchase
                    // This ensures loader stops and redirects even for unexpected product IDs
                    debugPrint(
                        "Unknown product ID: ${purchaseDetails.productID}, treating as lifetime purchase");
                    await controller
                        .disableAd(const Duration(days: 3650012345));
                    await Future.delayed(Duration(seconds: 2));
                    // Complete the purchase for iOS - critical to prevent infinite loading
                    if (Platform.isIOS) {
                      await _inAppPurchase.completePurchase(purchaseDetails);
                    }
                    EasyLoading.dismiss();
                    await _addLifetimeWalletBonusOnce();
                    Constants.showToast('Purchase Successful');
                    await SharPreferences.setBoolean('closead', true);
                    debugPrint(
                        "purchase success (fallback) - redirecting to home");
                    await _finishAfterLifetimePurchaseSuccess();
                    return;
                  }
                }
              }
            }
          } else if (purchaseDetails.status == PurchaseStatus.restored) {
            // Additive: keep Restoring… loader while collecting StoreKit products.
            if (!_restoreCollecting) {
              EasyLoading.dismiss();
            }
            final restoreFlag =
                await SharPreferences.getBoolean('restorepurches');
            final startFlag = await SharPreferences.getBoolean('startpurches');
            debugPrint("restore data 5 is $restoreFlag");

            // If Apple reports "restored" during a Buy flow (already subscribed),
            // check if we should show restore dialog first
            if (restoreFlag == true || startFlag == true) {
              // Check if user tapped on a plan they already own (should show dialog)
              if (_shouldShowRestoreDialog &&
                  _pendingRestoreProductId == purchaseDetails.productID) {
                // Show restore dialog instead of auto-restoring
                if (mounted) {
                  await _showRestoreDialogForRestoredPurchase(
                      purchaseDetails, controller);
                }
                // Reset flags
                _shouldShowRestoreDialog = false;
                _pendingRestoreProductId = null;
              } else {
                // Normal restore flow (from restore button)
                if (restoreFlag != true) {
                  await SharPreferences.setBoolean('restorepurches', true);
                }
                // debugPrint("restore data 6 is $data");
                // await restorePurchaseHandle(purchaseDetails.productID,
                //     purchaseDetails.transactionDate ?? '', controller);
                if (mounted) {
                  _handleRestore(purchaseDetails, controller);
                }
              }
            }
          }
        } else if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
          EasyLoading.dismiss();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          EasyLoading.dismiss();
          if (widget.invisiblePurchaseHost) {
            if (mounted) {
              setState(() {
                userTap = false;
              });
              _popInvisiblePurchaseHost(false);
            }
          } else {
            Constants.showToast('Something went wrong');

            // Check if this is the first time showing paywall and user canceled
            await _checkAndShowExitOffer(controller);
          }
        }
      }
    });
  }

  _initialize() async {
    await SharPreferences.setBoolean('closead', false);
    await SharPreferences.setString('OpenAd', '1');
    await SharPreferences.setBoolean('restorepurches', false);
    await SharPreferences.setBoolean('startpurches', false);

    // Provider.of<DownloadProvider>(context, listen: false).disableAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myProvider = Provider.of<DownloadProvider>(context, listen: false);
      _myProvider?.disableAd();
    });
    if (mounted) {
      setState(() {
        isPurchaseLoading = true;
      });
    }

    // Check if preloaded data is available
    final preloadedAvailability =
        PaywallPreloadService.getPreloadedAvailability();
    final preloadedProducts = PaywallPreloadService.getPreloadedProducts();

    final preloadedHasAllSlots = preloadedProducts.isNotEmpty &&
        _cacheHasPaywallSlot(preloadedProducts.map((p) => p.id), 'sixmonth') &&
        _cacheHasPaywallSlot(preloadedProducts.map((p) => p.id), 'oneyear') &&
        (_cacheHasPaywallSlot(preloadedProducts.map((p) => p.id), 'lifetime') ||
            _cacheHasPaywallSlot(preloadedProducts.map((p) => p.id), 'twoyear'));

    if (preloadedAvailability != null &&
        preloadedProducts.isNotEmpty &&
        preloadedHasAllSlots) {
      // Use preloaded data - instant display
      debugPrint('Using preloaded paywall data');
      _isAvailable = preloadedAvailability;
      if (mounted) {
        setState(() {
          _products = List<ProductDetails>.from(preloadedProducts);
          _mergeMissingFallbackPlans();
          isPurchaseLoading = false;
        });
      }
      // Save preloaded products to cache
      final productprovider =
          Provider.of<DownloadProvider>(context, listen: false);
      await productprovider.saveProductList(preloadedProducts.map((iapProduct) {
        return m.ProductDetails(
          id: iapProduct.id,
          title: iapProduct.title,
          description: iapProduct.description,
          price: iapProduct.price,
          rawPrice: iapProduct.rawPrice,
          currencyCode: iapProduct.currencyCode,
          currencySymbol: iapProduct.currencySymbol,
        );
      }).toList());
    } else {
      if (preloadedProducts.isNotEmpty && !preloadedHasAllSlots) {
        debugPrint(
          '⚠️ Preload missing paywall slots — re-querying store for all plans',
        );
      }
      // Fallback to original loading logic if preload not available
      // Check availability of InApp Purchases
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('Is Available: $_isAvailable');
      // perform our async calls only when in-app purchase is available
      if (_isAvailable) {
        await _getUserProducts();
        // _verifyPurchases();

        // listen to new purchases and rebuild the widget whenever
        // there is a new purchase after adding the new purchase to our
        // purchase list

        // If products are still empty after loading, create fallback from constants
        if (_products.isEmpty && mounted) {
          debugPrint(
              '⚠️ Products still empty after load, creating fallback from constants');
          _createFallbackProductsFromConstants();
        }

        if (mounted) {
          setState(() {
            isPurchaseLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isPurchaseLoading = false;
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _applyInitialPlanSelectionIfAny();
      });
    }

    _logPaywallData(source: 'initialize');

    await _autoStartPurchaseIfNeeded();

    if (widget.fromHomeExitOffer && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final ctrl = Get.find<DashBoardController>();
        final offer = await _getExitOfferFromApi(ctrl);
        if (offer != null && mounted) _showExitOfferBottomSheet(offer);
      });
    }
  }

  Future<void> _getUserProducts() async {
    // setState(() {});
    await SharPreferences.setBoolean('closead', false);
    final productprovider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      // Set delegate to null - delegate is optional for querying products
      // Purchase transactions will handle delegate setup separately if needed
      await iosPlatformAddition.setDelegate(null);

      Set<String> ids = _paywallQueryProductIds;
      _lastQueriedProductIds = ids;

      debugPrint("🔍 Querying products - IDs: $ids");
      debugPrint("   App bundle prefix: $_planBundlePrefix");
      debugPrint("📦 Current products empty: ${_products.isEmpty}");

      final datafn = await productprovider.loadProductList();
      debugPrint("💾 Loaded from cache: ${datafn.length} products");

      final datacheck = datafn.map((data) {
        return ProductDetails(
          id: data.id,
          title: data.title,
          description: data.description,
          price: data.price,
          rawPrice: data.rawPrice,
          currencyCode: data.currencyCode,
          currencySymbol: data.currencySymbol,
        );
      }).toList();

      if (_products.isEmpty && datacheck.isEmpty) {
        debugPrint("🔄 Cache is empty, querying from App Store...");
        ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(ids);
        _lastStoreNotFoundIds = response.notFoundIDs.toSet();

        debugPrint("📊 Product Details Response:");
        debugPrint("   - Error: ${response.error}");
        debugPrint("   - Not Found IDs: ${response.notFoundIDs}");
        debugPrint(
            "   - Product Details Count: ${response.productDetails.length}");
        debugPrint(
            "   - Products: ${response.productDetails.map((p) => '${p.id}: ${p.price}').join(', ')}");

        if (response.error != null) {
          debugPrint("❌ Error querying products: ${response.error}");
        }

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
              "⚠️ Products not found in App Store: ${response.notFoundIDs.join(', ')}");
        }

        if (response.productDetails.isEmpty) {
          debugPrint("⚠️ No products returned. This might mean:");
          debugPrint("   1. Products not configured in App Store Connect");
          debugPrint("   2. Products not approved yet");
          debugPrint("   3. Network/Store connectivity issue");
        }

        await Future.delayed(Duration(seconds: 2));

        if (response.productDetails.isNotEmpty) {
          await productprovider
              .saveProductList(response.productDetails.map((iapProduct) {
            return m.ProductDetails(
              id: iapProduct.id,
              title: iapProduct.title,
              description: iapProduct.description,
              price: iapProduct.price,
              rawPrice: iapProduct.rawPrice,
              currencyCode: iapProduct.currencyCode,
              currencySymbol: iapProduct.currencySymbol,
            );
          }).toList());
          setState(() {
            _products = List<ProductDetails>.from(response.productDetails);
            _mergeMissingFallbackPlans();
            debugPrint("✅ Products loaded successfully: ${_products.length}");
          });
        } else {
          debugPrint(
              "⚠️ No products from store, creating fallback products from constants");
          // Create fallback products using constant plan IDs
          _createFallbackProductsFromConstants();
        }
      } else {
        final cachedIds = datafn.map((product) => product.id).toList();
        final missingExpectedPlans =
            !_cacheHasPaywallSlot(cachedIds, 'sixmonth') ||
            !_cacheHasPaywallSlot(cachedIds, 'oneyear') ||
            (!_cacheHasPaywallSlot(cachedIds, 'lifetime') &&
                !_cacheHasPaywallSlot(cachedIds, 'twoyear'));

        if (missingExpectedPlans) {
          debugPrint(
              '🔄 Cache missing expected plans, re-querying from App Store...');
          final response = await _inAppPurchase.queryProductDetails(ids);
          _lastQueriedProductIds = ids;
          _lastStoreNotFoundIds = response.notFoundIDs.toSet();
          if (response.notFoundIDs.isNotEmpty) {
            debugPrint(
                '⚠️ Products not found in App Store: ${response.notFoundIDs.join(', ')}');
          }

          final merged = <String, ProductDetails>{
            for (final product in datacheck) product.id: product,
            for (final product in response.productDetails) product.id: product,
          };

          if (merged.isNotEmpty) {
            await productprovider.saveProductList(merged.values.map((iapProduct) {
              return m.ProductDetails(
                id: iapProduct.id,
                title: iapProduct.title,
                description: iapProduct.description,
                price: iapProduct.price,
                rawPrice: iapProduct.rawPrice,
                currencyCode: iapProduct.currencyCode,
                currencySymbol: iapProduct.currencySymbol,
              );
            }).toList());
            if (mounted) {
              setState(() {
                _products = merged.values.toList();
                _mergeMissingFallbackPlans();
                debugPrint(
                    '✅ Merged cache + store products: ${_products.length}');
              });
            }
          } else {
            _createFallbackProductsFromConstants();
          }
        } else {
          debugPrint("💾 Loading products from cache");
          if (mounted) {
            setState(() {
              _products = List<ProductDetails>.from(datacheck);
              _mergeMissingFallbackPlans();
              debugPrint("✅ Loaded ${_products.length} products from cache");
            });
          }
        }
      }
    }
  }

  List<ProductDetails> _buildAllFallbackProducts() {
    final List<ProductDetails> fallbackProducts = [];

    fallbackProducts.add(ProductDetails(
      id: _resolvedSixMonthPlanId,
      title: '6 Months Premium',
      description: 'Get 6 months of premium access',
      price: '\$9.99',
      rawPrice: 9.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ));

    fallbackProducts.add(ProductDetails(
      id: _resolvedOneYearPlanId,
      title: '1 Year Premium',
      description: 'Get 1 year of premium access',
      price: '\$19.99',
      rawPrice: 19.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ));

    fallbackProducts.add(ProductDetails(
      id: _resolvedLifeTimePlanId,
      title: 'Lifetime Premium',
      description: 'Get lifetime premium access',
      price: '\$24.99',
      rawPrice: 24.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ));

    return fallbackProducts;
  }

  void _applyPaywallProductDisplayFilter() {
    final hasLifetime = _products.any((product) => _isLifetimeProductId(product.id));
    if (hasLifetime) {
      // Show Lifetime instead of 2-Year when Lifetime is available.
      _products.removeWhere((product) => _isTwoYearProductId(product.id));
    }
    // If Lifetime is unavailable, keep 2-Year as the existing third-slot fallback.
    if (selectedindex >= _products.length) {
      selectedindex = _products.length >= 2 ? 1 : 0;
    }
    _sortProducts();
  }

  void _mergeMissingFallbackPlans() {
    _sanitizeStalePaywallProducts();
    final hasSixMonth =
        _products.any((product) => _isSixMonthProductId(product.id));
    final hasOneYear =
        _products.any((product) => _isOneYearProductId(product.id));
    final hasLifetime =
        _products.any((product) => _isLifetimeProductId(product.id));
    final hasTwoYear =
        _products.any((product) => _isTwoYearProductId(product.id));
    for (final fallback in _buildAllFallbackProducts()) {
      if (fallback.id.contains('sixmonth')) {
        if (!hasSixMonth) {
          _products.add(fallback);
        }
        continue;
      }
      if (fallback.id.contains('oneyear')) {
        if (!hasOneYear) {
          _products.add(fallback);
        }
        continue;
      }
      if (fallback.id.contains('lifetime')) {
        if (!hasLifetime && !hasTwoYear) {
          _products.add(fallback);
        }
        continue;
      }
    }
    _sortProducts();
    _applyPaywallProductDisplayFilter();
  }

  void _logPaywallData({required String source}) {
    debugPrint('════════ PAYWALL DATA ($source) ════════');
    debugPrint('IAP available: $_isAvailable');
    debugPrint('checkad: ${widget.checkad}');
    debugPrint('App: ${BibleInfo.bible_shortName}');
    debugPrint('ios_Bundle_Id: ${BibleInfo.ios_Bundle_Id}');
    debugPrint('Plan bundle prefix: $_planBundlePrefix');
    debugPrint('Expected plan IDs: $_expectedPaywallPlanIds');
    debugPrint('Queried store IDs: $_lastQueriedProductIds');
    if (_lastStoreNotFoundIds.isNotEmpty) {
      debugPrint('Store not found IDs: $_lastStoreNotFoundIds');
    }
    debugPrint(
      'Resolved IDs -> 6M: $_resolvedSixMonthPlanId | '
      '1Y: $_resolvedOneYearPlanId | 2Y: $_twoYearPlanId | '
      'LT: $_resolvedLifeTimePlanId',
    );
    debugPrint(
      'Widget plan IDs -> 6M: ${widget.sixMonthPlan} | '
      '1Y: ${widget.oneYearPlan} | LT: ${widget.lifeTimePlan}',
    );
    debugPrint(
      'Constants -> 6M: ${BibleInfo.sixMonthPlanid} | '
      '1Y: ${BibleInfo.oneYearPlanid} | 2Y: ${BibleInfo.twoYearPlanid}',
    );
    debugPrint(
      'Products loaded: ${_products.length} | selectedIndex: $selectedindex',
    );
    if (_products.isEmpty) {
      debugPrint('  (no products)');
    } else {
      for (var i = 0; i < _products.length; i++) {
        final product = _products[i];
        final planLabel = _getPlanTitle(i);
        final slot = _productPlanSlotLabel(product.id);
        final appMatch = _isPaywallProductForThisApp(product.id);
        final expected = _expectedPaywallPlanIds.contains(product.id);
        debugPrint(
          '  [$i] $planLabel | slot=$slot | id=${product.id} | '
          'appMatch=$appMatch | expectedId=$expected | '
          'price=${product.price} | rawPrice=${product.rawPrice} | '
          'currency=${product.currencyCode}',
        );
        if (!appMatch) {
          debugPrint(
            '      ⚠️ STALE: product belongs to another app bundle '
            '(e.g. genevabible cache from a previous install)',
          );
        }
      }
      if (selectedindex >= 0 && selectedindex < _products.length) {
        final selected = _products[selectedindex];
        debugPrint(
          'Selected plan -> ${_getPlanTitle(selectedindex)} | '
          'slot=${_productPlanSlotLabel(selected.id)} | '
          'id=${selected.id} | price=${selected.price}',
        );
      }
    }
    debugPrint('════════════════════════════════════════');
  }

  /// Create fallback products using constant plan IDs when store query fails
  void _createFallbackProductsFromConstants() {
    debugPrint('📦 Creating fallback products from constants...');
    final fallbackProducts = _buildAllFallbackProducts();

    if (fallbackProducts.isNotEmpty && mounted) {
      setState(() {
        _products = fallbackProducts;
        _sortProducts();
        debugPrint(
            '✅ Created ${_products.length} fallback products from constants');
      });
    } else {
      debugPrint('⚠️ Could not create fallback products');
    }
  }

  final controller = Get.isRegistered<DashBoardController>()
      ? Get.find<DashBoardController>()
      : Get.put(DashBoardController());
  @override
  void initState() {
    super.initState();
    // Additive: if opened via a path that skipped openPaywallStacked,
    // leave immediately when dashboard IAP is disabled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_leaveIfDashboardIapDisabled());
    });
    if (!widget.invisiblePurchaseHost) {
      // Track Paywall Screen event
      AnalyticsService.trackPaywallScreen();

      // Mark that paywall is being shown for the first time tracking
      _markPaywallShown();
    }

    _initialize();
    // WidgetsBinding.instance.addObserver(this);
    debugPrint("iap ad - WidgetsBinding");

    _purchaseUpdatedStream = InAppPurchase.instance.purchaseStream;
    _purchaseUpdatedStream.listen(
      (purchases) => _listenToPurchaseUpdated(purchases, controller),
      onDone: () {
        // _subscription?.cancel();
      },
      onError: (error) {
        debugPrint("Purchase Stream Error: $error");
      },
    );

    // Removed auto-show exit offer when coming from home screen
    // Exit offer will now only show when user taps Close icon or "Continue with free version"
    // if (widget.checkad == 'home') {
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     await Future.delayed(const Duration(milliseconds: 1000));
    //     if (mounted) {
    //       await _checkAndShowExitOfferFromHome();
    //     }
    //   });
    // }
    // _loadRewardedAd();
  }

  /// Additive: close / skip paywall when dashboard IAP flag is off.
  Future<void> _leaveIfDashboardIapDisabled() async {
    if (!mounted) return;
    if (await SubscriptionScreen.isDashboardIapEnabled()) return;
    debugPrint(
        'SubscriptionScreen: dashboard IAP disabled — leaving paywall');
    try {
      EasyLoading.dismiss();
    } catch (_) {}
    if (!mounted) return;
    if (widget.checkad == 'onboard') {
      await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
      return;
    }
    if (Get.key.currentState?.canPop() == true ||
        (mounted && Navigator.of(context).canPop())) {
      Get.back();
      return;
    }
    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }

  /// Check and show exit offer when accessed from home screen
  Future<void> _checkAndShowExitOfferFromHome() async {
    try {
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');
      final now = DateTime.now();
      DateTime? firstShownDateTime;

      // Check if 10 minutes have passed
      try {
        if (exitOfferFirstShownTime != null) {
          firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            debugPrint('⏭️ Exit offer time expired (10 minutes passed)');
            return;
          }
        } else {
          // First time access from home: start the 10-minute window
          firstShownDateTime = now;
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', now.toIso8601String());
        }
      } catch (e) {
        debugPrint('Error parsing exit offer timestamp: $e');
        return;
      }

      // Get exit offer from API using instance controller
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null && mounted) {
        debugPrint('✅ Showing exit offer bottom sheet from home screen');
        // Show exit offer bottom sheet
        _showExitOfferBottomSheet(exitOffer);
      } else {
        debugPrint('⚠️ Exit offer not found or widget not mounted');
      }
    } catch (e) {
      debugPrint('Error showing exit offer from home: $e');
    }
  }

  @override
  void dispose() {
    debugPrint("iap ad - dispose");
    if (widget.invisiblePurchaseHost) {
      EasyLoading.dismiss();
    }
    _subscription?.cancel();
    _loadingTimeoutTimer?.cancel(); // Cancel loading timeout timer
    // Reset exit offer flag on dispose
    _isExitOfferShowing = false;
    // Call async clean-up without awaiting
    alldispose();

    super.dispose();
  }

  void alldispose() async {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(null);
      // await _subscription?.cancel();
    }
  }

  double calculateOriginalPrice(
      double discountPercent, double discountedPrice) {
    // Convert the discount percentage to a fraction
    double discountFraction = discountPercent / 100;

    // Calculate the original price using the formula: original price = discounted price / (1 - discount fraction)
    double originalPrice = discountedPrice / (1 - discountFraction);

    return originalPrice;
  }

  //new iap logic

  /// Show restore dialog for restored purchase detected from purchase stream
  Future<void> _showRestoreDialogForRestoredPurchase(
    PurchaseDetails purchaseDetails,
    DashBoardController controller,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "You're Already on this Plan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Would You like to Restore it",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Reset flags
                  _shouldShowRestoreDialog = false;
                  _pendingRestoreProductId = null;
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // Reset flags
                  _shouldShowRestoreDialog = false;
                  _pendingRestoreProductId = null;
                  // Process restore
                  if (mounted) {
                    await restorePurchaseHandle(
                      purchaseDetails.productID,
                      purchaseDetails.transactionDate ?? '',
                      controller,
                      context: context,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CommanColor.lightModePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Yes, Restore",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Handle restored purchases (after pressing restore button)
  Future<void> _handleRestore(
    PurchaseDetails purchaseDetails,
    DashBoardController controller,
  ) async {
    if (!mounted) return;
    debugPrint("Restored Purchase: ${purchaseDetails.productID}");

    // Additive: during Restore-button collection, only queue — apply once later.
    if (_restoreCollecting) {
      _queueRestoreProduct(
        purchaseDetails.productID,
        purchaseDetails.transactionDate ?? '',
      );
      return;
    }

    await restorePurchaseHandle(
      purchaseDetails.productID,
      purchaseDetails.transactionDate ?? '',
      controller,
      context: context,
    );
  }

  /// 🔹 Trigger restore (iOS only)
  Future<void> _restorePurchases(DashBoardController controller) async {
    // Check connectivity FIRST before showing loader
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      _restoreCollecting = false;
      Constants.showToast("No Internet Connection");
      return; // Return early - don't show loader or proceed
    }

    EasyLoading.show(status: "Restoring...");
    _beginRestoreCollection();

    try {
      await _inAppPurchase.restorePurchases();
      await Future.delayed(Duration(seconds: 9));

      // Additive: include API candidate when available (often fails with empty receipt).
      try {
        final res = await restorePurchase();
        if (res != null && res['status'] == 'success') {
          final rawData = res['data'].toString().split('-productId:');
          if (rawData.length == 2) {
            final data = rawData[1].split('-date:');
            final productId = data[0].toString();
            final date = data.length > 1 ? data[1].toString() : '';
            _queueRestoreProduct(productId, date);
          }
        } else {
          debugPrint(
            'Restore API status not success: ${res?['status']} '
            '(using StoreKit collected products)',
          );
        }
      } catch (e) {
        DebugConsole.log("restore API error - $e");
      }

      await _applyBestCollectedRestore(controller);
    } catch (e) {
      _restoreCollecting = false;
      EasyLoading.dismiss();
      DebugConsole.log("restore No active subscription available error - $e");
      Constants.showToast('No active subscription available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // final controller =
    //     Get.put(DashBoardController()); // Initialize controller here
    //final controller = Get.find<DashBoardController>();

    // Move these helper functions outside the builder

    // Setup purchase stream listener once
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   _subscription = _inAppPurchase.purchaseStream.listen((data) {
    //     _listenToPurchaseUpdated(data, controller);
    //     // Use controller update instead of setState
    //     setState(() {
    //       _purchases.addAll(data);
    //       _verifyPurchases();
    //     });
    //   });
    // });

    if (widget.invisiblePurchaseHost) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const SizedBox.shrink(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Exit offer commented out
        // await _checkAndShowExitOfferBeforeClose(controller);
        _navigateAwayFromPaywall();
      },
      child: Scaffold(
        backgroundColor: _paywallCream,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPaywallHeroWithCard(context, size),
                  if (widget.checkad == 'image')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Color(0xFF2D2D3A), size: 24),
                          onPressed: () => _navigateAwayFromPaywall(),
                        ),
                      ),
                    ),
                  _buildPaywallSectionTitle(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isPurchaseLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator.adaptive(),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Please wait...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _buildPaywallPlanRow(controller),
                    ),
                  ),
                  if (!isPurchaseLoading && _products.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                                await SharPreferences.setString('OpenAd', '1');
                                await SharPreferences.setBoolean(
                                    'startpurches', true);
                                _buyProduct(_products[selectedindex]);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFD4894A),
                                Color(0xFFB86B2E),
                                Color(0xFF8B4E1F),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC45A1F)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                            child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Start Growing Today',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.chevron_right,
                                    color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.favorite,
                                size: 13,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                          TextSpan(
                            text:
                                'Join thousands of believers growing closer to God every day',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade400,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildPaywallTrustRow(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      _navigateAwayFromPaywall();
                    },
                    child: const Text(
                      'Continue with Limited Access',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF757575),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _openLegalUrl(
                            'https://bibleoffice.com/terms_conditions.html'),
                        child: const Text(
                          'Terms of Use',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF757575)),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await SharPreferences.setBoolean(
                              'restorepurches', true);
                          await _restorePurchases(controller);
                        },
                        child: const Text(
                          'Restore',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF757575)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openLegalUrl(
                            'https://bibleoffice.com/privacy_policy.html'),
                        child: const Text(
                          'Privacy Policy',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF757575)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          _navigateAwayFromPaywall();
                        },
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF5A5A5A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _paywallGold = Color(0xFF9E7340);
  static const Color _paywallInk = Color(0xFF2D2D3A);
  static const Color _paywallTitleGold = Color(0xFF9E7340);
  static const Color _paywallCream = Color(0xFFFFFBF7);
  static const List<Shadow> _paywallHeroTextShadow = [
    Shadow(
      color: Color(0x59FFFFFF),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  static const TextStyle _paywallHeroHighlightStyle = TextStyle(
    color: _paywallTitleGold,
    fontWeight: FontWeight.w800,
    shadows: _paywallHeroTextShadow,
  );
  static const TextStyle _paywallHeroTitleBaseStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: _paywallInk,
    height: 1.12,
    letterSpacing: -0.3,
    shadows: _paywallHeroTextShadow,
  );
  static const Color _paywallSubtitle = Color(0xFF5C534C);

  static const String _paywallIconPremium = 'assets/paywall_icons/premium.png';
  static const String _paywallIconPray =
      'assets/paywall_icons/praywithguidance.png';
  static const String _paywallIconScripture =
      'assets/paywall_icons/read_scripture.png';
  static const String _paywallIconPeace = 'assets/paywall_icons/finepaeace.png';
  static const String _paywallIconPlant = 'assets/paywall_icons/leaf_icon.png';
  static const String _paywallIconCrown = 'assets/paywall_icons/crown_icon.png';
  static const String _paywallIconLowerCost =
      'assets/paywall_icons/shield_icon.png';
  static const String _paywallHeroBg = 'assets/img.png';

  static const double _kPaywallPremiumBadgeHeight = 52;
  static const double _kPaywallValueIconSlotSize = 56;
  static const double _kPaywallValueIconSize = 48;
  static const double _kPaywallValueIconCircleSize = 42;
  static const Color _paywallPrayIconCircle = Color(0xFFFFF6EB);
  static const Color _paywallScriptureIconCircle = Color(0xFFF0F7EE);
  static const Color _paywallPeaceIconCircle = Color(0xFFFFF1ED);
  static const double _kPaywallPlanIconSize = 80;
  static const double _kPaywallPlanIconPadding = 8;
  static const double _kPaywallLowerCostIconPadding = 4;
  static const double _kPaywallTrustIconSize = 24;
  static const Color _paywallTrustIconColor = Color(0xFF6B6B6B);
  static const double _kPaywallCardOverlap = 94.0;
  static const double _kPaywallValueCardLayoutHeight = 130.0;
  static const double _kPaywallValueCardSectionGap = 30.0;
  static const double _kPlanBottomBannerHeight = 30;
  static const double _kPlanSubtitleBlockHeight = 33;
  static const double _kPlanPriceBlockHeight = 40;

  Widget _buildPaywallHeroWithCard(BuildContext context, Size size) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isCompactHeight = size.height < 750;
    // On smaller devices (e.g. iPhone SE), use a taller hero and less card overlap
    // so the subtitle stays fully visible above the value card.
    final imageHeight = isCompactHeight
        ? (size.height * 0.44).clamp(290.0, 340.0)
        : (size.height * 0.42).clamp(280.0, 340.0);
    final cardOverlap =
        isCompactHeight ? 72.0 : _kPaywallCardOverlap;
    final sectionHeight = imageHeight +
        (_kPaywallValueCardLayoutHeight - cardOverlap) +
        _kPaywallValueCardSectionGap;

    return SizedBox(
      height: sectionHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.14),
                    BlendMode.lighten,
                  ),
                  child: Image.asset(
                    _paywallHeroBg,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8D5C4),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _paywallCream.withOpacity(0.06),
                        _paywallCream.withOpacity(0.22),
                        _paywallCream.withOpacity(0.72),
                        _paywallCream,
                      ],
                      stops: const [0.0, 0.30, 0.64, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topPadding + 40,
                left: 0,
                right: 0,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _paywallCream.withOpacity(0.26),
                        _paywallCream.withOpacity(0.14),
                        _paywallCream.withOpacity(0.03),
                        _paywallCream.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 6),
                    child: Image.asset(
                      _paywallIconPremium,
                      height: _kPaywallPremiumBadgeHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: topPadding + 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.left,
                      text: const TextSpan(
                        style: _paywallHeroTitleBaseStyle,
                        children: [
                          TextSpan(text: 'Grow Closer\n'),
                          TextSpan(text: 'to '),
                          TextSpan(
                            text: 'God',
                            style: _paywallHeroHighlightStyle,
                          ),
                          TextSpan(
                            text: ' Daily',
                            style: _paywallHeroHighlightStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Guidance, prayer, and encouragement\n whenever you need it.',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _paywallSubtitle,
                        fontWeight: FontWeight.w500,
                        shadows: _paywallHeroTextShadow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: imageHeight - cardOverlap,
            child: _buildPaywallValueCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallValueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _paywallValueColumn(
                _paywallIconPray,
                'Pray With Confidence',
                'Support during difficult moments',
                iconCircleColor: _paywallPrayIconCircle,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _paywallValueColumn(
                _paywallIconScripture,
                'Understand Scripture Better',
                'Make God\'s Word easier to apply',
                iconCircleColor: _paywallScriptureIconCircle,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),
            Expanded(
              child: _paywallValueColumn(
                _paywallIconPeace,
                'Find Peace Every Day',
                'Find hope during challenging times',
                iconCircleColor: _paywallPeaceIconCircle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallValueIcon(String iconAsset, Color circleColor) {
    return SizedBox(
      width: _kPaywallValueIconSlotSize,
      height: _kPaywallValueIconSlotSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _kPaywallValueIconCircleSize,
            height: _kPaywallValueIconCircleSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: circleColor.withValues(alpha: 0.85),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          Image.asset(
            iconAsset,
            width: _kPaywallValueIconSize,
            height: _kPaywallValueIconSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.auto_awesome,
              color: _paywallGold,
              size: _kPaywallValueIconSize - 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paywallValueColumn(
    String iconAsset,
    String title,
    String subtitle, {
    Color? iconCircleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          if (iconCircleColor != null)
            _buildPaywallValueIcon(iconAsset, iconCircleColor)
          else
            SizedBox(
              width: _kPaywallValueIconSlotSize,
              height: _kPaywallValueIconSlotSize,
              child: Image.asset(
                iconAsset,
                width: _kPaywallValueIconSlotSize,
                height: _kPaywallValueIconSlotSize,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _paywallInk,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyle(
              fontSize: 9,
              height: 1.3,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              'assets/Line 217.png',
              height: 14,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) =>
                  Divider(color: Colors.grey.shade400),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Choose How You Want to Grow',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _paywallInk,
              ),
            ),
          ),
          Expanded(
            child: Image.asset(
              'assets/Line 216.png',
              height: 14,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) =>
                  Divider(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallPlanRow(DashBoardController controller) {
    if (_products.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_products.length == 1) {
      return _buildPlanCard(0, controller);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _products.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _buildPlanCard(i, controller)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallTrustRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _paywallTrustItem(
              Icons.gpp_good_outlined,
              'Cancel anytime',
              'No commitment',
            ),
          ),
          Expanded(
            child: _paywallTrustItem(
              Icons.lock_outline,
              'Secure payment',
              '100% safe & trusted',
            ),
          ),
          Expanded(
            child: _paywallTrustItem(
              Icons.sync,
              'Restore anytime',
              'Access on all devices',
            ),
          ),
        ],
      ),
    );
  }

  Widget _paywallTrustItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          SizedBox(
            height: _kPaywallTrustIconSize + 4,
            child: Icon(
              icon,
              size: _kPaywallTrustIconSize,
              color: _paywallTrustIconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _paywallInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              height: 1.25,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  double? _fakeOffer(ProductDetails product, DashBoardController controller) {
    if (_isSixMonthProductId(product.id)) {
      return double.tryParse(controller.sixMonthPlanValue ?? '');
    }
    if (_isOneYearProductId(product.id)) {
      final fromApi = double.tryParse(controller.oneYearPlanValue ?? '');
      if (fromApi != null && fromApi > 0) return fromApi;
      return double.tryParse(BibleInfo.oneYearPlanDiscount);
    }
    if (_isTwoYearProductId(product.id)) {
      return double.tryParse(BibleInfo.twoYearPlanDiscount);
    }
    if (_isLifetimeProductId(product.id)) {
      return double.tryParse(controller.lifeTimePlanValue ?? '');
    }
    return null;
  }

  String _getDiscountedPrice(
      ProductDetails product, DashBoardController controller) {
    final fakeOfferPercentage = _fakeOffer(product, controller);
    if (fakeOfferPercentage != null) {
      final fakePrice =
          calculateOriginalPrice(fakeOfferPercentage, product.rawPrice);
      return '${product.currencySymbol}${fakePrice.toStringAsFixed(2)}';
    }
    return '';
  }

  String _getPlanTitle(int index) {
    if (_isSixMonthProductId(_products[index].id)) return '6 Months';
    if (_isOneYearProductId(_products[index].id)) return '1 Year';
    if (_isTwoYearProductId(_products[index].id)) return '2 Years';
    if (_isLifetimeProductId(_products[index].id)) return 'Lifetime';
    return _products[index].description;
  }

  String _getPlanSubtitle(int index) {
    if (_isSixMonthProductId(_products[index].id)) {
      return 'Build Your Faith Habit';
    }
    if (_isOneYearProductId(_products[index].id)) {
      return 'Best for Daily Spiritual Growth';
    }
    if (_isTwoYearProductId(_products[index].id)) {
      return 'Long-term Spiritual Companion';
    }
    if (_isLifetimeProductId(_products[index].id)) {
      return 'Long-term Spiritual Companion';
    }
    return '';
  }

  String get _currentBonusLabel {
    String label = "Get 5,000 Bonus credits with this plan";
    if (_products.isNotEmpty &&
        selectedindex >= 0 &&
        selectedindex < _products.length) {
      final currentId = _products[selectedindex].id;
      if (_isSixMonthProductId(currentId)) {
        label = "Get 500 Bonus credits with this plan";
      } else if (_isOneYearProductId(currentId)) {
        label = "Get 1,000 Bonus credits with this plan";
      } else if (_isLifetimeProductId(currentId)) {
        label = "Get 5,000 Bonus credits with this plan";
      }
    }
    return label;
  }

  String get _currentBonusHighlight {
    String highlight = "5,000 Bonus credits";
    if (_products.isNotEmpty &&
        selectedindex >= 0 &&
        selectedindex < _products.length) {
      final currentId = _products[selectedindex].id;
      if (_isSixMonthProductId(currentId)) {
        highlight = "500 Bonus credits";
      } else if (_isOneYearProductId(currentId)) {
        highlight = "1,000 Bonus credits";
      } else if (_isLifetimeProductId(currentId)) {
        highlight = "5,000 Bonus credits";
      }
    }
    return highlight;
  }

  String? _getBadgeText(int index, DashBoardController controller) {
    final fakeOfferValue = _fakeOffer(_products[index], controller);
    if (_isOneYearProductId(_products[index].id)) {
      if (fakeOfferValue != null && fakeOfferValue > 0) {
        return 'Save ${fakeOfferValue.toStringAsFixed(0)}%';
      }
      return null;
    }
    if (_isTwoYearProductId(_products[index].id)) {
      if (fakeOfferValue != null && fakeOfferValue > 0) {
        return 'Save ${fakeOfferValue.toStringAsFixed(0)}%';
      }
      return 'Best Value';
    }
    if (_isLifetimeProductId(_products[index].id)) {
      return 'Best Value';
    }
    return null;
  }

  String _planBadgeLabel(int index, String? badgeText) {
    if (_isOneYearProductId(_products[index].id)) {
      return 'MOST POPULAR';
    }
    if (_isTwoYearProductId(_products[index].id)) {
      return 'BEST VALUE';
    }
    if (_isLifetimeProductId(_products[index].id)) {
      return 'BEST VALUE';
    }
    return badgeText ?? '';
  }

  String _planCenterIconAsset(int index) {
    if (_isSixMonthProductId(_products[index].id)) {
      return _paywallIconPlant;
    }
    if (_isOneYearProductId(_products[index].id)) {
      return _paywallIconCrown;
    }
    return _paywallIconLowerCost;
  }

  double _planCenterIconPadding(int index) {
    return _planCenterIconAsset(index) == _paywallIconLowerCost
        ? _kPaywallLowerCostIconPadding
        : _kPaywallPlanIconPadding;
  }

  double _planCenterIconInnerSize(int index) {
    final padding = _planCenterIconPadding(index);
    return _kPaywallPlanIconSize - (padding * 2);
  }

  Widget _buildPlanCard(int index, DashBoardController controller) {
    final isSelected = selectedindex == index;
    final discountedPrice = _getDiscountedPrice(_products[index], controller);
    final badgeText = _getBadgeText(index, controller);
    final badgeLabel = _planBadgeLabel(index, badgeText);
    final isSixMonth = _isSixMonthProductId(_products[index].id);
    final isOneYear = _isOneYearProductId(_products[index].id);
    final isTwoYear = _isTwoYearProductId(_products[index].id);
    final isLifetime = _isLifetimeProductId(_products[index].id);
    final isLongTerm = isTwoYear || isLifetime;

    final themedAccent = isOneYear
        ? const Color(0xFF7B1FA2)
        : isLongTerm
            ? const Color(0xFF388E3C)
            : const Color(0xFF5D4037);
    final accent = isSelected ? themedAccent : const Color(0xFF5D4037);
    final bg = isSelected
        ? (isOneYear
            ? const Color(0xFFFAF5FC)
            : isLongTerm
                ? const Color(0xFFF5FBF6)
                : Colors.white)
        : Colors.white;
    final border = isSelected ? themedAccent : Colors.grey.shade300;

    String? bottomBanner;
    if (isTwoYear) {
      bottomBanner = 'LOWEST COST';
    } else if (isSelected && isOneYear && badgeText != null) {
      bottomBanner = badgeText.toUpperCase();
    } else if (isSelected && isLifetime) {
      bottomBanner = 'LOWEST COST';
    }

    final borderWidth = isSelected ? 2.0 : 1.0;
    final hasBadge = badgeLabel.isNotEmpty;
    final bannerAccent = isTwoYear ? themedAccent : accent;

    Widget? badgeWidget;
    if (hasBadge) {
      badgeWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          badgeLabel,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedindex = index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: hasBadge ? Center(child: badgeWidget) : null,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: borderWidth),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 14),
                      child: Column(
                        children: [
                          Text(
                            _getPlanTitle(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSixMonth ? 14 : 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected && !isSixMonth
                                  ? accent
                                  : _paywallInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: _kPlanSubtitleBlockHeight,
                            child: Text(
                              _getPlanSubtitle(index),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.2,
                                color: isSelected && !isSixMonth
                                    ? accent.withValues(alpha: 0.8)
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            _planCenterIconAsset(index),
                            width: _kPaywallPlanIconSize,
                            height: _kPaywallPlanIconSize,
                            fit: BoxFit.contain,
                          ),
                          const Spacer(),
                          SizedBox(
                            height: _kPlanPriceBlockHeight,
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 14,
                                  child: discountedPrice.isNotEmpty
                                      ? Text(
                                          discountedPrice,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 1.1,
                                            color: isSelected
                                                ? accent.withValues(alpha: 0.65)
                                                : Colors.grey.shade500,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        )
                                      : null,
                                ),
                                Text(
                                  _products[index].price,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected && !isSixMonth
                                        ? accent
                                        : _paywallInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: _kPlanBottomBannerHeight,
                    width: double.infinity,
                    child: bottomBanner != null
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: isOneYear
                                  ? themedAccent
                                  : bannerAccent.withValues(alpha: 0.14),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                bottomBanner,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isOneYear ? Colors.white : bannerAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
      String text, List<String> highlightWords, BuildContext context) {
    List<TextSpan> spans = [];
    String remainingText = text;
    final highlightColor = CommanColor.isDarkTheme(context)
        ? Colors.white
        : const Color(0xFF805531);

    while (remainingText.isNotEmpty) {
      int earliestIndex = -1;
      String? foundWord;

      // Find the earliest occurrence of any highlight word
      for (String word in highlightWords) {
        int index = remainingText.toLowerCase().indexOf(word.toLowerCase());
        if (index != -1 && (earliestIndex == -1 || index < earliestIndex)) {
          earliestIndex = index;
          foundWord = word;
        }
      }

      if (earliestIndex == -1) {
        // No more highlights, add remaining text
        spans.add(TextSpan(text: remainingText));
        break;
      } else {
        // Add text before highlight
        if (earliestIndex > 0) {
          spans.add(TextSpan(text: remainingText.substring(0, earliestIndex)));
        }

        // Add highlighted word
        final actualWord = remainingText.substring(
            earliestIndex, earliestIndex + foundWord!.length);
        spans.add(TextSpan(
          text: actualWord,
          style: TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.w700,
          ),
        ));

        // Update remaining text
        remainingText =
            remainingText.substring(earliestIndex + foundWord.length);
      }
    }

    return spans;
  }

  Widget _buildFeatureItem(String image, String text,
      {List<String>? highlightWords}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 50),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(image, width: 28, height: 28), // ✅ use image, not Icon
          const SizedBox(width: 12),
          highlightWords != null && highlightWords.isNotEmpty
              ? RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 14, color: CommanColor.whiteBlack(context)),
                    children:
                        _buildHighlightedText(text, highlightWords, context),
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: CommanColor.whiteBlack(context)),
                ),
        ],
      ),
    );
  }
}

/// Exit Offer Bottom Sheet Content Widget with countdown timer
class _ExitOfferBottomSheetContent extends StatefulWidget {
  final GetAudioModelDataSubFields exitOffer;
  final String lifetimePrice;
  final String originalLifetimePrice;
  final double screenWidth;
  final int initialMinutes;
  final int initialSeconds;
  final VoidCallback onUnlockPremium;
  final VoidCallback onMaybeLater;

  const _ExitOfferBottomSheetContent({
    required this.exitOffer,
    required this.lifetimePrice,
    required this.originalLifetimePrice,
    required this.screenWidth,
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onUnlockPremium,
    required this.onMaybeLater,
  });

  @override
  State<_ExitOfferBottomSheetContent> createState() =>
      _ExitOfferBottomSheetContentState();
}

class _ExitOfferBottomSheetContentState
    extends State<_ExitOfferBottomSheetContent> {
  Timer? _countdownTimer;
  late int _countdownMinutes;
  late int _countdownSeconds;

  @override
  void initState() {
    super.initState();
    _countdownMinutes = widget.initialMinutes;
    _countdownSeconds = widget.initialSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else if (_countdownMinutes > 0) {
            _countdownMinutes--;
            _countdownSeconds = 59;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          false, // Prevent back button dismissal on iPad - user must take action
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: SizedBox(
                  height: widget.screenWidth > 450 ? 160 : 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/paywall-bg.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4E342E),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'LIMITED TIME OFFER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Lifetime Premium',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D2D3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: widget.screenWidth > 450 ? 15 : 14,
                          color: const Color(0xFF2D2D3A),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Unlock every Premium Bible feature. ',
                          ),
                          TextSpan(
                            text: widget.exitOffer.item_2?.contains('%') == true
                                ? widget.exitOffer.item_2!
                                : '30% Off',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7B1FA2),
                            ),
                          ),
                          const TextSpan(text: ' for a limited time.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFCE93D8),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (widget.originalLifetimePrice !=
                                  widget.lifetimePrice &&
                              widget.originalLifetimePrice.isNotEmpty)
                            Text(
                              widget.originalLifetimePrice,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            widget.lifetimePrice,
                            style: TextStyle(
                              fontSize: widget.screenWidth > 450 ? 32 : 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7B1FA2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'One-Time Blessing. Lifetime Access.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time,
                                  size: 15, color: Colors.red.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Offer ends in ${_countdownMinutes.toString().padLeft(2, '0')}:${_countdownSeconds.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          widget.onUnlockPremium();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE07A3A),
                                Color(0xFFC45A1F),
                                Color(0xFF9E4A18),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Start Growing Today',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        widget.onMaybeLater();
                      },
                      child: const Text(
                        'Continue with Limited Access',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
