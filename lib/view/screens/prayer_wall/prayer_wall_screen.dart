import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/post_prayer_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_comments_sheet.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_login_required_dialog.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_share_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_report_dialog.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_status_dialog.dart';
import 'package:biblebookapp/utils/network_error_message.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  /// Name last saved when posting (fallback display).
  String? _localDisplayName;
  /// Cached profile photo URL (fallback for my posts if API omits image).
  String? _viewerProfileImage;
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
  bool _statusPromptShowing = false;

  bool _looksOffline(Object e) => isNetworkRelatedError(e);

  String _friendlyError(Object e) => userFacingNetworkMessage(e);

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
      final profileImage =
          await _cacheNotifier.readCache(key: 'profile_image');
      final localName = await PrayerWallLocalStore.loadLastDisplayName();

      final loggedIn = (authtoken != null && authtoken.toString().isNotEmpty) ||
          (userid != null && userid.toString().isNotEmpty);

      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _userId = userid?.toString();
        _userName = name?.toString();
        _localDisplayName = localName;
        final img = profileImage?.toString().trim() ?? '';
        _viewerProfileImage = img.isNotEmpty ? img : null;
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
        _viewerProfileImage = null;
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
      final prayers = results[0] as List<PrayerWallItem>;
      await PrayerWallLocalStore.markPrayersAsSeen(prayers.map((p) => p.id));
      setState(() {
        _all = prayers;
        _likeCounts = Map<String, int>.from(results[1] as Map<String, int>);
        _commentCounts = Map<String, int>.from(results[2] as Map<String, int>);
        _prayerAuthorMap = authorMap;
        _loading = false;
      });
      await _maybeShowExpiredStatusPrompt();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  /// UI-only: after exact `postedAt + durationDays`, ask for status.
  Future<void> _maybeShowExpiredStatusPrompt() async {
    if (!mounted || _statusPromptShowing) return;

    final metaMap = await PrayerWallLocalStore.loadPrayerDurationMeta();
    final submitted = await PrayerWallLocalStore.loadStatusSubmittedIds();
    if (!mounted) return;

    String? duePrayerId;
    DateTime? dueAt;
    for (final item in _all) {
      if (!_isMyPrayer(item)) continue;
      if (submitted.contains(item.id)) continue;
      final meta = metaMap[item.id];
      if (meta == null || !meta.isExpired) continue;
      if (dueAt == null || meta.expiresAt.isBefore(dueAt)) {
        dueAt = meta.expiresAt;
        duePrayerId = item.id;
      }
    }
    if (duePrayerId == null || !mounted) return;

    _statusPromptShowing = true;
    try {
      final status = await PrayerWallStatusDialog.show(context);
      if (!mounted) return;
      if (status == null) return;
      await PrayerWallLocalStore.markStatusSubmitted(duePrayerId);
      if (!mounted) return;
      Constants.showToast(
        'Thank you for sharing. Keep trusting and praying🙏',
        2200,
      );
    } finally {
      _statusPromptShowing = false;
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

  /// UI gate only: show Login Required, then open LoginScreen. No API changes.
  Future<bool> _ensureLoggedIn({required String message}) async {
    if (_isLoggedIn) return true;
    final goLogin = await PrayerWallLoginRequiredDialog.show(
      context,
      message: message,
    );
    if (goLogin != true || !mounted) return false;

    final result = await Get.to<dynamic>(
      () => LoginScreen(hasSkip: false, popOnSuccess: true),
    );
    if (!mounted) return false;
    await _loadAuthAndLocalName();
    return _isLoggedIn || result == true;
  }

  Future<void> _toggleLike(PrayerWallItem item) async {
    final allowed = await _ensureLoggedIn(
      message:
          'Please log in to support this prayer request and leave a comment.',
    );
    if (!allowed || !mounted) return;

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

  Future<bool> _ensureCanComment() {
    return _ensureLoggedIn(
      message:
          'Please log in to support this prayer request and leave a comment.',
    );
  }

  Future<void> _openReport(PrayerWallItem item) async {
    final reason = await PrayerWallReportDialog.show(context);
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    try {
      final rawReporterId = ((_userId ?? '').trim().isNotEmpty)
          ? _userId!.trim()
          : await PrayerWallLocalStore.getOrCreateReporterId();
      final reporterId =
          PrayerWallLocalStore.normalizeReporterId(rawReporterId);
      print(
        'PrayerWall _openReport data => '
        'prayerId=${item.id}, reporter_id=$reporterId '
        '(len=${reporterId.length}/128), '
        'report_reason=${reason.trim()}',
      );
      await PrayerWallService.reportPrayer(
        prayerId: item.id,
        reporterId: reporterId,
        reportReason: reason.trim(),
      );
      if (!mounted) return;
      Constants.showToast('Report submitted successfully', 2000);
    } catch (e) {
      print('PrayerWall _openReport error: $e');
      if (!mounted) return;
      _showAppleToast(_looksOffline(e)
          ? 'No internet connection. Please try again.'
          : 'Could not submit report. Please try again.');
    }
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
    final scrollCtrl = ScrollController();

    void scrollFieldIntoView() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollCtrl.hasClients) return;
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      });
    }

    String? action;
    try {
      action = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final media = MediaQuery.of(ctx);
          final bottomInset = media.viewInsets.bottom;
          final topInset = media.padding.top;
          final maxSheetHeight =
              media.size.height - topInset - bottomInset - 24;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: topInset + 12,
              bottom: bottomInset + 12,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: dialogBg,
                elevation: 12,
                shadowColor: Colors.black45,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: maxSheetHeight.clamp(280.0, media.size.height),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Flexible(
                        child: SingleChildScrollView(
                          controller: scrollCtrl,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
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
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE7DCCB),
                                  ),
                                ),
                                child: TextField(
                                  controller: titleCtrl,
                                  maxLength: 120,
                                  style: TextStyle(
                                      color: isDark ? Colors.white : brown),
                                  decoration: InputDecoration(
                                    hintText: 'Enter a short title',
                                    hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey.shade600),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(
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
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE7DCCB),
                                  ),
                                ),
                                child: TextField(
                                  controller: descCtrl,
                                  maxLines: 5,
                                  maxLength: 2000,
                                  onTap: scrollFieldIntoView,
                                  style: TextStyle(
                                      color: isDark ? Colors.white : brown,
                                      height: 1.35),
                                  decoration: InputDecoration(
                                    hintText: 'Write your prayer details…',
                                    hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey.shade600),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(
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
                              const SizedBox(height: 8),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
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
    } finally {
      scrollCtrl.dispose();
    }

    if (action == null || action == 'cancel') return;

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          const cream = Color(0xFFFFF9F3);
          const ink = Color(0xFF4B3423);
          const muted = Color(0xFF6B4E3D);
          const deleteRed = Color(0xFFC62828);
          final bg = isDark ? CommanColor.darkPrimaryColor : cream;
          final titleColor = isDark ? Colors.white : ink;
          final bodyColor = isDark ? Colors.white70 : muted;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Delete Prayer?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Are you sure you want to delete this prayer request? This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: bodyColor,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: titleColor,
                                    side: BorderSide(
                                      color: titleColor.withValues(
                                        alpha: isDark ? 0.55 : 0.75,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: deleteRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
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
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx, false),
                      icon: Icon(
                        Icons.close,
                        color: bodyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Future<void> _openPostPrayerScreen({bool showSuccessToast = false}) async {
    final allowed = await _ensureLoggedIn(
      message:
          'Please log in to support this prayer request and leave a comment.',
    );
    if (!allowed || !mounted) return;

    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast('No internet connection', 1000);
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
      if (showSuccessToast && mounted) {
        _showAppleToast('Prayer posted successfully.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final brown = const Color(0xFF5C4033);
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
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
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(color: cream),
        child: Scaffold(
          backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? brown.withValues(alpha: 0.9) : brown,
        foregroundColor: Colors.white,
        elevation: isDark ? 8 : 6,
        onPressed: () => _openPostPrayerScreen(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
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
                                      profileImageUrl: () {
                                        final fromApi =
                                            item.profileImage?.trim() ?? '';
                                        if (fromApi.isNotEmpty) return fromApi;
                                        if (_isMyPrayer(item) &&
                                            (_viewerProfileImage
                                                    ?.trim()
                                                    .isNotEmpty ??
                                                false)) {
                                          return _viewerProfileImage!.trim();
                                        }
                                        return null;
                                      }(),
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
                                      onReport: () => _openReport(item),
                                      likeCount: _likeCounts[item.id] ?? 0,
                                      liked: _isLiked(item.id),
                                      likeBusy:
                                          _likeToggleBusy.contains(item.id),
                                      onToggleLike: () => _toggleLike(item),
                                      commentCount:
                                          _commentCounts[item.id] ?? 0,
                                      onEnsureCanComment: _ensureCanComment,
                                      onCommentsChanged:
                                          _refreshCommentCountsOnly,
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Padding(
      //   padding: EdgeInsets.fromLTRB(
      //     16,
      //     0,
      //     16,
      //     16 + MediaQuery.of(context).padding.bottom,
      //   ),
      //   child: ElevatedButton(
      //     onPressed: () => _openPostPrayerScreen(showSuccessToast: true),
      //     style: ElevatedButton.styleFrom(
      //       backgroundColor: brown,
      //       foregroundColor: Colors.white,
      //       padding: const EdgeInsets.symmetric(vertical: 16),
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(28),
      //       ),
      //     ),
      //     child: const Text(
      //       'Post a Prayer',
      //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      //     ),
      //   ),
      // ),
        )
      )
    );
  }
}

Widget _metaChip({
  required String label,
  required Color brown,
  required bool isDark,
  IconData? leadingIcon,
  String? tooltip,
}) {
  final chip = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF4A382C) : brown.withOpacity(0.14),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark ? const Color(0xFF6B5344) : brown.withOpacity(0.35),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(
            leadingIcon,
            size: 12,
            color: isDark ? const Color(0xFFF5EDE3) : brown,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF5EDE3) : brown,
          ),
        ),
      ],
    ),
  );

  if (tooltip == null || tooltip.trim().isEmpty) return chip;
  return Tooltip(message: tooltip, child: chip);
}

