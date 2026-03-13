import 'dart:convert';

import 'package:biblebookapp/services/smart_notification_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/services.dart';

/// Streak state for notification content.
enum StreakNotificationState {
  streak_not_started,
  streak_pending,
  streak_completed,
}

/// Result for one notification: message body and action payload for tap.
class StreakNotificationContent {
  const StreakNotificationContent({
    required this.message,
    required this.action,
  });
  final String message;
  final String action;
}

/// Loads assets/streak.json and picks message + action by time slot and streak state.
/// Fixed schedule: morning 8 AM, afternoon 2 PM, night 8 PM.
class StreakNotificationHelper {
  static Map<String, dynamic>? _cachedJson;

  static Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) return _cachedJson!;
    final String raw =
        await rootBundle.loadString('assets/streak.json');
    _cachedJson = json.decode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  /// Current streak state for today (for notification content).
  static Future<StreakNotificationState> getStreakState() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown =
        await SharPreferences.getString(SharPreferences.streakFlowLastShownDate);
    if (lastShown == today) {
      return StreakNotificationState.streak_completed;
    }
    final started =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    if (started == today) {
      return StreakNotificationState.streak_pending;
    }
    return StreakNotificationState.streak_not_started;
  }

  /// Slot key for 8 AM = morning, 2 PM = afternoon, 8 PM = night.
  static String slotFromHourMinute(int hour, int minute) {
    if (hour == 8 && minute == 0) return 'morning';
    if (hour == 14 && minute == 0) return 'afternoon';
    if (hour == 20 && minute == 0) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'night';
  }

  static String _stateKey(StreakNotificationState state) {
    switch (state) {
      case StreakNotificationState.streak_not_started:
        return 'streak_not_started';
      case StreakNotificationState.streak_pending:
        return 'streak_pending';
      case StreakNotificationState.streak_completed:
        return 'streak_completed';
    }
  }

  /// Returns title (app name style) and content for the given slot.
  /// Uses current streak state and rotates message by day.
  static Future<StreakNotificationContent> getContentForSlot(
    String slot,
  ) async {
    final data = await _loadJson();
    final slotData = data[slot] as Map<String, dynamic>?;
    if (slotData == null) {
      return const StreakNotificationContent(
        message: 'Stay in the Word.',
        action: 'open_reading',
      );
    }
    final state = await getStreakState();
    final key = _stateKey(state);
    final list = slotData[key] as List<dynamic>?;
    if (list == null || list.isEmpty) {
      return const StreakNotificationContent(
        message: 'Stay in the Word.',
        action: 'open_reading',
      );
    }
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % list.length;
    final item = list[index] as Map<String, dynamic>;
    final message = item['message'] as String? ?? 'Stay in the Word.';
    final action = item['action'] as String? ?? 'open_reading';
    return StreakNotificationContent(message: message, action: action);
  }

  /// Convenience: get content for morning (8 AM).
  static Future<StreakNotificationContent> getMorningContent() =>
      getContentForSlot('morning');

  /// Convenience: get content for afternoon (2 PM).
  static Future<StreakNotificationContent> getAfternoonContent() =>
      getContentForSlot('afternoon');

  /// Convenience: get content for night (8 PM).
  static Future<StreakNotificationContent> getNightContent() =>
      getContentForSlot('night');

  /// Reschedule morning/afternoon/evening streak notifications with current streak state.
  /// Call on app open so notification text matches current scenario and all enabled slots are registered.
  static Future<void> rescheduleStreakNotificationsIfEnabled() async {
    final on1 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn);
    final on2 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);
    final on3 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
    final hasAny = (on1 ?? false) || (on2 ?? false) || (on3 ?? false);
    if (!hasAny) return;

    await SmartNotificationHelper.cancelSmartNotification();
    final svc = NotificationsServices();
    if (on1 == true) {
      final content = await getMorningContent();
      await svc.showNotification(1, 'Bible', content.message, 8, 0, payload: content.action);
    }
    if (on2 == true) {
      final content = await getAfternoonContent();
      await svc.showNotification(2, 'Bible', content.message, 14, 0, payload: content.action);
    }
    if (on3 == true) {
      final content = await getNightContent();
      await svc.showNotification(3, 'Bible', content.message, 20, 0, payload: content.action);
    }
  }
}
