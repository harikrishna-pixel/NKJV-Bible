import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Screen 10 — My Paths (Active / Completed).
class MyPathsScreen extends StatefulWidget {
  const MyPathsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MyPathsScreen> createState() => _MyPathsScreenState();
}

class _MyPathsScreenState extends State<MyPathsScreen> {
  late int _tab = widget.initialTab;
  bool _loading = true;
  List<({ConnectionPath path, int day, double pct})> _active = [];
  List<({ConnectionPath path, DateTime? on})> _completed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = <({ConnectionPath path, int day, double pct})>[];
    for (final p in await ConnectionPathProgress.activePaths()) {
      final done = (await ConnectionPathProgress.completedDays(p)).length;
      final day = await ConnectionPathProgress.currentDay(p);
      active.add((path: p, day: day, pct: done / p.durationDays));
    }
    final completed = <({ConnectionPath path, DateTime? on})>[];
    for (final p in await ConnectionPathProgress.completedPaths()) {
      completed.add((path: p, on: await ConnectionPathProgress.completedOn(p.id)));
    }
    completed.sort((a, b) =>
        (b.on ?? DateTime(2000)).compareTo(a.on ?? DateTime(2000)));
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
      title: 'My Paths',
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _Segmented(
              labels: const ['Active', 'Completed'],
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
        label: 'Start New Path',
        onPressed: () async {
          await Get.to(
            () => const AllConnectionPathsScreen(),
            transition: Transition.cupertino,
          );
          await _load();
        },
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
              height: 1.4,
              color: Pc.muted,
            ),
          ),
        ),
      );

  Widget _buildActive() {
    if (_active.isEmpty) {
      return _empty('No active paths yet.\nStart a path to begin your journey.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final a = _active[i];
        return ParchmentCard(
          onTap: () async {
            await Get.to(
              () => PathOverviewScreen(path: a.path),
              transition: Transition.cupertino,
            );
            await _load();
          },
          child: Row(
            children: [
              BronzeBadge(icon: a.path.icon, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(a.path.title),
                    _sub(a.path.durationLabel),
                    const SizedBox(height: 4),
                    _sub('Day ${a.day + 1} of ${a.path.durationDays}'),
                    const SizedBox(height: 6),
                    ParchmentProgressBar(value: a.pct, height: 5),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Pc.brown),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleted() {
    if (_completed.isEmpty) {
      return _empty('No completed paths yet.\nFinish a path to see it here.');
    }
    final fmt = DateFormat('MMM d, yyyy');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _completed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = _completed[i];
        return ParchmentCard(
          onTap: () => Get.to(
            () => PathProgressScreen(path: c.path),
            transition: Transition.cupertino,
          ),
          child: Row(
            children: [
              BronzeBadge(icon: c.path.icon, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(c.path.title),
                    _sub(c.path.durationLabel),
                    if (c.on != null) _sub('Completed on ${fmt.format(c.on!)}'),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_outline, color: Pc.brown, size: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _title(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Pc.ink,
        ),
      );

  Widget _sub(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 13,
          color: Pc.muted,
        ),
      );
}

/// Two/three-option parchment segmented control.
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
      height: 40,
      decoration: BoxDecoration(
        color: Pc.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Pc.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? Pc.brown : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : Pc.ink,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
