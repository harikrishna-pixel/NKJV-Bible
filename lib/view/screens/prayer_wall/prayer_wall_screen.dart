import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/prayer_wall/post_prayer_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_comments_sheet.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_share_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

/// Prayer Wall — lists `GET /api/prayers`, supports category filter, like & comment counts.
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  static const List<String> _sortOptions = [
    'Latest',
    'Most prayed',
  ];
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
  Set<String> _myPrayerIds = {};
  String _filter = 'All';
  String _sort = 'Latest';
  bool _loading = true;
  String? _error;
  bool _authLoading = true;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userId;
  /// Name last saved when posting (no login required).
  String? _localDisplayName;
  final CacheNotifier _cacheNotifier = CacheNotifier();

  /// Logged-in name if any, otherwise last locally saved post name.
  String get _viewerDisplayName {
    final u = (_userName ?? '').trim();
    if (u.isNotEmpty) return u;
    return (_localDisplayName ?? '').trim();
  }

  /// Maps prayer ObjectId → like document `_id` for unlike (persisted).
  Map<String, String> _likeIdByPrayerId = {};
  final Set<String> _likeToggleBusy = {};

  bool _looksOffline(Object e) {
    final s = e.toString();
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('Network is unreachable');
  }

  String _friendlyError(Object e) {
    if (_looksOffline(e)) {
      return 'You’re offline. Please check your internet connection and try again.';
    }
    return e.toString();
  }

  void _showAppleToast(String message) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 24,
        right: 24,
        bottom: 88,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1400), () => entry.remove());
  }

  @override
  void initState() {
    super.initState();
    _hydrateLikesFromDisk();
    _hydratePrayerAuthorsFromDisk();
    _hydrateMyPrayerIdsFromDisk();
    _loadAuthAndLocalName();
    _refresh();
  }

  Future<void> _loadAuthAndLocalName() async {
    try {
      final authtoken = await _cacheNotifier.readCache(key: 'authtoken');
      final userid = await _cacheNotifier.readCache(key: 'userid');
      final name = await _cacheNotifier.readCache(key: 'name');
      final localName = await PrayerWallLocalStore.loadLastDisplayName();

      final loggedIn = (authtoken != null && authtoken.toString().isNotEmpty) ||
          (userid != null && userid.toString().isNotEmpty);

      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _userId = userid?.toString();
        _userName = name?.toString();
        _localDisplayName = localName;
        _authLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final localName = await PrayerWallLocalStore.loadLastDisplayName();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _userId = null;
        _userName = null;
        _localDisplayName = localName;
        _authLoading = false;
      });
    }
  }

  Future<void> _reloadLocalDisplayName() async {
    final n = await PrayerWallLocalStore.loadLastDisplayName();
    if (!mounted) return;
    setState(() => _localDisplayName = n);
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

  Future<void> _hydrateMyPrayerIdsFromDisk() async {
    final s = await PrayerWallLocalStore.loadMyPrayerIds();
    if (!mounted) return;
    setState(() => _myPrayerIds = s);
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
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  List<PrayerWallItem> get _visible {
    final base = _filter == 'All'
        ? List<PrayerWallItem>.from(_all)
        : _all.where((p) => p.category == _filter).toList();

    int createdMs(PrayerWallItem p) =>
        p.createdAt?.millisecondsSinceEpoch ?? 0;

    if (_sort == 'Most prayed') {
      base.sort((a, b) {
        final la = _likeCounts[a.id] ?? 0;
        final lb = _likeCounts[b.id] ?? 0;
        if (lb != la) return lb.compareTo(la);
        return createdMs(b).compareTo(createdMs(a));
      });
    } else {
      base.sort((a, b) => createdMs(b).compareTo(createdMs(a)));
    }
    return base;
  }

  bool _isMyPrayer(PrayerWallItem item) {
    if (_myPrayerIds.contains(item.id)) return true;
    final uid = (_userId ?? '').trim();
    final uname = _viewerDisplayName;
    final authorId = (item.authorUserId ?? '').trim();
    if (uid.isNotEmpty && authorId.isNotEmpty && uid == authorId) return true;
    final local = (_prayerAuthorMap[item.id] ?? '').trim();
    if (uname.isNotEmpty && local.isNotEmpty && uname == local) return true;
    final apiName = (item.authorName ?? '').trim();
    if (uname.isNotEmpty && apiName.isNotEmpty && uname == apiName) return true;
    return false;
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
      _showAppleToast(_looksOffline(e)
          ? 'No internet connection. Please try again.'
          : 'Like update failed. Please try again.');
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

  Future<void> _openPrayerActions(PrayerWallItem item) async {
    final isMine = _isMyPrayer(item);
    if (!isMine) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final dialogBg = isDark
        ? CommanColor.darkPrimaryColor
        : (themeProvider.currentCustomTheme == AppCustomTheme.vintage
            ? const Color(0xFFF8F3EA)
            : themeProvider.backgroundColor);

    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final screenH = MediaQuery.of(ctx).size.height;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: screenH * 0.85,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: dialogBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: brown.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_outlined,
                                color: isDark ? Colors.white70 : brown,
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Edit your post',
                              style: TextStyle(
                                color: isDark ? Colors.white : brown,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx, 'cancel'),
                            icon: Icon(Icons.close,
                                color: isDark ? Colors.white70 : brown),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white
                                        .withValues(alpha: 0.08)
                                    : const Color(0xFFE7DCCB),
                              ),
                            ),
                            child: TextField(
                              controller: titleCtrl,
                              maxLength: 120,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white : brown),
                              decoration: InputDecoration(
                                hintText: 'Enter a short title',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.fromLTRB(
                                        12, 12, 12, 10),
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white
                                        .withValues(alpha: 0.08)
                                    : const Color(0xFFE7DCCB),
                              ),
                            ),
                            child: TextField(
                              controller: descCtrl,
                              maxLines: 5,
                              maxLength: 2000,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white : brown,
                                  height: 1.35),
                              decoration: InputDecoration(
                                hintText:
                                    'Write your prayer details…',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.fromLTRB(
                                        12, 12, 12, 10),
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tip: Use “Read more” on long posts for a full view.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, 'delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, 'save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (action == null || action == 'cancel') return;

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? CommanColor.darkPrimaryColor : null,
          surfaceTintColor: Colors.transparent,
          title: const Text('Delete post?'),
          content: const Text('This post will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: isDark ? Colors.white70 : null)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: isDark ? Colors.white : null)),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await PrayerWallService.deletePrayer(item.id);
        await PrayerWallLocalStore.removePrayerAuthor(prayerId: item.id);
        await PrayerWallLocalStore.removeMyPrayerId(item.id);
        if (!mounted) return;
        await _hydratePrayerAuthorsFromDisk();
        await _hydrateMyPrayerIdsFromDisk();
        await _refresh();
        if (!mounted) return;
        Constants.showToast('Post deleted.');
      } catch (e) {
        if (!mounted) return;
        _showAppleToast(_looksOffline(e)
            ? 'No internet connection. Please try again.'
            : 'Could not delete. Please try again.');
      }
      return;
    }

    if (action == 'save') {
      final newTitle = titleCtrl.text.trim();
      final newDesc = descCtrl.text.trim();
      try {
        await PrayerWallService.updatePrayer(
          prayerId: item.id,
          prayerTitle: newTitle,
          prayerDescription: newDesc,
        );
        if (!mounted) return;
        await _refresh();
        if (!mounted) return;
        Constants.showToast('Post updated.');
      } catch (e) {
        if (!mounted) return;
        _showAppleToast(_looksOffline(e)
            ? 'No internet connection. Please try again.'
            : 'Could not update. Please try again.');
      }
    }
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
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (themeProvider.currentCustomTheme == AppCustomTheme.vintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);
    final userInitials = (() {
      final raw =
          _viewerDisplayName.replaceAll(RegExp(r'\s+'), '');
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? brown.withValues(alpha: 0.9) : brown,
        foregroundColor: Colors.white,
        elevation: isDark ? 8 : 6,
        onPressed: () async {
          final isConnected = await InternetConnection().hasInternetAccess;
          if (!isConnected) {
            Constants.showToast('No internet connection', 5000);
            return;
          }
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const PostPrayerScreen(),
            ),
          );
          if (posted == true && mounted) {
            await _reloadLocalDisplayName();
            await _hydratePrayerAuthorsFromDisk();
            await _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
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
                  Expanded(
                    child: Center(
                      child: Text(
                        'Prayer Wall',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ),
                  // Balance the back button so the title stays centered.
                  const SizedBox(width: 48),
                ],
              ),
            ),
            SizedBox(
              // Increased height so category chips have enough vertical
              // space and don't get visually cut off on some devices.
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 24, 10),
                itemCount: _filterCategories.length,
                itemBuilder: (context, i) {
                  final c = _filterCategories[i];
                  final sel = _filter == c;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i == _filterCategories.length - 1 ? 0 : 10,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _filter = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? brown
                              : (isDark ? Colors.white12 : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? brown : Colors.grey.shade400,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c,
                          style: TextStyle(
                            color: sel
                                ? Colors.white
                                : (isDark ? Colors.white : brown),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Sort:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : brown,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    dropdownColor: isDark ? CommanColor.darkPrimaryColor : Colors.white,
                    items: _sortOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color: isDark ? Colors.white : brown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _sort = v);
                    },
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brown,
                                    foregroundColor: Colors.white,
                                  ),
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
                                      displayName: _isMyPrayer(item)
                                          ? (_viewerDisplayName.isNotEmpty
                                              ? _viewerDisplayName
                                              : 'You')
                                          : (item.isAnonymous
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
                                                              _viewerDisplayName
                                                                  .isNotEmpty)
                                                          ? _viewerDisplayName
                                                          : ((_prayerAuthorMap[item.id]
                                                                          ?.trim()
                                                                          .isNotEmpty ??
                                                                      false)
                                                                  ? _prayerAuthorMap[item.id]!
                                                                      .trim()
                                                                  : 'Community member')))),
                                      isMine: _isMyPrayer(item),
                                      onOpen: () => _openPrayerActions(item),
                                      onShare: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PrayerShareScreen(
                                              prayerId: item.id,
                                              title: item.title,
                                              description: item.description,
                                            ),
                                          ),
                                        );
                                      },
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
              await _reloadLocalDisplayName();
              await _hydratePrayerAuthorsFromDisk();
              await _refresh();
              if (!mounted) return;
              _showAppleToast('Prayer posted successfully.');
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
        )
      )
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
    required this.isMine,
    required this.onOpen,
    required this.onShare,
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
  final bool isMine;
  final VoidCallback onOpen;
  final VoidCallback onShare;
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

  bool _textOverflows(
    BuildContext context,
    String text, {
    required TextStyle style,
    required int maxLines,
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isMine ? onOpen : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark 
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFFD4C4B0),
            width: 1,
          ),
        ),
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
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.12)
                        : brown.withOpacity(0.2),
                    child: Text(
                      _avatarInitials(displayName),
                      style: TextStyle(
                        color: isDark ? Colors.white : brown,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$displayName${timeLabel.isNotEmpty ? ' · $timeLabel' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : brown,
                                ),
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: brown.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: brown,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                      // Icon(Icons.favorite_border, size: 14, color: isDark ? Colors.white70 : brown),
                      const SizedBox(width: 4),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : brown,
                        ),
                      ),
                    ],
                  ),
                ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: brown.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.share, size: 16, color: isDark ? Colors.white70 : brown),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final titleText =
                      item.title.isNotEmpty ? item.title : item.description;
                  final titleStyle = TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color:
                        isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  );
                  final overflow = _textOverflows(
                    context,
                    titleText,
                    style: titleStyle,
                    maxLines: 3,
                    maxWidth: constraints.maxWidth,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      if (overflow)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (dctx) => AlertDialog(
                                  backgroundColor:
                                      isDark ? CommanColor.darkPrimaryColor : null,
                                  surfaceTintColor: Colors.transparent,
                                  title: Text(
                                    'Prayer',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : brown,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      titleText,
                                      style: TextStyle(
                                          color:
                                              isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dctx),
                                      child: Text('Close',
                                          style: TextStyle(
                                              color: isDark ? Colors.white : null)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'Read more',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: brown,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (item.title.isNotEmpty) ...[
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final descStyle = TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    );
                    final overflow = _textOverflows(
                      context,
                      item.description,
                      style: descStyle,
                      maxLines: 4,
                      maxWidth: constraints.maxWidth,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: descStyle,
                        ),
                        if (overflow)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (dctx) => AlertDialog(
                                    backgroundColor:
                                        isDark ? CommanColor.darkPrimaryColor : null,
                                    surfaceTintColor: Colors.transparent,
                                    title: Text(
                                      item.title.isNotEmpty
                                          ? item.title
                                          : 'Prayer',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : brown,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        item.description,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dctx),
                                        child: Text('Close',
                                            style: TextStyle(
                                                color:
                                                    isDark ? Colors.white : null)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Read more',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: brown,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
                                  color: isDark ? Colors.white70 : brown, size: 18),
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
      ),
        );
  }
}
