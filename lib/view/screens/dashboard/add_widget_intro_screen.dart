import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Walkthrough for adding home-screen widgets. Swipe left/right or use Next.
/// Opened from Home Screen drawer -> Add Widget.
class AddWidgetIntroScreen extends StatefulWidget {
  const AddWidgetIntroScreen({
    super.key,
    this.iosWidgetKind,
    this.widgetTitle,
  });

  final String? iosWidgetKind;
  final String? widgetTitle;

  @override
  State<AddWidgetIntroScreen> createState() => _AddWidgetIntroScreenState();
}

class _AddWidgetIntroScreenState extends State<AddWidgetIntroScreen> {
  static const List<String> _imagePaths = [
    'assets/home-widgets/widget Mockup 1.png',
    'assets/home-widgets/widget Mockup 2.png',
    'assets/home-widgets/widget Mockup 3.png',
    'assets/home-widgets/widget Mockup 4.png',
    'assets/home-widgets/widget Mockup 5.png',
  ];

  static const List<String> _titles = [
    'Try Home Screen Widget',
    'Press & Hold Screen',
    'Tap \'Edit\' or "+" icon',
    'Search & Find the App',
    'Pick a Widget Style',
  ];

  static const List<String> _subtitles = [
    'Get daily Bible verses and prayers directly on your Home screen',
    'Hold the home screen until apps begin to Shake.',
    'Tap Edit in the top corner and select Add Widget.',
    'Scroll or search "Bible" to locate the widget.',
    'Select a widget size and tap Add Widget',
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  int get _pageCount => _imagePaths.length;

  bool get _isLastPage => _currentPage >= _pageCount - 1;

  Widget _buildSlideImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
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

  Widget _buildTopText(bool isTablet, bool isDark) {
    final titleColor = CommanColor.whiteBlack(context);
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.78)
        : const Color(0xFF5D4037);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _titles[_currentPage],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: isTablet ? 26 : 22,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: isTablet ? 10 : 8),
        Text(
          _subtitles[_currentPage],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  void _onNextTap(bool isDark) {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  Widget _buildPrimaryButton({
    required bool isTablet,
    required bool isLastPage,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
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
        backgroundColor: CommanColor.lightDarkPrimary(context),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 14 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomActions({
    required bool isTablet,
    required bool isDark,
    required bool isFirstPage,
    required bool isLastPage,
  }) {
    if (isLastPage) {
      return SizedBox(
        width: double.infinity,
        child: _buildPrimaryButton(
          isTablet: isTablet,
          isLastPage: true,
          onPressed: () => Get.back(),
        ),
      );
    }

    if (isFirstPage) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: CommanColor.whiteBlack(context),
                side: BorderSide(
                  color: CommanColor.lightDarkPrimary(context).withOpacity(0.5),
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
            child: _buildPrimaryButton(
              isTablet: isTablet,
              isLastPage: false,
              onPressed: () => _onNextTap(isDark),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _buildPrimaryButton(
        isTablet: isTablet,
        isLastPage: false,
        onPressed: () => _onNextTap(isDark),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final path in _imagePaths) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isLastPage = _isLastPage;
    final isFirstPage = _currentPage == 0;
    final pageCount = _pageCount;

    return Scaffold(
      // Solid theme color avoids yellow flash during route transition.
      backgroundColor: isDark
          ? CommanColor.darkPrimaryColor
          : (themeProvider.currentCustomTheme == AppCustomTheme.vintage
              ? const Color(0xFFF5F0E6)
              : themeProvider.backgroundColor),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mockup images
          Positioned(
            top: isTablet ? 180 : 160,
            left: isTablet ? 28 : 16,
            right: isTablet ? 28 : 16,
            bottom: isTablet ? 100 : 90,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) =>
                  _buildSlideImage(_imagePaths[index]),
            ),
          ),

          // Title/subtitle first, then dot indicator below
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 36 : 24,
                  isTablet ? 16 : 12,
                  isTablet ? 36 : 24,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopText(isTablet, isDark),
                    SizedBox(height: isTablet ? 16 : 14),
                    _buildPageDots(context, pageCount, isDark),
                  ],
                ),
              ),
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
                child: _buildBottomActions(
                  isTablet: isTablet,
                  isDark: isDark,
                  isFirstPage: isFirstPage,
                  isLastPage: isLastPage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
