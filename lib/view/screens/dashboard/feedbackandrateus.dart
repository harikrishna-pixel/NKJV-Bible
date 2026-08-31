import 'dart:io';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RateUsDialog extends StatelessWidget {
  final ValueNotifier<int> _rating = ValueNotifier<int>(0);
  final ValueNotifier<bool> _showFeedbackButton = ValueNotifier<bool>(false);

  RateUsDialog({super.key});

  void _setRating(int rating) {
    _rating.value = rating;
    _showFeedbackButton.value = rating >= 4;
  }

  void _submitRating() {
    final int rating = _rating.value;
    if (rating > 0) {
      // TODO: Handle the user's rating submission
      // You can send the rating to an API or store it locally
      print('User rating: $rating');
    }
  }

  void _submitFeedback() {
    // TODO: Handle the user's feedback submission
    // You can launch an email intent or navigate to a feedback screen
    print('User feedback');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AlertDialog(
        title: Text('Rate Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you rate our app?'),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: _rating,
              builder: (BuildContext context, int value, Widget? child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => _setRating(i),
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: value >= i ? Colors.yellow : Colors.grey,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey[500]),
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 50),
              ValueListenableBuilder<bool>(
                valueListenable: _showFeedbackButton,
                builder: (BuildContext context, bool value, Widget? child) {
                  if (!value) {
                    return ElevatedButton(
                      child: Text('Feedback'),
                      onPressed: () async {
                        final DeviceInfoPlugin deviceInfoPlugin =
                            DeviceInfoPlugin();
                        String deviceType = 'ios';
                        String groupId = '1';
                        String packageName = '';
                        String appName = BibleInfo.bible_shortName;
                        String deviceId = '';
                        String deviceModel = '';
                        String deviceName = '';
                        String appVersion = '';
                        String osVersion = '';
                        String appType = '';
                        String language = 'en';
                        String countryCode = 'IN';
                        String themeColor = 'd43f8d';
                        String themeMode = '0';
                        String width = '100px';
                        String height = '100px';
                        String isDevelopOrProd = '0';

                        if (Platform.isAndroid) {
                          final androidInfo =
                              await deviceInfoPlugin.androidInfo;
                          deviceType = 'Android';
                          deviceId = androidInfo.id ?? '';
                          deviceModel = androidInfo.model ?? '';
                          packageName = BibleInfo.android_Package_Name;
                        } else if (Platform.isIOS) {
                          final iosInfo = await deviceInfoPlugin.iosInfo;
                          deviceType = 'iOS';
                          packageName = BibleInfo.ios_Bundle_Id;
                          deviceId = iosInfo.identifierForVendor ?? '';
                          deviceModel = iosInfo.utsname.machine ?? '';
                        }

                        debugPrint(
                            "urldata - $deviceType - $packageName - $appName - $deviceModel - $deviceId");

                        final url =
                            "https://bibleoffice.com/m_feedback/API/feedback_form/index.php?device_type=$deviceType&group_id=1&package_name=$packageName&app_name=$appName&device_id=$deviceId&device_model=$deviceModel";

                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    );
                  } else {
                    return ElevatedButton(
                      child: Text('Rate Us'),
                      onPressed: () async {
                        var appId = BibleInfo.apple_AppId;
                        if (Platform.isAndroid) {
                          final appPackageName =
                              (await PackageInfo.fromPlatform()).packageName;
                          try {
                            launchUrl(Uri.parse(
                                "market://details?id=$appPackageName"));
                          } on PlatformException {
                            launchUrl(Uri.parse(
                                "https://play.google.com/store/apps/details?id=$appPackageName"));
                          }
                        } else if (Platform.isIOS) {
                          launchUrl(Uri.parse(
                              "https://apps.apple.com/sg/app/myturf-app/id$appId"));
                        }
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
