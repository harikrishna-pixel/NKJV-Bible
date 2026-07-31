// Streak icon for app bar and beautiful popup dialog.
// UI matches app theme (CommanColor, ThemeProvider).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/streak_flow/daily_journey_screen.dart';

class _StreakIconVisualState {
  const _StreakIconVisualState({
    required this.streak,
    required this.showCountBadge,
    required this.todayComplete,
    required this.showNotificationDot,
  });

  final int streak;
  final bool showCountBadge;
  /// True when today's streak journey is finished (usual badge style).
  final bool todayComplete;
  final bool showNotificationDot;

  static Future<_StreakIconVisualState> load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    final started = await SharPreferences.getString(
        SharPreferences.streakFlowStartedDate);
    final steps = await SharPreferences.getInt(
            SharPreferences.streakFlowStepsCompletedToday) ??
        0;
    final streak = await StreakService.getCurrentStreak();
    // Display only — same day-session rules as Daily Journey (no pref writes).
    int effectiveSteps = 0;
    if (lastShown == today) {
      effectiveSteps = 4;
    } else if (started == today) {
      effectiveSteps = steps;
    }
    final todayComplete =
        lastShown == today || (started == today && steps >= 4);
    // Keep streak count visible on following days (not only on completion day).
    final showCountBadge = streak > 0;
    // Day-N pending (e.g. Day 2 after Day 1 done): red dart until today completes.
    // First-time (no streak yet): keep prior cue — red only before first step.
    final showNotificationDot = showCountBadge
        ? !todayComplete
        : (!todayComplete && effectiveSteps < 1);

    return _StreakIconVisualState(
      streak: streak,
      showCountBadge: showCountBadge,
      todayComplete: todayComplete,
      showNotificationDot: showNotificationDot,
    );
  }
}

/// Streak icon button for Home app bar. Tapping opens Daily Journey screen.
class StreakIconButton extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;

  const StreakIconButton({
    super.key,
    this.iconSize = 24,
    this.iconColor,
  });

  Widget _inactiveFlame({required Color color, required bool showDot}) {
    final badgeSize = iconSize * 1.55;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            size: iconSize * 0.82,
            color: color.withOpacity(0.42),
          ),
        ),
        if (showDot)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? CommanColor.whiteBlack(context);
    return StreamBuilder<_StreakIconVisualState>(
      stream: (() async* {
        yield await _StreakIconVisualState.load();
        yield* Stream<void>.periodic(const Duration(seconds: 2))
            .asyncMap((_) => _StreakIconVisualState.load());
      })(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        final streak = state?.streak ?? 0;
        final showCountBadge = state?.showCountBadge ?? false;
        final showNotificationDot = state?.showNotificationDot ?? false;

        final todayComplete = state?.todayComplete ?? false;
        // Not completed today: outlined badge + red dart (screenshot style).
        // Completed today: full orange filled badge (old style), no dart.
        final showOutlinedPending = showCountBadge && !todayComplete;

        return InkWell(
          onTap: () => Get.to(() => const DailyJourneyScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: showCountBadge
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: iconSize * 0.45,
                          vertical: iconSize * 0.12,
                        ),
                        decoration: BoxDecoration(
                          color: showOutlinedPending
                              ? Colors.white
                              : const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(20),
                          border: showOutlinedPending
                              ? Border.all(
                                  color: const Color(0xFFE65100)
                                      .withOpacity(0.55),
                                  width: 1.4,
                                )
                              : null,
                          boxShadow: showOutlinedPending
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFE65100)
                                        .withOpacity(0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: iconSize * 0.85,
                              color: showOutlinedPending
                                  ? const Color(0xFFE65100)
                                  : Colors.white,
                            ),
                            SizedBox(width: iconSize * 0.15),
                            Text(
                              '$streak',
                              style: TextStyle(
                                fontSize: iconSize * 0.7,
                                fontWeight: FontWeight.w700,
                                color: showOutlinedPending
                                    ? const Color(0xFFE65100)
                                    : Colors.white,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showNotificationDot)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : _inactiveFlame(
                    color: color,
                    showDot: showNotificationDot,
                  ),
          ),
        );
      },
    );
  }
}

/// Streak popup and helpers.
class StreakUI {
  /// Shows a beautiful streak popup dialog.
  static Future<void> showStreakPopup(BuildContext context) async {
    final streak = await StreakService.getCurrentStreak();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth > 600;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? CommanColor.darkPrimaryColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 400 : 320,
          ),
          padding: EdgeInsets.all(isTablet ? 28 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 88 : 72,
                height: isTablet ? 88 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE65100),
                      const Color(0xFFFF9800),
                      const Color(0xFFFFB74D),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: isTablet ? 48 : 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                streak > 0 ? 'Day $streak Streak' : 'Start Your Streak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 24 : 22,
                  fontWeight: FontWeight.w800,
                  color: CommanColor.whiteBlack(ctx),
                ),
              ),
              SizedBox(height: isTablet ? 12 : 10),
              Text(
                streak > 0
                    ? 'You’ve completed your daily connection, verse, devotional and prayer for $streak day${streak == 1 ? '' : 's'} in a row. Keep it up!'
                    : 'Complete your daily connection, verse, devotional and prayer to start your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: CommanColor.lightDarkPrimary(ctx),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 14 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 16,
                      fontWeight: FontWeight.w600,
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
}
