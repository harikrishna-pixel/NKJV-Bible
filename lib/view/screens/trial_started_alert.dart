import 'package:biblebookapp/services/trial_reminder_ux.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Day 0 in-app confirmation after a trial subscription starts (HTML UX).
/// Does not change purchase / restore logic.
class TrialStartedAlert {
  static const Color _cream = Color(0xFFF4E9D2);
  static const Color _paper = Color(0xFFFBF4E2);
  static const Color _ink = Color(0xFF241A0F);
  static const Color _ink2 = Color(0xFF4F4026);
  static const Color _gold = Color(0xFF96712E);
  static const Color _line = Color(0xFFE4D4B0);
  static const Color _green = Color(0xFF5F7D4F);
  static const Color _ctaTop = Color(0xFFC07A3C);
  static const Color _ctaBot = Color(0xFF9A5323);

  static const Duration _kClearUpgradeDeferDelay = Duration(milliseconds: 300);

  static Future<void> show(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final prefs = await SharedPreferences.getInstance();
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    await prefs.setString('premiumalrt', '2');

    final freeUntil = await TrialReminderUx.markTrialStartedAndScheduleReminder();
    final freeUntilLabel = TrialReminderUx.formatFreeUntil(freeUntil);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        void close() {
          try {
            EasyLoading.dismiss();
          } catch (_) {}
          Navigator.of(dialogContext).pop();
          Future.delayed(const Duration(milliseconds: 50), () {
            try {
              EasyLoading.dismiss();
            } catch (_) {}
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.18 : 22,
            vertical: isTablet ? size.height * 0.1 : 36,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: _cream,
              padding: EdgeInsets.fromLTRB(
                isTablet ? 28 : 22,
                isTablet ? 32 : 26,
                isTablet ? 28 : 22,
                isTablet ? 26 : 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isTablet ? 72 : 66,
                      height: isTablet ? 72 : 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFB08B3F), Color(0xFF96712E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.45),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    SizedBox(height: isTablet ? 18 : 16),
                    Text(
                      "You're in. Your free\ntrial has started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 24 : 22,
                        height: 1.15,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Full access to AI study, prayer & ad-free reading — free for 3 days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: _ink2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'FREE UNTIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            freeUntilLabel,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 19 : 17,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 16, color: _green),
                        const SizedBox(width: 7),
                        Text(
                          "We'll remind you before it ends.",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 22 : 20),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_ctaTop, _ctaBot],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _ctaBot.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: close,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 16 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Start Reading',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: isTablet ? 17 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFF6EA),
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
      },
    );

    await Future.delayed(_kClearUpgradeDeferDelay);
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false);
  }
}
