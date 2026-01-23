import 'dart:io';
import 'dart:ui' as ui;

import 'package:biblebookapp/main.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../constants/images.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  final InAppReview _inAppReview = InAppReview.instance;
  Availability availability = Availability.loading;
  final String _appStoreId = '6461349171';
  final String _microsoftStoreId = '';

  Future<void> _requestReview() async {
    // final isAvailable = await _inAppReview.isAvailable();
    // log('Is Available: $isAvailable');
    // if (isAvailable) {
    //   try {
    //     await _inAppReview.requestReview();
    //   } catch (e, st) {
    //     log('Error: $e,$st');
    //   }
    // }
    // Retry-friendly connectivity check to avoid false "offline" on first run
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResult.isNotEmpty &&
        (connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.ethernet));
    if (!hasConnection) {
      await Future.delayed(const Duration(milliseconds: 500));
      final retry = await Connectivity().checkConnectivity();
      final retryHasConnection = retry.isNotEmpty &&
          (retry.contains(ConnectivityResult.wifi) ||
              retry.contains(ConnectivityResult.mobile) ||
              retry.contains(ConnectivityResult.ethernet));
      if (!retryHasConnection) {
        // Check actual internet access
        try {
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            return Constants.showToast("No Internet Connection");
          } else {
            return Constants.showToast("Check your Internet connection");
          }
        } catch (_) {
          return Constants.showToast("No Internet Connection");
        }
      }
    }

    final InAppReview inAppReview = InAppReview.instance;

    final isAvailable = await inAppReview.isAvailable();
    debugPrint('Is Available: $isAvailable');
    if (isAvailable) {
      try {
        await inAppReview.requestReview();
      } catch (e, st) {
        Constants.showToast("review request failed");
        debugPrint('Error: $e,$st');
      }
    } else {
      Constants.showToast("review request not available, try again later");
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> openStoreListing() async {
      await _inAppReview.openStoreListing(
        appStoreId: _appStoreId,
        microsoftStoreId: _microsoftStoreId,
      );
    }

    Future<void> checkAvailability() async {
      try {
        final isAvailable = await _inAppReview.isAvailable();

        // This plugin cannot be tested on Android by installing your app
        // locally. See https://github.com/britannio/in_app_review#testing for
        // more information.
        availability = isAvailable && !Platform.isAndroid
            ? Availability.available
            : Availability.unavailable;
      } catch (_) {
        availability = Availability.unavailable;
      }
    }

    // Run the availability check on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAvailability();
    });
    String bibleName;
    bibleName = BibleInfo.bible_shortName;
    String bibleVersion;
    bibleVersion = BibleInfo.current_Version;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.fill))
            : null,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text("About Us",
                        style: CommanStyle.appBarStyle(context)),
                  ),
                  SizedBox()
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Image.asset(
                "assets/new_ico.png",
                height: 100,
                width: 100,
              ),
              SizedBox(
                height: 30,
              ),
              //Image.asset(Images.appLogo(context),width: 200,height: 200,color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark ? Colors.white:Colors.black ,),
              Text(
                "$bibleName  $bibleVersion",
                style: CommanStyle.appBarStyle(context),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: const Text(
                      "Thanks for downloading the app. We continually strive to provide user with best possible features and options to read the Bible App. Please send us your feedback.",
                      textAlign: TextAlign.center,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Support us by rating the app",
                style: CommanStyle.bw17500(context),
              ),
              const SizedBox(
                height: 40,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: 40,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        alignment: Alignment.center,
                        // maximumSize: Size(MediaQuery.of(context).size.width, 40),
                        backgroundColor:
                            CommanColor.inDarkWhiteAndInLightPrimary(context)),
                    onPressed: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      final DeviceInfoPlugin deviceInfoPlugin =
                          DeviceInfoPlugin();
                      PackageInfo packageInfo =
                          await PackageInfo.fromPlatform();
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

                      if (Platform.isAndroid) {
                        final androidInfo = await deviceInfoPlugin.androidInfo;
                        deviceType = 'Android';
                        deviceId = androidInfo.id ?? '';
                        deviceName = androidInfo.name;
                        deviceModel = androidInfo.model ?? '';
                        osVersion = 'Android ${androidInfo.version.release}';
                        packageName = BibleInfo.android_Package_Name;
                      } else if (Platform.isIOS) {
                        final iosInfo = await deviceInfoPlugin.iosInfo;
                        deviceType = 'iOS';
                        osVersion = 'iOS ${iosInfo.systemVersion}';
                        deviceName = iosInfo.name;
                        packageName = BibleInfo.ios_Bundle_Id;
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
                    },
                    child: Text(
                      "Feedback",
                      style:
                          CommanStyle.inDarkPrimaryInLightWhite15500(context),
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: 40,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        alignment: Alignment.center,
                        // maximumSize: Size(MediaQuery.of(context).size.width, 40),
                        backgroundColor:
                            CommanColor.inDarkWhiteAndInLightPrimary(context)),
                    onPressed: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      final appPackageName =
                          (await PackageInfo.fromPlatform()).packageName;
                      String message =
                          ''; // Declare the message variable outside the if-else block
                      String appid;
                      appid = BibleInfo.apple_AppId;
                      if (Platform.isAndroid) {
                        message =
                            "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://play.google.com/store/apps/details?id=$appPackageName";
                      } else if (Platform.isIOS) {
                        message =
                            "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://itunes.apple.com/app/id$appid"; // Example iTunes URL
                      }

                      if (message.isNotEmpty) {
                        Share.share(message,
                            sharePositionOrigin: Rect.fromPoints(
                                const Offset(2, 2), const Offset(3, 3)));
                      } else {
                        print('Message is empty or undefined');
                      }
                    },
                    child: Text(
                      "Share",
                      style:
                          CommanStyle.inDarkPrimaryInLightWhite15500(context),
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: 40,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        alignment: Alignment.center,
                        // maximumSize: Size(MediaQuery.of(context).size.width, 40),
                        backgroundColor:
                            CommanColor.inDarkWhiteAndInLightPrimary(context)),
                    onPressed: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      _requestReview();
                    },
                    child: Text(
                      "Rate Us",
                      style:
                          CommanStyle.inDarkPrimaryInLightWhite15500(context),
                    )),
              ),
              // const SizedBox(height: 20,),
              // SizedBox(
              //   width: MediaQuery.of(context).size.width*0.55,
              //   height: 40,
              //   child: ElevatedButton(
              //       style: ElevatedButton.styleFrom(
              //           alignment: Alignment.center,
              //           // maximumSize: Size(MediaQuery.of(context).size.width, 40),
              //           backgroundColor: CommanColor.inDarkWhiteAndInLightPrimary(context)
              //       ),
              //       onPressed: ()  {
              //        Get.to(()=>AboutUpdateScreen());
              //       }, child:Text("About Update",style: CommanStyle.inDarkPrimaryInLightWhite15500(context),)),
              //
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
