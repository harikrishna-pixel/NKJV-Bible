import 'dart:async';

import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yearly 3-day trial paywall. No close. Purchase and restore use the
/// existing invisible [SubscriptionScreen] host.
class YearlyTrialPaywall extends StatefulWidget {
  const YearlyTrialPaywall({
    super.key,
    required this.sixMonthPlan,
    required this.oneYearPlan,
    required this.lifeTimePlan,
    required this.checkad,
  });

  final String sixMonthPlan;
  final String oneYearPlan;
  final String lifeTimePlan;
  final String checkad;

  @override
  State<YearlyTrialPaywall> createState() => _YearlyTrialPaywallState();
}

class _YearlyTrialPaywallState extends State<YearlyTrialPaywall> {
  static const Color _bg = Color(0xFFF8F1E4);
  static const Color _ink = Color(0xFF1C1A17);
  static const Color _muted = Color(0xFF8D8680);
  static const Color _gold = Color(0xFFC6A04A);
  static const Color _goldDeep = Color(0xFFB8923A);
  static const Color _card = Color(0xFFFFFCF7);
  static const Color _line = Color(0xFFE6D7BC);

  static const List<String> _weekdayShort = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  static const List<String> _weekdayTitle = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _remindMe = true;
  bool _busy = false;
  ProductDetails? _oneYear;

  String get _resolvedSixMonth => BibleInfo.isAutoRenewablePaywallMode
      ? BibleInfo.arOneMonthPlanid
      : AppApiConstant.resolveSubscriptionProductId(
          widget.sixMonthPlan,
          BibleInfo.sixMonthPlanid,
        );

  String get _resolvedOneYear => BibleInfo.isAutoRenewablePaywallMode
      ? BibleInfo.arOneYearPlanid
      : AppApiConstant.resolveSubscriptionProductId(
          widget.oneYearPlan,
          BibleInfo.oneYearPlanid,
        );

