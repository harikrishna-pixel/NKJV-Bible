import 'dart:async';

import 'package:biblebookapp/constant/app_api_constant.dart';

import 'package:biblebookapp/controller/dashboard_controller.dart';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';

import 'package:biblebookapp/services/paywall_preload_service.dart';
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

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

/// Multi-select paywall matching OldPaper Design B (PAYWALL v8 APPROVED).

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
  });

  final String sixMonthPlan;

  final String oneYearPlan;

  final String lifeTimePlan;

  final String checkad;

  @override
  State<MultiSelectPaywall> createState() => _MultiSelectPaywallState();
}

enum _PwCard { ai, lifetime }

enum _AiDur { sixMonth, oneYear }

class _MultiSelectPaywallState extends State<MultiSelectPaywall> {
  // OldPaper v8 Design B palette (UI only).

  static const Color _cream = Color(0xFFEFE6D8);

  static const Color _paper = Color(0xFFFDFBF6);

  static const Color _ink = Color(0xFF101B2B);

  static const Color _line = Color(0xFFE2D6C0);

  static const Color _purple = Color(0xFF5B3FBF);

  static const Color _green = Color(0xFF1E7A45);

  static const Color _greenSoft = Color(0xFFDCEFE3);

  _PwCard _sel = _PwCard.ai;

  _AiDur _dur = _AiDur.oneYear;

  ProductDetails? _sixMonth;

  ProductDetails? _oneYear;

  ProductDetails? _lifetime;

  bool _loading = true;

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

