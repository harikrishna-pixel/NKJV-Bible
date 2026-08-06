import 'dart:async';

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
              horizontal: isTablet ? size.width * 0.18 : 0,
              vertical: 16,
            ),
            child: Column(
              children: [
                Expanded(
                  child: _ValueChatBody(isTablet: isTablet),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 0 : 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: isTablet ? 56 : 52,
                    child: DecoratedBox(
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
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: Colors.white.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: isTablet ? 22 : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatContent {
  const _ChatContent({
    required this.question,
    required this.lead,
    required this.verse,
    required this.reference,
  });

  final String question;
  final String lead;
  final String verse;
  final String reference;
}

class _AskChip {
  const _AskChip({
    required this.key,
    required this.icon,
    required this.label,
    required this.content,
  });

  final String key;
  final IconData icon;
  final String label;
  final _ChatContent content;
}

const _defaultChat = _ChatContent(
  question: 'How can I find peace in difficult times?',
  lead:
      "When life feels heavy, you don't have to carry it alone. Bring it to God honestly, and let His promise steady your heart:",
  verse:
      '"Peace I leave with you; my peace I give you. Do not let your hearts be troubled."',
  reference: '— John 14:27',
);

const _askChips = <_AskChip>[
  _AskChip(
    key: 'forgive',
    icon: Icons.chat_bubble_outline_rounded,
    label: 'How do I forgive someone who hurt me?',
    content: _ChatContent(
      question: 'How do I forgive someone who hurt me?',
      lead:
          "Forgiveness is a choice you make before it becomes a feeling — and you don't have to do it in your own strength. Ask God to soften your heart first, then release the hurt to Him a little at a time.",
      verse:
          '"Be kind and compassionate to one another, forgiving each other, just as in Christ God forgave you."',
      reference: '— Ephesians 4:32',
    ),
  ),
  _AskChip(
    key: 'night',
    icon: Icons.nightlight_round,
    label: 'A verse for anxious nights',
    content: _ChatContent(
      question: 'A verse for anxious nights',
      lead:
          'When your thoughts start racing at night, breathe slowly and hand the day back to God. You are safe in His care — let these words be the last thing on your mind:',
      verse:
          '"In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety."',
      reference: '— Psalm 4:8',
    ),
  ),
  _AskChip(
    key: 'family',
    icon: Icons.volunteer_activism_rounded,
    label: 'Help me pray for my family',
    content: _ChatContent(
      question: 'Help me pray for my family',
      lead:
          'A short, honest prayer is more than enough. Try praying this over your loved ones tonight: "Lord, watch over each person in my home, protect them, and draw them close to You."',
      verse: '"As for me and my household, we will serve the Lord."',
      reference: '— Joshua 24:15',
    ),
  ),
];

class _ValueChatBody extends StatefulWidget {
  const _ValueChatBody({required this.isTablet});

  final bool isTablet;

  @override
  State<_ValueChatBody> createState() => _ValueChatBodyState();
}

class _ValueChatBodyState extends State<_ValueChatBody> {
  static const Color _gold = Color(0xFFB08B3F);
  static const Color _gold2 = Color(0xFFC9A35A);
  static const Color _goldDeep = Color(0xFF96712E);
  static const Color _line = Color(0xFFE6D8BE);
  static const Color _paper = Color(0xFFFFFDF8);
  static const Color _inkSoft = Color(0xFF6B5A44);

  _ChatContent _content = _defaultChat;
  String? _selectedChipKey;
  bool _showAnswer = false;
  bool _showTyping = true;
  Timer? _chatTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAnswer(delay: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
  }

  void _scheduleAnswer({required Duration delay}) {
    _chatTimer?.cancel();
    setState(() {
      _showAnswer = false;
      _showTyping = true;
    });
    _chatTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _showTyping = false;
        _showAnswer = true;
      });
    });
  }

  void _onChipTap(_AskChip chip) {
    setState(() {
      _selectedChipKey = chip.key;
      _content = chip.content;
    });
    _scheduleAnswer(delay: const Duration(milliseconds: 1100));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: widget.isTablet ? 0 : 0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildOrb(),
          const SizedBox(height: 7),
          Text(
            'Answers from Scripture',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: widget.isTablet ? 22 : 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241A0F),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isTablet ? 48 : 34,
              5,
              widget.isTablet ? 48 : 34,
              0,
            ),
            child: Text(
              'Ask anything — get calm, Bible-based guidance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.isTablet ? 14 : 12.5,
                height: 1.4,
                color: _inkSoft,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final fade = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    );
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(fade);
                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${_selectedChipKey ?? 'default'}_${_content.question}',
                    ),
                    child: _buildUserRow(),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final fade = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    );
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(fade);
                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                  child: _showTyping
                      ? KeyedSubtree(
                          key: const ValueKey('typing'),
                          child: _buildTypingRow(),
                        )
                      : _showAnswer
                          ? KeyedSubtree(
                              key: ValueKey(
                                'answer_${_selectedChipKey ?? 'default'}',
                              ),
                              child: _buildAnswerRow(),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'TRY ASKING · TAP TO SEND',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: _goldDeep,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 11, 22, 6),
            child: Column(
              children: _askChips
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildAskChip(chip),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89646).withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: _appIconImage(size: 52),
      ),
    );
  }

  Widget _appIconImage({required double size}) {
    return Image.asset(
      'assets/guidance_brand_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        Images.appIcon1024,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildUserRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isTablet ? 320 : MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBDD),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: const Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _content.question,
                  style: TextStyle(
                    fontSize: widget.isTablet ? 15 : 14,
                    height: 1.35,
                    color: const Color(0xFF3A2E1C),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _userAvatar(),
      ],
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFEFE3CD),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 18,
        color: Color(0xFF7A6544),
      ),
    );
  }

  Widget _aiAvatar() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 0.9,
          colors: [Color(0xFF8A4A22), Color(0xFF5A2C11)],
        ),
      ),
      child: const Text(
        '📖',
        style: TextStyle(fontSize: 15, height: 1.1),
      ),
    );
  }

  Widget _buildTypingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _aiAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBECCB), Color(0xFFF7E2B8)],
            ),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(5),
            ),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }

  Widget _buildAnswerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _aiAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.isTablet ? 360 : MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBECCB), Color(0xFFF7E2B8)],
              ),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _content.lead,
                  style: TextStyle(
                    fontSize: widget.isTablet ? 14 : 13,
                    height: 1.5,
                    color: const Color(0xFF4A3A26),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _gold, width: 2.5),
                    ),
                  ),
                  child: Text(
                    _content.verse,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 14.5 : 13.5,
                      height: 1.42,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF3A2E1C),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _content.reference,
                  style: TextStyle(
                    fontSize: widget.isTablet ? 13.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: _goldDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAskChip(_AskChip chip) {
    final isSelected = _selectedChipKey == chip.key;
    return GestureDetector(
      onTap: () => _onChipTap(chip),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? null : _paper,
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDF7E8), Color(0xFFF7EDD5)],
                )
              : null,
          border: Border.all(
            color: isSelected ? _gold : _line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEFE0BD)
                    : const Color(0xFFF4EBD7),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                chip.icon,
                size: 15,
                color: isSelected ? _goldDeep : const Color(0xFF7A6544),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                chip.label,
                style: TextStyle(
                  fontSize: widget.isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF5C4718)
                      : _inkSoft,
                ),
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? _goldDeep : _gold2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value + delay) % 1.0;
            final opacity = t < 0.3 ? 0.25 + (t / 0.3) * 0.75 : 0.25;
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 2, right: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFB9975A).withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
