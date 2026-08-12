import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists prayer↔like document ids and comment ids created on this device
/// so unlike / edit / delete can call the API correctly after restarts.
class PrayerWallLocalStore {
  PrayerWallLocalStore._();

  static const _kLikeMap = 'prayer_wall_like_map_v1';
  static const _kMyCommentIds = 'prayer_wall_my_comment_ids_v1';
  static const _kPrayerAuthorMap = 'prayer_wall_prayer_author_map_v1';
  static const _kLastDisplayName = 'prayer_wall_last_display_name_v1';
  static const _kMyPrayerIds = 'prayer_wall_my_prayer_ids_v1';
  static const _kSeenPrayerIds = 'prayer_wall_seen_prayer_ids_v1';
  static const _kPrayerDurationMeta = 'prayer_wall_duration_meta_v1';
  static const _kStatusSubmittedIds = 'prayer_wall_status_submitted_ids_v1';
  static const _kReporterId = 'prayer_wall_reporter_id_v1';

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

  /// Local fallback for prayer cards when API row has no author name.
  /// Maps prayer ObjectId -> author display name.
  static Future<Map<String, String>> loadPrayerAuthorMap() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kPrayerAuthorMap);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> savePrayerAuthorMap(Map<String, String> map) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrayerAuthorMap, jsonEncode(map));
  }

  static Future<void> putPrayerAuthor({
    required String prayerId,
    required String authorName,
  }) async {
    final pid = prayerId.trim();
    final name = authorName.trim();
    if (pid.isEmpty || name.isEmpty) return;
    final m = await loadPrayerAuthorMap();
    m[pid] = name;
    await savePrayerAuthorMap(m);
  }

  static Future<void> removePrayerAuthor({required String prayerId}) async {
    final pid = prayerId.trim();
    if (pid.isEmpty) return;
    final m = await loadPrayerAuthorMap();
    m.remove(pid);
    await savePrayerAuthorMap(m);
  }

  /// Last name used when posting (or prefilled from login). For display / prefill only.
  static Future<String?> loadLastDisplayName() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kLastDisplayName);
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static Future<void> saveLastDisplayName(String name) async {
    final t = name.trim();
    if (t.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastDisplayName, t);
  }

  /// Tracks prayer ids created by this device so user can edit/delete even when
  /// the API author fields are anonymous/blank.
  static Future<Set<String>> loadMyPrayerIds() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kMyPrayerIds);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveMyPrayerIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMyPrayerIds, jsonEncode(ids.toList()));
  }

  static Future<void> addMyPrayerId(String prayerId) async {
    final pid = prayerId.trim();
    if (pid.isEmpty) return;
    final s = await loadMyPrayerIds();
    s.add(pid);
    await saveMyPrayerIds(s);
  }

  static Future<void> removeMyPrayerId(String prayerId) async {
    final pid = prayerId.trim();
    if (pid.isEmpty) return;
    final s = await loadMyPrayerIds();
    s.remove(pid);
    await saveMyPrayerIds(s);
  }

  /// Prayer ids the user has already opened on the Prayer Wall (badge = unseen only).
  static Future<Set<String>> loadSeenPrayerIds() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSeenPrayerIds);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveSeenPrayerIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSeenPrayerIds, jsonEncode(ids.toList()));
  }

  static Future<void> markPrayersAsSeen(Iterable<String> prayerIds) async {
    final seen = await loadSeenPrayerIds();
    var changed = false;
    for (final raw in prayerIds) {
      final pid = raw.trim();
      if (pid.isEmpty) continue;
      if (seen.add(pid)) changed = true;
    }
    if (changed) await saveSeenPrayerIds(seen);
  }

  /// Maps prayerId → { durationDays, postedAtMs } for exact expiry prompts.
  static Future<Map<String, PrayerWallDurationMeta>>
      loadPrayerDurationMeta() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kPrayerDurationMeta);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return {};
      final out = <String, PrayerWallDurationMeta>{};
      decoded.forEach((k, v) {
        if (v is! Map) return;
        final meta = PrayerWallDurationMeta.fromMap(
          Map<String, dynamic>.from(v),
        );
        if (meta != null) out[k.toString()] = meta;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> savePrayerDurationMeta(
    Map<String, PrayerWallDurationMeta> map,
  ) async {
    final p = await SharedPreferences.getInstance();
    final encoded = map.map((k, v) => MapEntry(k, v.toMap()));
    await p.setString(_kPrayerDurationMeta, jsonEncode(encoded));
  }

  static Future<void> putPrayerDurationMeta({
    required String prayerId,
    required int durationDays,
    required DateTime postedAt,
  }) async {
    final pid = prayerId.trim();
    if (pid.isEmpty || durationDays <= 0) return;
    final m = await loadPrayerDurationMeta();
    m[pid] = PrayerWallDurationMeta(
      durationDays: durationDays,
      postedAt: postedAt,
    );
    await savePrayerDurationMeta(m);
  }

  static Future<Set<String>> loadStatusSubmittedIds() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kStatusSubmittedIds);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveStatusSubmittedIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStatusSubmittedIds, jsonEncode(ids.toList()));
  }

  static Future<void> markStatusSubmitted(String prayerId) async {
    final pid = prayerId.trim();
    if (pid.isEmpty) return;
    final s = await loadStatusSubmittedIds();
    s.add(pid);
    await saveStatusSubmittedIds(s);
  }

  /// Stable anonymous reporter id for `/api/prayer-reports` (max 128 chars).
  static const int reporterIdMaxLength = 128;

  static String normalizeReporterId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.length <= reporterIdMaxLength) return t;
    return t.substring(0, reporterIdMaxLength);
  }

  static Future<String> getOrCreateReporterId() async {
    final p = await SharedPreferences.getInstance();
    final existing = normalizeReporterId(p.getString(_kReporterId) ?? '');
    if (existing.isNotEmpty) {
      // Keep a clipped id if an older oversized value was stored.
      if (existing != (p.getString(_kReporterId) ?? '').trim()) {
        await p.setString(_kReporterId, existing);
      }
      return existing;
    }
    final id = normalizeReporterId(
      'device-${DateTime.now().millisecondsSinceEpoch}',
    );
    await p.setString(_kReporterId, id);
    return id;
  }
}

class PrayerWallDurationMeta {
  PrayerWallDurationMeta({
    required this.durationDays,
    required this.postedAt,
  });

  final int durationDays;
  final DateTime postedAt;

  DateTime get expiresAt => postedAt.add(Duration(days: durationDays));

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toMap() => {
        'durationDays': durationDays,
        'postedAtMs': postedAt.millisecondsSinceEpoch,
      };

  static PrayerWallDurationMeta? fromMap(Map<String, dynamic> map) {
    final days = map['durationDays'];
    final ms = map['postedAtMs'];
    final durationDays = days is int
        ? days
        : int.tryParse(days?.toString() ?? '');
    final postedAtMs = ms is int ? ms : int.tryParse(ms?.toString() ?? '');
    if (durationDays == null || durationDays <= 0 || postedAtMs == null) {
      return null;
    }
    return PrayerWallDurationMeta(
      durationDays: durationDays,
      postedAt: DateTime.fromMillisecondsSinceEpoch(postedAtMs),
    );
  }
}
