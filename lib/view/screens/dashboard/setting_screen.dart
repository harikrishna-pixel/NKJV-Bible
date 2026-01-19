import 'dart:io';
import 'dart:ui' as ui;
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/changeThemeButtun.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/about.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../constants/images.dart';
import '../../constants/share_preferences.dart';
import '../../widget/notification_service.dart';

import 'FontType.dart';

enum NotificationTime { morning, afternoon, evening }

class SettingScreen extends StatefulWidget {
  final bool notificationValue;
  const SettingScreen({super.key, required this.notificationValue});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    getNotificationDetails();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        await SharPreferences.setString('OpenAd', '1');
        break;
      case AppLifecycleState.inactive:
        await SharPreferences.setString('OpenAd', '1');
        break;
      case AppLifecycleState.resumed:
        await SharPreferences.setString('OpenAd', '1');
        bool? nt =
            await SharPreferences.getBoolean(SharPreferences.isNotificationOn);

        bool? nt1 =
            await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);

        bool? nt2 =
            await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
        // Check current status
        final status = await Permission.notification.status;
        debugPrint("✅ Notification permission is granted  ${status.isGranted}");
        if (status.isGranted) {
          debugPrint("✅ Notification permission is granted");
          setState(() {
            notificationButtonValue = nt ?? true;
            notificationButtonValue1 = nt1 ?? true;
            notificationButtonValue2 = nt2 ?? true;
          });
          // Proceed with your logic
        }
        // final status2 = await Permission.notification.status;
        // debugPrint(
        //     "✅ Notification permission is granted  ${status2.isGranted}");
        // if (status2.isGranted) {
        //   debugPrint("✅ Notification permission is granted");
        //   setState(() {
        //     notificationButtonValue = true;
        //     notificationButtonValue1 = true;
        //     notificationButtonValue2 = true;
        //   });
        // }
        break;

      default:
        break;
    }
  }

  Time selectedNotificationTime = Time(hour: 8, minute: 00, second: 00);
  Time selectedNotificationTime1 = Time(hour: 14, minute: 00, second: 00);
  Time selectedNotificationTime2 = Time(hour: 20, minute: 00, second: 00);
  bool notificationButtonValue = false;
  bool notificationButtonValue1 = false;
  bool notificationButtonValue2 = false;
  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  String? notificationalert;
  bool status3 = false;
  var notificationHours = "08";
  var notificationHours1 = "02";
  var notificationHours2 = "08";
  var notificationMinute = "00";
  var notificationMinute1 = "02";
  var notificationMinute2 = "00";

  String selectedTime = "8:00 AM";
  String selectedTime1 = "2:00 PM";
  String selectedTime2 = "8:00 PM";
  String morningTitle = 'Verse of The Day!';
  String morningBody = 'Tap to read!';
  String afternoonTitle = "Its noon now!";
  String afternoonBody = "Take a break with Bible reading";
  String eveningTitle = "Its time to pray!";
  String eveningBody = "Be faithful in small things";

  getNotificationDetails() async {
    // Future.delayed(
    //   Duration.zero,
    //   () async {
    //     // setState(() {
    //     SharPreferences.getString(SharPreferences.notificationTimeHour)
    //         .then((value) {
    //       debugPrint('settime notificationTimeHour - $value');
    //       setState(() {
    //         value != null
    //             ? notificationHours = value.toString()
    //             : notificationHours = "8";
    //       });
    //       debugPrint('settime notificationTimeHour n - $notificationHours');
    //     });
    //     SharPreferences.getString(SharPreferences.notificationTimeMinute)
    //         .then((value) {
    //       debugPrint('settime notificationTimeMinute - $value');
    //       setState(() {
    //         value != null
    //             ? notificationMinute = value.toString()
    //             : notificationMinute = "00";
    //         value == null
    //             ? selectedTime = "8:00 AM"
    //             : selectedTime = DateFormat.jm().format(DateFormat("hh:mm:ss")
    //                 .parse("$notificationHours:$notificationMinute:00"));
    //         value == null
    //             ? selectedNotificationTime =
    //                 Time(hour: 8, minute: 00, second: 00)
    //             : selectedNotificationTime = Time(
    //                 hour: int.parse(notificationHours),
    //                 minute: int.parse(notificationMinute.toString()),
    //                 second: 00);
    //       });
    //     });
    //     debugPrint(
    //         'settime notificationTimeHour nt - $notificationMinute  $selectedTime $selectedNotificationTime');

    //     SharPreferences.getString(SharPreferences.notificationTimeHour1)
    //         .then((value) {
    //       value != null
    //           ? notificationHours1 = value.toString()
    //           : notificationHours1 = "8";
    //     });
    //     SharPreferences.getString(SharPreferences.notificationTimeMinute1)
    //         .then((value) {
    //       value != null
    //           ? notificationMinute1 = value.toString()
    //           : notificationMinute1 = "00";
    //       value == null
    //           ? selectedTime1 = "8:00 AM"
    //           : selectedTime1 = DateFormat.jm().format(DateFormat("hh:mm:ss")
    //               .parse("$notificationHours1:$notificationMinute1:00"));
    //       value == null
    //           ? selectedNotificationTime1 =
    //               Time(hour: 8, minute: 00, second: 00)
    //           : selectedNotificationTime1 = Time(
    //               hour: int.parse(notificationHours1),
    //               minute: int.parse(notificationMinute1.toString()),
    //               second: 00);
    //     });

    //     SharPreferences.getString(SharPreferences.notificationTimeHour2)
    //         .then((value) {
    //       value != null
    //           ? notificationHours2 = value.toString()
    //           : notificationHours2 = "8";
    //     });
    //     SharPreferences.getString(SharPreferences.notificationTimeMinute2)
    //         .then((value) {
    //       value != null
    //           ? notificationMinute2 = value.toString()
    //           : notificationMinute2 = "00";
    //       value == null
    //           ? selectedTime2 = "8:00 AM"
    //           : selectedTime2 = DateFormat.jm().format(DateFormat("hh:mm:ss")
    //               .parse("$notificationHours2:$notificationMinute2:00"));
    //       value == null
    //           ? selectedNotificationTime2 =
    //               Time(hour: 8, minute: 00, second: 00)
    //           : selectedNotificationTime2 = Time(
    //               hour: int.parse(notificationHours2),
    //               minute: int.parse(notificationMinute2.toString()),
    //               second: 00);
    //     });
    //     // });
    //   },
    // );

    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getBool('notificationshowonetime') ?? false;

    if (data == false) {
      final prefs = await SharedPreferences.getInstance();

      prefs.setBool("notificationshowonetime", true);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return const NotifyMeDialog();
          },
        );
      }
    }

    try {
      // Fetch all values sequentially using await
      String? hour =
          await SharPreferences.getString(SharPreferences.notificationTimeHour);
      String? minute = await SharPreferences.getString(
          SharPreferences.notificationTimeMinute);

      String? hour1 = await SharPreferences.getString(
          SharPreferences.notificationTimeHour1);
      String? minute1 = await SharPreferences.getString(
          SharPreferences.notificationTimeMinute1);

      String? hour2 = await SharPreferences.getString(
          SharPreferences.notificationTimeHour2);
      String? minute2 = await SharPreferences.getString(
          SharPreferences.notificationTimeMinute2);

      bool? nt =
          await SharPreferences.getBoolean(SharPreferences.isNotificationOn);

      bool? nt1 =
          await SharPreferences.getBoolean(SharPreferences.isNotificationOn1);

      bool? nt2 =
          await SharPreferences.getBoolean(SharPreferences.isNotificationOn2);
      // Check current status
      final status = await Permission.notification.status;
      debugPrint("✅ Notification permission is granted  ${status.isGranted}");
      if (status.isGranted) {
        debugPrint("✅ Notification permission is granted");
        setState(() {
          notificationButtonValue = nt ?? true;
          notificationButtonValue1 = nt1 ?? true;
          notificationButtonValue2 = nt2 ?? true;
        });
        // Proceed with your logic
      } else {
        setState(() {
          notificationButtonValue = false;
          notificationButtonValue1 = false;
          notificationButtonValue2 = false;
        });
      }
      // Update state at once
      setState(() {
        notificationHours = hour ?? "8";
        notificationMinute = minute ?? "00";
        selectedTime = (minute == null)
            ? "8:00 AM"
            : DateFormat.jm().format(DateFormat("HH:mm:ss")
                .parse("$notificationHours:$notificationMinute:00"));
        selectedNotificationTime = Time(
          hour: int.parse(notificationHours),
          minute: int.parse(notificationMinute),
          second: 00,
        );

        notificationHours1 = hour1 ?? "2";
        notificationMinute1 = minute1 ?? "00";
        selectedTime1 = (minute1 == null)
            ? "2:00 PM"
            : DateFormat.jm().format(DateFormat("HH:mm:ss")
                .parse("$notificationHours1:$notificationMinute1:00"));
        selectedNotificationTime1 = Time(
          hour: int.parse(notificationHours1),
          minute: int.parse(notificationMinute1),
          second: 00,
        );

        notificationHours2 = hour2 ?? "8";
        notificationMinute2 = minute2 ?? "00";
        selectedTime2 = (minute2 == null)
            ? "8:00 PM"
            : DateFormat.jm().format(DateFormat("HH:mm:ss")
                .parse("$notificationHours2:$notificationMinute2:00"));
        selectedNotificationTime2 = Time(
          hour: int.parse(notificationHours2),
          minute: int.parse(notificationMinute2),
          second: 00,
        );
      });

      // Print values after they are updated
      debugPrint('Updated notificationTimeHour: $notificationHours');
      debugPrint('Updated notificationTimeMinute: $notificationMinute');
      debugPrint('Updated selectedTime: $selectedTime');
      debugPrint('Updated selectedNotificationTime: $selectedNotificationTime');
    } catch (e) {
      debugPrint('Error fetching notification details: $e');
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // notificationButtonValue = widget.notificationValue;
  //   // notificationButtonValue1 = widget.notificationValue;
  //   // notificationButtonValue2 = widget.notificationValue;

  // }

  checknotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final data = prefs.getString("notifiyalrt");

    if (data != '1') {
      await prefs.setString("notifiyalrt", notificationalert ?? '0');
    }
  }

  int getNotificationId(NotificationTime time) {
    if (time == NotificationTime.morning) {
      return 1;
    } else if (time == NotificationTime.afternoon) {
      return 2;
    } else {
      return 3;
    }
  }

  String getNotificationTitle(NotificationTime time) {
    if (time == NotificationTime.morning) {
      return morningTitle;
    } else if (time == NotificationTime.afternoon) {
      return afternoonTitle;
    } else {
      return eveningTitle;
    }
  }

  String getNotificationBody(NotificationTime time) {
    if (time == NotificationTime.morning) {
      return morningBody;
    } else if (time == NotificationTime.afternoon) {
      return afternoonBody;
    } else {
      return eveningBody;
    }
  }

  String getNotificationHours(NotificationTime time) {
    if (time == NotificationTime.morning) {
      return notificationHours;
    } else if (time == NotificationTime.afternoon) {
      return notificationHours1;
    } else {
      return notificationHours2;
    }
  }

  String getNotificationMin(NotificationTime time) {
    if (time == NotificationTime.morning) {
      return notificationMinute;
    } else if (time == NotificationTime.afternoon) {
      return notificationMinute1;
    } else {
      return notificationMinute2;
    }
  }

  updateOnTimeChange(NotificationTime notificationTime, DateTime time) {
    final hourtime = DateFormat("hh:mm a").format(time);
    final onlyhourtime = DateFormat("HH:mm").format(time);
    setState(() {
      if (notificationTime == NotificationTime.morning) {
        notificationHours = onlyhourtime.toString().split(":").first;
        notificationMinute = onlyhourtime.toString().split(":").last;
        selectedTime = hourtime;
        selectedNotificationTime = Time(
            hour: int.parse(notificationHours),
            minute: int.parse(notificationMinute.toString()),
            second: 00);
      } else if (notificationTime == NotificationTime.afternoon) {
        notificationHours1 = onlyhourtime.toString().split(":").first;
        notificationMinute1 = onlyhourtime.toString().split(":").last;
        selectedTime1 = hourtime;
        selectedNotificationTime1 = Time(
            hour: int.parse(notificationHours1),
            minute: int.parse(notificationMinute1.toString()),
            second: 00);
      } else {
        notificationHours2 = onlyhourtime.toString().split(":").first;
        notificationMinute2 = onlyhourtime.toString().split(":").last;
        selectedTime2 = hourtime;
        selectedNotificationTime2 = Time(
            hour: int.parse(notificationHours2),
            minute: int.parse(notificationMinute2.toString()),
            second: 00);
      }
    });
  }

  String getAmPm(NotificationTime time) {
    String selected;

    if (time == NotificationTime.morning) {
      selected = selectedTime;
    } else if (time == NotificationTime.afternoon) {
      selected = selectedTime1;
    } else {
      selected = selectedTime2;
    }

    return selected.trim().toUpperCase().contains("AM") ? "AM" : "PM";
  }

  Widget hourMinute12H(NotificationTime notificationTime) {
    // DateFormat("hh:mm a").format(time);
    DateTime initialT = DateFormat("yyyy-MM-dd hh:mm:ss a").parse(
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${getNotificationHours(notificationTime)}:${getNotificationMin(notificationTime)}:00 ${getAmPm(notificationTime)}");
    return TimePickerSpinner(
      is24HourMode: false,
      itemHeight: 30,
      itemWidth: 40,
      spacing: 10,
      time: initialT,
      isForce2Digits: true,
      highlightedTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: CommanColor.lightDarkPrimary(context),
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 20),
      normalTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.grey,
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 18),
      onTimeChange: (time) {
        updateOnTimeChange(notificationTime, time);
      },
    );
  }

  void setNotification(NotificationTime notificationTime) async {
    NotificationsServices().showNotification(
        getNotificationId(notificationTime),
        getNotificationTitle(notificationTime),
        getNotificationBody(notificationTime),
        int.parse(getNotificationHours(notificationTime)),
        int.parse(getNotificationMin(notificationTime)));
  }

  disableNotification(NotificationTime notificationTime) {
    NotificationsServices()
        .stopNotification(getNotificationId(notificationTime));
  }

  void showNotificationDialog(NotificationTime notificationTime) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return showDialog(
        context: context,
        builder: (context) {
          return Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 16,
              child: Container(
                margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        height: 60,
                        width: 60,
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: Center(
                          child: Image.asset(
                            Images.notificationBell(context),
                            fit: BoxFit.fill,
                            height: 35,
                            width: 35,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 10),
                        child: Text('Set Notification',
                            style: TextStyle(
                                color: Colors.black87,
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 18,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.only(bottom: 20.0, left: 25, right: 25),
                        child: Text(
                            '''Set your best time to get the verse of day every day''',
                            style: TextStyle(
                                color: Colors.black87,
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 14,
                                fontWeight: FontWeight.w400),
                            textAlign: TextAlign.center),
                      ),
                      hourMinute12H(notificationTime),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                getNotificationDetails();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CommanColor.lightGrey,
                                fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.35,
                                    35),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7)),
                              ),
                              child: Center(
                                child: Text(
                                  "Not Now",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: BibleInfo.letterSpacing,
                                      fontSize: BibleInfo.fontSizeScale * 16
                                      // MediaQuery.of(context).size.width *
                                      //     0.037
                                      ),
                                ),
                              )),
                          ElevatedButton(
                              onPressed: () async {
                                // if (notificationTime ==
                                //     NotificationTime.morning) {
                                //   SharPreferences.setString(
                                //       SharPreferences.notificationTimeHour,
                                //       notificationHours.toString());
                                //   SharPreferences.setString(
                                //           SharPreferences
                                //               .notificationTimeMinute,
                                //           notificationMinute.toString())
                                //       .then((value) {
                                //     debugPrint(
                                //         " settime -$notificationHours : $notificationMinute  ");

                                //     Constants.showToast(
                                //         "Notification time update successfully.");
                                //     if (notificationButtonValue) {
                                //       setNotification(notificationTime);
                                //     }
                                //     Navigator.pop(context);
                                //   });
                                // } else if (notificationTime ==
                                //     NotificationTime.afternoon) {
                                //   SharPreferences.setString(
                                //       SharPreferences.notificationTimeHour1,
                                //       notificationHours1.toString());
                                //   SharPreferences.setString(
                                //           SharPreferences
                                //               .notificationTimeMinute1,
                                //           notificationMinute1.toString())
                                //       .then((value) {
                                //     Constants.showToast(
                                //         "Notification time update successfully.");
                                //     if (notificationButtonValue1) {
                                //       setNotification(notificationTime);
                                //     }
                                //     Navigator.pop(context);
                                //   });
                                // } else {
                                //   SharPreferences.setString(
                                //       SharPreferences.notificationTimeHour2,
                                //       notificationHours2.toString());
                                //   SharPreferences.setString(
                                //           SharPreferences
                                //               .notificationTimeMinute2,
                                //           notificationMinute2.toString())
                                //       .then((value) {
                                //     Constants.showToast(
                                //         "Notification time update successfully.");
                                //     if (notificationButtonValue2) {
                                //       setNotification(notificationTime);
                                //     }
                                //     Navigator.pop(context);
                                //   });
                                // }
                                debugPrint(
                                    "updated notification time: $notificationMinute1");
                                try {
                                  if (notificationTime ==
                                      NotificationTime.morning) {
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeHour,
                                        notificationHours.toString() ?? "0");
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeMinute,
                                        notificationMinute.toString() ?? "0");

                                    debugPrint(
                                        "Set time - $notificationHours : $notificationMinute");

                                    Constants.showToast(
                                        "Notification time updated successfully.");

                                    if (notificationButtonValue) {
                                      setNotification(notificationTime);
                                    }
                                  } else if (notificationTime ==
                                      NotificationTime.afternoon) {
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeHour1,
                                        notificationHours1.toString() ?? "0");
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeMinute1,
                                        notificationMinute1.toString() ?? "0");

                                    Constants.showToast(
                                        "Notification time updated successfully.");

                                    if (notificationButtonValue1) {
                                      setNotification(notificationTime);
                                    }
                                  } else {
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeHour2,
                                        notificationHours2.toString() ?? "0");
                                    await SharPreferences.setString(
                                        SharPreferences.notificationTimeMinute2,
                                        notificationMinute2.toString() ?? "0");

                                    Constants.showToast(
                                        "Notification time updated successfully.");

                                    if (notificationButtonValue2) {
                                      setNotification(notificationTime);
                                    }
                                  }

                                  // Close the screen safely
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  debugPrint(
                                      "Error updating notification time: $e");
                                  Constants.showToast(
                                      "Failed to update notification time.");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    CommanColor.lightDarkPrimary(context),
                                fixedSize: Size(
                                    MediaQuery.of(context).size.width * 0.3,
                                    35),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7)),
                              ),
                              child: const Text(
                                "Update",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: BibleInfo.fontSizeScale * 16),
                              )),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ));
        },
      );
    }
  }

  _launchURL() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final locale = ui.window.locale;
    String deviceType = 'ios';
    String groupId = '1';
    String packageName = '';
    String appName = BibleInfo.bible_shortName;
    String deviceId = '';
    String deviceModel = '';
    String deviceName = '';
    String appVersion = packageInfo.version;
    String osVersion = '';
    String appType = '';
    String language = locale.languageCode;
    String countryCode = locale.countryCode.toString();
    String themeColor = 'd43f8d';
    String themeMode = '0';
    String width = '100px';
    String height = '100px';
    String isDevelopOrProd = '0';
    await SharPreferences.setString('OpenAd', '1');
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceType = 'Android';
      deviceId = androidInfo.id ?? '';
      deviceModel = androidInfo.model ?? '';
      deviceName = androidInfo.name;
      osVersion = 'Android ${androidInfo.version.release}';
      packageName = BibleInfo.android_Package_Name;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceType = 'iOS';
      osVersion = 'iOS ${iosInfo.systemVersion}';
      packageName = BibleInfo.ios_Bundle_Id;
      deviceName = iosInfo.name;
      deviceId = iosInfo.identifierForVendor ?? '';
      deviceModel = iosInfo.utsname.machine ?? '';
    }

    debugPrint(
        "urldata - $deviceType - $packageName - $appName - $deviceModel - $deviceId");

    final url =
        "https://bibleoffice.com/m_feedback/API/feedback_form/index.php?device_type=$deviceType&group_id=1&package_name=$packageName&app_name=$appName&device_id=$deviceId&device_model=$deviceModel&device_name=$deviceName&app_version=$appVersion&os_version=$osVersion&app_type=$deviceType&language=$language&country_code=$countryCode";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
    // const url =
    //     'https://bibleoffice.com/m_feedback/API/feedback_form/index.php';
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }

  Future<void> _requestReview() async {
    // var connectivityResult = await Connectivity().checkConnectivity();
    // if (connectivityResult.first == ConnectivityResult. ||
    //     connectivityResult.first == ConnectivityResult.wifi ||
    //     connectivityResult.first == ConnectivityResult.mobile) {

    final InAppReview inAppReview = InAppReview.instance;

    final isAvailable = await inAppReview.isAvailable();
    debugPrint('Is Available: $isAvailable. ');
    if (isAvailable) {
      try {
        await inAppReview.requestReview();
        await Future.delayed(Duration(seconds: 3));
        // Don't check connectivity after review - it's not needed
        // The review dialog doesn't require internet, and checking after can show false errors
      } catch (e, st) {
        Constants.showToast("review request failed");
        debugPrint('Error: $e,$st');
      }
    } else {
      Constants.showToast("review request not available, try again later");
    }

    // } else {
    //   Constants.showToast('Please connect to the internet');
    // }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (context) {
        //     return HomeScreen(
        //         From: "",
        //         selectedVerseNumForRead: "",
        //         selectedBookForRead: "",
        //         selectedChapterForRead: "",
        //         selectedBookNameForRead: "",
        //         selectedVerseForRead: "");
        //   }),
        // );
        Get.offAll(
            () => HomeScreen(
                From: "Setting",
                selectedVerseNumForRead: "",
                selectedBookForRead: "",
                selectedChapterForRead: "",
                selectedBookNameForRead: "",
                selectedVerseForRead: ""),
            transition: Transition.cupertinoDialog,
            duration: const Duration(milliseconds: 300));
      },
      child: Scaffold(
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration:
                Provider.of<ThemeProvider>(context).currentCustomTheme ==
                        AppCustomTheme.vintage
                    ? BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(Images.bgImage(context)),
                            fit: BoxFit.fill))
                    : null,
            child: ListView(
              shrinkWrap: true,
              physics: const ScrollPhysics(),
              children: [
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.offAll(
                            () => HomeScreen(
                                From: "Setting",
                                selectedVerseNumForRead: "",
                                selectedBookForRead: "",
                                selectedChapterForRead: "",
                                selectedBookNameForRead: "",
                                selectedVerseForRead: ""),
                            transition: Transition.cupertinoDialog,
                            duration: const Duration(milliseconds: 300));
                        // Get.back();
                        // Get.to(() => HomeScreen(
                        //     From: "",
                        //     selectedVerseNumForRead: "",
                        //     selectedBookForRead: "",
                        //     selectedChapterForRead: "",
                        //     selectedBookNameForRead: "",
                        //     selectedVerseForRead: ""));
                        // checknotification();
                        // Navigator.of(context).push(
                        //   MaterialPageRoute(builder: (context) {
                        //     return HomeScreen(
                        //         From: "",
                        //         selectedVerseNumForRead: "",
                        //         selectedBookForRead: "",
                        //         selectedChapterForRead: "",
                        //         selectedBookNameForRead: "",
                        //         selectedVerseForRead: "");
                        //   }),
                        // );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15.0),
                      child: Text("Settings",
                          style: CommanStyle.appBarStyle(context)),
                    ),
                    const SizedBox()
                  ],
                ),
                SizedBox(
                  height: screenWidth < 380 ? 12 : 20,
                ),
                Container(
                  height: 30,
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Notification",
                        style: CommanStyle.white14500,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                /////
                /// Morning Notification
                /////
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 7 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          showNotificationDialog(NotificationTime.morning);
                        },
                        child: Row(
                          children: [
                            Text(
                              "Morning",
                              style: CommanStyle.bw16500(context),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "($selectedTime)",
                              style: CommanStyle.bw12400(context),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FlutterSwitch(
                        duration: Duration.zero,
                        showOnOff: true,
                        activeTextColor: Colors.white,
                        inactiveTextColor: Colors.white,
                        activeTextFontWeight: FontWeight.w400,
                        inactiveTextFontWeight: FontWeight.w400,
                        value: notificationButtonValue,
                        toggleSize: screenWidth < 380 ? 16 : 22,
                        padding: 0,
                        height: screenWidth < 380 ? 17 : 25,
                        width: screenWidth < 380 ? 45 : 55,
                        valueFontSize: screenWidth < 380
                            ? BibleInfo.fontSizeScale * 12
                            : BibleInfo.fontSizeScale * 14,
                        activeColor: const Color(0xFF368117),
                        onToggle: (newVal) async {
                          final status = await Permission.notification.status;

                          if (status.isGranted) {
                            setState(() {
                              notificationButtonValue =
                                  !notificationButtonValue;
                            });
                            SharPreferences.setBoolean(
                                SharPreferences.isNotificationOn,
                                notificationButtonValue);
                            if (notificationButtonValue) {
                              setNotification(NotificationTime.morning);
                              // showNotificationAlertDialog(context);
                            } else {
                              disableNotification(NotificationTime.morning);
                            }
                          } else {
                            checkNotificationPermission();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                ////
                /// Afternoon
                ////
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 4 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          showNotificationDialog(NotificationTime.afternoon);
                        },
                        child: Row(
                          children: [
                            Text(
                              "Afternoon",
                              style: CommanStyle.bw16500(context),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "($selectedTime1)",
                              style: CommanStyle.bw12400(context),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FlutterSwitch(
                        duration: Duration.zero,
                        showOnOff: true,
                        activeTextColor: Colors.white,
                        inactiveTextColor: Colors.white,
                        activeTextFontWeight: FontWeight.w400,
                        inactiveTextFontWeight: FontWeight.w400,
                        value: notificationButtonValue1,
                        toggleSize: screenWidth < 380 ? 16 : 22,
                        padding: 0,
                        height: screenWidth < 380 ? 17 : 25,
                        width: screenWidth < 380 ? 45 : 55,
                        valueFontSize: screenWidth < 380
                            ? BibleInfo.fontSizeScale * 12
                            : BibleInfo.fontSizeScale * 14,
                        activeColor: const Color(0xFF368117),
                        onToggle: (newVal) async {
                          final status = await Permission.notification.status;

                          if (status.isGranted) {
                            setState(() {
                              notificationButtonValue1 =
                                  !notificationButtonValue1;
                            });
                            SharPreferences.setBoolean(
                                SharPreferences.isNotificationOn1,
                                notificationButtonValue1);
                            if (notificationButtonValue1) {
                              setNotification(NotificationTime.afternoon);
                              // showNotificationAlertDialog(context);
                            } else {
                              disableNotification(NotificationTime.afternoon);
                            }
                          } else {
                            checkNotificationPermission();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                //////Evening
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 7 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          showNotificationDialog(NotificationTime.evening);
                        },
                        child: Row(
                          children: [
                            Text(
                              "Evening",
                              style: CommanStyle.bw16500(context),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "($selectedTime2)",
                              style: CommanStyle.bw12400(context),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FlutterSwitch(
                        duration: Duration.zero,
                        showOnOff: true,
                        activeTextColor: Colors.white,
                        inactiveTextColor: Colors.white,
                        activeTextFontWeight: FontWeight.w400,
                        inactiveTextFontWeight: FontWeight.w400,
                        value: notificationButtonValue2,
                        toggleSize: screenWidth < 380 ? 16 : 22,
                        padding: 0,
                        height: screenWidth < 380 ? 17 : 25,
                        width: screenWidth < 380 ? 45 : 55,
                        valueFontSize: screenWidth < 380
                            ? BibleInfo.fontSizeScale * 12
                            : BibleInfo.fontSizeScale * 14,
                        activeColor: const Color(0xFF368117),
                        onToggle: (newVal) async {
                          final status = await Permission.notification.status;

                          if (status.isGranted) {
                            setState(() {
                              notificationButtonValue2 =
                                  !notificationButtonValue2;
                            });
                            SharPreferences.setBoolean(
                                SharPreferences.isNotificationOn2,
                                notificationButtonValue2);
                            if (notificationButtonValue2) {
                              setNotification(NotificationTime.evening);
                              //   showNotificationAlertDialog(context);
                            } else {
                              disableNotification(NotificationTime.evening);
                            }
                          } else {
                            checkNotificationPermission();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  height: 30,
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Verse of the Day",
                        style: CommanStyle.white14500,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 7 : 10),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => PreferenceSelectionScreen(
                            isSetting: true,
                          ));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Change Preferences",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                ////
                ///End of notification
                ///
                ///
                const SizedBox(
                  height: 5,
                ),
                Container(
                  height: 30,
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Appearance",
                        style: CommanStyle.white14500,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 5 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        themeProvider.isDarkMode ? "Light Mode" : "Dark Mode",
                        style: CommanStyle.bw16500(context),
                      ),
                      const Spacer(),
                      ChangeThemeButtonWidget()
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 7 : 10),
                  child: GestureDetector(
                    onTap: () => _showThemeDialog(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Themes",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Container(
                          // margin: const EdgeInsets.all(8),
                          width: screenWidth < 380 ? 27 : 32,
                          height: screenWidth < 380 ? 27 : 32,
                          decoration: BoxDecoration(
                            image: Provider.of<ThemeProvider>(context)
                                        .currentCustomTheme ==
                                    AppCustomTheme.vintage
                                ? DecorationImage(
                                    image:
                                        AssetImage(Images.bgImage((context))),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Provider.of<ThemeProvider>(context)
                                .backgroundColor,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        //ChangeThemeButtonWidget()
                      ],
                    ),
                  ),
                ),
                // Container(
                //   height: 30,
                //   color: Colors.black45,
                //   padding: const EdgeInsets.symmetric(horizontal: 20),
                //   width: MediaQuery.of(context).size.width,
                //   child: const Row(
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     children: [
                //       Text(
                //         "Font",
                //         style: CommanStyle.white14500,
                //       )
                //     ],
                //   ),
                // ),

                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 5 : 10),
                  child: InkWell(
                    onTap: () {
                      Get.to(() => const FontType(),
                          transition: Transition.cupertinoDialog,
                          duration: const Duration(milliseconds: 300));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Font Type",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  height: 30,
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Support",
                        style: CommanStyle.white14500,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 5 : 10),
                  child: InkWell(
                    onTap: _launchURL,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Feedback",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 1 : 10),
                  child: InkWell(
                    onTap: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      // Check actual internet access (not just network interface)
                      // This is more reliable than Connectivity() which can give false negatives
                      final hasInternet =
                          await InternetConnection().hasInternetAccess;

                      // Only show toast if actually offline - don't show when online
                      if (!hasInternet) {
                        Constants.showToast('Check Your Internet Connection');
                        return;
                      }
                      // If online, proceed directly without showing toast
                      _requestReview();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Rate Us",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: screenWidth < 380 ? 1 : 5,
                ),
                // Padding(
                //   padding: const EdgeInsets.only(
                //     left: 9,
                //     right: 20,
                //   ),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     children: [
                //       TextButton(
                //         onPressed: () async {
                //           await SharPreferences.setString('OpenAd', '1');
                //           Get.to(() => const FeedbackWebView(),
                //               transition: Transition.cupertinoDialog,
                //               duration: const Duration(milliseconds: 300));
                //         },
                //         child: Text(
                //           "Survey",
                //           style: CommanStyle.bw16500(context),
                //         ),
                //       ),
                //       const Spacer(),
                //       Icon(
                //         Icons.navigate_next,
                //         color: CommanColor.whiteBlack(context),
                //         size: 24,
                //       )
                //     ],
                //   ),
                // ),
                SizedBox(
                  height: screenWidth < 380 ? 1 : 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 21, vertical: screenWidth < 380 ? 4 : 10),
                  child: InkWell(
                    onTap: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      final url =
                          "https://bibleoffice.com/bible_faq.php?user=bala";

                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        throw 'Could not launch $url';
                      }
                      // Get.to(() => const FaqScreen(),
                      //     transition: Transition.cupertinoDialog,
                      //     duration: const Duration(milliseconds: 300));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "FAQ",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  height: 30,
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "About",
                        style: CommanStyle.white14500,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: screenWidth < 380 ? 5 : 10),
                  child: InkWell(
                    onTap: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      Get.to(() => const AboutUs(),
                          transition: Transition.cupertinoDialog,
                          duration: const Duration(milliseconds: 300));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "About Us",
                          style: CommanStyle.bw16500(context),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9, right: 20, top: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await SharPreferences.setString('OpenAd', '1');
                          if (Platform.isAndroid) {
                            launchUrl(
                                Uri.parse(
                                    "https://play.google.com/store/apps/dev?id=8519850462019154979"),
                                mode: LaunchMode.externalApplication);
                          } else if (Platform.isIOS) {
                            launchUrl(
                                Uri.parse(
                                    "https://apps.apple.com/us/developer/balasubramaniyan-thambusamy/id1701606111"),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          "More Apps",
                          style: CommanStyle.bw16500(context),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () async {
                          await SharPreferences.setString('OpenAd', '1');
                          if (Platform.isAndroid) {
                            launchUrl(
                                Uri.parse(
                                    "https://play.google.com/store/apps/dev?id=8519850462019154979"),
                                mode: LaunchMode.externalApplication);
                          } else if (Platform.isIOS) {
                            launchUrl(
                                Uri.parse(
                                    "https://apps.apple.com/us/developer/balasubramaniyan-thambusamy/id1701606111"),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Icon(
                          Icons.navigate_next,
                          color: CommanColor.whiteBlack(context),
                          size: 24,
                        ),
                      )
                    ],
                  ),
                ),

                // ListTile(
                //   dense: true,
                //   onTap: () async {},
                //   visualDensity:
                //       const VisualDensity(horizontal: 0, vertical: 0),
                //   leading: const Icon(
                //     Icons.edit_calendar,
                //     color: Color(0XFF805531),
                //   ),
                //   title: Text(
                //     'Survey',
                //     style: CommanStyle.bothPrimary16600(context),
                //   ),
                // ),
              ],
            )),
      ),
    );
  }

  void showNotificationAlertDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setBool("notificationshowonetime", true);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.grey,
                              )),
                        ],
                      ),
                    ),

                    /// Title
                    Text(
                      "Alert!",
                      style: TextStyle(
                        fontSize: screenWidth < 380
                            ? 19
                            : screenWidth > 450
                                ? 22
                                : 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),

                    SizedBox(height: 16),

                    /// Message
                    Text(
                      "To stay connected,\nplease enable notifications.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth < 380
                              ? 13
                              : screenWidth > 450
                                  ? 16
                                  : 14,
                          color: Colors.black87),
                    ),

                    SizedBox(height: 12),

                    /// Settings Path
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: screenWidth < 380
                                ? 13
                                : screenWidth > 450
                                    ? 16
                                    : 14,
                            color: Colors.black),
                        children: [
                          TextSpan(text: "Go to "),
                          TextSpan(
                            text: "Settings > Notifications > Enable",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    /// Open Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Add actual settings redirection logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF875736), // Brown
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Open Settings',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
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
  }

  Future<bool> checkNotificationPermission() async {
    try {
      debugPrint("function call");
      // Handle Android-specific logic
      if (Platform.isAndroid) {
        // Check for Android 12+ (API 31+) - exact alarm permission
        final ProcessResult result =
            await Process.run('getprop', ['ro.build.version.sdk']);
        final int sdkInt = int.tryParse(result.stdout.toString().trim()) ?? 0;

        debugPrint("Android SDK Version: $sdkInt");

        if (sdkInt >= 31) {
          if (await Permission.scheduleExactAlarm.isDenied) {
            await Permission.scheduleExactAlarm.request();
            debugPrint("Requested schedule exact alarm permission");
          }
        }
      } else {
// Check current notification permission
        if (await Permission.notification.isGranted) {
          return true;
        }

        final PermissionStatus status = await Permission.notification.request();

        // await openAppSettings();
        await showPermissionSettingsDialog(context);

        //  Get.back();
        // Get.offAll(() => HomeScreen(
        //     From: "splash",
        //     selectedVerseNumForRead: "",
        //     selectedBookForRead: "",
        //     selectedChapterForRead: "",
        //     selectedBookNameForRead: "",
        //     selectedVerseForRead: ""));

        // Request notification permission
        //final PermissionStatus status = await Permission.notification.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking notification permission: $e");
      return false;
    }
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    // Always show theme dialog first
    showDialog(
      context: context,
      builder: (_) => ThemeDialog(
        selected: Provider.of<ThemeProvider>(context, listen: false)
            .currentCustomTheme,
        onPremiumRequired: () => _showPremiumThemeDialog(context),
      ),
    );
  }

  Future<void> _showPremiumThemeDialog(BuildContext context) async {
    // Check subscription status before showing premium dialog
    // Only show for unsubscribed users
    bool isSubscribed = false;

    // First check subscription plan - getSubscriptionPlan() reads directly from SharedPreferences
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final subscriptionPlan = await downloadProvider.getSubscriptionPlan();
    final hasSubscriptionPlan = subscriptionPlan != null &&
        subscriptionPlan.isNotEmpty &&
        ['platinum', 'gold', 'silver'].contains(subscriptionPlan.toLowerCase());

    // Check expiry date (this is set by disableAd() during subscription/restore)
    String? expiryDateString;
    try {
      expiryDateString =
          await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
    } catch (e) {
      debugPrint("Error getting expiry date in premium dialog: $e");
    }

    // Must have subscription plan AND valid expiry date, OR just valid expiry date as fallback
    if (hasSubscriptionPlan &&
        expiryDateString != null &&
        expiryDateString.isNotEmpty) {
      try {
        final expiryDate = DateTime.parse(expiryDateString);
        final currentTime = DateTime.now();
        final diffDays = expiryDate.difference(currentTime).inDays;
        // Subscription is valid if expiry date is today or in the future (>= 0)
        // This includes lifetime subscriptions (>365 days)
        isSubscribed = diffDays >= 0;
        debugPrint(
            "_showPremiumThemeDialog: Subscription check - plan: $subscriptionPlan, expiry: $expiryDateString, diffDays: $diffDays, isSubscribed: $isSubscribed");
      } catch (e) {
        debugPrint("Error parsing subscription expiry in premium dialog: $e");
        isSubscribed = false;
      }
    } else if (expiryDateString != null && expiryDateString.isNotEmpty) {
      // Fallback: If subscription plan is not found but expiry date exists and is valid,
      // consider user subscribed (handles cases where plan wasn't saved but expiry was set)
      try {
        final expiryDate = DateTime.parse(expiryDateString);
        final currentTime = DateTime.now();
        final diffDays = expiryDate.difference(currentTime).inDays;
        if (diffDays >= 0) {
          isSubscribed = true;
          debugPrint(
              "_showPremiumThemeDialog: Fallback check - No plan found but valid expiry date exists: $expiryDateString, diffDays: $diffDays, isSubscribed: $isSubscribed");
        } else {
          debugPrint(
              "_showPremiumThemeDialog: Fallback check - Expiry date found but expired: $expiryDateString, diffDays: $diffDays");
        }
      } catch (e) {
        debugPrint("Error parsing expiry date in fallback premium dialog: $e");
        isSubscribed = false;
      }
    } else {
      debugPrint(
          "_showPremiumThemeDialog: No subscription plan found and no expiry date found, user not subscribed");
    }

    // Don't show premium dialog if user is subscribed
    if (isSubscribed) {
      debugPrint(
          "_showPremiumThemeDialog: User is subscribed, not showing premium dialog");
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final oldPaperColor = themeProvider
        .backgroundColor; // Get old paper theme color (Color(0xFFF3E5C2))

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: oldPaperColor, // Use old paper theme color
          child: Container(
            width: screenWidth > 450
                ? screenWidth * 0.5
                : screenWidth * 0.85, // Make dialog wider
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - Single line
                Text(
                  'Premium Access Required',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth > 450 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                // Body text
                Text(
                  'Upgrade to access all themes and personalise your Bible with a richer, distraction-free reading experience.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth > 450 ? 16 : 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              oldPaperColor, // Use old paper theme color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Maybe Later',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth > 450 ? 15 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Don't check connectivity before navigating - similar to Rate Us
                          // The subscription screen will handle any connectivity issues if needed
                          Navigator.pop(context);
                          // Use constants as fallback when SharedPreferences are empty (first time loading)
                          final sixMonthPlan =
                              await SharPreferences.getString('sixMonthPlan') ??
                                  BibleInfo.sixMonthPlanid;
                          final oneYearPlan =
                              await SharPreferences.getString('oneYearPlan') ??
                                  BibleInfo.oneYearPlanid;
                          final lifeTimePlan =
                              await SharPreferences.getString('lifeTimePlan') ??
                                  BibleInfo.lifeTimePlanid;
                          Get.to(
                            () => SubscriptionScreen(
                              sixMonthPlan: sixMonthPlan,
                              oneYearPlan: oneYearPlan,
                              lifeTimePlan: lifeTimePlan,
                              checkad: 'theme',
                            ),
                            transition: Transition.cupertinoDialog,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF8B5E3C), // Dark brown
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Upgrade Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 450 ? 15 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showPermissionSettingsDialog(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: CommanColor.white,
        title: Text(
          "Permission Required",
          style: TextStyle(color: CommanColor.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enable notification in settings to use this feature.",
              style: TextStyle(color: CommanColor.black),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Settings > Notifications > Enable",
              style: TextStyle(
                  color: CommanColor.black, fontWeight: FontWeight.w700),
            )
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await SharPreferences.setString('OpenAd', '1');
                    await openAppSettings(); // Opens settings

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF875736), // Brown
                    padding: EdgeInsets.symmetric(
                        vertical: screenWidth < 380
                            ? 11
                            : screenWidth > 450
                                ? 13
                                : 12,
                        horizontal: screenWidth < 380
                            ? 14.0
                            : screenWidth > 450
                                ? 21.0
                                : 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: screenWidth < 380
                          ? 14.0
                          : screenWidth > 450
                              ? 17
                              : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    //  openAppSettings(); // Opens settings
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommanColor.lightGrey1, // Brown
                    padding: EdgeInsets.symmetric(
                        vertical: screenWidth < 380
                            ? 11
                            : screenWidth > 450
                                ? 13
                                : 12,
                        horizontal: screenWidth < 380
                            ? 14.0
                            : screenWidth > 450
                                ? 21.0
                                : 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: screenWidth < 380
                          ? 14.0
                          : screenWidth > 450
                              ? 17
                              : 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // TextButton(
          //   onPressed: () => Navigator.pop(context), // Dismiss
          //   child: Text(
          //     "Cancel",
          //     style: TextStyle(color: CommanColor.black),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class NotifyMeDialog extends StatelessWidget {
  const NotifyMeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 100 : 24,
        vertical: isTablet ? 60 : 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                      )),
                ],
              ),
            ),
            Image.asset(
              Images.notificationBell(context),
              fit: BoxFit.fill,
              height: 25,
              width: 25,
            ),
            const SizedBox(height: 16),
            const Text(
              "Choose Your Daily Verse Time",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Select the time you’d like to receive the Verse of the Day and stay connected with God’s Word",
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("Set Reminder Time",
                    style: TextStyle(fontSize: 15, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ThemeDialog extends StatefulWidget {
  final AppCustomTheme selected;
  final VoidCallback onPremiumRequired;

  const ThemeDialog({
    super.key,
    required this.selected,
    required this.onPremiumRequired,
  });

  @override
  State<ThemeDialog> createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<ThemeDialog> {
  late AppCustomTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeProvider>(context);
    final themes = AppCustomTheme.values;

    Color getColor(AppCustomTheme theme) {
      switch (theme) {
        case AppCustomTheme.vintage:
          return const Color(0xFFF3E5C2);
        case AppCustomTheme.white:
          return Colors.white;
        case AppCustomTheme.lightbrown:
          return CommanColor.backgrondcolor;
      }
    }

    Widget themeBox(AppCustomTheme theme) {
      final color = getColor(theme);

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedTheme = theme;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            image: theme == AppCustomTheme.vintage
                ? DecorationImage(
                    image: AssetImage(Images.bgImage((context))),
                    fit: BoxFit.cover,
                  )
                : null,
            border: Border.all(
              color: _selectedTheme == theme
                  ? Colors.brown
                  : const Color.fromARGB(255, 230, 230, 230),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: CommanColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: const Text(
              "Theme",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: themes.map(themeBox).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                ),
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Close", style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                onPressed: () async {
                  final provider =
                      Provider.of<ThemeProvider>(context, listen: false);
                  if (_selectedTheme == provider.currentCustomTheme) {
                    Constants.showToast("This theme is already applied");
                    return;
                  }

                  // Check subscription before setting theme - same logic as intro subscription screen
                  // When user subscribes or restores, disableAd() is called which sets expiry date in isRewardAdViewTime
                  bool isSubscribed = false;

                  // First check subscription plan
                  final downloadProvider =
                      Provider.of<DownloadProvider>(context, listen: false);
                  final subscriptionPlan =
                      await downloadProvider.getSubscriptionPlan();
                  final hasSubscriptionPlan = subscriptionPlan != null &&
                      subscriptionPlan.isNotEmpty &&
                      ['platinum', 'gold', 'silver']
                          .contains(subscriptionPlan.toLowerCase());

                  // Check expiry date (this is set by disableAd() during subscription/restore)
                  String? expiryDateString;
                  try {
                    expiryDateString = await SharPreferences.getString(
                        SharPreferences.isRewardAdViewTime);
                  } catch (e) {
                    debugPrint("Error getting expiry date: $e");
                  }

                  // Must have subscription plan AND valid expiry date, OR just valid expiry date as fallback
                  if (hasSubscriptionPlan &&
                      expiryDateString != null &&
                      expiryDateString.isNotEmpty) {
                    try {
                      final expiryDate = DateTime.parse(expiryDateString);
                      final currentTime = DateTime.now();
                      final diffDays =
                          expiryDate.difference(currentTime).inDays;
                      // Subscription is valid if expiry date is today or in the future (>= 0)
                      // This includes lifetime subscriptions (>365 days)
                      isSubscribed = diffDays >= 0;
                      debugPrint(
                          "ThemeDialog: Subscription check - plan: $subscriptionPlan, expiry: $expiryDateString, diffDays: $diffDays, isSubscribed: $isSubscribed");
                    } catch (e) {
                      debugPrint("Error parsing subscription expiry: $e");
                      isSubscribed = false;
                    }
                  } else if (expiryDateString != null &&
                      expiryDateString.isNotEmpty) {
                    // Fallback: If subscription plan is not found but expiry date exists and is valid,
                    // consider user subscribed (handles cases where plan wasn't saved but expiry was set)
                    try {
                      final expiryDate = DateTime.parse(expiryDateString);
                      final currentTime = DateTime.now();
                      final diffDays =
                          expiryDate.difference(currentTime).inDays;
                      if (diffDays >= 0) {
                        isSubscribed = true;
                        debugPrint(
                            "ThemeDialog: Fallback check - No plan found but valid expiry date exists: $expiryDateString, diffDays: $diffDays, isSubscribed: $isSubscribed");
                      } else {
                        debugPrint(
                            "ThemeDialog: Fallback check - Expiry date found but expired: $expiryDateString, diffDays: $diffDays");
                      }
                    } catch (e) {
                      debugPrint("Error parsing expiry date in fallback: $e");
                      isSubscribed = false;
                    }
                  } else {
                    debugPrint(
                        "ThemeDialog: No subscription plan found and no expiry date found, user not subscribed");
                  }

                  if (!isSubscribed) {
                    // Close theme dialog and show premium dialog
                    Navigator.pop(context);
                    widget.onPremiumRequired();
                  } else {
                    // User is subscribed, set theme directly without showing premium dialog
                    debugPrint(
                        "ThemeDialog: User is subscribed, setting theme directly");
                    provider.setCustomTheme(_selectedTheme);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Set", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
