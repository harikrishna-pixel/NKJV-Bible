import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/onboard_faith_screen.dart';
import 'package:biblebookapp/view/screens/welcome_screen.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationInfoScreen extends StatelessWidget {
  const NotificationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? size.width * 0.2 : 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100,),
                // Notification Image
                Image.asset(
                  "assets/bell.png",
                  height: isTablet ? 160 : 120,
                  width: isTablet ? 160 : 120,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: isTablet ? 30 : 24),

                // Title
                Text(
                  "Stay Connected to \n God’s Word",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 34 : 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: isTablet ? 20 : 16),

                // Description
                Text(
                  "We’ll send notifications to help you \n stay on track with daily verses, \n prayer reminders and more.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: isTablet ? 40 : 32),

                Text(
                  "You can change these preferences \n  anytime in Settings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: isTablet ? 40 : 32),
                // Got it Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 80 : 40,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5C3D),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        // Mark notification info as shown
                        await SharPreferences.setBoolean('notification_info_shown', true);

                        // Navigate to usual flow
                        _navigateToNextScreen();
                      },
                      child: Text(
                        "Got it",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(
                  flex: 3,
                ),
                Text(
                  "Your privacy is always respected",
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToNextScreen() async {
    final isOnboardingCompleted =
        await SharPreferences.getBoolean(SharPreferences.onboarding);
    if (isOnboardingCompleted == null || !isOnboardingCompleted) {
      await SharPreferences.setBoolean(SharPreferences.onboarding, true);
      Get.offAll(() => const FaithOnboardingScreen());
    } else {
      Future.delayed(
        const Duration(seconds: 1),
        () {
          SharPreferences.setBoolean(SharPreferences.isLoadBookContent, true);
          Get.offAll(() => HomeScreen(
              From: "splash",
              selectedVerseNumForRead: "",
              selectedBookForRead: "",
              selectedChapterForRead: "",
              selectedBookNameForRead: "",
              selectedVerseForRead: ""));
        },
      );
    }
  }
}

