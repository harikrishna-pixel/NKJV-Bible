import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// "Your Faith Journey" full screen: calendar, streak cards, milestones.
/// Shown when user taps info (i) on Daily Journey instead of the pop-up dialog.
class YourFaithJourneyScreen extends StatefulWidget {
  const YourFaithJourneyScreen({super.key});

  @override
  State<YourFaithJourneyScreen> createState() => _YourFaithJourneyScreenState();
}

class _YourFaithJourneyScreenState extends State<YourFaithJourneyScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _panel = Color(0xFFF8F4EB);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _startedOrange = Color(0xFFE8A030);

  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalDays = 0;
  List<String> _completedDates = [];
  String? _startedNotFinishedDate;
  DateTime _viewMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await StreakService.getCurrentStreak();
    final dates =
        await SharPreferences.getStringList(SharPreferences.streakCompletedDates) ??
            <String>[];
    final started =
        await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
    final stepsCompletedToday =
        await SharPreferences.getInt(SharPreferences.streakFlowStepsCompletedToday) ??
            0;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final best = _computeBestStreak(dates);
    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _completedDates = List.from(dates);
        _totalDays = dates.length;
        _bestStreak = best;
        _startedNotFinishedDate =
            (started == today && !dates.contains(today) && stepsCompletedToday > 0)
            ? today
            : null;
      });
    }
  }

  int _computeBestStreak(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    final sorted = List<String>.from(sortedDates)..sort();
    int best = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      try {
        final prev = DateTime.parse(sorted[i - 1]);
        final cur = DateTime.parse(sorted[i]);
        final diff = cur.difference(DateTime(prev.year, prev.month, prev.day)).inDays;
        if (diff == 1) {
          current++;
        } else {
          if (current > best) best = current;
          current = 1;
        }
      } catch (_) {
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      bgColor = themeProvider.themeMode == ThemeMode.dark
          ? CommanColor.darkPrimaryColor
          : themeProvider.backgroundColor;
    } catch (_) {
      bgColor = const Color(0xFFF5F0E6);
    }
    final isDark = bgColor == CommanColor.darkPrimaryColor;
    final textColor = isDark ? Colors.white : _brown;
    final panelColor = isDark ? Colors.white.withOpacity(0.12) : _panel;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'Your Faith Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _calendarCard(context, textColor, panelColor, isDark),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _streakCard(
                              context,
                              'Current Streak',
                              _currentStreak,
                              true,
                              textColor,
                              panelColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _streakCard(
                              context,
                              'Best Streak',
                              _bestStreak,
                              false,
                              textColor,
                              panelColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _totalDaysCard(context, textColor, panelColor),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Milestones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _milestonesList(context, textColor, panelColor),
                      const SizedBox(height: 24),
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

  Widget _calendarCard(
      BuildContext context, Color textColor, Color panelColor, bool isDark) {
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final daysInMonth = last.day;
    final firstWeekday = first.weekday % 7;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () {
                  setState(() {
                    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
                  });
                },
              ),
              Text(
                _monthYearLabel(month, year),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontFamily: 'Georgia',
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () {
                  setState(() {
                    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / 7;
              const double cellH = 46;
              final rows = <Widget>[];
              int day = 1;
              for (int i = 0; i < 6; i++) {
                final rowChildren = <Widget>[];
                for (int j = 0; j < 7; j++) {
                  if (i == 0 && j < firstWeekday) {
                    rowChildren.add(SizedBox(width: cellW, height: cellH));
                    continue;
                  }
                  if (day > daysInMonth) {
                    rowChildren.add(SizedBox(width: cellW, height: cellH));
                    continue;
                  }
                  final date = DateTime(year, month, day);
                  final key = date.toIso8601String().split('T')[0];
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isCompleted = _completedDates.contains(key);
                  final isStartedNotFinished = _startedNotFinishedDate == key;
                  rowChildren.add(
                    SizedBox(
                      width: cellW,
                      height: cellH,
                      child: Container(
                        // Don't auto-highlight a week row. Only special dates should stand out.
                        child: Center(
                          child: _dayCell(
                            day: day,
                            isToday: isToday,
                            isCompleted: isCompleted,
                            isStartedNotFinished: isStartedNotFinished,
                            isFuture: date.isAfter(today),
                            textColor: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                  day++;
                }
                rows.add(Row(children: rowChildren));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: rows,
              );
            },
          ),
          const SizedBox(height: 16),
          _legendRow(textColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Complete all 4 steps to keep your streak alive',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.9),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.local_fire_department_rounded,
                  size: 18, color: _gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIcon({
    required bool isCompleted,
    required bool isStartedNotFinished,
    required bool isToday,
    required bool isFuture,
    required Color textColor,
    bool compact = false,
  }) {
    final double size = compact ? 18 : 22;
    final double iconSize = compact ? 11 : 14;

    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _brown,
        ),
        child: Icon(Icons.check, size: iconSize, color: Colors.white),
      );
    }
    if (isStartedNotFinished) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _startedOrange,
        ),
        child: Icon(Icons.schedule_rounded,
            size: iconSize, color: Colors.white),
      );
    }
    if (isToday) {
      final double borderW = compact ? 1.0 : 1.2;
      final double innerDot = compact ? 8 : 10;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _brown, width: borderW),
        ),
        child: Container(
          width: innerDot,
          height: innerDot,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _brown,
          ),
        ),
      );
    }
    if (!isFuture) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: textColor.withOpacity(0.28), width: 1.5),
        ),
      );
    }
    return SizedBox(width: size, height: size);
  }

  String _monthYearLabel(int month, int year) {
    const names = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${names[month - 1]} $year';
  }

  Widget _dayCell({
    required int day,
    required bool isToday,
    required bool isCompleted,
    required bool isStartedNotFinished,
    required bool isFuture,
    required Color textColor,
  }) {
    return SizedBox(
      width: 28,
      height: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 11,
              height: 1.0,
              color: isFuture ? textColor.withOpacity(0.4) : textColor,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 1),
          _statusIcon(
            isCompleted: isCompleted,
            isStartedNotFinished: isStartedNotFinished,
            isToday: isToday,
            isFuture: isFuture,
            textColor: textColor,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color textColor) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(
              isCompleted: true,
              isStartedNotFinished: false,
              isToday: false,
              isFuture: false,
              textColor: textColor,
            ),
            const SizedBox(width: 6),
            Text('Completed Journey',
                style: TextStyle(fontSize: 11, color: textColor, fontFamily: 'Georgia')),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(
              isCompleted: false,
              isStartedNotFinished: true,
              isToday: false,
              isFuture: false,
              textColor: textColor,
            ),
            const SizedBox(width: 6),
            Text('Started but not finished',
                style: TextStyle(fontSize: 11, color: textColor, fontFamily: 'Georgia')),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(
              isCompleted: false,
              isStartedNotFinished: false,
              isToday: false,
              isFuture: false,
              textColor: textColor,
            ),
            const SizedBox(width: 6),
            Text('Missed day',
                style: TextStyle(fontSize: 11, color: textColor, fontFamily: 'Georgia')),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusIcon(
              isCompleted: false,
              isStartedNotFinished: false,
              isToday: true,
              isFuture: false,
              textColor: textColor,
            ),
            const SizedBox(width: 6),
            Text('Today',
                style: TextStyle(fontSize: 11, color: textColor, fontFamily: 'Georgia')),
          ],
        ),
      ],
    );
  }

  Widget _streakCard(BuildContext context, String label, int value,
      bool isCurrent, Color textColor, Color panelColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.9),
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.local_fire_department_rounded,
            size: 36,
            color: isCurrent ? _gold : textColor.withOpacity(0.4),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
          Text(
            'Days',
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.8),
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalDaysCard(
      BuildContext context, Color textColor, Color panelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Days Walked',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  'Keep walking with faith',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_totalDays',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestonesList(
      BuildContext context, Color textColor, Color panelColor) {
    final items = <({String title, String date})>[];
    if (_completedDates.isNotEmpty) {
      final sorted = List<String>.from(_completedDates)..sort();
      final first = sorted.first;
      try {
        final d = DateTime.parse(first);
        items.add((
          title: 'First Prayer Completed',
          date: '${_monthName(d.month)} ${d.day}, ${d.year}',
        ));
      } catch (_) {}
      if (_bestStreak >= 7) {
        int foundAt = -1;
        int run = 0;
        for (int i = 0; i < sorted.length; i++) {
          if (i > 0) {
            try {
              final prev = DateTime.parse(sorted[i - 1]);
              final cur = DateTime.parse(sorted[i]);
              final diff =
                  cur.difference(DateTime(prev.year, prev.month, prev.day)).inDays;
              if (diff == 1) {
                run++;
                if (run >= 6) {
                  foundAt = i;
                  break;
                }
              } else {
                run = 0;
              }
            } catch (_) {
              run = 0;
            }
          } else {
            run = 1;
          }
        }
        if (foundAt >= 0) {
          try {
            final d = DateTime.parse(sorted[foundAt]);
            items.insert(
              0,
              (
                title: '7 Day Streak Achieved',
                date: '${_monthName(d.month)} ${d.day}, ${d.year}',
              ),
            );
          } catch (_) {}
        }
      }
    }
    if (items.isEmpty) {
      items.add((
        title: 'Complete your first 4 steps',
        date: '',
      ));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        e.title.startsWith('7')
                            ? Icons.emoji_events
                            : Icons.check_circle_outline,
                        color: _gold,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            if (e.date.isNotEmpty)
                              Text(
                                e.date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.8),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }
}
