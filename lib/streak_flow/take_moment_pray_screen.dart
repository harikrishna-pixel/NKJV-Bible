import 'package:biblebookapp/streak_flow/take_moment_released_screen.dart';
import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Find Peace flow — short prayer after breathing (Amen / Skip).
class TakeMomentPrayScreen extends StatefulWidget {
  const TakeMomentPrayScreen({super.key});

  @override
  State<TakeMomentPrayScreen> createState() => _TakeMomentPrayScreenState();
}

class _TakeMomentPrayScreenState extends State<TakeMomentPrayScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _warmTan = Color(0xFF8B7355);

  bool _navigating = false;

  void _continue() {
    if (_navigating) return;
    _navigating = true;
    Get.off(() => const TakeMomentReleasedScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : _brown;
    final Color softText = isDark ? Colors.white70 : _warmTan;

    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        showBird: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: textColor.withOpacity(0.85),
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(active: false, textColor: textColor),
                          const SizedBox(width: 12),
                          _dot(active: false, textColor: textColor),
                          const SizedBox(width: 12),
                          _dot(active: true, textColor: textColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Container(
                width: isTablet ? 168 : 144,
                height: isTablet ? 140 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(isDark ? 0.18 : 0.7),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: _gold.withOpacity(0.22),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/take_moment/lets_pray_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Let's Pray",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  'God,\n'
                  'I give You what I cannot carry.\n'
                  'Quiet my heart, guide my thoughts,\n'
                  'and help me rest in\n'
                  'Your presence.\n'
                  'Amen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    height: 1.65,
                    color: softText,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const Spacer(flex: 3),
              _primaryButton(
                context,
                label: 'Amen',
                onPressed: _continue,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _continue,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 15,
                    color: softText,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
        color: active ? _gold : Colors.transparent,
        border: Border.all(
          color: active ? _gold : textColor.withOpacity(0.3),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final lightBtnColor =
        CommanColor.lightDarkPrimary(context).withOpacity(0.92);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.45) : lightBtnColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _gold.withOpacity(isDark ? 0.85 : 1),
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
