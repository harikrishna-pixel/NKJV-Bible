import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared "Old Paper" parchment styling for Connection Paths + Milestones.
class Pc {
  Pc._();

  static const ink = Color(0xFF2C1E1A);
  static const muted = Color(0xFF7A6A5A);
  static const brown = Color(0xFF4A3728);
  static const brownDark = Color(0xFF3D2B1F);
  static const gold = Color(0xFFC9A227);
  static const bronze = Color(0xFFA67C3D);
  static const card = Color(0xFFFFFBF5);
  static const track = Color(0xFFE8DFD2);
  static const border = Color(0xFFD4C4A8);
  static const bgAsset = 'assets/lightMode/day_bg.png';

  static const serif = 'Georgia';

  static BoxDecoration cardDecoration({double radius = 14}) => BoxDecoration(
        color: card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: brownDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

/// Parchment page with centered serif title and back arrow.
class ParchmentScaffold extends StatelessWidget {
  const ParchmentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.bottom,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottom;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Pc.bgAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: showBack
                          ? IconButton(
                              onPressed: onBack ?? () => Get.back(),
                              icon: const Icon(Icons.arrow_back, color: Pc.ink),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: Pc.serif,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Pc.ink,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 13,
                                color: Pc.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: actions.isEmpty
                          ? null
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: actions,
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParchmentCard extends StatelessWidget {
  const ParchmentCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Pc.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ParchmentButton extends StatelessWidget {
  const ParchmentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4E36), Pc.brownDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: Pc.brownDark.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
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
}

class ParchmentLinkButton extends StatelessWidget {
  const ParchmentLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: Pc.serif,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Pc.ink,
        ),
      ),
    );
  }
}

/// Small bronze-ringed circular icon (list rows).
class BronzeBadge extends StatelessWidget {
  const BronzeBadge({
    super.key,
    required this.icon,
    this.size = 46,
    this.label,
  });

  final IconData icon;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFF6E7C1), Color(0xFFE0C58C)],
        ),
        border: Border.all(color: Pc.bronze, width: 2),
        boxShadow: [
          BoxShadow(
            color: Pc.brownDark.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                fontFamily: Pc.serif,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
                color: Pc.brown,
              ),
            )
          : Icon(icon, color: Pc.brown, size: size * 0.52),
    );
  }
}

/// Large emblem: icon/number in a circle framed by a laurel wreath + rays.
class LaurelEmblem extends StatelessWidget {
  const LaurelEmblem({
    super.key,
    this.icon,
    this.text,
    this.size = 150,
    this.rays = true,
  });

  final IconData? icon;
  final String? text;
  final double size;
  final bool rays;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LaurelPainter(rays: rays)),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFF8EBC8), Color(0xFFDDBF82)],
              ),
              border: Border.all(color: Pc.bronze, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Pc.brownDark.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: text != null
                ? Text(
                    text!,
                    style: TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: inner * 0.42,
                      fontWeight: FontWeight.w700,
                      color: Pc.brown,
                    ),
                  )
                : Icon(icon ?? Icons.add, size: inner * 0.55, color: Pc.brown),
          ),
        ],
      ),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  _LaurelPainter({required this.rays});

  final bool rays;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.36;

    if (rays) {
      final rayPaint = Paint()
        ..color = Pc.bronze.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      for (var i = 0; i < 17; i++) {
        final a = math.pi + (math.pi * i / 16);
        final p1 = c + Offset(math.cos(a), math.sin(a)) * (size.width * 0.3);
        final p2 = c + Offset(math.cos(a), math.sin(a)) * (size.width * 0.49);
        canvas.drawLine(p1, p2, rayPaint);
      }
    }

    final stem = Paint()
      ..color = Pc.bronze
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final leaf = Paint()..color = const Color(0xFFB8893F);

    for (final side in [-1.0, 1.0]) {
      final rect = Rect.fromCircle(center: c, radius: r);
      final start = side < 0 ? math.pi * 0.6 : math.pi * 0.4;
      final sweep = side < 0 ? math.pi * 0.75 : -math.pi * 0.75;
      canvas.drawArc(rect, start, sweep, false, stem);
      for (var i = 0; i < 7; i++) {
        final t = start + sweep * (i + 0.5) / 7;
        final p = c + Offset(math.cos(t), math.sin(t)) * r;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(t + (side < 0 ? -0.5 : 0.5) + math.pi / 2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(side * 6, 0),
            width: size.width * 0.1,
            height: size.width * 0.045,
          ),
          leaf,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter oldDelegate) =>
      oldDelegate.rays != rays;
}

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Pc.bronze.withValues(alpha: 0.45))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.eco_rounded, size: 16, color: Pc.bronze),
        ),
        Expanded(child: Divider(color: Pc.bronze.withValues(alpha: 0.45))),
      ],
    );
  }
}

class ParchmentProgressBar extends StatelessWidget {
  const ParchmentProgressBar({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: Pc.track,
        valueColor: const AlwaysStoppedAnimation(Pc.brown),
      ),
    );
  }
}

/// Filled brown circle with white check (done) — used in lists.
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, this.done = true, this.size = 28});

  final bool done;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? Pc.brown : Colors.transparent,
        border: Border.all(color: Pc.brown, width: 1.6),
      ),
      child: done
          ? Icon(Icons.check, size: size * 0.62, color: Colors.white)
          : null,
    );
  }
}

/// Horizontal day stepper (1..N): done = check, current = filled, rest outline.
class DayStepper extends StatelessWidget {
  const DayStepper({
    super.key,
    required this.total,
    required this.completed,
    required this.current,
    this.onTapDay,
  });

  final int total;
  final Set<int> completed;
  final int current;
  final void Function(int dayIndex)? onTapDay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final done = completed.contains(i);
          final isCurrent = i == current && !done;
          return GestureDetector(
            onTap: onTapDay == null ? null : () => onTapDay!(i),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || isCurrent ? Pc.brown : Pc.card,
                    border: Border.all(color: Pc.brown, width: 1.4),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: Pc.serif,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isCurrent ? Colors.white : Pc.brown,
                          ),
                        ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Day ${i + 1}',
                  style: const TextStyle(fontSize: 9.5, color: Pc.muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// App-style parchment dialog with one primary button.
Future<void> showParchmentMessage(
  BuildContext context, {
  required String title,
  required String body,
  IconData icon = Icons.lock_outline_rounded,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Pc.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Pc.brown),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: Pc.serif,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: Pc.serif,
                fontSize: 14,
                height: 1.4,
                color: Pc.muted,
              ),
            ),
            const SizedBox(height: 18),
            ParchmentButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
