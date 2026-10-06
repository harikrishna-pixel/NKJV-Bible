import 'package:shared_preferences/shared_preferences.dart';

/// Local progress for Reading Plans only.
/// Uses its own preference keys — does not touch Study Plan progress.
class ReadingPlanProgressService {
  ReadingPlanProgressService._();

  static const _startedPrefix = 'reading_plan_started_';
  static const _dayPrefix = 'reading_plan_day_';
  static const _completedPrefix = 'reading_plan_completed_';
  /// Calendar day (yyyy-M-d) when the user last marked a day complete.
  static const _lastCompleteDatePrefix = 'reading_plan_last_complete_date_';

  static String calendarDayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Future<bool> isStarted(String planId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_startedPrefix$planId') ?? false;
  }

  static Future<void> markStarted(String planId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_startedPrefix$planId', true);
  }

  static Future<bool> isDayCompleted(String planId, int dayIndex) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_dayPrefix${planId}_$dayIndex') ?? false;
  }

  static Future<void> setDayCompleted(
    String planId,
    int dayIndex, {
    required bool completed,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_dayPrefix${planId}_$dayIndex', completed);
    if (completed) {
      await p.setString(
        '$_lastCompleteDatePrefix$planId',
        calendarDayKey(),
      );
      await p.setBool('$_startedPrefix$planId', true);
    }
  }

  static Future<String?> lastCompleteDate(String planId) async {
    final p = await SharedPreferences.getInstance();
    final s = (p.getString('$_lastCompleteDatePrefix$planId') ?? '').trim();
    return s.isEmpty ? null : s;
  }

  static Future<int> completedDayCount(String planId, int totalDays) async {
    var n = 0;
    for (var i = 0; i < totalDays; i++) {
      if (await isDayCompleted(planId, i)) n++;
    }
    return n;
  }

  static Future<double> progress(String planId, int totalDays) async {
    if (totalDays <= 0) return 0;
    final done = await completedDayCount(planId, totalDays);
    return done / totalDays;
  }

  static Future<bool> isCompleted(String planId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_completedPrefix$planId') ?? false;
  }

  static Future<void> markCompleted(String planId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_completedPrefix$planId', true);
  }

  /// Not started | Ongoing | Completed — for list / header badges.
  static Future<ReadingPlanStatusInfo> statusInfo({
    required String planId,
    required int totalDays,
  }) async {
    final done = await completedDayCount(planId, totalDays);
    final pct = totalDays <= 0 ? 0.0 : done / totalDays;
    if (done <= 0) {
      return ReadingPlanStatusInfo(
        label: 'Not started',
        completedDays: 0,
        totalDays: totalDays,
        progress: 0,
        kind: ReadingPlanStatusKind.notStarted,
      );
    }
    if (done >= totalDays) {
      return ReadingPlanStatusInfo(
        label: 'Completed',
        completedDays: totalDays,
        totalDays: totalDays,
        progress: 1,
        kind: ReadingPlanStatusKind.completed,
      );
    }
    return ReadingPlanStatusInfo(
      label: 'Ongoing · $done of $totalDays',
      completedDays: done,
      totalDays: totalDays,
      progress: pct,
      kind: ReadingPlanStatusKind.ongoing,
    );
  }

  /// True if this day may be opened now.
  /// Completed days can always be re-read.
  /// The next incomplete day unlocks only on a **new calendar day**
  /// after the previous day was marked complete.
  static Future<bool> canOpenDay({
    required String planId,
    required int dayIndex,
    required int totalDays,
  }) async {
    if (dayIndex < 0 || dayIndex >= totalDays) return false;

    if (await isDayCompleted(planId, dayIndex)) return true;

    // Must finish earlier days first.
    for (var i = 0; i < dayIndex; i++) {
      if (!await isDayCompleted(planId, i)) return false;
    }

    // First day is always available until completed.
    if (dayIndex == 0) return true;

    final last = await lastCompleteDate(planId);
    if (last == null) return false;

    // Locked until tomorrow (next calendar day after last complete).
    return last != calendarDayKey();
  }

  static Future<void> reset(String planId, int totalDays) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('$_startedPrefix$planId');
    await p.remove('$_completedPrefix$planId');
    await p.remove('$_lastCompleteDatePrefix$planId');
    for (var i = 0; i < totalDays; i++) {
      await p.remove('$_dayPrefix${planId}_$i');
    }
  }
}

enum ReadingPlanStatusKind { notStarted, ongoing, completed }

class ReadingPlanStatusInfo {
  const ReadingPlanStatusInfo({
    required this.label,
    required this.completedDays,
    required this.totalDays,
    required this.progress,
    required this.kind,
  });

  final String label;
  final int completedDays;
  final int totalDays;
  final double progress;
  final ReadingPlanStatusKind kind;
}
