import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/my_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_details_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> openConnectionPath(ConnectionPath path) async {
  final started = await ConnectionPathProgress.isStarted(path.id);
  final completed = await ConnectionPathProgress.isCompleted(path.id);
  if (started && !completed) {
    await Get.to(
      () => PathOverviewScreen(path: path),
      transition: Transition.cupertino,
    );
    return;
  }
  await Get.to(
    () => PathDetailsScreen(path: path),
    transition: Transition.cupertino,
  );
}

/// Decode every cover once so switching category / tab doesn't show a blank
/// frame while a new card image loads.
void precacheConnectionCovers(BuildContext context) {
  for (final asset in ConnectionPathsData.coverAssets.values.toSet()) {
    precacheImage(AssetImage(asset), context);
  }
}

/// Mockup screen 1 — Connection Paths home.
class ConnectionPathsScreen extends StatefulWidget {
  const ConnectionPathsScreen({super.key});

  @override
  State<ConnectionPathsScreen> createState() => _ConnectionPathsScreenState();
}

class _ConnectionPathsScreenState extends State<ConnectionPathsScreen> {
  bool _loading = true;
  List<ConnectionPath> _paths = const [];
  String _category = 'all';
  ConnectionPath? _continue;
  int _continueDay = 0;
  int _continueDone = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheConnectionCovers(context);
  }

  Future<void> _load() async {
    final paths = await ConnectionPathsData.load();
    final active = await ConnectionPathProgress.activePaths();
    ConnectionPath? cont;
    var day = 0;
    var done = 0;
    if (active.isNotEmpty) {
      cont = active.first;
      day = await ConnectionPathProgress.currentDay(cont);
      done = (await ConnectionPathProgress.completedDays(cont)).length;
    }
    if (!mounted) return;
    setState(() {
      _paths = paths;
      _continue = cont;
      _continueDay = day;
      _continueDone = done;
      _loading = false;
    });
  }

  List<ConnectionPath> get _filtered =>
      ConnectionPathsData.forCategory(_category);

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: 'Connection Paths',
      backgroundAsset: ConnectionPathsData.pageBgAsset,
      scrim: true,
      actions: [
        IconButton(
          tooltip: 'My Connection Paths',
          onPressed: () async {
            await Get.to(
              () => const MyPathsScreen(),
              transition: Transition.cupertino,
            );
            await _load();
          },
          icon: const Icon(Icons.folder_outlined, color: Pc.ink),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : RefreshIndicator(
              color: Pc.brown,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  _HeroBanner(),
                  const SizedBox(height: 16),
                  if (_continue != null) ...[
                    const _SectionTitle('Continue Your Journey'),
                    const SizedBox(height: 8),
                    _ContinueCard(
                      path: _continue!,
                      day: _continueDay,
                      done: _continueDone,
                      onTap: () async {
                        await openConnectionPath(_continue!);
                        await _load();
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  const _SectionTitle('Explore by Category'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ConnectionPathsData.categoryChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = ConnectionPathsData.categoryChips[i];
                        final selected = _category == c.id;
                        return ParchmentChoiceChip(
                          label: c.label,
                          selected: selected,
                          onTap: () => setState(() => _category = c.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionTitle('Featured Connection Paths')),
                      TextButton(
                        onPressed: () => Get.to(
                          () => const AllConnectionPathsScreen(),
                          transition: Transition.cupertino,
                        ),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Pc.brown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final p in (_category == 'all'
                      ? ConnectionPathsData.featured
                      : _filtered.take(5)))
                    Padding(
                      key: ValueKey(p.id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeaturedPathCard(
                        path: p,
                        onTap: () async {
                          await openConnectionPath(p);
                          await _load();
                        },
                      ),
                    ),
                  if (_paths.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No Connection Paths found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Pc.muted),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(ConnectionPathsData.heroAsset, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Connection Paths',
                    style: TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Guided journeys to grow closer to God.',
                    style: TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 13.5,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: Pc.serif,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Pc.ink,
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.path,
    required this.day,
    required this.done,
    required this.onTap,
  });

  final ConnectionPath path;
  final int day;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = path.durationDays;
    final pct = total == 0 ? 0.0 : done / total;
    return ParchmentCard(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              ConnectionPathsData.coverFor(path),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.title,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Pc.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Days completed so far (Day 1 done → "Day 1 of 7").
                  'Day ${done < 1 ? 1 : done} of $total',
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 13,
                    color: Pc.muted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Pc.track,
                    color: Pc.brown,
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

/// Mockup-style featured card: wide cover image + text.
class _FeaturedPathCard extends StatelessWidget {
  const _FeaturedPathCard({required this.path, required this.onTap});

  final ConnectionPath path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: Image.asset(
                ConnectionPathsData.coverFor(path),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.title,
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Pc.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${path.durationDays} days · ${path.dailyTime}',
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 12.5,
                          color: Pc.brown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        path.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 12.5,
                          height: 1.3,
                          color: Pc.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Pc.brown),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup screen 2 — All Connection Paths.
class AllConnectionPathsScreen extends StatefulWidget {
  const AllConnectionPathsScreen({super.key});

  @override
  State<AllConnectionPathsScreen> createState() =>
      _AllConnectionPathsScreenState();
}

class _AllConnectionPathsScreenState extends State<AllConnectionPathsScreen> {
  String _category = 'all';
  bool _loading = true;
  final Map<String, String> _status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheConnectionCovers(context);
  }

  Future<void> _load() async {
    await ConnectionPathsData.load();
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
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ConnectionPathsData.forCategory(_category);
    final totalDays = list.fold<int>(0, (sum, p) => sum + p.durationDays);
    return ParchmentScaffold(
      title: 'All Connection Paths',
      backgroundAsset: ConnectionPathsData.pageBgAsset,
      scrim: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    '${list.length} paths · $totalDays days',
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      color: Pc.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: ConnectionPathsData.categoryChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = ConnectionPathsData.categoryChips[i];
                      final selected = _category == c.id;
                      return ParchmentChoiceChip(
                        label: c.label,
                        selected: selected,
                        onTap: () => setState(() => _category = c.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final status = _status[p.id];
                      return Padding(
                        key: ValueKey(p.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ParchmentCard(
                          onTap: () async {
                            await openConnectionPath(p);
                            await _load();
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  ConnectionPathsData.coverFor(p),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: const TextStyle(
                                        fontFamily: Pc.serif,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Pc.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.durationDays} days',
                                      style: const TextStyle(
                                        fontFamily: Pc.serif,
                                        fontSize: 12.5,
                                        color: Pc.brown,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      status ?? p.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: Pc.serif,
                                        fontSize: 12.5,
                                        height: 1.3,
                                        color: Pc.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Pc.brown),
                            ],
                          ),
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
