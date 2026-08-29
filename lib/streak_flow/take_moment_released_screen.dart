import 'dart:async';

import 'package:biblebookapp/streak_flow/take_moment_complete_screen.dart';
import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// After Amen: confirmation first, then scripture — one route, no stacked overlap.
/// Tap or 10s advances to the next step only once.
class TakeMomentReleasedScreen extends StatefulWidget {
  const TakeMomentReleasedScreen({super.key});

  @override
  State<TakeMomentReleasedScreen> createState() =>
      _TakeMomentReleasedScreenState();
}

class _TakeMomentReleasedScreenState extends State<TakeMomentReleasedScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _warmTan = Color(0xFF8B7355);
  static const Duration _autoAdvance = Duration(seconds: 10);

  /// 0 = placed confirmation, 1 = scripture
  int _step = 0;
  Timer? _timer;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    _timer = Timer(_autoAdvance, () {
      if (!mounted || _advancing) return;
      _goNext();
    });
  }

  void _goNext() {
    if (_advancing || !mounted) return;
    _advancing = true;
    _timer?.cancel();
    _timer = null;

    if (_step == 0) {
      setState(() {
        _step = 1;
        _advancing = false;
      });
      _startAutoAdvance();
      return;
    }

    Get.off(() => const TakeMomentCompleteScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : _brown;
    final Color softText = isDark ? Colors.white70 : _warmTan;

    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        showBird: _step == 0,
        birdWidthFactor: 0.55,
        child: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _goNext,
                child: _step == 0
                    ? _buildPlacedStep(
                        isTablet: isTablet,
                        textColor: textColor,
                        softText: softText,
                      )
                    : _buildScriptureStep(
                        isTablet: isTablet,
                        isDark: isDark,
                        textColor: textColor,
                        softText: softText,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacedStep({
    required bool isTablet,
    required Color textColor,
    required Color softText,
  }) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold.withOpacity(0.15),
            border: Border.all(color: _gold, width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: _gold,
            size: 32,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "You've taken a moment to place your worries in God's hands.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Georgia',
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(
                child: Divider(color: textColor.withOpacity(0.25)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.favorite,
                  size: isTablet ? 16 : 14,
                  color: _gold,
                ),
              ),
              Expanded(
                child: Divider(color: textColor.withOpacity(0.25)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'He is with you and will carry what you cannot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 17 : 15,
              color: softText,
              fontFamily: 'Georgia',
              height: 1.45,
            ),
          ),
        ),
        const Spacer(flex: 3),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildScriptureStep({
    required bool isTablet,
    required bool isDark,
    required Color textColor,
    required Color softText,
  }) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: isTablet ? 100 : 84,
          height: isTablet ? 100 : 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.55),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/take_moment/apostrophe_icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            '"Cast all your anxiety on Him because He cares for you."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '— 1 Peter 5:7',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: softText,
            fontFamily: 'Georgia',
          ),
        ),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _careItem(
                icon: Icons.favorite_border,
                label: 'He Cares',
                color: softText,
                isTablet: isTablet,
              ),
              _careItem(
                icon: Icons.shield_outlined,
                label: 'He Strengthens',
                color: softText,
                isTablet: isTablet,
              ),
              _doveCareItem(
                label: 'He Gives Peace',
                color: softText,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _careItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Column(
      children: [
        Icon(icon, size: isTablet ? 28 : 24, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: color,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _doveCareItem({
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Column(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
          child: Image.asset(
            'assets/dove.png',
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: color,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}
