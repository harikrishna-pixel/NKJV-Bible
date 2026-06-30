import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Final screen of Find Peace flow; tapping Continue goes to Home Screen.
class TakeMomentReleasedScreen extends StatelessWidget {
  const TakeMomentReleasedScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);

  void _goHome() {
    Get.offAll(() => HomeScreen(
          From: "splash",
          selectedVerseNumForRead: "",
          selectedBookForRead: "",
          selectedChapterForRead: "",
          selectedBookNameForRead: "",
          selectedVerseForRead: "",
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;
    final lightBtnColor = CommanColor.lightDarkPrimary(context).withOpacity(0.92);
    final Color textColor = isDark ? Colors.white : _brown;
    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: false, textColor: textColor),
                  const SizedBox(width: 12),
                  _dot(active: false, textColor: textColor),
                  const SizedBox(width: 12),
                  _dot(active: true, textColor: textColor),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withOpacity(0.15),
                  border: Border.all(color: _gold, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: _gold, size: 32),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'You have released your worries to God.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: textColor.withOpacity(0.25),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '◆',
                        style: TextStyle(
                          color: _gold,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: textColor.withOpacity(0.25),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '"Cast all your anxiety on Him because He cares for you."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    fontFamily: 'Georgia',
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '— 1 Peter 5:7',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: textColor.withOpacity(0.85),
                  fontFamily: 'Georgia',
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _goHome,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.45)
                              : lightBtnColor,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue Your Journey',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : _cream,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? Colors.white : _cream,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goHome,
                child: Text(
                  'Return to Home',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: textColor.withOpacity(0.85),
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
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
}
