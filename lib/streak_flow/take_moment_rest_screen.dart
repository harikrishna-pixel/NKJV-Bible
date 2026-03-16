import 'dart:async';
import 'package:biblebookapp/streak_flow/take_moment_released_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "Rest in His presence" - Breathing meditation exercise
/// Serene, professional UI designed to reduce stress and create a sanctuary-like experience
class TakeMomentRestScreen extends StatefulWidget {
  const TakeMomentRestScreen({super.key});

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
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _glowAnimation;

  // Serene color palette
  static const Color _deepStone = Color(0xFF2B2416);
  static const Color _warmBeige = Color(0xFFF5F0E6);
  static const Color _softGold = Color(0xFFD4A574);
  static const Color _paleSage = Color(0xFFE8ECDC);
  static const Color _dustyBlue = Color(0xFF5C6B7C);

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

    // Breathing animation - slow, meditative cycle
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    // Glow animation for calming effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    // Pulse for interaction feedback
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

    final Color backgroundColor = isDark ? const Color(0xFF1A1410) : _warmBeige;
    final Color accentColor = isDark ? const Color(0xFFC9A227) : _softGold;
    final Color textColor = isDark ? Colors.white : _deepStone;
    final Color secondaryText = isDark ? Colors.white70 : _deepStone;

    final List<Color> gradientColors = isDark
        ? [
            const Color(0xFF1A1410),
            const Color(0xFF2A231A),
            const Color(0xFF1A1410)
          ]
        : [
            const Color(0xFFFAF7F1),
            const Color(0xFFF5F0E6),
            const Color(0xFFEFE9DD)
          ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress dots with subtle animation
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 32),
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

              // Header text with refined typography
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      'Rest in',
                      style: TextStyle(
                        fontSize: isTablet ? 26 : 22,
                        fontWeight: FontWeight.w400,
                        color: secondaryText,
                        fontFamily: 'Georgia',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'His presence',
                      style: TextStyle(
                        fontSize: isTablet ? 42 : 36,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Georgia',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Subtitle with gentle guidance
              Text(
                'A moment to breathe and find peace',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: secondaryText,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 48),

              // Main breathing circle with multiple layers
              Expanded(
                child: Center(
                  child: Listener(
                    onPointerDown: (_) {
                      if (!_isHolding && mounted) {
                        setState(() => _isHolding = true);
                        _pulseController.forward();
                        _startCountdown();
                      }
                    },
                    onPointerUp: (_) => _stopCountdown(),
                    onPointerCancel: (_) => _stopCountdown(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow effect
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, _) {
                            return Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(
                                        _glowAnimation.value * 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Breathing circle animation
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

              // Instructional text below circle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  children: [
                    AnimatedOpacity(
                      opacity: _isHolding ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isHolding
                            ? 'Hold to continue...'
                            : 'Hold the circle to start',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13,
                          color: secondaryText,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isHolding
            ? (isDark
                ? Colors.white.withOpacity(0.08)
                : _softGold.withOpacity(0.15))
            : Colors.transparent,
        border: Border.all(
          color: _isHolding ? accentColor : accentColor.withOpacity(0.6),
          width: _isHolding ? 3 : 2.5,
        ),
        boxShadow: [
          if (_isHolding)
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Countdown number with breathing animation
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                CurvedAnimation(
                    parent: _breathingController, curve: Curves.easeInOut),
              ),
              child: Text(
                '$_count',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  color: textColor,
                  fontFamily: 'Georgia',
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isHolding ? 'Hold' : 'Breathe in',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: textColor.withOpacity(0.8),
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressDot(bool active, Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accentColor : Colors.transparent,
        border: Border.all(
          color: accentColor.withOpacity(active ? 1.0 : 0.4),
          width: active ? 0 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}
