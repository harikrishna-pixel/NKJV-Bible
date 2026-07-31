import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
  static const Color _goldDeep = Color(0xFF8B6914);
  static const Color _gold2 = Color(0xFFC9A35A);
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
        BibleInfo.sixMonthPlanid,
      );

  String get _resolvedOneYear => AppApiConstant.resolveSubscriptionProductId(
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
    _loadProducts();
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
      if (p.id == _resolvedSixMonth ||
          id.contains('sixmonth') && !id.contains('exit')) {
        six ??= p;
      } else if (p.id == _resolvedOneYear ||
          (id.contains('oneyear') && !id.contains('exit'))) {
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

  String get _aiPer => _dur == _AiDur.oneYear ? '/yr' : '/6 mo';

  String get _aiNote {
    if (_dur == _AiDur.oneYear) {
      return 'billed yearly as $_aiPrice · auto-renews';
    }
    return 'billed every 6 months as $_aiPrice · auto-renews';
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

  String get _micro => _sel == _PwCard.lifetime
      ? 'One-time $_lifetimePrice · no recurring charge'
      : 'then $_aiPrice$_aiPer · auto-renews · cancel anytime';

  Future<void> _openLegal(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _continueLimited() async {
    if (!mounted) return;
    final navContext = context;
    await StreakFlowNavigation.navigateToStreakFlowOrHome(navContext);
  }

  Future<void> _onClose() async {
    await _continueLimited();
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
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );

    if (ok == true && mounted) {
      if (Get.isRegistered<DashBoardController>()) {
        await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
      }
      if (!mounted) return;
      await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
    }
  }

  /// Restore uses existing SubscriptionScreen restore path (UI host, same logic).
  Future<void> _restorePurchases() async {
    await SharPreferences.setBoolean('restorepurches', true);
    if (!mounted) return;
    await SubscriptionScreen.openPaywallStacked(
      sixMonthPlan: widget.sixMonthPlan,
      oneYearPlan: widget.oneYearPlan,
      lifeTimePlan: widget.lifeTimePlan,
      checkad: widget.checkad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w > 600;

    return Scaffold(
      backgroundColor: _cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHero(isTablet),
                  _buildBenefits(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? w * 0.14 : 18,
                      13,
                      isTablet ? w * 0.14 : 18,
                      0,
                    ),
                    child: Column(
                      children: [
                        _buildAiCard(isTablet),
                        const SizedBox(height: 11),
                        _buildLifetimeCard(isTablet),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTrustRow(),
                  const SizedBox(height: 8),
                  _buildLegalRow(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          _buildFooter(isTablet, w),
        ],
      ),
    );
  }

  Widget _buildHero(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Hero image + parchment wash (HTML pw-hero).
          Positioned.fill(
            child: Image.asset(
              'assets/paywall-bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.8, -0.2),
                  end: const Alignment(0.6, 1),
                  colors: [
                    _cream.withOpacity(0.74),
                    _cream.withOpacity(0.36),
                    _cream.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.46, 0.72],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _cream.withOpacity(0),
                    _cream.withOpacity(0.88),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 40 : 22,
                10,
                isTablet ? 40 : 22,
                52,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_goldDeep, _gold2],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👑 PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white.withOpacity(0.82),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _onClose,
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: Center(
                              child: Text(
                                '✕',
                                style: TextStyle(
                                  color: Color(0xFF3A2B18),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 32 : 27,
                        color: const Color(0xFF241A0F),
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(text: 'Grow Closer to '),
                        TextSpan(
                          text: 'God Daily',
                          style: TextStyle(color: _goldDeep),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Guidance, prayer, and encouragement whenever you need it.',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12.5,
                      color: const Color(0xFF40361F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    Widget cell({
      required String emoji,
      required Color bg,
      required String title,
      required String sub,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: _ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: _inkSoft,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
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
                emoji: '🙏',
                bg: const Color(0xFFF3ECDD),
                title: 'Pray With\nConfidence',
                sub: 'Support in hard moments',
              ),
              VerticalDivider(width: 1, thickness: 1, color: _line),
              cell(
                emoji: '📖',
                bg: const Color(0xFFEAF1E6),
                title: 'Understand\nScripture',
                sub: "God's Word made clear",
              ),
              VerticalDivider(width: 1, thickness: 1, color: _line),
              cell(
                emoji: '❤️',
                bg: const Color(0xFFFBEAE7),
                title: 'Find Peace\nEvery Day',
                sub: "Hope when it's hard",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiCard(bool isTablet) {
    final selected = _sel == _PwCard.ai;
    return GestureDetector(
      onTap: () => setState(() => _sel = _PwCard.ai),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _purple : _line,
            width: 2,
          ),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFCFAFF), Color(0xFFF6F0FF)],
                )
              : null,
          color: selected ? null : _paper,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF604696).withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RadioDot(selected: selected, color: _purple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '✨ AI Premium',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE7F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D51A3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDurationRow(isTablet),
            const SizedBox(height: 12),
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
                      fontSize: isTablet ? 28 : 24,
                      color: _ink,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      _aiPer,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              _aiNote,
              style: const TextStyle(fontSize: 12, color: _inkSoft),
            ),
            const SizedBox(height: 10),
            _inclRow(
              rich: true,
              bold: 'Unlimited AI',
              rest: ' — chat, prayer & answers',
            ),
            const SizedBox(height: 6),
            _inclRow(text: 'Ad-free · all premium features'),
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
          '6 Months',
          _sixMonth != null && _sixMonth!.rawPrice > 0
              ? '${_sixMonth!.currencySymbol.isNotEmpty ? _sixMonth!.currencySymbol : '\$'}${(_sixMonth!.rawPrice / 6).toStringAsFixed(2)}/mo'
              : '\$5.83/mo',
          'SAVE 40%',
        ),
      if (_oneYear != null || _loading)
        (
          _AiDur.oneYear,
          '1 Year',
          _oneYear != null && _oneYear!.rawPrice > 0
              ? '${_oneYear!.currencySymbol.isNotEmpty ? _oneYear!.currencySymbol : '\$'}${(_oneYear!.rawPrice / 12).toStringAsFixed(2)}/mo'
              : '\$4.99/mo',
          'POPULAR',
        ),
    ];

    if (items.isEmpty) {
      items.addAll(const [
        (_AiDur.sixMonth, '6 Months', '\$5.83/mo', 'SAVE 40%'),
        (_AiDur.oneYear, '1 Year', '\$4.99/mo', 'POPULAR'),
      ]);
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
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
      onTap: () => setState(() => _sel = _PwCard.lifetime),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _green : _line,
            width: 2,
          ),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FCF7), Color(0xFFEEF6EC)],
                )
              : null,
          color: selected ? null : _paper,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF466E3C).withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RadioDot(selected: selected, color: _green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '💎 Lifetime',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'One-time · Pay once',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F7A3A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _lifetimePrice,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet ? 28 : 24,
                    color: _ink,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    ' once',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ad-free forever · no subscription',
              style: TextStyle(fontSize: 12, color: Color(0xFF3F7A3A)),
            ),
            const SizedBox(height: 10),
            _inclRow(
              rich: true,
              bold: 'Ad-free forever',
              rest: ' + all reading & study features',
            ),
            const SizedBox(height: 6),
            _inclRow(
              rich: true,
              prefix: 'Use AI anytime with credits — ',
              bold: 'earn free or buy',
            ),
            const SizedBox(height: 6),
            _inclRow(
              rich: true,
              bold: '5,000',
              rest: ' welcome credits to start',
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE7DBFB),
            shape: BoxShape.circle,
          ),
          child: const Text(
            '✓',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5E3FA0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: rich
              ? Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12.5, color: _inkSoft),
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
                  style: const TextStyle(fontSize: 12.5, color: _inkSoft),
                ),
        ),
      ],
    );
  }

  Widget _buildTrustRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛡️ Cancel anytime',
              style: TextStyle(fontSize: 12, color: _inkSoft)),
          SizedBox(width: 18),
          Text('🔒 Secure & trusted',
              style: TextStyle(fontSize: 12, color: _inkSoft)),
        ],
      ),
    );
  }

  Widget _buildLegalRow() {
    Widget link(String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _inkSoft,
            decoration: TextDecoration.underline,
            decorationColor: _inkSoft,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          link(
            'Terms of Use',
            () => _openLegal('https://bibleoffice.com/terms_conditions.html'),
          ),
          const Text(' · ', style: TextStyle(fontSize: 11, color: _inkSoft)),
          link(
            'Privacy Policy',
            () => _openLegal('https://bibleoffice.com/privacy_policy.html'),
          ),
          const Text(' · ', style: TextStyle(fontSize: 11, color: _inkSoft)),
          link('Restore Purchases', _restorePurchases),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isTablet, double w) {
    final hPad = isTablet ? w * 0.14 : 18.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: isTablet ? 56 : 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB4842E),
                      Color(0xFFC9A35A),
                      Color(0xFFA9791F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _startPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '$_ctaLabel  ›',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _trustLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _micro,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: _inkSoft),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _continueLimited,
              child: const Text(
                'Continue with Limited Access',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A866A),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF9A866A),
                ),
              ),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 15, 6, 7),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF4EFFC) : Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected ? const Color(0xFF6D51A3) : const Color(0xFFE2D3B4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFF6D51A3)
                        : const Color(0xFF2B1F13),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perMo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    gradient: badge == 'POPULAR'
                        ? const LinearGradient(
                            colors: [Color(0xFFB4842E), Color(0xFFC9A35A)],
                          )
                        : null,
                    color: badge == 'POPULAR' ? null : const Color(0xFF5E8F5A),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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
