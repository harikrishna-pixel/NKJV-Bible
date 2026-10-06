import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/daily_connection_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _PathState {
  _PathState({
    required this.completed,
    required this.current,
    required this.canOpenCurrent,
    required this.stepsCurrent,
  });

  final Set<int> completed;
  final int current;
  final bool canOpenCurrent;
  final Set<PathStep> stepsCurrent;
}

Future<_PathState> _loadState(ConnectionPath path) async {
  final done = await ConnectionPathProgress.completedDays(path);
  final current = await ConnectionPathProgress.currentDay(path);
  final finished = current >= path.durationDays;
  final canOpen =
      finished ? false : await ConnectionPathProgress.canOpenDay(path, current);
  final steps = finished
      ? <PathStep>{}
      : await ConnectionPathProgress.stepsDone(path.id, current);
  return _PathState(
    completed: done,
    current: current,
    canOpenCurrent: canOpen,
    stepsCurrent: steps,
  );
}

Future<void> _showLocked(BuildContext context, ConnectionPath path, int day,
    Set<int> completed) {
  for (var i = 0; i < day; i++) {
    if (!completed.contains(i)) {
      return showParchmentMessage(
        context,
        title: 'Keep going in order',
        body: 'Please complete Day ${i + 1} first.',
      );
    }
  }
  return showParchmentMessage(
    context,
    title: 'Opens tomorrow',
    body:
        'You already finished today\'s connection. Day ${day + 1} will unlock tomorrow.',
  );
}

/// Screen 4 — Path Overview (day stepper + today's plan).
class PathOverviewScreen extends StatefulWidget {
  const PathOverviewScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  State<PathOverviewScreen> createState() => _PathOverviewScreenState();
}

class _PathOverviewScreenState extends State<PathOverviewScreen> {
  _PathState? _state;
  int? _selected;

