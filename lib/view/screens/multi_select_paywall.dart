import 'dart:async';

import 'package:biblebookapp/constant/app_api_constant.dart';

import 'package:biblebookapp/controller/dashboard_controller.dart';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';

import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/services/paywall_price_cache.dart';
import 'package:biblebookapp/services/premium_entitlement_label_sync.dart';

import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';

import 'package:biblebookapp/view/constants/share_preferences.dart';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';

import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';

import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';

import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:get/get.dart';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

/// Multi-select paywall UI (Old Paper Irresistible HTML).
/// Product IDs / prices come from the same sources as [SubscriptionScreen].
/// Purchases run through the existing invisible [SubscriptionScreen] host —
/// no changes to that purchase / restore logic.

class MultiSelectPaywall extends StatefulWidget {
  const MultiSelectPaywall({
    super.key,
    required this.sixMonthPlan,
    required this.oneYearPlan,
    required this.lifeTimePlan,
    required this.checkad,
    this.selectLifetime = false,
  });

  final String sixMonthPlan;

  final String oneYearPlan;

  final String lifeTimePlan;

  final String checkad;

  /// Open with the Lifetime card selected (e.g. reading Lifetime prompt).
  final bool selectLifetime;

  @override
  State<MultiSelectPaywall> createState() => _MultiSelectPaywallState();
}

enum _PwCard { ai, lifetime }

enum _AiDur { sixMonth, oneYear }

/// Display-only price load UI (does not change buy / restore).
enum _PriceUiState { loading, retrying, ready, noInternet, unavailable }

class _MultiSelectPaywallState extends State<MultiSelectPaywall> {
  // Old Paper Irresistible paywall palette (UI only — from HTML).
  static const Color _cream = Color(0xFFF4E9D2);
  static const Color _paper = Color(0xFFFBF4E2);
  static const Color _ink = Color(0xFF2B1F13);
  static const Color _soft = Color(0xFF5A4A30);
  static const Color _gold = Color(0xFFB08B3F);
  static const Color _goldDeep = Color(0xFF96712E);
  static const Color _line = Color(0xFFE2D2B2);
  static const Color _selBorder = Color(0xFF9A5A2A);
  static const Color _ctaTop = Color(0xFFC07A3C);
  static const Color _ctaBot = Color(0xFF9A5323);
  static const String _serif = 'Georgia';

  late _PwCard _sel = widget.selectLifetime ? _PwCard.lifetime : _PwCard.ai;

  _AiDur _dur = _AiDur.oneYear;

  /// Exit / win-back sheet (UI only). First ✕ / Continue Free shows it once.
  /// Only during onboarding (`checkad == 'onboard'`), not Paywall Options.
  static const String _exitOfferConsumedPref = 'ms_exit_offer_consumed';

  bool _exitOfferVisible = false;
  bool _exitOfferShownOnce = false;

  bool get _exitOfferEnabled => widget.checkad == 'onboard';

  Future<bool> _shouldShowExitOffer() async {
    if (!_exitOfferEnabled || _exitOfferShownOnce) return false;
    final consumed =
        await SharPreferences.getBoolean(_exitOfferConsumedPref);
    return consumed != true;
  }

  Future<void> _presentExitOffer() async {
    await SharPreferences.setBoolean(_exitOfferConsumedPref, true);
    if (!mounted) return;
    setState(() {
      _exitOfferShownOnce = true;
      _exitOfferVisible = true;
    });
  }

  ProductDetails? _sixMonth;

  ProductDetails? _oneYear;

  ProductDetails? _lifetime;

  bool _loading = true;

  _PriceUiState _priceUi = _PriceUiState.loading;

  String? _cachedMonthPrice;
  String? _cachedYearPrice;
  String? _cachedLifetimePrice;

  String get _resolvedSixMonth => BibleInfo.isAutoRenewablePaywallMode
      ? BibleInfo.arOneMonthPlanid
      : AppApiConstant.resolveSubscriptionProductId(
        widget.sixMonthPlan,
        BibleInfo.sixMonthPlanid,
      );

  String get _resolvedOneYear => BibleInfo.isAutoRenewablePaywallMode
      ? BibleInfo.arOneYearPlanid
      : AppApiConstant.resolveSubscriptionProductId(
        widget.oneYearPlan,
        BibleInfo.oneYearPlanid,
      );

