import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/onboard_faith_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const String _kWelcomeBg = 'assets/welcome-screen-bg.png';
  static const Color _kWelcomeInk = Color(0xFF3D2914);
  static const Color _kWelcomeGold = Color(0xFFC59434);
  static const Color _kWelcomeBrown = Color(0xFF5C4033);

  static const List<({String icon, String label})> _features = [
    (
    icon: 'assets/splash_welcome_icons/bible_assitant.png',
    label: 'AI Bible\nAssistant',
    ),
    (
    icon: 'assets/splash_welcome_icons/prayer_support.png',
    label: 'Prayer\nSupport',
    ),
    (
    icon: 'assets/splash_welcome_icons/easier-reading.png',
    label: 'Easier\nReading',
    ),
    (
    icon: 'assets/splash_welcome_icons/audio_bible.png',
    label: 'Audio\nBible',
    ),
  ];

  /// null while loading flag; false = new user (single logo); true = upgrader.
  bool? _showLogoComparison;

  @override
  void initState() {
    super.initState();
    _loadLogoMode();
  }

  Future<void> _loadLogoMode() async {
    final show = await SharPreferences.getBoolean(
        SharPreferences.showWelcomeLogoComparison) ??
        false;
    if (!mounted) return;
    setState(() => _showLogoComparison = show);
  }

  void _continueToOnboarding() {
    Get.offAll(() => const FaithOnboardingScreen());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final showComparison = _showLogoComparison ?? false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _kWelcomeBg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? size.width * 0.14 : 16,
                          isTablet ? 8 : 4,
                          isTablet ? size.width * 0.14 : 16,
                          isTablet ? 12 : 8,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: showComparison
                                    ? _welcomeLogoComparison(
                                    isTablet: isTablet)
                                    : _welcomeSingleNewLogo(
                                    isTablet: isTablet),
                              ),
                              SizedBox(height: isTablet ? 18 : 14),
                              Text(
                                'Welcome to the',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: _kWelcomeInk,
                                  fontFamily: 'Georgia',
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                BibleInfo.bible_shortName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 34 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: _kWelcomeInk,
                                  fontFamily: 'Georgia',
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _welcomeGoldDivider(),
                              const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 8,
                                ),
                                child: Text(
                                  'The Bible you trust, now with a refreshed design and powerful new tools to support your daily walk with God.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 17 : 14.5,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                    color: _kWelcomeInk.withOpacity(0.9),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 20 : 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0;
                                  i < _features.length;
                                  i++) ...[
                                    if (i > 0)
                                      SizedBox(width: isTablet ? 10 : 6),
                                    Expanded(
                                      child: _WelcomeFeatureCard(
                                        iconAsset: _features[i].icon,
                                        label: _features[i].label,
                                        isTablet: isTablet,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? size.width * 0.14 + 18 : 18,
                    isTablet ? 12 : 8,
                    isTablet ? size.width * 0.14 + 18 : 18,
                    isTablet ? 18 : 14,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: isTablet ? 64 : 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF763201),
                            Color(0xFFD5821F),
                            Color(0xFF763201),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: _continueToOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Additive: new users — only the in-app new logo (no Old→New row).
  Widget _welcomeSingleNewLogo({required bool isTablet}) {
    final iconSize = isTablet ? 128.0 : 110.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/new_logos.jpg',
        height: iconSize,
        width: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _welcomeLogoComparison({required bool isTablet}) {
    final iconSize = isTablet ? 118.0 : 100.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/Icon-1024.png',
                height: iconSize,
                width: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Old Look',
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w500,
                color: _kWelcomeInk.withOpacity(0.75),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 20 : 14,
            iconSize * 0.38,
            isTablet ? 20 : 14,
            0,
          ),
          child: Icon(
            Icons.arrow_forward,
            size: isTablet ? 22 : 18,
            color: _kWelcomeBrown,
          ),
        ),
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/new_logos.jpg',
                height: iconSize,
                width: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New Look',
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w500,
                color: _kWelcomeInk.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _welcomeGoldDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          _welcomeDividerDot(),
          Expanded(
            child: Container(
              height: 1,
              color: _kWelcomeGold.withOpacity(0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.add,
              size: 14,
              color: _kWelcomeGold,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _kWelcomeGold.withOpacity(0.8),
            ),
          ),
          _welcomeDividerDot(),
        ],
      ),
    );
  }

  Widget _welcomeDividerDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: _kWelcomeGold.withOpacity(0.85),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _WelcomeFeatureCard extends StatelessWidget {
  const _WelcomeFeatureCard({
    required this.iconAsset,
    required this.label,
    required this.isTablet,
  });

  final String iconAsset;
  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 6 : 2,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C4033).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: isTablet ? 98 : 88,
            width: double.infinity,
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: isTablet ? 1.12 : 1.15,
                  child: Image.asset(
                    iconAsset,
                    height: isTablet ? 72 : 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 11.5 : 10,
              fontWeight: FontWeight.w500,
              color: _WelcomeScreenState._kWelcomeInk.withOpacity(0.88),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}