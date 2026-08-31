// Single Live Activity at a time (display-only orchestration).
// Order: Streak (until 4/4) → Continue Reading → Today's Memory Verse.
// Does not change streak, reading, or verse business logic.

import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/live_activity/content_live_activity.dart';
import 'package:biblebookapp/streak/streak_live_activity.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';

/// Which Live Activity should be visible right now.
enum LiveActivitySlot { streak, continueReading, memoryVerse }

/// Ensures only one Live Activity is active, in priority order.
class LiveActivityQueue {
  static Timer? _dayBoundaryTimer;

  /// Refresh the single active Live Activity from existing app data.
  static Future<void> sync({bool forceStart = false}) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final slot = await currentSlot();
      switch (slot) {
        case LiveActivitySlot.streak:
          await ContentLiveActivitySync.endAll();
          await StreakLiveActivitySync.sync(forceStart: forceStart);
          break;
        case LiveActivitySlot.continueReading:
          await StreakLiveActivitySync.end();
          await ContentLiveActivitySync.endMemoryVerse();
          await ContentLiveActivitySync.syncContinueReading(
            forceStart: true,
          );
          break;
        case LiveActivitySlot.memoryVerse:
          await StreakLiveActivitySync.end();
          await ContentLiveActivitySync.endContinueReading();
          await ContentLiveActivitySync.syncMemoryVerse(
            forceStart: true,
          );
          break;
      }
      _scheduleNextDayBoundarySync();
    } catch (e) {
      debugPrint('LiveActivityQueue.sync failed: $e');
    }
  }

  /// Display-only: which slot wins right now (reads existing prefs/DB only).
  static Future<LiveActivitySlot> currentSlot() async {
    final steps = await StreakLiveActivitySync.todayStepsCompleted();
    if (steps < StreakLiveActivitySync.stepsTotal) {
      return LiveActivitySlot.streak;
    }

    // Streak done for today → Continue Reading until current chapter is complete,
    // then Today's Memory Verse. (Read-only: verse is_read flags in DB.)
    if (!await _isCurrentChapterComplete()) {
      return LiveActivitySlot.continueReading;
    }
    return LiveActivitySlot.memoryVerse;
  }

  /// Read-only: all verses in the saved book/chapter marked is_read = yes.
  static Future<bool> _isCurrentChapterComplete() async {
    try {
      final bookNumStr =
          (await SharPreferences.getString(SharPreferences.selectedBookNum)) ??
              '0';
      final chapterStr =
          (await SharPreferences.getString(SharPreferences.selectedChapter)) ??
              '1';
      final bookNum = int.tryParse(bookNumStr) ?? 0;
      final chapterNum = int.tryParse(chapterStr) ?? 1;
      if (bookNum < 0) return false;

      final db = await DBHelper().db;
      if (db == null) return false;

      // chapter_num in DB is 0-based (UI chapter - 1).
      final dbChapter = (chapterNum - 1).clamp(0, 200);
      final rows = await db.rawQuery(
        '''
        SELECT
          COUNT(*) AS total,
          SUM(CASE WHEN LOWER(TRIM(is_read)) = 'yes' THEN 1 ELSE 0 END) AS read_count
        FROM verse
        WHERE book_num = ? AND chapter_num = ?
        ''',
        [bookNum, dbChapter],
      );
      if (rows.isEmpty) return false;

      final total = int.tryParse('${rows.first['total']}') ?? 0;
      if (total <= 0) return false;
      final readCount = int.tryParse('${rows.first['read_count']}') ?? 0;
      return readCount >= total;
    } catch (_) {
      return false;
    }
  }

  static void _scheduleNextDayBoundarySync() {
    if (kIsWeb || !Platform.isIOS) return;
    _dayBoundaryTimer?.cancel();
    final now = DateTime.now();
    final nextBoundary = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final delay = nextBoundary.difference(now);
    if (delay.isNegative) return;
    _dayBoundaryTimer = Timer(delay, () {
      unawaited(sync());
    });
  }
}
