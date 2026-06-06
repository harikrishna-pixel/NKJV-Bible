import 'dart:convert';

import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/services.dart';

/// Separate scenario-based notifications (IDs 11/12/13).
/// Does not modify streak or smart notification helpers.
const int scenarioMorningNotificationId = 11;
const int scenarioAfternoonNotificationId = 12;
const int scenarioEveningNotificationId = 13;

class ScenarioNotificationContent {
  const ScenarioNotificationContent({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final String action;
}

/// Loads [assets/notification_matrix.json] + [assets/notification_templates.json]
/// and schedules personalized morning/afternoon/evening notifications.
class ScenarioNotificationHelper {
  static List<Map<String, dynamic>>? _cachedMatrix;
  static List<Map<String, dynamic>>? _cachedTemplates;

  static const Map<String, String> _scheduleToTemplateCategory = {
    'VERSE': 'VERSE_OF_THE_DAY',
    'AI_CHAT': 'AI_CHAT',
    'PRAYER': 'PRAYER',
    'DAILY_SCRIPTURE': 'DAILY_SCRIPTURE',
    'DEVOTIONAL': 'DEVOTIONAL',
    'CHECK_CONNECTION': 'CHECK_YOUR_CONNECTION_WITH_GOD',
    'STREAKS': 'STREAKS',
  };

  static String _todayKey() =>
      DateTime.now().toIso8601String().split('T')[0];

  static String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.toIso8601String().split('T')[0];
  }

  static Future<List<Map<String, dynamic>>> _loadMatrix() async {
    if (_cachedMatrix != null) return _cachedMatrix!;
    final raw =
        await rootBundle.loadString('assets/notification_matrix.json');
    final list = json.decode(raw) as List<dynamic>;
    _cachedMatrix =
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return _cachedMatrix!;
  }

  static Future<List<Map<String, dynamic>>> _loadTemplates() async {
    if (_cachedTemplates != null) return _cachedTemplates!;
    final raw =
        await rootBundle.loadString('assets/notification_templates.json');
    final list = json.decode(raw) as List<dynamic>;
    _cachedTemplates =
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return _cachedTemplates!;
  }

  static Future<List<String>> _openDates() async {
    final raw = await SharPreferences.getString(SharPreferences.appOpenTimes);
    if (raw == null || raw.isEmpty) return [];
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final list = map['open_times'] as List<dynamic>? ?? [];
      final dates = <String>[];
      for (final entry in list) {
        if (entry is Map<String, dynamic>) {
          final date = entry['date'] as String?;
          if (date != null && date.isNotEmpty) dates.add(date);
        }
      }
      dates.sort();
      return dates;
    } catch (_) {
      return [];
    }
  }

