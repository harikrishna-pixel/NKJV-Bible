// Streak: 1 day added when user uses AI Chat or Prayer Guidance that day.
// Consecutive days = streak. Missing a day resets to 1.

import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/streak/streak_live_activity.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';

/// Status for each day in the weekly calendar (Sun=0 .. Sat=6).
enum WeekDayStatus { completed, missed, ongoing, future }

class StreakService {
  static String _todayKey() =>
      DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

  /// Call when user gets a successful AI Chat or Prayer Guidance response.
  /// Updates streak for today (at most once per day).
  static Future<void> recordActivity() async {
    final today = _todayKey();
    final lastStr =
        await SharPreferences.getString(SharPreferences.streakLastActivityDate);
    final count = await SharPreferences.getInt(SharPreferences.streakCount) ?? 0;

    // Always mark today's completion for weekly calendar view.
    try {
      final existing = await SharPreferences.getStringList(
              SharPreferences.streakCompletedDates) ??
          <String>[];
      if (!existing.contains(today)) {
        await SharPreferences.setListString(
            SharPreferences.streakCompletedDates, [...existing, today]);
      }
    } catch (_) {}

    if (lastStr == today) {
      // Already counted today — still refresh Live Activity UI mirror.
      StreakLiveActivitySync.sync();
      return;
    }

    final now = DateTime.now();
    int newCount = 1;

    if (lastStr != null && lastStr.isNotEmpty) {
      try {
        final last = DateTime.parse(lastStr);
        final lastDate = DateTime(last.year, last.month, last.day);
        final todayDate = DateTime(now.year, now.month, now.day);
        final diffDays = todayDate.difference(lastDate).inDays;

        if (diffDays == 1) {
          newCount = count + 1;
        }
        // else diffDays > 1 or < 0: reset to 1
      } catch (_) {}
    }

    await SharPreferences.setString(
        SharPreferences.streakLastActivityDate, today);
    await SharPreferences.setInt(SharPreferences.streakCount, newCount);

    if (newCount == 7) {
      await WalletService.addCredits(100);
    }

    // UI mirror only — never affects streak calculation above.
    StreakLiveActivitySync.sync();
  }

  /// Total distinct days the user completed a streak (never reset by weekly UI).
  static Future<int> getTotalCompletedDays() async {
    final dates =
        await SharPreferences.getStringList(SharPreferences.streakCompletedDates) ??
            <String>[];
    return dates.length;
  }

  /// Current streak (consecutive days). 0 if never or broken.
  static Future<int> getCurrentStreak() async {
    final lastStr =
        await SharPreferences.getString(SharPreferences.streakLastActivityDate);
    if (lastStr == null || lastStr.isEmpty) return 0;

    try {
      final last = DateTime.parse(lastStr);
      final today = DateTime.now();
      final lastDate = DateTime(last.year, last.month, last.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      final diffDays = todayDate.difference(lastDate).inDays;

      if (diffDays > 1) return 0; // streak broken
      final count = await SharPreferences.getInt(SharPreferences.streakCount) ?? 0;
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Last activity date (YYYY-MM-DD) or null.
  static Future<String?> getLastActivityDate() async {
    return SharPreferences.getString(SharPreferences.streakLastActivityDate);
  }

  /// For the current week (Sun–Sat), returns status for each day.
  /// completed = day had activity and is part of current streak;
  /// missed = day in the past but not part of streak (gap or before streak);
  /// ongoing = today (current day);
  /// future = day not yet reached.
  static Future<List<WeekDayStatus>> getWeekDayStatuses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday;
    final sundayOffset = weekday == 7 ? 0 : weekday;
    final weekStart = today.subtract(Duration(days: sundayOffset));

    final completedDates =
        await SharPreferences.getStringList(SharPreferences.streakCompletedDates) ??
            <String>[];

    final List<WeekDayStatus> statuses = [];
    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      if (dayDate.isAfter(today)) {
        statuses.add(WeekDayStatus.future);
        continue;
      }
      if (dayDate == today) {
        statuses.add(WeekDayStatus.ongoing);
        continue;
      }
      final key = dayDate.toIso8601String().split('T')[0];
      if (completedDates.contains(key)) {
        statuses.add(WeekDayStatus.completed);
      } else {
        statuses.add(WeekDayStatus.missed);
      }
    }
    return statuses;
  }
}
