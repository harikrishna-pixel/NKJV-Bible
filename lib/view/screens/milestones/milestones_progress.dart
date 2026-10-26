import 'package:biblebookapp/services/reading_plan_progress_service.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/milestones/data/milestones_data.dart';
import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/reading_plans/data/reading_plans_data.dart';
import 'package:biblebookapp/view/screens/reading_plans/models/reading_plan_model.dart';

/// Read-only progress for Achievements / Milestones.
/// Uses existing streak + Prayer Wall local stores + reading-plan prefs.
/// Does not write streak / prayer / reading-plan business logic.
class MilestonesProgressService {
  MilestonesProgressService._();

  /// Days Connected = distinct days with a Daily Connection (streak) or a
  /// completed Connection Path day; same calendar date counts once.
  static Future<int> _connectionDays() async {
    final streakDates = await SharPreferences.getStringList(
            SharPreferences.streakCompletedDates) ??
        <String>[];
    final pathDays = await ConnectionPathProgress.connectedDayKeys();
    return {...streakDates, ...pathDays}.length;
  }

  /// My-prayer ids are cleared/rebuilt by the Prayer Wall account sync, so a
  /// just-posted (pending) prayer can drop out; the device-owned ids written
  /// on post are not touched by that sync.
  static Future<int> _prayersPosted() async => {
        ...await PrayerWallLocalStore.loadMyPrayerIds(),
        ...await PrayerWallLocalStore.loadOwnedPrayerIds(),
      }.length;

  static Future<int> _prayersJoined() async =>
      (await PrayerWallLocalStore.loadLikeMap()).length;

  static Future<int> _commentsMade() async =>
      (await PrayerWallLocalStore.loadMyCommentIds()).length;

  static Future<int> _pathsCompleted() async {
    var n = (await ConnectionPathProgress.completedPaths()).length;
    for (final plan in ReadingPlansData.allPlans) {
      if (await ReadingPlanProgressService.isCompleted(plan.id)) n++;
    }
    return n;
  }

  static Future<int> currentFor(MilestoneDef def) async {
    switch (def.category) {
      case MilestoneCategory.connection:
        // Path-completion milestones (doc §10) live under Connection tab.
        if (def.id.startsWith('path_')) return _pathsCompleted();
        // Connection day milestones use total days connected (not streak).
        return _connectionDays();
      case MilestoneCategory.prayer:
        // First Prayer = published prayers; others = unique prayers joined.
        if (def.id == 'pray_1') return _prayersPosted();
        return _prayersJoined();
      case MilestoneCategory.community:
        return _commentsMade();
    }
  }

  static Future<List<MilestoneProgress>> forCategory(
    MilestoneCategory category,
  ) async {
    final defs = MilestonesData.byCategory(category);
    final out = <MilestoneProgress>[];
    for (final d in defs) {
      out.add(MilestoneProgress(def: d, current: await currentFor(d)));
    }
    return out;
  }

  static Future<MilestoneProgress?> forId(String id) async {
    final def = MilestonesData.byId(id);
    if (def == null) return null;
    return MilestoneProgress(def: def, current: await currentFor(def));
  }

  static Future<ConnectionHubStats> hubStats() async {
    final connected = await _connectionDays();
    final streak = await StreakService.getCurrentStreak();
    final paths = await _pathsCompleted();
    final joined = await _prayersJoined();
    var answers = 0;
    try {
      answers = (await PrayerWallLocalStore.loadStatusSubmittedIds()).length;
    } catch (_) {}

    String? activeTitle;
    String? activePathId;
    var activeDay = 0;
    var activeTotal = 0;
    final activePaths = await ConnectionPathProgress.activePaths();
    if (activePaths.isNotEmpty) {
      final p = activePaths.first;
      activeTitle = p.title;
      activePathId = p.id;
      activeDay = (await ConnectionPathProgress.completedDays(p)).length;
      activeTotal = p.durationDays;
    }
    for (final plan in activeTitle != null
        ? const <ReadingPlan>[]
        : ReadingPlansData.allPlans) {
      final started = await ReadingPlanProgressService.isStarted(plan.id);
      final done = await ReadingPlanProgressService.isCompleted(plan.id);
      if (!started || done) continue;
      final count = await ReadingPlanProgressService.completedDayCount(
        plan.id,
        plan.durationDays,
      );
      activeTitle = plan.title;
      activeDay = count.clamp(0, plan.durationDays);
      activeTotal = plan.durationDays;
      break;
    }

    return ConnectionHubStats(
      totalConnectedDays: connected,
      currentStreak: streak,
      pathsCompleted: paths,
      prayersJoined: joined,
      answersReceived: answers,
      activePathTitle: activeTitle,
      activePathId: activePathId,
      activePathDay: activeDay,
      activePathTotal: activeTotal,
    );
  }
}
