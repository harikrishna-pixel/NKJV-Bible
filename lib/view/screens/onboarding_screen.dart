import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<String> boardingImages = [
    'assets/onboarding/1.jpg',
    'assets/onboarding/2.jpg',
    'assets/onboarding/3.jpg',
    'assets/onboarding/4.jpg',
    'assets/onboarding/5.jpg',
  ];

  late PageController pageController;
  late int currentIndex;

  pageListener() {
    currentIndex = pageController.page?.toInt() ?? 0;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    pageController = PageController();
    pageController.addListener(pageListener);
  }

  endNavigation() async {
    //  Get.offAll(() => SignupScreen());
    Get.offAll(() => PreferenceSelectionScreen(
          isSetting: false,
        ));
  }

  // Future<void> requestTrackingPermission() async {
  //   final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  //   if (status == TrackingStatus.notDetermined) {
  //     await AppTrackingTransparency.requestTrackingAuthorization();
  //   }
  // }

  /// First onboarding page: app logo, official typography, no book icon.
  Widget _buildFirstOnboardingPage(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A2C6A),
            Color(0xFF5E3A7A),
            Color(0xFFE8E0F0),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 24),
          child: Column(
            children: [
              SizedBox(height: isTablet ? 50 : 36),
              // App logo (replaces book icon)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A2C6A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/Icon-1024.png',
                    width: isTablet ? 120 : 88,
                    height: isTablet ? 120 : 88,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 36 : 28),
              // Title — clean, official typography (sans-serif)
              Text(
                'Grow Closer to God\nEvery Day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: Colors.white,
                  fontFamily: 'Arial',
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              // Subtitle — readable contrast
              Text(
                'Your AI-powered Bible companion for reading, prayer, and spiritual guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 17 : 15,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3D3D3D),
                  fontFamily: 'Arial',
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.9),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFirstOnboardingPage(context);
                }
                return Image.asset(
                  boardingImages[index],
                  fit: BoxFit.cover,
                );
              },
              itemCount: boardingImages.length,
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).viewPadding.top + 20,
              child: GestureDetector(
                onTap: () {
                  endNavigation();
                },
                child: Text("Skip",
                    style: (screenWidth > 450
                        ? CommanStyle.bw14400(context).copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: currentIndex == 0 ? Colors.white : Colors.black,
                            fontSize: BibleInfo.fontSizeScale * 25,
                            color: currentIndex == 0 ? Colors.white : Colors.black)
                        : CommanStyle.bw14400(context).copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: currentIndex == 0 ? Colors.white : Colors.black,
                            color: currentIndex == 0 ? Colors.white : Colors.black))),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              child: SmoothPageIndicator(
                controller: pageController,
                count: boardingImages.length,
                effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    strokeWidth: 3,
                    activeDotColor: CommanColor.darkPrimaryColor),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  if (currentIndex + 1 < boardingImages.length) {
                    pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn);
                  } else {
                    endNavigation();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CommanColor.darkPrimaryColor,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
