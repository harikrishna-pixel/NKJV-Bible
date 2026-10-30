import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:biblebookapp/view/screens/milestones/data/milestones_data.dart';
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

/// Mockup 13 — Milestones (Connection / Prayer / Community).
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
  }

  Future<void> _open(MilestoneProgress p) async {
    await Get.to(
      () => MilestoneDetailScreen(milestoneId: p.def.id),
      transition: Transition.cupertino,
    );
    await _load();
  }

  void _openNext() {
    final cat = MilestoneCategory.values[_tabs.index];
    final list = _byCat[cat] ?? const <MilestoneProgress>[];
    if (list.isEmpty) return;
    final next =
        list.firstWhere((p) => !p.isComplete, orElse: () => list.last);
    _open(next);
  }

  @override
  Widget build(BuildContext context) {
    final cat = MilestoneCategory.values[_tabs.index];
    final list = _byCat[cat] ?? const <MilestoneProgress>[];
    final done = list.where((p) => p.isComplete).length;
    return ParchmentScaffold(
      title: 'Milestones',
      backgroundAsset: 'assets/peace-bg.png',
      scrim: true,
      body: Column(
        children: [
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Celebrate your spiritual journey\nand growth with God.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Pc.serif,
                fontSize: 14,
                height: 1.35,
                color: Pc.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Pc.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: const TextStyle(
                  fontFamily: Pc.serif,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: Pc.serif,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: MilestoneCategory.values
                    .map((c) => Tab(text: MilestonesData.tabTitle(c)))
                    .toList(),
              ),
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$done / ${list.length} unlocked',
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 12.5,
                  color: Pc.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Pc.brown))
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
        label: 'View ${MilestonesData.tabTitle(cat)} Milestones',
        onPressed: _loading ? null : _openNext,
        gold: true,
        showArrow: true,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_tabIcon(category), color: Pc.bronze, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                MilestonesData.tabIntro(category),
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 14,
                  height: 1.4,
                  color: Pc.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...items.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MilestoneCard(
                progress: p,
                onTap: () => onOpen(p),
              ),
            )),
        const SizedBox(height: 8),
        const Text(
          'Every milestone reminds you that your small steps in connection with God and others create lasting impact.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: Pc.serif,
            fontSize: 12.5,
            height: 1.4,
            color: Pc.muted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Mockup-style card with corner marks, seal, title, status.
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.progress,
    required this.onTap,
  });

  final MilestoneProgress progress;
  final VoidCallback onTap;

  /// Days Connected and Prayer cards: one distinct icon each.
  static const Map<String, IconData> _cardIcons = {
    'conn_1': Icons.emoji_objects_outlined,
    'conn_7': Icons.calendar_view_week_outlined,
    'conn_30': Icons.calendar_month_outlined,
    'conn_50': Icons.favorite_border,
    'conn_100': Icons.park_outlined,
    'conn_365': Icons.wb_sunny_outlined,
    'pray_1': Icons.edit_note_outlined,
    'pray_10': Icons.people_outline,
    'pray_50': Icons.handshake_outlined,
    'pray_100': Icons.self_improvement,
    'pray_250': Icons.public,
  };

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _CornerFramePainter(color: Pc.border),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: BoxDecoration(
              color: Pc.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Pc.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                BronzeBadge(
                  icon: _cardIcons[p.def.id] ?? milestoneIconFor(p.def.icon),
                  size: 52,
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
                        ParchmentProgressBar(value: p.fraction, height: 5),
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
        ),
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  _CornerFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const len = 12.0;
    const inset = 4.0;
    // Top-left
    canvas.drawLine(const Offset(inset, inset + len), const Offset(inset, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + len, inset), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - inset - len, inset), Offset(size.width - inset, inset), paint);
    canvas.drawLine(
        Offset(size.width - inset, inset), Offset(size.width - inset, inset + len), paint);
    // Bottom-left
    canvas.drawLine(Offset(inset, size.height - inset - len),
        Offset(inset, size.height - inset), paint);
    canvas.drawLine(Offset(inset, size.height - inset),
        Offset(inset + len, size.height - inset), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - inset - len, size.height - inset),
        Offset(size.width - inset, size.height - inset), paint);
    canvas.drawLine(Offset(size.width - inset, size.height - inset - len),
        Offset(size.width - inset, size.height - inset), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
