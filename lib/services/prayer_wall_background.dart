import 'package:biblebookapp/services/prayer_wall_activity_notifier.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

/// Workmanager task names — must match Info.plist / AppDelegate identifiers.
const String kPrayerWallPeriodicTask = 'com.biblebookapp.prayerWallActivity';
const String kPrayerWallOneOffTask = 'com.biblebookapp.prayerWallActivityOneOff';

/// Top-level entry for background GET poll → local notification.
@pragma('vm:entry-point')
void prayerWallBackgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationsServices.ensureInitialized();
      await PrayerWallActivityNotifier.checkAndNotify(fromBackground: true);
      return true;
    } catch (e) {
      debugPrint('prayerWall background task error: $e');
      return false;
    }
  });
}

/// Registers periodic + optional one-off background polls (additive only).
class PrayerWallBackgroundScheduler {
  PrayerWallBackgroundScheduler._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await Workmanager().initialize(
        prayerWallBackgroundCallbackDispatcher,
        isInDebugMode: false,
      );
      await Workmanager().registerPeriodicTask(
        kPrayerWallPeriodicTask,
        kPrayerWallPeriodicTask,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 10),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('PrayerWallBackgroundScheduler.init failed: $e');
    }
  }

  /// Call when app goes to background so a check can run soon after close.
  static Future<void> scheduleSoonAfterClose() async {
    try {
      await ensureInitialized();
      await Workmanager().registerOneOffTask(
        kPrayerWallOneOffTask,
        kPrayerWallOneOffTask,
        initialDelay: const Duration(minutes: 2),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('PrayerWallBackgroundScheduler.oneOff failed: $e');
    }
  }
}
