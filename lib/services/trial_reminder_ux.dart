import 'package:biblebookapp/services/premium_entitlement_label_sync.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trial reminder UX only (Day 0 screen / Day 2 push / drawer row).
/// Does not change purchase, restore, or IAP validation.
class TrialReminderUx {
  TrialReminderUx._();

  static const _freeUntilKey = 'trial_ux_free_until';
  static const _trialDays = 3;

  static const _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _monthShort = [
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

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Last free calendar day (Day 2 of a 3-day trial). Same math as yearly trial paywall.
  static DateTime freeUntilFromStart([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final planBegins = today.add(const Duration(days: _trialDays));
    return planBegins.subtract(const Duration(days: 1));
  }

  static String formatFreeUntil(DateTime date) {
    final week = _weekdayShort[date.weekday - 1];
    return '$week, ${date.day} ${_monthShort[date.month - 1]}';
  }

  static String formatWeekdayShort(DateTime date) =>
      _weekdayShort[date.weekday - 1];

  /// Subscriptions that use the 3-day trial confirmation UX.
  /// Lifetime and Exit Offer yearly have no free trial → Premium Unlocked instead.
  static Future<bool> shouldShowTrialStartedFlow() async {
    final id =
        (await PremiumEntitlementLabelSync.readLastProductId() ?? '')
            .toLowerCase()
            .trim();
    if (id.contains('lifetime')) return false;
    // Exit (`oneyearautoexit`) contains "oneyear" but is not a free-trial SKU.
    if (BibleInfo.isExitOfferYearlyProductId(id)) return false;
    if (id.isEmpty) return true;
    if (id.contains('oneyear') ||
        id.contains('1year') ||
        BibleInfo.isArOneYearProductId(id) ||
        id.contains('sixmonth') ||
        id.contains('6month') ||
        id.contains('onemonth') ||
        BibleInfo.isOneMonthProductId(id) ||
        BibleInfo.isArSixMonthProductId(id)) {
      return true;
    }
    return !id.contains('lifetime');
  }

  static Future<DateTime?> readFreeUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_freeUntilKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Persist free-until + schedule the one Day-2 local push (HTML copy).
  static Future<DateTime> markTrialStartedAndScheduleReminder({
    bool schedulePush = true,
  }) async {
    final freeUntil = freeUntilFromStart();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_freeUntilKey, freeUntil.toIso8601String());
    if (schedulePush) {
      await scheduleDay2Push(freeUntil: freeUntil);
    }
    return freeUntil;
  }

  /// One push ~24h before renewal — continuity copy from trial_end_reminder.html.
  static Future<void> scheduleDay2Push({DateTime? freeUntil}) async {
    final last = freeUntil ?? await readFreeUntil() ?? freeUntilFromStart();
    // Match existing timing: morning of the day before last free day.
    final remindDay = last.subtract(const Duration(days: 1));
    final when = DateTime(remindDay.year, remindDay.month, remindDay.day, 9);
    final renewLabel = formatWeekdayShort(last.add(const Duration(days: 1)));
    await NotificationsServices().scheduleTrialEndReminder(
      when: when,
      title: 'Your premium continues tomorrow',
      body:
          'Day 3 of 3 — your plan renews $renewLabel. Nothing to do to keep your AI study & ad-free reading. Manage anytime in Settings.',
    );
  }

  static Future<TrialDrawerState> drawerState() async {
    final freeUntil = await readFreeUntil();
    if (freeUntil == null) return TrialDrawerState.none;
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(freeUntil);
    final renewDay = last.add(const Duration(days: 1));
    if (today.isAfter(last)) {
      return TrialDrawerState.none;
    }
    final renewLabel = formatWeekdayShort(renewDay);
    if (today == last) {
      return TrialDrawerState(
        showTrialBadge: true,
        showEndingCard: true,
        title: 'Trial ends today',
        body:
            'Premium continues $renewLabel — AI study & ad-free reading. Tap to manage.',
      );
    }
    final dayBefore = last.subtract(const Duration(days: 1));
    if (today == dayBefore) {
      return TrialDrawerState(
        showTrialBadge: true,
        showEndingCard: true,
        title: 'Trial ends tomorrow',
        body:
            'Premium continues $renewLabel — AI study & ad-free reading. Tap to manage.',
      );
    }
    return TrialDrawerState(
      showTrialBadge: true,
      showEndingCard: false,
      title: '',
      body: '',
    );
  }
}

class TrialDrawerState {
  const TrialDrawerState({
    required this.showTrialBadge,
    required this.showEndingCard,
    required this.title,
    required this.body,
  });

  static const none = TrialDrawerState(
    showTrialBadge: false,
    showEndingCard: false,
    title: '',
    body: '',
  );

  final bool showTrialBadge;
  final bool showEndingCard;
  final String title;
  final String body;
}
