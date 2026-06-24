import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum FeatureCreditsPaywallKind { chat, prayerGuidance }

class FeatureCreditsPaywallScreen extends StatefulWidget {
  const FeatureCreditsPaywallScreen({super.key, required this.kind});

  final FeatureCreditsPaywallKind kind;

  @override
  State<FeatureCreditsPaywallScreen> createState() =>
      _FeatureCreditsPaywallScreenState();
}

class _FeatureCreditsPaywallScreenState
    extends State<FeatureCreditsPaywallScreen> {
  static const Color _brown = Color(0xFF4E342E);
  static const Color _gold = Color(0xFF9E7340);
  static const Color _ink = Color(0xFF2D2418);

  String _salePrice = '₹ 1,299';

  bool get _isChat => widget.kind == FeatureCreditsPaywallKind.chat;

  String get _backgroundAsset => _isChat
      ? 'assets/chat-paywall-bg.png'
      : 'assets/prayer_guidance-paywall-bg.png';

  String get _checkad =>
      _isChat ? 'chat_credits_paywall' : 'prayer_guidance_credits_paywall';

  @override
  void initState() {
    super.initState();
    _loadOneYearPricing();
  }

  Future<void> _loadOneYearPricing() async {
    try {
      final oneYearId = await SharPreferences.getString('oneYearPlan') ??
          BibleInfo.oneYearPlanid;

      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return;

      final response =
          await InAppPurchase.instance.queryProductDetails({oneYearId});
      if (response.productDetails.isEmpty || !mounted) return;

      setState(() {
        _salePrice = response.productDetails.first.price;
      });
    } catch (_) {
      // Keep fallback display price.
    }
  }

  Future<void> _openPurchase(BuildContext context) async {
    final sixMonth = await SharPreferences.getString('sixMonthPlan') ??
        BibleInfo.sixMonthPlanid;
    final oneYear =
        await SharPreferences.getString('oneYearPlan') ?? BibleInfo.oneYearPlanid;
    final lifeTime =
        await SharPreferences.getString('lifeTimePlan') ?? BibleInfo.lifeTimePlanid;

    if (!context.mounted) return;

    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: sixMonth,
          oneYearPlan: oneYear,
          lifeTimePlan: lifeTime,
          checkad: _checkad,
          initialSelectedPlanIndex: 1,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );

    if (ok == true && context.mounted) {
      Navigator.of(context).maybePop(true);
    }
  }

  Future<void> _openRestorePaywall() async {
    final sixMonth = await SharPreferences.getString('sixMonthPlan') ??
        BibleInfo.sixMonthPlanid;
    final oneYear =
        await SharPreferences.getString('oneYearPlan') ?? BibleInfo.oneYearPlanid;
    final lifeTime =
        await SharPreferences.getString('lifeTimePlan') ?? BibleInfo.lifeTimePlanid;

    Get.to(
      () => SubscriptionScreen(
        sixMonthPlan: sixMonth,
        oneYearPlan: oneYear,
        lifeTimePlan: lifeTime,
        checkad: _checkad,
        initialSelectedPlanIndex: 1,
      ),
      transition: Transition.cupertinoDialog,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 450;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D5),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 20,
                      8,
                      isWide ? 28 : 20,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 12),
                        _buildTitleBlock(isWide),
                        const SizedBox(height: 14),
                        _buildStatusBanner(),
                        const SizedBox(height: 22),
                        _buildPremiumSection(isWide),
                        const SizedBox(height: 22),
                        _buildPlanCard(isWide),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 20,
                    0,
                    isWide ? 28 : 20,
                    12,
                  ),
                  child: Column(
                    children: [
                      _buildUnlockButton(),
                      const SizedBox(height: 12),
                      _buildFooter(),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _brown,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isChat ? Icons.chat_bubble_outline : Icons.volunteer_activism,
            color: Colors.white,
            size: 20,
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close, size: 16, color: Color(0xFF5A5A5A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBlock(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isWide ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.15,
            ),
            children: _isChat
                ? const [
                    TextSpan(text: "You're Out of "),
                    TextSpan(
                      text: 'AI Guidance',
                      style: TextStyle(color: _gold),
                    ),
                    TextSpan(text: ' Credits'),
                  ]
                : const [
                    TextSpan(text: 'Continue Sending '),
                    TextSpan(
                      text: 'Prayer Requests',
                      style: TextStyle(color: _gold),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isChat
              ? 'Continue asking questions and receive biblical guidance.'
              : 'Get prayer support and encouragement from our community.',
          style: TextStyle(
            fontSize: isWide ? 15 : 14,
            height: 1.35,
            color: _ink.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E6).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brown.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isChat ? Icons.card_giftcard : Icons.favorite,
            color: _brown,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isChat
                  ? 'Used all free credits for today. Upgrade to continue without limits.'
                  : 'Used all free prayer support for today. Upgrade to continue without limits.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: _ink.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(bool isWide) {
    final features = _isChat
        ? const [
            (Icons.chat_bubble_outline, 'Unlimited\nAI Chat'),
            (Icons.menu_book_outlined, 'Better Scripture\nUnderstanding'),
            (Icons.favorite_border, 'Emotional\nSupport'),
            (Icons.shield_outlined, 'Premium Faith\nTools'),
          ]
        : const [
            (Icons.favorite_border, 'Priority Prayer\nSupport'),
            (Icons.groups_outlined, 'Community\nPrayers'),
            (Icons.shield_outlined, 'Confidential\n& Safe'),
            (Icons.church_outlined, 'Prayer\nReminders'),
          ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _sectionDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'With Premium You Get',
                style: TextStyle(
                  fontSize: isWide ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: _ink.withValues(alpha: 0.8),
                ),
              ),
            ),
            Expanded(child: _sectionDivider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < features.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _featureItem(features[i].$1, features[i].$2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _sectionDivider() {
    return Container(
      height: 1,
      color: _brown.withValues(alpha: 0.22),
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _brown,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            color: _ink.withValues(alpha: 0.82),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(bool isWide) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC9A227), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                '1 Year Premium',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: isWide ? 22 : 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on,
                      color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '3000 Credits Included',
                    style: TextStyle(
                      fontSize: isWide ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: _ink.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _salePrice,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: isWide ? 34 : 30,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Billed once a year',
                style: TextStyle(
                  fontSize: 12,
                  color: _ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _brown,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '★ MOST POPULAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openPurchase(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _brown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 18),
            const SizedBox(width: 8),
            Text(
              _isChat ? 'Unlock & Continue Chat' : 'Unlock Prayer Support',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _openRestorePaywall,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Restore Purchase',
            style: TextStyle(
              fontSize: 13,
              color: _ink.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ' • ',
          style: TextStyle(color: _ink.withValues(alpha: 0.45)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined,
                size: 14, color: _ink.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
            Text(
              'Secure Payment',
              style: TextStyle(
                fontSize: 13,
                color: _ink.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
