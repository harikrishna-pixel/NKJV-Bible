import 'dart:async';

import 'package:biblebookapp/main.dart' show routeObserver;
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "You have unlimited AI access" card for Chat and Prayer Guidance.
/// Shown once ever after purchase; auto-hides after 10s, on close,
/// or when another screen is pushed on top.
class UnlimitedAccessBanner extends StatefulWidget {
  const UnlimitedAccessBanner({
    super.key,
    required this.screenWidth,
    required this.isDark,
    required this.onDismissed,
  });

  final double screenWidth;
  final bool isDark;
  final VoidCallback onDismissed;

  /// Same key Chat used, so users who closed it before never see it again.
  static const _shownKey = 'chat_unlimited_access_card_dismissed';
  static bool _shownThisSession = false;

  static Future<bool> shouldShow() async {
    if (_shownThisSession) return false;
    try {
      if (!await BibleInfo.shouldSkipChatPrayerCredits()) return false;
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_shownKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markShown() async {
    _shownThisSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_shownKey, true);
    } catch (_) {}
  }

  @override
  State<UnlimitedAccessBanner> createState() => _UnlimitedAccessBannerState();
}

class _UnlimitedAccessBannerState extends State<UnlimitedAccessBanner>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _hide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Timer? _autoTimer;
  bool _hiding = false;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    UnlimitedAccessBanner._markShown();
    _autoTimer = Timer(const Duration(seconds: 10), _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void didPushNext() => _dismiss();

  Future<void> _dismiss() async {
    if (_hiding || !mounted) return;
    _hiding = true;
    _autoTimer?.cancel();
    await _hide.forward();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    if (_subscribed) routeObserver.unsubscribe(this);
    _hide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = widget.screenWidth;
    final isDark = widget.isDark;
    final ink = isDark ? const Color(0xFFF5F0E6) : const Color(0xFF3D2914);
    final muted = isDark ? const Color(0xFFD4C4B0) : const Color(0xFF7A6455);
    final cardBg = isDark ? const Color(0xFF3A2923) : const Color(0xFFFFFAF4);
    final border = isDark ? const Color(0xFF6B5348) : const Color(0xFFE9D7B8);
    final curve = CurvedAnimation(parent: _hide, curve: Curves.easeIn);

    return SizeTransition(
      sizeFactor: ReverseAnimation(curve),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: ReverseAnimation(curve),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.4),
          ).animate(curve),
          child: Material(
            color: cardBg,
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              padding: EdgeInsets.fromLTRB(
                screenWidth > 450 ? 14 : 12,
                screenWidth > 450 ? 12 : 10,
                4,
                screenWidth > 450 ? 12 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Image.asset(
                      'assets/gold-premium-icons/theme_premium_crown.png',
                      width: screenWidth > 450 ? 36 : 32,
                      height: screenWidth > 450 ? 36 : 32,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.workspace_premium,
                        size: screenWidth > 450 ? 32 : 28,
                        color: const Color(0xFFCFA03A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have unlimited AI access',
                          style: TextStyle(
                            color: ink,
                            fontSize: screenWidth > 450 ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Credits won\'t be used.',
                          style: TextStyle(
                            color: muted,
                            fontSize: screenWidth > 450 ? 13 : 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.close, size: 18, color: muted),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
