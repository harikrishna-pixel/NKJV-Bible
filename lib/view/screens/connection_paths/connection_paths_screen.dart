import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/my_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_details_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> openConnectionPath(ConnectionPath path) async {
  await Get.to(
    () => PathDetailsScreen(path: path),
    transition: Transition.cupertino,
  );
}

/// Screen 1 — Choose a Connection Path.
class ConnectionPathsScreen extends StatelessWidget {
  const ConnectionPathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = ConnectionPathsData.featured;
    return ParchmentScaffold(
      title: 'Connection Paths',
      actions: [
        IconButton(
          tooltip: 'My Paths',
          onPressed: () => Get.to(
            () => const MyPathsScreen(),
            transition: Transition.cupertino,
          ),
          icon: const Icon(Icons.bookmark_border_rounded, color: Pc.ink),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          const SizedBox(height: 6),
          const Text(
            'Choose a\nConnection Path',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Pc.serif,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Pc.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grow closer to God\none day at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Pc.serif,
              fontSize: 15,
              height: 1.35,
              color: Pc.muted,
            ),
          ),
          const SizedBox(height: 20),
          ...featured.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeaturedPathTile(path: p),
            ),
          ),
          ParchmentCard(
            onTap: () => Get.to(
              () => const AllConnectionPathsScreen(),
              transition: Transition.cupertino,
            ),
            child: const Row(
              children: [
                BronzeBadge(icon: Icons.menu_book_rounded, size: 42),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'View All Paths',
                    style: TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Pc.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Pc.brown),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Start a path and build your\ndaily connection with God.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Pc.serif,
              fontSize: 14,
              height: 1.4,
              color: Pc.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedPathTile extends StatelessWidget {
  const _FeaturedPathTile({required this.path});

  final ConnectionPath path;

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      onTap: () => openConnectionPath(path),
      child: Row(
        children: [
          BronzeBadge(icon: path.icon, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.durationLabel,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 13,
                    color: Pc.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  path.title,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Pc.brown),
        ],
      ),
    );
  }
}

/// Screen 2 — All Connection Paths with duration filter.
class AllConnectionPathsScreen extends StatefulWidget {
  const AllConnectionPathsScreen({super.key});

  @override
  State<AllConnectionPathsScreen> createState() =>
      _AllConnectionPathsScreenState();
}

class _AllConnectionPathsScreenState extends State<AllConnectionPathsScreen> {
  int? _days;
  final Map<String, String> _status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = <String, String>{};
    for (final p in ConnectionPathsData.all) {
      if (await ConnectionPathProgress.isCompleted(p.id)) {
        map[p.id] = 'Completed';
      } else if (await ConnectionPathProgress.isStarted(p.id)) {
        final day = await ConnectionPathProgress.currentDay(p);
        map[p.id] = 'Day ${day + 1} of ${p.durationDays}';
      }
    }
    if (!mounted) return;
    setState(() {
      _status
        ..clear()
        ..addAll(map);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ConnectionPathsData.forDuration(_days);
    return ParchmentScaffold(
      title: 'All Connection Paths',
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _days == null,
                  onTap: () => setState(() => _days = null),
                ),
                ...ConnectionPathsData.durations.map(
                  (d) => _FilterChip(
                    label: '$d Days',
                    selected: _days == d,
                    onTap: () => setState(() => _days = d),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = list[i];
                final status = _status[p.id];
                return ParchmentCard(
                  onTap: () async {
                    await openConnectionPath(p);
                    await _load();
                  },
                  child: Row(
                    children: [
                      BronzeBadge(icon: p.icon, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.durationLabel,
                              style: const TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 12.5,
                                color: Pc.muted,
                              ),
                            ),
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Pc.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status ?? p.tagline,
                              style: TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 13,
                                fontWeight: status != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: status != null ? Pc.brown : Pc.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'Completed')
                        const CheckCircle(size: 26)
                      else
                        const Icon(Icons.chevron_right, color: Pc.brown),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Pc.brown : Pc.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? Pc.brown : Pc.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Pc.serif,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Pc.ink,
            ),
          ),
        ),
      ),
    );
  }
}
