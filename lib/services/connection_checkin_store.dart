import 'dart:convert';

import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';

/// 0 Very Far … 4 Very Close. Additive store — does not change streak logic.
class ConnectionCheckinStore {
  ConnectionCheckinStore._();

  static const labels = [
    'Very Far',
    'Far',
    'Growing',
    'Close',
    'Very Close',
  ];

  static const colors = [
    Color(0xFFD8E89A),
    Color(0xFFB7D96A),
    Color(0xFF7CB342),
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];

  static Future<Map<String, int>> loadAll() async {
    final raw =
        await SharPreferences.getString(SharPreferences.connectionCheckinByDay);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      decoded.forEach((key, value) {
        final day = key.toString();
        final level = (value as num?)?.toInt();
        if (day.isEmpty || level == null) return;
        out[day] = level.clamp(0, 4);
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> record({
    required String dayKey,
    required int level,
  }) async {
    final day = dayKey.trim();
    if (day.isEmpty) return;
    final map = await loadAll();
    map[day] = level.clamp(0, 4);
    await SharPreferences.setString(
      SharPreferences.connectionCheckinByDay,
      jsonEncode(map),
    );
  }

  /// Additive: copy already-saved Faith Journey slider days into Insights.
  /// Does not overwrite days already logged, and does not change streak prefs.
  static Future<Map<String, int>> hydrateFromExistingStreakItems() async {
    final map = await loadAll();
    final raw =
        await SharPreferences.getString(SharPreferences.streakFlowItemByDay);
    if (raw == null || raw.trim().isEmpty) return map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return map;
      var changed = false;
      decoded.forEach((key, value) {
        final day = key.toString();
        if (day.isEmpty || map.containsKey(day)) return;
        if (value is! Map) return;
        final slider = (value['connectionSliderValue'] as num?)?.toDouble();
        if (slider == null) return;
        map[day] = levelFromSlider(slider);
        changed = true;
      });
      if (changed) {
        await SharPreferences.setString(
          SharPreferences.connectionCheckinByDay,
          jsonEncode(map),
        );
      }
    } catch (_) {}
    return map;
  }

  static String dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? parseDay(String key) {
    try {
      return DateTime.parse(key);
    } catch (_) {
      return null;
    }
  }

  /// Slider 0–1 → 5 UI levels (same snap as Faith Journey labels).
  static int levelFromSlider(double value) {
    if (value <= 0.125) return 0;
    if (value <= 0.375) return 1;
    if (value <= 0.625) return 2;
    if (value <= 0.875) return 3;
    return 4;
  }
}
