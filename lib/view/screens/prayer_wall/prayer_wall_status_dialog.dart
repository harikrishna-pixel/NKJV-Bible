import 'package:flutter/material.dart';

/// Shown after a user's prayer duration has fully expired (exact timestamp).
/// UI-only — does not call Prayer Wall APIs.
class PrayerWallStatusDialog {
  PrayerWallStatusDialog._();

  static const Color _cream = Color(0xFFFFF9F3);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _peach = Color(0xFFF3E4D8);

  /// Returns `'answered'`, `'in_progress'`, or `null` if dismissed.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _PrayerWallStatusDialogBody(),
    );
  }
}

class _PrayerWallStatusDialogBody extends StatefulWidget {
  const _PrayerWallStatusDialogBody();

  @override
  State<_PrayerWallStatusDialogBody> createState() =>
      _PrayerWallStatusDialogBodyState();
}

class _PrayerWallStatusDialogBodyState
    extends State<_PrayerWallStatusDialogBody> {
  /// `answered` | `in_progress`
  String _selected = 'answered';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Material(
        color: PrayerWallStatusDialog._cream,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PrayerHero(),
                  const SizedBox(height: 16),
                  const Text(
                    'How did this prayer go?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: PrayerWallStatusDialog._ink,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The time you selected for this prayer request has ended. Please update the prayer status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: PrayerWallStatusDialog._muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StatusOptionCard(
                    selected: _selected == 'answered',
                    title: 'Answered',
                    subtitle: 'My prayer was answered.',
                    icon: Icons.check,
                    iconBg: const Color(0xFF2E7D4F),
                    onTap: () => setState(() => _selected = 'answered'),
                  ),
                  const SizedBox(height: 10),
                  _StatusOptionCard(
                    selected: _selected == 'in_progress',
                    title: 'In Progress',
                    subtitle: 'I’m still waiting and believing.',
                    icon: Icons.schedule,
                    iconBg: const Color(0xFFE0A84E),
                    onTap: () => setState(() => _selected = 'in_progress'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your update encourages others and strengthens our faith.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: PrayerWallStatusDialog._muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PrayerWallStatusDialog._brown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: PrayerWallStatusDialog._muted.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerHero extends StatelessWidget {
  const _PrayerHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: PrayerWallStatusDialog._peach,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.handshake_outlined,
            size: 34,
            color: PrayerWallStatusDialog._brown,
          ),
          const Positioned(
            top: 6,
            left: 10,
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            top: 10,
            right: 8,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 10,
            left: 8,
            child: Icon(Icons.auto_awesome, size: 9, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 14,
            right: 6,
            child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFFE0A84E)),
          ),
        ],
      ),
    );
  }
}

class _StatusOptionCard extends StatelessWidget {
  const _StatusOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? PrayerWallStatusDialog._brown
        : PrayerWallStatusDialog._brown.withValues(alpha: 0.22);
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PrayerWallStatusDialog._ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: PrayerWallStatusDialog._muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? PrayerWallStatusDialog._brown
                    : PrayerWallStatusDialog._brown.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
