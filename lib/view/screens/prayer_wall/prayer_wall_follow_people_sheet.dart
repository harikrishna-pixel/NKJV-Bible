import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Followers / Following list. IDs come from existing GET follow APIs.
/// Name + photo are matched from wall prayers only — no name API.
Future<void> showPrayerWallFollowPeopleSheet({
  required BuildContext context,
  required String title,
  required List<String> userIds,
  required List<PrayerWallItem> wallPrayers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _PrayerWallFollowPeopleSheet(
        title: title,
        userIds: userIds,
        wallPrayers: wallPrayers,
      );
    },
  );
}

class _FollowPersonRow {
  const _FollowPersonRow({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String? photoUrl;
}

class _PrayerWallFollowPeopleSheet extends StatelessWidget {
  const _PrayerWallFollowPeopleSheet({
    required this.title,
    required this.userIds,
    required this.wallPrayers,
  });

  final String title;
  final List<String> userIds;
  final List<PrayerWallItem> wallPrayers;

  _FollowPersonRow _rowFor(String userId) {
    for (final p in wallPrayers) {
      if (p.isAnonymous) continue;
      final identity = (p.identityUserId ?? '').trim();
      final author = (p.authorUserId ?? '').trim();
      if (identity != userId && author != userId) continue;
      final name = (p.authorName ?? '').trim();
      final photo = (p.profileImage ?? '').trim();
      return _FollowPersonRow(
        userId: userId,
        name: name.isEmpty ? 'Community member' : name,
        photoUrl: photo.isEmpty ? null : photo,
      );
    }
    return _FollowPersonRow(userId: userId, name: 'Community member');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    const brown = Color(0xFF5C4033);
    final bg = isDark ? CommanColor.darkPrimaryColor : const Color(0xFFFFF9F3);
    final ink = isDark ? Colors.white : brown;
    final rows = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .map(_rowFor)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : brown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: ink),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Text(
                            title == 'Followers'
                                ? 'No followers yet.'
                                : 'Not following anyone yet.',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : brown,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white12
                                : brown.withOpacity(0.08),
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            final photo = (row.photoUrl ?? '').trim();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: brown.withOpacity(0.12),
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? Text(
                                        _initials(row.name),
                                        style: const TextStyle(
                                          fontFamily: 'Georgia',
                                          fontWeight: FontWeight.w500,
                                          color: brown,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                row.name,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontWeight: FontWeight.w500,
                                  color: ink,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
