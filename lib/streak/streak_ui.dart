// Streak icon for app bar and beautiful popup dialog.
// UI matches app theme (CommanColor, ThemeProvider).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/streak/streak_service.dart';

/// Streak icon button for Home app bar. Tapping shows streak popup.
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
    return FutureBuilder<int>(
      future: StreakService.getCurrentStreak(),
      builder: (context, snapshot) {
        final streak = snapshot.data ?? 0;
        return InkWell(
          onTap: () => StreakUI.showStreakPopup(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: iconSize,
                  color: streak > 0 ? const Color(0xFFE65100) : color,
                ),
                if (streak > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: TextStyle(
                      fontSize: iconSize * 0.75,
                      fontWeight: FontWeight.w700,
                      color: streak > 0 ? const Color(0xFFE65100) : color,
                    ),
                  ),
                ],
              ],
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE65100).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: isTablet ? 48 : 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                streak > 0 ? '$streak Day Streak!' : 'Start Your Streak',
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
                    ? 'You’ve used AI Chat or Prayer Guidance for $streak day${streak == 1 ? '' : 's'} in a row. Keep it up!'
                    : 'Use AI Chat or Prayer Guidance once today to start your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Text(
                'Use at least one every day to build your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white60 : Colors.black54,
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
