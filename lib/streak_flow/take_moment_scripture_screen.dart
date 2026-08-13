import 'dart:async';

import 'package:biblebookapp/streak_flow/take_moment_complete_screen.dart';
import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Find Peace flow — scripture encouragement after placing worries.
class TakeMomentScriptureScreen extends StatefulWidget {
  const TakeMomentScriptureScreen({super.key});

  @override
  State<TakeMomentScriptureScreen> createState() =>
      _TakeMomentScriptureScreenState();
}

class _TakeMomentScriptureScreenState extends State<TakeMomentScriptureScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _warmTan = Color(0xFF8B7355);
  static const Duration _autoAdvance = Duration(seconds: 5);

  Timer? _timer;
  bool _held = false;
  bool _navigating = false;

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
      if (!mounted || _held || _navigating) return;
      _continue();
    });
  }

  void _onBodyTap() {
    // First tap: hold / pause auto-advance. Second tap: go next.
    if (_held) {
      _continue();
      return;
    }
    _timer?.cancel();
    _timer = null;
    setState(() => _held = true);
  }

  void _continue() {
    if (_navigating) return;
    _navigating = true;
    _timer?.cancel();
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
        showBird: false,
        child: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBodyTap,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(active: false, textColor: textColor),
                        const SizedBox(width: 12),
                        _dot(active: false, textColor: textColor),
                        const SizedBox(width: 12),
                        _dot(active: true, textColor: textColor),
                      ],
                    ),
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
                    if (_held)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Tap again to continue',
                          style: TextStyle(
                            fontSize: 13,
                            color: softText.withOpacity(0.8),
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _continue,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: isTablet ? 44 : 38,
                          color: softText.withOpacity(0.9),
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

  Widget _dot({required bool active, required Color textColor}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _gold : Colors.transparent,
        border: Border.all(
          color: active ? _gold : textColor.withOpacity(0.3),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 8)]
            : null,
      ),
    );
  }
}
