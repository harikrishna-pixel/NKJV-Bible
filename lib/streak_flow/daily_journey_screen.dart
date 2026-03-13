import 'package:biblebookapp/streak_flow/mood_prayer_data.dart';
import 'package:biblebookapp/streak_flow/streak_saved_list_screen.dart';
import 'package:biblebookapp/streak_flow/your_faith_journey_screen.dart';
import 'package:biblebookapp/streak_flow/pour_out_worries_screen.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';
import 'package:biblebookapp/streak/streak_service.dart' show StreakService, WeekDayStatus;
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
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
  List<WeekDayStatus> _weekStatuses = List.filled(7, WeekDayStatus.future);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown = await SharPreferences.getString(SharPreferences.streakFlowLastShownDate);
    final steps = (lastShown == today) ? 4 : 0; // 4 if completed flow today
    final streak = await StreakService.getCurrentStreak();
    final statuses = await StreakService.getWeekDayStatuses();
    if (mounted) {
      setState(() {
        _stepsCompletedToday = steps;
        _currentStreak = streak;
        _weekStatuses = statuses;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    Color bgColor;
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      bgColor = themeProvider.themeMode == ThemeMode.dark
          ? CommanColor.darkPrimaryColor
          : themeProvider.backgroundColor;
    } catch (_) {
      bgColor = const Color(0xFFF5F0E6);
    }
    final gradientColors = [bgColor, bgColor, bgColor];
    final isDark = bgColor == CommanColor.darkPrimaryColor;
    final Color textColor = isDark ? Colors.white : _brown;
    final Color panelColor = isDark ? Colors.white.withOpacity(0.12) : _panel;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
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
                        'Daily Journey',
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
                      icon: Icon(Icons.library_books_rounded, color: textColor, size: 26),
                      tooltip: 'Saved',
                      onPressed: () => Get.to(() => const StreakSavedListScreen()),
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
                      onPressed: () => Get.to(() => const YourFaithJourneyScreen()),
                    ),
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
                      // Week circles: completed / missed / ongoing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (i) {
                          final status = i < _weekStatuses.length ? _weekStatuses[i] : WeekDayStatus.future;
                          final isOngoing = status == WeekDayStatus.ongoing;
                          final isCompleted = status == WeekDayStatus.completed;
                          final isMissed = status == WeekDayStatus.missed;
                          Color circleColor = panelColor.withOpacity(0.8);
                          Color borderColor = textColor.withOpacity(0.2);
                          Color iconColor = textColor.withOpacity(isDark ? 0.9 : 0.7); // future/pending
                          double borderWidth = 1;
                          if (isOngoing) {
                            circleColor = _gold.withOpacity(0.2);
                            borderColor = _gold;
                            borderWidth = 2.5;
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
                          final showLock = isMissed || status == WeekDayStatus.future;
                          return Column(
                            children: [
                              Container(
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
                                    Icon(
                                      Icons.local_fire_department_rounded,
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
                              const SizedBox(height: 4),
                              Text(
                                days[i],
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
                        value: _loaded ? (_stepsCompletedToday / 4).clamp(0.0, 1.0) : 0.75,
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
                      const SizedBox(height: 20),
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
                                Icon(Icons.star_border, color: _gold, size: 28),
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
                        onTap: () => Get.to(() => const StreakConnectionScreen()),
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
                          final item = await MoodPrayerLoader.pickItem(connectionIndex: 1);
                          if (item != null && mounted) Get.to(() => StreakVerseScreen(item: item));
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
                          final item = await MoodPrayerLoader.pickItem(connectionIndex: 1);
                          if (item != null && mounted) Get.to(() => StreakDevotionalScreen(item: item));
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
                          final item = await MoodPrayerLoader.pickItem(connectionIndex: 1);
                          if (item != null && mounted) Get.to(() => StreakPrayerScreen(item: item));
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
                      _card(
                        panelColor: panelColor,
                        textColor: textColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: _gold, size: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentStreak >= 7
                                    ? '7-day streak complete! ⭐ 100 Faith Credits earned'
                                    : '${7 - _currentStreak} more ${7 - _currentStreak == 1 ? 'day' : 'days'} to unlock ⭐ 100 Faith Credits',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  fontFamily: 'Georgia',
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
      ),
    );
  }

  Widget _sectionTitle(String text, Color textColor) {
    return Row(
      children: [
        Expanded(child: Divider(color: textColor.withOpacity(0.3), thickness: 1)),
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
        Expanded(child: Divider(color: textColor.withOpacity(0.3), thickness: 1)),
      ],
    );
  }

  Widget _card({required Widget child, required Color panelColor, required Color textColor}) {
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
            const SizedBox(width: 28, height: 28),
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
              Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
