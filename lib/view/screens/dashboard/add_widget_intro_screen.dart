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

  void _onAddWidgetTap() {
    if (_isIOS && _currentPage < _imagePaths.length - 1) {
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
      body: SafeArea(
        top: !useFullScreen,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: isTablet ? 24 : 16,
                    ),
                    child: Image.asset(
                      _imagePaths[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 32 : 24,
                  16,
                  isTablet ? 32 : 24,
                  isTablet ? 24 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onAddWidgetTap,
                        icon: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        label: Text(
                          'Add Widget',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CommanColor.lightDarkPrimary(context),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          color: Colors.grey,
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
    );
  }
}
