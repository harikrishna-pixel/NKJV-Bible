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

  // 2x2 feature cards (reference UI): gold line icons + label.
  static const List<({IconData? icon, String? asset, String label})>
      _features = [
    (
      icon: Icons.menu_book_rounded,
      asset: null,
      label: 'Understand\nScripture',
    ),
    (
      icon: null,
      asset: 'assets/take_moment/praying_hands.png',
      label: 'Pray Together',
    ),
    (
      icon: Icons.headphones_rounded,
      asset: null,
      label: 'Audio Bible',
    ),
    (
      icon: Icons.auto_awesome,
      asset: null,
      label: 'AI Bible\nAssistant',
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
                                // Always single logo — Old/New comparison hidden for now.
                                // Logic (_loadLogoMode / showWelcomeLogoComparison) unchanged.
                                child: _welcomeSingleNewLogo(
                                  isTablet: isTablet,
                                ),
                                // child: showComparison
                                //     ? _welcomeLogoComparison(
                                //         isTablet: isTablet)
                                //     : _welcomeSingleNewLogo(
                                //         isTablet: isTablet),
                              ),
                              SizedBox(height: isTablet ? 22 : 18),
                              Text(
                                'Welcome to',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.w700,
                                  color: _kWelcomeInk,
                                  fontFamily: 'Georgia',
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                BibleInfo.bible_shortName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 46 : 40,
                                  fontWeight: FontWeight.w800,
                                  color: _kWelcomeInk,
                                  fontFamily: 'Georgia',
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _welcomeGoldDivider(),
                              const SizedBox(height: 14),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 12,
                                ),
                                child: Text(
                                  'Read, pray, and grow closer\nto God every day.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 19 : 17,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: _kWelcomeInk.withOpacity(0.9),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 26 : 22),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 0 : 6,
                                ),
                                child: Column(
                                  children: [
                                    for (var row = 0; row < 2; row++) ...[
                                      if (row > 0)
                                        SizedBox(height: isTablet ? 14 : 12),
                                      Row(
                                        children: [
                                          for (var col = 0;
                                              col < 2;
                                              col++) ...[
                                            if (col > 0)
                                              SizedBox(
                                                  width: isTablet ? 14 : 12),
                                            Expanded(
                                              child: _WelcomeFeatureCard(
                                                icon: _features[row * 2 + col]
                                                    .icon,
                                                iconAsset:
                                                    _features[row * 2 + col]
                                                        .asset,
                                                label: _features[row * 2 + col]
                                                    .label,
                                                isTablet: isTablet,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
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
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF8A5530),
                            Color(0xFF5C3317),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C3317).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _continueToOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: isTablet ? 21 : 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: isTablet ? 24 : 22,
                            ),
                          ],
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
    final iconSize = isTablet ? 170.0 : 150.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _kWelcomeBrown.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/new_logos.jpg',
          height: iconSize,
          width: iconSize,
          fit: BoxFit.cover,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: _kWelcomeGold.withOpacity(0.8),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '✝',
              style: TextStyle(fontSize: 16, color: _kWelcomeGold),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _kWelcomeGold.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

}

class _WelcomeFeatureCard extends StatelessWidget {
  const _WelcomeFeatureCard({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.isTablet,
  });

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final bool isTablet;

  static const Color _gold = Color(0xFFB8862E);

  @override
  Widget build(BuildContext context) {
    final iconSize = isTablet ? 40.0 : 36.0;
    return Container(
      height: isTablet ? 118 : 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D7B8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C4033).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: iconSize,
            width: iconSize,
            child: iconAsset != null
                ? Image.asset(
                    iconAsset!,
                    color: _gold,
                    colorBlendMode: BlendMode.srcIn,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, size: iconSize, color: _gold),
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Georgia',
              color: _WelcomeScreenState._kWelcomeInk,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}