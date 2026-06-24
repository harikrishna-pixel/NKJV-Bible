import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Milestone pop-up before milestone IAP (non-dismissible).
class MilestoneJourneyDialog {
  MilestoneJourneyDialog._();

  static const String _scriptureHeroAsset =
      'assets/paywall_icons/read_scripture.png';
  static const String _prayerHeroAsset = 'assets/creating_prayer.png';
  static const String _treasureAccentAsset = 'assets/gold-treasure-icon.png';

  static const Color _ink = Color(0xFF3D2914);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _gold = Color(0xFFC59434);
  static const Color _cream = Color(0xFFF5F0E6);

  static const String _prayerTopIconAsset =
      'assets/paywall_icons/praywithguidance.png';
  static const String _scriptureTopIconAsset =
      'assets/paywall_icons/read_scripture.png';

  static Future<void> showScriptureMilestone(BuildContext context) {
    return _show(
      context,
      headline: 'Your Scripture Journey Is Growing',
      line1: 'We\'re grateful to be part of your journey.',
      line2: 'We have a special blessing for you.',
      heroAsset: _scriptureHeroAsset,
      topIconAsset: _scriptureTopIconAsset,
    );
  }

  static Future<void> showPrayerMilestone(BuildContext context) {
    return _show(
      context,
      headline: 'Your Prayer Journey is Growing.',
      line1: 'You\'ve been spending time in prayers.',
      line2: 'We\'re thankful to walk this journey with you.',
      line3: 'We have a special blessing for you.',
      heroAsset: _prayerHeroAsset,
      topIconAsset: _prayerTopIconAsset,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String headline,
    required String line1,
    required String line2,
    String? line3,
    required String heroAsset,
    required String topIconAsset,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.62),
        pageBuilder: (ctx, _, __) => _MilestoneJourneyPage(
          headline: headline,
          line1: line1,
          line2: line2,
          line3: line3,
          heroAsset: heroAsset,
          topIconAsset: topIconAsset,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}

class _MilestoneJourneyPage extends StatelessWidget {
  const _MilestoneJourneyPage({
    required this.headline,
    required this.line1,
    required this.line2,
    required this.heroAsset,
    required this.topIconAsset,
    this.line3,
  });

  final String headline;
  final String line1;
  final String line2;
  final String? line3;
  final String heroAsset;
  final String topIconAsset;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final cream =
        isDark ? CommanColor.darkPrimaryColor : MilestoneJourneyDialog._cream;
    final ink = isDark ? Colors.white : MilestoneJourneyDialog._ink;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.86)
        : MilestoneJourneyDialog._ink.withValues(alpha: 0.88);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: MilestoneJourneyDialog._gold.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: MilestoneJourneyDialog._gold.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          heroAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: MilestoneJourneyDialog._brown
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.06),
                                Colors.transparent,
                                cream.withValues(alpha: 0.2),
                                cream,
                              ],
                              stops: const [0.0, 0.4, 0.88, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MilestoneJourneyDialog._gold
                                      .withValues(alpha: 0.7),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(9),
                              child: Image.asset(
                                topIconAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.auto_awesome,
                                  color: MilestoneJourneyDialog._gold,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ColoredBox(
                    color: cream,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              height: 1.22,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            line1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 14,
                              height: 1.5,
                              color: bodyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            line2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 14,
                              height: 1.5,
                              color: bodyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (line3 != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              line3!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 14,
                                height: 1.5,
                                color: bodyColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: MilestoneJourneyDialog._gold
                                  .withValues(alpha: isDark ? 0.2 : 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: MilestoneJourneyDialog._gold
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  MilestoneJourneyDialog._treasureAccentAsset,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 18,
                                    color: MilestoneJourneyDialog._gold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'A Special Blessing Awaits',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.amber.shade100
                                        : MilestoneJourneyDialog._brown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF763201),
                                    Color(0xFFD5821F),
                                    Color(0xFF763201),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF763201)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
