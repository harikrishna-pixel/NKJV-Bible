import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/my_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void _returnHome() => Get.until((route) => route.isFirst);

/// Screen 6 — Day Completed.
class DayCompletedScreen extends StatefulWidget {
  const DayCompletedScreen({
    super.key,
    required this.path,
    required this.dayIndex,
  });

  final ConnectionPath path;
  final int dayIndex;

  @override
  State<DayCompletedScreen> createState() => _DayCompletedScreenState();
}

class _DayCompletedScreenState extends State<DayCompletedScreen> {
  int _connected = 0;

  @override
  void initState() {
    super.initState();
    ConnectionPathProgress.completedDays(widget.path).then((d) {
      if (mounted) setState(() => _connected = d.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: '',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const LaurelEmblem(icon: Icons.add, size: 170),
              const SizedBox(height: 14),
              Text(
                'Day ${widget.dayIndex + 1}\nCompleted!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Great! You made time\nwith God today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 16,
                  height: 1.4,
                  color: Pc.muted,
                ),
              ),
              const SizedBox(height: 22),
              const OrnamentDivider(),
              const SizedBox(height: 14),
              Text(
                '$_connected Day${_connected == 1 ? '' : 's'} Connected',
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep going on your\nConnection Path. Your next day\nunlocks tomorrow.',
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
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParchmentButton(
            label: 'View Path Progress',
            onPressed: () => Get.off(
              () => PathProgressScreen(path: widget.path),
              transition: Transition.cupertino,
            ),
          ),
          ParchmentLinkButton(label: 'Return Home', onPressed: _returnHome),
        ],
      ),
    );
  }
}

/// Screen 9 — Path Completed.
class PathCompletedScreen extends StatelessWidget {
  const PathCompletedScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: '',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const LaurelEmblem(icon: Icons.add, size: 170),
              const SizedBox(height: 14),
              const Text(
                'Path\nCompleted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                path.title,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 18,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'You have finished this path.\nKeep making meaningful time\nwith God every day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 15,
                  height: 1.45,
                  color: Pc.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParchmentButton(
            label: 'View My Paths',
            onPressed: () => Get.off(
              () => const MyPathsScreen(initialTab: 1),
              transition: Transition.cupertino,
            ),
          ),
          ParchmentLinkButton(
            label: 'Start Another Path',
            onPressed: () => Get.off(
              () => const AllConnectionPathsScreen(),
              transition: Transition.cupertino,
            ),
          ),
        ],
      ),
    );
  }
}
