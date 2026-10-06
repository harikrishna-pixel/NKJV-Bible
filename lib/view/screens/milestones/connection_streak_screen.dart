import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';

/// Screen 12 — Connection Streak (read-only view of [StreakService]).
class ConnectionStreakScreen extends StatefulWidget {
  const ConnectionStreakScreen({super.key});

  @override
  State<ConnectionStreakScreen> createState() => _ConnectionStreakScreenState();
}

class _ConnectionStreakScreenState extends State<ConnectionStreakScreen> {
  int _streak = 0;
  List<WeekDayStatus> _week = const [];
  bool _todayDone = false;
  bool _loading = true;

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await StreakService.getCurrentStreak();
    final week = await StreakService.getWeekDayStatuses();
    final last = await StreakService.getLastActivityDate();
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _week = week;
      _todayDone = last == today;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: 'Connection Streak',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Pc.brown))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const LaurelEmblem(
                      icon: Icons.local_fire_department_outlined,
                      size: 170,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_streak',
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Pc.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Day Streak',
                      style: TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Pc.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _streak > 0
                          ? 'You are building a\nbeautiful habit.'
                          : 'Connect with God today\nto start your streak.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 16,
                        height: 1.4,
                        color: Pc.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (i) {
                        final st = i < _week.length
                            ? _week[i]
                            : WeekDayStatus.future;
                        final done = st == WeekDayStatus.completed ||
                            (st == WeekDayStatus.ongoing && _todayDone);
                        return Column(
                          children: [
                            Text(
                              _labels[i],
                              style: TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 13,
                                fontWeight: st == WeekDayStatus.ongoing
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: Pc.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CheckCircle(done: done, size: 32),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    const OrnamentDivider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Every day with God\nbrings transformation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 15,
                        height: 1.4,
                        color: Pc.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