  String get _resolvedLifetime => AppApiConstant.resolveSubscriptionProductId(
        widget.lifeTimePlan,
        BibleInfo.lifeTimePlanid,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_onPaywallOpen());
    });
    unawaited(_loadYearProduct());
  }

  Future<void> _onPaywallOpen() async {
    if (!mounted) return;
    if (!await SubscriptionScreen.isDashboardIapEnabled()) {
      await _leavePaywall();
      return;
    }
    await SubscriptionScreen.trackAndMarkVisiblePaywallOpen();
    if (!mounted) return;
    try {
      Provider.of<DownloadProvider>(context, listen: false).disableAd();
    } catch (_) {}
    await SharPreferences.setBoolean('closead', false);
    await SharPreferences.setString('OpenAd', '1');
  }

  Future<void> _loadYearProduct() async {
    var products = PaywallPreloadService.getPreloadedProducts();
    if (products.isEmpty) {
      await PaywallPreloadService.preloadPaywallData();
      products = PaywallPreloadService.getPreloadedProducts();
    }
    ProductDetails? year;
    void take(Iterable<ProductDetails> list) {
      for (final p in list) {
        if (year == null &&
            (p.id == _resolvedOneYear ||
                BibleInfo.isArOneYearProductId(p.id))) {
          year = p;
        }
      }
    }

    take(products);
    if (year == null) {
      try {
        if (await InAppPurchase.instance.isAvailable()) {
          final response = await InAppPurchase.instance.queryProductDetails(
            AppApiConstant.subscriptionProductIdQueryVariants(_resolvedOneYear),
          );
          take(response.productDetails);
        }
      } catch (e) {
        debugPrint('YearlyTrialPaywall: store requery failed: $e');
      }
    }
    if (!mounted) return;
    setState(() => _oneYear = year);
  }

  String get _yearPrice =>
      (_oneYear != null && _oneYear!.price.isNotEmpty) ? _oneYear!.price : '\$39.99';

  String get _weekPrice {
    final product = _oneYear;
    if (product == null || product.rawPrice <= 0) return '\$0.77';
    final weekly = product.rawPrice / 52;
    final symbol = product.price.replaceAll(RegExp(r'[\d.,\s]+'), '').trim();
    final mark = symbol.isEmpty ? '\$' : symbol;
    return '$mark${weekly.toStringAsFixed(2)}';
  }

  DateTime get _today => DateTime.now();

  DateTime get _planBegins =>
      DateTime(_today.year, _today.month, _today.day).add(const Duration(days: 3));

  DateTime get _lastTrialDay =>
      _planBegins.subtract(const Duration(days: 1));

  String _planBeginsLabel(DateTime date) {
    final week = _weekdayShort[date.weekday - 1];
    final month = _monthShort[date.month - 1].toUpperCase();
    return '$week, $month ${date.day}';
  }

  String _cancelByLabel(DateTime date) {
    final week = _weekdayTitle[date.weekday - 1];
    final month = _monthShort[date.month - 1];
    return '$week, $month ${date.day}';
  }

  Future<void> _onRemindChanged(bool value) async {
    setState(() => _remindMe = value);
    if (!value) {
      await NotificationsServices().cancelTrialEndReminder();
      return;
    }
    await NotificationsServices().requestNotificationPermissions();
  }

  Future<void> _scheduleReminderIfNeeded() async {
    if (!_remindMe) {
      await NotificationsServices().cancelTrialEndReminder();
      return;
    }
    final day = _lastTrialDay;
    await NotificationsServices().scheduleTrialEndReminder(
      when: DateTime(day.year, day.month, day.day, 9),
      title: 'Your free trial ends today',
      body: 'Cancel today and pay nothing. Your yearly plan begins tomorrow.',
    );
  }

  Future<void> _startTrial() async {
    if (_busy) return;
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: _resolvedSixMonth,
          oneYearPlan: _resolvedOneYear,
          lifeTimePlan: _resolvedLifetime,
          checkad: widget.checkad,
          initialSelectedPlanIndex: 1,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await _scheduleReminderIfNeeded();
      await _onPurchaseFinished();
      return;
    }
    try {
      final raw = await SharPreferences.getString(
        SharPreferences.isRewardAdViewTime,
      );
      if (raw != null &&
          raw.isNotEmpty &&
          DateTime.parse(raw).isAfter(DateTime.now()) &&
          mounted) {
        await _scheduleReminderIfNeeded();
        await _onPurchaseFinished();
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restore() async {
    if (_busy) return;
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    EasyLoading.show(status: 'Restoring...');
    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: _resolvedSixMonth,
          oneYearPlan: _resolvedOneYear,
          lifeTimePlan: _resolvedLifetime,
          checkad: widget.checkad,
          invisiblePurchaseHost: true,
          autoStartRestore: true,
        ),
      ),
    );
    if (ok == true && mounted) {
      await _leaveAfterRestore();
      return;
    }
    try {
      EasyLoading.dismiss();
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onPurchaseFinished() async {
    if (!mounted) return;
    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
    }
    if (!mounted) return;
    try {
      await EasyLoading.dismiss();
    } catch (_) {}
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('premiumalrt', '1');
    } catch (_) {}
    if (!mounted) return;
    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      await provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    if (!mounted) return;
    Get.offAll(
      () => HomeScreen(
        From: 'premium',
        selectedVerseNumForRead: '',
        selectedBookForRead: '',
        selectedChapterForRead: '',
        selectedBookNameForRead: '',
        selectedVerseForRead: '',
      ),
    );
  }

  Future<void> _leaveAfterRestore() async {
    if (!mounted) return;
    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
    }
    await _leavePaywall();
  }

  Future<void> _leavePaywall() async {
    if (!mounted) return;
    try {
      EasyLoading.dismiss();
    } catch (_) {}
    try {
      Provider.of<DownloadProvider>(context, listen: false).enableAd();
    } catch (_) {}
    await SharPreferences.setBoolean('closead', true);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }

  Future<void> _openLegal(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;
    final hPad = isTablet ? width * 0.18 : 28.0;
    final planDay = _planBegins;
    final cancelDay = _lastTrialDay;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 18),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '3-DAY FREE TRIAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: isTablet ? 34 : 28,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.15,
                      ),
                      children: const [
                        TextSpan(text: 'You won\u2019t be charged '),
                        TextSpan(
                          text: 'today',
                          style: TextStyle(
                            color: _goldDeep,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your daily time with God is ready.\nHere\u2019s exactly what happens next.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 15,
                    height: 1.45,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                _step(
                  filled: true,
                  icon: Icons.lock_outline_rounded,
                  iconColor: Colors.white,
                  last: false,
                  child: _copy(
                    label: 'TODAY',
                    title: 'Everything unlocks \u2014 free',
                    lines: const [
                      'Clear answers on any verse, anytime',
                      'A prayer for what\u2019s on your heart',
                      'Daily devotion, with no ads',
                    ],
                  ),
                ),
                _step(
                  filled: false,
                  icon: Icons.notifications_none_rounded,
                  iconColor: _gold,
                  last: false,
                  child: _copy(
                    label: 'BEFORE YOUR TRIAL ENDS',
                    title: 'We\u2019ll remind you',
                    body: 'One heads-up, with time to spare.',
                  ),
                ),
                _step(
                  filled: false,
                  icon: Icons.star_border_rounded,
                  iconColor: _gold,
                  last: true,
                  child: _copy(
                    label: _planBeginsLabel(planDay),
                    title: 'Only then does your plan begin',
                    body:
                        'Cancel by ${_cancelByLabel(cancelDay)} and pay nothing.',
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _line),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 18,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Remind me before it ends',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _remindMe,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF34C759),
                        onChanged: _busy ? null : _onRemindChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold, width: 1.4),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YEARLY PLAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: _goldDeep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'That\u2019s about $_weekPrice/week',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _yearPrice,
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                  ),
                                ),
                                const TextSpan(
                                  text: '/year',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '3 DAYS FREE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55C6A04A),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _busy ? null : _startTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        disabledBackgroundColor: _gold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start 3-Day Free Trial  \u2192',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Auto-renews yearly \u00b7 Cancel anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: Color(0xFF8A8178),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _link(
                        'Terms of Use',
                        () => _openLegal(BibleInfo.termsandConditionURL),
                      ),
                      const _FooterDot(),
                      _link(
                        'Privacy Policy',
                        () => _openLegal(BibleInfo.privacyPolicyURL),
                      ),
                      const _FooterDot(),
                      _link('Restore Purchases', _restore),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step({
    required bool filled,
    required IconData icon,
    required Color iconColor,
    required bool last,
    required Widget child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? _gold : _card,
                    border: Border.all(color: _gold, width: 1.4),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                if (!last)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: _gold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20, top: 2),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _copy({
    required String label,
    required String title,
    String? body,
    List<String> lines = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: _goldDeep,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
                            fontWeight: FontWeight.w800,
            color: _ink,
            height: 1.25,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
        for (final line in lines) ...[
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_rounded, size: 14, color: _gold),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E5852),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _link(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A8178),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF8A8178),
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '\u00b7',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A8178),
        ),
      ),
    );
  }
}
