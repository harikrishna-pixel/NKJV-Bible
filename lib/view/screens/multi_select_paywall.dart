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

/// Multi-select paywall matching OldPaper prototype screen 13 (PAYWALL v6).
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
  static const Color _cream = Color(0xFFF5EBD8);
  static const Color _paper = Color(0xFFFFFDF8);
  static const Color _ink = Color(0xFF2B1F13);
  static const Color _inkSoft = Color(0xFF6B5A44);
  static const Color _line = Color(0xFFE2D3B4);
  static const Color _purple = Color(0xFF6D51A3);
  static const Color _green = Color(0xFF5E8F5A);
  static const Color _greenSoft = Color(0xFFEEF6EC);

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

  String get _aiPer => _dur == _AiDur.oneYear ? '/yr' : '/mo';

  String get _aiNote {
    if (_dur == _AiDur.oneYear) {
      return 'billed yearly as $_aiPrice · auto-renews';
    }
    return 'billed monthly as $_aiPrice · auto-renews';
  }

  String get _lifetimePrice {
    final p = _lifetime;
    if (p != null && p.price.isNotEmpty) return p.price;
    return '\$79.99';
  }

  String get _ctaLabel => _sel == _PwCard.lifetime
      ? 'Get Lifetime Access'
      : 'Start 3-Day Free Trial';

  String get _trustLine => _sel == _PwCard.lifetime
      ? '✦ One payment — yours forever, no subscription'
      : "✦ You won't be charged for the first 3 days";

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
    // Tablet reference uses wider content (~8% inset); phone keeps 18.
    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 18.0;

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
                      // UI only: tighter gap under benefits card → AI Premium.
                      padding: EdgeInsets.fromLTRB(
                          hPad, isTablet ? 4 : 2, hPad, 0),
                      child: Column(
                        children: [
                          _buildAiCard(isTablet),
                          SizedBox(height: isTablet ? 14 : 11),
                          _buildLifetimeCard(isTablet),
                          // UI only: charge line directly under Lifetime card.
                          SizedBox(height: isTablet ? 14 : 12),
                          Text(
                            _trustLine,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 13.5 : 12.5,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
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
    // UI only: room for 2-line centered sub-topics (icons unchanged).
    final cardLayoutHeight = isTablet ? 158.0 : 140.0;
    final cardOverlap = isTablet
        ? 96.0
        : isCompactHeight
            ? 68.0
            : 90.0;
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
                              Colors.white.withOpacity(0.14),
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
                                paywallCream.withOpacity(0.0),
                                paywallCream.withOpacity(0.04),
                                paywallCream.withOpacity(0.35),
                                paywallCream,
                              ]
                            : [
                                paywallCream.withOpacity(0.06),
                                paywallCream.withOpacity(0.22),
                                paywallCream.withOpacity(0.72),
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
                          paywallCream.withOpacity(isTablet ? 0.10 : 0.26),
                          paywallCream.withOpacity(isTablet ? 0.04 : 0.14),
                          paywallCream.withOpacity(0.03),
                          paywallCream.withOpacity(0.0),
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
                          left: heroSidePad, top: isTablet ? 10 : 6),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/paywall_icons/premium.png',
                            height: isTablet ? 60 : 52,
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
                              color: Colors.white.withOpacity(0.52),
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
                                          .withOpacity(0.62),
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
                Positioned(
                  left: heroSidePad,
                  right: heroSidePad,
                  top: topPadding + (isTablet ? 54 : 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: isTablet ? 'Georgia' : null,
                            fontSize: isTablet ? 40 : 34,
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
                                fontFamily: isTablet ? 'Georgia' : null,
                                color: paywallTitleGold,
                                fontWeight: FontWeight.w800,
                                shadows: heroShadows,
                              ),
                            ),
                            TextSpan(
                              text: ' Daily',
                              style: TextStyle(
                                fontFamily: isTablet ? 'Georgia' : null,
                                color: paywallTitleGold,
                                fontWeight: FontWeight.w800,
                                shadows: heroShadows,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 10 : 8),
                      Text(
                        'Guidance, prayer, and encouragement\n whenever you need it.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: isTablet ? 16.5 : 14,
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
      required String sub,
    }) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 36 : 30,
                height: isTablet ? 36 : 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: isTablet ? 18 : 16, color: iconColor),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 13 : 11,
                  color: _ink,
                  height: 1.15,
                ),
              ),
              // UI only: sub-topic lower + wrapped like referral (icons unchanged).
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: isTablet ? 11 : 9,
                  fontWeight: FontWeight.w400,
                  color: _inkSoft,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // UI only: a little wider (less side inset) to match referral.
    final side = isTablet
        ? (MediaQuery.sizeOf(context).width * 0.06).clamp(28.0, 48.0)
        : 8.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: side),
      padding: EdgeInsets.symmetric(
          vertical: isTablet ? 18 : 14, horizontal: isTablet ? 8 : 4),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        border: Border.all(color: const Color(0xFFF0E6CF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF503C19).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              icon: Icons.volunteer_activism_rounded,
              bg: const Color(0xFFF3ECDD),
              iconColor: const Color(0xFF8B6914),
              title: 'Pray With\nConfidence',
              sub: 'Support in\nhard moments',
            ),
            VerticalDivider(width: 1, thickness: 1, color: _line),
            cell(
              icon: Icons.menu_book_rounded,
              bg: const Color(0xFFEAF1E6),
              iconColor: const Color(0xFF5E8F5A),
              title: 'Understand\nScripture',
              sub: "God's Word\nmade clear",
            ),
            VerticalDivider(width: 1, thickness: 1, color: _line),
            cell(
              icon: Icons.favorite_rounded,
              bg: const Color(0xFFFBEAE7),
              iconColor: const Color(0xFFC75B4A),
              title: 'Find Peace\nEvery Day',
              sub: "Hope when\nit's hard",
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          isTablet ? 20 : 14,
          isTablet ? 18 : 13,
          isTablet ? 20 : 14,
          isTablet ? 18 : 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
          border: Border.all(
            color: selected ? _purple : _line,
            width: 2,
          ),
          // Always use a light gradient (never null) so selection never
          // flashes black while AnimatedContainer lerps decorations.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [Color(0xFFFCFAFF), Color(0xFFF6F0FF)]
                : const [_paper, _paper],
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF604696).withValues(alpha: 0.28),
                    blurRadius: 18,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: isTablet ? 20 : 18,
                        color: const Color(0xFF6D51A3),
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Flexible(
                        child: Text(
                          'AI Premium',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 21 : 17,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : 8,
                      vertical: isTablet ? 5 : 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE7F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6D51A3),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildDurationRow(isTablet),
            SizedBox(height: isTablet ? 16 : 12),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _aiPrice,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w800,
                      fontSize: isTablet ? 32 : 24,
                      color: _ink,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      _aiPer,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: _inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              _aiNote,
              style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12, color: _inkSoft),
            ),
            SizedBox(height: isTablet ? 14 : 10),
            _inclRow(
              rich: true,
              bold: 'Unlimited AI',
              rest: ' — chat, prayer & answers',
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8 : 6),
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
    final items = <(_AiDur, String, String, String?)>[
      if (_sixMonth != null || _loading)
        (
          _AiDur.sixMonth,
          '1 Month',
          _sixMonth != null && _sixMonth!.rawPrice > 0
              ? '${_sixMonth!.currencySymbol.isNotEmpty ? _sixMonth!.currencySymbol : '\$'}${_sixMonth!.rawPrice.toStringAsFixed(2)}/mo'
              : '\$4.99/mo',
          null, // no top badge on 1 Month
        ),
      if (_oneYear != null || _loading)
        (
          _AiDur.oneYear,
          '1 Year',
          _oneYear != null && _oneYear!.rawPrice > 0
              ? '${_oneYear!.currencySymbol.isNotEmpty ? _oneYear!.currencySymbol : '\$'}${(_oneYear!.rawPrice / 12).toStringAsFixed(2)}/mo'
              : '\$4.99/mo',
          'SAVE 40%',
        ),
    ];

    if (items.isEmpty) {
      items.addAll(const [
        (_AiDur.sixMonth, '1 Month', '\$4.99/mo', null),
        (_AiDur.oneYear, '1 Year', '\$4.99/mo', 'SAVE 40%'),
      ]);
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: _DurChip(
              selected: _dur == items[i].$1 && _sel == _PwCard.ai,
              label: items[i].$2,
              perMo: items[i].$3,
              badge: items[i].$4,
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
          isTablet ? 20 : 14,
          isTablet ? 18 : 13,
          isTablet ? 20 : 14,
          isTablet ? 18 : 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
          border: Border.all(
            color: selected ? _green : _line,
            width: 2,
          ),
          // Always use a light gradient (never null) so selection never
          // flashes black while AnimatedContainer lerps decorations.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [Color(0xFFF8FCF7), Color(0xFFEEF6EC)]
                : const [_paper, _paper],
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF466E3C).withValues(alpha: 0.28),
                    blurRadius: 18,
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
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.diamond_rounded,
                        size: isTablet ? 20 : 18,
                        color: const Color(0xFF3F7A3A),
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Flexible(
                        child: Text(
                          'Lifetime',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 21 : 17,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 10 : 8,
                      vertical: isTablet ? 5 : 4),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'One time Payment',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3F7A3A),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _lifetimePrice,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet ? 32 : 24,
                    color: _ink,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    ' once',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: _inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              'Ad-free forever · no subscription',
              style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12,
                  color: const Color(0xFF3F7A3A)),
            ),
            SizedBox(height: isTablet ? 14 : 10),
            _inclRow(
              rich: true,
              bold: 'Ad-free forever',
              rest: ' + all reading & study features',
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8 : 6),
            _inclRow(
              rich: true,
              prefix: 'Use AI anytime with credits — ',
              bold: 'earn free or buy',
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 8 : 6),
            _inclRow(
              rich: true,
              bold: '5,000',
              rest: ' welcome credits to start',
              isTablet: isTablet,
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
  }) {
    final fontSize = isTablet ? 14.0 : 12.5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isTablet ? 18 : 16,
          height: isTablet ? 18 : 16,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE7DBFB),
            shape: BoxShape.circle,
          ),
          child: Text(
            '✓',
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5E3FA0),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 10 : 8),
        Expanded(
          child: rich
              ? Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: fontSize, color: _inkSoft),
                    children: [
                      if (prefix.isNotEmpty) TextSpan(text: prefix),
                      TextSpan(
                        text: bold,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      TextSpan(text: rest),
                    ],
                  ),
                )
              : Text(
                  text ?? '',
                  style: TextStyle(fontSize: fontSize, color: _inkSoft),
                ),
        ),
      ],
    );
  }

  Widget _buildTrustRow({bool isTablet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              size: isTablet ? 16 : 14, color: _inkSoft),
          SizedBox(width: isTablet ? 6 : 4),
          Text('Cancel anytime',
              style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12, color: _inkSoft)),
          SizedBox(width: isTablet ? 14 : 10),
          Container(
            width: 1,
            height: isTablet ? 14 : 12,
            color: _inkSoft.withOpacity(0.35),
          ),
          SizedBox(width: isTablet ? 14 : 10),
          Icon(Icons.lock_outline_rounded,
              size: isTablet ? 16 : 14, color: _inkSoft),
          SizedBox(width: isTablet ? 6 : 4),
          Text('Secure & trusted',
              style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12, color: _inkSoft)),
        ],
      ),
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
            color: _inkSoft,
            decoration: TextDecoration.underline,
            decorationColor: _inkSoft,
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
                  fontSize: isTablet ? 12 : 11, color: _inkSoft)),
          link(
            'Privacy Policy',
            () => _openLegal('https://bibleoffice.com/privacy_policy.html'),
          ),
          Text(' · ',
              style: TextStyle(
                  fontSize: isTablet ? 12 : 11, color: _inkSoft)),
          link('Restore Purchases', _restorePurchases),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isTablet, double w) {
    final hPad = isTablet ? (w * 0.08).clamp(36.0, 64.0) : 18.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, isTablet ? 10 : 8, hPad, 12),
        child: Column(
          children: [
            // UI only: slightly shorter CTA button.
            SizedBox(
              width: double.infinity,
              height: isTablet ? 50 : 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB4842E),
                      Color(0xFFC9A35A),
                      Color(0xFFA9791F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                ),
                child: ElevatedButton(
                  onPressed: _startPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(isTablet ? 14 : 12),
                    ),
                  ),
                  child: Text(
                    '$_ctaLabel ›',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // UI only: Continue above Cancel anytime + legal lines.
            SizedBox(height: isTablet ? 10 : 8),
            GestureDetector(
              onTap: _continueLimited,
              child: Text(
                'Continue with Limited Access',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  color: const Color(0xFF9A866A),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 10 : 8),
            _buildTrustRow(isTablet: isTablet),
            SizedBox(height: isTablet ? 10 : 8),
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
    required this.perMo,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String label;
  final String perMo;
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
            padding: EdgeInsets.fromLTRB(
              isTablet ? 10 : 6,
              isTablet ? 18 : 15,
              isTablet ? 10 : 6,
              isTablet ? 10 : 7,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF4EFFC) : Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 13 : 11),
              border: Border.all(
                color: selected
                    ? const Color(0xFF6D51A3)
                    : const Color(0xFFE2D3B4),
                width: selected && isTablet ? 2.0 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFF6D51A3)
                        : const Color(0xFF2B1F13),
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                Text(
                  perMo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF6D51A3)
                        : const Color(0xFF6B5A44),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 8 : 6,
                      vertical: isTablet ? 3.5 : 2.5),
                  decoration: BoxDecoration(
                    gradient: badge == 'SAVE 40%'
                        ? const LinearGradient(
                            colors: [Color(0xFFB4842E), Color(0xFFC9A35A)],
                          )
                        : null,
                    color: badge == 'SAVE 40%'
                        ? null
                        : const Color(0xFF5E8F5A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 9 : 8,
                      fontWeight: FontWeight.w800,
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
