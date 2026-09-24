import 'dart:async';
import 'package:biblebookapp/streak_flow/take_moment_pray_screen.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "Rest in His presence" - Breathing meditation exercise
class TakeMomentRestScreen extends StatefulWidget {
  const TakeMomentRestScreen({
    super.key,
    this.worryText,
  });

  /// User thoughts from Pour Out Your Worries (display on Let's Pray).
  final String? worryText;

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

enum _BreathPhase { inhale, hold, exhale }

class _TakeMomentRestScreenState extends State<TakeMomentRestScreen>
    with TickerProviderStateMixin {
  static const int _maxBreaths = 5;
  static const Duration _inhaleDuration = Duration(seconds: 4);
  static const Duration _holdDuration = Duration(seconds: 2);
  static const Duration _exhaleDuration = Duration(seconds: 6);

  int _breathNumber = 1;
  _BreathPhase _phase = _BreathPhase.inhale;
  Timer? _timer;
  bool _isHolding = false;
  /// UI only: after 5 cycles, show bottom slide bar (nav still goes to Pray).
  bool _allCyclesDone = false;
  double _slideProgress = 0;
  late AnimationController _glowController;
  late AnimationController _orbController;
  late Animation<double> _glowAnimation;
  late Animation<double> _orbSizeAnimation;
  late Animation<double> _pauseOpacityAnimation;

  static const Color _softGold = Color(0xFFD4A574);
  static const Color _warmTan = Color(0xFF8B7355);

  Duration _durationForPhase(_BreathPhase phase) {
    switch (phase) {
      case _BreathPhase.inhale:
        return _inhaleDuration;
      case _BreathPhase.hold:
        return _holdDuration;
      case _BreathPhase.exhale:
        return _exhaleDuration;
    }
  }

  int _secondsForPhase(_BreathPhase phase) {
    return _durationForPhase(phase).inSeconds;
  }

  void _vibrateForPhase(_BreathPhase phase) {
    switch (phase) {
      case _BreathPhase.inhale:
        HapticFeedback.mediumImpact();
        break;
      case _BreathPhase.hold:
        HapticFeedback.heavyImpact();
        break;
      case _BreathPhase.exhale:
        HapticFeedback.lightImpact();
        break;
    }
  }

  void _runOrbForPhase(_BreathPhase phase) {
    // One continuous orb — GIF-like grow / hold / shrink (circle only).
    switch (phase) {
      case _BreathPhase.inhale:
        _orbController.duration = _inhaleDuration;
        _orbController.forward(from: 0);
        break;
      case _BreathPhase.hold:
        _orbController.value = 1.0;
        break;
      case _BreathPhase.exhale:
        _orbController.duration = _exhaleDuration;
        _orbController.reverse(from: 1);
        break;
    }
  }

  void _scheduleNextPhase() {
    _timer?.cancel();
    _timer = Timer(_durationForPhase(_phase), () {
      if (!mounted || !_isHolding) return;
      setState(() {
        if (_phase == _BreathPhase.inhale) {
          _phase = _BreathPhase.hold;
        } else if (_phase == _BreathPhase.hold) {
          _phase = _BreathPhase.exhale;
        } else {
          // Completed one full breath cycle.
          if (_breathNumber >= _maxBreaths) {
            _timer?.cancel();
            _isHolding = false;
            _orbController.value = 0;
            // UI: show slide bar; existing Pray destination unchanged.
            _allCyclesDone = true;
            _slideProgress = 0;
            return;
          }
          _breathNumber++;
          _phase = _BreathPhase.inhale;
        }
        _vibrateForPhase(_phase);
        _runOrbForPhase(_phase);
      });
      if (mounted && _isHolding) {
        _scheduleNextPhase();
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _vibrateForPhase(_BreathPhase.inhale);
    _runOrbForPhase(_BreathPhase.inhale);
    _scheduleNextPhase();
  }

  void _stopCountdown() {
    if (_allCyclesDone) return;
    _timer?.cancel();
    _timer = null;
    _orbController.stop();
    _orbController.value = 0;
    if (mounted) {
      setState(() {
        _isHolding = false;
        _breathNumber = 1;
        _phase = _BreathPhase.inhale;
      });
    }
  }

  void _goToPray() {
    Get.off(
      () => TakeMomentPrayScreen(worryText: widget.worryText),
    );
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _glowAnimation = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    _orbController = AnimationController(
      vsync: this,
      duration: _inhaleDuration,
      value: 0,
    );
    // 0 = small (exhale), 1 = large (inhale/hold)
    _orbSizeAnimation = CurvedAnimation(
      parent: _orbController,
      curve: Curves.easeInOut,
    );
    // Pause icon only near full size (hold).
    _pauseOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _orbController,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  String get _phaseSecondsLabel {
    final secs = _secondsForPhase(_phase);
    switch (_phase) {
      case _BreathPhase.inhale:
        return 'Breathe in for $secs seconds';
      case _BreathPhase.hold:
        return 'Hold for $secs seconds';
      case _BreathPhase.exhale:
        return 'Breathe out for $secs seconds';
    }
  }

  /// 0..1 fill for the current cycle's top dot (UI only).
  double get _currentCycleFill {
    if (!_isHolding || _allCyclesDone) return _allCyclesDone ? 1.0 : 0.0;
    switch (_phase) {
      case _BreathPhase.inhale:
        return (0.15 + 0.35 * _orbController.value).clamp(0.0, 1.0);
      case _BreathPhase.hold:
        return 0.55;
      case _BreathPhase.exhale:
        return (0.6 + 0.4 * (1.0 - _orbController.value)).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

    final Color accentColor = isDark ? const Color(0xFFC9A227) : _softGold;
    final Color textColor = isDark ? Colors.white : _warmTan;
    final Color secondaryText = isDark ? Colors.white70 : _warmTan;

    return Scaffold(
      body: TakeMomentRestScreen.peaceBackgroundStack(
        isDark: isDark,
        showBird: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 18),
                child: AnimatedBuilder(
                  animation: _orbController,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_maxBreaths, (i) {
                        final completedCount =
                            _allCyclesDone ? _maxBreaths : (_breathNumber - 1);
                        double fill = 0;
                        if (i < completedCount) {
                          fill = 1;
                        } else if (!_allCyclesDone &&
                            _isHolding &&
                            i == _breathNumber - 1) {
                          fill = _currentCycleFill;
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 10,
                          ),
                          child: _cycleDot(fill: fill, accentColor: accentColor),
                        );
                      }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _allCyclesDone
                    ? Text(
                        'Well done',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 30 : 26,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      )
                    : _isHolding
                        ? Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text(
                              _phaseSecondsLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          )
                        : Column(
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
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Listener(
                    onPointerDown: (_) {
                      if (_allCyclesDone) return;
                      if (!_isHolding && mounted) {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _isHolding = true;
                          _breathNumber = 1;
                          _phase = _BreathPhase.inhale;
                        });
                        _startCountdown();
                      }
                    },
                    onPointerUp: (_) => _stopCountdown(),
                    onPointerCancel: (_) => _stopCountdown(),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowAnimation,
                        _orbController,
                      ]),
                      builder: (context, _) {
                        return _buildBreathGraphic(
                          isTablet: isTablet,
                          isDark: isDark,
                          accentColor: accentColor,
                          textColor: textColor,
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_allCyclesDone)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: _buildSlideBar(
                    isTablet: isTablet,
                    accentColor: accentColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                )
              else if (!_isHolding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
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
                      'Hold the circle to start',
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
                )
              else
                const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideBar({
    required bool isTablet,
    required Color accentColor,
    required Color textColor,
    required bool isDark,
  }) {
    const trackH = 56.0;
    const thumb = 48.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackW = constraints.maxWidth;
        final maxDx = (trackW - thumb - 8).clamp(0.0, trackW);
        final dx = _slideProgress * maxDx;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final next = ((_slideProgress * maxDx) + details.delta.dx)
                .clamp(0.0, maxDx);
            setState(() => _slideProgress = maxDx <= 0 ? 0 : next / maxDx);
          },
          onHorizontalDragEnd: (_) {
            if (_slideProgress >= 0.92) {
              HapticFeedback.mediumImpact();
              _goToPray();
            } else {
              setState(() => _slideProgress = 0);
            }
          },
          child: Container(
            height: trackH,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: accentColor.withOpacity(0.55),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Fill trail
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: dx + thumb / 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Slide to continue',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: textColor.withOpacity(0.85),
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  left: 4 + dx,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreathGraphic({
    required bool isTablet,
    required bool isDark,
    required Color accentColor,
    required Color textColor,
  }) {
    if (_allCyclesDone) {
      return _outlinedCountCircle(
        isTablet: isTablet,
        accentColor: accentColor,
        textColor: textColor,
        countLabel: '$_maxBreaths',
        phaseLabel: 'Complete',
      );
    }
    // Idle: outlined circle with remaining count (matches start UI).
    if (!_isHolding) {
      return _outlinedCountCircle(
        isTablet: isTablet,
        accentColor: accentColor,
        textColor: textColor,
        countLabel: '$_maxBreaths',
        phaseLabel: 'Breathe in',
      );
    }

    // Active: one continuous GIF-like orb (same widget, size morphs).
    return _breathingOrbGif(
      isTablet: isTablet,
      accentColor: accentColor,
      textColor: textColor,
    );
  }

  Widget _outlinedCountCircle({
    required bool isTablet,
    required Color accentColor,
    required Color textColor,
    required String countLabel,
    required String phaseLabel,
  }) {
    final size = isTablet ? 260.0 : 220.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withOpacity(0.65),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              countLabel,
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
              phaseLabel,
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

  /// Single-screen realistic circle: grows on inhale, holds, shrinks on exhale.
  Widget _breathingOrbGif({
    required bool isTablet,
    required Color accentColor,
    required Color textColor,
  }) {
    final t = _orbSizeAnimation.value; // 0 small → 1 large
    final minSize = isTablet ? 150.0 : 128.0;
    final maxSize = isTablet ? 292.0 : 252.0;
    final glow = _glowAnimation.value;
    final showPause = _phase == _BreathPhase.hold;
    // Same orb colors for all phases; hold keeps full size + pause logo only.
    final size = minSize + (maxSize - minSize) * t;
    final pauseOpacity = showPause
        ? 1.0
        : (_phase == _BreathPhase.inhale
            ? _pauseOpacityAnimation.value * 0.10
            : 0.0);

    return SizedBox(
      width: maxSize + 90,
      height: maxSize + 90,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft outer bloom (same look for inhale / hold / exhale)
          Container(
            width: size + 48 + glow * 12,
            height: size + 48 + glow * 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8C9A0).withOpacity(
                    0.28 + glow * 0.25 * t,
                  ),
                  blurRadius: 58.0,
                  spreadRadius: 18.0,
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.18 + 0.15 * t),
                  blurRadius: 34,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          // Core orb — same colors; size only changes (bigger → hold → smaller)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.98),
                  const Color(0xFFF3E0C4).withOpacity(0.95),
                  Color.lerp(
                    accentColor.withOpacity(0.40),
                    const Color(0xFFE0B57A).withOpacity(0.75),
                    t,
                  )!,
                  accentColor.withOpacity(0.05 + 0.12 * t),
                ],
                stops: const [0.08, 0.28, 0.62, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.35 + 0.2 * t),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.20 + 0.18 * t),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Hold: pause logo only (orb stays same size & colors)
          Opacity(
            opacity: pauseOpacity,
            child: _attractivePauseMark(
              isTablet: isTablet,
              accentColor: accentColor,
              textColor: textColor,
              active: showPause,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attractivePauseMark({
    required bool isTablet,
    required Color accentColor,
    required Color textColor,
    required bool active,
  }) {
    // Match reference: thick solid tan pause bars, no inner badge.
    final barW = isTablet ? 16.0 : 13.0;
    final barH = isTablet ? 48.0 : 40.0;
    final gap = isTablet ? 16.0 : 13.0;
    final color = active ? const Color(0xFF8B7355) : Colors.transparent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pauseBar(width: barW, height: barH, color: color),
        SizedBox(width: gap),
        _pauseBar(width: barW, height: barH, color: color),
      ],
    );
  }

  Widget _pauseBar({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width * 0.35),
      ),
    );
  }

  Widget _cycleDot({required double fill, required Color accentColor}) {
    const size = 12.0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withOpacity(fill >= 1 ? 1.0 : 0.45),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fill.clamp(0.0, 1.0),
              widthFactor: 1,
              child: ColoredBox(color: accentColor),
            ),
          ),
        ),
      ),
    );
  }
}