  static Future<int> _daysSinceLastOpen() async {
    final dates = await _openDates();
    if (dates.isEmpty) {
      final installed =
          await SharPreferences.getString(SharPreferences.appInstalledDate);
      if (installed == null || installed.isEmpty) return 0;
      try {
        final installedDate = DateTime.parse(installed);
        final today = DateTime.now();
        final installedDay = DateTime(
            installedDate.year, installedDate.month, installedDate.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        return todayDay.difference(installedDay).inDays;
      } catch (_) {
        return 0;
      }
    }
    final last = dates.last;
    try {
      final lastDate = DateTime.parse(last);
      final today = DateTime.now();
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      return todayDay.difference(lastDay).inDays;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> _installedToday() async {
    final installed =
        await SharPreferences.getString(SharPreferences.appInstalledDate);
    return installed == _todayKey();
  }

  static Future<bool> _openedToday() async {
    return (await _openDates()).contains(_todayKey());
  }

  static Future<bool> _openedYesterday() async {
    return (await _openDates()).contains(_yesterdayKey());
  }

  static Future<bool> _completedStreakToday() async {
    final last =
        await SharPreferences.getString(SharPreferences.streakFlowLastShownDate);
    return last == _todayKey();
  }

  static Future<bool> _startedStreakToday() async {
    final started =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    return started == _todayKey();
  }

  static Future<bool> _readYesterday() async {
    final dates = await SharPreferences.getStringList(
            SharPreferences.streakCompletedDates) ??
        [];
    return dates.contains(_yesterdayKey());
  }

  static Future<int> _totalOpenDays() => _openDates().then((d) => d.length);

  static Future<int> _totalCompletedDays() async {
    final dates = await SharPreferences.getStringList(
            SharPreferences.streakCompletedDates) ??
        [];
    return dates.length;
  }

  static Future<bool> _hasAiActivity() async {
    final last =
        await SharPreferences.getString(SharPreferences.streakLastActivityDate);
    return last != null && last.isNotEmpty;
  }

  static Future<bool> _onboardingComplete() async {
    return (await SharPreferences.getBoolean(SharPreferences.onboarding)) ??
        false;
  }

  static Future<int> _currentStreakCount() async {
    return (await SharPreferences.getInt(SharPreferences.streakCount)) ?? 0;
  }

  /// Picks the best matching row from notification_matrix.json.
  static Future<int> resolveMatrixId() async {
    final daysInactive = await _daysSinceLastOpen();
    final openedToday = await _openedToday();
    final openedYesterday = await _openedYesterday();
    final completedToday = await _completedStreakToday();
    final readYesterday = await _readYesterday();
    final totalOpens = await _totalOpenDays();
    final totalCompleted = await _totalCompletedDays();
    final streakCount = await _currentStreakCount();
    final installedToday = await _installedToday();
    final onboarding = await _onboardingComplete();
    final hasAi = await _hasAiActivity();
    final startedToday = await _startedStreakToday();

    if (daysInactive >= 30) return 23;
    if (daysInactive >= 21) return 22;
    if (daysInactive >= 14) return 21;
    if (daysInactive >= 10) return 20;
    if (daysInactive >= 7) return 19;
    if (daysInactive >= 5) return 18;
    if (daysInactive >= 3) {
      if (totalCompleted >= 7) return 24;
      if (hasAi) return 26;
      return 17;
    }

    if (totalOpens >= 30 && daysInactive == 0) return 16;
    if (streakCount >= 7 && daysInactive == 0) return 15;
    if (openedToday && !completedToday && !startedToday) return 14;
    if (completedToday) return 12;
    if (openedToday && startedToday && !completedToday) return 11;
    if (readYesterday) return 10;
    if (openedYesterday) return 9;
    if (openedToday) return 13;

    if (streakCount >= 1) return 8;
    if (completedToday || (startedToday && hasAi)) return 7;
    if (hasAi) return 6;
    if (totalCompleted >= 1 || startedToday) return 5;
    if (onboarding) return 4;
    if (totalOpens == 1) return 3;
    if (totalOpens == 0 && !installedToday) return 2;
    if (installedToday) return 1;

    return 9;
  }

  static String _actionForTemplateCategory(String category) {
    switch (category) {
      case 'AI_CHAT':
        return 'open_chat';
      case 'PRAYER':
      case 'DEVOTIONAL':
      case 'CHECK_YOUR_CONNECTION_WITH_GOD':
      case 'STREAKS':
        return 'open_streak';
      case 'VERSE_OF_THE_DAY':
      case 'DAILY_SCRIPTURE':
        return 'open_verse';
      default:
        return 'open_verse';
    }
  }

  static Future<ScenarioNotificationContent> getContentForSlot(
      String slot) async {
    final matrix = await _loadMatrix();
    final templates = await _loadTemplates();
    final matrixId = await resolveMatrixId();

    final row = matrix.firstWhere(
      (e) => e['id'] == matrixId,
      orElse: () => matrix.first,
    );
    final schedule = row['schedule'] as Map<String, dynamic>? ?? {};
    final scheduleKey = schedule[slot] as String? ?? 'VERSE';
    final templateCategory =
        _scheduleToTemplateCategory[scheduleKey] ?? 'VERSE_OF_THE_DAY';

    final categoryTemplates = templates
        .where((t) => t['category'] == templateCategory)
        .toList();
    if (categoryTemplates.isEmpty) {
      return const ScenarioNotificationContent(
        title: 'Bible',
        message: 'Take a moment with God today.',
        action: 'open_verse',
      );
    }

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final template =
        categoryTemplates[dayOfYear % categoryTemplates.length];
    final title = template['title'] as String? ?? 'Bible';
    final message =
        template['message'] as String? ?? 'Take a moment with God today.';

    return ScenarioNotificationContent(
      title: title,
      message: message,
      action: _actionForTemplateCategory(templateCategory),
    );
  }

  static Future<({int hh, int mm})> _timeForSlot(String slot) async {
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
      case 'evening':
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

  static Future<void> _cancelAll() async {
    final svc = NotificationsServices();
    svc.stopNotification(scenarioMorningNotificationId);
    svc.stopNotification(scenarioAfternoonNotificationId);
    svc.stopNotification(scenarioEveningNotificationId);
  }

  /// Schedules scenario notifications when enabled. Uses separate IDs/channel
  /// from streak notifications (1/2/3).
  static Future<void> rescheduleScenarioNotificationsIfEnabled() async {
    final enabled =
        await SharPreferences.getBoolean(SharPreferences.isScenarioNotificationOn);
    if (enabled == false) {
      await _cancelAll();
      return;
    }

    final onMorning =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn);
    final onAfternoon =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);
    final onEvening =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);

    await NotificationsServices.ensureInitialized();
    await _cancelAll();

    final hasAny =
        (onMorning ?? false) || (onAfternoon ?? false) || (onEvening ?? false);
    if (!hasAny) return;

    final svc = NotificationsServices();

    if (onMorning == true) {
      final content = await getContentForSlot('morning');
      final time = await _timeForSlot('morning');
      await svc.showScenarioNotification(
        scenarioMorningNotificationId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
    }
    if (onAfternoon == true) {
      final content = await getContentForSlot('afternoon');
      final time = await _timeForSlot('afternoon');
      await svc.showScenarioNotification(
        scenarioAfternoonNotificationId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
    }
    if (onEvening == true) {
      final content = await getContentForSlot('evening');
      final time = await _timeForSlot('evening');
      await svc.showScenarioNotification(
        scenarioEveningNotificationId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
    }
  }
}