  Future<void> _loadProducts() async {
    // Same data path as SubscriptionScreen / PaywallPreloadService.

    var products = PaywallPreloadService.getPreloadedProducts();

    if (products.isEmpty) {
      await PaywallPreloadService.preloadPaywallData();

      products = PaywallPreloadService.getPreloadedProducts();
    }

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

    assignFrom(products);

    // Display-only: if a slot is still empty, requery StoreKit using the

    // same constant / resolved product IDs (buy / restore path unchanged).

    if (six == null || year == null || life == null) {
      try {
        if (await InAppPurchase.instance.isAvailable()) {
          final ids = <String>{
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedSixMonth),
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedOneYear),
            ...AppApiConstant.subscriptionProductIdQueryVariants(
                _resolvedLifetime),
          };

          final response =
              await InAppPurchase.instance.queryProductDetails(ids);

          assignFrom(response.productDetails);
        }
      } catch (e) {
        debugPrint('MultiSelectPaywall: store requery failed: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _sixMonth = six;

      _oneYear = year;

      _lifetime = life;

      _loading = false;

      if (_oneYear == null && _sixMonth != null) {
        _dur = _AiDur.sixMonth;
      }
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

  String get _aiPrice {
    final p = _selectedAiProduct;

    if (p != null && p.price.isNotEmpty) return p.price;

    // Existing fallback when StoreKit product is not bound yet.

    return _dur == _AiDur.oneYear ? '\$59.99' : '\$34.99';
  }

  String get _lifetimePrice {
    final p = _lifetime;

    if (p != null && p.price.isNotEmpty) return p.price;

    // Existing fallback when StoreKit product is not bound yet.

    return '\$79.99';
  }

  String get _ctaLabel => _sel == _PwCard.lifetime
      ? 'Get Lifetime Access →'
      : 'Start My 3-Day Free Trial →';

  String get _aboveCta => _sel == _PwCard.lifetime
      ? 'One payment today. Yours from here on.'
      : "You won't be charged anything today.";

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

    if (!await canLaunchUrl(uri)) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _continueLimited() async {
    await _navigateAwayFromPaywall();
  }

  Future<void> _onClose() async {
    await _navigateAwayFromPaywall();
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

    // Tablet reference uses wider content (~8% inset); phone matches v8 16.

    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 16.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await _navigateAwayFromPaywall();
      },
      child: Scaffold(
      backgroundColor: _cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHero(isTablet),
                  Padding(
                      // UI only: a little space between benefits → AI Premium.

                    padding: EdgeInsets.fromLTRB(
                          hPad, isTablet ? 12 : 10, hPad, 0),

                    child: Column(
                      children: [
                        _buildAiCard(isTablet),
                          SizedBox(height: isTablet ? 12 : 9),
                        _buildLifetimeCard(isTablet),
                      ],
                    ),
                  ),
                    SizedBox(height: isTablet ? 6 : 4),
                ],
              ),
            ),
          ),
          _buildFooter(isTablet, w),
        ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isTablet) {
    // Restored pre-v8 hero: full scenic img + text overlay positions (UI only).

    const paywallInk = Color(0xFF2D2D3A);

    const paywallTitleGold = Color(0xFF9E7340);

    const paywallCream = Color(0xFFFFFBF7);

    const paywallSubtitle = Color(0xFF5C534C);

    const heroShadows = <Shadow>[
      Shadow(
        color: Color(0x59FFFFFF),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ];

    final size = MediaQuery.sizeOf(context);

    final topPadding = MediaQuery.paddingOf(context).top;

    final isCompactHeight = size.height < 750;

    // Tablet: taller hero so scenic bg shows fully; phone unchanged.

    final imageHeight = isTablet
        ? (size.height * 0.46).clamp(380.0, 520.0)
        : isCompactHeight
            ? (size.height * 0.44).clamp(290.0, 340.0)
            : (size.height * 0.42).clamp(280.0, 340.0);

    // Compact benefits: pull box up toward subtitle (UI only).

    final cardLayoutHeight = isTablet ? 104.0 : 86.0;

    final cardOverlap = isTablet
        ? 88.0
        : isCompactHeight
            ? 72.0
            : 84.0;

    final sectionHeight = imageHeight + (cardLayoutHeight - cardOverlap) + 4.0;

    final heroSidePad = isTablet ? (size.width * 0.08).clamp(36.0, 64.0) : 16.0;

    return SizedBox(
      width: double.infinity,
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
                  child: ColoredBox(
                    color: paywallCream,
                    child: isTablet
                        ? Image.asset(
                            'assets/img.png',
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            width: double.infinity,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE8D5C4),
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: 0.14),
                              BlendMode.lighten,
                            ),
            child: Image.asset(
                              'assets/img.png',
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
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isTablet
                            ? [
                                paywallCream.withValues(alpha: 0.0),
                                paywallCream.withValues(alpha: 0.04),
                                paywallCream.withValues(alpha: 0.35),
                                paywallCream,
                              ]
                            : [
                                paywallCream.withValues(alpha: 0.06),
                                paywallCream.withValues(alpha: 0.22),
                                paywallCream.withValues(alpha: 0.72),
                                paywallCream,
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
                    height: isTablet ? 100 : 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                  colors: [
                          paywallCream.withValues(
                              alpha: isTablet ? 0.10 : 0.26),
                          paywallCream.withValues(
                              alpha: isTablet ? 0.04 : 0.14),
                          paywallCream.withValues(alpha: 0.03),
                          paywallCream.withValues(alpha: 0.0),
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
                      padding: EdgeInsets.only(
                          left: heroSidePad, top: isTablet ? 8 : 6),
                      child: Row(
                        children: [
                          // iPad: PREMIUM sits with title (centered left).

                          // Phone: badge stays top-left (unchanged).

                          if (!isTablet)
                            Image.asset(
                              'assets/paywall_icons/premium.png',
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),

                          const Spacer(),

                          Padding(
                            padding: EdgeInsets.only(right: isTablet ? 16 : 12),
                            child: Material(
                              // UI only: lightly visible close (readable, not heavy).

                              color: Colors.white.withValues(alpha: 0.52),

                              elevation: 0,

                              shadowColor: Colors.transparent,

                              shape: const CircleBorder(),

                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _onClose,
                                child: SizedBox(
                                  width: isTablet ? 30 : 26,
                                  height: isTablet ? 30 : 26,
                                  child: Center(
                                    child: Icon(
                                      Icons.close,
                                      size: isTablet ? 15 : 14,
                                      color: const Color(0xFF3A2B18)
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isTablet)
                  Positioned(
                    left: heroSidePad,

                    // Keep copy on the left side of the scenic hero.

                    right: size.width * 0.40,

                    top: topPadding + 20,

                    bottom: (imageHeight * 0.22).clamp(80.0, 140.0),

                    child: Align(
                      // iPad UI only: vertically center on left side of hero.

                      alignment: Alignment.centerLeft,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                children: [
                          Image.asset(
                            'assets/paywall_icons/premium.png',
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: paywallInk,
                                height: 1.12,
                                letterSpacing: -0.3,
                                shadows: heroShadows,
                              ),
                              children: [
                                const TextSpan(text: 'Grow Closer\n'),
                                const TextSpan(text: 'to '),
                                TextSpan(
                                  text: 'God',
                          style: TextStyle(
                                    fontFamily: 'Georgia',
                                    color: paywallTitleGold,
                            fontWeight: FontWeight.w800,
                                    shadows: heroShadows,
                                  ),
                                ),
                                TextSpan(
                                  text: ' Daily',
                                style: TextStyle(
                                    fontFamily: 'Georgia',
                                    color: paywallTitleGold,
                                    fontWeight: FontWeight.w800,
                                    shadows: heroShadows,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Guidance, prayer, and encouragement\n whenever you need it.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 16.5,
                              height: 1.4,
                              color: paywallSubtitle,
                              fontWeight: FontWeight.w500,
                              shadows: heroShadows,
                        ),
                      ),
                    ],
                  ),
                    ),
                  )
                else
                  Positioned(
                    left: heroSidePad,
                    right: heroSidePad,
                    top: topPadding + 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: paywallInk,
                              height: 1.12,
                              letterSpacing: -0.3,
                              shadows: heroShadows,
                            ),
                            children: [
                              const TextSpan(text: 'Grow Closer\n'),
                              const TextSpan(text: 'to '),
                    TextSpan(
                                text: 'God',
                      style: TextStyle(
                                  color: paywallTitleGold,
                                  fontWeight: FontWeight.w800,
                                  shadows: heroShadows,
                                ),
                              ),
                        TextSpan(
                                text: ' Daily',
                                style: TextStyle(
                                  color: paywallTitleGold,
                                  fontWeight: FontWeight.w800,
                                  shadows: heroShadows,
                                ),
                        ),
                      ],
                    ),
                  ),
                        const SizedBox(height: 8),
                  Text(
                          'Guidance, prayer, and encouragement\n whenever you need it.',
                          textAlign: TextAlign.left,
                    style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: paywallSubtitle,
                            fontWeight: FontWeight.w500,
                            shadows: heroShadows,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: imageHeight - cardOverlap,
            child: _buildBenefits(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits([bool isTablet = false]) {
    Widget cell({
      required IconData icon,
      required Color bg,
      required Color iconColor,
      required String title,
    }) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 40 : 36,
                height: isTablet ? 40 : 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: isTablet ? 22 : 20, color: iconColor),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 13 : 11.5,
                  color: const Color(0xFF17202E),
                  height: 1.28,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final side = isTablet
        ? (MediaQuery.sizeOf(context).width * 0.06).clamp(28.0, 48.0)
        : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: side),
      padding: EdgeInsets.symmetric(
          vertical: isTablet ? 14 : 12, horizontal: isTablet ? 6 : 4),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
          boxShadow: [
            BoxShadow(
            color: const Color(0xFF5A3C14).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
              icon: Icons.volunteer_activism_rounded,
              bg: const Color(0xFFFBF0DA),
              iconColor: const Color(0xFFB07A1E),
                title: 'Pray With\nConfidence',
              ),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFFEFE7DA)),
              cell(
              icon: Icons.menu_book_rounded,
              bg: const Color(0xFFEDF4E2),
              iconColor: const Color(0xFF5C8A2B),
              title: 'Understand\nScripture Better',
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFFEFE7DA)),
              cell(
              icon: Icons.favorite_rounded,
              bg: const Color(0xFFFCE9EA),
              iconColor: const Color(0xFFD9636B),
                title: 'Find Peace\nEvery Day',
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildAiCard(bool isTablet) {
    final selected = _sel == _PwCard.ai;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_sel == _PwCard.ai) return;

        setState(() => _sel = _PwCard.ai);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          isTablet ? 18 : 15,
          isTablet ? 16 : 14,
          isTablet ? 18 : 15,
          isTablet ? 16 : 15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? _purple : _line,
            width: selected ? 2.5 : 1.5,
          ),
          color: selected ? const Color(0xFFF6F1FE) : _paper,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5B3FBF).withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: isTablet ? 20 : 19,
                  color: _purple,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(
                  child: Text(
                    'AI Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 21 : 19,
                      letterSpacing: -0.2,
                      color: _ink,
                    ),
                  ),
                ),
                if (_sel == _PwCard.ai && _dur == _AiDur.oneYear)
                  _SaveFiftyBadge(isTablet: isTablet),
              ],
            ),
            SizedBox(height: isTablet ? 18 : 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            _buildDurationRow(isTablet),
            SizedBox(height: isTablet ? 12 : 10),
            _inclRow(
              rich: true,
              bold: 'Unlimited AI',
              rest: ' — chat, prayer & answers',
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8 : 7),
            _inclRow(
              rich: true,
              bold: 'Ad-free',
              rest: ' · all premium features',
              isTablet: isTablet,
            ),
          ],
        ),
            ),
            if (selected)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _BestValueCardShine(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _planPrice(ProductDetails? product, String fallback) {
    if (product != null && product.price.isNotEmpty) return product.price;
    return fallback;
  }

  String _yearPerMonthCaption() {
    final product = _oneYear;
    if (product != null && product.rawPrice > 0) {
      final sym =
          product.currencySymbol.isNotEmpty ? product.currencySymbol : '\$';
      final perMonth = (product.rawPrice / 12).round();
      return '$sym$perMonth per month';
    }
    return 'per month';
  }

  Widget _buildDurationRow(bool isTablet) {
    final items = <(_AiDur, String, String, String, Color)>[
      if (_sixMonth != null || _loading)
        (
          _AiDur.sixMonth,
          '1 Month',
          _planPrice(_sixMonth, '\$34.99'),
          'per month',
          const Color(0xFF8A8498),
        ),
      if (_oneYear != null || _loading)
        (
          _AiDur.oneYear,
          '1 Year',
          _planPrice(_oneYear, '\$59.99'),
          _yearPerMonthCaption(),
          const Color(0xFF8B5E3C),
        ),
    ];

    if (items.isEmpty) {
      items.addAll([
        (
          _AiDur.sixMonth,
          '1 Month',
          _planPrice(_sixMonth, '\$34.99'),
          'per month',
          const Color(0xFF8A8498),
        ),
        (
          _AiDur.oneYear,
          '1 Year',
          _planPrice(_oneYear, '\$59.99'),
          _yearPerMonthCaption(),
          const Color(0xFF8B5E3C),
        ),
      ]);
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: isTablet ? 16 : 14),
          Expanded(
            child: _DurChip(
              selected: _dur == items[i].$1 && _sel == _PwCard.ai,
              label: items[i].$2,
              price: items[i].$3,
              caption: items[i].$4,
              captionColor: items[i].$5,
              onTap: () => setState(() {
                _sel = _PwCard.ai;

                _dur = items[i].$1;
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLifetimeCard(bool isTablet) {
    final selected = _sel == _PwCard.lifetime;

    final priceMuted = !selected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_sel == _PwCard.lifetime) return;

        setState(() => _sel = _PwCard.lifetime);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          isTablet ? 18 : 15,
          isTablet ? 16 : 14,
          isTablet ? 18 : 15,
          isTablet ? 16 : 15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? _green : _line,
            width: selected ? 2.5 : 1.5,
          ),
          color: selected ? const Color(0xFFF0F8F3) : _paper,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E7A45).withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RadioDot(selected: selected, color: _green),
                SizedBox(width: isTablet ? 10 : 8),
                Icon(
                  Icons.diamond_rounded,
                  size: isTablet ? 20 : 19,
                  color: _green,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(
                  child: Text(
                    'Lifetime',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 21 : 19,
                      letterSpacing: -0.2,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 14,
                    vertical: isTablet ? 8 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _green
                        : const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Best Value',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 14 : 11),
            Opacity(
              opacity: priceMuted ? 0.45 : 1,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _lifetimePrice,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                      fontSize: isTablet ? 34 : 30,
                      letterSpacing: -0.6,
                      height: 1.1,
                    color: _ink,
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                      'once',
                    style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C5240),
                    ),
                  ),
                ),
              ],
            ),
            ),
            SizedBox(height: isTablet ? 12 : 11),
            _inclRow(
              rich: true,
              bold: 'Ad-free forever',
              rest: ' + all reading & study features',
              isTablet: isTablet,
              accentGreen: true,
            ),
            SizedBox(height: isTablet ? 8 : 7),
            _inclRow(
              rich: true,
              prefix: 'Use AI anytime with credits — ',
              bold: 'earn free or buy',
              isTablet: isTablet,
              accentGreen: true,
            ),
            SizedBox(height: isTablet ? 8 : 7),
            _inclRow(
              rich: true,
              bold: '5,000',
              rest: ' welcome credits to start',
              isTablet: isTablet,
              accentGreen: true,
            ),
          ],
        ),
            ),
            if (selected)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _BestValueCardShine(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inclRow({
    String? text,
    bool rich = false,
    String bold = '',
    String rest = '',
    String prefix = '',
    bool isTablet = false,
    bool accentGreen = false,
  }) {
    final fontSize = isTablet ? 13.5 : 12.5;

    final checkColor =
        accentGreen ? const Color(0xFF1E7A45) : const Color(0xFF5B3FBF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '✓',
            style: TextStyle(
            fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w800,
            color: checkColor,
            height: 1.35,
            ),
          ),
        SizedBox(width: isTablet ? 8 : 8),
        Expanded(
          child: rich
              ? Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: fontSize,
                      color: const Color(0xFF2E2718),
                      height: 1.35,
                    ),
                    children: [
                      if (prefix.isNotEmpty) TextSpan(text: prefix),
                      TextSpan(
                        text: bold,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E2718),
                        ),
                      ),
                      TextSpan(text: rest),
                    ],
                  ),
                )
              : Text(
                  text ?? '',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFF2E2718),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLegalRow({bool isTablet = false}) {
    Widget link(String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 11,
            color: const Color(0xFF9A9080),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF9A9080),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          link(
            'Terms of Use',
            () => _openLegal('https://bibleoffice.com/terms_conditions.html'),
          ),
          Text(' · ',
              style: TextStyle(
                  fontSize: isTablet ? 12 : 11,
                  color: const Color(0xFF9A9080))),
          link(
            'Privacy Policy',
            () => _openLegal('https://bibleoffice.com/privacy_policy.html'),
          ),
          Text(' · ',
              style: TextStyle(
                  fontSize: isTablet ? 12 : 11,
                  color: const Color(0xFF9A9080))),
          link('Restore Purchases', _restorePurchases),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isTablet, double w) {
    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 16.0;

    final lifetimeCta = _sel == _PwCard.lifetime;

    return SafeArea(
      top: false,
      child: Padding(
        // UI only: tighter bottom CTA block spacing.

        padding: EdgeInsets.fromLTRB(hPad, isTablet ? 4 : 2, hPad, 4),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _aboveCta,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: const Color(0xFF4A3B22),
              ),
            ),
            SizedBox(height: isTablet ? 7 : 6),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 56 : 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: lifetimeCta
                        ? const [Color(0xFF2E9457), Color(0xFF166438)]
                        : const [Color(0xFFC08D22), Color(0xFF8E5F10)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: (lifetimeCta
                              ? const Color(0xFF166438)
                              : const Color(0xFF8E5F10))
                          .withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onPrimaryCta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    _ctaLabel,
                    style: TextStyle(
                      fontSize: isTablet ? 19 : 17.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 6 : 5),
            Text(
              _belowCta,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: -0.1,
                color: const Color(0xFF3E3527),
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            GestureDetector(
              onTap: _continueLimited,
              child: Text(
                'Continue with Limited Access',
                style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12.5,
                  color: const Color(0xFF8A7A5E),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 6 : 5),
            _buildLegalRow(isTablet: isTablet),
          ],
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
  const _SaveFiftyBadge({required this.isTablet});

  final bool isTablet;

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
          'Save 50%',
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
