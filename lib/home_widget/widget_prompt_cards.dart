import 'package:biblebookapp/home_widget/widget_prompt_service.dart';
import 'package:flutter/material.dart';

const Color _kPromptGold = Color(0xFFB0893D);
const Color _kPromptInk = Color(0xFF2C2014);
const Color _kPromptMuted = Color(0xFF6D5A45);

/// Loads [shouldShow] without changing host-screen logic.
class WidgetPromptGate extends StatefulWidget {
  const WidgetPromptGate({
    super.key,
    required this.id,
    required this.triggerMet,
    required this.builder,
    this.fallback = const SizedBox.shrink(),
    this.libraryTab,
  });

  final WidgetPromptId id;
  final bool triggerMet;
  final Widget Function(BuildContext context, VoidCallback onDismiss) builder;
  final Widget fallback;
  /// For A6 only: Bookmark / Highlights / Underline owner key.
  final String? libraryTab;

  @override
  State<WidgetPromptGate> createState() => _WidgetPromptGateState();
}

class _WidgetPromptGateState extends State<WidgetPromptGate> {
  Future<bool>? _future;

  Future<bool> _load() => WidgetPromptService.shouldShow(
        widget.id,
        triggerMet: widget.triggerMet,
        libraryTab: widget.libraryTab,
      );

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant WidgetPromptGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.triggerMet != widget.triggerMet ||
        oldWidget.libraryTab != widget.libraryTab) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (snap.data != true) return widget.fallback;
        return _DismissiblePrompt(
          id: widget.id,
          builder: widget.builder,
          fallback: widget.fallback,
        );
      },
    );
  }
}

class _DismissiblePrompt extends StatefulWidget {
  const _DismissiblePrompt({
    required this.id,
    required this.builder,
    required this.fallback,
  });

  final WidgetPromptId id;
  final Widget Function(BuildContext context, VoidCallback onDismiss) builder;
  final Widget fallback;

  @override
  State<_DismissiblePrompt> createState() => _DismissiblePromptState();
}

/// Lets prompt CTAs hide the card after Steps without calling decline logic.
class _PromptUiScope extends InheritedWidget {
  const _PromptUiScope({
    required this.hideAfterHowTo,
    required super.child,
  });

  final VoidCallback hideAfterHowTo;

  static _PromptUiScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PromptUiScope>();

  @override
  bool updateShouldNotify(_PromptUiScope oldWidget) =>
      hideAfterHowTo != oldWidget.hideAfterHowTo;
}

class _DismissiblePromptState extends State<_DismissiblePrompt> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    // R1: mounting a card prompt locks this session to that prompt id.
    WidgetPromptService.notePromptDisplayed(widget.id);
  }

  Future<void> _dismiss() async {
    await WidgetPromptService.markDismissed(widget.id);
    if (mounted) setState(() => _hidden = true);
  }

  /// UI-only hide after Steps / Got it. Does not touch decline / hide-until.
  void _hideAfterHowTo() {
    if (mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return widget.fallback;
    return _PromptUiScope(
      hideAfterHowTo: _hideAfterHowTo,
      child: widget.builder(context, _dismiss),
    );
  }
}

Future<void> _openHowToThenHideUi(
  BuildContext context,
  WidgetPromptId id,
) async {
  final hideAfterHowTo = _PromptUiScope.maybeOf(context)?.hideAfterHowTo;
  await WidgetPromptService.openHowToAdd(id);
  if (!context.mounted) return;
  hideAfterHowTo?.call();
}

/// A1 — slim Continue Reading row (chapter complete).
class WidgetPromptA1Row extends StatelessWidget {
  const WidgetPromptA1Row({
    super.key,
    required this.nextLabel,
    required this.onDismiss,
  });

  final String nextLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: _kPromptGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue on your Home Screen',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: _kPromptInk,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$nextLabel, one tap away.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kPromptMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _GoldChipButton(
            label: 'Add widget',
            onTap: () => _openHowToThenHideUi(context, WidgetPromptId.a1),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: _kPromptMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A2 — replaces Keep going block on streak complete (day 3+).
class WidgetPromptA2Card extends StatelessWidget {
  const WidgetPromptA2Card({
    super.key,
    required this.streakDays,
    required this.onDismiss,
  });

  final int streakDays;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.grid_view_rounded,
                  color: Color(0xFFE8C36A), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keep going — keep your flame in sight',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The streak widget shows day $streakDays on your Home Screen, so tomorrow doesn\'t sneak past you.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _GoldChipButton(
              label: 'Add',
              onTap: () => _openHowToThenHideUi(context, WidgetPromptId.a2),
            ),
          ),
        ],
      ),
    );
  }
}

/// A6 — Favorite Verse card in Library (bookmarks).
class WidgetPromptA6Card extends StatelessWidget {
  const WidgetPromptA6Card({
    super.key,
    required this.savedCount,
    required this.onDismiss,
  });

  final int savedCount;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4D2B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'FAVORITE VERSE',
                  style: TextStyle(
                    color: _kPromptGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              InkWell(
                onTap: onDismiss,
                child: const Icon(Icons.close, size: 16, color: _kPromptMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$savedCount verses saved. Let them find you.',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _kPromptInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The Favorite Verse widget rotates through everything you\'ve bookmarked.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: _kPromptMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  _openHowToThenHideUi(context, WidgetPromptId.a6),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add widget',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A8b — gold "Add widget" pill for prayer result row.
class WidgetPromptA8bPill extends StatelessWidget {
  const WidgetPromptA8bPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: _kPromptGold,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => WidgetPromptService.openHowToAdd(WidgetPromptId.a8b),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                'Add widget',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldChipButton extends StatelessWidget {
  const _GoldChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPromptGold,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
