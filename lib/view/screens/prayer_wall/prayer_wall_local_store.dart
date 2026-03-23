import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists prayer↔like document ids and comment ids created on this device
/// so unlike / edit / delete can call the API correctly after restarts.
class PrayerWallLocalStore {
  PrayerWallLocalStore._();

  static const _kLikeMap = 'prayer_wall_like_map_v1';
  static const _kMyCommentIds = 'prayer_wall_my_comment_ids_v1';

  static Future<Map<String, String>> loadLikeMap() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kLikeMap);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveLikeMap(Map<String, String> map) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLikeMap, jsonEncode(map));
  }

  static Future<Set<String>> loadMyCommentIds() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kMyCommentIds);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveMyCommentIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMyCommentIds, jsonEncode(ids.toList()));
  }

  static Future<void> addMyCommentId(String id) async {
    final s = await loadMyCommentIds();
    s.add(id);
    await saveMyCommentIds(s);
  }

  static Future<void> removeMyCommentId(String id) async {
    final s = await loadMyCommentIds();
    s.remove(id);
    await saveMyCommentIds(s);
  }
}
