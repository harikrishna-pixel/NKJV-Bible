import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/post_prayer_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_comments_sheet.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Prayer Wall — lists `GET /api/prayers`, supports category filter, like & comment counts.
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  static const List<String> _filterCategories = [
    'All',
    'Health',
    'Family',
    'Financial',
    'Job',
    'Gratitude',
    'Others',
  ];

  List<PrayerWallItem> _all = [];
  Map<String, int> _likeCounts = {};
  Map<String, int> _commentCounts = {};
  Map<String, String> _prayerAuthorMap = {};
  String _filter = 'All';
  bool _loading = true;
  String? _error;
  bool _authLoading = true;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userId;
  final CacheNotifier _cacheNotifier = CacheNotifier();

  /// Maps prayer ObjectId → like document `_id` for unlike (persisted).
  Map<String, String> _likeIdByPrayerId = {};
  final Set<String> _likeToggleBusy = {};

  @override
  void initState() {
    super.initState();
    _hydrateLikesFromDisk();
    _hydratePrayerAuthorsFromDisk();
    _initAuthAndProfile();
    _refresh();
  }

  Future<void> _initAuthAndProfile() async {
    try {
      final authtoken = await _cacheNotifier.readCache(key: 'authtoken');
      final userid = await _cacheNotifier.readCache(key: 'userid');
      final name = await _cacheNotifier.readCache(key: 'name');

      final loggedIn = (authtoken != null && authtoken.toString().isNotEmpty) ||
          (userid != null && userid.toString().isNotEmpty);

      if (!mounted) return;

      if (!loggedIn) {
        // If user isn't logged in, show the existing login screen.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(hasSkip: false),
          ),
        );
        return;
      }

      setState(() {
        _isLoggedIn = true;
        _userId = userid?.toString();
        _userName = name;
        _authLoading = false;
      });
    } catch (_) {
      // If cache read fails for any reason, treat as not logged in.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(hasSkip: false),
        ),
      );
    }
  }

  Future<void> _hydrateLikesFromDisk() async {
    final m = await PrayerWallLocalStore.loadLikeMap();
    if (!mounted) return;
    setState(() => _likeIdByPrayerId = m);
  }

  Future<void> _hydratePrayerAuthorsFromDisk() async {
    final m = await PrayerWallLocalStore.loadPrayerAuthorMap();
    if (!mounted) return;
    setState(() => _prayerAuthorMap = m);
  }

  /// True if this device has marked the prayer as liked (see persisted map).
  bool _isLiked(String prayerId) =>
      _likeIdByPrayerId.containsKey(prayerId);

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authorMap = await PrayerWallLocalStore.loadPrayerAuthorMap();
      final results = await Future.wait([
        PrayerWallService.fetchPrayers(),
        PrayerWallService.fetchLikeCountsByPrayer(),
        PrayerWallService.fetchCommentCountsByPrayer(),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<PrayerWallItem>;
        _likeCounts = Map<String, int>.from(results[1] as Map<String, int>);
        _commentCounts = Map<String, int>.from(results[2] as Map<String, int>);
        _prayerAuthorMap = authorMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<PrayerWallItem> get _visible {
    if (_filter == 'All') return _all;
    return _all.where((p) => p.category == _filter).toList();
  }

  Future<void> _refreshCommentCountsOnly() async {
    try {
      final c = await PrayerWallService.fetchCommentCountsByPrayer();
      if (!mounted) return;
      setState(() => _commentCounts = c);
    } catch (_) {}
  }

  Future<void> _toggleLike(PrayerWallItem item) async {
    final pid = item.id;
    if (_likeToggleBusy.contains(pid)) return;
    setState(() => _likeToggleBusy.add(pid));

    try {
      if (_isLiked(pid)) {
        final likeId = _likeIdByPrayerId[pid];
        await PrayerWallService.deleteLike(
          likeId: (likeId != null && likeId.isNotEmpty) ? likeId : null,
          prayerId: pid,
        );
        _likeIdByPrayerId.remove(pid);
        await PrayerWallLocalStore.saveLikeMap(_likeIdByPrayerId);
        if (!mounted) return;
        setState(() {
          final n = (_likeCounts[pid] ?? 1) - 1;
          _likeCounts[pid] = n < 0 ? 0 : n;
        });
      } else {
        final newId = await PrayerWallService.postLike(pid);
        if (newId != null && newId.isNotEmpty) {
          _likeIdByPrayerId[pid] = newId;
        } else {
          _likeIdByPrayerId[pid] = '';
        }
        await PrayerWallLocalStore.saveLikeMap(_likeIdByPrayerId);
        if (!mounted) return;
        setState(() {
          _likeCounts[pid] = (_likeCounts[pid] ?? 0) + 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like update failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _likeToggleBusy.remove(pid));
      }
    }
  }

  Future<void> _openComments(PrayerWallItem item) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: Colors.transparent,
        child: PrayerWallCommentsSheet(
          prayerId: item.id,
          titlePreview:
              item.title.isNotEmpty ? item.title : item.description,
        ),
      ),
    );
    await _refreshCommentCountsOnly();
  }

  String _timeLabel(PrayerWallItem item) {
    final d = item.createdAt;
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final cream = isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF5F0E6);
    final userInitials = (() {
      final raw = (_userName ?? '').trim().replaceAll(RegExp(r'\s+'), '');
      if (raw.isEmpty) return '?';
      if (raw.length == 1) return raw[0].toUpperCase();
      return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
    })();

    if (_authLoading) {
      return Scaffold(
        backgroundColor: cream,
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: brown,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 90,),
                  Text(
                    'Prayer Wall',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Georgia',
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _filterCategories.length,
                itemBuilder: (context, i) {
                  final c = _filterCategories[i];
                  final sel = _filter == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c),
                      selected: sel,
                      onSelected: (_) => setState(() => _filter = c),
                      selectedColor: brown,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: sel
                            ? Colors.white
                            : (isDark ? Colors.white : brown),
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.white,
                      side: BorderSide(
                        color: sel ? brown : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoggedIn && (_userName?.trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: brown.withOpacity(0.2),
                      child: Text(
                        userInitials,
                        style: TextStyle(
                          color: brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hi, ${_userName!.trim()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : brown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refresh,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: _visible.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.25,
                                    ),
                                    Center(
                                      child: Text(
                                        'No prayers in this category yet.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 100),
                                  itemCount: _visible.length,
                                  itemBuilder: (context, index) {
                                    final item = _visible[index];
                                    return _PrayerCard(
                                      item: item,
                                      brown: brown,
                                      isDark: isDark,
                                      timeLabel: _timeLabel(item),
                                      displayName: item.isAnonymous
                                          ? 'Anonymous'
                                          : ((item.authorName?.trim().isNotEmpty ??
                                                  false)
                                              ? item.authorName!.trim()
                                              : (((item.authorUserId
                                                                  ?.trim()
                                                                  .isNotEmpty ??
                                                              false) &&
                                                          (_userId?.trim().isNotEmpty ??
                                                              false) &&
                                                          item.authorUserId!
                                                                  .trim() ==
                                                              _userId!.trim() &&
                                                          (_userName
                                                                  ?.trim()
                                                                  .isNotEmpty ??
                                                              false))
                                                      ? _userName!.trim()
                                              : ((_prayerAuthorMap[item.id]
                                                              ?.trim()
                                                              .isNotEmpty ??
                                                          false)
                                                      ? _prayerAuthorMap[item.id]!
                                                          .trim()
                                                      : 'Community member'))),
                                      likeCount: _likeCounts[item.id] ?? 0,
                                      liked: _isLiked(item.id),
                                      likeBusy:
                                          _likeToggleBusy.contains(item.id),
                                      onToggleLike: () => _toggleLike(item),
                                      commentCount:
                                          _commentCounts[item.id] ?? 0,
                                      onComments: () => _openComments(item),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: ElevatedButton(
          onPressed: () async {
            final posted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const PostPrayerScreen(),
              ),
            );
            if (posted == true && mounted) {
              await _hydratePrayerAuthorsFromDisk();
              await _refresh();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: brown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text(
            'Post a Prayer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.item,
    required this.brown,
    required this.isDark,
    required this.timeLabel,
    required this.displayName,
    required this.likeCount,
    required this.liked,
    required this.likeBusy,
    required this.onToggleLike,
    required this.commentCount,
    required this.onComments,
  });

  final PrayerWallItem item;
  final Color brown;
  final bool isDark;
  final String timeLabel;
  final String displayName;
  final int likeCount;
  final bool liked;
  final bool likeBusy;
  final VoidCallback onToggleLike;
  final int commentCount;
  final VoidCallback onComments;

  String _avatarInitials(String value) {
    final raw = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '?';
    if (raw.length == 1) return raw[0].toUpperCase();
    return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: brown.withOpacity(0.2),
                  child: Text(
                    _avatarInitials(displayName),
                    style: TextStyle(
                      color: brown,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$displayName${timeLabel.isNotEmpty ? ' · $timeLabel' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : brown,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brown.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 14, color: brown),
                      const SizedBox(width: 4),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title.isNotEmpty ? item.title : item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
            if (item.title.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isDark ? Colors.white70 : Colors.grey.shade800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF0E8DC),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: likeBusy ? null : onToggleLike,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (likeBusy)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: brown,
                                ),
                              )
                            else
                              Icon(
                                liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: liked
                                    ? Colors.red.shade400
                                    : brown,
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF0E8DC),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: onComments,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color: brown, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$commentCount Comments',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : brown,
                                ),
                              ),
                            ),
                          ],
                        ),
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
