import 'dart:convert';
import 'package:biblebookapp/view/constants/share_preferences.dart';

/// One saved item from Streak Flow (verse, devotional, or prayer).
class StreakSavedItem {
  StreakSavedItem({
    required this.type,
    required this.title,
    required this.body,
    required this.savedAt,
  });

  final String type; // 'verse' | 'devotional' | 'prayer'
  final String title;
  final String body;
  final String savedAt; // ISO date or datetime string

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'body': body,
        'savedAt': savedAt,
      };

  static StreakSavedItem fromJson(Map<String, dynamic> json) {
    return StreakSavedItem(
      type: json['type'] as String? ?? 'verse',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      savedAt: json['savedAt'] as String? ?? '',
    );
  }
}

/// Single place to store and read saved verses, devotionals, and prayers from Streak Flow.
class StreakSavedStorage {
  static Future<List<StreakSavedItem>> getAll() async {
    final raw = await SharPreferences.getString(SharPreferences.streakSavedItems);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => StreakSavedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<StreakSavedItem> items) async {
    final list = items.map((e) => e.toJson()).toList();
    await SharPreferences.setString(
        SharPreferences.streakSavedItems, jsonEncode(list));
  }

  static Future<void> add(StreakSavedItem item) async {
    final list = await getAll();
    list.add(item);
    await _saveAll(list);
  }

  /// Remove one item that matches type, title, and body (first match only).
  static Future<void> remove(String type, String title, String body) async {
    final list = await getAll();
    final idx = list.indexWhere((e) =>
        e.type == type && e.title == title && e.body == body);
    if (idx >= 0) {
      list.removeAt(idx);
      await _saveAll(list);
    }
  }

  /// Whether an item with this type+title+body is already saved.
  static Future<bool> contains(String type, String title, String body) async {
    final list = await getAll();
    return list.any((e) =>
        e.type == type && e.title == title && e.body == body);
  }

  /// Remove by index (for list screen delete).
  static Future<void> removeAt(int index) async {
    final list = await getAll();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _saveAll(list);
  }
}
