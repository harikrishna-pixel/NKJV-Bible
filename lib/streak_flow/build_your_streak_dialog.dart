import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';

/// "Build Your Daily Streak" dialog shown when tapping (i) on Daily Journey.
/// Parchment style, 5 steps + completion reward, "Got it" button.
class BuildYourStreakDialog extends StatelessWidget {
  const BuildYourStreakDialog({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _panel = Color(0xFFF5F0E6);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    Color dialogBackground;
    Color textColor;
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDark = themeProvider.themeMode == ThemeMode.dark;
      dialogBackground = isDark ? CommanColor.darkPrimaryColor : themeProvider.backgroundColor;
      textColor = isDark ? Colors.white : _brown;
    } catch (_) {
      dialogBackground = const Color(0xFFF8F4EB);
      textColor = _brown;
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: isTablet ? 400 : 340),
        decoration: BoxDecoration(
          color: dialogBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 28 : 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Build Your Daily Streak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay connected with God each day',
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    color: textColor.withOpacity(0.85),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 20),
                _stepRow(context, Icons.favorite, 'Connection', 'Share how you feel today', textColor, dialogBackground),
                const SizedBox(height: 8),
                _stepRow(context, Icons.menu_book, 'Verse of the Day', 'Receive God\'s Word', textColor, dialogBackground),
                const SizedBox(height: 8),
                _stepRow(context, Icons.auto_stories, 'Devotional', 'Read a thoughtful devotional', textColor, dialogBackground),
                const SizedBox(height: 8),
                _stepRow(context, Icons.whatshot, 'Prayer', 'Get a prayer based on your mood', textColor, dialogBackground),
                const SizedBox(height: 8),
                _rewardStepRow(context, textColor, dialogBackground),
                const SizedBox(height: 16),
                Text(
                  'Complete all steps to grow your streak!',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: textColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _gold, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Got it',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.w600,
                                color: _gold,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20, color: _gold),
                          ],
                        ),
                      ),
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

  Widget _stepRow(BuildContext context, IconData icon, String title, String desc, Color textColor, Color panelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: panelColor == CommanColor.darkPrimaryColor ? Colors.white.withOpacity(0.12) : _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(0.25),
              border: Border.all(color: _gold.withOpacity(0.5)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.8),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardStepRow(BuildContext context, Color textColor, Color panelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: panelColor == CommanColor.darkPrimaryColor ? Colors.white.withOpacity(0.12) : _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(0.25),
              border: Border.all(color: _gold.withOpacity(0.5)),
            ),
            child: Icon(Icons.card_giftcard, color: textColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completion Reward',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+20 Faith Credits',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.9),
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
