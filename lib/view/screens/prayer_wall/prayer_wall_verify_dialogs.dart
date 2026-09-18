import 'dart:math' as math;

import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_guidelines_dialog.dart';
import 'package:flutter/material.dart';

/// Prayer Wall AI verify / result dialogs (UI only — no API calls).
class PrayerWallVerifyDialogs {
  PrayerWallVerifyDialogs._();

  static const Color cream = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF4B3423);
  static const Color muted = Color(0xFF6B4E3D);
  static const Color brown = Color(0xFF5C4033);
  static const Color gold = Color(0xFFC9A227);
  static const Color green = Color(0xFF2E9B4B);
  static const Color softPink = Color(0xFFF8E6E6);
  static const Color softRed = Color(0xFFD96B6B);
  static const Color tipPink = Color(0xFFFBEDED);
  static const Color tipRed = Color(0xFFB85C5C);
  static const Color thankBox = Color(0xFFF7F1EA);

  /// Non-dismissible verifying overlay. Caller updates [controller], then pops.
  static Future<void> showVerifying(
    BuildContext context, {
    required PrayerVerifyProgressController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => PopScope(
        canPop: false,
        child: _VerifyingDialog(controller: controller),
      ),
    );
  }

  /// Success after AI + publish. Returns `true` when "View Prayer Wall" is tapped.
  static Future<bool?> showVerified(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _VerifiedDialog(),
    );
  }

  /// Invalid content. Returns `'edit'` or `'cancel'`.
  static Future<String?> showInappropriate(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _InappropriateDialog(),
    );
  }

  static Widget diamondDivider({Color color = const Color(0xFFD9CBB8)}) {
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 7,
              height: 7,
              color: color,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1, height: 1)),
      ],
    );
  }
}

/// 0 = none done (step 1 active), 4 = all done.
class PrayerVerifyProgressController extends ChangeNotifier {
  int _completedCount = 0;

  int get completedCount => _completedCount;

  void setCompleted(int count) {
    final next = count.clamp(0, 4);
    if (next == _completedCount) return;
    _completedCount = next;
    notifyListeners();
  }

  Future<void> advanceTo(int count, {Duration stepDelay = const Duration(milliseconds: 450)}) async {
    while (_completedCount < count.clamp(0, 4)) {
      await Future<void>.delayed(stepDelay);
      setCompleted(_completedCount + 1);
    }
  }
}

class _VerifyingDialog extends StatelessWidget {
  const _VerifyingDialog({required this.controller});

  final PrayerVerifyProgressController controller;

  static const _steps = [
    ('1. Checking your prayer ...', 'Reading your prayer.'),
    ('2. AI content review ...', 'Making sure the content is appropriate.'),
    ('3. Checking community guidelines ...', 'Ensuring it follows our guidelines.'),
    ('4. Preparing to publish ...', 'Getting your prayer ready.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Material(
        color: PrayerWallVerifyDialogs.cream,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final done = controller.completedCount;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CrossRadianceIcon(),
                  const SizedBox(height: 14),
                  const Text(
                    'Verifying your prayer...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: PrayerWallVerifyDialogs.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Our AI is carefully reviewing your prayer to keep the Prayer Wall safe and meaningful for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: PrayerWallVerifyDialogs.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrayerWallVerifyDialogs.diamondDivider(),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _steps.length; i++) ...[
                    _VerifyStepRow(
                      title: _steps[i].$1,
                      subtitle: _steps[i].$2,
                      status: done > i
                          ? _StepStatus.done
                          : (done == i
                              ? _StepStatus.active
                              : _StepStatus.pending),
                      showConnector: i < _steps.length - 1,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { done, active, pending }

class _VerifyStepRow extends StatelessWidget {
  const _VerifyStepRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.showConnector,
  });

  final String title;
  final String subtitle;
  final _StepStatus status;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              _StepBadge(status: status),
              if (showConnector)
                Container(
                  width: 1.5,
                  height: 28,
                  margin: const EdgeInsets.only(top: 4),
                  color: const Color(0xFFD9CBB8),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showConnector ? 10 : 0, top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: PrayerWallVerifyDialogs.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: PrayerWallVerifyDialogs.muted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.status});

  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _StepStatus.done:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: PrayerWallVerifyDialogs.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case _StepStatus.active:
        return SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PrayerWallVerifyDialogs.gold,
            backgroundColor: PrayerWallVerifyDialogs.gold.withValues(alpha: 0.2),
          ),
        );
      case _StepStatus.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PrayerWallVerifyDialogs.ink.withValues(alpha: 0.45),
              width: 1.6,
            ),
          ),
        );
    }
  }
}

