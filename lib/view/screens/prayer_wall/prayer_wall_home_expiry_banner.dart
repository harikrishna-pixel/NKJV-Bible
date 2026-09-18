import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _HomePrayerBannerKind { endsToday, hasEnded }

class _HomePrayerBannerState {
  const _HomePrayerBannerState({
    required this.kind,
    required this.prayerId,
    required this.expiresAt,
  });

  final _HomePrayerBannerKind kind;
  final String prayerId;
  final DateTime expiresAt;
}

/// Home reader banner for prayer expiry — additive UI only.
/// Uses GET `/api/prayers` + local my-prayer ids / duration meta.
class PrayerWallHomeExpiryBanner extends StatefulWidget {
  const PrayerWallHomeExpiryBanner({super.key});

  @override
  State<PrayerWallHomeExpiryBanner> createState() =>
      _PrayerWallHomeExpiryBannerState();
}

class _PrayerWallHomeExpiryBannerState
    extends State<PrayerWallHomeExpiryBanner> with WidgetsBindingObserver {
  _HomePrayerBannerState? _banner;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  static bool _sameLocalDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static String _ymd(DateTime d) {
    final l = d.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '${l.year}-$m-$day';
  }

  DateTime? _resolveExpiresAt(
    PrayerWallItem item,
    Map<String, PrayerWallDurationMeta> metaMap,
  ) {
    if (item.expiresAt != null) return item.expiresAt;
    final meta = metaMap[item.id];
    if (meta != null) return meta.expiresAt;
    final created = item.createdAt;
    final days = item.prayerDuration;
    if (created != null && days != null && days > 0) {
      return created.add(Duration(days: days));
    }
    return null;
  }

  Future<void> _refresh() async {
    if (!mounted || _busy) return;
    try {
      final myIds = await PrayerWallLocalStore.loadMyPrayerIds();
      final metaMap = await PrayerWallLocalStore.loadPrayerDurationMeta();
      final submitted = await PrayerWallLocalStore.loadStatusSubmittedIds();
      final dismissed = await PrayerWallLocalStore.loadHomeBannerDismissKeys();
      final prayers = await PrayerWallService.fetchPrayers();
      if (!mounted) return;

      final now = DateTime.now();
      _HomePrayerBannerState? ended;
      _HomePrayerBannerState? endsToday;

      for (final p in prayers) {
        if (!myIds.contains(p.id)) continue;
        final expires = _resolveExpiresAt(p, metaMap);
        if (expires == null) continue;

        // Prefer API expiry into local meta for later Prayer Wall prompts.
        final days = p.prayerDuration ?? metaMap[p.id]?.durationDays;
        final posted = p.createdAt ?? metaMap[p.id]?.postedAt;
        if (days != null && days > 0 && posted != null) {
          await PrayerWallLocalStore.putPrayerDurationMeta(
            prayerId: p.id,
            durationDays: days,
            postedAt: posted,
          );
        }

        final expired = !now.isBefore(expires.toLocal());
        if (expired) {
          if (submitted.contains(p.id)) continue;
          final dismissKey = 'has_ended:${p.id}';
          if (dismissed.contains(dismissKey)) continue;
          if (ended == null || expires.isBefore(ended.expiresAt)) {
            ended = _HomePrayerBannerState(
              kind: _HomePrayerBannerKind.hasEnded,
              prayerId: p.id,
              expiresAt: expires,
            );
          }
          continue;
        }

        if (_sameLocalDay(expires, now)) {
          final dismissKey = 'ends_today:${p.id}:${_ymd(now)}';
          if (dismissed.contains(dismissKey)) continue;
          if (endsToday == null || expires.isBefore(endsToday.expiresAt)) {
            endsToday = _HomePrayerBannerState(
              kind: _HomePrayerBannerKind.endsToday,
              prayerId: p.id,
              expiresAt: expires,
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _banner = ended ?? endsToday);
    } catch (_) {
      // Keep home reading unaffected if Prayer Wall API is unavailable.
    }
  }

  Future<void> _dismiss() async {
    final b = _banner;
    if (b == null) return;
    final key = b.kind == _HomePrayerBannerKind.hasEnded
        ? 'has_ended:${b.prayerId}'
        : 'ends_today:${b.prayerId}:${_ymd(DateTime.now())}';
    await PrayerWallLocalStore.markHomeBannerDismissed(key);
    if (!mounted) return;
    setState(() => _banner = null);
  }

  Future<void> _onEndsTodayTap() async {
    await Get.to(() => const PrayerWallScreen());
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _onUpdateStatus() async {
    final b = _banner;
    if (b == null || _busy) return;
    setState(() => _busy = true);
    try {
      final status = await PrayerWallStatusDialog.show(context);
      if (!mounted) return;
      if (status == null) return;
      await PrayerWallLocalStore.markStatusSubmitted(b.prayerId);
      await PrayerWallLocalStore.markHomeBannerDismissed(
        'has_ended:${b.prayerId}',
      );
      if (!mounted) return;
      Constants.showToast(
        'Thank you for sharing. Keep trusting and praying🙏',
        2200,
      );
      setState(() => _banner = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _banner;
    if (b == null) return const SizedBox.shrink();
    if (b.kind == _HomePrayerBannerKind.endsToday) {
      return _EndsTodayBanner(
        onTap: _onEndsTodayTap,
        onClose: _dismiss,
      );
    }
    return _HasEndedBanner(
      onUpdateStatus: _busy ? null : _onUpdateStatus,
      onClose: _dismiss,
    );
  }
}

class _EndsTodayBanner extends StatelessWidget {
  const _EndsTodayBanner({
    required this.onTap,
    required this.onClose,
  });

  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: const Color(0xFFF7EEDF),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4D4BC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🙏', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your prayer period ends today',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3E2A1F),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Take a moment to pray for your request.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Color(0xFF5C4A3A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF5C4A3A)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HasEndedBanner extends StatelessWidget {
  const _HasEndedBanner({
    required this.onUpdateStatus,
    required this.onClose,
  });

  final VoidCallback? onUpdateStatus;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EEDF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4D4BC)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.volunteer_activism,
              color: Color(0xFFC9A227),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your prayer period has ended',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E2A1F),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Share how your prayer journey went.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: Color(0xFF5C4A3A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 8),
                    child: Icon(Icons.close, size: 16, color: Color(0xFF5C4A3A)),
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onUpdateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C4033),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
