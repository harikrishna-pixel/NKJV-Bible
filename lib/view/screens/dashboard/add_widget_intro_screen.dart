import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows the 5 home-widget images one by one with swipe; user taps "Add Widget"
/// to advance or on last screen close and return to Home.
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

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isIOS => Platform.isIOS;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= _imagePaths.length - 1;

  void _onAddWidgetTap() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final useFullScreen = _isIOS;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: CommanColor.backgrondcolor,
      appBar: useFullScreen
          ? null
          : AppBar(
              backgroundColor: CommanColor.lightDarkPrimary(context),
              leading: IconButton(
                icon: Icon(
                    Icons.arrow_back_ios,
                    color: CommanColor.whiteBlack(context)),
                onPressed: () => Get.back(),
              ),
              title: Text(
                'Add Widget',
                style: TextStyle(
                  color: CommanColor.whiteBlack(context),
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _imagePaths[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          Positioned(
            left: isTablet ? 32 : 18,
            right: isTablet ? 32 : 18,
            bottom: (isTablet ? 18 : 14) + bottomInset,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 6 : 2,
                  vertical: isTablet ? 4 : 2,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        foregroundColor: Colors.white.withValues(alpha: 0.95),
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _onAddWidgetTap,
                      icon: Icon(Icons.arrow_forward,
                          color: Colors.white, size: isTablet ? 18 : 16),
                      label: Text(
                        _isLastPage ? 'Got it' : 'Next',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommanColor.lightDarkPrimary(context),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 18 : 14,
                          vertical: isTablet ? 14 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
