import 'package:biblebookapp/services/study_plan_verse_service.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_result_screens.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen 5 — Daily Connection (Verse / Devotion / Reflection / Prayer).
class DailyConnectionScreen extends StatefulWidget {
  const DailyConnectionScreen({
    super.key,
    required this.path,
    required this.dayIndex,
  });

  final ConnectionPath path;
  final int dayIndex;

  @override
  State<DailyConnectionScreen> createState() => _DailyConnectionScreenState();
}

class _DailyConnectionScreenState extends State<DailyConnectionScreen> {
  Set<PathStep> _steps = {};
  bool _dayDone = false;
  bool _loading = true;
  bool _completing = false;
  String _verseText = '';
  String _reflection = '';

  PathDay get day => widget.path.days[widget.dayIndex];
  String get pathId => widget.path.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final steps = await ConnectionPathProgress.stepsDone(pathId, widget.dayIndex);
    final done =
        await ConnectionPathProgress.isDayCompleted(pathId, widget.dayIndex);
    final refl =
        await ConnectionPathProgress.reflection(pathId, widget.dayIndex);
    var text = '';
    try {
      final verses = await StudyPlanVerseService.fetchVerseContent(day.verseRef);
      text = verses
          .map((v) => _clean((v.content ?? '').toString()))
          .where((t) => t.isNotEmpty)
          .join(' ');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _dayDone = done;
      _reflection = refl;
      _verseText = text;
      _loading = false;
    });
  }

  static String _clean(String raw) => raw
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .trim();

  Future<void> _markStep(PathStep step) async {
    await ConnectionPathProgress.setStepDone(pathId, widget.dayIndex, step);
    if (!mounted) return;
    setState(() => _steps = {..._steps, step});
  }

  Future<void> _openReading({
    required PathStep step,
    required String title,
    String? reference,
    required String body,
    required String confirmLabel,
  }) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F4EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const OrnamentDivider(),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 17,
                    height: 1.5,
                    color: Pc.ink,
                  ),
                ),
                if (reference != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    reference,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Pc.brown,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ParchmentButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) await _markStep(step);
  }

  Future<void> _openReflection() async {
    final ctrl = TextEditingController(text: _reflection);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F4EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reflection',
                  style: TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.reflection,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 15,
                    height: 1.4,
                    color: Pc.muted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: Pc.serif, color: Pc.ink),
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts…',
                    filled: true,
                    fillColor: Pc.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Pc.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Pc.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Pc.brown),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ParchmentButton(
                  label: 'Save Reflection',
                  onPressed: () {
                    final t = ctrl.text.trim();
                    if (t.isEmpty) return;
                    Navigator.of(ctx).pop(t);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();
    if (saved == null) return;
    await ConnectionPathProgress.saveReflection(pathId, widget.dayIndex, saved);
    if (!mounted) return;
    setState(() => _reflection = saved);
    await _markStep(PathStep.reflection);
  }

  Future<void> _completeDay() async {
    if (_completing) return;
    setState(() => _completing = true);
    final finished =
        await ConnectionPathProgress.completeDay(widget.path, widget.dayIndex);
    if (!mounted) return;
    if (finished) {
      await Get.off(
        () => PathCompletedScreen(path: widget.path),
        transition: Transition.fadeIn,
      );
    } else {
      await Get.off(
        () => DayCompletedScreen(path: widget.path, dayIndex: widget.dayIndex),
        transition: Transition.fadeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _steps.length == PathStep.values.length;
    final dayNo = widget.dayIndex + 1;
    return ParchmentScaffold(
      title: widget.path.title,
      subtitle: 'Day $dayNo of ${widget.path.durationDays}',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _SectionCard(
                  title: 'Verse',
                  body: _verseText.isEmpty ? day.verseRef : _verseText,
                  footer: _verseText.isEmpty ? null : day.verseRef,
                  actionLabel: 'Read',
                  done: _dayDone || _steps.contains(PathStep.verse),
                  onAction: () => _openReading(
                    step: PathStep.verse,
                    title: 'Today\'s Verse',
                    reference: day.verseRef,
                    body: _verseText.isEmpty
                        ? 'Open your Bible to ${day.verseRef} and read it slowly.'
                        : _verseText,
                    confirmLabel: 'I\'ve Read It',
                  ),
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Devotion',
                  body: day.devotion,
                  actionLabel: 'Read',
                  done: _dayDone || _steps.contains(PathStep.devotion),
                  onAction: () => _openReading(
                    step: PathStep.devotion,
                    title: day.title,
                    body: day.devotion,
                    confirmLabel: 'Mark as Read',
                  ),
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Reflection',
                  body: _reflection.isEmpty ? day.reflection : _reflection,
                  actionLabel: _reflection.isEmpty ? 'Write' : 'Edit',
                  done: _dayDone || _steps.contains(PathStep.reflection),
                  onAction: _openReflection,
                ),
                const SizedBox(height: 10),
                _SectionCard(
                  title: 'Prayer',
                  body: 'Talk to God with a sincere heart.',
                  actionLabel: 'Pray',
                  done: _dayDone || _steps.contains(PathStep.prayer),
                  onAction: () => _openReading(
                    step: PathStep.prayer,
                    title: 'Prayer',
                    body: day.prayer,
                    confirmLabel: 'Amen',
                  ),
                ),
              ],
            ),
      bottom: _loading
          ? null
          : _dayDone
              ? ParchmentButton(
                  label: 'Day $dayNo Completed',
                  icon: Icons.check,
                  onPressed: () => Get.back(),
                )
              : ParchmentButton(
                  label: allDone
                      ? 'Complete Day $dayNo'
                      : 'Complete Day $dayNo (${_steps.length}/4)',
                  icon: Icons.check,
                  onPressed: allDone && !_completing ? _completeDay : null,
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.done,
    required this.onAction,
    this.footer,
  });

  final String title;
  final String body;
  final String? footer;
  final String actionLabel;
  final bool done;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
              ),
              if (done) const CheckCircle(size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 14,
                        height: 1.4,
                        color: Pc.ink,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        footer!,
                        style: const TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 13,
                          color: Pc.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Pc.brown,
                  backgroundColor: Pc.card,
                  side: const BorderSide(color: Pc.border),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
