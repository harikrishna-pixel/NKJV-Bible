import 'package:biblebookapp/services/reading_plan_progress_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/reading_plans/data/reading_plans_data.dart';
import 'package:biblebookapp/view/screens/reading_plans/models/reading_plan_model.dart';
import 'package:biblebookapp/view/screens/reading_plans/reading_plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Settings → Reading Plans. Additive UI only; does not change Study Plans.
class ReadingPlansScreen extends StatefulWidget {
  const ReadingPlansScreen({super.key});

  @override
  State<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends State<ReadingPlansScreen> {
  int? _selectedDays; // null = All
  final Map<String, ReadingPlanStatusInfo> _status = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final plans = ReadingPlansData.allPlans;
    final map = <String, ReadingPlanStatusInfo>{};
    for (final plan in plans) {
      map[plan.id] = await ReadingPlanProgressService.statusInfo(
        planId: plan.id,
        totalDays: plan.durationDays,
      );
    }
    if (!mounted) return;
    setState(() {
      _status
        ..clear()
        ..addAll(map);
    });
  }

  List<ReadingPlan> get _filtered =>
      ReadingPlansData.plansForDuration(_selectedDays);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final primary = CommanColor.lightDarkPrimary(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F4F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reading Plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'One day at a time — the next day unlocks tomorrow.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DurationChip(
                        label: 'All',
                        selected: _selectedDays == null,
                        onTap: () => setState(() => _selectedDays = null),
                      ),
                      ...ReadingPlansData.durations.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _DurationChip(
                            label: '$d days',
                            selected: _selectedDays == d,
                            onTap: () => setState(() => _selectedDays = d),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final plan = _filtered[index];
                final info = _status[plan.id] ??
                    ReadingPlanStatusInfo(
                      label: 'Not started',
                      completedDays: 0,
                      totalDays: plan.durationDays,
                      progress: 0,
                      kind: ReadingPlanStatusKind.notStarted,
                    );
                return _ReadingPlanCard(
                  plan: plan,
                  status: info,
                  onTap: () async {
                    await Get.to(
                      () => ReadingPlanDetailScreen(plan: plan),
                      transition: Transition.cupertino,
                      duration: const Duration(milliseconds: 280),
                    );
                    await _loadProgress();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? CommanColor.lightDarkPrimary(context)
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({
    required this.plan,
    required this.status,
    required this.onTap,
  });

  final ReadingPlan plan;
  final ReadingPlanStatusInfo status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (status.progress * 100).round();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 178,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  plan.backgroundAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: CommanColor.lightDarkPrimary(context),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${plan.durationDays} days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.kind == ReadingPlanStatusKind.completed
                                  ? const Color(0xFF2E7D32).withOpacity(0.85)
                                  : status.kind == ReadingPlanStatusKind.ongoing
                                      ? const Color(0xFFE8A317).withOpacity(0.9)
                                      : Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.kind == ReadingPlanStatusKind.notStarted
                                  ? 'Not started'
                                  : status.kind == ReadingPlanStatusKind.completed
                                      ? 'Completed'
                                      : 'Ongoing',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (status.kind != ReadingPlanStatusKind.notStarted)
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        plan.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.kind == ReadingPlanStatusKind.notStarted
                            ? '0 of ${plan.durationDays} days complete'
                            : status.kind == ReadingPlanStatusKind.completed
                                ? 'All ${plan.durationDays} days complete'
                                : '${status.completedDays} of ${status.totalDays} days complete',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: status.progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
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