  ConnectionPath get path => widget.path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _loadState(path);
    if (!mounted) return;
    setState(() {
      _state = s;
      _selected = null;
    });
  }

  Future<void> _openDay(int day) async {
    final s = _state!;
    final isDone = s.completed.contains(day);
    if (!isDone && !await ConnectionPathProgress.canOpenDay(path, day)) {
      if (!mounted) return;
      await _showLocked(context, path, day, s.completed);
      return;
    }
    await Get.to(
      () => DailyConnectionScreen(path: path, dayIndex: day),
      transition: Transition.cupertino,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null) {
      return ParchmentScaffold(
        title: path.title,
        subtitle: path.durationLabel,
        body: const Center(child: CircularProgressIndicator(color: Pc.brown)),
      );
    }
    final finished = s.current >= path.durationDays;
    final shown = (_selected ?? (finished ? path.durationDays - 1 : s.current))
        .clamp(0, path.durationDays - 1);
    final day = path.days[shown];
    final shownDone = s.completed.contains(shown);
    final steps = shown == s.current ? s.stepsCurrent : <PathStep>{};

    final String label;
    VoidCallback? onPressed;
    if (finished && _selected == null) {
      label = 'View Path Progress';
      onPressed = () => Get.off(
            () => PathProgressScreen(path: path),
            transition: Transition.cupertino,
          );
    } else if (shownDone) {
      label = 'Review Day ${shown + 1}';
      onPressed = () => _openDay(shown);
    } else if (shown == s.current && s.canOpenCurrent) {
      label = steps.isEmpty
          ? 'Start Day ${shown + 1}'
          : 'Continue Day ${shown + 1}';
      onPressed = () => _openDay(shown);
    } else {
      label = shown == s.current
          ? 'Day ${shown + 1} Opens Tomorrow'
          : 'Day ${shown + 1} Locked';
      onPressed = () => _showLocked(context, path, shown, s.completed);
    }

    return ParchmentScaffold(
      title: path.title,
      subtitle: path.durationLabel,
      actions: [
        IconButton(
          tooltip: 'Path progress',
          onPressed: () => Get.to(
            () => PathProgressScreen(path: path),
            transition: Transition.cupertino,
          ),
          icon: const Icon(Icons.insights_outlined, color: Pc.ink),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 16),
        children: [
          DayStepper(
            total: path.durationDays,
            completed: s.completed,
            current: s.current,
            onTapDay: (i) => setState(() => _selected = i),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ParchmentCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${shown + 1}',
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 13,
                      color: Pc.muted,
                    ),
                  ),
                  Text(
                    day.title,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Pc.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.subtitle,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 14,
                      color: Pc.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StepRow(
                    done: shownDone || steps.contains(PathStep.verse),
                    title: 'Verse',
                    sub: day.verseRef,
                  ),
                  _StepRow(
                    done: shownDone || steps.contains(PathStep.devotion),
                    title: 'Devotion',
                    sub: 'Make time for meaningful connection',
                  ),
                  _StepRow(
                    done: shownDone || steps.contains(PathStep.reflection),
                    title: 'Reflection',
                    sub: day.reflection,
                  ),
                  _StepRow(
                    done: shownDone || steps.contains(PathStep.prayer),
                    title: 'Prayer',
                    sub: 'Talk to God with a sincere heart',
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: ParchmentButton(label: label, onPressed: onPressed),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.done,
    required this.title,
    required this.sub,
    this.last = false,
  });

  final bool done;
  final String title;
  final String sub;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: Pc.border.withValues(alpha: 0.7)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckCircle(done: done, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Pc.ink,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 13,
                        height: 1.3,
                        color: Pc.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Screen 7 — Path Progress.
class PathProgressScreen extends StatefulWidget {
  const PathProgressScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  State<PathProgressScreen> createState() => _PathProgressScreenState();
}

class _PathProgressScreenState extends State<PathProgressScreen> {
  _PathState? _state;

  ConnectionPath get path => widget.path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _loadState(path);
    if (!mounted) return;
    setState(() => _state = s);
  }

  Future<void> _showCompletedDays() async {
    final s = _state!;
    final days = s.completed.toList()..sort();
    if (days.isEmpty) {
      await showParchmentMessage(
        context,
        title: 'No days yet',
        body: 'Complete your first day to see it here.',
        icon: Icons.event_available_outlined,
      );
      return;
    }
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFFF8F4EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            const Text(
              'Completed Days',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Pc.serif,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 10),
            ...days.map(
              (d) => ListTile(
                leading: const CheckCircle(size: 26),
                title: Text(
                  'Day ${d + 1} · ${path.days[d].title}',
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontWeight: FontWeight.w600,
                    color: Pc.ink,
                  ),
                ),
                subtitle: Text(
                  path.days[d].verseRef,
                  style: const TextStyle(fontFamily: Pc.serif, color: Pc.muted),
                ),
                trailing: const Icon(Icons.chevron_right, color: Pc.brown),
                onTap: () => Navigator.of(ctx).pop(d),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await Get.to(
      () => DailyConnectionScreen(path: path, dayIndex: picked),
      transition: Transition.cupertino,
    );
    await _load();
  }

  Future<void> _showAbout() {
    return showParchmentMessage(
      context,
      title: path.title,
      body: '${path.about}\n\nEach day includes a verse, a short devotion, '
          'a reflection question and a prayer. A new day unlocks each '
          'calendar day after you complete the previous one.',
      icon: path.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null) {
      return ParchmentScaffold(
        title: path.title,
        subtitle: path.durationLabel,
        body: const Center(child: CircularProgressIndicator(color: Pc.brown)),
      );
    }
    final doneCount = s.completed.length;
    final pct = path.durationDays == 0 ? 0.0 : doneCount / path.durationDays;
    final finished = s.current >= path.durationDays;

    return ParchmentScaffold(
      title: path.title,
      subtitle: path.durationLabel,
      body: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 16),
        children: [
          DayStepper(
            total: path.durationDays,
            completed: s.completed,
            current: s.current,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 14,
                          color: Pc.muted,
                        ),
                      ),
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Pc.ink,
                        ),
                      ),
                      Text(
                        '$doneCount of ${path.durationDays} Days Completed',
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 13,
                          color: Pc.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ParchmentProgressBar(value: pct),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.play_circle_outline,
                  title: finished ? 'Path Completed' : 'Continue Path',
                  sub: finished
                      ? 'All ${path.durationDays} days done'
                      : 'Day ${s.current + 1} - ${path.days[s.current].title}',
                  onTap: () => Get.off(
                    () => PathOverviewScreen(path: path),
                    transition: Transition.cupertino,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.event_available_outlined,
                  title: 'View Completed Days',
                  sub: '$doneCount Day${doneCount == 1 ? '' : 's'}',
                  onTap: _showCompletedDays,
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.info_outline,
                  title: 'About This Path',
                  sub: 'Details & Benefits',
                  onTap: _showAbout,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: ParchmentButton(
        label: 'Browse More Paths',
        onPressed: () => Get.to(
          () => const AllConnectionPathsScreen(),
          transition: Transition.cupertino,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Pc.brown, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 13,
                    color: Pc.muted,
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
