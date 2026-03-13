import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Celebration dialog when user completes the full 4-step streak (Day X Complete).
/// Shows app logo, "Day X Complete", streak started strip, Continue Tomorrow, Enable Daily Reminder.
class StreakCompleteCelebrationDialog extends StatelessWidget {
  const StreakCompleteCelebrationDialog({
    super.key,
    required this.streakCount,
    required this.onContinueTomorrow,
  });

  final int streakCount;
  final void Function(BuildContext dialogContext) onContinueTomorrow;

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF8F4EB);
  static const Color _stripBg = Color(0xFFF0E6D0);

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildTopDecorationRow(),
              const SizedBox(height: 12),
              Image.asset(
                'assets/Icon-1024.png',
                height: 72,
                width: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                BibleInfo.bible_shortName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _brown.withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Day $streakCount Complete',
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
                  "You spent time in God's Word today. Come back tomorrow to continue your journey.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _brown.withOpacity(0.9),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _stripBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Day $streakCount Streak Started',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _brown,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xFF5C4A3A),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onContinueTomorrow(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _brown.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Continue Tomorrow',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => SettingScreen(notificationValue: false));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 20, color: _gold),
                        const SizedBox(width: 8),
                        Text(
                          'Enable Daily Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _gold,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Top decoration: row of golden stars with subtle size/opacity variation.
  Widget _buildTopDecorationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (i) {
        final size = 12.0 + (i % 3) * 2.0; // 12, 14, 16 for variety
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
