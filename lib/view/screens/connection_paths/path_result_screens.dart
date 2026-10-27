import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/my_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mockup screen 9 — Day Complete.
class DayCompletedScreen extends StatelessWidget {
  const DayCompletedScreen({
    super.key,
    required this.path,
    required this.dayIndex,
  });

  final ConnectionPath path;
  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final msg = path.days[dayIndex].completionMessage;
    final total = path.durationDays;
    final done = (dayIndex + 1).clamp(0, total);
    // Mockup 9: valley sunrise, gold check, progress dots, two buttons.
    return ParchmentScaffold(
      title: '',
      showBack: false,
      backgroundAsset: ConnectionPathsData.completeBgAsset,
      scrimGradient: Pc.sunriseScrim,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Pc.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Pc.gold.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                'Day ${dayIndex + 1} Complete',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg.isEmpty ? 'Great! You made time with God today.' : msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 16,
                  height: 1.4,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Pc.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Pc.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Pc.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ProgressDots(done: done, total: total),
                    const SizedBox(height: 8),
                    Text(
                      '$done of $total days completed',
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 13.5,
                        color: Pc.muted,
                      ),
                    ),
                  ],
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
            label: 'Continue My Journey',
            onPressed: () => Get.off(
              () => PathOverviewScreen(path: path),
              transition: Transition.cupertino,
            ),
            showArrow: true,
          ),
          const SizedBox(height: 10),
          ParchmentLightButton(
            label: 'View Path Overview',
            onPressed: () => Get.off(
              () => PathOverviewScreen(path: path),
              transition: Transition.cupertino,
            ),
          ),
        ],
      ),
    );
  }
}

/// Day dots joined by a line: filled gold for completed days (mockup 9).
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dot = total > 14 ? 8.0 : 12.0;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i < done ? Pc.bronze : Pc.track,
              ),
            ),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? Pc.bronze : Pc.card,
              border: Border.all(
                color: i < done ? Pc.bronze : Pc.border,
                width: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mockup screen 11 — Path Complete.
class PathCompletedScreen extends StatelessWidget {
  const PathCompletedScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  Widget build(BuildContext context) {
    final msg = path.completionMessage;
    return ParchmentScaffold(
      title: '',
      showBack: false,
      backgroundAsset: ConnectionPathsData.completeBgAsset,
      // Lighter than the default scrim so the sunrise shows (mockup 9 / 11).
      scrimColor: const Color(0x99F8F1E3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  ConnectionPathsData.coverFor(path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.workspace_premium_rounded,
                  size: 56, color: Pc.gold),
              const SizedBox(height: 12),
              const Text(
                'Path Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Pc.brown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                msg.isEmpty
                    ? 'You finished this Connection Path. Keep walking with God.'
                    : msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 15,
                  height: 1.45,
                  color: Pc.muted,
                ),
              ),
              if (path.summaryReference.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  path.summaryReference,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Pc.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParchmentButton(
            label: 'Explore More Paths',
            onPressed: () => Get.off(
              () => const AllConnectionPathsScreen(),
              transition: Transition.cupertino,
            ),
            gold: true,
            showArrow: true,
          ),
          TextButton(
            onPressed: () => Get.off(
              () => const MyPathsScreen(initialTab: 1),
              transition: Transition.cupertino,
            ),
            child: const Text('View Completed Paths',
                style: TextStyle(color: Pc.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
