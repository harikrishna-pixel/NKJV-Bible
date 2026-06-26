import 'package:biblebookapp/view/constants/colors.dart';
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
    'assets/home-widgets/light-home_2.png',
    'assets/home-widgets/light-home_3.png',
    'assets/home-widgets/light-home_4.png',
    'assets/home-widgets/light-home_5.png',
  ];

  static const List<String> _darkImagePaths = [
    'assets/home-widgets/Dark-home_1.png',
    'assets/home-widgets/Dark-home_2.png',
    'assets/home-widgets/Dark-home_3.png',
    'assets/home-widgets/Dark-home_4.png',
    'assets/home-widgets/Dark-home_5.png',
  ];

  /// Shifts cover downward to hide baked-in dots/title baked into slide PNGs.
  static const Alignment _slideAlignment = Alignment(0, 0.18);

  int _currentPage = 0;

  List<String> _imagePathsForTheme(bool isDark) =>
      isDark ? _darkImagePaths : _lightImagePaths;

  int _pageCount(bool isDark) => _imagePathsForTheme(isDark).length;

  bool _isLastPage(bool isDark) =>
      _currentPage >= _pageCount(isDark) - 1;

  Widget _buildFullScreenSlide(String path) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false)
            .themeMode ==
        ThemeMode.dark;
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: _slideAlignment,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(
          color: isDark
              ? CommanColor.darkPrimaryColor
              : Provider.of<ThemeProvider>(context, listen: false)
                  .backgroundColor,
          child: child,
        );
      },
    );
  }

  /// Top indicator — matches baked center-dot style (pill + gold dots).
  Widget _buildPageDots(BuildContext context, int count, bool isDark) {
    const slotWidth = 28.0;
    final activeColor = CommanColor.lightDarkPrimary(context);
    final inactiveColor =
    isDark ? activeColor.withOpacity(0.35) : const Color(0xFFE5B889);

    // Directionality ensures dots always render left-to-right (index 0 → last)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final active = index == _currentPage;
          return SizedBox(
            width: slotWidth,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDark = Provider.of<ThemeProvider>(context, listen: false)
              .themeMode ==
          ThemeMode.dark;
      for (final path in _imagePathsForTheme(isDark)) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final imagePaths = _imagePathsForTheme(isDark);
    final isLastPage = _isLastPage(isDark);
    final pageCount = _pageCount(isDark);

    return Scaffold(
      backgroundColor: isDark
          ? CommanColor.darkPrimaryColor
          : themeProvider.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _currentPage,
            sizing: StackFit.expand,
            children: [
              for (final path in imagePaths) _buildFullScreenSlide(path),
            ],
          ),

          // Top page dots indicator
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 700),
              child: _buildPageDots(context, pageCount, isDark),
            ),
          ),

          // Bottom buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
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
            ),
          ),
        ],
      ),
    );
  }
}