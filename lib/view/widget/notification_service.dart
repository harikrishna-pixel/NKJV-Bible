import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // final AndroidInitializationSettings _androidInitializationSettings = const AndroidInitializationSettings("logo");

  Future<void> initialiseNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    InitializationSettings initializationSettings =
        const InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: DarwinInitializationSettings());

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions on iOS and Android 13+
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<bool> requestNotificationPermissions() async {
    // Request permission for iOS (automatically done for Android by flutter_local_notifications)
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (Platform.isAndroid) {
      int sdkInt = int.parse(
          (await Process.run('getprop', ['ro.build.version.sdk']))
              .stdout
              .trim());
      debugPrint("Settime sdk - $sdkInt");
      if (sdkInt >= 31) {
        // Only request for Android 12+ (API 31+)
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
          debugPrint("Settime sdk - request acess");
        }
      }
    }

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      return true;
    }

    if (await Permission.notification.isGranted) {
      return true;
    }

    final PermissionStatus status = await Permission.notification.request();

    return status.isGranted;
  }

  Future<void> showNotification(
      int id, String title, String body, int hh, int mm) async {
    log('Set Notification: $id, $title,$body, $hh,$mm');
    var dateTime = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hh, mm, 0);
    tz.initializeTimeZones();
    final setTime = tz.TZDateTime.from(dateTime, tz.local);
    log('Set Time: $setTime');
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      setTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_verse_channel',
          'Daily Verse Notifications',
          channelDescription: 'Notifications for daily Bible verses',
          importance: Importance.max,
          priority: Priority.max,
          icon: "@mipmap/ic_launcher",
          sound: const RawResourceAndroidNotificationSound('bell'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'bell.mp3',
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void stopNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
