import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_path_verse_service.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_result_screens.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_celebration_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Mockup screens 5–8 — Daily Connection steps.
class DailyConnectionScreen extends StatefulWidget {
  const DailyConnectionScreen({
    super.key,
    required this.path,
    required this.dayIndex,
    this.review = false,
    this.initialStep,
  });

  final ConnectionPath path;
  final int dayIndex;

  /// Read-only replay of a completed day: starts at Verse (or [initialStep]),
  /// moves forward with Continue, never saves progress or edits.
  final bool review;

  /// With [review], open just this step (tapped from the day card).
  final PathStep? initialStep;

  @override
  State<DailyConnectionScreen> createState() => _DailyConnectionScreenState();
}

class _DailyConnectionScreenState extends State<DailyConnectionScreen> {
  PathStep _step = PathStep.verse;
  Set<PathStep> _done = {};
  bool _loading = true;
  bool _completing = false;
  String _verseText = '';
  late final TextEditingController _reflection;

  PathDay get day => widget.path.days[widget.dayIndex];
  String get pathId => widget.path.id;

  static const _steps = [
    PathStep.verse,
    PathStep.devotion,
    PathStep.reflection,
    PathStep.prayer,
  ];

  @override
  void initState() {
    super.initState();
    _reflection = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final steps =
        await ConnectionPathProgress.stepsDone(pathId, widget.dayIndex);
    final refl =
        await ConnectionPathProgress.reflection(pathId, widget.dayIndex);
    final text = await ConnectionPathVerseService.textForDay(day);
    PathStep start = PathStep.verse;
    for (final s in _steps) {
      if (!steps.contains(s)) {
        start = s;
        break;
      }
      if (s == PathStep.prayer) start = PathStep.prayer;
    }
    if (widget.review) start = widget.initialStep ?? PathStep.verse;
    if (!mounted) return;
    setState(() {
      _done = steps;
      _reflection.text = refl;
      _verseText = text;
      _step = start;
      _loading = false;
    });
  }

  /// Review always moves forward to Prayer (also when opened from a step row).
  bool get _reviewDoneHere => _step == PathStep.prayer;

  /// Back from the step the review was opened on returns to the day card.
  bool get _atReviewStart =>
      widget.review && _step == (widget.initialStep ?? PathStep.verse);

  Future<void> _goNext() async {
    if (widget.review) {
      if (_reviewDoneHere) {
        Get.back();
        return;
      }
      setState(() => _step = _steps[_steps.indexOf(_step) + 1]);
      return;
    }
    await ConnectionPathProgress.setStepDone(pathId, widget.dayIndex, _step);
    if (_step == PathStep.reflection) {
      await ConnectionPathProgress.saveReflection(
          pathId, widget.dayIndex, _reflection.text.trim());
    }
    final i = _steps.indexOf(_step);
    if (i < _steps.length - 1) {
      setState(() {
        _done = {..._done, _step};
        _step = _steps[i + 1];
      });
      return;
    }
    await _completeDay();
  }

  Future<void> _goBack() async {
    final i = _steps.indexOf(_step);
    if (i <= 0 || _atReviewStart) {
      Get.back();
      return;
    }
    setState(() => _step = _steps[i - 1]);
  }

  Future<void> _completeDay() async {
    if (_completing) return;
    setState(() => _completing = true);
    // Seed before earn so this unlock can show (not deferred to Milestones).
    await MilestoneCelebrationCoordinator.seedBaselineIfNeeded();
    await ConnectionPathProgress.setStepDone(
        pathId, widget.dayIndex, PathStep.prayer);
    final pathDone =
        await ConnectionPathProgress.completeDay(widget.path, widget.dayIndex);
    if (!mounted) return;
    if (pathDone) {
      await Get.off(
        () => PathCompletedScreen(path: widget.path),
        transition: Transition.cupertino,
      );
    } else {
      await Get.off(
        () => DayCompletedScreen(
          path: widget.path,
          dayIndex: widget.dayIndex,
        ),
        transition: Transition.cupertino,
      );
    }
    // Unlock popup on the completion screen (not when opening Milestones later).
    await MilestoneCelebrationCoordinator.checkAndShow();
  }

