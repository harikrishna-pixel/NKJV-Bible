import 'dart:convert';

import 'package:biblebookapp/constant/prayer_wall_api_constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP layer for Prayer Wall — keeps UI free of URL strings.
class PrayerWallService {
  PrayerWallService._();

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'marberx@123tech',
      };

  /// App identity fields for all Prayer Wall write payloads.
  static Map<String, dynamic> get _appMeta => {
        'app_id': BibleInfo.appID,
        'app_name': BibleInfo.bible_shortName,
      };

  static String _encodeBody(Map<String, dynamic> body) =>
      jsonEncode({...body, ..._appMeta});

  static String? _extractId(dynamic decoded) {
    if (decoded is! Map) return null;
    final m = Map<String, dynamic>.from(decoded);
    return m['_id']?.toString() ?? m['id']?.toString();
  }

  static Future<List<PrayerWallItem>> fetchPrayers() async {
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.prayers),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Prayers failed (${res.statusCode}): ${res.body}');
    }
    return PrayerWallItem.listFromResponseBody(res.body);
  }

  static Future<Map<String, dynamic>> createPrayer({
    required String prayerTitle,
    required String prayerDescription,
    required String prayerCategory,
    bool isAnonymous = true,
    String? userName,
    int prayerDuration = 7,
  }) async {
    final bodyMap = <String, dynamic>{
      'prayer_title': prayerTitle,
      'prayer_description': prayerDescription,
      'prayer_category': prayerCategory,
      'isAnonymous': isAnonymous,
      'prayer_duration': prayerDuration,
    };

    // Always send logged-in user's display name (when available),
    // alongside the user's selected `isAnonymous` flag.
    final normalizedUserName = userName?.trim();
    if (normalizedUserName != null && normalizedUserName.isNotEmpty) {
      bodyMap['user_name'] = normalizedUserName;
    }
    final bodyJson = _encodeBody(bodyMap);
    print('PrayerWallService.createPrayer request body: $bodyJson');

    final res = await http.post(
      Uri.parse(PrayerWallApiConstant.prayers),
      headers: _jsonHeaders,
      body: bodyJson,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Create prayer failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  static Future<void> updatePrayer({
    required String prayerId,
    required String prayerTitle,
    required String prayerDescription,
  }) async {
    final body = _encodeBody({
      // Support multiple backend shapes without changing UI logic.
      'prayerId': prayerId,
      '_id': prayerId,
      'id': prayerId,
      'prayer_title': prayerTitle,
      'prayer_description': prayerDescription,
    });

    final res = await http.patch(
      Uri.parse(PrayerWallApiConstant.prayers),
      headers: _jsonHeaders,
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 404) {
      final res2 = await http.patch(
        Uri.parse('${PrayerWallApiConstant.prayers}/$prayerId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res2.statusCode >= 200 && res2.statusCode < 300) return;

      final res3 = await http.put(
        Uri.parse('${PrayerWallApiConstant.prayers}/$prayerId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res3.statusCode >= 200 && res3.statusCode < 300) return;

      throw Exception(
          'Update prayer failed (${res3.statusCode}): ${res3.body}');
    }

    throw Exception('Update prayer failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> deletePrayer(String prayerId) async {
    final body = _encodeBody({
      // Support multiple backend shapes without changing UI logic.
      'prayerId': prayerId,
      '_id': prayerId,
      'id': prayerId,
    });

    final res = await http.delete(
      Uri.parse(PrayerWallApiConstant.prayers),
      headers: _jsonHeaders,
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 404) {
      final res2 = await http.delete(
        Uri.parse('${PrayerWallApiConstant.prayers}/$prayerId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res2.statusCode >= 200 && res2.statusCode < 300) return;
      throw Exception(
          'Delete prayer failed (${res2.statusCode}): ${res2.body}');
    }

    throw Exception('Delete prayer failed (${res.statusCode}): ${res.body}');
  }

  /// Returns like count per prayerId from either full list or filtered payload.
  static Future<Map<String, int>> fetchLikeCountsByPrayer() async {
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.likes),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {};
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['likes'] is List) {
      return _countByPrayerId(decoded['likes'] as List);
    }
    if (decoded is List) {
      return _countByPrayerId(decoded);
    }
    return {};
  }

  static Map<String, int> _countByPrayerId(List list) {
    final map = <String, int>{};
    for (final e in list) {
      if (e is! Map) continue;
      final pid = e['prayerId']?.toString() ?? e['prayer_id']?.toString();
      if (pid == null || pid.isEmpty) continue;
      map[pid] = (map[pid] ?? 0) + 1;
    }
    return map;
  }

  static List<Map<String, dynamic>> _parseLikeList(dynamic decoded) {
    if (decoded is Map && decoded['likes'] is List) {
      return (decoded['likes'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Latest like document `_id` for this prayer (best-effort for unlike).
  static Future<String?> fetchLatestLikeIdForPrayer(String prayerId) async {
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.likesForPrayer(prayerId)),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    try {
      final list = _parseLikeList(jsonDecode(res.body));
      if (list.isEmpty) return null;
      // Prefer last entry (often newest first from API — still heuristic).
      for (var i = list.length - 1; i >= 0; i--) {
        final id = list[i]['_id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}
    return null;
  }

  /// POST like. Returns like document `_id` when available (201 or parsed body).
  /// On 200 "Already liked", tries GET likes for this prayer to obtain an id.
  static Future<String?> postLike(String prayerId) async {
    final res = await http.post(
      Uri.parse(PrayerWallApiConstant.likes),
      headers: _jsonHeaders,
      body: _encodeBody({'prayerId': prayerId}),
    );
    if (res.statusCode == 201) {
      try {
        if (res.body.isEmpty) return null;
        final decoded = jsonDecode(res.body);
        return _extractId(decoded);
      } catch (_) {
        return null;
      }
    }
    if (res.statusCode == 200) {
      try {
        if (res.body.isNotEmpty) {
          final decoded = jsonDecode(res.body);
          final fromBody = _extractId(decoded);
          if (fromBody != null) return fromBody;
        }
      } catch (_) {}
      return fetchLatestLikeIdForPrayer(prayerId);
    }
    throw Exception('Like failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteLike({
    String? likeId,
    String? prayerId,
  }) async {
    if ((likeId == null || likeId.isEmpty) &&
        (prayerId == null || prayerId.isEmpty)) {
      throw Exception('deleteLike: need likeId or prayerId');
    }
    final body = <String, dynamic>{};
    if (likeId != null && likeId.isNotEmpty) {
      body['likeId'] = likeId;
    } else {
      body['prayerId'] = prayerId;
    }
    final res = await http.delete(
      Uri.parse(PrayerWallApiConstant.likes),
      headers: _jsonHeaders,
      body: _encodeBody(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Unlike failed (${res.statusCode}): ${res.body}');
  }

  static Future<Map<String, int>> fetchCommentCountsByPrayer() async {
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.comments),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {};
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return {};
    final map = <String, int>{};
    for (final e in decoded) {
      if (e is! Map) continue;
      final pid = e['prayerId']?.toString() ?? e['prayer_id']?.toString();
      if (pid == null || pid.isEmpty) continue;
      map[pid] = (map[pid] ?? 0) + 1;
    }
    return map;
  }

  static Future<List<Map<String, dynamic>>> fetchCommentsForPrayer(
      String prayerId) async {
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.commentsForPrayer(prayerId)),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Comments failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<String> postComment({
    required String prayerId,
    required String commentText,
    bool isAnonymous = true,
  }) async {
    final res = await http.post(
      Uri.parse(PrayerWallApiConstant.comments),
      headers: _jsonHeaders,
      body: _encodeBody({
        'prayerId': prayerId,
        'comment_text': commentText,
        'isAnonymous': isAnonymous,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Post comment failed (${res.statusCode}): ${res.body}');
    }
    try {
      final decoded = jsonDecode(res.body);
      final id = _extractId(decoded);
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    throw Exception('Post comment: missing _id in response');
  }

  /// PATCH `/api/comments` — `commentId` + `comment_text` (matches prayer PATCH style).
  static Future<void> updateComment({
    required String commentId,
    required String commentText,
  }) async {
    final body = _encodeBody({
      // Support multiple backend shapes without changing UI logic.
      'commentId': commentId,
      '_id': commentId,
      'id': commentId,
      'comment_text': commentText,
      'commentText': commentText,
      'text': commentText,
    });

    final res = await http.patch(
      Uri.parse(PrayerWallApiConstant.comments),
      headers: _jsonHeaders,
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 404) {
      final res2 = await http.patch(
        Uri.parse('${PrayerWallApiConstant.comments}/$commentId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res2.statusCode >= 200 && res2.statusCode < 300) return;

      final res3 = await http.put(
        Uri.parse('${PrayerWallApiConstant.comments}/$commentId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res3.statusCode >= 200 && res3.statusCode < 300) return;

      throw Exception(
          'Update comment failed (${res3.statusCode}): ${res3.body}');
    }

    throw Exception('Update comment failed (${res.statusCode}): ${res.body}');
  }

  static Future<void> deleteComment(String commentId) async {
    final body = _encodeBody({
      // Support multiple backend shapes without changing UI logic.
      'commentId': commentId,
      '_id': commentId,
      'id': commentId,
    });

    final res = await http.delete(
      Uri.parse(PrayerWallApiConstant.comments),
      headers: _jsonHeaders,
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    if (res.statusCode == 404) {
      final res2 = await http.delete(
        Uri.parse('${PrayerWallApiConstant.comments}/$commentId'),
        headers: _jsonHeaders,
        body: body,
      );
      if (res2.statusCode >= 200 && res2.statusCode < 300) return;
      throw Exception(
          'Delete comment failed (${res2.statusCode}): ${res2.body}');
    }

    throw Exception('Delete comment failed (${res.statusCode}): ${res.body}');
  }

  /// POST `/api/prayer-reports`
  static Future<void> reportPrayer({
    required String prayerId,
    required String reporterId,
    required String reportReason,
  }) async {
    final url = PrayerWallApiConstant.prayerReports;
    final payload = {
      'prayerId': prayerId,
      'reporter_id': PrayerWallLocalStore.normalizeReporterId(reporterId),
      'report_reason': reportReason,
    };
    final body = _encodeBody(payload);
    print('PrayerWallService.reportPrayer URL: $url');
    print('PrayerWallService.reportPrayer headers: $_jsonHeaders');
    print('PrayerWallService.reportPrayer request body: $body');
    final res = await http.post(
      Uri.parse(url),
      headers: _jsonHeaders,
      body: body,
    );
    print(
      'PrayerWallService.reportPrayer response: '
      'status=${res.statusCode} body=${res.body}',
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Report prayer failed (${res.statusCode}): ${res.body}');
  }
}
