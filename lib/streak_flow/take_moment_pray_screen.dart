import 'package:biblebookapp/streak_flow/take_moment_complete_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Find Peace flow — short prayer after breathing (Amen / Skip).
class TakeMomentPrayScreen extends StatefulWidget {
  const TakeMomentPrayScreen({
    super.key,
    this.worryText,
  });

  /// User thoughts from Pour Out Your Worries — used only to pick a related
  /// positive prayer theme (raw text is never shown).
  final String? worryText;

  @override
  State<TakeMomentPrayScreen> createState() => _TakeMomentPrayScreenState();
}

class _TakeMomentPrayScreenState extends State<TakeMomentPrayScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);

  bool _navigating = false;

  static const String _defaultPrayer = 'God,\n'
      'I give You what I cannot carry.\n'
      'Quiet my heart, guide my thoughts,\n'
      'and help me rest in\n'
      'Your presence.\n'
      'Amen.';

  static const String _peacePrayer = 'God,\n'
      'Quiet my racing thoughts.\n'
      'Fill me with Your calm\n'
      'and peace.\n'
      'I rest in You.\n'
      'Amen.';

  static const String _workPrayer = 'Lord,\n'
      'Guide my work and open\n'
      'the right doors.\n'
      'Give me wisdom and courage\n'
      'for today.\n'
      'I trust Your plan.\n'
      'Amen.';

  static const String _familyPrayer = 'Father,\n'
      'Heal what is broken\n'
      'in my relationships.\n'
      'Fill our hearts with\n'
      'patience and love.\n'
      'Amen.';

  static const String _fearPrayer = 'God,\n'
      'Replace my fear with\n'
      'Your courage.\n'
      'Hold my tomorrow\n'
      'in Your hands.\n'
      'I am not alone.\n'
      'Amen.';

  static const String _healthPrayer = 'Lord,\n'
      'Touch my body and restore\n'
      'my strength.\n'
      'Bring comfort and healing.\n'
      'Thank You for caring for me.\n'
      'Amen.';

  static const String _gratitudePrayer = 'God,\n'
      'Thank You for being near.\n'
      'Open my eyes to Your goodness\n'
      'and fill my heart\n'
      'with gratitude.\n'
      'Amen.';

  /// Display-only: pick a related positive prayer from [worryText] themes.
  /// Raw user words are never shown; layout stays center-aligned.
  String get _prayerText {
    final raw = (widget.worryText ?? '').trim().toLowerCase();
    if (raw.isEmpty) return _defaultPrayer;

    bool has(List<String> keys) => keys.any(raw.contains);

    if (has([
      'peace',
      'calm',
      'rest',
      'quiet',
      'mind',
      'stress',
      'overwhelm',
      'anxious',
      'anxiety',
    ])) {
      return _peacePrayer;
    }
    if (has([
      'job',
      'work',
      'career',
      'interview',
      'money',
      'finance',
      'financial',
      'bill',
      'office',
    ])) {
      return _workPrayer;
    }
    if (has([
      'family',
      'parent',
      'spouse',
      'husband',
      'wife',
      'child',
      'kids',
      'marriage',
      'friend',
      'relationship',
    ])) {
      return _familyPrayer;
    }
    if (has([
      'afraid',
      'fear',
      'scared',
      'worry',
      'worried',
      'future',
      'uncertain',
    ])) {
      return _fearPrayer;
    }
    if (has([
      'sick',
      'ill',
      'health',
      'pain',
      'heal',
      'healing',
      'hospital',
      'doctor',
    ])) {
      return _healthPrayer;
    }
    if (has([
      'thank',
      'grateful',
      'gratitude',
      'bless',
      'joyful',
      'joy',
    ])) {
      return _gratitudePrayer;
    }
    return _defaultPrayer;
  }

  void _continue() {
    if (_navigating) return;
    _navigating = true;
    // Single merged "Well done!" screen (former placed + scripture steps).
    Get.off(() => const TakeMomentCompleteScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    const isDark = false;
    final Color textColor = isDark ? Colors.white : _brown;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: textColor.withOpacity(0.85),
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(active: false, textColor: textColor),
                          const SizedBox(width: 12),
                          _dot(active: false, textColor: textColor),
                          const SizedBox(width: 12),
                          _dot(active: true, textColor: textColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                  child: Column(
                    children: [
                      // Praying hands in a soft golden halo (mockup).
                      Container(
                        width: isTablet ? 250 : 210,
                        height: isTablet ? 250 : 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFF3C9).withOpacity(0.95),
                              const Color(0xFFF6DFA0).withOpacity(0.45),
                              const Color(0xFFF6DFA0).withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                        padding: EdgeInsets.all(isTablet ? 30 : 24),
                        child: Image.asset(
                          takeMomentPrayingHands,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Let’s Pray",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 46 : 40,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const TakeMomentOrnamentDivider(),
                      const SizedBox(height: 18),
                      Text(
                        _prayerText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          height: 1.6,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _primaryButton(
                context,
                label: 'Amen',
                onPressed: _continue,
              ),
              SizedBox(height: isTablet ? 56 : 48),
            ],
          ),
        ),
      ),
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

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    const isDark = false;
    final lightBtnColor =
        CommanColor.lightDarkPrimary(context).withOpacity(0.92);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.45) : lightBtnColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _gold.withOpacity(isDark ? 0.85 : 1),
                width: 2,
              ),
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
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _cream,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
