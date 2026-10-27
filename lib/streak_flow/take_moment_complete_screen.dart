import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/chat/prayer_guidance_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Leafy parchment page used by Let's Pray and Well done!.
const String takeMomentPaperBg = 'assets/take_moment/take_moment_paper_bg.jpg';
const String takeMomentPrayingHands = 'assets/take_moment/praying_hands.png';
const String _crossHillAsset = 'assets/take_moment/cross_hill.png';

/// Gold line — diamond — gold line, under titles (mockup).
class TakeMomentOrnamentDivider extends StatelessWidget {
  const TakeMomentOrnamentDivider({super.key, this.width = 220});

  final double width;

  static const Color _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gold.withOpacity(0.0),
                  _gold.withOpacity(0.85),
                ],
              ),
            ),
          ),
        );
    return SizedBox(
      width: width,
      child: Row(
        children: [
          line(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.diamond_outlined, size: 16, color: _gold),
          ),
          Expanded(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gold.withOpacity(0.85),
                    _gold.withOpacity(0.0),
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

/// Find Peace flow — single "Well done!" screen after Let's Pray (merges the
/// former confirmation, scripture and completion screens).
class TakeMomentCompleteScreen extends StatelessWidget {
  const TakeMomentCompleteScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _warmTan = Color(0xFF6E5638);

  void _goHome() {
    Get.offAll(() => HomeScreen(
          From: "splash",
          selectedVerseNumForRead: "",
          selectedBookForRead: "",
          selectedChapterForRead: "",
          selectedBookNameForRead: "",
          selectedVerseForRead: "",
        ));
    Future.microtask(() {
      Get.to(
        () => const PrayerGuidanceScreen(),
        transition: Transition.cupertino,
        duration: const Duration(milliseconds: 350),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final lightBtnColor =
        CommanColor.lightDarkPrimary(context).withOpacity(0.92);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(takeMomentPaperBg),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                  child: Column(
                    children: [
                      // Cross on the hill; edges faded into the parchment.
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.18, 0.78, 1.0],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(
                          _crossHillAsset,
                          height: isTablet ? 260 : 210,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Well done!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 46 : 40,
                          fontWeight: FontWeight.w700,
                          color: _brown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You've completed your\nmoment with God.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 21 : 19,
                          height: 1.35,
                          color: _warmTan,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const TakeMomentOrnamentDivider(width: 260),
                      const SizedBox(height: 18),
                      // Scripture card (former separate scripture screen).
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E6CC).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD9C29A),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brown.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '“Cast all your anxiety on Him\nbecause He cares for you.”',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 21 : 18,
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                                color: _brown,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '— 1 Peter 5:7',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14.5,
                                color: _warmTan,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _careItem(
                              icon: Icons.favorite_border,
                              label: 'He Cares',
                              isTablet: isTablet,
                            ),
                          ),
                          _careDivider(),
                          Expanded(
                            child: _careItem(
                              icon: Icons.shield_outlined,
                              label: 'He Strengthens',
                              isTablet: isTablet,
                            ),
                          ),
                          _careDivider(),
                          Expanded(
                            child: _doveCareItem(
                              label: 'He Gives Peace',
                              isTablet: isTablet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goHome,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: lightBtnColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _gold, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: isTablet ? 19 : 18,
                            fontWeight: FontWeight.w600,
                            color: _cream,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 56 : 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _careDivider() => Container(
        width: 1,
        height: 48,
        color: _warmTan.withOpacity(0.3),
      );

  Widget _careItem({
    required IconData icon,
    required String label,
    required bool isTablet,
  }) {
    return Column(
      children: [
        Icon(icon, size: isTablet ? 30 : 26, color: _brown),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            color: _warmTan,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _doveCareItem({
    required String label,
    required bool isTablet,
  }) {
    return Column(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(_brown, BlendMode.srcATop),
          child: Image.asset(
            'assets/dove.png',
            width: isTablet ? 30 : 26,
            height: isTablet ? 30 : 26,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            color: _warmTan,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
