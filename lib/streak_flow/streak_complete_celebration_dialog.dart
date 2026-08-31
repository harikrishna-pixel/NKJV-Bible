import 'package:flutter/material.dart';

/// Celebration dialog when user completes the full 4-step streak (Day X Complete).
/// Shows "Day X Complete", streak summary strip, and Enable Daily Reminder.
class StreakCompleteCelebrationDialog extends StatefulWidget {
  const StreakCompleteCelebrationDialog({
    super.key,
    required this.streakCount,
  });

  final int streakCount;

  @override
  State<StreakCompleteCelebrationDialog> createState() =>
      _StreakCompleteCelebrationDialogState();
}

class _StreakCompleteCelebrationDialogState
    extends State<StreakCompleteCelebrationDialog> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF8F4EB);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _brown.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildTopDecorationRow(),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 72,
                    color: _gold,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day ${widget.streakCount} Complete',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _brown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.celebration, size: 24, color: _gold),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You spent time in God's Word today.\nCome back tomorrow to continue your journey.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _brown.withOpacity(0.9),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: _brown.withOpacity(0.6),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top decoration: row of golden stars with subtle size/opacity variation.
  Widget _buildTopDecorationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (i) {
        final size = 12.0 + (i % 3) * 2.0;
        final opacity = 0.7 + (i % 4) * 0.08;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: _gold.withOpacity(opacity.clamp(0.0, 1.0)),
          ),
        );
      }),
    );
  }
}
