import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/multi_select_paywall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// First-time onboarding only: shown after "Start now" and before the paywall.
/// UI only — Continue opens MultiSelectPaywall (same plan IDs as SubscriptionScreen).
class FreeTrialIntroScreen extends StatefulWidget {
  const FreeTrialIntroScreen({
    super.key,
    required this.sixMonthPlan,
    required this.oneYearPlan,
    required this.lifeTimePlan,
  });

  final String sixMonthPlan;
  final String oneYearPlan;
  final String lifeTimePlan;

  @override
  State<FreeTrialIntroScreen> createState() => _FreeTrialIntroScreenState();
}

class _FreeTrialIntroScreenState extends State<FreeTrialIntroScreen> {
  static const String _kPaperBg = 'assets/lightMode/day_bg.png';
  static const Color _ink = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC59434);
  static const Color _goldDeep = Color(0xFF8B6914);
  static const Color _cream = Color(0xFFF5EBD8);
  static const Color _muted = Color(0xFF6B5540);

  bool _remindMe = true;

  void _continueToPlans() {
    Get.offAll(
      () => MultiSelectPaywall(
        sixMonthPlan: widget.sixMonthPlan,
        oneYearPlan: widget.oneYearPlan,
        lifeTimePlan: widget.lifeTimePlan,
        checkad: 'onboard',
      ),
      transition: SubscriptionScreen.paywallRouteTransition,
      duration: SubscriptionScreen.paywallRouteDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final hPad = isTablet ? screenWidth * 0.16 : 28.0;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _kPaperBg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '👑  3-DAY FREE TRIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: isTablet ? 30 : 26,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.25,
                            ),
                            children: const [
                              TextSpan(text: "You won't be charged "),
                              TextSpan(
                                text: 'today',
                                style: TextStyle(color: Color(0xFFB07A28)),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Full access starts now. Here's exactly what \n happens over the next 3 days.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            height: 1.45,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _TimelineSection(isTablet: isTablet),
                      ],
                    ),
                  ),
                ),
                // Remind + trust lines sit with Continue (bottom of page).
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF8).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE4D5C0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remind me before it ends',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "One notification on Day 2 — that's it",
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 12,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _remindMe,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (v) =>
                                  setState(() => _remindMe = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '✓  No payment now',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              color: _goldDeep,
                            ),
                          ),
                          const SizedBox(width: 22),
                          Text(
                            '✓  Cancel anytime',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              color: _goldDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 56 : 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF763201),
                                Color(0xFFD5821F),
                                Color(0xFF763201),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            onPressed: _continueToPlans,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Continue to plans  ›',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "See your options — you still won't be charged today",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: _muted.withOpacity(0.85),
                        ),
                      ),
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
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const _DayDot(
                  filled: true,
                  emoji: '🔓',
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFC59434).withOpacity(0.55),
                  ),
                ),
                const _DayDot(
                  filled: false,
                  emoji: '🔔',
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFC59434).withOpacity(0.55),
                  ),
                ),
                const _DayDot(
                  filled: false,
                  softPurple: true,
                  emoji: '⭐',
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _DayBlock(
                  isTablet: isTablet,
                  label: 'TODAY',
                  title: 'Everything unlocks — free',
                  body:
                      'Unlimited AI chat, prayer & guidance, ad-free reading.',
                ),
                SizedBox(height: isTablet ? 26 : 22),
                _DayBlock(
                  isTablet: isTablet,
                  label: 'DAY 2',
                  title: "We'll remind you",
                  body:
                      'A gentle heads-up before your trial ends — no surprise.',
                ),
                SizedBox(height: isTablet ? 26 : 22),
                _DayBlock(
                  isTablet: isTablet,
                  label: 'DAY 3',
                  title: 'Only then does your plan begin',
                  body:
                      '\$59.99/yr, and only if you keep it. Cancel \nanytime in one tap.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.filled,
    required this.emoji,
    this.softPurple = false,
  });

  final bool filled;
  final bool softPurple;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (filled) {
      bg = const Color(0xFFC59434);
    } else if (softPurple) {
      bg = const Color(0xFFF4EFFC);
    } else {
      bg = const Color(0xFFFFFDF8);
    }

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: softPurple
              ? const Color(0xFFE2D5F5)
              : const Color(0xFFC59434),
          width: 1.5,
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 17, height: 1.1),
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.isTablet,
    required this.label,
    required this.title,
    required this.body,
  });

  final bool isTablet;
  final String label;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: const Color(0xFFC59434),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D2914),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              height: 1.35,
              color: const Color(0xFF6B5540),
            ),
          ),
        ],
      ),
    );
  }
}
