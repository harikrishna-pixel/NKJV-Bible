import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Mockup screen 12 — My Connection Paths (In Progress / Completed).
class MyPathsScreen extends StatefulWidget {
  const MyPathsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MyPathsScreen> createState() => _MyPathsScreenState();
}

class _MyPathsScreenState extends State<MyPathsScreen> {
  late int _tab = widget.initialTab;
  bool _loading = true;
  List<({ConnectionPath path, int day, int done})> _active = [];
  List<({ConnectionPath path, DateTime? on})> _completed = [];

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
    final active = <({ConnectionPath path, int day, int done})>[];
    for (final p in await ConnectionPathProgress.activePaths()) {
      final done = (await ConnectionPathProgress.completedDays(p)).length;
      final day = await ConnectionPathProgress.currentDay(p);
      active.add((path: p, day: day, done: done));
    }
    final completed = <({ConnectionPath path, DateTime? on})>[];
    for (final p in await ConnectionPathProgress.completedPaths()) {
      completed
          .add((path: p, on: await ConnectionPathProgress.completedOn(p.id)));
    }
    completed.sort(
        (a, b) => (b.on ?? DateTime(2000)).compareTo(a.on ?? DateTime(2000)));
    if (!mounted) return;
    setState(() {
      _active = active;
      _completed = completed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: 'My Connection Paths',
      backgroundAsset: ConnectionPathsData.pageBgAsset,
      scrim: true,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Segmented(
              labels: const ['In Progress', 'Completed'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Pc.brown))
                : _tab == 0
                    ? _buildActive()
                    : _buildCompleted(),
          ),
        ],
      ),
      bottom: ParchmentButton(
        label: 'Explore Paths',
        onPressed: () async {
          await Get.to(
            () => const AllConnectionPathsScreen(),
            transition: Transition.cupertino,
          );
          await _load();
        },
        gold: true,
        showArrow: true,
      ),
    );
  }

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Pc.serif,
              fontSize: 15,
              color: Pc.muted,
            ),
          ),
        ),
      );

  Widget _buildActive() {
    if (_active.isEmpty) {
      return _empty(
          'No paths in progress yet.\nStart a Connection Path to begin.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _active.length,
      itemBuilder: (_, i) {
        final a = _active[i];
        final pct = a.done / a.path.durationDays;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ParchmentCard(
            onTap: () async {
              await Get.to(
                () => PathOverviewScreen(path: a.path),
                transition: Transition.cupertino,
              );
              await _load();
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    ConnectionPathsData.coverFor(a.path),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.path.title,
                          style: const TextStyle(
                              fontFamily: Pc.serif,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: Pc.ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${a.done} of ${a.path.durationDays} days',
                        style: const TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 12.5,
                            color: Pc.muted),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleted() {
    if (_completed.isEmpty) {
      return _empty('No completed paths yet.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _completed.length,
      itemBuilder: (_, i) {
        final c = _completed[i];
        final date =
            c.on == null ? '' : DateFormat('MMM d, yyyy').format(c.on!);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ParchmentCard(
            onTap: () => openConnectionPath(c.path),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    ConnectionPathsData.coverFor(c.path),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.path.title,
                          style: const TextStyle(
                              fontFamily: Pc.serif,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: Pc.ink)),
                      const SizedBox(height: 2),
                      Text(
                        date.isEmpty ? 'Completed' : 'Completed $date',
                        style: const TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 12.5,
                            color: Pc.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Pc.brown, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Pc.track.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pc.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: index == i ? Pc.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: index == i
                        ? [
                            BoxShadow(
                              color: Pc.brownDark.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 12.5,
                      fontWeight:
                          index == i ? FontWeight.w700 : FontWeight.w500,
                      color: index == i ? Pc.ink : Pc.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
