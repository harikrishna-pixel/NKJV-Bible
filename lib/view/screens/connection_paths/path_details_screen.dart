import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen 3 — Path Details (what's included + Start This Path).
class PathDetailsScreen extends StatefulWidget {
  const PathDetailsScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  State<PathDetailsScreen> createState() => _PathDetailsScreenState();
}

class _PathDetailsScreenState extends State<PathDetailsScreen> {
  bool _started = false;
  bool _completed = false;

  static const _included = [
    (Icons.menu_book_outlined, 'Daily Verse', 'Short, meaningful verses'),
    (Icons.auto_stories_outlined, 'Daily Devotion', '2–3 minute encouragement'),
    (Icons.lightbulb_outline, 'Reflection', 'Think and apply'),
    (Icons.self_improvement_outlined, 'Daily Prayer', 'Connect with God'),
    (Icons.trending_up_rounded, 'Track Progress', 'Stay consistent'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ConnectionPathProgress.isStarted(widget.path.id);
    final c = await ConnectionPathProgress.isCompleted(widget.path.id);
    if (!mounted) return;
    setState(() {
      _started = s;
      _completed = c;
    });
  }

  Future<void> _start() async {
    if (!_started) await ConnectionPathProgress.start(widget.path.id);
    await Get.off(
      () => PathOverviewScreen(path: widget.path),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    return ParchmentScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text(
            path.durationLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Pc.serif,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Pc.ink,
            ),
          ),
          Text(
            path.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Pc.serif,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Pc.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Pc.serif,
              fontSize: 15,
              height: 1.35,
              color: Pc.muted,
            ),
          ),
          const SizedBox(height: 14),
          Center(child: LaurelEmblem(icon: path.icon, size: 170)),
          const SizedBox(height: 10),
          ...List.generate(_included.length, (i) {
            final (icon, title, sub) = _included[i];
            return Column(
              children: [
                if (i > 0)
                  Divider(height: 1, color: Pc.border.withValues(alpha: 0.7)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(icon, color: Pc.brown, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: Pc.serif,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      bottom: ParchmentButton(
        label: _completed
            ? 'View This Path'
            : _started
                ? 'Continue Path'
                : 'Start This Path',
        onPressed: _start,
      ),
    );
  }
}
