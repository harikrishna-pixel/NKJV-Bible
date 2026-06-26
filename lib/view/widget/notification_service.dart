import 'dart:developer';
import 'dart:io';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsServices {
  /// Single plugin instance — scheduling must use the same instance that was initialized.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Plugin init only — no permission dialog. Safe to call at splash / app open.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Do not request iOS notification permission here — onboarding screen 4 handles that.
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  /// Full init + system permission prompt. Used by onboarding screen 4 only.
  Future<void> initialiseNotifications() async {
    await ensureInitialized();

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Call at app startup (e.g. from splash) to store notification payload when app was launched from a notification tap.
  static Future<void> storeLaunchPayloadIfFromNotification() async {
    await ensureInitialized();
    final NotificationAppLaunchDetails? details =
        await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final String? payload = details?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        await SharPreferences.setString(
            SharPreferences.pendingNotificationAction, payload);
      }
    }
  }

  Future<bool> isNotificationPermissionGranted() async {
    await ensureInitialized();
    return await Permission.notification.isGranted;
  }

  Future<void> _ensureExactAlarmIfNeeded() async {
    if (!Platform.isAndroid) return;
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      final sdkInt = int.tryParse(result.stdout.toString().trim()) ?? 0;
      if (sdkInt >= 31 && await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('scheduleExactAlarm check failed: $e');
    }
  }

  /// Explicit permission request — for Settings / onboarding, not background schedule.
  Future<bool> requestNotificationPermissions() async {
    await ensureInitialized();

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _plugin.getNotificationAppLaunchDetails();

    await _ensureExactAlarmIfNeeded();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        await SharPreferences.setString(
            SharPreferences.pendingNotificationAction, payload);
      }
      return true;
    }

    if (await Permission.notification.isGranted) {
      return true;
    }

    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  static void _onNotificationTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      SharPreferences.setString(
          SharPreferences.pendingNotificationAction, payload);
      Get.offAll(() => HomeScreen(
            From: 'splash',
            selectedVerseNumForRead: '',
            selectedBookForRead: '',
            selectedChapterForRead: '',
            selectedBookNameForRead: '',
            selectedVerseForRead: '',
          ));
    }
  }

  /// Next daily fire time in UTC (avoids wrong tz.local defaulting to UTC wall-clock).
  tz.TZDateTime _nextDailySchedule(int hh, int mm) {
    tz.initializeTimeZones();
    final now = DateTime.now();
    var local = DateTime(now.year, now.month, now.day, hh, mm);
    if (local.isBefore(now)) {
      local = local.add(const Duration(days: 1));
    }
    final utc = local.toUtc();
    return tz.TZDateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  /// Schedules a daily notification at hh:mm with optional payload for tap handling.
  Future<void> showNotification(
      int id, String title, String body, int hh, int mm,
      {String? payload}) async {
    await ensureInitialized();
    if (!await isNotificationPermissionGranted()) {
      log('Notification permission not granted — skipped id $id');
      return;
    }
    await _ensureExactAlarmIfNeeded();

    final setTime = _nextDailySchedule(hh, mm);
    log('Set Notification: $id, $title, $body, $hh:$mm → $setTime, payload: $payload');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      setTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_verse_channel_church',
          'Daily Verse Notifications',
          channelDescription: 'Notifications for daily Bible verses',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('church_bell'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'church_bell.mp3',
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Scenario notifications — separate channel/IDs from streak (1/2/3) and smart (0).
  Future<void> showScenarioNotification(
      int id, String title, String body, int hh, int mm,
      {String? payload}) async {
    await ensureInitialized();
    if (!await isNotificationPermissionGranted()) {
      log('Notification permission not granted — skipped scenario id $id');
      return;
    }
    await _ensureExactAlarmIfNeeded();

    final setTime = _nextDailySchedule(hh, mm);
    log('Set Scenario Notification: $id, $title, $body, $hh:$mm → $setTime');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      setTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'scenario_notification_channel_church',
          'Scenario Notifications',
          channelDescription:
              'Personalized Bible reminders based on your journey',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('church_bell'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'church_bell.mp3',
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  void stopNotification(int id) async {
    await _plugin.cancel(id);
  }
}