  String get _resolvedLifetime => AppApiConstant.resolveSubscriptionProductId(
        widget.lifeTimePlan,
        BibleInfo.lifeTimePlanid,
      );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_onPaywallOpen());
    });

    _loadProducts();
  }

  Future<void> _onPaywallOpen() async {
    if (!mounted) return;

    if (!await SubscriptionScreen.isDashboardIapEnabled()) {
      await _leaveIfDashboardIapDisabled();

      return;
    }

    await SubscriptionScreen.trackAndMarkVisiblePaywallOpen();

    try {
      Provider.of<DownloadProvider>(context, listen: false).disableAd();
    } catch (_) {}

    await SharPreferences.setBoolean('closead', false);

    await SharPreferences.setString('OpenAd', '1');
  }

  Future<void> _leaveIfDashboardIapDisabled() async {
    if (!mounted) return;

    try {
      EasyLoading.dismiss();
    } catch (_) {}

    await _navigateAwayFromPaywall();
  }

  Future<void> _navigateAwayFromPaywall() async {
    if (!mounted) return;

    try {
      Provider.of<DownloadProvider>(context, listen: false).enableAd();
    } catch (_) {}

    await SharPreferences.setBoolean('closead', true);

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Get.back();

      return;
    }

    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }

  Future<void> _onInvisibleHostFinished(bool success,
      {required bool wasPurchase}) async {
    if (!success || !mounted) return;

    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
    }

    if (!mounted) return;

    if (!wasPurchase) {
      await _navigateAwayFromPaywall();

      return;
    }

    // AR purchase success (incl. onboard): show Premium Unlocked right away,

    // then go Home. Previously onboard skipped unlock and only left the paywall.

    try {
      await EasyLoading.dismiss();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      await EasyLoading.dismiss();
    } catch (_) {}

    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('premiumalrt', '1');
    } catch (_) {}

    if (!mounted) return;

    // Show Premium Unlocked on Home, not on this paywall — closing the
    // dialog here used to reveal the paywall again after a successful buy.
    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);

      await provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }

    if (!mounted) return;

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

  Future<void> _readPriceCaches() async {
    _cachedMonthPrice = await PaywallPriceCache.read(_resolvedSixMonth);
    _cachedYearPrice = await PaywallPriceCache.read(_resolvedOneYear);
    _cachedLifetimePrice = await PaywallPriceCache.read(_resolvedLifetime);
  }

  Future<void> _persistLivePrices() async {
    final six = _sixMonth;
    if (six != null && six.price.isNotEmpty) {
      await PaywallPriceCache.save(six.id, six.price);
      _cachedMonthPrice = six.price;
    }
    final year = _oneYear;
    if (year != null && year.price.isNotEmpty) {
      await PaywallPriceCache.save(year.id, year.price);
      _cachedYearPrice = year.price;
    }
    final life = _lifetime;
    if (life != null && life.price.isNotEmpty) {
      await PaywallPriceCache.save(life.id, life.price);
      _cachedLifetimePrice = life.price;
    }
  }

  bool get _hasCachedDisplayPrices =>
      (_cachedMonthPrice?.isNotEmpty == true) ||
      (_cachedYearPrice?.isNotEmpty == true) ||
      (_cachedLifetimePrice?.isNotEmpty == true);

  bool get _hasLiveOrCachedPrices {
    final monthOk = (_sixMonth?.price.isNotEmpty == true) ||
        (_cachedMonthPrice?.isNotEmpty == true);
    final yearOk = (_oneYear?.price.isNotEmpty == true) ||
        (_cachedYearPrice?.isNotEmpty == true);
    final lifeOk = (_lifetime?.price.isNotEmpty == true) ||
        (_cachedLifetimePrice?.isNotEmpty == true);
    return monthOk || yearOk || lifeOk;
  }

  Future<void> _loadProducts({bool isRetry = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _priceUi =
          isRetry ? _PriceUiState.retrying : _PriceUiState.loading;
    });

    await _readPriceCaches();

    final online = await InternetConnection().hasInternetAccess;
    if (!mounted) return;
    if (!online) {
      if (_hasCachedDisplayPrices) {
        setState(() {
          _loading = false;
          _priceUi = _PriceUiState.ready;
        });
      } else {
        setState(() {
          _loading = false;
          _priceUi = _PriceUiState.noInternet;
        });
      }
      return;
    }

    // Same data path as SubscriptionScreen / PaywallPreloadService.
    ProductDetails? six;
    ProductDetails? year;
    ProductDetails? life;

    void assignFrom(Iterable<ProductDetails> list) {
      for (final p in list) {
        final id = p.id.toLowerCase();
        // Paywall shows AR 1-month in the short slot (not AR 6-month).
        if (six == null &&
            (p.id == _resolvedSixMonth ||
                BibleInfo.isArOneMonthProductId(p.id))) {
          six = p;
        } else if (year == null &&
            (p.id == _resolvedOneYear ||
                BibleInfo.isArOneYearProductId(p.id))) {
          year = p;
        } else if (life == null &&
            (p.id == _resolvedLifetime ||
                (id.contains('lifetime') && !id.contains('exit')))) {
          life = p;
        }
      }
    }

    try {
      var products = PaywallPreloadService.getPreloadedProducts();
      if (products.isEmpty) {
        await PaywallPreloadService.preloadPaywallData()
            .timeout(const Duration(seconds: 10));
        products = PaywallPreloadService.getPreloadedProducts();
      }
      assignFrom(products);

      // Display-only: if a slot is still empty, requery StoreKit using the
      // same constant / resolved product IDs (buy / restore path unchanged).
      if (six == null || year == null || life == null) {
        if (await InAppPurchase.instance.isAvailable()) {
          final ids = <String>{
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedSixMonth),
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedOneYear),
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedLifetime),
          };
          final response = await InAppPurchase.instance
              .queryProductDetails(ids)
              .timeout(const Duration(seconds: 10));
          assignFrom(response.productDetails);
        }
      }
    } catch (e) {
      debugPrint('MultiSelectPaywall: store price load failed: $e');
    }

    if (!mounted) return;

    setState(() {
      _sixMonth = six;
      _oneYear = year;
      _lifetime = life;
      if (_oneYear == null && _sixMonth != null) {
        _dur = _AiDur.sixMonth;
      }
    });

    await _persistLivePrices();
    if (!mounted) return;

    final ready = _hasLiveOrCachedPrices;
    setState(() {
      _loading = false;
      _priceUi = ready ? _PriceUiState.ready : _PriceUiState.unavailable;
    });
  }

  ProductDetails? get _selectedAiProduct =>
      _dur == _AiDur.oneYear ? _oneYear : _sixMonth;

  String get _selectedProductId {
    if (_sel == _PwCard.lifetime) return _resolvedLifetime;

    return _dur == _AiDur.oneYear ? _resolvedOneYear : _resolvedSixMonth;
  }

  /// Slot for SubscriptionScreen: 0=6mo, 1=1yr, 2=lifetime.

  int get _selectedPlanSlot {
    if (_sel == _PwCard.lifetime) return 2;

    return _dur == _AiDur.oneYear ? 1 : 0;
  }

  /// (1 - yearly / (monthly × 12)) × 100 from store prices. Null if unknown.
  int? get _yearSavePercent {
    final monthly = _sixMonth?.rawPrice ?? 0;
    final yearly = _oneYear?.rawPrice ?? 0;
    if (monthly <= 0 || yearly <= 0) return null;
    final percent = (1 - yearly / (monthly * 12)) * 100;
    if (percent <= 0 || percent >= 100) return null;
    return percent.round();
  }

  String get _aiPrice {
    final p = _selectedAiProduct;
    if (p != null && p.price.isNotEmpty) return p.price;
    if (_dur == _AiDur.oneYear) {
      return _cachedYearPrice ?? '';
    }
    return _cachedMonthPrice ?? '';
  }

  String get _lifetimePrice {
    final p = _lifetime;
    if (p != null && p.price.isNotEmpty) return p.price;
    return _cachedLifetimePrice ?? '';
  }

  bool get _canTapPurchase {
    if (_loading || _priceUi != _PriceUiState.ready) return false;
    if (_sel == _PwCard.lifetime) return _lifetimePrice.isNotEmpty;
    return _dur == _AiDur.oneYear
        ? _yearPrice.isNotEmpty
        : _monthPrice.isNotEmpty;
  }

  String get _ctaLabel => _sel == _PwCard.lifetime
      ? 'Unlock Lifetime Access'
      : 'Start My 3-Day Free Trial';

  String get _trustLine => _sel == _PwCard.lifetime
      ? 'One-time payment · Secure checkout'
      : 'No charge today · Cancel anytime';

  String get _monthPrice {
    final p = _sixMonth;
    if (p != null && p.price.isNotEmpty) return p.price;
    return _cachedMonthPrice ?? '';
  }

  String get _yearPrice {
    final p = _oneYear;
    if (p != null && p.price.isNotEmpty) return p.price;
    return _cachedYearPrice ?? '';
  }

  String get _yearAnchor {
    final monthly = _sixMonth?.rawPrice ?? 0;
    if (monthly > 0) {
      final anchor = monthly * 12;
      final symbol = (_sixMonth?.currencySymbol.isNotEmpty == true)
          ? _sixMonth!.currencySymbol
          : '\$';
      return '$symbol${anchor.toStringAsFixed(2)}';
    }
    return '\$71.88';
  }

  String get _headline {
    if (_sel == _PwCard.lifetime) return 'Pay Once. Read Ad-Free.';
    if (_dur == _AiDur.oneYear) return 'A Year of Deeper Faith';
    return 'Go Deeper. Every Day.';
  }

  String get _subhead {
    if (_sel == _PwCard.lifetime) {
      return 'Your reading & study tools, for life.';
    }
    if (_dur == _AiDur.oneYear) {
      return 'Unlimited Bible AI + ad-free reading.';
    }
    return 'One plan. Unlimited Bible AI. No ads.';
  }

  String get _belowCta {
    if (_sel == _PwCard.lifetime) {
      return 'No subscription · Yours on every device you sign in to.';
    }

    if (_dur == _AiDur.oneYear) {
      return 'Then $_aiPrice/year · Auto-renews · Cancel anytime.';
    }

    return 'Then $_aiPrice/month · Auto-renews · Cancel anytime.';
  }

  Future<void> _openLegal(String url) async {
    final uri = Uri.parse(url);
    // Do not gate on canLaunchUrl — on some iPads / iPhone 12 builds it
    // returns false for https and silently no-ops (SE still worked).
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (opened) return;
    } catch (_) {}
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _continueLimited() async {
    if (await _shouldShowExitOffer()) {
      await _presentExitOffer();
      return;
    }
    await _navigateAwayFromPaywall();
  }

  Future<void> _onClose() async {
    // Close exit offer → back to main paywall (leave only on next close).
    if (_exitOfferVisible) {
      if (!mounted) return;
      setState(() => _exitOfferVisible = false);
      return;
    }
    if (await _shouldShowExitOffer()) {
      await _presentExitOffer();
      return;
    }
    await _navigateAwayFromPaywall();
  }

  /// Exit sheet CTA — same yearly purchase path (no new product / pricing logic).
  Future<void> _claimExitGift() async {
    if (!mounted) return;
    setState(() {
      _exitOfferVisible = false;
      _sel = _PwCard.ai;
      _dur = _AiDur.oneYear;
    });
    await _onPrimaryCta();
  }

  String _formatPlanExpiry(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String? _kindFromStoreProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('lifetime')) return 'lifetime';
    if (BibleInfo.isArOneYearProductId(productId) || id.contains('oneyear')) {
      return 'year';
    }
    if (BibleInfo.isOneMonthProductId(productId) ||
        BibleInfo.isArSixMonthProductId(productId) ||
        id.contains('sixmonth')) {
      return 'month';
    }
    return null;
  }

  DateTime? _parseStoreTransactionDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    final numeric = int.tryParse(trimmed);
    if (numeric == null) return null;
    if (numeric > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric);
    }
    if (numeric > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
    }
    return null;
  }

  DateTime? _expiryFromLastPurchase(String kind, DateTime? purchasedAt) {
    if (purchasedAt == null) return null;
    if (kind == 'year') {
      return purchasedAt.add(const Duration(days: 366));
    }
    if (kind == 'month') {
      return purchasedAt.add(const Duration(days: 30));
    }
    return null;
  }

  Future<({String kind, DateTime? purchasedAt})?> _ownedKindFromStore() async {
    StreamSubscription<List<PurchaseDetails>>? sub;
    try {
      final dated = <String, DateTime>{};
      final undated = <String>{};
      sub = InAppPurchase.instance.purchaseStream.listen((purchases) {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.restored ||
              p.status == PurchaseStatus.purchased) {
            final at = _parseStoreTransactionDate(p.transactionDate);
            if (at != null) {
              final prev = dated[p.productID];
              if (prev == null || at.isAfter(prev)) {
                dated[p.productID] = at;
              }
            } else {
              undated.add(p.productID);
            }
          }
          if (p.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(p);
          }
        }
      });
      await InAppPurchase.instance.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      if (dated.isNotEmpty) {
        String? lastId;
        DateTime? lastAt;
        dated.forEach((id, at) {
          if (lastAt == null || at.isAfter(lastAt!)) {
            lastAt = at;
            lastId = id;
          }
        });
        if (lastId != null) {
          final kind = _kindFromStoreProductId(lastId!);
          if (kind != null) {
            return (kind: kind, purchasedAt: lastAt);
          }
        }
      }

      String? kind;
      for (final id in undated) {
        final next = _kindFromStoreProductId(id);
        if (next == 'year') kind = 'year';
        if (next == 'month' && kind != 'year') kind = 'month';
        if (next == 'lifetime' && kind == null) kind = 'lifetime';
      }
      if (kind == null) return null;
      return (kind: kind, purchasedAt: null);
    } catch (_) {
      return null;
    } finally {
      await sub?.cancel();
    }
  }

  Future<String?> _ownedKindFromLastBuy() async {
    try {
      final id = await PremiumEntitlementLabelSync.readLastProductId();
      if (id == null || id.isEmpty) return null;
      final plan = PremiumEntitlementLabelSync.planKeyForProductId(id);
      if (plan == 'platinum') return 'lifetime';
      if (plan == 'gold' || plan == 'twoyear') return 'year';
      if (plan == 'silver') return 'month';
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _ownedActiveKind() async {
    try {
      final download = Provider.of<DownloadProvider>(context, listen: false);
      final plan = (await download.getSubscriptionPlan())?.toLowerCase().trim();
      final raw = await SharPreferences.getString(
        SharPreferences.isRewardAdViewTime,
      );
      DateTime? expiry;
      if (raw != null && raw.isNotEmpty) {
        expiry = DateTime.tryParse(raw);
      }
      final active =
          expiry != null && !expiry.isBefore(DateTime.now());
      if (plan == 'platinum') return 'lifetime';
      if (plan == 'gold') return 'year';
      if (plan == 'silver') return 'month';
      if (active) return 'month';
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _ownedExpiry() async {
    try {
      final raw = await SharPreferences.getString(
        SharPreferences.isRewardAdViewTime,
      );
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  String get _tryingKind {
    if (_sel == _PwCard.lifetime) return 'lifetime';
    return _dur == _AiDur.oneYear ? 'year' : 'month';
  }

  Future<void> _onPrimaryCta() async {
    var owned = await _ownedActiveKind();
    DateTime? storePurchasedAt;
    if (!mounted) return;
    if (owned == null) {
      owned = await _ownedKindFromLastBuy();
    }
    if (!mounted) return;
    if (owned == null) {
      EasyLoading.show(status: 'Please wait...');
      final store = await _ownedKindFromStore();
      owned = store?.kind;
      storePurchasedAt = store?.purchasedAt;
      await EasyLoading.dismiss();
      if (!mounted) return;
    }
    if (owned == null) {
      await _startPurchase();
      return;
    }
    var expiry = await _ownedExpiry();
    if (expiry == null && owned != 'lifetime') {
      expiry = _expiryFromLastPurchase(owned, storePurchasedAt);
    }
    if (!mounted) return;
    final action = await _showAlreadyHavePlanBox(
      ownedKind: owned,
      tryingKind: _tryingKind,
      expiry: expiry,
    );
    if (!mounted) return;
    if (action == 'buy') {
      await _startPurchase();
    } else if (action == 'restore') {
      await _restorePurchases();
    }
  }

  Future<String?> _showAlreadyHavePlanBox({
    required String ownedKind,
    required String tryingKind,
    DateTime? expiry,
  }) {
    final ownedLifetime = ownedKind == 'lifetime';
    final tryingLifetime = tryingKind == 'lifetime';
    final tryingYear = tryingKind == 'year';
    final lastPlanLabel = ownedKind == 'year' ? '1 Year' : '1 Month';
    final expired = expiry != null && expiry.isBefore(DateTime.now());
    final expiryLabel =
        expiry != null ? _formatPlanExpiry(expiry) : null;

    final title = ownedLifetime
        ? 'You Already Own\nLifetime'
        : 'You Already Have\nan Active Plan';
    final String body;
    if (ownedLifetime) {
      body = tryingLifetime
          ? 'You already have Lifetime Ad-Free Study access.'
          : 'You have Lifetime Ad-Free Study access. The AI Premium plan adds Unlimited AI without using credits and will renew automatically ${tryingYear ? 'each year' : 'each month'}.';
    } else if (expired && expiryLabel != null) {
      body =
          'Your last plan was $lastPlanLabel. It expired on $expiryLabel. Purchasing another plan will create an additional charge.';
    } else if (expiryLabel != null) {
      body =
          'Your last $lastPlanLabel plan is currently active until $expiryLabel. Purchasing another plan will create an additional charge.';
    } else {
      body =
          'Your last plan is $lastPlanLabel. Purchasing another plan will create an additional charge.';
    }
    final addLabel = tryingLifetime
        ? 'Add Lifetime Access'
        : (ownedLifetime
            ? 'Add Unlimited AI'
            : (tryingYear ? 'Add 1 Year Plan' : 'Add 1 Month Plan'));
    final showPrice = ownedLifetime && !tryingLifetime;
    final hideAdd = !ownedLifetime || tryingLifetime;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final isTablet = mq.width > 600;
        final addIsLifetime = tryingLifetime;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isTablet ? mq.width * 0.45 : mq.width * 0.85,
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 20,
                isTablet ? 18 : 14,
                isTablet ? 24 : 20,
                isTablet ? 22 : 18,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6EBDD), Color(0xFFEBDDC9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD2C1A8), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(
                        Icons.close,
                        size: isTablet ? 22 : 20,
                        color: const Color(0xFF7B5536),
                      ),
                    ),
                  ),
                  Container(
                    width: isTablet ? 56 : 48,
                    height: isTablet ? 56 : 48,
                    decoration: BoxDecoration(
                      color: ownedLifetime
                          ? const Color(0xFFF6E8C8)
                          : const Color(0xFFE7DEFA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ownedLifetime
                          ? Icons.diamond_outlined
                          : Icons.calendar_today_outlined,
                      size: isTablet ? 26 : 22,
                      color: ownedLifetime
                          ? const Color(0xFFB07A1E)
                          : const Color(0xFF5B3FBF),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: const Color(0xFF101B2B),
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5C534C),
                    ),
                  ),
                  if (!ownedLifetime && expiryLabel != null) ...[
                    SizedBox(height: isTablet ? 10 : 8),
                    Text(
                      expired
                          ? 'Expired on $expiryLabel'
                          : 'Expires on $expiryLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101B2B),
                      ),
                    ),
                  ],
                  SizedBox(height: isTablet ? 22 : 18),
                  if (!hideAdd) ...[
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 52 : 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: addIsLifetime
                                ? const [Color(0xFF2E9457), Color(0xFF166438)]
                                : const [Color(0xFFC08D22), Color(0xFF8E5F10)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop('buy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            addLabel,
                            style: TextStyle(
                              fontSize: isTablet ? 17 : 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 10 : 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 52 : 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop('restore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F2EA),
                        foregroundColor: const Color(0xFF5B3FBF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Restore My Current Plan',
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5B3FBF),
                        ),
                      ),
                    ),
                  ),
                  if (showPrice) ...[
                    SizedBox(height: isTablet ? 12 : 10),
                    Text(
                      _belowCta,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        color: const Color(0xFF5B3FBF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Purchase via existing invisible SubscriptionScreen (unchanged IAP logic).

  Future<void> _startPurchase() async {
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;

    if (!mounted) return;

    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: _resolvedSixMonth,
          oneYearPlan: _resolvedOneYear,
          lifeTimePlan: _resolvedLifetime,
          checkad: widget.checkad,
          initialSelectedPlanIndex: _selectedPlanSlot,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );

      if (!mounted) return;
    if (ok == true) {
      await _onInvisibleHostFinished(true, wasPurchase: true);
      return;
    }
    // 1 Month host sometimes pops without true after a successful write.
    try {
      final raw = await SharPreferences.getString(
        SharPreferences.isRewardAdViewTime,
      );
      if (raw != null &&
          raw.isNotEmpty &&
          DateTime.parse(raw).isAfter(DateTime.now()) &&
          mounted) {
        await _onInvisibleHostFinished(true, wasPurchase: true);
      }
    } catch (_) {}
  }

  Future<void> _restorePurchases() async {
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;

    if (!mounted) return;

    EasyLoading.show(status: "Restoring...");

    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: _resolvedSixMonth,
          oneYearPlan: _resolvedOneYear,
          lifeTimePlan: _resolvedLifetime,
      checkad: widget.checkad,
          invisiblePurchaseHost: true,
          autoStartRestore: true,
        ),
      ),
    );

    if (ok == true && mounted) {
      await _onInvisibleHostFinished(true, wasPurchase: false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w > 600;
    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 22.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onClose();
      },
      child: Scaffold(
        backgroundColor: _cream,
        body: Stack(
          children: [
            // Paper texture feel (UI only).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _cream,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _cream.withValues(alpha: 0.95),
                      _cream,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.paddingOf(context).top + 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: _onClose,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: const Color(0xFF6B5A44),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildAppIconHeader(isTablet),
                        const SizedBox(height: 8),
                        Text(
                          _headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _serif,
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 28 : 24,
                            height: 1.08,
                            letterSpacing: -0.3,
                            color: const Color(0xFF241A0F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subhead,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: _soft,
                          ),
                        ),
                        const SizedBox(height: 11),
                        _buildBenefits(isTablet),
                        const SizedBox(height: 11),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFFE2D2B2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        _buildConfidence(isTablet),
                        const SizedBox(height: 14),
                        _buildReassure(isTablet),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildFooter(isTablet, w),
              ],
            ),
            if (_exitOfferVisible) _buildExitOffer(isTablet),
            if (_priceUi != _PriceUiState.ready) _buildPriceStatusOverlay(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStatusOverlay(bool isTablet) {
    final loading = _priceUi == _PriceUiState.loading ||
        _priceUi == _PriceUiState.retrying;
    final noNet = _priceUi == _PriceUiState.noInternet;
    final title = loading
        ? (_priceUi == _PriceUiState.retrying
            ? 'Retrying...'
            : 'Getting your price...')
        : (noNet ? 'No Internet Connection' : 'Price unavailable');
    final body = loading
        ? (_priceUi == _PriceUiState.retrying
            ? 'Getting your price again...'
            : 'Please wait a moment')
        : (noNet
            ? 'Please check your internet connection and try again.'
            : "We couldn't load the purchase price. This may be a temporary issue. Please try again.");

    return Positioned.fill(
      child: ColoredBox(
        color: _cream.withValues(alpha: 0.97),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: _onClose,
                    icon: const Icon(Icons.close, color: Color(0xFF6B5A44)),
                  ),
                ),
                const Spacer(),
                Container(
                  width: isTablet ? 72 : 64,
                  height: isTablet ? 72 : 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: loading
                        ? const Color(0xFFEFE3C8)
                        : const Color(0xFFF6E6DF),
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF9A5323),
                          ),
                        )
                      : Icon(
                          noNet ? Icons.wifi_off_rounded : Icons.error_outline,
                          size: 32,
                          color: const Color(0xFFA8502F),
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _serif,
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 24 : 22,
                    color: const Color(0xFF241A0F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: loading ? FontStyle.italic : FontStyle.normal,
                    color: _soft,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                if (loading)
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9C7A8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Loading price...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _serif,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF6B5A44),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_ctaTop, _ctaBot],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _loadProducts(isRetry: true),
                        icon: const Icon(Icons.refresh_rounded,
                            color: Color(0xFFFFF6EA)),
                        label: Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: _serif,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFFFFF6EA),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(flex: 2),
                Text(
                  'Terms  ·  Restore  ·  Privacy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _soft.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIconHeader(bool isTablet) {
    return Column(
      children: [
        Container(
          width: isTablet ? 88 : 78,
          height: isTablet ? 88 : 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0x8050320F),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/Icon-1024.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: const Color(0xFFE8D5C4),
              child: Icon(Icons.menu_book, size: 36, color: _goldDeep),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFB6945A)],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'PREMIUM',
              style: TextStyle(
                fontFamily: _serif,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.5,
                fontSize: isTablet ? 13.5 : 12.5,
                color: const Color(0xFF9A7430),
              ),
            ),
            const SizedBox(width: 9),
            Container(
              width: 34,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB6945A), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<(IconData, String)> get _benefitRows {
    if (_sel == _PwCard.lifetime) {
      return const [
        (Icons.block, 'Remove ads permanently'),
        (Icons.bookmark_border, 'Keep highlights, notes & bookmarks'),
        (Icons.layers_outlined, 'Explore Connection Paths'),
        (Icons.payments_outlined, '5,000 AI credits (~250 AI chats)'),
      ];
    }
    return const [
      (Icons.chat_bubble_outline, 'Ask unlimited Bible questions'),
      (Icons.menu_book_outlined, 'Understand any verse or chapter'),
      (Icons.favorite_border, 'Create personal prayers with AI'),
      (Icons.layers_outlined, 'Read ad-free & follow Connection Paths'),
    ];
  }

  Widget _buildBenefits(bool isTablet) {
    return Column(
      children: [
        for (final row in _benefitRows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.$1, size: isTablet ? 26 : 25, color: const Color(0xFF6B5A44)),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: const Color(0xFF2E2214),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidence(bool isTablet) {
    if (_sel == _PwCard.lifetime) {
      return _confidenceLine(
        icon: Icons.all_inclusive,
        text: 'One payment, yours forever. No subscription, no recurring fees.',
        isTablet: isTablet,
      );
    }
    if (_dur == _AiDur.oneYear) {
      final save = _yearSavePercent;
      final saveText = save != null
          ? 'That\'s $save% off paying monthly — our most popular plan'
          : 'That\'s 44% off paying monthly — our most popular plan';
      final monthly = _sixMonth?.rawPrice ?? 0;
      final yearly = _oneYear?.rawPrice ?? 0;
      String saveAmount = '\$31.89';
      if (monthly > 0 && yearly > 0) {
        final diff = (monthly * 12) - yearly;
        if (diff > 0) {
          final symbol = (_oneYear?.currencySymbol.isNotEmpty == true)
              ? _oneYear!.currencySymbol
              : '\$';
          saveAmount = '$symbol${diff.toStringAsFixed(2)}';
        }
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBF1D8), Color(0xFFF6E9C9)],
          ),
          boxShadow: [
            BoxShadow(
              color: _goldDeep.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'You save $saveAmount a year',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _serif,
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 17 : 15.5,
                color: const Color(0xFF7A5A1E),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              saveText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 12.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5A4A2E),
              ),
            ),
          ],
        ),
      );
    }
    return _confidenceLine(
      icon: Icons.spa_outlined,
      text: 'All AI features included. Flexible — month to month.',
      isTablet: isTablet,
    );
  }

  Widget _confidenceLine({
    required IconData icon,
    required String text,
    required bool isTablet,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7A9B6A)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 13.5 : 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: _soft,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReassure(bool isTablet) {
    final lifetime = _sel == _PwCard.lifetime;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            lifetime ? Icons.all_inclusive : Icons.notifications_none_rounded,
            size: 16,
            color: _goldDeep,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              lifetime
                  ? 'Instant lifetime access — pay once, keep it forever.'
                  : "We'll remind you before your free trial ends.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: const Color(0xFF4F4026),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required bool selected,
    required bool recommended,
    required String name,
    required String price,
    String? anchor,
    String? badge,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    // Fixed equal size for all three cards (match 1 Year footprint).
    final cardH = isTablet ? 130.0 : 120.0;

    Widget badgeChip(String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: LinearGradient(
            colors: label.contains('BEST')
                ? const [Color(0xFFEAC877), Color(0xFFA9792B)]
                : const [Color(0xFF9676CF), Color(0xFF6C50A6)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 10 : 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: cardH,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? _selBorder
                          : (recommended ? const Color(0xFFD9B56A) : _line),
                      width: 1.7,
                    ),
                    gradient: recommended
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: selected
                                ? const [Color(0xFFFFFDF6), Color(0xFFFBF2DC)]
                                : const [Color(0xFFFCF4DD), Color(0xFFF7EBCB)],
                          )
                        : null,
                    color: recommended
                        ? null
                        : (selected ? Colors.white : _paper),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _selBorder.withValues(alpha: 0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _serif,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 18 : 17,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 15,
                        child: anchor == null
                            ? const SizedBox.shrink()
                            : Text(
                                anchor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA9966F),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                      ),
                      Text(
                        price,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 13.5 : 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B5A44),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? _selBorder
                                : const Color(0xFFC4B084),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9A5A2A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -10,
                  child: badgeChip(badge),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet, double w) {
    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 22.0;
    final save = _yearSavePercent;
    final saveBadge = save != null ? 'SAVE $save%' : 'SAVE 44%';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanCard(
                  selected: _sel == _PwCard.ai && _dur == _AiDur.sixMonth,
                  recommended: false,
                  name: '1 Month',
                  price: '$_monthPrice / mo',
                  onTap: () => setState(() {
                    _sel = _PwCard.ai;
                    _dur = _AiDur.sixMonth;
                  }),
                  isTablet: isTablet,
                ),
                const SizedBox(width: 9),
                _buildPlanCard(
                  selected: _sel == _PwCard.ai && _dur == _AiDur.oneYear,
                  recommended: true,
                  name: '1 Year',
                  price: '$_yearPrice / yr',
                  anchor: _yearAnchor,
                  badge: saveBadge,
                  onTap: () => setState(() {
                    _sel = _PwCard.ai;
                    _dur = _AiDur.oneYear;
                  }),
                  isTablet: isTablet,
                ),
                const SizedBox(width: 9),
                _buildPlanCard(
                  selected: _sel == _PwCard.lifetime,
                  recommended: false,
                  name: 'Lifetime',
                  price: '$_lifetimePrice once',
                  badge: 'BEST VALUE',
                  onTap: () => setState(() => _sel = _PwCard.lifetime),
                  isTablet: isTablet,
                ),
              ],
            ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_ctaTop, _ctaBot],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _ctaBot.withValues(alpha: 0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _canTapPurchase ? _onPrimaryCta : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 17 : 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _ctaLabel,
                    style: TextStyle(
                      fontFamily: _serif,
                      fontSize: isTablet ? 19 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFF6EA),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 15, color: Color(0xFF6B5A44)),
                const SizedBox(width: 7),
                Text(
                  _trustLine,
                  style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: _soft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: _continueLimited,
              child: Text(
                'Continue Free Version',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2214),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF2E2214),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegalRow(isTablet: isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalRow({bool isTablet = false}) {
    Widget link(String label, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 6 : 4,
            vertical: isTablet ? 8 : 6,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B5A44),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF6B5A44),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link('Restore Purchases', _restorePurchases),
        Text(' · ',
            style: TextStyle(
                fontSize: isTablet ? 12 : 11, color: const Color(0xFF6B5A44))),
        link(
          'Terms',
          () => _openLegal('https://bibleoffice.com/terms_conditions.html'),
        ),
        Text(' · ',
            style: TextStyle(
                fontSize: isTablet ? 12 : 11, color: const Color(0xFF6B5A44))),
        link(
          'Privacy',
          () => _openLegal('https://bibleoffice.com/privacy_policy.html'),
        ),
      ],
    );
  }

  Widget _buildExitOffer(bool isTablet) {
    return Positioned.fill(
      child: Material(
        color: _cream.withValues(alpha: 0.98),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _exitOfferVisible = false);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF3A2B18)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(0, -0.3),
                            colors: [Color(0xFFFBEFCF), Color(0xFFEEDBA6)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldDeep.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(
                            'assets/dove.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '✦ ONE-TIME OFFER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: _goldDeep,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: _serif,
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 32 : 28,
                            height: 1.1,
                            color: const Color(0xFF241A0F),
                          ),
                          children: const [
                            TextSpan(text: 'Wait — a '),
                            TextSpan(
                              text: 'gift',
                              style: TextStyle(color: Color(0xFF9A5323)),
                            ),
                            TextSpan(text: '\nbefore you go'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        "We'd love for you to keep growing in the Word. Here's a gift to begin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: _soft,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gold, width: 2),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFFBF2), Color(0xFFF8EFD6)],
                          ),
                        ),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFB5712E), Color(0xFFC9A35A)],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/offer/gift.png',
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                        Icons.card_giftcard,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'A GIFT TO BEGIN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              '1 Year Premium · Unlimited AI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _serif,
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 19 : 18,
                                color: const Color(0xFF241A0F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Original (anchor) struck + real yearly StoreKit price.
                            Text(
                              _yearAnchor,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA9966F),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$_yearPrice',
                                    style: TextStyle(
                                      fontFamily: _serif,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF9A5323),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' / year',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B5A44),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_yearPrice/year · auto-renews · cancel anytime',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B5A44),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: const [
                                _ExitChip('✓ Unlimited AI'),
                                _ExitChip('✓ Ad-free'),
                                _ExitChip('✓ All features'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(isTablet ? 40 : 24, 0, isTablet ? 40 : 24, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_ctaTop, _ctaBot],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: _claimExitGift,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Claim My Gift ›',
                            style: TextStyle(
                              fontFamily: _serif,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFF6EA),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '$_yearPrice/year · auto-renews · cancel anytime',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A6A4E),
                      ),
                    ),
                    const SizedBox(height: 11),
                    GestureDetector(
                      onTap: () {
                        setState(() => _exitOfferVisible = false);
                      },
                      child: const Text(
                        'No thanks, continue with limited access',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B5A44),
                          decoration: TextDecoration.underline,
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

class _ExitChip extends StatelessWidget {
  const _ExitChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1E3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F6A45),
        ),
      ),
    );
  }
}


