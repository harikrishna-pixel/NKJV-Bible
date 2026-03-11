import 'package:biblebookapp/streak_flow/build_your_streak_dialog.dart';
import 'package:biblebookapp/streak_flow/pour_out_worries_screen.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown = await SharPreferences.getString(SharPreferences.streakFlowLastShownDate);
    final steps = (lastShown == today) ? 4 : 0; // 4 if completed flow today
    if (mounted) {
      setState(() {
        _stepsCompletedToday = steps;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final todayIndex = DateTime.now().weekday % 7; // 0=Sun .. 6=Sat

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F0E6),
              Color(0xFFEDE6D8),
              Color(0xFFE5DCC8),
            ],
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
                      icon: const Icon(Icons.arrow_back_ios, color: _brown),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'Daily Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: _brown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _brown, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _brown,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const BuildYourStreakDialog(),
                      ),
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
                      // Week circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (i) {
                          final isCurrent = i == todayIndex;
                          return Column(
                            children: [
                              Container(
                                width: isTablet ? 44 : 38,
                                height: isTablet ? 44 : 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrent ? _gold.withOpacity(0.2) : _panel.withOpacity(0.8),
                                  border: Border.all(
                                    color: isCurrent ? _gold : _brown.withOpacity(0.2),
                                    width: isCurrent ? 2.5 : 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  size: isTablet ? 22 : 18,
                                  color: isCurrent ? const Color(0xFFE65100) : _brown.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                days[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _brown,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                              if (i > todayIndex) Text('${i + 1}', style: TextStyle(fontSize: 10, color: _brown.withOpacity(0.5))),
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
                          color: _brown.withOpacity(0.9),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: _loaded ? (_stepsCompletedToday / 4).clamp(0.0, 1.0) : 0.75,
                        backgroundColor: _panel,
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step ${_stepsCompletedToday.clamp(0, 4)} of 4',
                        style: TextStyle(
                          fontSize: 12,
                          color: _brown.withOpacity(0.8),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Today's Reward
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Reward',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _brown,
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
                                    color: _brown,
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
                                color: _brown.withOpacity(0.75),
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // With Jesus
                      _sectionTitle('With Jesus'),
                      const SizedBox(height: 4),
                      Text(
                        'Spend a few moments with Him and start your day blessed!',
                        style: TextStyle(
                          fontSize: 13,
                          color: _brown.withOpacity(0.85),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _activityCard(
                        icon: Icons.favorite,
                        title: 'Connect',
                        subtitle: '1 min · Share how you feel.',
                        completed: _stepsCompletedToday >= 1,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.menu_book,
                        title: 'Verse of the Day',
                        subtitle: '1 min · Daily reading.',
                        completed: _stepsCompletedToday >= 2,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.auto_stories,
                        title: 'Devotional',
                        subtitle: '2 min · Insight for today.',
                        completed: _stepsCompletedToday >= 3,
                      ),
                      const SizedBox(height: 8),
                      _activityCard(
                        icon: Icons.whatshot,
                        title: 'Prayer',
                        subtitle: '2 min · Talk with Him.',
                        completed: _stepsCompletedToday >= 4,
                      ),
                      const SizedBox(height: 24),
                      // Seek His Presence
                      _sectionTitle('Seek His Presence'),
                      const SizedBox(height: 4),
                      Text(
                        'Share your heart with God and find His peace.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _brown.withOpacity(0.85),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _actionCard(
                        icon: Icons.favorite_border,
                        title: 'What\'s on Your Heart?',
                        subtitle: 'Share your burdens...',
                        onTap: () => Get.to(() => ChatScreen()),
                      ),
                      const SizedBox(height: 8),
                      _actionCard(
                        icon: Icons.eco,
                        title: 'Find Peace',
                        subtitle: 'Release your worries.',
                        onTap: () => Get.to(() => const PourOutWorriesScreen()),
                      ),
                      const SizedBox(height: 24),
                      // Next Milestone
                      _card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: _gold, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '3 more days to unlock ⭐ 100 Faith Credits',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _brown,
                                fontFamily: 'Georgia',
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

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: _brown.withOpacity(0.3), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _brown,
              fontFamily: 'Georgia',
            ),
          ),
        ),
        Expanded(child: Divider(color: _brown.withOpacity(0.3), thickness: 1)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _brown.withOpacity(0.06),
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
  }) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _brown, size: 26),
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
                    color: _brown,
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: _brown.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28)
          else
            const SizedBox(width: 28, height: 28),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _card(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brown, size: 26),
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
                        color: _brown,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _brown.withOpacity(0.8),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: _brown.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
