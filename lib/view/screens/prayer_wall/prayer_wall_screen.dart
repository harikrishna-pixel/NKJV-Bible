import 'dart:async';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/referral_code_bottom_sheet.dart';
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

class _PrayerWallScreenState extends State<PrayerWallScreen>
    with WidgetsBindingObserver {
  static const List<String> _sortOptions = [
    'Latest',
    'Most prayed',
  ];
  static const List<String> _myPrayerSortOptions = [
    'Current',
    'Expired',
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
  Map<String, String> _prayerAuthorUserIdMap = {};
  Set<String> _myPrayerIds = {};
  /// UI-only: prayers reported on this device (flag highlight).
  Set<String> _reportedPrayerIds = {};
  /// UI-only: prayer `_id`s blocked on this device (hide those prayers).
  Set<String> _blockedUserIds = {};
  String _filter = 'All';
  String _sort = 'Latest';
  /// Inside My Prayers: Current (active) vs Expired (prayer-history).
  String _myPrayerSort = 'Current';
  bool _loading = true;
  String? _error;
  bool _authLoading = true;
  bool _isLoggedIn = false;
  String? _userName;
  String? _userId;
  String? _userEmail;
  /// Resolve `user_id` from POST /api/users/resolve (additive ownership check).
  String? _resolveUserId;
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
  bool _openingPostPrayer = false;

  /// UI-only: My Prayer section — posted prayers + blocked list tabs.
  bool _showingHistory = false;
  bool _historyLoading = false;
  String? _historyError;
  List<PrayerWallItem> _historyItems = [];
  /// Additive: expired prayers from GET /api/prayer-history (My Prayers → Expired).
  List<PrayerWallItem> _expiredHistoryItems = [];
  bool _openingHistory = false;

  /// UI-only: blocked prayers list (unblock + count).
  bool _showingBlocked = false;
  /// True when My Prayers sort is Expired.
  bool get _showingExpired =>
      _showingHistory && !_showingBlocked && _myPrayerSort == 'Expired';
  bool _blockedApiRestoreBusy = false;
  /// Login email the in-memory blocked list was loaded for (account scoping).
  String? _blockedListAccountEmail;
  /// Login email [_myPrayerIds] belongs to (account scoping).
  String? _myPrayerListAccountEmail;

  /// True when keyboard is up or a text field is focused (hide FAB overlay).
  bool get _hideFabForInput {
    final mqBottom = MediaQuery.viewInsetsOf(context).bottom;
    if (mqBottom > 0) return true;
    final view = View.maybeOf(context);
    if (view != null &&
        view.viewInsets.bottom / view.devicePixelRatio > 0) {
      return true;
    }
    final focusCtx = FocusManager.instance.primaryFocus?.context;
    if (focusCtx == null) return false;
    return focusCtx.findAncestorWidgetOfExactType<TextField>() != null ||
        focusCtx.findAncestorWidgetOfExactType<TextFormField>() != null ||
        focusCtx.widget is EditableText;
  }

  void _onFocusOrMetricsChanged() {
    if (mounted) setState(() {});
  }

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
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusOrMetricsChanged);
    _hydrateLikesFromDisk();
    _hydratePrayerAuthorsFromDisk();
    _hydratePrayerAuthorUserIdsFromDisk();
    _hydrateMyPrayerIdsFromDisk();
    _hydrateReportedPrayerIdsFromDisk();
    _hydrateBlockedUserIdsFromDisk();
    _loadAuthAndLocalName();
    _refresh();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusOrMetricsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _onFocusOrMetricsChanged();
  }

  Future<void> _loadAuthAndLocalName() async {
    try {
      final authtoken = await _cacheNotifier.readCache(key: 'authtoken');
      final userid = await _cacheNotifier.readCache(key: 'userid');
      final name = await _cacheNotifier.readCache(key: 'name');
      final emailCache = await _cacheNotifier.readCache(key: 'user');
      final profileImage =
          await _cacheNotifier.readCache(key: 'profile_image');
      final localName = await PrayerWallLocalStore.loadLastDisplayName();

      final loggedIn = (authtoken != null && authtoken.toString().isNotEmpty) ||
          (userid != null && userid.toString().isNotEmpty);
      final email = (emailCache ?? '').toString().trim();

      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _userId = userid?.toString();
        _userName = name?.toString();
        _userEmail = loggedIn && email.isNotEmpty ? email : null;
        _localDisplayName = localName;
        final img = profileImage?.toString().trim() ?? '';
        _viewerProfileImage = img.isNotEmpty ? img : null;
        _authLoading = false;
      });
      if (loggedIn && email.isNotEmpty) {
        await _syncBlockedUserIdsForAccount(email);
        await _syncMyPrayerIdsForAccount(email);
        await _hydrateResolveUserId();
        // Rebuild again once resolve user_id is ready (re-login ownership).
        await _rebuildMyPrayerIdsForCurrentAccount();
      } else {
        await _syncBlockedUserIdsForAccount(null);
        await _syncMyPrayerIdsForAccount(null);
        if (!mounted) return;
        setState(() => _resolveUserId = null);
      }
      if (!mounted) return;
      unawaited(_restoreBlockedUserIdsFromApi());
    } catch (_) {
      if (!mounted) return;
      final localName = await PrayerWallLocalStore.loadLastDisplayName();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _userId = null;
        _userName = null;
        _userEmail = null;
        _localDisplayName = localName;
        _viewerProfileImage = null;
        _resolveUserId = null;
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

  Future<void> _hydratePrayerAuthorUserIdsFromDisk() async {
    final m = await PrayerWallLocalStore.loadPrayerAuthorUserIdMap();
    if (!mounted) return;
    setState(() => _prayerAuthorUserIdMap = m);
  }

  Future<void> _mergeAuthorUserIdsFromPrayers(List<PrayerWallItem> prayers) async {
    final m = await PrayerWallLocalStore.loadPrayerAuthorUserIdMap();
    var changed = false;
    for (final p in prayers) {
      final uid = (p.authorUserId ?? '').trim();
      if (uid.isEmpty) continue;
      if (m[p.id] == uid) continue;
      m[p.id] = uid;
      changed = true;
    }
    if (!changed) return;
    await PrayerWallLocalStore.savePrayerAuthorUserIdMap(m);
    if (!mounted) return;
    setState(() => _prayerAuthorUserIdMap = m);
  }

  /// My Prayers / ownership: prayer email must match this login when email is known.
  bool _prayerMatchesLoginEmail(PrayerWallItem item, [String? emailOverride]) {
    final want = (emailOverride ?? _userEmail ?? '').trim().toLowerCase();
    if (want.isEmpty) return true;
    final prayerEmail = (item.email ?? '').trim().toLowerCase();
    return prayerEmail.isNotEmpty && prayerEmail == want;
  }

  /// Additive: rebuild My Prayer ids for this login from device-owned + wall
  /// email/identity matches (fixes empty My Prayers after logout → login).
  Future<void> _rebuildMyPrayerIdsForCurrentAccount() async {
    final want = (_userEmail ?? '').trim().toLowerCase();
    if (want.isEmpty) {
      await PrayerWallLocalStore.saveMyPrayerIds({});
      if (!mounted) return;
      setState(() => _myPrayerIds = {});
      return;
    }

    final owned = await PrayerWallLocalStore.loadOwnedPrayerIds();
    final merged = <String>{...owned};
    final resolveId = (_resolveUserId ?? '').trim();

    for (final p in _all) {
      final prayerEmail = (p.email ?? '').trim().toLowerCase();
      if (prayerEmail.isNotEmpty && prayerEmail == want) {
        merged.add(p.id);
        continue;
      }
      if (resolveId.isEmpty) continue;
      if ((p.identityUserId ?? '').trim() == resolveId) {
        merged.add(p.id);
        continue;
      }
      final mapped = (_prayerAuthorUserIdMap[p.id] ?? '').trim();
      final authorUid = (p.authorUserId ?? '').trim();
      if (mapped == resolveId || authorUid == resolveId) {
        merged.add(p.id);
      }
    }

    await PrayerWallLocalStore.saveMyPrayerIds(merged);
    if (!mounted) return;
    setState(() => _myPrayerIds = merged);
  }

  /// Drop previous account's posted-id cache when login email changes,
  /// then rebuild for the current account (do not leave My Prayers empty).
  Future<void> _syncMyPrayerIdsForAccount(String? email) async {
    final key = (email ?? '').trim().toLowerCase();
    if (key.isEmpty) {
      if (!mounted) return;
      setState(() {
        _myPrayerIds = {};
        _myPrayerListAccountEmail = null;
      });
      await PrayerWallLocalStore.saveMyPrayerIds({});
      return;
    }
    final switched = _myPrayerListAccountEmail != key;
    if (!mounted) return;
    setState(() => _myPrayerListAccountEmail = key);
    if (switched) {
      await PrayerWallLocalStore.saveMyPrayerIds({});
      if (!mounted) return;
      setState(() => _myPrayerIds = {});
    }
    await _rebuildMyPrayerIdsForCurrentAccount();
  }

  Future<void> _hydrateMyPrayerIdsFromDisk() async {
    final want = (_userEmail ?? '').trim().toLowerCase();
    if (want.isNotEmpty && _myPrayerListAccountEmail != want) {
      await _syncMyPrayerIdsForAccount(_userEmail);
      return;
    }
    await _rebuildMyPrayerIdsForCurrentAccount();
  }

  Future<void> _hydrateReportedPrayerIdsFromDisk() async {
    final s = await PrayerWallLocalStore.loadReportedPrayerIds();
    if (!mounted) return;
    setState(() => _reportedPrayerIds = s);
  }

  /// Additive: cache resolve `user_id` for prayer ownership after logout/reinstall.
  Future<void> _hydrateResolveUserId() async {
    if (!_isLoggedIn) {
      if (!mounted) return;
      setState(() => _resolveUserId = null);
      return;
    }
    final cached = await PrayerWallLocalStore.loadIdentityUserId();
    final id = (cached != null && cached.isNotEmpty)
        ? cached
        : await PrayerWallService.ensureIdentityUserId();
    if (!mounted) return;
    setState(() => _resolveUserId = id);
  }

  Future<void> _hydrateBlockedUserIdsFromDisk() async {
    // Account-scoped list loads in [_loadAuthAndLocalName]; avoid stale device-wide ids.
    if (!mounted) return;
    setState(() => _blockedUserIds = {});
  }

  /// Load blocked ids for the current login email only (not other accounts).
  Future<void> _syncBlockedUserIdsForAccount(String? email) async {
    final key = (email ?? '').trim().toLowerCase();
    if (key.isEmpty) {
      if (!mounted) return;
      setState(() {
        _blockedUserIds = {};
        _blockedListAccountEmail = null;
      });
      return;
    }
    final forAccount =
        await PrayerWallLocalStore.loadBlockedUserIdsForEmail(key);
    if (!mounted) return;
    setState(() {
      _blockedUserIds = forAccount;
      _blockedListAccountEmail = key;
    });
  }

  /// Additive: refill local blocked ids from GET /api/blocked-users.
  /// Same `user_id` as POST (this account's prayer `_id`s). Does not change
  /// block/unblock POST/DELETE or how the wall hides blocked prayers.
  Future<void> _restoreBlockedUserIdsFromApi({
    List<PrayerWallItem>? prayers,
  }) async {
    if (!mounted || _blockedApiRestoreBusy) return;
    var email = (_userEmail ?? '').trim();
    var loggedIn = _isLoggedIn;
    if (!loggedIn || email.isEmpty) {
      try {
        final authtoken = await _cacheNotifier.readCache(key: 'authtoken');
        final userid = await _cacheNotifier.readCache(key: 'userid');
        final emailCache = await _cacheNotifier.readCache(key: 'user');
        loggedIn = loggedIn ||
            (authtoken != null && authtoken.toString().isNotEmpty) ||
            (userid != null && userid.toString().isNotEmpty);
        if (email.isEmpty) {
          email = (emailCache ?? '').toString().trim();
        }
      } catch (_) {}
    }
    if (!loggedIn) return;

    final emailKey = email.trim().toLowerCase();
    if (_blockedListAccountEmail != emailKey) {
      await _syncBlockedUserIdsForAccount(email);
      if (!mounted) return;
    }

    if (_blockedApiRestoreBusy) return;
    _blockedApiRestoreBusy = true;
    try {
      final fromApi = await PrayerWallService.fetchBlockedUserIdsForAccount(
        email: email,
      );
      if (!mounted) return;
      // Replace with this account's server list — do not union other accounts' ids.
      await PrayerWallLocalStore.saveBlockedUserIds(fromApi, email: email);
      if (!mounted) return;
      setState(() {
        _blockedUserIds = fromApi;
        _blockedListAccountEmail = emailKey;
      });
    } catch (e) {
      print('PrayerWall _restoreBlockedUserIdsFromApi error: $e');
    } finally {
      _blockedApiRestoreBusy = false;
    }
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
      await _mergeAuthorUserIdsFromPrayers(prayers);
      final mergedAuthorUserIdMap =
          await PrayerWallLocalStore.loadPrayerAuthorUserIdMap();
      if (!mounted) return;
      setState(() {
        _all = prayers;
        _likeCounts = Map<String, int>.from(results[1] as Map<String, int>);
        _commentCounts = Map<String, int>.from(results[2] as Map<String, int>);
        _prayerAuthorMap = authorMap;
        _prayerAuthorUserIdMap = mergedAuthorUserIdMap;
        _loading = false;
      });
      // Additive: after wall load, restore My Prayer ids for this login email.
      if (_isLoggedIn && (_userEmail ?? '').trim().isNotEmpty) {
        await _rebuildMyPrayerIdsForCurrentAccount();
      }
      unawaited(_restoreBlockedUserIdsFromApi(prayers: prayers));
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
    final List<PrayerWallItem> source;
    if (_showingHistory && !_showingBlocked && _myPrayerSort == 'Expired') {
      source = _expiredHistoryItems;
    } else if (_showingHistory) {
      source = _historyItems.where((p) => !p.isDurationExpired).toList();
    } else {
      source = _all;
    }
    // UI-only: prayers this user/device reported stay hidden for them only.
    // Does not change report API, ownership, or what other users see.
    final notReported = source.where((p) => !_reportedPrayerIds.contains(p.id));
    // UI-only: hide prayers this user blocked (prayer `_id` or their user id).
    final notBlocked =
        notReported.where((p) => !_isItemBlocked(p));
    final base = _filter == 'All'
        ? List<PrayerWallItem>.from(notBlocked)
        : notBlocked.where((p) => p.category == _filter).toList();

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

  /// Owner only: same login email on the prayer, else this session's posted ids.
  bool _isMyPrayer(PrayerWallItem item) {
    final myEmail = (_userEmail ?? '').trim().toLowerCase();
    final prayerEmail = (item.email ?? '').trim().toLowerCase();
    if (myEmail.isNotEmpty && prayerEmail.isNotEmpty) {
      return myEmail == prayerEmail;
    }
    final resolveId = (_resolveUserId ?? '').trim();
    if (resolveId.isNotEmpty) {
      final prayerIdentity = (item.identityUserId ?? '').trim();
      if (prayerIdentity.isNotEmpty && prayerIdentity == resolveId) {
        if (myEmail.isNotEmpty && prayerEmail.isNotEmpty) {
          return prayerEmail == myEmail;
        }
        if (myEmail.isNotEmpty && prayerEmail.isEmpty) {
          return _myPrayerIds.contains(item.id);
        }
        return prayerEmail.isEmpty || _myPrayerIds.contains(item.id);
      }
      final authorUid = (_prayerAuthorUserIdMap[item.id] ?? '').trim();
      if (authorUid.isNotEmpty && authorUid == resolveId) {
        if (myEmail.isNotEmpty && prayerEmail.isNotEmpty) {
          return prayerEmail == myEmail;
        }
        if (myEmail.isNotEmpty && prayerEmail.isEmpty) {
          return _myPrayerIds.contains(item.id);
        }
        return prayerEmail.isEmpty || _myPrayerIds.contains(item.id);
      }
    }
    if (_myPrayerIds.contains(item.id)) return true;
    if (_prayerAuthorMap.containsKey(item.id)) return true;
    return false;
  }

  Future<void> _refreshCommentCountsOnly() async {
    try {
      final c = await PrayerWallService.fetchCommentCountsByPrayer();
      if (!mounted) return;
      setState(() => _commentCounts = c);
    } catch (_) {}
  }

  /// UI-only: blocks parallel embedded-login routes from Like/Comment/Post taps.
  static bool _embeddedLoginGateBusy = false;

  /// UI gate only: show Login Required, then open LoginScreen. No API changes.
  Future<bool> _ensureLoggedIn({
    required String message,
    VoidCallback? replaceOnSuccess,
  }) async {
    if (_isLoggedIn) return true;
    if (_embeddedLoginGateBusy) return false;

    final goLogin = await PrayerWallLoginRequiredDialog.show(
      context,
      message: message,
    );
    if (goLogin != true || !mounted) return false;

    _embeddedLoginGateBusy = true;
    try {
      final result = await Get.to<bool>(
        () => LoginScreen(
          hasSkip: false,
          popOnSuccess: true,
          replaceOnSuccess: replaceOnSuccess,
        ),
        routeName: LoginScreen.embeddedRouteName,
        preventDuplicates: true,
      );
      if (!mounted) return false;
      ReferralCodeBottomSheet.resetPresentationLock();
      await _loadAuthAndLocalName();
      return _isLoggedIn || result == true;
    } finally {
      _embeddedLoginGateBusy = false;
    }
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

  /// Comments: anyone may open/view. Posting still requires login via [_ensureCanPostComment].
  Future<bool> _ensureCanComment() => Future<bool>.value(true);

  /// UI gate only: login required before posting a comment.
  Future<bool> _ensureCanPostComment() {
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
      await PrayerWallLocalStore.markPrayerReported(item.id);
      if (!mounted) return;
      setState(() => _reportedPrayerIds.add(item.id));
      Constants.showToast('Report submitted successfully', 2000);
    } catch (e) {
      print('PrayerWall _openReport error: $e');
      if (!mounted) return;
      _showAppleToast(_looksOffline(e)
          ? 'No internet connection. Please try again.'
          : 'Could not submit report. Please try again.');
    }
  }

  /// Prayer `_id` from GET /api/prayers, e.g. `6a8fbde1beff837effb65eed`.
  static final RegExp _mongoObjectId = RegExp(r'^[a-fA-F0-9]{24}$');

  String? _mongoPrayerId(String? raw) {
    final id = (raw ?? '').trim();
    if (!_mongoObjectId.hasMatch(id)) return null;
    return id;
  }

  String? _blockPrayerId(PrayerWallItem item) => _mongoPrayerId(item.id);

  /// Additive: block target for two-way feed — their resolve user id when present.
  /// Falls back to prayer `_id` (existing POST shape).
  String? _blockTargetId(PrayerWallItem item) {
    return _mongoPrayerId(item.identityUserId) ??
        _mongoPrayerId(item.authorUserId) ??
        _blockPrayerId(item);
  }

  bool _itemMatchesBlockedId(PrayerWallItem p, String id) {
    if (id.isEmpty) return false;
    if (p.id == id) return true;
    if ((p.identityUserId ?? '').trim() == id) return true;
    if ((p.authorUserId ?? '').trim() == id) return true;
    return false;
  }

  bool _isItemBlocked(PrayerWallItem p) {
    for (final id in _blockedUserIds) {
      if (_itemMatchesBlockedId(p, id)) return true;
    }
    return false;
  }

  /// Resolve `user_id` from POST /api/users/resolve (used as block API `user_id`).
  Future<String?> _resolveUserIdForBlock() async {
    final id = await PrayerWallService.ensureIdentityUserId();
    final trimmed = (id ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    // Additive: Unblock can run before disk cache is ready; reuse session id.
    final fallback = (_resolveUserId ?? '').trim();
    return fallback.isEmpty ? null : fallback;
  }

  List<PrayerWallItem> get _blockedItemsOnWall =>
      _all.where(_isItemBlocked).toList();

  List<String> get _blockedIdsNotOnWall {
    return _blockedUserIds.where((id) {
      for (final p in _all) {
        if (_itemMatchesBlockedId(p, id)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openBlockedList() async {
    // Blocked list lives inside My Prayer — open that section first.
    if (!_showingHistory) {
      final allowed = await _ensureLoggedIn(
        message: 'Please log in to view blocked users.',
      );
      if (!allowed || !mounted) return;
      setState(() {
        _showingHistory = true;
        _showingBlocked = true;
        _myPrayerSort = 'Current';
        _historyError = null;
      });
      await _reloadMyPrayerHistory();
      return;
    }
    setState(() => _showingBlocked = !_showingBlocked);
  }

  void _selectMyPrayerTab({required bool blocked}) {
    if (!_showingHistory) return;
    setState(() {
      _showingBlocked = blocked;
      if (!blocked) _myPrayerSort = 'Current';
    });
  }

  String _avatarInitialsForName(String value) {
    final raw = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '?';
    if (raw.length == 1) return raw[0].toUpperCase();
    return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
  }

  PrayerWallItem? _prayerItemById(String id) {
    for (final p in _all) {
      if (p.id == id) return p;
    }
    for (final p in _historyItems) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> _confirmBlockAction({
    required bool unblock,
    String? displayName,
    String? profileImageUrl,
  }) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    const cream = Color(0xFFFFF9F3);
    const ink = Color(0xFF4B3423);
    const muted = Color(0xFF6B4E3D);
    const brown = Color(0xFF5C4033);
    final bg = isDark ? CommanColor.darkPrimaryColor : cream;
    final titleColor = isDark ? Colors.white : ink;
    final bodyColor = isDark ? Colors.white70 : muted;
    final accent = isDark ? const Color(0xFFE8C9A0) : brown;

    final name = (displayName ?? '').trim();
    final who = name.isNotEmpty ? name : 'this user';
    final photoUrl = (profileImageUrl ?? '').trim();
    final hasPhoto = photoUrl.isNotEmpty;
    final initials = _avatarInitialsForName(
      name.isNotEmpty ? name : 'Community member',
    );

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final dialogWidth = MediaQuery.sizeOf(ctx).width * 0.88;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: isDark
                          ? const Color(0xFF4A382C)
                          : brown.withValues(alpha: 0.15),
                      backgroundImage:
                          hasPhoto ? NetworkImage(photoUrl) : null,
                      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                      child: hasPhoto
                          ? null
                          : Text(
                              initials,
                              style: TextStyle(
                                color: isDark ? Colors.white : brown,
                                fontWeight: FontWeight.w700,
                                fontSize: 30,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      unblock ? 'Unblock $who?' : 'Block $who?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (unblock)
                      Text(
                        'Their prayers will show on your wall again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: bodyColor,
                        ),
                      )
                    else ...[
                      Text(
                        'You will no longer see prayers or activity from this user.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: bodyColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Their prayers will be removed from your Prayer Wall.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: bodyColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                backgroundColor: isDark
                                    ? Colors.transparent
                                    : cream,
                                side: BorderSide(
                                  color: brown.withValues(alpha: 0.55),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                unblock ? 'Unblock' : 'Block',
                                style: const TextStyle(
                                  fontSize: 16,
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
            ),
          ),
        );
      },
    );
    return ok == true;
  }

  Future<void> _unblockByPrayerId(String prayerId) async {
    final blockedId = _mongoPrayerId(prayerId);
    if (blockedId == null) return;
    final uid = await _resolveUserIdForBlock();
    if (uid == null) {
      _showAppleToast('Cannot unblock this user right now.');
      return;
    }
    final blockedItem = _prayerItemById(prayerId);
    final confirmed = await _confirmBlockAction(
      unblock: true,
      displayName:
          blockedItem != null ? _cardDisplayName(blockedItem) : null,
      profileImageUrl: blockedItem?.profileImage,
    );
    if (!confirmed || !mounted) return;
    try {
      await PrayerWallService.unblockUser(
        userId: uid,
        blockedUserId: blockedId,
      );
      await PrayerWallLocalStore.unmarkBlockedUser(
        blockedId,
        email: _userEmail,
      );
      if (!mounted) return;
      setState(() => _blockedUserIds.remove(blockedId));
      Constants.showToast('User unblocked', 2000);
    } catch (e) {
      print('PrayerWall _unblockByPrayerId error: $e');
      if (!mounted) return;
      _showAppleToast(_looksOffline(e)
          ? 'No internet connection. Please try again.'
          : 'Could not update block. Please try again.');
    }
  }

  Future<void> _openBlockUser(PrayerWallItem item) async {
    print('unique prayer id: ${item.id}');

    final prayerId = _blockPrayerId(item);
    final blockedId = _blockTargetId(item);
    if (blockedId == null) {
      _showAppleToast('Cannot block this user right now.');
      return;
    }

    final allowed = await _ensureLoggedIn(
      message: 'Please log in to block users.',
    );
    if (!allowed || !mounted) return;

    final uid = await _resolveUserIdForBlock();
    if (uid == null) {
      _showAppleToast('Cannot block this user right now.');
      return;
    }

    print('block user_id (resolve user_id): $uid');
    print('block blocked_user_id: $blockedId');

    final already = _isItemBlocked(item);
    final confirmed = await _confirmBlockAction(
      unblock: already,
      displayName: _cardDisplayName(item),
      profileImageUrl: item.profileImage,
    );
    if (!confirmed || !mounted) return;

    try {
      if (already) {
        await PrayerWallService.unblockUser(
          userId: uid,
          blockedUserId: blockedId,
        );
        if (prayerId != null && prayerId != blockedId) {
          try {
            await PrayerWallService.unblockUser(
              userId: uid,
              blockedUserId: prayerId,
            );
          } catch (_) {}
        }
        await PrayerWallLocalStore.unmarkBlockedUser(
          blockedId,
          email: _userEmail,
        );
        if (prayerId != null) {
          await PrayerWallLocalStore.unmarkBlockedUser(
            prayerId,
            email: _userEmail,
          );
        }
        if (!mounted) return;
        setState(() {
          _blockedUserIds.remove(blockedId);
          if (prayerId != null) _blockedUserIds.remove(prayerId);
        });
        Constants.showToast('User unblocked', 2000);
      } else {
        await PrayerWallService.blockUser(
          userId: uid,
          blockedUserId: blockedId,
        );
        await PrayerWallLocalStore.markBlockedUser(
          blockedId,
          email: _userEmail,
        );
        if (prayerId != null && prayerId != blockedId) {
          await PrayerWallLocalStore.markBlockedUser(
            prayerId,
            email: _userEmail,
          );
        }
        if (!mounted) return;
        setState(() {
          _blockedUserIds.add(blockedId);
          if (prayerId != null) _blockedUserIds.add(prayerId);
        });
        Constants.showToast('User blocked', 2000);
      }
    } catch (e) {
      print('PrayerWall _openBlockUser error: $e');
      if (!mounted) return;
      _showAppleToast(_looksOffline(e)
          ? 'No internet connection. Please try again.'
          : 'Could not update block. Please try again.');
    }
  }

  Future<void> _openPrayerActions(PrayerWallItem item) async {
    final isMine = _isMyPrayer(item);
    if (!isMine) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);

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
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (ctx) {
          final media = MediaQuery.of(ctx);
          final bottomInset = media.viewInsets.bottom;
          final topInset = media.padding.top;
          final maxSheetHeight =
              media.size.height - topInset - bottomInset - 24;
          const parchment = Color(0xFFF5EFE4);
          const ink = Color(0xFF4B3423);
          const muted = Color(0xFF6B4E3D);
          const fieldCream = Color(0xFFFFFFFF);
          const deleteBorder = Color(0xFFB85C4A);
          final sheetBg = isDark ? CommanColor.darkPrimaryColor : parchment;
          final titleColor = isDark ? Colors.white : ink;
          final labelColor = isDark ? Colors.white70 : brown;
          final fieldBg = isDark
              ? Colors.white.withValues(alpha: 0.06)
              : fieldCream;
          final fieldBorder = isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2D5C4);

          Widget quillIcon({double size = 42}) {
            return SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                'assets/edit_post_quill_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.edit_outlined,
                  size: size * 0.55,
                  color: isDark ? Colors.white70 : brown,
                ),
              ),
            );
          }

          Widget crossDivider() {
            final line = Color(0xFFD4C4B0).withValues(alpha: isDark ? 0.35 : 1);
            return Row(
              children: [
                Expanded(child: Divider(color: line, thickness: 1, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: isDark ? Colors.white54 : const Color(0xFF8B7355),
                  ),
                ),
                Expanded(child: Divider(color: line, thickness: 1, height: 1)),
              ],
            );
          }

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
                color: sheetBg,
                elevation: 14,
                shadowColor: Colors.black45,
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
                        child: Row(
                          children: [
                            quillIcon(size: 44),
                            Expanded(
                              child: Text(
                                'Edit Your Post',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx, 'cancel'),
                              icon: Icon(
                                Icons.close,
                                color: isDark ? Colors.white70 : brown,
                              ),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                        child: crossDivider(),
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
                                'TITLE',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Material(
                                color: fieldBg,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: fieldBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: TextField(
                                  controller: titleCtrl,
                                  maxLength: 120,
                                  cursorColor: brown,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : brown,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter a short title',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: fieldBg,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        14, 14, 14, 12),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Material(
                                color: fieldBg,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: fieldBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: TextField(
                                  controller: descCtrl,
                                  maxLines: 5,
                                  maxLength: 2000,
                                  onTap: scrollFieldIntoView,
                                  cursorColor: brown,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : brown,
                                    height: 1.35,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Write your prayer details…',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: fieldBg,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        14, 14, 14, 12),
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      Navigator.pop(ctx, 'delete'),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: deleteBorder,
                                    side: const BorderSide(
                                      color: deleteBorder,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, 'save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brown,
                                    foregroundColor: const Color(0xFFF5EFE4),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Save',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.edit, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 12,
                          color: isDark
                              ? Colors.white38
                              : muted.withValues(alpha: 0.45),
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
        await PrayerWallLocalStore.removePrayerDurationMeta(prayerId: item.id);
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

  /// Display name on a card. Own posts use the name saved with the prayer
  /// (API / local map), not a forced login-cache override.
  String _cardDisplayName(PrayerWallItem item) {
    final fromApi = (item.authorName ?? '').trim();
    final fromMap = (_prayerAuthorMap[item.id] ?? '').trim();

    if (_isMyPrayer(item)) {
      if (fromApi.isNotEmpty) return fromApi;
      if (fromMap.isNotEmpty) return fromMap;
      if (_viewerDisplayName.isNotEmpty) return _viewerDisplayName;
      return 'You';
    }

    if (item.isAnonymous) return 'Anonymous';
    if (fromApi.isNotEmpty) return fromApi;

    final authorId = (item.authorUserId ?? '').trim();
    final uid = (_userId ?? '').trim();
    if (authorId.isNotEmpty &&
        uid.isNotEmpty &&
        authorId == uid &&
        _viewerDisplayName.isNotEmpty) {
      return _viewerDisplayName;
    }
    if (fromMap.isNotEmpty) return fromMap;
    return 'Community member';
  }

  Widget _myPrayerSegmentChip({
    required String label,
    required bool selected,
    required Color brown,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? brown
              : (isDark ? Colors.white12 : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? brown
                : (isDark ? const Color(0xFF5A4638) : Colors.grey.shade400),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white : brown),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedList({
    required Color brown,
    required bool isDark,
  }) {
    final items = _blockedItemsOnWall;
    final leftover = _blockedIdsNotOnWall;
    final count = _blockedUserIds.length;
    final cardBg = isDark ? const Color(0xFF2C2118) : const Color(0xFFFFF9F3);
    final border = isDark ? const Color(0xFF5A4638) : const Color(0xFFE2D2C0);
    final ink = isDark ? Colors.white : const Color(0xFF3D2914);
    final muted =
        isDark ? const Color(0xFFE8DDD0) : const Color(0xFF6B5344);
    final peach = isDark ? const Color(0xFF4A382C) : const Color(0xFFF3E4D8);

    String initials(String name) {
      final raw = name.trim().replaceAll(RegExp(r'\s+'), '');
      if (raw.isEmpty) return '?';
      if (raw.length == 1) return raw[0].toUpperCase();
      return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
    }

    Widget unblockChip(VoidCallback onTap) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D2E24) : peach,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: brown.withValues(alpha: isDark ? 0.45 : 0.35),
              ),
            ),
            child: Text(
              'Unblock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? const Color(0xFFE8C9A0) : brown,
              ),
            ),
          ),
        ),
      );
    }

    Widget blockedCard({
      required String name,
      required String subtitle,
      required VoidCallback onUnblock,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: peach,
              child: Text(
                initials(name),
                style: TextStyle(
                  color: isDark ? Colors.white : brown,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            unblockChip(onUnblock),
          ],
        ),
      );
    }

    if (count == 0) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
        children: [
          const SizedBox(height: 48),
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: peach,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_outlined,
                size: 36,
                color: isDark ? const Color(0xFFE8C9A0) : brown,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No blocked profiles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'People you block will appear here.\nYou can unblock them anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: muted,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A2C22) : peach,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: brown.withValues(alpha: isDark ? 0.35 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A382C) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFE8C9A0) : brown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You blocked $count ${count == 1 ? 'person' : 'people'}',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap Unblock to see their prayers again.',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          final name = _cardDisplayName(item);
          final title =
              item.title.isNotEmpty ? item.title : item.description;
          return blockedCard(
            name: name,
            subtitle: title,
            onUnblock: () => _unblockByPrayerId(item.id),
          );
        }),
        ...leftover.map((id) {
          return blockedCard(
            name: 'Blocked prayer',
            subtitle: 'This prayer is hidden from your wall.',
            onUnblock: () => _unblockByPrayerId(id),
          );
        }),
      ],
    );
  }

  /// UI-only: header uses profile photo (or person icon) — same tap target.
  Widget _buildHeaderProfileIcon() {
    final url = (_viewerProfileImage ?? '').trim();
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_outline,
            color: Colors.white,
          ),
        ),
      );
    }
    return const Icon(
      Icons.person_outline,
      color: Colors.white,
    );
  }

  /// Additive: device-posted ids can be missing from identity GET; fill from wall
  /// cache and existing `fetchPrayersByPrayerIds` without changing identity flow.
  Future<List<PrayerWallItem>> _mergeDevicePostedIntoHistory({
    required List<PrayerWallItem> fromIdentity,
    required Set<String> ownedIds,
    String? accountEmail,
  }) async {
    final want = (accountEmail ?? _userEmail ?? '').trim().toLowerCase();
    final seen = fromIdentity.map((p) => p.id).toSet();
    final localIds = {...ownedIds, ...await PrayerWallLocalStore.loadMyPrayerIds()};
    final missing = localIds.where((id) => !seen.contains(id)).toSet();
    if (missing.isEmpty) return fromIdentity;

    final merged = List<PrayerWallItem>.from(fromIdentity);
    for (final p in _all) {
      if (!missing.contains(p.id)) continue;
      if (want.isNotEmpty && !_prayerMatchesLoginEmail(p, want)) continue;
      merged.add(p);
      seen.add(p.id);
    }

    final stillMissing = missing.where((id) => !seen.contains(id)).toList();
    if (stillMissing.isNotEmpty) {
      try {
        final fetched =
            await PrayerWallService.fetchPrayersByPrayerIds(stillMissing);
        for (final p in fetched) {
          if (want.isNotEmpty && !_prayerMatchesLoginEmail(p, want)) continue;
          if (seen.add(p.id)) merged.add(p);
        }
      } catch (e) {
        print('PrayerWall merge device-posted into My Prayer: $e');
      }
    }

    merged.sort((a, b) {
      final am = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bm = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bm.compareTo(am);
    });
    return merged;
  }

  /// UI-only: My Prayer — load prayers I posted (ids from local store + ?prayerId=).
  Future<void> _openMyPrayerHistory() async {
    if (_openingHistory) return;
    if (_showingHistory) {
      setState(() {
        _showingHistory = false;
        _showingBlocked = false;
        _myPrayerSort = 'Current';
        _historyError = null;
      });
      return;
    }

    final allowed = await _ensureLoggedIn(
      message: 'Please log in to view your prayers.',
    );
    if (!allowed || !mounted) return;

    setState(() {
      _showingHistory = true;
      _showingBlocked = false;
      _myPrayerSort = 'Current';
    });
    await _reloadMyPrayerHistory();
  }

  Future<void> _reloadMyPrayerHistory() async {
    if (_openingHistory) return;
    _openingHistory = true;
    try {
      if (!mounted) return;
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });

      if (!mounted) return;
      await _syncMyPrayerIdsForAccount(_userEmail);
      if ((_resolveUserId ?? '').trim().isEmpty) {
        await _hydrateResolveUserId();
      }
      if (!mounted) return;

      // Prefer rebuilt ids (wall email/identity + device-owned) after re-login.
      final postedIds = await PrayerWallLocalStore.loadMyPrayerIds();
      final ownedFallback = await PrayerWallLocalStore.loadOwnedPrayerIds();
      final effectiveOwned = postedIds.isNotEmpty
          ? postedIds
          : ownedFallback;
      await PrayerWallLocalStore.saveMyPrayerIds(effectiveOwned);
      if (!mounted) return;

      final fromIdentity =
          await PrayerWallService.fetchPrayersByIdentityUserId();
      if (!mounted) return;
      final myEmail = (_userEmail ?? '').trim().toLowerCase();
      final mine = myEmail.isEmpty
          ? fromIdentity
          : fromIdentity
              .where((p) => _prayerMatchesLoginEmail(p, myEmail))
              .toList();
      final historyItemsRaw = await _mergeDevicePostedIntoHistory(
        fromIdentity: mine,
        ownedIds: effectiveOwned,
        accountEmail: myEmail.isEmpty ? null : myEmail,
      );
      // Additive: include wall posts matching this login (visible on Wall but
      // missing from identity GET after logout → login).
      var wallForMerge = _all;
      if (wallForMerge.isEmpty && myEmail.isNotEmpty) {
        try {
          wallForMerge = await PrayerWallService.fetchPrayers();
          if (mounted && wallForMerge.isNotEmpty) {
            setState(() => _all = wallForMerge);
            await _rebuildMyPrayerIdsForCurrentAccount();
          }
        } catch (_) {}
      }
      final seen = historyItemsRaw.map((p) => p.id).toSet();
      final mergedHistory = List<PrayerWallItem>.from(historyItemsRaw);
      if (myEmail.isNotEmpty) {
        for (final p in wallForMerge) {
          if (seen.contains(p.id)) continue;
          if (!_prayerMatchesLoginEmail(p, myEmail)) continue;
          mergedHistory.add(p);
          seen.add(p.id);
        }
      }
      mergedHistory.sort((a, b) {
        final am = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bm = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am);
      });
      final historyItems = myEmail.isEmpty
          ? mergedHistory
          : mergedHistory
              .where((p) => _prayerMatchesLoginEmail(p, myEmail))
              .toList();
      final ids = historyItems.map((p) => p.id).toSet();
      if (ids.isNotEmpty) {
        await PrayerWallLocalStore.saveMyPrayerIds(ids);
      }

      var fromHistoryApi = <PrayerWallItem>[];
      try {
        fromHistoryApi = await PrayerWallService.fetchPrayerHistory();
      } catch (e) {
        print('PrayerWall fetchPrayerHistory: $e');
      }
      if (!mounted) return;
      final historyMine = myEmail.isEmpty
          ? fromHistoryApi
          : fromHistoryApi.where((p) {
              final e = (p.email ?? '').trim().toLowerCase();
              if (e.isEmpty) return true;
              return e == myEmail;
            }).toList();
      final expired = <PrayerWallItem>[];
      final expiredSeen = <String>{};
      void addExpired(PrayerWallItem p) {
        if (expiredSeen.add(p.id)) expired.add(p);
      }
      final activeIds = historyItems
          .where((p) => !p.isDurationExpired)
          .map((p) => p.id)
          .toSet();
      for (final p in historyItems) {
        if (p.isDurationExpired) addExpired(p);
      }
      for (final p in historyMine) {
        if (p.isDurationExpired) {
          addExpired(p);
        } else if (!activeIds.contains(p.id) &&
            p.expiresAt == null &&
            (p.prayerDuration == null || p.prayerDuration! <= 0)) {
          // History endpoint row with no duration fields: treat as expired.
          addExpired(p);
        }
      }
      expired.sort((a, b) {
        final am = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bm = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bm.compareTo(am);
      });

      setState(() {
        _myPrayerIds = ids;
        _historyItems = historyItems;
        _expiredHistoryItems = expired;
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        _historyError = _friendlyError(e);
        _historyItems = [];
        _expiredHistoryItems = [];
      });
    } finally {
      _openingHistory = false;
    }
  }

  Future<void> _openPostPrayerScreen({bool showSuccessToast = false}) async {
    if (_openingPostPrayer) return;
    if (mounted) setState(() => _openingPostPrayer = true);
    try {
      final isConnected = await InternetConnection().hasInternetAccess;
      if (!isConnected) {
        Constants.showToast('No internet connection', 1000);
        return;
      }
      if (!mounted) return;

      if (!_isLoggedIn) {
        final allowed = await _ensureLoggedIn(
          message:
              'Please log in to support this prayer request and leave a comment.',
          replaceOnSuccess: () {
            Get.off(
              () => const PostPrayerScreen(),
              routeName: PostPrayerScreen.routeName,
              preventDuplicates: true,
              transition: Transition.noTransition,
              duration: Duration.zero,
            );
          },
        );
        if (!allowed || !mounted) return;
        // Login was replaced with Post a Prayer — do not push it again.
        return;
      }

      if (!mounted) return;
      final posted = await Get.to<bool>(
        () => const PostPrayerScreen(),
        routeName: PostPrayerScreen.routeName,
        preventDuplicates: true,
      );
      if (posted == true && mounted) {
        await _reloadLocalDisplayName();
        await _hydratePrayerAuthorsFromDisk();
        await _hydrateMyPrayerIdsFromDisk();
        await _refresh();
        if (_showingHistory && mounted) {
          await _reloadMyPrayerHistory();
        }
        if (showSuccessToast && mounted) {
          _showAppleToast('Prayer posted successfully.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _openingPostPrayer = false);
      } else {
        _openingPostPrayer = false;
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
      floatingActionButton: (_hideFabForInput || _showingBlocked)
          ? null
          : FloatingActionButton(
              backgroundColor: isDark ? brown.withValues(alpha: 0.9) : brown,
              foregroundColor: Colors.white,
              elevation: isDark ? 8 : 6,
              onPressed: _openingPostPrayer ? null : () => _openPostPrayerScreen(),
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
                    onPressed: () {
                      if (_showingHistory && _showingBlocked) {
                        setState(() => _showingBlocked = false);
                        return;
                      }
                      if (_showingHistory) {
                        setState(() {
                          _showingHistory = false;
                          _showingBlocked = false;
                          _myPrayerSort = 'Current';
                          _historyError = null;
                        });
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _showingHistory ? 'My Profile' : 'Prayer Wall',
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
                  // My Prayer: no header action icons (back only).
                  if (_showingHistory)
                    const SizedBox(width: 48)
                  else
                    IconButton(
                      tooltip: 'My Profile',
                      icon: _buildHeaderProfileIcon(),
                      onPressed:
                          _openingHistory ? null : _openMyPrayerHistory,
                    ),
                ],
              ),
            ),
            if (_showingHistory)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _myPrayerSegmentChip(
                        label: 'My Prayers',
                        selected: !_showingBlocked,
                        brown: brown,
                        isDark: isDark,
                        onTap: () => _selectMyPrayerTab(blocked: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _myPrayerSegmentChip(
                        label: _blockedUserIds.isEmpty
                            ? 'Blocked'
                            : 'Blocked (${_blockedUserIds.length})',
                        selected: _showingBlocked,
                        brown: brown,
                        isDark: isDark,
                        onTap: () => _selectMyPrayerTab(blocked: true),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_showingHistory)
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
            if (!_showingHistory)
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
            if (_showingHistory && !_showingBlocked)
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
                    value: _myPrayerSort,
                    underline: const SizedBox.shrink(),
                    dropdownColor: isDark ? CommanColor.darkPrimaryColor : Colors.white,
                    items: _myPrayerSortOptions
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
                      setState(() => _myPrayerSort = v);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showingBlocked
                  ? _buildBlockedList(brown: brown, isDark: isDark)
                  : (_showingHistory ? _historyLoading : _loading)
                  ? const Center(child: CircularProgressIndicator())
                  : (_showingHistory ? _historyError : _error) != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (_showingHistory ? _historyError : _error)!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _showingHistory
                                      ? _reloadMyPrayerHistory
                                      : _refresh,
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
                          onRefresh: _showingHistory
                              ? _reloadMyPrayerHistory
                              : _refresh,
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
                                        _showingExpired
                                            ? 'No expired prayers yet.'
                                            : _showingHistory
                                            ? 'No prayers in My Prayer yet.'
                                            : 'No prayers in this category yet.',
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
                                      displayName: _cardDisplayName(item),
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
                                      isReported:
                                          _reportedPrayerIds.contains(item.id),
                                      onBlock: () => _openBlockUser(item),
                                      isBlocked: _isItemBlocked(item),
                                      canBlock: !_isMyPrayer(item),
                                      likeCount: _likeCounts[item.id] ?? 0,
                                      liked: _isLiked(item.id),
                                      likeBusy:
                                          _likeToggleBusy.contains(item.id),
                                      onToggleLike: () => _toggleLike(item),
                                      commentCount:
                                          _commentCounts[item.id] ?? 0,
                                      onEnsureCanComment: _ensureCanComment,
                                      onEnsureCanPostComment:
                                          _ensureCanPostComment,
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
    this.isReported = false,
    required this.onBlock,
    this.isBlocked = false,
    this.canBlock = false,
    required this.likeCount,
    required this.liked,
    required this.likeBusy,
    required this.onToggleLike,
    required this.commentCount,
    required this.onEnsureCanComment,
    required this.onEnsureCanPostComment,
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
  final bool isReported;
  final VoidCallback onBlock;
  final bool isBlocked;
  final bool canBlock;
  final int likeCount;
  final bool liked;
  final bool likeBusy;
  final VoidCallback onToggleLike;
  final int commentCount;
  final Future<bool> Function() onEnsureCanComment;
  final Future<bool> Function() onEnsureCanPostComment;
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

  Future<void> _showCardMoreMenu({
    required Color brown,
    required bool isDark,
  }) async {
    const cream = Color(0xFFFFF9F3);
    const ink = Color(0xFF4B3423);
    const muted = Color(0xFF6B4E3D);
    final sheetBg = isDark ? const Color(0xFF2C2118) : cream;
    final titleColor = isDark ? Colors.white : ink;
    final subtitleColor = isDark ? Colors.white70 : muted;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: sheetBg,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white24
                          : const Color(0xFFD0C4B4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      widget.isReported
                          ? Icons.flag_rounded
                          : Icons.flag_outlined,
                      color: widget.isReported
                          ? const Color(0xFFC45C3A)
                          : (isDark ? Colors.white : brown),
                    ),
                    title: Text(
                      'Report Prayer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    subtitle: Text(
                      'Flag this prayer for review',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    onTap: () => Navigator.of(ctx).pop('report'),
                  ),
                  if (widget.canBlock)
                    ListTile(
                      leading: Icon(
                        widget.isBlocked
                            ? Icons.block_rounded
                            : Icons.block_outlined,
                        color: widget.isBlocked
                            ? const Color(0xFFC45C3A)
                            : (isDark ? Colors.white : brown),
                      ),
                      title: Text(
                        widget.isBlocked ? 'Unblock User' : 'Block User',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      subtitle: Text(
                        widget.isBlocked
                            ? 'Show their prayers on your wall again'
                            : 'Hide prayers from this user',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                      onTap: () => Navigator.of(ctx).pop('block'),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFE8C9A0)
                              : brown,
                          side: BorderSide(
                            color: brown.withValues(alpha: 0.55),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (action == 'report') {
      widget.onReport();
    } else if (action == 'block') {
      widget.onBlock();
    }
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
                  // UI-only: owner sees Edit; others see ⋮ (Report / Block).
                  if (isMine)
                    InkWell(
                      onTap: widget.onOpen,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: isDark ? Colors.white : brown,
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _showCardMoreMenu(
                        brown: brown,
                        isDark: isDark,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_vert,
                          size: 22,
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
                                      ? Icons.volunteer_activism
                                      : Icons.volunteer_activism_outlined,
                                  color: liked
                                      ? brown
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
                              const SizedBox(width: 6),
                              Text(
                                'Prayed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
                              Text(
                                '$commentCount',
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
                ],
              ),
              if (_commentsOpen)
                PrayerWallCommentsSheet(
                  key: ValueKey('comments_${item.id}'),
                  prayerId: item.id,
                  titlePreview:
                      item.title.isNotEmpty ? item.title : item.description,
                  embedded: true,
                  onEnsureCanPost: widget.onEnsureCanPostComment,
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
