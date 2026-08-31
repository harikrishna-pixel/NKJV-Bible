// iOS Live Activity mirror for Daily Streak.
// Read-only sync — does not change streak calculation or preferences.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mirrors current streak + today's steps onto an iOS Live Activity.
class StreakLiveActivitySync {
  static const MethodChannel _channel =
      MethodChannel('com.biblebookapp/streak_live_activity');

  static const int _stepsTotal = 4;

  /// Display-only total steps mirrored on the Live Activity.
  static int get stepsTotal => _stepsTotal;

  /// Last calendar day (yyyy-MM-dd) that was successfully mirrored.
  static String? _lastSyncedDayKey;

  /// Fires once shortly after local midnight to refresh the lock-screen mirror.
  static Timer? _dayBoundaryTimer;

  static String _todayKey() => DateTime.now().toIso8601String().split('T')[0];

  /// Push current streak state to the Live Activity (start or update).
  /// Safe to call often; failures are ignored so streak logic is never affected.
  static Future<void> sync({bool forceStart = false}) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final streak = await StreakService.getCurrentStreak();
      final steps = await _todayStepsCompleted();
      final dayKey = _todayKey();
      await _channel.invokeMethod<void>('sync', <String, dynamic>{
        'streakCount': streak,
        'stepsCompleted': steps,
        'stepsTotal': _stepsTotal,
        'forceStart': forceStart,
        // Display-only: which local day this snapshot belongs to.
        'contentDayKey': dayKey,
      });
      _lastSyncedDayKey = dayKey;
      _scheduleNextDayBoundarySync();
    } catch (e) {
      debugPrint('StreakLiveActivitySync.sync failed: $e');
    }
  }

  /// Display-only refresh when the app returns to the foreground.
  /// Re-reads existing streak prefs for the current device date; does not
  /// change streak calculation or stored values.
  static Future<void> syncOnAppForeground() async {
    if (kIsWeb || !Platform.isIOS) return;
    await sync(forceStart: false);
  }

  /// If the calendar day changed since the last mirror, push a fresh snapshot.
  /// No-op when already synced for today. Does not alter streak logic.
  static Future<void> syncIfCalendarDayChanged() async {
    if (kIsWeb || !Platform.isIOS) return;
    final today = _todayKey();
    if (_lastSyncedDayKey == today) return;
    await sync(forceStart: false);
  }

  /// Schedule one display-only sync just after the next local midnight.
  static void _scheduleNextDayBoundarySync() {
    if (kIsWeb || !Platform.isIOS) return;
    _dayBoundaryTimer?.cancel();
    final now = DateTime.now();
    final nextBoundary = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final delay = nextBoundary.difference(now);
    if (delay.isNegative) return;
    _dayBoundaryTimer = Timer(delay, () {
      // Day rolled over — refresh mirror from current prefs/date.
      unawaited(sync(forceStart: false));
    });
  }

  /// End any active streak Live Activity. Does not change streak data.
  static Future<void> end() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('end');
    } catch (e) {
      debugPrint('StreakLiveActivitySync.end failed: $e');
    }
  }

  static Future<bool> areEnabled() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>('areEnabled');
      return enabled == true;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort read of today's completed steps from existing prefs only.
  /// Public for Live Activity queue prioritization (display-only).
  static Future<int> todayStepsCompleted() => _todayStepsCompleted();

  static Future<int> _todayStepsCompleted() async {
    final today = _todayKey();
    final lastShown = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    if (lastShown == today) return _stepsTotal;

    var best = 0;
    final started = await SharPreferences.getString(
        SharPreferences.streakFlowStartedDate);
    if (started == today) {
      best = await SharPreferences.getInt(
              SharPreferences.streakFlowStepsCompletedToday) ??
          0;
    }

    final fromMap = await _stepsFromByDayMap(today);
    return math.max(best, fromMap).clamp(0, _stepsTotal);
  }

  static Future<int> _stepsFromByDayMap(String dayKey) async {
    try {
      final raw = await SharPreferences.getString(
          SharPreferences.streakFlowStepsByDay);
      if (raw == null || raw.trim().isEmpty) return 0;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 0;
      final value = decoded[dayKey];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
