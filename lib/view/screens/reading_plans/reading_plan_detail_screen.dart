import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/services/reading_plan_progress_service.dart';
import 'package:biblebookapp/services/study_plan_verse_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/reading_plans/models/reading_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Day list + verse reader for a single Reading Plan.
/// Calls existing verse fetch helpers; does not modify Study Plan logic.
class ReadingPlanDetailScreen extends StatefulWidget {
  const ReadingPlanDetailScreen({super.key, required this.plan});

  final ReadingPlan plan;

  @override
  State<ReadingPlanDetailScreen> createState() =>
      _ReadingPlanDetailScreenState();
}

class _ReadingPlanDetailScreenState extends State<ReadingPlanDetailScreen> {
  static const Color _cream = Color(0xFFFFFBF7);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _gold = Color(0xFFC9A227);

  final Set<int> _completedDays = {};
  final Set<int> _unlockedDays = {};
  ReadingPlanStatusInfo? _status;
  double _progress = 0;
  bool _loading = true;

  ReadingPlan get plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final done = <int>{};
    final unlocked = <int>{};
    for (var i = 0; i < plan.durationDays; i++) {
      if (await ReadingPlanProgressService.isDayCompleted(plan.id, i)) {
        done.add(i);
      }
      if (await ReadingPlanProgressService.canOpenDay(
        planId: plan.id,
        dayIndex: i,
        totalDays: plan.durationDays,
      )) {
        unlocked.add(i);
      }
    }
    final status = await ReadingPlanProgressService.statusInfo(
      planId: plan.id,
      totalDays: plan.durationDays,
    );
    if (!mounted) return;
    setState(() {
      _completedDays
        ..clear()
        ..addAll(done);
      _unlockedDays
        ..clear()
        ..addAll(unlocked);
      _status = status;
      _progress = status.progress;
      _loading = false;
    });
  }

  Future<void> _markDayComplete(int dayIndex) async {
    await ReadingPlanProgressService.setDayCompleted(
      plan.id,
      dayIndex,
      completed: true,
    );
    final totalDone = await ReadingPlanProgressService.completedDayCount(
      plan.id,
      plan.durationDays,
    );
    if (totalDone >= plan.durationDays) {
      await ReadingPlanProgressService.markCompleted(plan.id);
    }
    await _bootstrap();
  }

  Future<void> _showLockedMessage(int dayIndex) async {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final bg = isDark ? CommanColor.darkPrimaryColor : _cream;
    final titleColor = isDark ? Colors.white : _ink;
    final bodyColor = isDark ? Colors.white70 : _muted;

    var title = 'Opens tomorrow';
    var body =
        'You already finished today’s reading. Day ${dayIndex + 1} will unlock tomorrow.';
    // Earlier days not finished yet.
    for (var i = 0; i < dayIndex; i++) {
      if (!_completedDays.contains(i)) {
        title = 'Keep going in order';
        body =
            'Please complete Day ${i + 1} first. Then the next day unlocks on the following day.';
        break;
      }
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 44, color: _brown),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens day dialog. After mark complete → stay; next day unlocks tomorrow.
  Future<void> _openDay(int dayIndex) async {
    if (dayIndex < 0 || dayIndex >= plan.durationDays) return;

    final allowed = await ReadingPlanProgressService.canOpenDay(
      planId: plan.id,
      dayIndex: dayIndex,
      totalDays: plan.durationDays,
    );
    if (!allowed) {
      await _showLockedMessage(dayIndex);
      return;
    }

    final refs = plan.versesForDay(dayIndex);
    final alreadyDone = _completedDays.contains(dayIndex);
    final result = await showDialog<_DayDialogResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _DayVerseDialog(
        dayNumber: dayIndex + 1,
        references: refs,
        initiallyCompleted: alreadyDone,
        isLastDay: dayIndex >= plan.durationDays - 1,
        cream: _cream,
        ink: _ink,
        muted: _muted,
        brown: _brown,
        gold: _gold,
      ),
    );

    if (!mounted) return;
    if (result != _DayDialogResult.markedComplete) return;

    if (!alreadyDone) {
      await _markDayComplete(dayIndex);
      if (!mounted) return;
      final isLast = dayIndex >= plan.durationDays - 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLast
                ? 'Reading plan completed. Well done!'
                : 'Day ${dayIndex + 1} done. Come back tomorrow for Day ${dayIndex + 2}.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmReset() async {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final bg = isDark ? CommanColor.darkPrimaryColor : _cream;
    final titleColor = isDark ? Colors.white : _ink;
    final bodyColor = isDark ? Colors.white70 : _muted;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 48,
                    color: _brown.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Reset progress?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This clears your progress for this reading plan only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _gold.withValues(alpha: 0.45),
                          thickness: 1,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.eco_rounded,
                          size: 16,
                          color: _gold.withValues(alpha: 0.9),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _gold.withValues(alpha: 0.45),
                          thickness: 1,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _brown,
                              side: BorderSide(
                                color: _brown.withValues(alpha: 0.55),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brown,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    await ReadingPlanProgressService.reset(plan.id, plan.durationDays);
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final primary = CommanColor.lightDarkPrimary(context);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4F0);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                tooltip: 'Reset progress',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _confirmReset,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    plan.backgroundAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: primary),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          () {
                            final s = _status;
                            if (s == null) {
                              return '${_completedDays.length} of ${plan.durationDays} days';
                            }
                            switch (s.kind) {
                              case ReadingPlanStatusKind.notStarted:
                                return 'Not started · 0 of ${plan.durationDays} days';
                              case ReadingPlanStatusKind.ongoing:
                                return 'Ongoing · ${s.completedDays} of ${s.totalDays} days · ${(s.progress * 100).round()}%';
                              case ReadingPlanStatusKind.completed:
                                return 'Completed · ${s.totalDays} of ${s.totalDays} days';
                            }
                          }(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList.separated(
                itemCount: plan.durationDays,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final done = _completedDays.contains(index);
                  final unlocked = _unlockedDays.contains(index);
                  final locked = !unlocked;
                  final refs = plan.versesForDay(index);
                  return Material(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => _openDay(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Opacity(
                        opacity: locked && !done ? 0.72 : 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: done
                                      ? primary.withOpacity(0.15)
                                      : locked
                                          ? (isDark
                                              ? Colors.white10
                                              : const Color(0xFFE8E2DA))
                                          : (isDark
                                              ? Colors.white10
                                              : const Color(0xFFF0EBE4)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: done
                                    ? Icon(Icons.check_rounded,
                                        color: primary, size: 22)
                                    : locked
                                        ? Icon(
                                            Icons.lock_outline_rounded,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF8A7A6A),
                                            size: 20,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF5A4A3A),
                                            ),
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Day ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: CommanColor.whiteBlack(
                                                  context),
                                            ),
                                          ),
                                        ),
                                        if (done)
                                          Text(
                                            'Done',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: primary,
                                            ),
                                          )
                                        else if (locked)
                                          Text(
                                            'Tomorrow',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white54
                                                  : const Color(0xFF8A7A6A),
                                            ),
                                          )
                                        else
                                          Text(
                                            'Today',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      refs.join('  ·  '),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF7A6A5A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Icon(
                                  locked && !done
                                      ? Icons.lock_outline_rounded
                                      : Icons.chevron_right_rounded,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFFB0A090),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

enum _DayDialogResult { closed, markedComplete }

class _DayVerseDialog extends StatefulWidget {
  const _DayVerseDialog({
    required this.dayNumber,
    required this.references,
    required this.initiallyCompleted,
    required this.isLastDay,
    required this.cream,
    required this.ink,
    required this.muted,
    required this.brown,
    required this.gold,
  });

  final int dayNumber;
  final List<String> references;
  final bool initiallyCompleted;
  final bool isLastDay;
  final Color cream;
  final Color ink;
  final Color muted;
  final Color brown;
  final Color gold;

  @override
  State<_DayVerseDialog> createState() => _DayVerseDialogState();
}

class _DayVerseDialogState extends State<_DayVerseDialog> {
  bool _loading = true;
  final List<({String ref, List<VerseBookContentModel> verses})> _sections =
      [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sections =
        <({String ref, List<VerseBookContentModel> verses})>[];
    for (final ref in widget.references) {
      final verses = await StudyPlanVerseService.fetchVerseContent(ref);
      sections.add((ref: ref, verses: verses));
    }
    if (!mounted) return;
    setState(() {
      _sections
        ..clear()
        ..addAll(sections);
      _loading = false;
    });
  }

  String _cleanHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? CommanColor.darkPrimaryColor : widget.cream;
    final titleColor = isDark ? Colors.white : widget.ink;
    final bodyColor = isDark ? Colors.white70 : widget.muted;
    final maxH = MediaQuery.sizeOf(context).height * 0.72;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day ${widget.dayNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '3 verses for today',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: bodyColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: widget.gold.withValues(alpha: 0.45),
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.eco_rounded,
                            size: 16,
                            color: widget.gold.withValues(alpha: 0.9),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: widget.gold.withValues(alpha: 0.45),
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _sections.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, i) {
                                final section = _sections[i];
                                final text = section.verses.isEmpty
                                    ? 'Verse text is unavailable for this reference in your current Bible.'
                                    : section.verses
                                        .map((v) =>
                                            _cleanHtml((v.content ?? '').toString()))
                                        .where((t) => t.isNotEmpty)
                                        .join('\n\n');
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.ref,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: widget.brown,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        height: 1.5,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (!widget.initiallyCompleted)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context)
                              .pop(_DayDialogResult.markedComplete),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.brown,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Mark day complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_DayDialogResult.closed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.brown,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (!widget.initiallyCompleted) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_DayDialogResult.closed),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.brown,
                            side: BorderSide(
                              color: widget.brown.withValues(alpha: 0.55),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      Navigator.of(context).pop(_DayDialogResult.closed),
                  icon: Icon(
                    Icons.close,
                    color: widget.muted.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
