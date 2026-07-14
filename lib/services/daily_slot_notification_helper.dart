import 'package:biblebookapp/services/scenario_notification_helper.dart';
import 'package:biblebookapp/services/smart_notification_helper.dart';
import 'package:biblebookapp/services/streak_notification_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';

/// Schedules at most ONE notification per Morning/Afternoon/Evening slot.
///
/// Priority:
/// 1. Streak not completed today → streak reminder
/// 2. Streak completed + chat not opened today → chat
/// 3. Otherwise → verse (no devotion/prayer after streak is done)
class DailySlotNotificationHelper {
  static Future<void>? _inFlight;

  /// Idempotent entry — safe if streak + scenario callers run in parallel.
  static Future<void> rescheduleEnabledSlots() {
    if (_inFlight != null) return _inFlight!;
    _inFlight = _rescheduleEnabledSlots().whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  static Future<void> _rescheduleEnabledSlots() async {
    final onMorning =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn);
    final onAfternoon =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);
    final onEvening =
        await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
    final hasAny =
        (onMorning ?? false) || (onAfternoon ?? false) || (onEvening ?? false);

    await NotificationsServices.ensureInitialized();
    await SmartNotificationHelper.cancelSmartNotification();

    final svc = NotificationsServices();
    svc.stopNotification(1);
    svc.stopNotification(2);
    svc.stopNotification(3);
    svc.stopNotification(scenarioMorningNotificationId);
    svc.stopNotification(scenarioAfternoonNotificationId);
    svc.stopNotification(scenarioEveningNotificationId);

    if (!hasAny) return;

    final streakState = await StreakNotificationHelper.getStreakState();
    final streakDone =
        streakState == StreakNotificationState.streak_completed;
    final chatOpened = await ScenarioNotificationHelper.openedChatToday();
    final scenarioExplicitlyOff = await SharPreferences.getBoolean(
          SharPreferences.isScenarioNotificationOn,
        ) ==
        false;

    if (onMorning == true) {
      await _scheduleSlot(
        svc: svc,
        streakSlot: 'morning',
        streakId: 1,
        scenarioId: scenarioMorningNotificationId,
        streakDone: streakDone,
        chatOpened: chatOpened,
        scenarioExplicitlyOff: scenarioExplicitlyOff,
      );
    }
    if (onAfternoon == true) {
      await _scheduleSlot(
        svc: svc,
        streakSlot: 'afternoon',
        streakId: 2,
        scenarioId: scenarioAfternoonNotificationId,
        streakDone: streakDone,
        chatOpened: chatOpened,
        scenarioExplicitlyOff: scenarioExplicitlyOff,
      );
    }
    if (onEvening == true) {
      await _scheduleSlot(
        svc: svc,
        streakSlot: 'night',
        streakId: 3,
        scenarioId: scenarioEveningNotificationId,
        streakDone: streakDone,
        chatOpened: chatOpened,
        scenarioExplicitlyOff: scenarioExplicitlyOff,
      );
    }
  }

  static Future<void> _scheduleSlot({
    required NotificationsServices svc,
    required String streakSlot,
    required int streakId,
    required int scenarioId,
    required bool streakDone,
    required bool chatOpened,
    required bool scenarioExplicitlyOff,
  }) async {
    final time = await StreakNotificationHelper.timeForSlot(streakSlot);

    if (!streakDone) {
      final content =
          await StreakNotificationHelper.getContentForSlot(streakSlot);
      await svc.showNotification(
        streakId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
      return;
    }

    // Streak completed: one non-streak nudge (chat if unused, else verse).
    final templateCategory = chatOpened ? 'VERSE_OF_THE_DAY' : 'AI_CHAT';
    final content = await ScenarioNotificationHelper
        .getTemplateContentForCategory(templateCategory);

    if (scenarioExplicitlyOff) {
      await svc.showNotification(
        streakId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
    } else {
      await svc.showScenarioNotification(
        scenarioId,
        content.title,
        content.message,
        time.hh,
        time.mm,
        payload: content.action,
      );
    }
  }
}
