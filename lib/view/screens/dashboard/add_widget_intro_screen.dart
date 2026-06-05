import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Walkthrough for adding home-screen widgets. Advance with the Next button only.
/// Opened from Home Screen drawer -> Add Widget.
class AddWidgetIntroScreen extends StatefulWidget {
  const AddWidgetIntroScreen({super.key});

  @override
  State<AddWidgetIntroScreen> createState() => _AddWidgetIntroScreenState();
}

class _AddWidgetIntroScreenState extends State<AddWidgetIntroScreen> {
  static const List<String> _lightImagePaths = [
    'assets/home-widgets/light-home_1.png',
    'assets/home-widgets/light-home2.png',
    'assets/home-widgets/light-home3.png',
    'assets/home-widgets/light-home4.png',
    'assets/home-widgets/light-home-5.png',
  ];

  static const List<String> _darkImagePaths = [
    'assets/home-widgets/dark-home_1.png',
    'assets/home-widgets/dark-home2.png',
    'assets/home-widgets/dark-home3.png',
    'assets/home-widgets/dark-home-4.png',
    'assets/home-widgets/dark-home-5.png',
  ];

  int _currentPage = 0;

  List<String> _imagePathsForTheme(bool isDark) =>
      isDark ? _darkImagePaths : _lightImagePaths;

  bool _isLastPage(bool isDark) =>
      _currentPage >= _imagePathsForTheme(isDark).length - 1;

  Widget _buildSlideImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: double.infinity,
    );
  }

  void _onNextTap(bool isDark) {
    if (!_isLastPage(isDark)) {
      setState(() => _currentPage++);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final imagePaths = _imagePathsForTheme(isDark);
    final isLastPage = _isLastPage(isDark);

    return Scaffold(
      backgroundColor:
          (isVintage && !isDark) ? null : themeProvider.backgroundColor,
      body: Container(
        decoration: (isVintage && !isDark)
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(color: themeProvider.backgroundColor),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 8,
                    vertical: 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentPage),
                      child: _buildSlideImage(imagePaths[_currentPage]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 28 : 20,
                  12,
                  isTablet ? 28 : 20,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CommanColor.whiteBlack(context),
                          side: BorderSide(
                            color: CommanColor.lightDarkPrimary(context)
                                .withOpacity(0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 14 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Not Now',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _onNextTap(isDark),
                        icon: Icon(
                          isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: isTablet ? 20 : 18,
                        ),
                        label: Text(
                          isLastPage ? 'Got it' : 'Next',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              CommanColor.lightDarkPrimary(context),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 14 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
