import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:flutter/material.dart';

/// Parchment popup when a milestone is newly unlocked (Screen 14 style).
class MilestoneUnlockedDialog extends StatelessWidget {
  const MilestoneUnlockedDialog({super.key, required this.progress});

  final MilestoneProgress progress;

  static const _ink = Color(0xFF2C1E1A);
  static const _brown = Color(0xFF4A3728);
  static const _muted = Color(0xFF7A6A5A);
  static const _cream = Color(0xFFF8F4EB);
  static const _gold = Color(0xFFC9A227);
  static const _card = Color(0xFFFFFBF5);

  static Future<void> show(
    BuildContext context, {
    required MilestoneProgress progress,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MilestoneUnlockedDialog(progress: progress),
    );
  }

  IconData _iconFor(IconKind kind) {
    switch (kind) {
      case IconKind.lantern:
        return Icons.nightlife_outlined;
      case IconKind.sprout:
        return Icons.eco_outlined;
      case IconKind.prayer:
        return Icons.volunteer_activism_outlined;
      case IconKind.community:
        return Icons.groups_outlined;
      case IconKind.wreath:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = progress.def;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _brown.withOpacity(0.22), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _card,
                border: Border.all(color: _gold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _brown.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 78,
                    color: _gold.withOpacity(0.35),
                  ),
                  Text(
                    '${def.target}',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Milestone Unlocked!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              def.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              def.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                height: 1.4,
                color: _muted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _brown.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(def.icon), color: _brown, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reward',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          def.reward,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
