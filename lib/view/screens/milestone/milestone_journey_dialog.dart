import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Milestone pop-up before Lifetime IAP (non-dismissible barrier).
class MilestoneJourneyDialog {
  MilestoneJourneyDialog._();

  static Future<void> showScriptureMilestone(BuildContext context) {
    return _show(
      context,
      headline: 'Your Scripture Journey Is Growing',
      line1: 'We\'re grateful to be part of your journey.',
      line2: 'We have a special blessing for you.',
    );
  }

  static Future<void> showPrayerMilestone(BuildContext context) {
    return _show(
      context,
      headline: 'Your Prayer Journey is Growing.',
      line1: 'You\'ve been spending time in prayers.',
      line2: 'We\'re thankful to walk this journey with you.',
      line3: 'We have a special blessing for you.',
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String headline,
    required String line1,
    required String line2,
    String? line3,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final cream = isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF5F0E6);
    final textColor = isDark ? Colors.white : brown;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brown.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  line1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  line2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (line3 != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    line3,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.6)),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
