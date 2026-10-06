import 'package:biblebookapp/view/screens/milestones/data/milestones_data.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_celebration_store.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_unlocked_dialog.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_progress.dart';
import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows parchment unlock popup for newly completed milestones.
/// Read-only vs existing streak/prayer/reading stores; only writes celebration flags.
class MilestoneCelebrationCoordinator {
  MilestoneCelebrationCoordinator._();

  static bool _busy = false;

  /// Snapshot current completes so upgrade users are not flooded with old unlocks.
  /// Call early at splash / home before the user can earn a new milestone.
  static Future<void> seedBaselineIfNeeded() async {
    if (await MilestoneCelebrationStore.isSeeded()) return;
    final celebrated = await MilestoneCelebrationStore.loadCelebratedIds();
    for (final def in MilestonesData.all) {
      final current = await MilestonesProgressService.currentFor(def);
      if (current >= def.target) celebrated.add(def.id);
    }
    await MilestoneCelebrationStore.saveCelebratedIds(celebrated);
    await MilestoneCelebrationStore.markSeeded();
  }

  /// Check progress and show at most one unlock popup if something is newly done.
  static Future<void> checkAndShow([BuildContext? context]) async {
    if (_busy) return;
    _busy = true;
    try {
      // Ensure baseline exists before comparing (safe if already seeded).
      final wasSeeded = await MilestoneCelebrationStore.isSeeded();
      await seedBaselineIfNeeded();
      // If we just created the baseline in this call, do not show anything.
      if (!wasSeeded) return;

      final ctx = context ?? Get.overlayContext ?? Get.context;
      if (ctx == null || !ctx.mounted) return;

      final celebrated = await MilestoneCelebrationStore.loadCelebratedIds();
      MilestoneProgress? firstNew;

      for (final def in MilestonesData.all) {
        final current = await MilestonesProgressService.currentFor(def);
        final p = MilestoneProgress(def: def, current: current);
        if (!p.isComplete || celebrated.contains(def.id)) continue;
        firstNew = p;
        break;
      }

      if (firstNew == null || !ctx.mounted) return;

      await MilestoneCelebrationStore.markCelebrated(firstNew.def.id);
      if (!ctx.mounted) return;
      await MilestoneUnlockedDialog.show(ctx, progress: firstNew);
    } catch (_) {
      // Additive UI only — never block caller flows.
    } finally {
      _busy = false;
    }
  }
}
