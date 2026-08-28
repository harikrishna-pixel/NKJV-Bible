import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/constant/prayer_wall_api_constant.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        'bundle_id': BibleInfo.ios_Bundle_Id, // com.balaklrapps.newkingsjamesversion
      };

  static String _encodeBody(Map<String, dynamic> body) =>
      jsonEncode({...body, ..._appMeta});

  static String? _extractId(dynamic decoded) {
    if (decoded is! Map) return null;
    final m = Map<String, dynamic>.from(decoded);
    return m['_id']?.toString() ?? m['id']?.toString();
  }

  /// Resolve returns `user_id` — that value is passed as `identityUserId` on GET/POST.
  static String? _extractResolveUserId(dynamic decoded) {
    String? fromMap(Map<String, dynamic> map) {
      final v = map['user_id'] ?? map['userId'];
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
      final data = map['data'];
      if (data is Map) {
        final nested = Map<String, dynamic>.from(data);
        final inner = nested['user_id'] ?? nested['userId'];
        final t = inner?.toString().trim() ?? '';
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    if (decoded is Map) {
      return fromMap(Map<String, dynamic>.from(decoded));
    }
    return null;
  }

  static Future<String> _deviceUid() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return (info.id ?? '').trim();
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return (info.identifierForVendor ?? '').trim();
      }
    } catch (e) {
      print('PrayerWallService._deviceUid error: $e');
    }
    return '';
  }

  /// Additive: POST `/api/users/resolve` after login — does not change login.
  static Future<String?> resolveIdentityUser({String? email}) async {
    try {
      final deviceId = await _deviceUid();
      final firebaseId =
          (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
      final resolvedEmail = (email ?? '').trim();
      final bodyMap = <String, dynamic>{
        'app_id': BibleInfo.appID,
      };
      if (firebaseId.isNotEmpty) {
        bodyMap['firebaseId'] = firebaseId;
      }
      if (resolvedEmail.isNotEmpty) {
        bodyMap['email'] = resolvedEmail;
      }
      if (deviceId.isNotEmpty) {
        bodyMap['device_id'] = deviceId;
      }
      final bodyJson = jsonEncode(bodyMap);
      print('========== POST /api/users/resolve ==========');
      print('URL  → ${PrayerWallApiConstant.usersResolve}');
      print('body → $bodyJson');
      print('=============================================');
      final res = await http
          .post(
            Uri.parse(PrayerWallApiConstant.usersResolve),
            headers: _jsonHeaders,
            body: bodyJson,
          )
          .timeout(const Duration(seconds: 15));
      print(
        'POST /api/users/resolve response → '
        '${res.statusCode} ${res.body}',
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        final data = m['data'];
        print('resolve raw identityUserId → ${m['identityUserId']}');
        print('resolve raw user_id → ${m['user_id']}');
        if (data is Map) {
          print(
            'resolve data.identityUserId → ${data['identityUserId']} '
            'data.user_id → ${data['user_id']}',
          );
        }
      }
      final userId = _extractResolveUserId(decoded);
      print('resolve using user_id as identityUserId → ${userId ?? "none"}');
      if (userId != null && userId.isNotEmpty) {
        await PrayerWallLocalStore.saveIdentityUserId(userId);
      }
      return userId;
    } catch (e) {
      print('PrayerWallService.resolveIdentityUser error: $e');
      return null;
    }
  }

  /// Cached resolve id, or resolve now using login email + device UID.
  static Future<String?> ensureIdentityUserId() async {
    final cached = await PrayerWallLocalStore.loadIdentityUserId();
    if (cached != null && cached.isNotEmpty) return cached;
    var email = '';
    try {
      email = (await CacheNotifier().readCache(key: 'user') ?? '')
          .toString()
          .trim();
    } catch (_) {}
    return resolveIdentityUser(email: email.isEmpty ? null : email);
  }

  static Future<List<PrayerWallItem>> fetchPrayers() async {
    // Wall feed stays GET /api/prayers (full list). identityUserId query
    // filters to one user and left the screen empty.
    final url = PrayerWallApiConstant.prayers;
    print('========== GET /api/prayers ==========');
    print('URL → $url');
    print('======================================');
    final res = await http.get(
      Uri.parse(url),
      headers: _jsonHeaders,
    );
    print(
      'GET /api/prayers response → ${res.statusCode} ${res.body}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Prayers failed (${res.statusCode}): ${res.body}');
    }
    return PrayerWallItem.listFromResponseBody(res.body);
  }

  /// Additive: `GET /api/prayers?identityUserId=<resolve user_id>`.
  static Future<List<PrayerWallItem>> fetchPrayersByIdentityUserId() async {
    var email = '';
    try {
      email = (await CacheNotifier().readCache(key: 'user') ?? '')
          .toString()
          .trim();
    } catch (_) {}
    final identityUserId = await resolveIdentityUser(
          email: email.isEmpty ? null : email,
        ) ??
        await PrayerWallLocalStore.loadIdentityUserId();
    if (identityUserId == null || identityUserId.isEmpty) {
      print('GET /api/prayers skipped: resolve user_id missing');
      return [];
    }
    final url =
        PrayerWallApiConstant.prayersForIdentityUserId(identityUserId);
    print('========== GET /api/prayers?identityUserId ==========');
    print('URL → $url');
    print('identityUserId (resolve user_id) → $identityUserId');
    print('====================================================');
    final res = await http.get(
      Uri.parse(url),
      headers: _jsonHeaders,
    );
    print(
      'GET /api/prayers?identityUserId response → '
      '${res.statusCode} ${res.body}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return [];
    final list = PrayerWallItem.listFromResponseBody(res.body);
    // Identity GET may return the full wall; keep only this login email.
    if (email.isEmpty) return list;
    final want = email.toLowerCase();
    return list
        .where((p) => (p.email ?? '').trim().toLowerCase() == want)
        .toList();
  }

  /// Additive: one prayer by posted id — `GET /api/prayers?prayerId={id}`.
  /// Server may ignore the query and return the full list; we keep only exact id.
  /// Does not change [fetchPrayers] (full wall).
  static Future<PrayerWallItem?> fetchPrayerByPrayerId(String prayerId) async {
    final id = prayerId.trim();
    if (id.isEmpty) return null;
    final res = await http.get(
      Uri.parse(PrayerWallApiConstant.prayersForPrayerId(id)),
      headers: _jsonHeaders,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Prayer by id failed (${res.statusCode}): ${res.body}');
    }
    final list = PrayerWallItem.listFromResponseBody(res.body);
    for (final p in list) {
      if (p.id == id) return p;
    }
    // Some APIs return a single object instead of a list.
    try {
      final decoded = jsonDecode(res.body);
      final one = PrayerWallItem.fromDynamic(decoded);
      if (one != null && one.id == id) return one;
    } catch (_) {}
    return null;
  }

  /// Additive: load history for ids saved when the user posted.
  /// Always filters to [prayerIds] only (API `?prayerId=` may return the full wall).
  static Future<List<PrayerWallItem>> fetchPrayersByPrayerIds(
    Iterable<String> prayerIds,
  ) async {
    final ids = prayerIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return [];

    // One request (server ignores filter today); keep only requested ids.
    List<PrayerWallItem> list;
    try {
      final probeId = ids.first;
      final res = await http.get(
        Uri.parse(PrayerWallApiConstant.prayersForPrayerId(probeId)),
        headers: _jsonHeaders,
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(
            'Prayers by id failed (${res.statusCode}): ${res.body}');
      }
      list = PrayerWallItem.listFromResponseBody(res.body);
    } catch (_) {
      list = await fetchPrayers();
    }

    final out = list.where((p) => ids.contains(p.id)).toList();
    out.sort((a, b) {
      final am = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bm = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bm.compareTo(am);
    });
    return out;
  }

  static Future<Map<String, dynamic>> createPrayer({
    required String prayerTitle,
    required String prayerDescription,
    required String prayerCategory,
    bool isAnonymous = true,
    String? userName,
    String? profileImage,
    String? email,
    String? identityUserId,
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
    // Additive: pass profile photo URL when available (does not change other fields).
    final normalizedImage = profileImage?.trim();
    if (normalizedImage != null && normalizedImage.isNotEmpty) {
      bodyMap['profile_image'] = normalizedImage;
    }
    // Additive: pass login email when available.
    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      bodyMap['email'] = normalizedEmail;
    }
    // Additive: pass resolve `user_id` as identityUserId on create.
    var resolvedIdentity = (identityUserId ?? '').trim();
    if (resolvedIdentity.isEmpty) {
      resolvedIdentity = (await ensureIdentityUserId()) ?? '';
    }
    if (resolvedIdentity.isNotEmpty) {
      bodyMap['identityUserId'] = resolvedIdentity;
    }
    final bodyJson = _encodeBody(bodyMap);
    // Debug: values sent with create prayer (app identity + full body).
    print('========== POST PRAYER ==========');
    print('app_id    → ${BibleInfo.appID}');
    print('app_name  → ${BibleInfo.bible_shortName}');
    print('bundle_id → ${BibleInfo.ios_Bundle_Id}');
    print('request body → $bodyJson');
    print('================================');

    final res = await http.post(
      Uri.parse(PrayerWallApiConstant.prayers),
      headers: _jsonHeaders,
      body: bodyJson,
    );
    print('POST prayer response → ${res.statusCode} ${res.body}');
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

  static Set<String> _parseBlockedUserIds(dynamic decoded) {
    final out = <String>{};
    void addId(dynamic v) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) out.add(s);
    }

    void addFromList(dynamic list) {
      if (list is! List) return;
      for (final e in list) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          addId(m['blocked_user_id'] ?? m['blockedUserId']);
        } else {
          addId(e);
        }
      }
    }

    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      addFromList(
        m['blocked_user_ids'] ?? m['blockedUserIds'] ?? m['blocked_users'],
      );
      addFromList(m['items']);
      final data = m['data'];
      if (data is List) {
        addFromList(data);
      } else if (data is Map) {
        final dm = Map<String, dynamic>.from(data);
        addFromList(
          dm['blocked_user_ids'] ??
              dm['blockedUserIds'] ??
              dm['blocked_users'] ??
              dm['items'],
        );
      }
    } else if (decoded is List) {
      addFromList(decoded);
    }
    return out;
  }

  /// Additive: `GET /api/blocked-users?user_id=` — same ids POST stored.
  /// Does not change POST/DELETE block or unblock.
  static Future<Set<String>> fetchBlockedUserIds({
    required String userId,
  }) async {
    final uid = userId.trim();
    if (uid.isEmpty) return {};
    try {
      final url = PrayerWallApiConstant.blockedUsersForUser(uid);
      print('========== GET /api/blocked-users ==========');
      print('URL → $url');
      print('user_id → $uid');
      print('============================================');
      final res = await http
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(const Duration(seconds: 15));
      print(
        'GET /api/blocked-users response → '
        '${res.statusCode} ${res.body}',
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return {};
      if (res.body.isEmpty) return {};
      return _parseBlockedUserIds(jsonDecode(res.body));
    } catch (e) {
      print('PrayerWallService.fetchBlockedUserIds error: $e');
      return {};
    }
  }

  /// Additive: restore blocked ids via resolve `user_id` only.
  static Future<Set<String>> fetchBlockedUserIdsForAccount({
    required String email,
    List<PrayerWallItem> wallPrayers = const [],
    Iterable<String> extraActorIds = const [],
  }) async {
    final identity = await ensureIdentityUserId();
    if (identity == null || identity.isEmpty) return {};
    return fetchBlockedUserIds(userId: identity);
  }

  /// POST `/api/blocked-users` — block a prayer poster for this user.
  static Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    final uid = userId.trim();
    final blocked = blockedUserId.trim();
    if (uid.isEmpty || blocked.isEmpty) {
      throw Exception('blockUser: user_id and blocked_user_id required');
    }
    final body = jsonEncode({
      'user_id': uid,
      'blocked_user_id': blocked,
    });
    print('PrayerWallService.blockUser body: $body');
    final res = await http.post(
      Uri.parse(PrayerWallApiConstant.blockedUsers),
      headers: _jsonHeaders,
      body: body,
    );
    print(
      'PrayerWallService.blockUser response: '
      'status=${res.statusCode} body=${res.body}',
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Block user failed (${res.statusCode}): ${res.body}');
  }

  /// DELETE `/api/blocked-users` — unblock a user for this account.
  static Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    final uid = userId.trim();
    final blocked = blockedUserId.trim();
    if (uid.isEmpty || blocked.isEmpty) {
      throw Exception('unblockUser: user_id and blocked_user_id required');
    }
    final body = jsonEncode({
      'user_id': uid,
      'blocked_user_id': blocked,
    });
    print('PrayerWallService.unblockUser body: $body');
    final res = await http.delete(
      Uri.parse(PrayerWallApiConstant.blockedUsers),
      headers: _jsonHeaders,
      body: body,
    );
    print(
      'PrayerWallService.unblockUser response: '
      'status=${res.statusCode} body=${res.body}',
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Unblock user failed (${res.statusCode}): ${res.body}');
  }

  /// Same Gemini endpoint used by Chat / Prayer Guidance.
  static const String _aiBaseUrl =
      'https://combine-api-ruby.vercel.app/api/chat';

  static const String _toastVulgar =
      'Please keep your prayer respectful. Inappropriate language is not allowed.';
  static const String _toastNotPrayer =
      'Please share a genuine prayer request only.';

  /// AI validation before publish. Returns [isValid]=true when content may post.
  /// On AI/network failure returns valid=true so existing publish path still works.
  static Future<PrayerWallValidationResult> validatePrayerContent({
    required String prayerTitle,
    required String prayerDescription,
  }) async {
    final prompt = '''
You are a content moderator for a Christian Prayer Wall in a Bible app (${BibleInfo.bible_shortName}).
Decide if the user's submission may be published.

Reject as INVALID if ANY of these apply:
1) Vulgar / profane / abusive / sexual / hateful / highly offensive language.
2) Not a genuine prayer or prayer request (spam, ads, jokes, random chat, news, opinions, questions that are not prayerful).
3) Anything beyond prayer — content that is not asking for prayer, giving thanks to God, seeking spiritual support, or sharing a blessing.

Accept as VALID if it is a sincere prayer, prayer request, thanksgiving, or blessing — even if informal, short, or imperfect English.

Respond with EXACTLY one line (no markdown, no extra explanation):
VALID
or
INVALID|vulgar|$_toastVulgar
or
INVALID|not_prayer|$_toastNotPrayer

Title: $prayerTitle
Details: $prayerDescription
''';

    try {
      final res = await http.post(
        Uri.parse(_aiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input': prompt}),
      );
      if (res.statusCode != 200) {
        return const PrayerWallValidationResult(isValid: true);
      }

      final text = _extractAiText(res.body).trim();
      if (text.isEmpty) {
        return const PrayerWallValidationResult(isValid: true);
      }

      final upper = text.toUpperCase();
      if (upper.startsWith('VALID') && !upper.startsWith('INVALID')) {
        return const PrayerWallValidationResult(isValid: true);
      }

      if (upper.contains('INVALID')) {
        final toast = _toastFromInvalidAiLine(text);
        return PrayerWallValidationResult(isValid: false, toastMessage: toast);
      }

      // Unclear AI reply — allow existing publish path.
      return const PrayerWallValidationResult(isValid: true);
    } catch (_) {
      return const PrayerWallValidationResult(isValid: true);
    }
  }

  static String _toastFromInvalidAiLine(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('vulgar') ||
        lower.contains('profan') ||
        lower.contains('inappropriate') ||
        lower.contains('offensive')) {
      return _toastVulgar;
    }
    if (lower.contains('not_prayer') ||
        lower.contains('not a prayer') ||
        lower.contains('beyond')) {
      return _toastNotPrayer;
    }
    // Prefer AI-provided toast after second pipe, if present.
    final parts = text.split('|');
    if (parts.length >= 3) {
      final custom = parts.sublist(2).join('|').trim();
      if (custom.isNotEmpty && custom.length < 160) return custom;
    }
    return _toastNotPrayer;
  }

  static String _extractAiText(String body) {
    try {
      final responseData = jsonDecode(body);
      if (responseData is! Map) return body;
      if (responseData['output'] != null) {
        if (responseData['output'] is String) {
          return responseData['output'].toString();
        }
        if (responseData['output'] is Map) {
          final output = responseData['output'] as Map;
          if (output['candidates'] is List &&
              (output['candidates'] as List).isNotEmpty) {
            final candidate = (output['candidates'] as List)[0];
            if (candidate is Map &&
                candidate['content'] is Map &&
                candidate['content']['parts'] is List &&
                (candidate['content']['parts'] as List).isNotEmpty) {
              final part = (candidate['content']['parts'] as List)[0];
              if (part is Map && part['text'] != null) {
                return part['text'].toString();
              }
            }
          }
        }
      }
      if (responseData['response'] != null) {
        return responseData['response'].toString();
      }
      if (responseData['text'] != null) {
        return responseData['text'].toString();
      }
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
    } catch (_) {}
    return body;
  }
}

/// Result of Prayer Wall AI content validation.
class PrayerWallValidationResult {
  const PrayerWallValidationResult({
    required this.isValid,
    this.toastMessage,
  });

  final bool isValid;
  final String? toastMessage;
}
