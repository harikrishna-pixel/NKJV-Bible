import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:biblebookapp/view/screens/milestones/data/milestones_data.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_celebration_coordinator.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_detail_screen.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_progress.dart';
import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

IconData milestoneIconFor(IconKind kind) {
  switch (kind) {
    case IconKind.lantern:
      return Icons.emoji_objects_outlined;
    case IconKind.sprout:
      return Icons.eco_outlined;
    case IconKind.prayer:
      return Icons.volunteer_activism_outlined;
    case IconKind.community:
      return Icons.groups_outlined;
    case IconKind.wreath:
      return Icons.emoji_events_outlined;
  }
}

IconData _tabIcon(MilestoneCategory c) {
  switch (c) {
    case MilestoneCategory.connection:
      return Icons.emoji_objects_outlined;
    case MilestoneCategory.prayer:
      return Icons.volunteer_activism_outlined;
    case MilestoneCategory.community:
      return Icons.groups_outlined;
  }
}

/// Screen 13 — Milestones (Connection / Prayer / Community tabs).
class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({
    super.key,
    this.initialCategory = MilestoneCategory.connection,
  });

  final MilestoneCategory initialCategory;

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final Map<MilestoneCategory, List<MilestoneProgress>> _byCat = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final i = MilestoneCategory.values.indexOf(widget.initialCategory);
    _tabs = TabController(
      length: MilestoneCategory.values.length,
      vsync: this,
      initialIndex: i < 0 ? 0 : i,
    )..addListener(() {
        if (!_tabs.indexIsChanging && mounted) setState(() {});
      });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final map = <MilestoneCategory, List<MilestoneProgress>>{};
    for (final c in MilestoneCategory.values) {
      map[c] = await MilestonesProgressService.forCategory(c);
    }
    if (!mounted) return;
    setState(() {
      _byCat
        ..clear()
        ..addAll(map);
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MilestoneCelebrationCoordinator.checkAndShow(context);
    });
  }

  Future<void> _open(MilestoneProgress p) async {
    await Get.to(
      () => MilestoneDetailScreen(milestoneId: p.def.id),
      transition: Transition.cupertino,
    );
    await _load();
  }

  /// Opens the next milestone the user is working toward in this tab.
  void _openNext() {
    final cat = MilestoneCategory.values[_tabs.index];
    final list = _byCat[cat] ?? const <MilestoneProgress>[];
    if (list.isEmpty) return;
    final next = list.firstWhere((p) => !p.isComplete, orElse: () => list.last);
    _open(next);
  }

  @override
  Widget build(BuildContext context) {
    final cat = MilestoneCategory.values[_tabs.index];
    return ParchmentScaffold(
      title: 'Milestones',
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Pc.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Pc.border),
              ),
              child: TabBar(
                controller: _tabs,
                labelColor: Colors.white,
                unselectedLabelColor: Pc.ink,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                indicator: BoxDecoration(
                  color: Pc.brown,
                  borderRadius: BorderRadius.circular(6),
                ),
                labelStyle: const TextStyle(
                  fontFamily: Pc.serif,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: Pc.serif,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
                tabs: MilestoneCategory.values
                    .map((c) => Tab(text: MilestonesData.tabTitle(c)))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Pc.brown))
                : TabBarView(
                    controller: _tabs,
                    children: MilestoneCategory.values
                        .map((c) => _CategoryList(
                              category: c,
                              items: _byCat[c] ?? const [],
                              onOpen: _open,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
      bottom: ParchmentButton(
        label: cat == MilestoneCategory.connection
            ? 'View All Milestones'
            : 'View ${MilestonesData.tabTitle(cat)} Milestones',
        onPressed: _loading ? null : _openNext,
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.category,
    required this.items,
    required this.onOpen,
  });

  final MilestoneCategory category;
  final List<MilestoneProgress> items;
  final void Function(MilestoneProgress) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        Row(
          children: [
            Icon(_tabIcon(category), color: Pc.bronze, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                MilestonesData.tabIntro(category),
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 14,
                  height: 1.35,
                  color: Pc.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...items.map((p) {
          final isConnection = category == MilestoneCategory.connection;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ParchmentCard(
              onTap: () => onOpen(p),
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  BronzeBadge(
                    icon: milestoneIconFor(p.def.icon),
                    size: 50,
                    label: isConnection ? '${p.def.target}' : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.def.title,
                          style: const TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Pc.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.def.subtitle,
                          style: const TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 13,
                            height: 1.3,
                            color: Pc.muted,
                          ),
                        ),
                        if (!p.isComplete) ...[
                          const SizedBox(height: 8),
                          ParchmentProgressBar(value: p.fraction, height: 4),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (p.isComplete)
                    const CheckCircle(size: 30)
                  else
                    Text(
                      '${p.current.clamp(0, p.def.target)}/${p.def.target}',
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Pc.brown,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
