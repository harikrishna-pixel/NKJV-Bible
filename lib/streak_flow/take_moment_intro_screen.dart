import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "Take a Moment With God" intro - first screen of Find Peace flow.
class TakeMomentIntroScreen extends StatelessWidget {
  const TakeMomentIntroScreen({
    super.key,
    this.worryText,
  });

  /// User thoughts from Pour Out Your Worries (display on Let's Pray).
  final String? worryText;

  static const Color _brown = Color(0xFF3D2914);
  static const Color _cream = Color(0xFFF5F0E6);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : _brown;
    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        showBird: false,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: true, textColor: textColor),
                  const SizedBox(width: 12),
                  _dot(active: false, textColor: textColor),
                  const SizedBox(width: 12),
                  _dot(active: false, textColor: textColor),
                ],
              ),
              const SizedBox(height: 28),
              // Same hands + dove icon as Give It to God banner
              Container(
                width: isTablet ? 180 : 150,
                height: isTablet ? 144 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(isDark ? 0.2 : 0.65),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFC9A227).withOpacity(0.18),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/take_moment/give_it_to_god_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Take a Moment With God',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Let\'s slow down and release your worries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 15,
                    color: textColor.withOpacity(0.9),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bullet(
                          Icons.air_rounded,
                          'Breathe in God\'s peace',
                          textColor,
                        ),
                        _bullet(
                          Icons.wb_sunny_outlined,
                          'Rest in His presence',
                          textColor,
                        ),
                        _bullet(
                          Icons.volunteer_activism_outlined,
                          'Release your worries to Him',
                          textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _parchmentButton(
                context,
                label: 'Start',
                onPressed: () => Get.to(
                  () => TakeMomentRestScreen(worryText: worryText),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot({required bool active, required Color textColor}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFC9A227) : Colors.transparent,
        border: Border.all(
          color: active ? const Color(0xFFC9A227) : textColor.withOpacity(0.3),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFC9A227).withOpacity(0.5),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
    );
  }

  Widget _bullet(IconData icon, String text, Color textColor) {
    const gold = Color(0xFFC9A227);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.55),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.28),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 16,
              color: gold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _parchmentButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;
    final lightBtnColor = CommanColor.lightDarkPrimary(context).withOpacity(0.92);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : lightBtnColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark ? const Color(0xFFC9A227) : _cream)
                    .withOpacity(0.75),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _cream,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
