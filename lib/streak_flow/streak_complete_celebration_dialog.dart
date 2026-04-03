import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Celebration dialog when user completes the full 4-step streak (Day X Complete).
/// Shows app logo, "Day X Complete", streak started strip, and Enable Daily Reminder.
class StreakCompleteCelebrationDialog extends StatefulWidget {
  const StreakCompleteCelebrationDialog({
    super.key,
    required this.streakCount,
  });

  final int streakCount;

  @override
  State<StreakCompleteCelebrationDialog> createState() =>
      _StreakCompleteCelebrationDialogState();
}

class _StreakCompleteCelebrationDialogState
    extends State<StreakCompleteCelebrationDialog> with WidgetsBindingObserver {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF8F4EB);
  static const Color _stripBg = Color(0xFFF0E6D0);

  bool _isNotificationEnabled = false;
  bool _isLoading = true;

  bool _coercePrefsBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    if (raw is int) return raw != 0;
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationStatus();
    // Second read after frame: prefs may update right as dialog opens (e.g. after Settings).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _checkNotificationStatus();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationStatus();
    }
  }

  Future<void> _checkNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final n1 = _coercePrefsBool(prefs.get(SharPreferences.isNotificationOn));
    final n2 = _coercePrefsBool(prefs.get(SharPreferences.isNotificationOn1));
    final n3 = _coercePrefsBool(prefs.get(SharPreferences.isNotificationOn2));

    if (!mounted) return;
    setState(() {
      _isNotificationEnabled = n1 || n2 || n3;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _brown.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildTopDecorationRow(),
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/Icon-1024.png',
                    height: 72,
                    width: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day ${widget.streakCount} Complete',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _brown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.celebration, size: 24, color: _gold),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You spent time in God's Word today.\nCome back tomorrow to continue your journey.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _brown.withOpacity(0.9),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _stripBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: _gold, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Streak Started',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _brown,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isLoading && !_isNotificationEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Want a daily notifications ?',
                            style: TextStyle(
                              fontSize: 14,
                              color: _brown.withOpacity(0.8),
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Get.to(() =>
                                      SettingScreen(notificationValue: false));
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _gold, width: 1.5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_none,
                                          size: 20, color: _gold),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Enable Daily Reminder',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _gold,
                                          fontFamily: 'Georgia',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: _brown.withOpacity(0.6),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top decoration: row of golden stars with subtle size/opacity variation.
  Widget _buildTopDecorationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (i) {
        final size = 12.0 + (i % 3) * 2.0;
        final opacity = 0.7 + (i % 4) * 0.08;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: _gold.withOpacity(opacity.clamp(0.0, 1.0)),
          ),
        );
      }),
    );
  }
}
