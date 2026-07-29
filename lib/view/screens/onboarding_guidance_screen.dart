import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';

class OnboardingGuidanceScreen extends StatelessWidget {
  const OnboardingGuidanceScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? size.width * 0.18 : 20,
              vertical: 16,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isTablet ? 0 : 24),
                          _BiblicalGuidanceChatAnimation(isTablet: isTablet),
                          const SizedBox(height: 28),
                          Text(
                            'Get Biblical Guidance',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Whenever questions arise, find calm,\nScripture-based guidance to help you\nreflect and move forward',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 17 : 15,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _Bullet(text: 'Ask without hesitation'),
                              SizedBox(height: 12),
                              _Bullet(text: 'Understand scripture deeply'),
                              SizedBox(height: 12),
                              _Bullet(text: 'Find peace in your decisions'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 65),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
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
                            'Continue',
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
                SizedBox(height: isTablet ? 20 : 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Display-only animated chat preview for onboarding (loops smoothly).
class _BiblicalGuidanceChatAnimation extends StatefulWidget {
  const _BiblicalGuidanceChatAnimation({required this.isTablet});

  final bool isTablet;

  @override
  State<_BiblicalGuidanceChatAnimation> createState() =>
      _BiblicalGuidanceChatAnimationState();
}

class _BiblicalGuidanceChatAnimationState
    extends State<_BiblicalGuidanceChatAnimation>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF3D2914);
  static const Color _brown = Color(0xFF7A5435);
  static const Color _aiBubble = Color(0xFFFFF6E8);
  static const Color _gold = Color(0xFFE8B84A);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _interval(double start, double end) {
    final t = _controller.value;
    if (t < start) return 0;
    if (t > end) return 1;
    return (t - start) / (end - start);
  }

  double _fade(double start, double end) =>
      Curves.easeOut.transform(_interval(start, end).clamp(0.0, 1.0));

  double _fadeOut(double start, double end) =>
      1 - Curves.easeIn.transform(_interval(start, end).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final userOpacity = _fade(0.02, 0.12) * _fadeOut(0.88, 0.98);
        final aiShellOpacity = _fade(0.14, 0.22) * _fadeOut(0.88, 0.98);
        final typingOpacity = _interval(0.24, 0.52).clamp(0.0, 1.0) *
            (1 - _interval(0.48, 0.56).clamp(0.0, 1.0));
        final responseOpacity = _fade(0.52, 0.66) * _fadeOut(0.88, 0.98);
        final glowStrength = (0.35 +
                0.65 *
                    Curves.easeInOut
                        .transform(_interval(0.58, 0.78).clamp(0.0, 1.0))) *
            responseOpacity;

        final dotPhase = _controller.value * 6;

        return SizedBox(
          width: widget.isTablet ? 340 : 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeroIcon(glowStrength),
              const SizedBox(height: 18),
              Opacity(
                opacity: userOpacity,
                child: _buildUserBubble(),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: aiShellOpacity,
                child: _buildAiResponse(
                  typingOpacity: typingOpacity,
                  responseOpacity: responseOpacity,
                  glowStrength: glowStrength,
                  dotPhase: dotPhase,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroIcon(double glowStrength) {
    final size = widget.isTablet ? 88.0 : 76.0;
    return SizedBox(
      height: size + 16,
      width: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 12,
            height: size + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.25 + glowStrength * 0.25),
                  blurRadius: 18 + glowStrength * 10,
                  spreadRadius: 2 + glowStrength * 2,
                ),
              ],
              gradient: RadialGradient(
                colors: [
                  _gold.withOpacity(0.45),
                  _gold.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              Images.appIcon1024,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/splash_welcome_icons/bible_assitant.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 8,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: _gold.withOpacity(0.85),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Icon(
              Icons.auto_awesome,
              size: 11,
              color: _gold.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: widget.isTablet ? 18 : 16,
          backgroundColor: _brown.withOpacity(0.18),
          child: Icon(
            Icons.person_rounded,
            size: widget.isTablet ? 20 : 18,
            color: _brown,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9A6B45),
                  Color(0xFF7A5435),
                  Color(0xFF6B4A30),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can I find peace in difficult times?',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 13.5 : 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.96),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '10:13 AM',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiResponse({
    required double typingOpacity,
    required double responseOpacity,
    required double glowStrength,
    required double dotPhase,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: widget.isTablet ? 18 : 16,
          backgroundColor: _brown.withOpacity(0.12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              Images.appIcon1024,
              width: widget.isTablet ? 24 : 22,
              height: widget.isTablet ? 24 : 22,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.menu_book_rounded,
                size: widget.isTablet ? 18 : 16,
                color: _brown,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: _aiBubble,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _brown.withOpacity(0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.12 + glowStrength * 0.28),
                  blurRadius: 10 + glowStrength * 8,
                  spreadRadius: glowStrength * 1.5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (typingOpacity > 0.05)
                  Opacity(
                    opacity: typingOpacity,
                    child: _TypingDots(
                      dotPhase: dotPhase,
                      color: _brown,
                    ),
                  ),
                if (responseOpacity > 0.05)
                  Opacity(
                    opacity: responseOpacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peace I leave with you; my peace I give you. — John 14:27',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 13.5 : 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '10:13 AM',
                              style: TextStyle(
                                fontSize: 10,
                                color: _ink.withOpacity(0.55),
                              ),
                            ),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: _brown.withOpacity(0.75),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({
    required this.dotPhase,
    required this.color,
  });

  final double dotPhase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final wave = ((dotPhase + index * 0.33) % 1.0);
          final scale = 0.65 + 0.35 * Curves.easeInOut.transform(wave);
          return Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.55 + scale * 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF8D684A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
