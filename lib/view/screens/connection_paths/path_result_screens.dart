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
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Pc.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Pc.gold, width: 2),
                ),
                child:
                    const Icon(Icons.check_rounded, size: 48, color: Pc.brown),
              ),
              const SizedBox(height: 18),
              const Text(
                'Day Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Pc.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg.isEmpty ? 'Great! You made time with God today.' : msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 15,
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
            label: 'Continue My Journey',
            onPressed: () => Get.off(
              () => PathOverviewScreen(path: path),
              transition: Transition.cupertino,
            ),
            gold: true,
            showArrow: true,
          ),
          TextButton(
            onPressed: () => Get.until((r) => r.isFirst),
            child: const Text('Back to Home',
                style: TextStyle(color: Pc.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
