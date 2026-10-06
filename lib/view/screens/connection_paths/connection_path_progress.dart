import 'package:biblebookapp/services/reading_plan_progress_service.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Connection Path progress. Day completion + next-day-tomorrow gating reuse
/// [ReadingPlanProgressService]; this adds per-day steps, reflections and
/// completion dates under separate keys.
class ConnectionPathProgress {
  ConnectionPathProgress._();

  static const _stepPrefix = 'cp_step_';
  static const _reflectionPrefix = 'cp_reflection_';
  static const _completedOnPrefix = 'cp_completed_on_';

  static Future<bool> isStarted(String pathId) =>
      ReadingPlanProgressService.isStarted(pathId);

  static Future<void> start(String pathId) =>
      ReadingPlanProgressService.markStarted(pathId);

  static Future<bool> isCompleted(String pathId) =>
      ReadingPlanProgressService.isCompleted(pathId);

  static Future<bool> isDayCompleted(String pathId, int day) =>
      ReadingPlanProgressService.isDayCompleted(pathId, day);

  static Future<bool> canOpenDay(ConnectionPath path, int day) =>
      ReadingPlanProgressService.canOpenDay(
        planId: path.id,
        dayIndex: day,
        totalDays: path.durationDays,
      );

  static Future<Set<int>> completedDays(ConnectionPath path) async {
    final out = <int>{};
    for (var i = 0; i < path.durationDays; i++) {
      if (await isDayCompleted(path.id, i)) out.add(i);
    }
    return out;
  }

  /// First incomplete day index, or durationDays when all done.
  static Future<int> currentDay(ConnectionPath path) async {
    for (var i = 0; i < path.durationDays; i++) {
      if (!await isDayCompleted(path.id, i)) return i;
    }
    return path.durationDays;
  }

  static Future<bool> isStepDone(String pathId, int day, PathStep step) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_stepPrefix${pathId}_${day}_${step.name}') ?? false;
  }

  static Future<void> setStepDone(String pathId, int day, PathStep step) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_stepPrefix${pathId}_${day}_${step.name}', true);
  }

  static Future<Set<PathStep>> stepsDone(String pathId, int day) async {
    final out = <PathStep>{};
    for (final s in PathStep.values) {
      if (await isStepDone(pathId, day, s)) out.add(s);
    }
    return out;
  }

  static Future<String> reflection(String pathId, int day) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('$_reflectionPrefix${pathId}_$day') ?? '';
  }

  static Future<void> saveReflection(String pathId, int day, String text) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_reflectionPrefix${pathId}_$day', text);
  }

  /// Marks the day complete. Returns true if this finished the whole path.
  static Future<bool> completeDay(ConnectionPath path, int day) async {
    await ReadingPlanProgressService.setDayCompleted(
      path.id,
      day,
      completed: true,
    );
    final done = await ReadingPlanProgressService.completedDayCount(
      path.id,
      path.durationDays,
    );
    if (done >= path.durationDays) {
      await ReadingPlanProgressService.markCompleted(path.id);
      final p = await SharedPreferences.getInstance();
      await p.setString(
        '$_completedOnPrefix${path.id}',
        DateTime.now().toIso8601String(),
      );
      return true;
    }
    return false;
  }

  static Future<DateTime?> completedOn(String pathId) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('$_completedOnPrefix$pathId');
    return s == null ? null : DateTime.tryParse(s);
  }

  static Future<void> reset(ConnectionPath path) async {
    await ReadingPlanProgressService.reset(path.id, path.durationDays);
    final p = await SharedPreferences.getInstance();
    await p.remove('$_completedOnPrefix${path.id}');
    for (var i = 0; i < path.durationDays; i++) {
      for (final s in PathStep.values) {
        await p.remove('$_stepPrefix${path.id}_${i}_${s.name}');
      }
      await p.remove('$_reflectionPrefix${path.id}_$i');
    }
  }

  static Future<List<ConnectionPath>> activePaths() async {
    final out = <ConnectionPath>[];
    for (final path in ConnectionPathsData.all) {
      if (await isStarted(path.id) && !await isCompleted(path.id)) {
        out.add(path);
      }
    }
    return out;
  }

  static Future<List<ConnectionPath>> completedPaths() async {
    final out = <ConnectionPath>[];
    for (final path in ConnectionPathsData.all) {
      if (await isCompleted(path.id)) out.add(path);
    }
    return out;
  }
}
