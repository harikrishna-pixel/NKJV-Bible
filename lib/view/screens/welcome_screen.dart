import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/notification_info_screen.dart';
import 'package:biblebookapp/view/screens/onboard_faith_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600; // Simple check for iPad vs i
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final shadowColor = isDark ? const Color(0x40000000) : const Color(0x26000000);
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                Images.bgImage(context)), // your parchment background
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isTablet ? size.width * 0.2 : 15, // wider margin for iPad
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Old logo → New logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          "assets/Icon-1024.png",
                          height: isTablet ? 128 : 100,
                          width: isTablet ? 128 : 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 24),
                        child: Icon(
                          Icons.arrow_forward,
                          size: isTablet ? 32 : 24,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          "assets/new_logos.jpg",
                          height: isTablet ? 128 : 100,
                          width: isTablet ? 128 : 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 28 : 24),
                  // Title — high contrast for readability on any background
                  Text(
                    "New Look, Same Bible",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 30 : 27,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: shadowColor,
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 12),

                  // First paragraph — clear contrast on light or gradient background
                  Text(
                    "We're grateful you're here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 17,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: shadowColor,
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),

                  // Second paragraph — strong contrast so descriptive text is clearly visible
                  Text(
                    "We've refreshed our app with a new look and added helpful ways to connect with God, including prayer and guided conversations.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 17,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: shadowColor,
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 40 : 24),

                  // Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 65),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.offAll(() => const FaithOnboardingScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // REQUIRED
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF763201),
                                Color(0xFFD5821F),
                                Color(0xFF763201),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 20 : 14,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Let's Begin →",
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
