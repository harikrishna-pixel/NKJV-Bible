import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Find Peace flow — final "Well done!" completion screen.
class TakeMomentCompleteScreen extends StatelessWidget {
  const TakeMomentCompleteScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _warmTan = Color(0xFF8B7355);

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
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : _brown;
    final Color softText = isDark ? Colors.white70 : _warmTan;
    final lightBtnColor =
        CommanColor.lightDarkPrimary(context).withOpacity(0.92);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/take_moment/take_moment_complete_bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          if (isDark) Container(color: Colors.black.withOpacity(0.45)),
          SafeArea(
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
                const Spacer(flex: 3),
                Text(
                  'Well done!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 36 : 32,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    "You've completed your moment with God.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15,
                      color: softText,
                      fontFamily: 'Georgia',
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _goHome,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: double.infinity,
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
                        child: Center(
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : _cream,
                              fontFamily: 'Georgia',
                            ),
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
                    'Return to Prayer',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      color: softText,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
