import 'dart:async';

import 'package:flutter/material.dart';

/// True on iPad-sized screens (repeat-tap guards are iPad-only).
bool isTabletLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// Wrap a modal sheet's content: for [delay] after it opens, a tap on the
/// dimmed area outside does not close it (a fast repeat tap would otherwise
/// land on that area and dismiss the sheet at once). Buttons inside that call
/// `Navigator.pop` still work immediately.
class DelayedBarrierDismiss extends StatefulWidget {
  const DelayedBarrierDismiss({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 600),
  });

  final Widget child;
  final bool enabled;
  final Duration delay;

  @override
  State<DelayedBarrierDismiss> createState() => _DelayedBarrierDismissState();
}

class _DelayedBarrierDismissState extends State<DelayedBarrierDismiss> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _ready = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return PopScope(canPop: _ready, child: widget.child);
  }
}

/// Briefly swallows every tap on screen (e.g. while a menu fades out or a
/// player slides away) so repeat taps can't hit the screen underneath.
/// Returns a callback that removes the shield early.
VoidCallback showTapShield(
  BuildContext context, {
  Duration duration = const Duration(milliseconds: 500),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return () {};
  final entry = OverlayEntry(
    builder: (_) => const Positioned.fill(
      child: AbsorbPointer(child: SizedBox.expand()),
    ),
  );
  overlay.insert(entry);
  var removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  Timer(duration, remove);
  return remove;
}
