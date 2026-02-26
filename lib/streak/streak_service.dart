// Streak: 1 day added when user uses AI Chat or Prayer Guidance that day.
// Consecutive days = streak. Missing a day resets to 1.

import 'package:biblebookapp/view/constants/share_preferences.dart';

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

    if (lastStr == today) return; // already counted today

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
}
