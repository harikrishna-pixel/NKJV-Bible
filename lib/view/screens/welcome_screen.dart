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

                  SizedBox(height: 100,),
                  // Welcome Image
                  Image.asset(
                    "assets/new_ico.png",
                    height: isTablet ? 150 : 100,
                    width: isTablet ? 150 : 100,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 30,),
                  // Title
                  Text(
                    "Begin Your Daily \n Bible Journey!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 34 : 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 12),

                  // Subtitle
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 17,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      children: const [
                        TextSpan(
                          text: "We’re grateful you’re here.\n",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                          "Let’s personalize your Bible experience \n"
                              "to make every reading more meaningful, powerful, and peaceful.",
                        ),
                      ],
                    ),
                  ),


                  SizedBox(height: isTablet ? 16 : 30),

                  // Italic line
                  Text(
                    "Just a few quick steps to get started..",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
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
                  Spacer(
                    flex: 1,
                  ),
                  // Text(
                  //   "Designed to help you grow daily in God’s Word",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     fontSize: isTablet ? 18 : 13,
                  //     fontStyle: FontStyle.normal,
                  //     color: Colors.black87,
                  //   ),
                  // ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