class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.color});

  final bool selected;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : const Color(0xFFCDBF9F),
          width: 2,
        ),
      ),
      child: selected
          ? const Text(
              '✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            )
          : null,
    );
  }
}

class _SaveFiftyBadge extends StatefulWidget {
  const _SaveFiftyBadge({required this.isTablet, required this.percent});

  final bool isTablet;
  final int percent;

  @override
  State<_SaveFiftyBadge> createState() => _SaveFiftyBadgeState();
}

class _SaveFiftyBadgeState extends State<_SaveFiftyBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 10,
          vertical: isTablet ? 7 : 6,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB703), Color(0xFFFF5A1F)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Save ${widget.percent}%',
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DurChip extends StatelessWidget {
  const _DurChip({
    required this.selected,
    required this.label,
    required this.price,
    required this.caption,
    required this.onTap,
    required this.captionColor,
  });

  final bool selected;

  final String label;

  final String price;

  final String caption;

  final Color captionColor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          isTablet ? 14 : 12,
          isTablet ? 18 : 16,
          isTablet ? 12 : 10,
          isTablet ? 18 : 16,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF6D4AFF)
                : const Color(0xFFE6E1F2),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: selected
                  ? Container(
                      width: isTablet ? 24 : 22,
                      height: isTablet ? 24 : 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B3FBF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: isTablet ? 16 : 14,
                      ),
                    )
                  : Container(
                      width: isTablet ? 24 : 22,
                      height: isTablet ? 24 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD5D3DE),
                          width: 1.6,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: isTablet ? 10 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1440),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: const Color(0xFF1B1440),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      fontWeight: FontWeight.w500,
                      color: captionColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestValueCardShine extends StatefulWidget {
  const _BestValueCardShine();

  @override
  State<_BestValueCardShine> createState() => _BestValueCardShineState();
}

class _BestValueCardShineState extends State<_BestValueCardShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(
          ((_controller.value - 0.12) / 0.38).clamp(0.0, 1.0),
        );
        return Align(
          alignment: Alignment(-1.4 + (t * 2.8), 0),
          child: Transform.rotate(
            angle: -0.55,
            child: Container(
              width: 56,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.34),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
