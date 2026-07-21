import 'dart:convert';
import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_list_screen.dart';
import 'package:biblebookapp/streak_flow/your_faith_journey_screen.dart';
import 'package:biblebookapp/streak_flow/pour_out_worries_screen.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/streak/streak_service.dart'
    show StreakService, WeekDayStatus;
import 'package:biblebookapp/streak/streak_live_activity.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';

/// Daily Journey screen: weekly streak, Today's Reward, With Jesus (4 steps), Seek His Presence (What's on Your Heart, Find Peace).
/// Shown when user taps Streak icon on Home. Info (i) shows Build Your Daily Streak dialog.
class DailyJourneyScreen extends StatefulWidget {
  const DailyJourneyScreen({super.key});

  @override
  State<DailyJourneyScreen> createState() => _DailyJourneyScreenState();
}

class _DailyJourneyScreenState extends State<DailyJourneyScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _panel = Color(0xFFF8F4EB);

  int _stepsCompletedToday = 0;
  bool _loaded = false;
  int _currentStreak = 0;
  Map<String, int> _stepsByDay = {};
  List<String> _completedDates = [];
  DateTime? _installDateOnly;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _journeyAnchor() => _installDateOnly ?? _dateOnly(DateTime.now());

  /// Journey slots 0–6 map to install day through install+6 (7-day challenge from start).
  DateTime _dayDateForViewIndex(int viewIndex) =>
      _journeyAnchor().add(Duration(days: viewIndex));

  int? _todayJourneyViewIndex() {
    final anchor = _journeyAnchor();
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(anchor).inDays;
    if (diff < 0 || diff > 6) return null;
    return diff;
  }

  String _weekdayLabelForDate(DateTime d) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return labels[d.weekday % 7];
  }

  bool _isDayFullyCompleted(String dayKey) {
    return (_stepsByDay[dayKey] ?? 0) >= 4 ||
        _completedDates.contains(dayKey);
  }

  WeekDayStatus _statusForInstallWeekDay(DateTime dayDate) {
    final today = _dateOnly(DateTime.now());
    final d = _dateOnly(dayDate);
    final anchor = _journeyAnchor();
    final journeyEnd = anchor.add(const Duration(days: 6));

    if (d.isBefore(anchor) || d.isAfter(journeyEnd)) {
      return WeekDayStatus.future;
    }
    if (d.isAfter(today)) return WeekDayStatus.future;
    if (d == today) return WeekDayStatus.ongoing;

    final dayKey = d.toIso8601String().split('T')[0];
    if (_isDayFullyCompleted(dayKey)) return WeekDayStatus.completed;
    return WeekDayStatus.missed;
  }

  String _dayKeyForViewIndex(int viewIndex) =>
      _dayDateForViewIndex(viewIndex).toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    int steps = 0;
    if (lastShown == today) {
      steps = 4;
    } else {
      final started = await SharPreferences.getString(
          SharPreferences.streakFlowStartedDate);
      if (started == today) {
        final s = await SharPreferences.getInt(
            SharPreferences.streakFlowStepsCompletedToday);
        steps = s ?? 0;
      }
    }
    final streak = await StreakService.getCurrentStreak();

    // Save the "install/open" date once so the calendar UI starts from that weekday.
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final installRaw =
        await SharPreferences.getString(SharPreferences.appInstalledDate);
    final installDate = (installRaw == null || installRaw.trim().isEmpty)
        ? DateTime.now()
        : DateTime.tryParse(installRaw) ?? DateTime.now();
    if (installRaw == null || installRaw.trim().isEmpty) {
      await SharPreferences.setString(
        SharPreferences.appInstalledDate,
        todayKey,
      );
    }
    final rawStepsMap =
        await SharPreferences.getString(SharPreferences.streakFlowStepsByDay);
    final completedDates =
        await SharPreferences.getStringList(SharPreferences.streakCompletedDates) ??
            <String>[];
    Map<String, int> parsedStepsMap = {};
    if (rawStepsMap != null && rawStepsMap.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawStepsMap);
        if (decoded is Map) {
          parsedStepsMap = decoded.map((k, v) {
            final numVal = v is num ? v : int.tryParse(v.toString()) ?? 0;
            return MapEntry(k.toString(), numVal.toInt());
          });
        }
      } catch (_) {
        parsedStepsMap = {};
      }
    }
    if (mounted) {
      setState(() {
        _stepsCompletedToday = steps;
        _currentStreak = streak;
        _stepsByDay = parsedStepsMap;
        _completedDates = List<String>.from(completedDates);
        _installDateOnly = _dateOnly(installDate);
        _loaded = true;
      });
    }
    // UI mirror only — does not change streak / journey state above.
    StreakLiveActivitySync.sync(forceStart: true);
  }

  Future<void> _storeTodaySteps(int steps) async {
    final dayKey = DateTime.now().toIso8601String().split('T')[0];
    final raw =
        await SharPreferences.getString(SharPreferences.streakFlowStepsByDay);
    Map<String, dynamic> map = {};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        } else if (decoded is Map) {
          map = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {
        map = {};
      }
    }
    map[dayKey] = steps.clamp(0, 4);
    await SharPreferences.setString(
      SharPreferences.streakFlowStepsByDay,
      jsonEncode(map),
    );
  }

  Future<void> _openDayJourneyCards({
    required int dayIndex,
    required String dayKey,
    required String dayLabel,
    required Color textColor,
    required Color panelColor,
    required bool isDark,
    required int stepsCompletedForDay,
  }) async {
    final item = await _resolveDayItem(dayKey);
    if (!mounted) return;
    if (item == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DayJourneyCardsScreen(
          dayLabel: dayLabel,
          item: item,
          textColor: textColor,
          panelColor: panelColor,
          isDark: isDark,
          stepsCompletedForDay: stepsCompletedForDay,
        ),
      ),
    );
  }

  MoodPrayerItem? _decodeStoredDayItem(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return MoodPrayerItem(
        connectionLevel: (raw['connectionLevel'] as num?)?.toInt() ?? 20,
        bookName: (raw['bookName'] ?? '').toString(),
        bookNumber: (raw['bookNumber'] as num?)?.toInt() ?? 0,
        chapterNumber: (raw['chapterNumber'] as num?)?.toInt() ?? 0,
        verseNumber: (raw['verseNumber'] as num?)?.toInt() ?? 0,
        verseText: (raw['verseText'] ?? '').toString(),
        devotionalText: (raw['devotionalText'] ?? '').toString(),
        prayerText: (raw['prayerText'] ?? '').toString(),
        connectionSliderValue:
            (raw['connectionSliderValue'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<MoodPrayerItem?> _resolveDayItem(String dayKey) async {
    final rawItems =
        await SharPreferences.getString(SharPreferences.streakFlowItemByDay);
    if (rawItems != null && rawItems.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is Map) {
          final stored = _decodeStoredDayItem(decoded[dayKey]);
          if (stored != null) return stored;
        }
      } catch (_) {}
    }
    return MoodPrayerLoader.pickItem(connectionIndex: 1);
  }

  /// Opens a completed step. All 4 done → swipeable pager; otherwise single screen only.
  Future<void> _openTodayFaithStep(int step) async {
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final item = await _resolveDayItem(todayKey);
    if (!mounted) return;

    if (_stepsCompletedToday >= 4) {
      Get.to(() => FaithJourneyStepPager(
            initialStep: step,
            item: item,
            initialSliderValue: item?.connectionSliderValue,
            viewOnly: true,
            stepsCompleted: 4,
          ));
      return;
    }

    switch (step) {
      case 1:
        Get.to(() => StreakConnectionScreen(
              viewOnly: false,
              initialSliderValue: item?.connectionSliderValue,
            ));
        return;
      case 2:
        if (item == null) return;
        Get.to(() => StreakVerseScreen(
              item: item,
              viewOnly: false,
            ));
        return;
      case 3:
        if (item == null) return;
        Get.to(() => StreakDevotionalScreen(
              item: item,
              viewOnly: false,
            ));
        return;
      case 4:
        if (item == null) return;
        Get.to(() => StreakPrayerScreen(
              item: item,
              viewOnly: false,
            ));
        return;
    }
  }

  Future<void> _onDayTap({
    required int dayIndex,
    required WeekDayStatus status,
    required bool effectiveCompleted,
    required Color textColor,
    required Color panelColor,
    required String dayLabel,
  }) async {
    final todayKey = DateTime.now().toIso8601String().split('T')[0];

    final dayKey = _dayKeyForViewIndex(dayIndex);
    final resolvedStatus = _statusForInstallWeekDay(_dayDateForViewIndex(dayIndex));

    if (resolvedStatus == WeekDayStatus.future) {
      if (!mounted) return;
      Constants.showToast('Your streak days are coming soon.');
      return;
    }

    final stored = _stepsByDay[dayKey];
    final stepsForDay = (dayKey == todayKey)
        ? ((stored != null && stored > 0) ? stored : _stepsCompletedToday)
        : (stored ?? (resolvedStatus == WeekDayStatus.completed ? 4 : 0));

    if (stepsForDay <= 0) {
      if (!mounted) return;
      Constants.showToast('No completed faith journey for this day.');
      return;
    }

    await _openDayJourneyCards(
      dayIndex: dayIndex,
      dayKey: dayKey,
      dayLabel: dayLabel,
      textColor: textColor,
      panelColor: panelColor,
      isDark: panelColor != _panel,
      stepsCompletedForDay: stepsForDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    Color bgColor;
    try {
      bgColor = themeProvider.themeMode == ThemeMode.dark
          ? CommanColor.darkPrimaryColor
          : themeProvider.backgroundColor;
    } catch (_) {
      bgColor = const Color(0xFFF5F0E6);
    }
    final isDark = bgColor == CommanColor.darkPrimaryColor;
    final isWhiteLight = !isDark &&
        themeProvider.currentCustomTheme == AppCustomTheme.white;
    final Color accentBrown = isWhiteLight ? const Color(0xFF424242) : _brown;
    final Color textColor = isDark ? Colors.white : accentBrown;
    final Color panelColor = isDark
        ? Colors.white.withOpacity(0.12)
        : (isWhiteLight ? const Color(0xFFF0F0F0) : _panel);

    // Journey slots 0–6 = install day through install+6.
    final int? todayViewIndex = _todayJourneyViewIndex();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(color: bgColor),
        child: SafeArea(
          child: Column(
            children: [
              // Header: back, title, info
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
                        'Faith Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.library_books_rounded,
                          color: textColor, size: 26),
                      tooltip: 'Saved to Faith Journey',
                      onPressed: () =>
                          Get.to(() => const StreakSavedListScreen()),
                    ),
                    IconButton(
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: textColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          Get.to(() => const YourFaithJourneyScreen()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    // Pinned: weekly streak + today's progress (scrolls independently below).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Week circles: completed / missed / ongoing
                          Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (i) {
                          final dayDate = _dayDateForViewIndex(i);
                          final dayKey = dayDate.toIso8601String().split('T')[0];
                          final dayLabel = _weekdayLabelForDate(dayDate);
                          final status = _statusForInstallWeekDay(dayDate);
                          final isToday = todayViewIndex == i;
                          final todayFullyCompleted =
                              isToday && _stepsCompletedToday >= 4;
                          final storedSteps = _stepsByDay[dayKey];
                          final int effectiveStepsForDay = (dayKey ==
                                  DateTime.now()
                                      .toIso8601String()
                                      .split('T')[0])
                              ? ((_stepsByDay[dayKey] ?? 0) > 0
                                  ? (_stepsByDay[dayKey] ?? 0)
                                  : _stepsCompletedToday)
                              : (storedSteps ??
                                  (_completedDates.contains(dayKey) ? 4 : 0));
                          final bool storedCompleted =
                              effectiveStepsForDay >= 4;

                          final bool isOngoing =
                              status == WeekDayStatus.ongoing &&
                                  !storedCompleted;
                          final bool isCompleted =
                              storedCompleted || todayFullyCompleted;
                          final bool isMissed = status == WeekDayStatus.missed;
                          final bool isFutureDay =
                              status == WeekDayStatus.future;
                          final bool isStartedNotFinished = !isFutureDay &&
                              !isCompleted &&
                              !isToday &&
                              effectiveStepsForDay > 0 &&
                              effectiveStepsForDay < 4;
                          Color circleColor = panelColor.withOpacity(0.8);
                          Color borderColor = textColor.withOpacity(0.2);
                          Color iconColor = textColor.withOpacity(
                              isDark ? 0.9 : 0.7); // future/pending
                          double borderWidth = 1;
                          if (isFutureDay) {
                            circleColor = panelColor.withOpacity(0.75);
                            borderColor = textColor.withOpacity(0.25);
                            borderWidth = 1;
                          } else if (isOngoing || isStartedNotFinished) {
                            circleColor = _gold.withOpacity(0.2);
                            borderColor = _gold.withOpacity(0.35);
                            borderWidth = 1.5;
                            iconColor = const Color(0xFFE65100);
                          } else if (isCompleted) {
                            circleColor = _gold.withOpacity(0.25);
                            borderColor = _gold;
                            iconColor = const Color(0xFFE65100);
                          } else if (isMissed) {
                            circleColor = panelColor.withOpacity(0.6);
                            borderColor = textColor.withOpacity(0.3);
                            iconColor = textColor.withOpacity(0.4);
                          }
                          final showLock = isFutureDay ||
                              (isMissed && effectiveStepsForDay == 0);
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => _onDayTap(
                                  dayIndex: i,
                                  status: status,
                                  effectiveCompleted: isCompleted,
                                  textColor: textColor,
                                  panelColor: panelColor,
                                  dayLabel: dayLabel,
                                ),
                                child: Container(
                                  width: isTablet ? 44 : 38,
                                  height: isTablet ? 44 : 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: circleColor,
                                    border: Border.all(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Show correct partial/full ring based on the real
                                      // number of steps completed for this day (0-4).
                                      if ((isOngoing ||
                                              isStartedNotFinished ||
                                              isCompleted) &&
                                          effectiveStepsForDay > 0)
                                        SizedBox(
                                          width: isTablet ? 44 : 38,
                                          height: isTablet ? 44 : 38,
                                          child: CircularProgressIndicator(
                                            value: (effectiveStepsForDay / 4)
                                                .clamp(0.0, 1.0),
                                            strokeWidth: isTablet ? 3 : 2.5,
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              _gold,
                                            ),
                                          ),
                                        ),
                                      Icon(
                                        isCompleted
                                            ? Icons
                                                .local_fire_department_rounded
                                            : Icons
                                                .local_fire_department_outlined,
                                        size: isTablet ? 22 : 18,
                                        color: iconColor,
                                      ),
                                      if (showLock)
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Transform.translate(
                                            offset: Offset(0, isTablet ? 4 : 3),
                                            child: Icon(
                                              Icons.lock,
                                              size: isTablet ? 22 : 20,
                                              color: textColor.withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      Text(
                        'Your Faith Walk Today',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.9),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: _loaded
                            ? (_stepsCompletedToday / 4).clamp(0.0, 1.0)
                            : 0.75,
                        backgroundColor: panelColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step ${_stepsCompletedToday.clamp(0, 4)} of 4',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.8),
                          fontFamily: 'Georgia',
                        ),
                      ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: textColor.withOpacity(isDark ? 0.12 : 0.08),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      // Today's Reward — only when daily streak is completed (all 4 steps)
                      if (_stepsCompletedToday >= 4) ...[
                        _card(
                          panelColor: panelColor,
                          textColor: textColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Reward',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star_border,
                                      color: _gold, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+20 Faith Credits',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use points for AI Bible Chat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.75),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // With Jesus
                      _sectionTitle('With Jesus', textColor),
                      const SizedBox(height: 4),
                      Text(
                        'Spend a few moments with Him and start your day blessed!',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.85),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _activityCard(
                        icon: Icons.favorite,
                        title: 'Connect',
                        subtitle: '1 min · Share how you feel.',
                        completed: _stepsCompletedToday >= 1,
                        onTap: _stepsCompletedToday >= 1
                            ? () async => _openTodayFaithStep(1)
                            : () => Get.to(
                                  () => const FaithJourneyStepPager(
                                    initialStep: 1,
                                  ),
                                ),
                        textColor: textColor,
                        panelColor: panelColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.menu_book,
                        title: 'Verse of the Day',
                        subtitle: '1 min · Daily reading.',
                        completed: _stepsCompletedToday >= 2,
                        onTap: () async {
                          if (_stepsCompletedToday >= 2) {
                            await _openTodayFaithStep(2);
                            return;
                          }
                          final item = await MoodPrayerLoader.pickItem(
                              connectionIndex: 1);
                          if (item != null && mounted) {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                2);
                            await _storeTodaySteps(2);
                            if (mounted) {
                              Get.to(() => FaithJourneyStepPager(
                                    initialStep: 2,
                                    item: item,
                                  ));
                            }
                          }
                        },
                        textColor: textColor,
                        panelColor: panelColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.auto_stories,
                        title: 'Devotional',
                        subtitle: '2 min · Insight for today.',
                        completed: _stepsCompletedToday >= 3,
                        onTap: () async {
                          if (_stepsCompletedToday >= 3) {
                            await _openTodayFaithStep(3);
                            return;
                          }
                          final item = await MoodPrayerLoader.pickItem(
                              connectionIndex: 1);
                          if (item != null && mounted) {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                2);
                            await _storeTodaySteps(2);
                            if (mounted) {
                              Get.to(() => FaithJourneyStepPager(
                                    initialStep: 3,
                                    item: item,
                                  ));
                            }
                          }
                        },
                        textColor: textColor,
                        panelColor: panelColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.whatshot,
                        title: 'Prayer',
                        subtitle: '2 min · Talk with Him.',
                        completed: _stepsCompletedToday >= 4,
                        onTap: () async {
                          if (_stepsCompletedToday >= 4) {
                            await _openTodayFaithStep(4);
                            return;
                          }
                          final item = await MoodPrayerLoader.pickItem(
                              connectionIndex: 1);
                          if (item != null && mounted) {
                            await SharPreferences.setInt(
                                SharPreferences.streakFlowStepsCompletedToday,
                                3);
                            await _storeTodaySteps(3);
                            if (mounted) {
                              Get.to(() => FaithJourneyStepPager(
                                    initialStep: 4,
                                    item: item,
                                  ));
                            }
                          }
                        },
                        textColor: textColor,
                        panelColor: panelColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      // Seek His Presence
                      _sectionTitle('Seek His Presence', textColor),
                      const SizedBox(height: 4),
                      Text(
                        'Share your heart with God and find His peace.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.85),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _actionCard(
                        icon: Icons.favorite_border,
                        title: 'What\'s on Your Heart?',
                        subtitle: 'Share your burdens...',
                        onTap: () => Get.to(() => ChatScreen()),
                        textColor: textColor,
                        panelColor: panelColor,
                      ),
                      const SizedBox(height: 8),
                      _actionCard(
                        icon: Icons.eco,
                        title: 'Find Peace',
                        subtitle: 'Release your worries.',
                        onTap: () => Get.to(() => const PourOutWorriesScreen()),
                        textColor: textColor,
                        panelColor: panelColor,
                      ),
                      const SizedBox(height: 24),
                      // Next Milestone (dynamic by streak)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            top: BorderSide(color: _gold.withOpacity(0.45)),
                            bottom: BorderSide(color: _gold.withOpacity(0.45)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: _gold, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentStreak >= 7
                                    ? '7-day streak complete! 100 Faith Credits earned'
                                    : '${7 - _currentStreak} more ${7 - _currentStreak == 1 ? 'day' : 'days'} to unlock 100 Faith Credits',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  fontFamily: 'Georgia',
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                          ],
                        ),
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

  Widget _sectionTitle(String text, Color textColor) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: textColor.withOpacity(0.3), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        Expanded(
            child: Divider(color: textColor.withOpacity(0.3), thickness: 1)),
      ],
    );
  }

  Widget _card(
      {required Widget child,
      required Color panelColor,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _activityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    VoidCallback? onTap,
    required Color textColor,
    required Color panelColor,
    required bool isDark,
  }) {
    final content = _card(
      panelColor: panelColor,
      textColor: textColor,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
          if (completed)
            Icon(
              Icons.check_circle,
              color: isDark ? Colors.white : const Color(0xFF2E7D32),
              size: 28,
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              color: textColor.withOpacity(0.35),
              size: 24,
            ),
        ],
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color panelColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _card(
          panelColor: panelColor,
          textColor: textColor,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: textColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.8),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: textColor.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayJourneyCardsScreen extends StatelessWidget {
  const _DayJourneyCardsScreen({
    required this.dayLabel,
    required this.item,
    required this.textColor,
    required this.panelColor,
    required this.isDark,
    required this.stepsCompletedForDay,
  });

  final String dayLabel;
  final MoodPrayerItem item;
  final Color textColor;
  final Color panelColor;
  final bool isDark;
  final int stepsCompletedForDay;

  void _openDayStep(BuildContext context, int step) {
    if (stepsCompletedForDay >= 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FaithJourneyStepPager(
            initialStep: step,
            item: item,
            initialSliderValue: item.connectionSliderValue,
            viewOnly: true,
            stepsCompleted: 4,
          ),
        ),
      );
      return;
    }

    switch (step) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StreakConnectionScreen(
              viewOnly: false,
              initialSliderValue: item.connectionSliderValue,
            ),
          ),
        );
        return;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StreakVerseScreen(
              item: item,
              viewOnly: false,
            ),
          ),
        );
        return;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StreakDevotionalScreen(
              item: item,
              viewOnly: false,
            ),
          ),
        );
        return;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StreakPrayerScreen(
              item: item,
              viewOnly: false,
            ),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
                    ),
                    Expanded(
                      child: Text(
                        '$dayLabel Faith Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 14),
                _journeyCard(
                  onTap: () => _openDayStep(context, 1),
                  icon: Icons.favorite,
                  title: 'Connect',
                  subtitle: '1 min · Share how you feel.',
                  textColor: textColor,
                  panelColor: panelColor,
                  completedIndicator: stepsCompletedForDay >= 1,
                ),
                const SizedBox(height: 10),
                _journeyCard(
                  onTap: () => _openDayStep(context, 2),
                  icon: Icons.menu_book,
                  title: 'Verse of the Day',
                  subtitle: '1 min · Daily reading.',
                  textColor: textColor,
                  panelColor: panelColor,
                  completedIndicator: stepsCompletedForDay >= 2,
                ),
                const SizedBox(height: 10),
                _journeyCard(
                  onTap: () => _openDayStep(context, 3),
                  icon: Icons.auto_stories,
                  title: 'Devotional',
                  subtitle: '2 min · Insight for today.',
                  textColor: textColor,
                  panelColor: panelColor,
                  completedIndicator: stepsCompletedForDay >= 3,
                ),
                const SizedBox(height: 10),
                _journeyCard(
                  onTap: () => _openDayStep(context, 4),
                  icon: Icons.local_fire_department,
                  title: 'Prayer',
                  subtitle: '2 min · Talk with Him.',
                  textColor: textColor,
                  panelColor: panelColor,
                  completedIndicator: stepsCompletedForDay >= 4,
                ),
                const SizedBox(height: 20),
                // Intentionally no extra "verse quote" block here:
                // tapping each card opens the corresponding step screen.
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _journeyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color panelColor,
    required VoidCallback onTap,
    required bool completedIndicator,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: const Color(0xFFC9A227).withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE3CB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: textColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withOpacity(0.82),
                        fontFamily: 'Georgia',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              completedIndicator
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF56A05E), size: 28)
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: textColor.withOpacity(0.35),
                      size: 26,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