  /// [buttonContext] anchors the iOS share sheet; without a non-zero origin
  /// iOS can refuse to present it.
  Future<void> _shareVerse(BuildContext buttonContext) async {
    final body =
        _verseText.isEmpty ? day.reference : '${day.reference}\n\n$_verseText';
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await Share.share(body, sharePositionOrigin: origin);
    } catch (e) {
      debugPrint('Connection Path share failed: $e');
      if (buttonContext.mounted) {
        ScaffoldMessenger.of(buttonContext).showSnackBar(
          const SnackBar(content: Text('Unable to share right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayNum = widget.dayIndex + 1;
    // Verse: sunrise Bible photo with a light dark tint and white header.
    // Devotion / Reflection / Prayer (mockup 6–8): valley sunrise with a cream
    // wash that fades toward the bottom, dark header.
    final sunrise = _step != PathStep.verse;
    return ParchmentScaffold(
      title: widget.path.title,
      subtitle: 'Day $dayNum of ${widget.path.durationDays}',
      backgroundAsset: sunrise
          ? ConnectionPathsData.valleyBgAsset
          : ConnectionPathsData.verseBgAsset,
      scrimColor: sunrise ? null : Colors.black.withValues(alpha: 0.18),
      scrimGradient: sunrise ? Pc.sunriseScrim : null,
      headerColor: sunrise ? Pc.ink : Colors.white,
      onBack: _goBack,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _StepBar(current: _step, done: _done, light: !sunrise),
                ),
                Expanded(child: _buildStep()),
              ],
            ),
      bottom: _bottomBar(),
    );
  }

  Widget? _bottomBar() {
    if (_loading) return null;
    if (widget.review) {
      return ParchmentButton(
        label: _reviewDoneHere ? 'Completed' : 'Continue',
        onPressed: _goNext,
        gold: true,
        showArrow: !_reviewDoneHere,
      );
    }
    switch (_step) {
      case PathStep.verse:
        return ParchmentButton(
          label: 'Next',
          onPressed: _goNext,
          gold: true,
          showArrow: true,
        );
      case PathStep.devotion:
        return ParchmentButton(
          label: 'Next',
          onPressed: _goNext,
          showArrow: true,
        );
      case PathStep.reflection:
        // Next only — enabled once something is written.
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _reflection,
          builder: (_, value, __) => ParchmentButton(
            label: 'Next',
            onPressed: value.text.trim().isEmpty ? null : _goNext,
            showArrow: true,
          ),
        );
      case PathStep.prayer:
        return ParchmentButton(
          label:
              _completing ? 'Saving…' : 'Complete Day ${widget.dayIndex + 1}',
          onPressed: _completing ? null : _goNext,
          gold: true,
          showArrow: true,
        );
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case PathStep.verse:
        return _VerseStep(
          day: day,
          verseText: _verseText,
          onShare: _shareVerse,
        );
      case PathStep.devotion:
        return _OpenTextStep(
          title: day.title,
          body: day.devotion,
          boxed: true,
        );
      case PathStep.reflection:
        return _ReflectionStep(
          prompt: day.reflection,
          controller: _reflection,
          readOnly: widget.review,
        );
      case PathStep.prayer:
        return _OpenTextStep(
          title: 'Prayer',
          body: day.prayer,
          boxed: true,
        );
    }
  }
}

/// Mockup 8: left-aligned title + text directly on the sunrise wash.
class _OpenTextStep extends StatelessWidget {
  const _OpenTextStep({
    required this.title,
    required this.body,
    this.boxed = false,
  });
  final String title;
  final String body;

