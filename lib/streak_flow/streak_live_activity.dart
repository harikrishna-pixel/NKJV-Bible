import 'dart:io';

import 'package:biblebookapp/streak/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin iOS Live Activity bridge for Daily Streak.
/// Safe no-op on Android / unsupported devices. Does not alter streak logic.
class StreakLiveActivity {
  StreakLiveActivity._();

  static const MethodChannel _channel =
      MethodChannel('com.biblebookapp/live_activity');

  /// Start or update the streak Live Activity. Fire-and-forget safe.
  static Future<void> syncProgress({required int stepsCompleted}) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final streakDays = await StreakService.getCurrentStreak();
      await _channel.invokeMethod<void>('startOrUpdate', {
        'streakDays': streakDays,
        'stepsCompleted': stepsCompleted.clamp(0, 4),
      });
    } catch (e) {
      debugPrint('StreakLiveActivity.syncProgress: $e');
    }
  }

  /// End / dismiss the Live Activity. Fire-and-forget safe.
  static Future<void> end() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('end');
    } catch (e) {
      debugPrint('StreakLiveActivity.end: $e');
    }
  }
}