class _PrayerCard extends StatefulWidget {
  const _PrayerCard({
    required this.item,
    required this.brown,
    required this.isDark,
    required this.timeLabel,
    required this.displayName,
    this.profileImageUrl,
    required this.isMine,
    required this.onOpen,
    required this.onShare,
    required this.onReport,
    required this.likeCount,
    required this.liked,
    required this.likeBusy,
    required this.onToggleLike,
    required this.commentCount,
    required this.onEnsureCanComment,
    required this.onCommentsChanged,
  });

  final PrayerWallItem item;
  final Color brown;
  final bool isDark;
  final String timeLabel;
  final String displayName;
  /// Optional photo URL (API profile_image / cached viewer image).
  final String? profileImageUrl;
  final bool isMine;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final int likeCount;
  final bool liked;
  final bool likeBusy;
  final VoidCallback onToggleLike;
  final int commentCount;
  final Future<bool> Function() onEnsureCanComment;
  final Future<void> Function() onCommentsChanged;

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  bool _titleExpanded = false;
  bool _descExpanded = false;
  bool _commentsOpen = false;

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

  Future<void> _toggleComments() async {
    if (_commentsOpen) {
      setState(() => _commentsOpen = false);
      await widget.onCommentsChanged();
      return;
    }
    final ok = await widget.onEnsureCanComment();
    if (!ok || !mounted) return;
    setState(() => _commentsOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final brown = widget.brown;
    final isDark = widget.isDark;
    final displayName = widget.displayName;
    final timeLabel = widget.timeLabel;
    final isMine = widget.isMine;
    final likeCount = widget.likeCount;
    final liked = widget.liked;
    final likeBusy = widget.likeBusy;
    final commentCount = widget.commentCount;
    final photoUrl = (widget.profileImageUrl ?? item.profileImage ?? '').trim();
    final hasPhoto = photoUrl.isNotEmpty;

    return InkWell(
      onTap: isMine ? widget.onOpen : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2118) : const Color(0xFFFFF6EB),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? const Color(0xFF5A4638)
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? const Color(0xFF4A382C)
                        : brown.withOpacity(0.18),
                    backgroundImage:
                        hasPhoto ? NetworkImage(photoUrl) : null,
                    onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            _avatarInitials(displayName),
                            style: TextStyle(
                              color: isDark ? Colors.white : brown,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF3D2914),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (timeLabel.isNotEmpty)
                              Text(
                                timeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFE8DDD0)
                                      : const Color(0xFF6B5344),
                                ),
                              ),
                            if (isMine)
                              _metaChip(
                                label: 'You',
                                brown: brown,
                                isDark: isDark,
                              ),
                            _metaChip(
                              label: item.category,
                              brown: brown,
                              isDark: isDark,
                              leadingIcon: Icons.label_outline_rounded,
                              tooltip: 'Prayer category',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.onShare,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: isDark ? Colors.white : brown,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onReport,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: isDark ? Colors.white : brown,
                      ),
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
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
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
                        maxLines: _titleExpanded ? null : 3,
                        overflow: _titleExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
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
                            onPressed: () => setState(
                              () => _titleExpanded = !_titleExpanded,
                            ),
                            child: Text(
                              _titleExpanded ? 'Show less' : 'Read more',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFE8C9A0)
                                    : brown,
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
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFE8DDD0)
                          : const Color(0xFF4A4A4A),
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
                          maxLines: _descExpanded ? null : 4,
                          overflow: _descExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
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
                              onPressed: () => setState(
                                () => _descExpanded = !_descExpanded,
                              ),
                              child: Text(
                                _descExpanded ? 'Show less' : 'Read more',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFE8C9A0)
                                      : brown,
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
                          ? const Color(0xFF3D2E24)
                          : const Color(0xFFF0E4D4),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: likeBusy ? null : widget.onToggleLike,
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
                                    color: isDark
                                        ? const Color(0xFFF5EDE3)
                                        : brown,
                                  ),
                                )
                              else
                                Icon(
                                  liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: liked
                                      ? Colors.red.shade400
                                      : (isDark
                                          ? const Color(0xFFF5EDE3)
                                          : brown),
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
                          ? const Color(0xFF3D2E24)
                          : const Color(0xFFF0E4D4),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _toggleComments,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: isDark ? Colors.white : brown,
                                size: 18,
                              ),
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
              if (_commentsOpen)
                PrayerWallCommentsSheet(
                  key: ValueKey('comments_${item.id}'),
                  prayerId: item.id,
                  titlePreview:
                      item.title.isNotEmpty ? item.title : item.description,
                  embedded: true,
                  onChanged: () {
                    widget.onCommentsChanged();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
