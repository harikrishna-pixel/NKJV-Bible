import 'dart:convert';

import 'package:biblebookapp/services/daily_slot_notification_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/services.dart';

/// Streak state for notification content.
enum StreakNotificationState {
  streak_not_started,
  streak_pending,
  streak_completed,
}

/// Result for one notification: title, message body and action payload for tap.
class StreakNotificationContent {
  const StreakNotificationContent({
    required this.title,
    required this.message,
    required this.action,
  });
  final String title;
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
        title: 'Bible',
        message: 'Stay in the Word.',
        action: 'open_reading',
      );
    }
    final state = await getStreakState();
    final key = _stateKey(state);
    final list = slotData[key] as List<dynamic>?;
    if (list == null || list.isEmpty) {
      return const StreakNotificationContent(
        title: 'Bible',
        message: 'Stay in the Word.',
        action: 'open_reading',
      );
    }
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % list.length;
    final item = list[index] as Map<String, dynamic>;
    final title = item['title'] as String? ?? 'Bible';
    final message = item['message'] as String? ?? 'Stay in the Word.';
    final action = item['action'] as String? ?? 'open_reading';
    return StreakNotificationContent(
      title: title,
      message: message,
      action: action,
    );
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

  static Future<({int hh, int mm})> timeForSlot(String slot) async {
    switch (slot) {
      case 'afternoon':
        final h = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeHour1) ??
                    '14') ??
            14;
        final m = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeMinute1) ??
                    '0') ??
            0;
        return (hh: h, mm: m);
      case 'night':
        final h = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeHour2) ??
                    '20') ??
            20;
        final m = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeMinute2) ??
                    '0') ??
            0;
        return (hh: h, mm: m);
      case 'morning':
      default:
        final h = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeHour) ??
                    '8') ??
            8;
        final m = int.tryParse(
                await SharPreferences.getString(
                        SharPreferences.notificationTimeMinute) ??
                    '0') ??
            0;
        return (hh: h, mm: m);
    }
  }

  /// Reschedule enabled slots with single-notification priority (streak → chat → verse).
  static Future<void> rescheduleStreakNotificationsIfEnabled() async {
    await DailySlotNotificationHelper.rescheduleEnabledSlots();
  }
}
