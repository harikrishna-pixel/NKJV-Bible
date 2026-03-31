import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "You have released your worries to God." + verse 1 Peter 5:7, "Continue Your Journey".
/// Final screen of Find Peace flow; tapping Continue goes to Home Screen.
class TakeMomentReleasedScreen extends StatelessWidget {
  const TakeMomentReleasedScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeMode.dark;
    final List<Color> gradientColors = isDark
        ? [CommanColor.darkPrimaryColor, CommanColor.darkPrimaryColor, CommanColor.darkPrimaryColor]
        : [const Color(0xFFF5F0E6), const Color(0xFFE8DED0), const Color(0xFFDDD0C0)];
    final Color textColor = isDark ? Colors.white : _brown;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
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
              const SizedBox(height: 48),
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
              const SizedBox(height: 24),
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
                      onTap: () {
                        Get.offAll(() => HomeScreen(
                              From: "splash",
                              selectedVerseNumForRead: "",
                              selectedBookForRead: "",
                              selectedChapterForRead: "",
                              selectedBookNameForRead: "",
                              selectedVerseForRead: "",
                            ));
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF8B7355),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: _gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Continue Your Journey',
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
              ),
              const SizedBox(height: 48),
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
        boxShadow: active ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 8)] : null,
      ),
    );
  }
}
