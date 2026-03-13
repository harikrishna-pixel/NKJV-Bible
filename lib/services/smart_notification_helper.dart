import 'dart:convert';

import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/services.dart';

/// ID used for the single smart-detected notification (do not conflict with 1=morning, 2=afternoon, 3=evening).
const int smartNotificationId = 0;

/// Result for smart notification: body text and action payload for tap.
class SmartNotificationContent {
  const SmartNotificationContent({
    required this.message,
    required this.actionId,
  });
  final String message;
  final String actionId;
}

/// Tracks last 7 days app open times, computes average, and provides content from smart_detected.json.
/// Only used when the user has NOT set any manual notification time (Morning/Afternoon/Evening all off).
class SmartNotificationHelper {
  static const int _maxDays = 7;
  static const int _minutesBefore = 30;

  static Map<String, dynamic>? _cachedJson;

  static Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) return _cachedJson!;
    final String raw =
        await rootBundle.loadString('assets/smart_detected.json');
    _cachedJson = json.decode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  /// Returns true if user has at least one manual notification (Morning/Afternoon/Evening) enabled.
  static Future<bool> userHasManualNotificationEnabled() async {
    final on1 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn);
    final on2 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);
    final on3 = await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
    return (on1 ?? false) || (on2 ?? false) || (on3 ?? false);
  }

  /// Record that the app was opened now. Keeps at most last 7 days (one entry per day; updates today's time).
  static Future<void> recordAppOpen() async {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String? raw = await SharPreferences.getString(SharPreferences.appOpenTimes);
    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        list = (map['open_times'] as List<dynamic>?) ?? [];
      } catch (_) {
        list = [];
      }
    }

    final List<Map<String, String>> entries = [];
    for (final e in list) {
      if (e is Map<String, dynamic>) {
        final d = e['date'] as String?;
        final t = e['time'] as String?;
        if (d != null && t != null) entries.add({'date': d, 'time': t});
      }
    }

    final cutoff = now.subtract(Duration(days: _maxDays));
    final cutoffStr = cutoff.toIso8601String().split('T')[0];
    entries.removeWhere((e) => e['date']!.compareTo(cutoffStr) < 0);

    final todayIndex = entries.indexWhere((e) => e['date'] == dateStr);
    if (todayIndex >= 0) {
      entries[todayIndex] = {'date': dateStr, 'time': timeStr};
    } else {
      entries.add({'date': dateStr, 'time': timeStr});
    }

    entries.sort((a, b) => (a['date']!).compareTo(b['date']!));
    final out = json.encode({'open_times': entries});
    await SharPreferences.setString(SharPreferences.appOpenTimes, out);
  }

  /// Computes average open time from last 7 days and returns (hour, minute) for notification 30 min before that.
  /// Returns null if we don't have enough data (e.g. fewer than 1 open).
  static Future<({int hh, int mm})?> getNotificationTime30MinBefore() async {
    String? raw = await SharPreferences.getString(SharPreferences.appOpenTimes);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final list = map['open_times'] as List<dynamic>?;
      if (list == null || list.isEmpty) return null;

      int totalMinutes = 0;
      int count = 0;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final t = e['time'] as String?;
        if (t == null) continue;
        final parts = t.split(':');
        if (parts.length < 2) continue;
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) continue;
        totalMinutes += h * 60 + m;
        count++;
      }
      if (count == 0) return null;

      final avgMinutes = totalMinutes ~/ count;
      final notifyMinutes = avgMinutes - _minutesBefore;
      if (notifyMinutes < 0) {
        final hh = (24 * 60 + notifyMinutes) ~/ 60;
        final mm = (24 * 60 + notifyMinutes) % 60;
        return (hh: hh % 24, mm: mm);
      }
      return (hh: notifyMinutes ~/ 60, mm: notifyMinutes % 60);
    } catch (_) {
      return null;
    }
  }

  /// Picks one message from smart_detected.json messages array (rotate by day) and returns message + action_id.
  static Future<SmartNotificationContent> getSmartNotificationContent() async {
    final data = await _loadJson();
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      return const SmartNotificationContent(
        message: 'Time for your Bible moment.',
        actionId: 'open_reading',
      );
    }
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % messages.length;
    final item = messages[index] as Map<String, dynamic>?;
    final message = item?['message'] as String? ?? 'Time for your Bible moment.';
    final actionId = item?['action_id'] as String? ?? 'open_reading';
    return SmartNotificationContent(message: message, actionId: actionId);
  }

  /// Schedules the smart notification only when user has NOT set any manual time. Call after recording app open or when user turns all toggles off.
  static Future<void> scheduleSmartNotificationIfNeeded() async {
    if (await userHasManualNotificationEnabled()) return;
    final time = await getNotificationTime30MinBefore();
    if (time == null) return;
    final content = await getSmartNotificationContent();
    await NotificationsServices().showNotification(
      smartNotificationId,
      'Bible',
      content.message,
      time.hh,
      time.mm,
      payload: content.actionId,
    );
  }

  /// Cancels the smart notification. Call when user enables any manual notification (Morning/Afternoon/Evening).
  static Future<void> cancelSmartNotification() async {
    NotificationsServices().stopNotification(smartNotificationId);
  }
}
