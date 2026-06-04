// Streak icon for app bar and beautiful popup dialog.
// UI matches app theme (CommanColor, ThemeProvider).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/streak_flow/daily_journey_screen.dart';

/// Streak icon button for Home app bar. Tapping opens Daily Journey screen.
class StreakIconButton extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;

  const StreakIconButton({
    super.key,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? CommanColor.whiteBlack(context);
    // Use a lightweight periodic refresh so streak stays consistent across screens
    // even when preferences change without triggering a rebuild (e.g. after restore flow).
    return StreamBuilder<int>(
      // Fetch once immediately (avoid initial "blank"), then refresh periodically.
      // Provide a computation so this never emits null (required for non-nullable int).
      stream: (() async* {
        yield await StreakService.getTotalCompletedDays();
        yield* Stream<int>.periodic(const Duration(seconds: 2), (_) => 0)
            .asyncMap((_) => StreakService.getTotalCompletedDays());
      })(),
      initialData: 0,
      builder: (context, snapshot) {
        final streak = snapshot.data ?? 0;
        final hasStreak = streak > 0;
        return InkWell(
          onTap: () => Get.to(() => const DailyJourneyScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: hasStreak
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: iconSize * 0.45,
                      vertical: iconSize * 0.12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withOpacity(0.35),
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
                          color: Colors.white,
                        ),
                        SizedBox(width: iconSize * 0.15),
                        Text(
                          '$streak',
                          style: TextStyle(
                            fontSize: iconSize * 0.7,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                : Icon(
                    Icons.local_fire_department_rounded,
                    size: iconSize,
                    color: color,
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
              // Flame icon with gradient
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
              // SizedBox(height: isTablet ? 24 : 20),
              // Text(
              //   'Use at least one every day to build your streak.',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: isTablet ? 14 : 13,
              //     fontStyle: FontStyle.italic,
              //     color: isDark ? Colors.white60 : Colors.black54,
              //   ),
              // ),
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
