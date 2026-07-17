import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Walkthrough for adding home-screen widgets. Swipe left/right or use Next.
/// Opened from Home Screen drawer -> Add Widget.
class AddWidgetIntroScreen extends StatefulWidget {
  const AddWidgetIntroScreen({super.key});

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

  Widget _buildFullScreenSlide(String path) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(
          color: const Color(0xFFF5F0E6),
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

  Widget _buildTopText(bool isTablet, bool isDark) {
    final title = _titles[_currentPage.clamp(0, _titles.length - 1)];
    final subtitle = _subtitles[_currentPage.clamp(0, _subtitles.length - 1)];
    final textColor = CommanColor.whiteBlack(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 26 : 22,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
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
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final isLastPage = _isLastPage;
    final isFirstPage = _currentPage == 0;
    final pageCount = _pageCount;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      // Always use old paper theme background for this walkthrough.
      backgroundColor: const Color(0xFFF5F0E6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Old paper theme background
          Positioned.fill(
            child: Image.asset(
              Images.bgImage(context),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Mockup images — leave room at top for title + dots
          Positioned(
            top: topInset + (isTablet ? 140 : 128),
            left: isTablet ? 48 : 28,
            right: isTablet ? 48 : 28,
            bottom: isTablet ? 110 : 96,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) =>
                  _buildFullScreenSlide(_imagePaths[index]),
            ),
          ),

          // Title + subtitle above dots (same as before)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots first (top), then title/subtitle below
                    _buildPageDots(context, pageCount, isDark),
                    const SizedBox(height: 14),
                    _buildTopText(isTablet, isDark),
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
