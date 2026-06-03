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
  static const List<String> _imagePaths = [
    'assets/home-widgets/home-1.png',
    'assets/home-widgets/home-2.png',
    'assets/home-widgets/home-3.png',
    'assets/home-widgets/home-4.png',
    'assets/home-widgets/home-5.png',
  ];

  static const List<String> _stepHints = [
    'Long-press an empty area on your Home Screen.',
    'Tap the + button, then search for this app.',
    'Choose a widget size you like.',
    'Drag the widget where you want it on your Home Screen.',
    'You\'re all set — enjoy your Bible widget!',
  ];

  int _currentPage = 0;

  bool get _isLastPage => _currentPage >= _imagePaths.length - 1;

  /// Images include a baked-in dot row at the top; crop it so only app dots show.
  Widget _buildCroppedSlideImage(String path) {
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.93,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }

  void _onNextTap() {
    if (!_isLastPage) {
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
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    return Scaffold(
      backgroundColor: isVintage ? null : themeProvider.backgroundColor,
      body: Container(
        decoration: isVintage
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'Add Widget',
                        textAlign: TextAlign.center,
                        style: CommanStyle.appBarStyle(context).copyWith(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
                child: Text(
                  'Step ${_currentPage + 1} of ${_imagePaths.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: CommanColor.whiteBlack(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 20),
                child: Text(
                  _stepHints[_currentPage],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    height: 1.35,
                    color: CommanColor.whiteBlack(context).withOpacity(0.85),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imagePaths.length, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? CommanColor.lightDarkPrimary(context)
                          : CommanColor.lightDarkPrimary(context)
                              .withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isVintage
                          ? Colors.white.withOpacity(0.92)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CommanColor.lightDarkPrimary(context)
                            .withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentPage),
                            child: _buildCroppedSlideImage(
                              _imagePaths[_currentPage],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
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
                          onPressed: _onNextTap,
                          icon: Icon(
                            _isLastPage
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: isTablet ? 20 : 18,
                          ),
                          label: Text(
                            _isLastPage ? 'Got it' : 'Next',
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
            ],
          ),
        ),
      ),
    );
  }
}
