import 'package:biblebookapp/view/screens/connection_paths/connection_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/my_paths_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:biblebookapp/view/screens/milestones/connection_streak_screen.dart';
import 'package:biblebookapp/view/screens/milestones/milestone_celebration_coordinator.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_progress.dart';
import 'package:biblebookapp/view/screens/milestones/milestones_screen.dart';
import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// My Connection hub — summary + entry to Milestones (additive UI).
/// Visual layout matches parchment Screen 11; progress still read-only.
class MyConnectionScreen extends StatefulWidget {
  const MyConnectionScreen({super.key});

  @override
  State<MyConnectionScreen> createState() => _MyConnectionScreenState();
}

class _MyConnectionScreenState extends State<MyConnectionScreen> {
  static const _ink = Color(0xFF2C1E1A);
  static const _brown = Color(0xFF4A3728);

  ConnectionHubStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await MilestonesProgressService.hubStats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
    // Additive unlock popup — does not change hub stats / progress logic.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MilestoneCelebrationCoordinator.checkAndShow(context);
    });
  }

  Future<void> _push(Widget page) async {
    await Get.to(() => page, transition: Transition.cupertino);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Pc.bgAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: _loading || s == null
              ? const Center(child: CircularProgressIndicator(color: _brown))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back, color: _ink),
                          ),
                          const Expanded(
                            child: Text(
                              'My Connection',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                        children: [
                          GestureDetector(
                            onTap: () => _push(const ConnectionStreakScreen()),
                            child:
                                _DaysConnectedCard(days: s.totalConnectedDays),
                          ),
                          const SizedBox(height: 14),
                          if (s.activePathTitle != null) ...[
                            GestureDetector(
                              onTap: () {
                                final p = s.activePathId == null
                                    ? null
                                    : ConnectionPathsData.byId(s.activePathId!);
                                _push(p == null
                                    ? const ConnectionPathsScreen()
                                    : PathOverviewScreen(path: p));
                              },
                              child: _CurrentPathCard(
                                title: s.activePathTitle!,
                                day: s.activePathDay,
                                total: s.activePathTotal,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            GestureDetector(
                              onTap: () =>
                                  _push(const ConnectionPathsScreen()),
                              child: const _StartPathCard(),
                            ),
                            const SizedBox(height: 14),
                          ],
                          GestureDetector(
                            onTap: () =>
                                _push(const MyPathsScreen(initialTab: 1)),
                            child: _StatsStrip(
                              pathsCompleted: s.pathsCompleted,
                              prayersJoined: s.prayersJoined,
                              answersReceived: s.answersReceived,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _PrimaryButton(
                            label: 'View All Paths & Milestones',
                            onPressed: () => _push(const MilestonesScreen()),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: ParchmentLinkButton(
                              label: 'My Paths',
                              onPressed: () => _push(const MyPathsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DaysConnectedCard extends StatelessWidget {
  const _DaysConnectedCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 52,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1E1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Days Connected',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1E1A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep going!',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF7A6A5A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 110,
            height: 120,
            child: CustomPaint(painter: _LanternPainter()),
          ),
        ],
      ),
    );
  }
}

class _StartPathCard extends StatelessWidget {
  const _StartPathCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT PATH',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Pc.muted,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Start a Connection Path',
                  style: TextStyle(
                    fontFamily: Pc.serif,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Pc.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Grow closer to God one day at a time.',
                  style: TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 13,
                    color: Pc.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Pc.brown),
        ],
      ),
    );
  }
}

class _CurrentPathCard extends StatelessWidget {
  const _CurrentPathCard({
    required this.title,
    required this.day,
    required this.total,
  });

  final String title;
  final int day;
  final int total;

  @override
  Widget build(BuildContext context) {
    final frac = total <= 0 ? 0.0 : (day / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT PATH',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A6A5A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF2C1E1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day ${(day + 1).clamp(1, total)} of $total',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    color: Color(0xFF7A6A5A),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE8DFD2),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF4A3728)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 56,
            height: 64,
            child: CustomPaint(painter: _SproutPainter()),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.pathsCompleted,
    required this.prayersJoined,
    required this.answersReceived,
  });

  final int pathsCompleted;
  final int prayersJoined;
  final int answersReceived;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$pathsCompleted',
              label: 'Paths\nCompleted',
            ),
          ),
          Container(width: 1, height: 52, color: const Color(0xFFD4C4A8)),
          Expanded(
            child: _StatCell(
              value: '$prayersJoined',
              label: 'Prayers\nJoined',
            ),
          ),
          Container(width: 1, height: 52, color: const Color(0xFFD4C4A8)),
          Expanded(
            child: _StatCell(
              value: '$answersReceived',
              label: 'Answers\nReceived',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C1E1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 12,
            height: 1.2,
            color: Color(0xFF7A6A5A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5A4332), Color(0xFF3D2B1F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D2B1F).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFFFFFBF5).withOpacity(0.92),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFD4C4A8), width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF3D2B1F).withOpacity(0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// Simple parchment-style oil lantern (Screen 11 illustration).
class _LanternPainter extends CustomPainter {
  const _LanternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = const Color(0xFFC9A227).withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = const Color(0xFFF2CF5A).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cx = size.width * 0.48;
    final top = size.height * 0.08;
    final bodyTop = size.height * 0.28;
    final bodyBottom = size.height * 0.72;
    final baseY = size.height * 0.82;

    // Soft glow behind glass
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, (bodyTop + bodyBottom) / 2),
        width: size.width * 0.42,
        height: size.height * 0.38,
      ),
      glow,
    );

    // Handle arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, top + 6),
        width: size.width * 0.34,
        height: size.height * 0.22,
      ),
      3.6,
      2.1,
      false,
      ink,
    );

    // Cap
    final cap = Path()
      ..moveTo(cx - size.width * 0.16, bodyTop)
      ..lineTo(cx - size.width * 0.1, top + 14)
      ..lineTo(cx + size.width * 0.1, top + 14)
      ..lineTo(cx + size.width * 0.16, bodyTop)
      ..close();
    canvas.drawPath(cap, ink);

    // Glass body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - size.width * 0.18,
        bodyTop,
        cx + size.width * 0.18,
        bodyBottom,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, ink);

    // Flame
    final flame = Path()
      ..moveTo(cx, bodyTop + 14)
      ..quadraticBezierTo(
        cx + 8,
        bodyTop + 28,
        cx,
        bodyTop + 42,
      )
      ..quadraticBezierTo(
        cx - 8,
        bodyTop + 28,
        cx,
        bodyTop + 14,
      );
    canvas.drawPath(
      flame,
      Paint()
        ..color = const Color(0xFFE8A317)
        ..style = PaintingStyle.fill,
    );

    // Base
    canvas.drawLine(
      Offset(cx - size.width * 0.22, bodyBottom),
      Offset(cx + size.width * 0.22, bodyBottom),
      ink,
    );
    canvas.drawLine(
      Offset(cx - size.width * 0.14, baseY),
      Offset(cx + size.width * 0.14, baseY),
      ink,
    );
    canvas.drawLine(
      Offset(cx - size.width * 0.1, bodyBottom),
      Offset(cx - size.width * 0.08, baseY),
      ink,
    );
    canvas.drawLine(
      Offset(cx + size.width * 0.1, bodyBottom),
      Offset(cx + size.width * 0.08, baseY),
      ink,
    );

    // Grass / wheat strokes
    final grass = Paint()
      ..color = const Color(0xFF6B5A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final dx in [-28.0, -18.0, 18.0, 28.0, 36.0]) {
      final x = cx + dx;
      canvas.drawArc(
        Rect.fromLTWH(x - 10, baseY - 28, 20, 40),
        dx < 0 ? 1.2 : 2.8,
        1.2,
        false,
        grass,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Line-art sprout for Current Path card (Screen 11).
class _SproutPainter extends CustomPainter {
  const _SproutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF4A3728)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width * 0.5;
    final stem = Path()
      ..moveTo(cx, size.height * 0.92)
      ..quadraticBezierTo(
        cx - 2,
        size.height * 0.55,
        cx,
        size.height * 0.22,
      );
    canvas.drawPath(stem, p);

    // Left leaf
    final left = Path()
      ..moveTo(cx, size.height * 0.48)
      ..quadraticBezierTo(
        cx - 22,
        size.height * 0.36,
        cx - 6,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        cx - 4,
        size.height * 0.38,
        cx,
        size.height * 0.48,
      );
    canvas.drawPath(left, p);

    // Right leaf
    final right = Path()
      ..moveTo(cx, size.height * 0.42)
      ..quadraticBezierTo(
        cx + 24,
        size.height * 0.28,
        cx + 8,
        size.height * 0.14,
      )
      ..quadraticBezierTo(
        cx + 6,
        size.height * 0.3,
        cx,
        size.height * 0.42,
      );
    canvas.drawPath(right, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