class _CrossRadianceIcon extends StatelessWidget {
  const _CrossRadianceIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RadiancePainter(
              color: PrayerWallVerifyDialogs.gold.withValues(alpha: 0.55),
            ),
          ),
          const Icon(
            Icons.add,
            size: 34,
            color: PrayerWallVerifyDialogs.brown,
          ),
        ],
      ),
    );
  }
}

class _RadiancePainter extends CustomPainter {
  _RadiancePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const rays = 16;
    for (var i = 0; i < rays; i++) {
      final a = (i / rays) * math.pi * 2;
      final inner = 18.0;
      final outer = i.isEven ? 32.0 : 28.0;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadiancePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _VerifiedDialog extends StatelessWidget {
  const _VerifiedDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Material(
        color: PrayerWallVerifyDialogs.cream,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SuccessSparkleIcon(),
              const SizedBox(height: 14),
              const Text(
                'Prayer Verified!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: PrayerWallVerifyDialogs.ink,
                ),
              ),
              const SizedBox(height: 12),
              PrayerWallVerifyDialogs.diamondDivider(),
              const SizedBox(height: 14),
              const Text(
                'Your prayer is ready to be shared on the Prayer Wall.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: PrayerWallVerifyDialogs.muted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: PrayerWallVerifyDialogs.thankBox,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: PrayerWallVerifyDialogs.gold,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thank you for lifting it in prayer.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: PrayerWallVerifyDialogs.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PrayerWallVerifyDialogs.brown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Prayer Wall',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 22),
                    ],
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

class _SuccessSparkleIcon extends StatelessWidget {
  const _SuccessSparkleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(88, 88),
            painter: _RadiancePainter(
              color: PrayerWallVerifyDialogs.green.withValues(alpha: 0.45),
            ),
          ),
          const Positioned(
            top: 6,
            right: 14,
            child: Icon(Icons.star, size: 12, color: PrayerWallVerifyDialogs.gold),
          ),
          const Positioned(
            top: 18,
            left: 10,
            child: Icon(Icons.star, size: 10, color: PrayerWallVerifyDialogs.gold),
          ),
          const Positioned(
            bottom: 12,
            right: 10,
            child: Icon(Icons.star, size: 11, color: PrayerWallVerifyDialogs.gold),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: PrayerWallVerifyDialogs.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _InappropriateDialog extends StatelessWidget {
  const _InappropriateDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Material(
        color: PrayerWallVerifyDialogs.cream,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ErrorSparkleIcon(),
              const SizedBox(height: 14),
              const Text(
                'We couldn\'t post your prayer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PrayerWallVerifyDialogs.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Our AI review found that your prayer may not be suitable for the Prayer Wall.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: PrayerWallVerifyDialogs.muted,
                ),
              ),
              const SizedBox(height: 14),
              PrayerWallVerifyDialogs.diamondDivider(),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: PrayerWallVerifyDialogs.tipPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: PrayerWallVerifyDialogs.softRed,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please avoid offensive language, harm to others, advertising, or unrelated content.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: PrayerWallVerifyDialogs.tipRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PrayerWallVerifyDialogs.brown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Edit My Prayer',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PrayerWallVerifyDialogs.brown,
                    side: const BorderSide(
                      color: PrayerWallVerifyDialogs.brown,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PrayerWallGuidelinesDialog.helpLink(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorSparkleIcon extends StatelessWidget {
  const _ErrorSparkleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 8,
            right: 16,
            child: Icon(Icons.star, size: 12, color: Color(0xFFE8A0A0)),
          ),
          const Positioned(
            top: 20,
            left: 12,
            child: Icon(Icons.star, size: 10, color: Color(0xFFE8A0A0)),
          ),
          const Positioned(
            bottom: 14,
            right: 12,
            child: Icon(Icons.star, size: 11, color: Color(0xFFE8A0A0)),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PrayerWallVerifyDialogs.softPink,
              shape: BoxShape.circle,
              border: Border.all(
                color: PrayerWallVerifyDialogs.softRed.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: PrayerWallVerifyDialogs.softRed,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
