import 'dart:async';
import 'package:biblebookapp/streak_flow/take_moment_released_screen.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "Rest in His presence" - Breathing meditation exercise
class TakeMomentRestScreen extends StatefulWidget {
  const TakeMomentRestScreen({super.key});

  static const String peaceBackground = 'assets/peace-bg.png';
  static const String birdAsset = 'assets/bird.png';

  /// Find Peace flow background: parchment scene + optional dove overlay (UI only).
  static Widget peaceBackgroundStack({
    required Widget child,
    bool isDark = false,
    bool showBird = true,
    double birdWidthFactor = 0.52,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(peaceBackground),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showBird)
          LayoutBuilder(
            builder: (context, constraints) {
              final birdWidth = constraints.maxWidth * birdWidthFactor;
              return Align(
                alignment: const Alignment(0, 0.38),
                child: Image.asset(
                  birdAsset,
                  width: birdWidth,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        if (isDark) Container(color: Colors.black.withOpacity(0.58)),
        child,
      ],
    );
  }

  @override
  State<TakeMomentRestScreen> createState() => _TakeMomentRestScreenState();
}

class _TakeMomentRestScreenState extends State<TakeMomentRestScreen>
    with TickerProviderStateMixin {
  int _count = 10;
  int _maxCount = 10;
  Timer? _timer;
  bool _isHolding = false;
  late AnimationController _breathingController;
  late AnimationController _glowController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _glowAnimation;

  static const Color _deepStone = Color(0xFF2B2416);
  static const Color _softGold = Color(0xFFD4A574);

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_count > 0) {
          _count--;
        } else {
          _timer?.cancel();
          _isHolding = false;
          Get.off(() => const TakeMomentReleasedScreen());
        }
      });
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _isHolding = false;
        _count = _maxCount;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

    final Color accentColor = isDark ? const Color(0xFFC9A227) : _softGold;
    final Color textColor = isDark ? Colors.white : _deepStone;
    final Color secondaryText = isDark ? Colors.white70 : _deepStone;

    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        showBird: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _progressDot(false, accentColor),
                    const SizedBox(width: 16),
                    _progressDot(true, accentColor),
                    const SizedBox(width: 16),
                    _progressDot(false, accentColor),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Rest in',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w400,
                        color: secondaryText.withOpacity(0.9),
                        fontFamily: 'Georgia',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'His presence',
                      style: TextStyle(
                        fontSize: isTablet ? 40 : 34,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A moment to breathe and find peace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 15,
                        color: secondaryText.withOpacity(0.85),
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: Listener(
                    onPointerDown: (_) {
                      if (!_isHolding && mounted) {
                        setState(() => _isHolding = true);
                        _startCountdown();
                      }
                    },
                    onPointerUp: (_) => _stopCountdown(),
                    onPointerCancel: (_) => _stopCountdown(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, _) {
                            return Container(
                              width: isTablet ? 260 : 220,
                              height: isTablet ? 260 : 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(
                                        _glowAnimation.value * 0.25),
                                    blurRadius: 36,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _breathingAnimation,
                          builder: (context, _) {
                            final scale =
                                _isHolding ? 0.98 : _breathingAnimation.value;
                            return Transform.scale(
                              scale: scale,
                              child: _buildMainCircle(
                                isTablet: isTablet,
                                isDark: isDark,
                                accentColor: accentColor,
                                textColor: textColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: AnimatedOpacity(
                  opacity: _isHolding ? 0.35 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.45)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _isHolding
                          ? 'Hold to continue...'
                          : 'Hold the circle to start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: textColor,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
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

  Widget _buildMainCircle({
    required bool isTablet,
    required bool isDark,
    required Color accentColor,
    required Color textColor,
  }) {
    final size = isTablet ? 200.0 : 180.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isHolding
            ? (isDark
                ? Colors.white.withOpacity(0.08)
                : _softGold.withOpacity(0.12))
            : Colors.transparent,
        border: Border.all(
          color: _isHolding ? accentColor : accentColor.withOpacity(0.65),
          width: _isHolding ? 2.5 : 2,
        ),
        boxShadow: [
          if (_isHolding)
            BoxShadow(
              color: accentColor.withOpacity(0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: TextStyle(
                fontSize: isTablet ? 76 : 68,
                fontWeight: FontWeight.w400,
                color: textColor,
                fontFamily: 'Georgia',
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isHolding ? 'Hold' : 'Breathe in',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: textColor.withOpacity(0.8),
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressDot(bool active, Color accentColor) {
    return Container(
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accentColor : Colors.transparent,
        border: Border.all(
          color: accentColor.withOpacity(active ? 1.0 : 0.4),
          width: active ? 0 : 1.5,
        ),
      ),
    );
  }
}