  /// Devotion: put the text on a parchment card so it stays readable over
  /// the busy lower part of the background photo.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      Text(
        title,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Pc.ink,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        body,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 16.5,
          height: 1.55,
          color: Pc.ink,
        ),
      ),
    ];
    if (boxed) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: Pc.cardDecoration(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
      children: content,
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.current,
    required this.done,
    this.light = false,
  });
  final PathStep current;
  final Set<PathStep> done;

  /// White labels / gold accent for use over a dark photo background.
  final bool light;

  static const labels = ['Verse', 'Devotion', 'Reflection', 'Prayer'];
  static const steps = PathStep.values;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: done.contains(steps[i - 1]) || current == steps[i]
                    ? (light ? Pc.gold : Pc.brown)
                    : (light ? Colors.white.withValues(alpha: 0.55) : Pc.track),
              ),
            ),
          _Dot(
            label: labels[i],
            active: current == steps[i],
            done: done.contains(steps[i]),
            light: light,
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.label,
    required this.active,
    required this.done,
    this.light = false,
  });
  final String label;
  final bool active;
  final bool done;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final on = light ? Pc.gold : Pc.brown;
    final off = light ? Colors.white.withValues(alpha: 0.7) : Pc.track;
    final color = active || done ? on : off;
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done || active ? on : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: Pc.serif,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: light
                ? Colors.white.withValues(alpha: active ? 1 : 0.85)
                : (active ? Pc.ink : Pc.muted),
            shadows: light ? _photoTextShadow : null,
          ),
        ),
      ],
    );
  }
}

class _VerseStep extends StatelessWidget {
  const _VerseStep({
    required this.day,
    required this.verseText,
    required this.onShare,
  });

  final PathDay day;
  final String verseText;
  final void Function(BuildContext buttonContext) onShare;

  @override
  Widget build(BuildContext context) {
    // Verse sits in the same glass card as Devotion / Reflection / Prayer,
    // centred on the photo; Save / Share stay as light actions above Next.
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: ConstrainedBox(
                // Vertically centre the card; long verses still scroll.
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 28),
                child: Center(
                  child: _GlassCard(
                    child: Column(
                      children: [
                        const Text(
                          'Verse',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Pc.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const OrnamentDivider(),
                        const SizedBox(height: 14),
                        Text(
                          verseText.isEmpty
                              ? 'Open your Bible to ${day.reference}'
                              : verseText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: MediaQuery.of(context).size.width > 450
                                ? 20
                                : 18,
                            height: 1.55,
                            color: Pc.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          day.reference,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: Pc.serif,
                            fontSize: 15,
                            color: Pc.brown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
          child: Row(
            children: [
              Expanded(
                child: _PhotoAction(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: '$verseText\n${day.reference}'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse copied')),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (buttonContext) => _PhotoAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onPressed: () => onShare(buttonContext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _photoTextShadow = [
  Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 2)),
];

/// White icon + label action that reads over the dark lower photo.
class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon:
          Icon(icon, color: Colors.white, size: 22, shadows: _photoTextShadow),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: _photoTextShadow,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFBF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Pc.border),
        boxShadow: [
          BoxShadow(
            color: Pc.brownDark.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReflectionStep extends StatelessWidget {
  const _ReflectionStep({
    required this.prompt,
    required this.controller,
    this.readOnly = false,
  });

  final String prompt;
  final TextEditingController controller;

  /// Review mode: show the saved reflection as text (non-editable).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      // Drag to hide the keyboard (multi-line field: Return adds a new line).
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Mockup 7: open layout on the sunrise wash (no outer card).
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reflection',
              style: TextStyle(
                fontFamily: Pc.serif,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prompt,
              style: const TextStyle(
                fontFamily: Pc.serif,
                fontSize: 17,
                height: 1.45,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Pc.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Pc.border),
              ),
              padding: const EdgeInsets.all(12),
              child: readOnly
                  ? SizedBox(
                      width: double.infinity,
                      child: Text(
                        controller.text.trim().isEmpty
                            ? 'No reflection written for this day.'
                            : controller.text,
                        style: TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 15,
                          height: 1.4,
                          color: controller.text.trim().isEmpty
                              ? Pc.muted
                              : Pc.ink,
                        ),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      maxLines: 6,
                      maxLength: 500,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 15,
                        color: Pc.ink,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write your thoughts here…',
                        hintStyle:
                            TextStyle(color: Pc.muted, fontFamily: Pc.serif),
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: Pc.muted, fontSize: 12),
                      ),
                    ),
            ),
            if (!readOnly) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Pc.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Pc.border),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      ConnectionPathsData.sproutAsset,
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Take your time. You can write as much or as '
                        'little as you like.',
                        style: TextStyle(
                          fontFamily: Pc.serif,
                          fontSize: 14,
                          height: 1.35,
                          color: Pc.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
