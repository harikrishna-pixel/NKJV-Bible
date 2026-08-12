import 'dart:convert';

import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Additive Prayer Wall activity poller.
///
/// Calls existing GET APIs, compares to a local snapshot, and shows local
/// notifications for new prayers / likes / comments. Does not alter Prayer Wall
/// like / comment / post business logic.
class PrayerWallActivityNotifier {
  PrayerWallActivityNotifier._();

  static const _kBaselineReady = 'prayer_wall_notif_baseline_ready_v1';
  static const _kPrayerIds = 'prayer_wall_notif_prayer_ids_v1';
  static const _kLikeCounts = 'prayer_wall_notif_like_counts_v1';
  static const _kCommentCounts = 'prayer_wall_notif_comment_counts_v1';
  static const _kLastCheckMs = 'prayer_wall_notif_last_check_ms_v1';

  static const String openPrayerWallPayload = 'open_prayer_wall';

  /// Notification ids outside daily (1–3) / smart (0) ranges.
  static const int _idNewPrayer = 9101;
  static const int _idLike = 9102;
  static const int _idComment = 9103;

  static const Duration _minInterval = Duration(seconds: 40);
  static const Duration _minIntervalBackground = Duration(minutes: 12);

  static bool _running = false;

  /// Poll GETs and show banners when activity increases.
  /// Safe to call from resume / home open / background; debounced and non-throwing.
  static Future<void> checkAndNotify({bool fromBackground = false}) async {
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastCheckMs) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final minGap = fromBackground
          ? _minIntervalBackground.inMilliseconds
          : _minInterval.inMilliseconds;
      if (lastMs > 0 && nowMs - lastMs < minGap) {
        return;
      }
      await prefs.setInt(_kLastCheckMs, nowMs);

      final results = await Future.wait([
        PrayerWallService.fetchPrayers(),
        PrayerWallService.fetchLikeCountsByPrayer(),
        PrayerWallService.fetchCommentCountsByPrayer(),
        PrayerWallLocalStore.loadMyPrayerIds(),
      ]);

      final prayers = results[0] as List<PrayerWallItem>;
      final likeCounts = Map<String, int>.from(results[1] as Map);
      final commentCounts = Map<String, int>.from(results[2] as Map);
      final myPrayerIds = Set<String>.from(results[3] as Set<String>);

      final currentPrayerIds = <String>{
        for (final p in prayers)
          if (p.id.trim().isNotEmpty) p.id.trim(),
      };

      final baselineReady = prefs.getBool(_kBaselineReady) ?? false;
      final prevPrayerIds = await _loadStringSet(prefs, _kPrayerIds);
      final prevLikes = await _loadCountMap(prefs, _kLikeCounts);
      final prevComments = await _loadCountMap(prefs, _kCommentCounts);

      if (!baselineReady) {
        await _saveSnapshot(
          prefs,
          prayerIds: currentPrayerIds,
          likeCounts: _countsForMyPrayers(likeCounts, myPrayerIds),
          commentCounts: _countsForMyPrayers(commentCounts, myPrayerIds),
        );
        await prefs.setBool(_kBaselineReady, true);
        debugPrint('PrayerWallActivityNotifier: baseline saved (no notify)');
        return;
      }

      // --- New prayers on the wall (not posted by this device) ---
      final newPrayerIds = currentPrayerIds
          .difference(prevPrayerIds)
          .difference(myPrayerIds);
      final hasNewPrayer = newPrayerIds.isNotEmpty;

      // --- Likes / comments on MY prayers only ---
      var hasNewLike = false;
      var hasNewComment = false;
      for (final pid in myPrayerIds) {
        final likeNow = likeCounts[pid] ?? 0;
        final likePrev = prevLikes[pid] ?? 0;
        if (likeNow > likePrev) hasNewLike = true;

        final commentNow = commentCounts[pid] ?? 0;
        final commentPrev = prevComments[pid] ?? 0;
        if (commentNow > commentPrev) hasNewComment = true;
      }

      final svc = NotificationsServices();
      if (hasNewComment) {
        await svc.showImmediateNotification(
          id: _idComment,
          title: '💬 New comment on your prayer',
          body:
              'Someone commented on your prayer. Tap to view and see all updates.',
          payload: openPrayerWallPayload,
        );
      }
      if (hasNewLike) {
        await svc.showImmediateNotification(
          id: _idLike,
          title: '🔔 Activity on your prayer',
          body:
              'Someone liked your prayer. Tap to view and see all updates.',
          payload: openPrayerWallPayload,
        );
      }
      if (hasNewPrayer) {
        await svc.showImmediateNotification(
          id: _idNewPrayer,
          title: '🙏 New prayer on the Prayer Wall',
          body:
              'Someone posted a new prayer. Tap to view and see all updates.',
          payload: openPrayerWallPayload,
        );
      }

      await _saveSnapshot(
        prefs,
        prayerIds: currentPrayerIds,
        likeCounts: _countsForMyPrayers(likeCounts, myPrayerIds),
        commentCounts: _countsForMyPrayers(commentCounts, myPrayerIds),
      );
    } catch (e) {
      debugPrint('PrayerWallActivityNotifier.checkAndNotify error: $e');
    } finally {
      _running = false;
    }
  }

  static Map<String, int> _countsForMyPrayers(
    Map<String, int> all,
    Set<String> myPrayerIds,
  ) {
    final out = <String, int>{};
    for (final pid in myPrayerIds) {
      out[pid] = all[pid] ?? 0;
    }
    return out;
  }

  static Future<void> _saveSnapshot(
    SharedPreferences prefs, {
    required Set<String> prayerIds,
    required Map<String, int> likeCounts,
    required Map<String, int> commentCounts,
  }) async {
    await prefs.setString(_kPrayerIds, jsonEncode(prayerIds.toList()));
    await prefs.setString(_kLikeCounts, jsonEncode(likeCounts));
    await prefs.setString(_kCommentCounts, jsonEncode(commentCounts));
  }

  static Future<Set<String>> _loadStringSet(
    SharedPreferences prefs,
    String key,
  ) async {
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, int>> _loadCountMap(
    SharedPreferences prefs,
    String key,
  ) async {
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0),
      );
    } catch (_) {
      return {};
    }
  }
}
