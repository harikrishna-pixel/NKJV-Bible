import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_progress.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_screen.dart';
import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen 14 — Milestone Detail.
class MilestoneDetailScreen extends StatefulWidget {
  const MilestoneDetailScreen({super.key, required this.milestoneId});

  final String milestoneId;

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  MilestoneProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await MilestonesProgressService.forId(widget.milestoneId);
    if (!mounted) return;
    setState(() {
      _progress = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    return ParchmentScaffold(
      title: 'Milestone Detail',
      body: _loading || p == null
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
              children: [
                Center(
                  child: LaurelEmblem(
                    size: 180,
                    text: p.def.category == MilestoneCategory.connection
                        ? '${p.def.target}'
                        : null,
                    icon: milestoneIconFor(p.def.icon),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.def.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.def.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 15,
                    height: 1.4,
                    color: Pc.muted,
                  ),
                ),
                const SizedBox(height: 14),
                const OrnamentDivider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Pc.ink,
                        ),
                      ),
                    ),
                    Text(
                      p.isComplete
                          ? 'Completed'
                          : '${p.current} / ${p.def.target}',
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Pc.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ParchmentProgressBar(value: p.fraction, height: 8),
                const SizedBox(height: 18),
                _InfoCard(
                  icon: Icons.emoji_objects_outlined,
                  title: 'About this milestone',
                  body: p.def.about,
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Reward',
                  body: p.def.reward,
                ),
              ],
            ),
      bottom: ParchmentButton(label: 'Continue', onPressed: () => Get.back()),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Pc.bronze, size: 34),
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
                    fontSize: 16,
                    color: Pc.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 14,
                    height: 1.4,
                    color: Pc.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
