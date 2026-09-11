import 'dart:async';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Additive: Prayer Wall user profile (tap name/avatar on another prayer).
/// Uses Follow APIs + prayers already loaded on the wall.
class PrayerWallUserProfileScreen extends StatefulWidget {
  const PrayerWallUserProfileScreen({
    super.key,
    required this.profileUserId,
    required this.displayName,
    this.profileImageUrl,
    this.viewerUserId,
    this.wallPrayers = const [],
    this.canBlock = false,
    this.isBlocked = false,
    this.onBlockUser,
  });

  final String profileUserId;
  final String displayName;
  final String? profileImageUrl;
  /// Logged-in viewer's resolve `user_id` (for follow).
  final String? viewerUserId;
  final List<PrayerWallItem> wallPrayers;
  /// Additive: same Block User flow as prayer card ⋮ menu.
  final bool canBlock;
  final bool isBlocked;
  final Future<bool> Function()? onBlockUser;

  @override
  State<PrayerWallUserProfileScreen> createState() =>
      _PrayerWallUserProfileScreenState();
}

class _PrayerWallUserProfileScreenState
    extends State<PrayerWallUserProfileScreen> {
  static const _brown = Color(0xFF5C4033);

  bool _loading = true;
  bool _followBusy = false;
  bool _isFollowing = false;
  bool _blockBusy = false;
  late bool _isBlocked;
  int _followersCount = 0;
  int _followingCount = 0;
  /// Additive: Recent Prayers — expanded cards show full text.
  final Set<String> _expandedRecentPrayerIds = {};

  List<PrayerWallItem> get _recentPrayers {
    final pid = widget.profileUserId.trim();
    if (pid.isEmpty) return const [];
    return widget.wallPrayers.where((p) {
      final a = (p.authorUserId ?? '').trim();
      final i = (p.identityUserId ?? '').trim();
      return a == pid || i == pid;
    }).toList();
  }

  bool get _isOwnProfile {
    final v = (widget.viewerUserId ?? '').trim();
    final p = widget.profileUserId.trim();
    return v.isNotEmpty && p.isNotEmpty && v == p;
  }

  bool get _showBlockMenu =>
      widget.canBlock && !_isOwnProfile && widget.onBlockUser != null;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.isBlocked;
    _loadFollowState();
  }

  Future<void> _onBlockMenuSelected() async {
    if (!_showBlockMenu || _blockBusy) return;
    setState(() => _blockBusy = true);
    final wasBlocked = _isBlocked;
    try {
      final ok = await widget.onBlockUser!();
      if (!mounted || !ok) return;
      setState(() => _isBlocked = !wasBlocked);
      // After Block, leave profile so wall hides their prayers (same as card).
      if (!wasBlocked) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _blockBusy = false);
    }
  }

  Future<void> _loadFollowState() async {
    final profileId = widget.profileUserId.trim();
    final viewerId = (widget.viewerUserId ?? '').trim();
    if (profileId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final followers =
          await PrayerWallService.fetchFollowers(userId: profileId);
      final following =
          await PrayerWallService.fetchFollowing(userId: profileId);
      var isFollowing = false;
      if (viewerId.isNotEmpty && !_isOwnProfile) {
        final mine = await PrayerWallService.fetchFollowing(userId: viewerId);
        isFollowing = mine.followingUserIds.contains(profileId);
      }
      if (!mounted) return;
      setState(() {
        _followersCount = followers.count;
        _followingCount = following.count;
        _isFollowing = isFollowing;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final viewerId = (widget.viewerUserId ?? '').trim();
    final profileId = widget.profileUserId.trim();
    if (viewerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to follow.')),
      );
      return;
    }
    if (profileId.isEmpty || _isOwnProfile || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      if (_isFollowing) {
        await PrayerWallService.unfollowUser(
          userId: viewerId,
          followingUserId: profileId,
        );
        if (!mounted) return;
        setState(() {
          _isFollowing = false;
          if (_followersCount > 0) _followersCount -= 1;
        });
      } else {
        await PrayerWallService.followUser(
          userId: viewerId,
          followingUserId: profileId,
        );
        if (!mounted) return;
        setState(() {
          _isFollowing = true;
          _followersCount += 1;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update follow. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  String _initials(String value) {
    final raw = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '?';
    if (raw.length == 1) return raw[0].toUpperCase();
    return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
  }

  String _timeLabel(PrayerWallItem item) {
    final created = item.createdAt;
    if (created == null) return '';
    final diff = DateTime.now().difference(created.toLocal());
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
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
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);
    final name = widget.displayName.trim().isEmpty
        ? 'Community member'
        : widget.displayName.trim();
    final photo = (widget.profileImageUrl ?? '').trim();
    final recent = _recentPrayers;

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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: isDark ? Colors.white : _brown),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : _brown,
                        ),
                      ),
                    ),
                    if (_showBlockMenu)
                      PopupMenuButton<String>(
                        enabled: !_blockBusy,
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white : _brown,
                        ),
                        color: isDark
                            ? const Color(0xFF2C241C)
                            : const Color(0xFFFFFBF5),
                        onSelected: (value) {
                          if (value == 'block') {
                            unawaited(_onBlockMenuSelected());
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem<String>(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(
                                  _isBlocked
                                      ? Icons.block_rounded
                                      : Icons.block_outlined,
                                  size: 20,
                                  color: _isBlocked
                                      ? const Color(0xFFC45C3A)
                                      : (isDark ? Colors.white : _brown),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isBlocked
                                      ? 'Unblock User'
                                      : 'Block User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : _brown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: isDark
                                    ? const Color(0xFF4A382C)
                                    : _brown.withOpacity(0.18),
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                onBackgroundImageError:
                                    photo.isNotEmpty ? (_, __) {} : null,
                                child: photo.isNotEmpty
                                    ? null
                                    : Text(
                                        _initials(name),
                                        style: TextStyle(
                                          color:
                                              isDark ? Colors.white : _brown,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : _brown,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Prayer Wall member',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : _brown.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : _brown.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                _statCell('${recent.length}', 'Prayers Shared'),
                                _divider(isDark),
                                _statCell('$_followersCount', 'Followers'),
                                _divider(isDark),
                                _statCell('$_followingCount', 'Following'),
                              ],
                            ),
                          ),
                          if (!_isOwnProfile) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _followBusy ? null : _toggleFollow,
                                icon: Icon(
                                  _isFollowing
                                      ? Icons.check
                                      : Icons.person_add_alt_1,
                                  size: 18,
                                ),
                                label: Text(
                                  _followBusy
                                      ? 'Please wait…'
                                      : (_isFollowing ? 'Followed' : 'Follow'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? (isDark
                                          ? const Color(0xFF4A382C)
                                          : const Color(0xFFE8D9C8))
                                      : _brown,
                                  foregroundColor: _isFollowing
                                      ? (isDark ? Colors.white : _brown)
                                      : Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            'Recent Prayers',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _brown,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recent.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No prayers to show yet.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade700,
                                ),
                              ),
                            )
                          else
                            ...recent.take(20).map((p) {
                              final title = p.title.trim();
                              final ai = (PrayerDualDescription.aiPrayer(
                                          p.description) ??
                                      '')
                                  .trim();
                              final my = (PrayerDualDescription.myWords(
                                          p.description) ??
                                      '')
                                  .trim();
                              final plain = PrayerDualDescription.isDual(
                                      p.description)
                                  ? ''
                                  : p.description.trim();
                              final subtitle = ai.isNotEmpty
                                  ? ai
                                  : (my.isNotEmpty ? my : plain);
                              final showTitle = title.isNotEmpty;
                              final showSubtitle = subtitle.isNotEmpty &&
                                  subtitle != title;
                              final expanded =
                                  _expandedRecentPrayerIds.contains(p.id);
                              final fallback = showTitle
                                  ? title
                                  : (showSubtitle ? subtitle : '');
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (expanded) {
                                        _expandedRecentPrayerIds.remove(p.id);
                                      } else {
                                        _expandedRecentPrayerIds.add(p.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2C2118)
                                          : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF5A4638)
                                            : _brown.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (showTitle && showSubtitle) ...[
                                          Text(
                                            title,
                                            maxLines: expanded ? null : 1,
                                            overflow: expanded
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.35,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF3D2914),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            subtitle,
                                            maxLines: expanded ? null : 2,
                                            overflow: expanded
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.35,
                                              fontWeight: FontWeight.w400,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF5C4A3A),
                                            ),
                                          ),
                                        ] else
                                          Text(
                                            fallback,
                                            maxLines: expanded ? null : 2,
                                            overflow: expanded
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.35,
                                              fontWeight: showTitle
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF3D2914),
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _timeLabel(p),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 34,
      color: isDark ? Colors.white24 : _brown.withOpacity(0.15),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: _brown.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
