import 'dart:async';

import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
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

  String get _resolvedSixMonth => AppApiConstant.resolveSubscriptionProductId(
        widget.sixMonthPlan,
        BibleInfo.isAutoRenewablePaywallMode
            ? BibleInfo.arOneMonthPlanid
            : BibleInfo.sixMonthPlanid,
      );

  String get _resolvedOneYear => AppApiConstant.resolveSubscriptionProductId(
        widget.oneYearPlan,
        BibleInfo.isAutoRenewablePaywallMode
            ? BibleInfo.arOneYearPlanid
            : BibleInfo.oneYearPlanid,
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
      EasyLoading.dismiss();
    } catch (_) {}
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('premiumalrt', '1');
    } catch (_) {}
    if (!mounted) return;
    await PremiumWelcomeAlert.show(context);

    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      await provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    if (!mounted) return;
    // Alert already shown (premiumalrt → 2); Home From premium keeps journey timing.
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
    for (final p in products) {
      final id = p.id.toLowerCase();
      // Paywall shows AR 1-month in the short slot (not AR 6-month).
      if (p.id == _resolvedSixMonth ||
          BibleInfo.isArOneMonthProductId(p.id)) {
        six ??= p;
      } else if (p.id == _resolvedOneYear ||
          BibleInfo.isArOneYearProductId(p.id)) {
        year ??= p;
      } else if (p.id == _resolvedLifetime ||
          (id.contains('lifetime') && !id.contains('exit'))) {
        life ??= p;
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
    return _dur == _AiDur.oneYear ? '\$59.99' : '\$34.99';
  }

  String get _aiPer => _dur == _AiDur.oneYear ? '/year' : '/month';

  /// UI only: strikethrough “was” price for yearly (SAVE 50% visual).
  String? get _aiWasPrice {
    if (_dur != _AiDur.oneYear) return null;
    final p = _oneYear;
    if (p == null || p.rawPrice <= 0) return null;
    final sym = p.currencySymbol.isNotEmpty ? p.currencySymbol : '\$';
    final was = p.rawPrice * 2;
    final text = was == was.roundToDouble()
        ? was.toStringAsFixed(0)
        : was.toStringAsFixed(2);
    return '$sym$text';
  }

  String get _aiNote {
    if (_dur == _AiDur.oneYear) {
      final p = _oneYear;
      if (p != null && p.rawPrice > 0) {
        final sym = p.currencySymbol.isNotEmpty ? p.currencySymbol : '\$';
        final mo = p.rawPrice / 12;
        final moText = mo == mo.roundToDouble()
            ? mo.toStringAsFixed(0)
            : mo.toStringAsFixed(2);
        return 'Works out to $sym$moText a month';
      }
      return 'Works out to a lower monthly cost';
    }
    return 'Billed every month';
  }

  String get _lifetimePrice {
    final p = _lifetime;
    if (p != null && p.price.isNotEmpty) return p.price;
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
          sixMonthPlan: widget.sixMonthPlan,
          oneYearPlan: widget.oneYearPlan,
          lifeTimePlan: widget.lifeTimePlan,
          checkad: widget.checkad,
          initialSelectedPlanIndex: _selectedPlanSlot,
          autoStartProductId: _selectedProductId,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );

    if (ok == true && mounted) {
      await _onInvisibleHostFinished(true, wasPurchase: true);
    }
  }

  Future<void> _restorePurchases() async {
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (!mounted) return;

    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: widget.sixMonthPlan,
          oneYearPlan: widget.oneYearPlan,
          lifeTimePlan: widget.lifeTimePlan,
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
    final sectionHeight =
        imageHeight + (cardLayoutHeight - cardOverlap) + 4.0;
    final heroSidePad =
        isTablet ? (size.width * 0.08).clamp(36.0, 64.0) : 16.0;

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
                            padding: EdgeInsets.only(
                                right: isTablet ? 16 : 12),
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
    final priceMuted = !selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_sel == _PwCard.ai) return;
        setState(() => _sel = _PwCard.ai);
      },
      child: AnimatedContainer(
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
                _RadioDot(selected: selected, color: _purple),
                SizedBox(width: isTablet ? 10 : 8),
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
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 11 : 10,
                      vertical: isTablet ? 6 : 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DEFA),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A2F9E),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 14 : 11),
            _buildDurationRow(isTablet),
            SizedBox(height: isTablet ? 14 : 11),
            if (_loading)
              const SizedBox(
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Opacity(
                opacity: priceMuted ? 0.45 : 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _aiPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? 34 : 30,
                        letterSpacing: -0.6,
                        height: 1.1,
                        color: _ink,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2),
                      child: Text(
                        _aiPer,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5C5240),
                        ),
                      ),
                    ),
                    if (_aiWasPrice != null) ...[
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          _aiWasPrice!,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFA2937B),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFFA2937B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: isTablet ? 4 : 2),
            Opacity(
              opacity: priceMuted ? 0.45 : 1,
              child: Text(
                _aiNote,
                style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11.5,
                    color: const Color(0xFF6E6353)),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 11),
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
    );
  }

  Widget _buildDurationRow(bool isTablet) {
    final items = <(_AiDur, String, String?)>[
      if (_sixMonth != null || _loading)
        (_AiDur.sixMonth, '1 Month', null),
      if (_oneYear != null || _loading)
        (_AiDur.oneYear, '1 Year', 'SAVE 50%'),
    ];

    if (items.isEmpty) {
      items.addAll(const [
        (_AiDur.sixMonth, '1 Month', null),
        (_AiDur.oneYear, '1 Year', 'SAVE 50%'),
      ]);
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: isTablet ? 12 : 9),
          Expanded(
            child: _DurChip(
              selected: _dur == items[i].$1 && _sel == _PwCard.ai,
              label: items[i].$2,
              badge: items[i].$3,
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
      child: AnimatedContainer(
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
                      horizontal: isTablet ? 11 : 10,
                      vertical: isTablet ? 6 : 5),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'One-time · Never renews',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF136135),
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
                  onPressed: _startPurchase,
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

class _DurChip extends StatelessWidget {
  const _DurChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 10 : 6,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF1EAFE)
                  : (badge != null
                      ? const Color(0xFFF7F3FD)
                      : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B3FBF)
                    : (badge != null
                        ? const Color(0xFFC6B8E0)
                        : const Color(0xFFDCD2E8)),
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 15,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF4A2F9E)
                    : const Color(0xFF101B2B),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -9,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 9 : 9,
                      vertical: isTablet ? 3.5 : 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A7113),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 9 : 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
