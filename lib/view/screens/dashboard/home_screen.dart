import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:biblebookapp/Model/dailyVerseList.dart';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/auth/auth.notifier.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/main.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/utils/emoji_text_style.dart';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/utils/network_error_message.dart';
import 'package:biblebookapp/view/widget/thanks_for_love_rating_dialog_content.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/bible_select_screen.dart';
import 'package:biblebookapp/view/screens/books/books_screen.dart';
import 'package:biblebookapp/view/screens/calendar_screen/view/calendar_screen.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/add_widget_intro_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/ios_style_app_drawer.dart';
import 'package:biblebookapp/view/screens/dashboard/social_link_screen.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topics_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/own_referral_code_dialog.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/eproducts_screen.dart';

import 'package:biblebookapp/view/screens/dashboard/mark_as_read_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/myLibrary.dart';
import 'package:biblebookapp/view/screens/dashboard/Search.dart';
import 'package:biblebookapp/view/screens/dashboard/dailyverse.dart';
import 'package:biblebookapp/view/screens/dashboard/fActionButton.dart';
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/more_apps/more_apps_screen.dart';
import 'package:biblebookapp/view/screens/profile/view/profile_screen.dart';
import 'package:biblebookapp/view/screens/quote_screen/quote_screen.dart';
import 'package:biblebookapp/view/screens/wallpaper_screen/wallpaper_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/chat/prayer_guidance_screen.dart';
import 'package:biblebookapp/streak/streak_ui.dart';
import 'package:biblebookapp/services/smart_notification_helper.dart';
import 'package:biblebookapp/services/daily_slot_notification_helper.dart';
import 'package:biblebookapp/streak_flow/daily_journey_screen.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart'
    hide SharPreferences;
import '../../constants/share_preferences.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:home_widget/home_widget.dart';
import 'package:biblebookapp/view/widget/webview.dart';
import 'package:biblebookapp/view/screens/study_plans/study_plans_screen.dart'
    as biblebookapp;
import 'package:popover/popover.dart';

import 'package:biblebookapp/view/widget/verse_item_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../constants/changeThemeButtun.dart';
import 'package:html/parser.dart' show parse;
import '../../constants/constant.dart';
import '../../constants/images.dart';
import '../../widget/home_content_edit_bottom_sheet.dart';
import '../authenitcation/view/login_screen.dart';
import 'book_list_screen.dart';
import 'chapterListScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as p;
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:html/parser.dart' as html;

/// Display-only thresholds for subscription info copy (does not affect IAP logic).
const int _kSubscriptionLifetimeDisplayMinDays = 10000;
const int _kSubscriptionTwoYearDisplayMinDays = 400;

bool _isLifetimeSubscriptionDisplay(int diffDy) =>
    diffDy > _kSubscriptionLifetimeDisplayMinDays;

bool _isTwoYearSubscriptionDisplay(int diffDy) =>
    diffDy >= _kSubscriptionTwoYearDisplayMinDays &&
    diffDy <= _kSubscriptionLifetimeDisplayMinDays;

/// Calendar-day count until expiry (matches what users expect in "X days left").
int _subscriptionDaysRemaining(DateTime expiryDate, [DateTime? now]) {
  final current = now ?? DateTime.now();
  final expiryOnly =
      DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  final nowOnly = DateTime(current.year, current.month, current.day);
  return expiryOnly.difference(nowOnly).inDays;
}

String _subscriptionRenewalDisplayText(int diffDy, [String? plan]) {
  if (diffDy < 0) {
    return 'Your subscription has expired';
  }
  final planKey = plan?.toLowerCase() ?? '';
  final dayLabel = diffDy == 1 ? 'day' : 'days';
  // Additive: silver/gold copy must not become "never expire" just because
  // remaining days are huge (e.g. bad lifetime expiry overwrite).
  if (planKey == 'silver' || planKey == 'gold') {
    return '$diffDy $dayLabel left for the renewal of the subscription.';
  }
  if (_isLifetimeSubscriptionDisplay(diffDy) || planKey == 'platinum') {
    return 'Your subscription will never expire';
  }
  return '$diffDy $dayLabel left for the renewal of the subscription.';
}

String _subscriptionPeriodDisplayText(
  String? plan,
  int diffDy,
  DateTime expiryDate,
) {
  final planKey = plan?.toLowerCase() ?? '';
  // Additive: trust stored plan key first so Restore info matches the plan
  // that was applied (silver/gold), not a lifetime day-threshold fallback.
  if (planKey == 'silver') {
    return 'Your subscription period is 6 months';
  }
  if (planKey == 'gold') {
  if (_isTwoYearSubscriptionDisplay(diffDy)) {
    return 'Your subscription period is 2 years';
  }
    return 'Your subscription period is 1 year';
  }
  if (_isLifetimeSubscriptionDisplay(diffDy) || planKey == 'platinum') {
    return 'Your subscription period is lifetime';
  }
  if (_isTwoYearSubscriptionDisplay(diffDy)) {
    return 'Your subscription period is 2 years';
  }
  return 'Your subscription expires on ${DateFormat('dd-MM-yyyy').format(expiryDate)}';
}

Widget _buildSubscriptionInfoDetails({
  required BuildContext context,
  required DateTime expiryDate,
  required double screenWidth,
}) {
  final diffDy = _subscriptionDaysRemaining(expiryDate);
  final downloadProvider =
      Provider.of<DownloadProvider>(context, listen: false);
  final textStyle = TextStyle(
    letterSpacing: BibleInfo.letterSpacing,
    fontSize: screenWidth < 380
        ? BibleInfo.fontSizeScale * 13
        : BibleInfo.fontSizeScale * 15,
    color: CommanColor.lightDarkPrimary(context),
    fontWeight: FontWeight.w400,
  );

  return FutureBuilder<String?>(
    future: downloadProvider.getSubscriptionPlan(),
    builder: (context, snapshot) {
      final plan = snapshot.data;
      return Column(
        children: [
          Text(
            _subscriptionRenewalDisplayText(diffDy, plan),
            style: textStyle,
          ),
          const SizedBox(height: 5),
          Text(
            _subscriptionPeriodDisplayText(plan, diffDy, expiryDate),
            style: textStyle,
          ),
          const SizedBox(height: 5),
        ],
      );
    },
  );
}

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  var selectedBookForRead;
  var selectedBookNameForRead;
  var selectedChapterForRead;
  var selectedVerseNumForRead;
  var selectedVerseForRead;
  var From;

  /// When true (e.g. opened from Search), verse is shown in default reading font, not user-selected font.
  final bool fromSearch;

  HomeScreen(
      {super.key,
      required this.selectedBookForRead,
      required this.selectedChapterForRead,
      required this.selectedVerseNumForRead,
      required this.From,
      required this.selectedBookNameForRead,
      required this.selectedVerseForRead,
      this.fromSearch = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  bool isOpenChat = false;
  bool _attemptedProviderChapterFallback = false;
  bool _hasDisplayedChapterContent = false;
  List<VerseBookContentModel> _lastVisibleChapterContent = [];
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   final ValueNotifier<int> _rating = ValueNotifier<int>(0);

//   final ValueNotifier<bool> _showFeedbackButton = ValueNotifier<bool>(false);

//   final ValueNotifier<DateTime?> lastIntertitialAdPlayed = ValueNotifier(null);

//   final ValueNotifier<String> adsDuration = ValueNotifier('0');
//   late List<ConnectivityResult> result;
//   final Connectivity _connectivity = Connectivity();
//   final InAppReview inAppReview = InAppReview.instance;
//   final AdService _adService = AdService();

//   String? RewardAdExpireDate;
//   String? selectedcolor;
//   void _setRating(int rating) {
//     _rating.value = rating;
//     _showFeedbackButton.value = rating >= 4;
//   }

//   double _fontSize = 19.0;
//   bool _scrollListenerAttached = false;

// // daily verse
//   List<DailyVerseList> dailyVerseList = [];
//   final bool _hasShownVerseToday = false;
//   DateTime? _lastShownTime;

//   loadAds() async {
//     final shouldLoadAd = await SharPreferences.shouldLoadAd();

//     if (shouldLoadAd) {

//       debugPrint("ad is called");
//       _adService.loadBannerAd(() {
//         if (mounted) {
//           setState(() {});
//         }
//       });
//     }
//   }

//   final GlobalKey _verseContainerKey = GlobalKey();
//   Future<void> loadInterstitialAd(DashBoardController controller) async {
//     final currentDate = DateTime.now();
//     int duration = int.tryParse(adsDuration.value) ?? 0;

//     if (lastIntertitialAdPlayed.value == null) {
//       if (controller.isInterstitialAdLoad.value &&
//           controller.adFree.value == false) {
//         try {
//           await controller.interstitialAd?.show();
//           lastIntertitialAdPlayed.value = DateTime.now();
//         } catch (e) {
//           debugPrint('Eror Loading Interstitial Ad:$e');
//         }
//       }
//     } else {
//       if (duration != 0) {
//         final diff =
//             currentDate.difference(lastIntertitialAdPlayed.value!).inMinutes;
//         if ((diff) > duration) {
//           if (controller.isInterstitialAdLoad.value &&
//               controller.adFree.value == false) {
//             try {
//               await controller.interstitialAd?.show();
//               lastIntertitialAdPlayed.value = DateTime.now();
//             } catch (e) {
//               debugPrint('Eror Loading Interstitial Ad:$e');
//             }
//           }
//         }
//       } else {
//         if (controller.isInterstitialAdLoad.value &&
//             controller.adFree.value == false) {
//           try {
//             await controller.interstitialAd?.show();
//             lastIntertitialAdPlayed.value = DateTime.now();
//           } catch (e) {
//             debugPrint('Eror Loading Interstitial Ad:$e');
//           }
//         }
//       }
//     }
//   }

//   bool isAdReady = false;

//   void _handleReward() async {
//     await SharPreferences.setBoolean("downloadreward", true);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//           content: Text('You earned a reward!, Now you can download')),
//     );
//     // Do your logic like increase appCount etc.
//   }

//   Future<void> _handleAdDismissed() async {
//     if (mounted) {
//       setState(() => isAdReady = false);
//     }
//     await SharPreferences.setString('OpenAd', '1');
//     RewardedAdService.loadAd(onAdLoaded: () {
//       if (mounted) {
//         setState(() => isAdReady = true);
//       }
//     });
//   }

//   String? message;
//   bool adsIcon = true;
//   bool isLoggedIn = false;

//   final AdService adService = AdService();
//   int swipeCount = 0;
//   int _swipeThreshold = 7;
//   int appLaunchCount = 0;
//   int appLaunchCountoffer = 0;
//   Availability availability = Availability.loading;
//   String? sixMonthPlan;
//   String? oneYearPlan;
//   String? lifeTimePlan;
//   int clickCount = 0;
//   List<DailyVerseList> filteredList = [];
//   final audioPlayer = AudioPlayer();
//   bool _isBottomSheetOpen = false;

//   Future<void> _loadFontSize() async {
//     final prefs = await SharedPreferences.getInstance();
//     final value = prefs.getString(SharPreferences.selectedFontSize);
//     if (mounted) {
//       setState(() {
//         _fontSize = value != null ? double.tryParse(value) ?? 19.0 : 19.0;
//       });
//     }
//   }

//   setdownloadreward() async {
//     await SharPreferences.setBoolean("downloadreward", false);
//     if (mounted) {
//       setState(() {
//         clickCount = 0;
//       });
//     }
//   }

//   checkuserloggedin() async {
//     final adProvider = DownloadProvider();
//     await adProvider.init();
//     final cacheprovider = Provider.of<CacheNotifier>(context, listen: false);
//     result = await _connectivity.checkConnectivity();
//     await checkingappcount(result);
//     final data = await cacheprovider.readCache(key: 'user');
//     // final dataname = await cacheprovider.readCache(key: 'name');

//     final datacount =
//         await SharPreferences.getString(SharPreferences.showinterstitialrow);

//     _swipeThreshold = int.parse(datacount ?? "7");

//     //   debugPrint("ad count is $_swipeThreshold");
//     final shouldLoadAd = await SharPreferences.shouldLoadAd();

//     debugPrint("ad count is $_swipeThreshold  $shouldLoadAd");
//     if (shouldLoadAd) {
//       //
//       //
//       debugPrint("ad int is 0");
//       adService.loadInterstitialAd(() {
//         debugPrint("ad int is 1");
//         if (mounted) {
//           setState(() {});
//         }
//         debugPrint("ad int is 2");
//       });
//     }
//     if (data != null) {
//       if (mounted) {
//         setState(() {
//           isLoggedIn = true;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           isLoggedIn = false;
//         });
//       }
//     }
//   }

  Future<void> _checkAndShowOfferDialog() async {
    int randomNumber = 0;
    final dataprovider = Provider.of<AuthNotifier>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDialogShown = prefs.getBool('offerDialogShown') ?? false;
    appLaunchCount = prefs.getInt('launchCount') ?? 0;
    appLaunchCountoffer = prefs.getInt('launchCountoffer') ?? 0;

    await Future.delayed(
      Duration(seconds: 1),
    );

    // await prefs.setInt('launchCountoffer', appLaunchCountoffer);
    debugPrint("offer dialog is open $isDialogShown  ");

    await SharPreferences.setBoolean("downloadreward", true);

    if (isDialogShown == false) {
      // Show the dialog
      final data2 = prefs.getString("alrt") ?? '0';

      // if (data2 != '1') {
      //   await Future.delayed(
      //     Duration(seconds: 1),
      //   );
      //   // final check = await Permission.notification.isGranted;

      //   // debugPrint("check nofi $check");
      //   // if (check) {
      //   //   await SharPreferences.setString('OpenAd', '1');
      //   //   await showNotificationDialog(context, () async {
      //   //     await SharPreferences.setString('OpenAd', '1');
      //   //     return _checkAndShowOfferDialog();
      //   //   });
      //   // } else {
      //   await prefs.setString("alrt", "1");
      //   final data = prefs.getString("notifiyalrt");
      //   if (data != '1') {
      //     await prefs.setString("notifiyalrt", '0');
      //   }

      //  // _checkAndShowOfferDialog();
      //   // }
      // }

      final data = prefs.getString("notifiyalrt");

      if (data == '0') {
        Random random = Random();
        await Future.delayed(Duration(minutes: 1));
        final bookofferdata = await dataprovider.getofferbook();

        if (bookofferdata != null && bookofferdata.isNotEmpty) {
          if (mounted) {
            setState(() {
              randomNumber = random.nextInt(bookofferdata.length);
            });
          }
          await prefs.setString("notifiyalrt", '1');
          await Future.delayed(Duration.zero, () async {
            await SharPreferences.setString('OpenAd', '1');
            if (mounted) {
              return await showGiftDialog(context, bookofferdata[randomNumber]);
            }
          });
        }
      }
    }
  }

  void _showChatEntryPopover(BuildContext buttonContext) {
    showPopover(
      context: buttonContext,
      direction: PopoverDirection.right,
      transitionDuration: const Duration(milliseconds: 250),
      bodyBuilder: (context) {
        return Container(
          color: CommanColor.whiteLightModePrimary(context),
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Center(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Get.to(ChatScreen());
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 5),
                    child: Row(
                      children: [
                        Image.asset(
                          CommanColor.isDarkTheme(context)
                              ? "assets/dark_modes/new-dark_chat.png"
                              : "assets/Chat white.png",
                          height: 22,
                          width: 22,
                          color: CommanColor.darkModePrimaryWhite(context),
                        ),
                        const SizedBox(width: 17),
                        Text(
                          "Ask Anything",
                          style: CommanStyle.pw14500(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: CommanColor.darkModePrimaryWhite(context),
                  thickness: 1.2,
                ),
                GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Get.to(const PrayerGuidanceScreen());
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 5),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/dove.png",
                          height: 26,
                          width: 26,
                          color: CommanColor.darkModePrimaryWhite(context),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "Prayer Guidance",
                          style: CommanStyle.pw14500(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      width: 180,
      height: 100,
      arrowDyOffset: -20,
      barrierColor: Colors.transparent,
      backgroundColor:
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
                  ThemeMode.dark
              ? Colors.white
              : CommanColor.lightModePrimary,
      arrowWidth: 24,
    ).then((value) {
      if (mounted) {
        setState(() {
          isOpenChat = false;
        });
      }
    });
  }

//   authObserver(User? user) async {
//     if (user == null) {
//       if (isLoggedIn) {
//         if (mounted) {
//           setState(() {
//             isLoggedIn = false;
//           });
//         }
//       }
//     } else if (user.emailVerified) {
//       isLoggedIn = true;
//     } else {
//       isLoggedIn = true;
//     }
//   }

//   updateLoading(bool val, {String? mess}) {
//     if (val) {
//       EasyLoading.show(status: mess);
//     } else {
//       EasyLoading.dismiss();
//     }
//     setState(() {
//       message = mess;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadFontSize();
//     checkuserloggedin();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {

//       _checkAndShowVerse();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       appLaunchCount = prefs.getInt('launchCount') ?? 0;
//       // appLaunchCount++;

//       debugPrint(" lanuchCount is - $appLaunchCount ");
//       if (appLaunchCount == 2) {
//         // setState(() {
//         //   appLaunchCount = 3;
//         // });
//         debugPrint(" lanuchCount 2 is - $appLaunchCount ");
//         final data = prefs.getString("review") ?? "1";

//         if (data == '1') {
//           Future.delayed(
//             Duration(minutes: 1),
//             () async {
//               await prefs.setInt('launchCount', 3);
//               await prefs.setString('review', '2');
//               appLaunchCount = prefs.getInt('launchCount') ?? 0;
//               debugPrint("lanuchCount 3 is - $appLaunchCount");
//               return requestReview(result);
//             },
//           );
//         }
//       }
//     });

//     RewardedAdService.loadAd(onAdLoaded: () {
//       if (mounted) {
//         setState(() => isAdReady = true);
//       }
//     });

//   }

//   checkscreen() {
//     // First get the FlutterView.
//     FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

// // Dimensions in physical pixels (px)
//     Size size = view.physicalSize;
//     double width = size.width;
//     double height = size.height;

//     debugPrint("sz current width - $width ");
//   }

//   Future<void> requestReview(List<ConnectivityResult> connectionStatus) async {

//     if (connectionStatus.first == ConnectivityResult.wifi ||
//         connectionStatus.first == ConnectivityResult.mobile) {
//       if (await inAppReview.isAvailable()) {
//         await inAppReview.requestReview();
//       } else {
//         Constants.showToast("Service not available at the moment");
//       }
//     } else {
//       Constants.showToast("No internet connection");
//     }
//   }

//   void _checkAndShowVerse() async {
//     final prefs = await SharedPreferences.getInstance();

//     final lastShownDateRaw = prefs.getString('last_shown_verse_date');
//     final now = DateTime.now();
//     final todayString = DateFormat('yyyy-MM-dd').format(now);
//     debugPrint("test0");

//     String lastShownDateFormatted = '';
//     if (lastShownDateRaw != null) {
//       try {
//         final parsed = DateTime.parse(lastShownDateRaw);
//         lastShownDateFormatted = DateFormat('yyyy-MM-dd').format(parsed);
//       } catch (e) {
//         debugPrint('⚠️ Invalid lastShownDate format: $lastShownDateRaw');
//       }
//     }
//     await Future.delayed(Duration(seconds: 45));
//     // Check if we've shown a verse today
//     if (lastShownDateFormatted != todayString) {
//       // Wait for 3 minutes
//       debugPrint("test1");
//       Future.delayed(Duration(seconds: 1), () {
//         debugPrint("test2");
//         if (context.mounted) {
//           debugPrint("test3");

//           return _showDailyVerseBottomSheet(_fontSize);
//         }
//       });
//     }
//   }

//   _showDailyVerseBottomSheet(fontSize) async {
//     final downloadProvider =
//         Provider.of<DownloadProvider>(context, listen: false);

//     await downloadProvider.loadDailyVerses();

//     setState(() {
//       dailyVerseList = downloadProvider.dailyVerseList;
//     });

//     // OverlayEntry? overlayEntry;
//     final prefs = await SharedPreferences.getInstance();
//     if (dailyVerseList.isEmpty) return;
//     debugPrint("test4");
//     // Find today's verse
//     final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

//     bool isSameDay(DateTime a, DateTime b) {
//       return a.year == b.year && a.month == b.month && a.day == b.day;
//     }

//     final todayVerse = dailyVerseList.firstWhere(
//       (verse) =>
//           isSameDay(DateTime.parse(verse.date.toString()), DateTime.now()),
//       orElse: () => dailyVerseList.first,
//     );

//     debugPrint("test5");
//     // Random background image
//     final random = Random();
//     final bgImages = [
//       "assets/im1.jpg",
//       "assets/im2.jpg",
//       "assets/im3.jpg",
//       "assets/im4.jpg",
//       "assets/im5.jpg",
//     ];
//     String randomBgImage = bgImages[random.nextInt(bgImages.length)];
//     // Save today's date to prefs
//     await prefs.setString('last_shown_verse_date', todayString);
//     debugPrint("test6");
//     await Future.delayed(Duration(seconds: 1));
//     if (_isBottomSheetOpen) return;

//     _isBottomSheetOpen = true;
//     debugPrint("test7");

//     await showModalBottomSheet(
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       enableDrag: false,
//       builder: (context) {
//         double screenWidth = MediaQuery.of(context).size.width;
//         return StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//           return FractionallySizedBox(
//             heightFactor: screenWidth < 380
//                 ? 0.85
//                 : screenWidth > 450
//                     ? 0.79
//                     : 0.73,
//             child: GestureDetector(
//               onTap: () {
//                 setState(
//                   () {
//                     randomBgImage = bgImages[random.nextInt(bgImages.length)];
//                   },
//                 );
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
//                   // image: DecorationImage(
//                   //   image: AssetImage(randomBgImage),
//                   //   fit: BoxFit.cover,
//                   // ),
//                 ),
//                 padding: EdgeInsets.all(7),
//                 child: Stack(
//                   //  crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.all(screenWidth < 380 ? 3 : 8.0),
//                       child: RepaintBoundary(
//                         key: _verseContainerKey,
//                         child: Stack(
//                           children: [
//                             FramedVerseContainer(
//                               backgroundImagePath: randomBgImage,
//                               showFrame: Random()
//                                   .nextBool(), // or true/false based on your logic
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: Column(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceEvenly,
//                                   children: [
//                                     SizedBox(height: 9),
//                                     Align(
//                                       alignment: Alignment.center,
//                                       child: AutoSizeHtmlWidget(
//                                         html: todayVerse.verse.toString(),
//                                         maxLines: 16,
//                                         color: CommanColor.white,
//                                         maxFontSize: screenWidth < 380
//                                             ? BibleInfo.fontSizeScale * 14.9
//                                             : screenWidth > 450
//                                                 ? BibleInfo.fontSizeScale * 32
//                                                 : DashBoardController()
//                                                         .fontSize
//                                                         .value *
//                                                     1.2,
//                                         minFontSize:
//                                             screenWidth < 380 ? 11.5 : 10.9,
//                                       ),

//                                     ),
//                                     Padding(
//                                       padding: const EdgeInsets.only(top: 3.0),
//                                       child: Align(
//                                         alignment: Alignment.centerRight,
//                                         child: Text(
//                                           "${todayVerse.book} ${todayVerse.chapter}:${todayVerse.verseNum}",
//                                           style: TextStyle(
//                                             color: CommanColor.white,
//                                             fontStyle: FontStyle.italic,
//                                             fontSize: screenWidth < 380
//                                                 ? 14
//                                                 : screenWidth > 450
//                                                     ? BibleInfo.fontSizeScale *
//                                                         28
//                                                     : fontSize - 2,
//                                           ),
//                                         ),
//                                       ),
//                                     ),

//                                     // App attribution
//                                     Padding(
//                                       padding: const EdgeInsets.only(
//                                           top: 4, right: 6),
//                                       child: Align(
//                                         alignment: Alignment.bottomLeft,
//                                         child: Opacity(
//                                           opacity: 0.8,
//                                           child: Image.asset(
//                                             "assets/Icon-1024.png",
//                                             height: screenWidth < 380
//                                                 ? 24
//                                                 : screenWidth > 450
//                                                     ? 50
//                                                     : 30,
//                                             width: screenWidth < 380
//                                                 ? 24
//                                                 : screenWidth > 450
//                                                     ? 50
//                                                     : 30,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               top: 17,
//                               right: 10,
//                               left: 10,
//                               child: Text(
//                                 "Verse of the Day",
//                                 style: TextStyle(
//                                   color: CommanColor.white,
//                                   decoration: TextDecoration.underline,
//                                   decorationColor:
//                                       Colors.white, // Set your desired color
//                                   decorationThickness: 2.0,
//                                   fontSize: screenWidth < 380
//                                       ? 17
//                                       : screenWidth > 450
//                                           ? 31
//                                           : 19,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     SizedBox(
//                         height: screenWidth < 380
//                             ? 5
//                             : screenWidth > 450
//                                 ? 13
//                                 : 9),
//                     Positioned(
//                       bottom: 10,
//                       right: 5,
//                       left: 5,
//                       child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             GestureDetector(
//                               onTap: () async {
//                                 Provider.of<DownloadProvider>(context,
//                                         listen: false)
//                                     .incrementBookmarkCount(context);

//                                 // Capture the verse as an image
//                                 RenderRepaintBoundary boundary =
//                                     _verseContainerKey.currentContext
//                                             ?.findRenderObject()
//                                         as RenderRepaintBoundary;
//                                 ui.Image image =
//                                     await boundary.toImage(pixelRatio: 3.0);
//                                 ByteData? byteData = await image.toByteData(
//                                     format: ui.ImageByteFormat.png);
//                                 Uint8List pngBytes =
//                                     byteData!.buffer.asUint8List();
//                                 //  await saveAndShare(pngBytes, "", "");
//                                 final directory = await getTemporaryDirectory();
//                                 final image1 =
//                                     File("${directory.path}/dailyverse.png");
//                                 image1.writeAsBytesSync(pngBytes);
//                                 // Share the image using XFile
//                                 final xFile = XFile(image1.path);
//                                 //await Share.shareXFiles([xFile]);
//                                 await Share.shareXFiles([xFile],
//                                     subject: '${BibleInfo.bible_shortName} app',
//                                     text: "",
//                                     sharePositionOrigin: Rect.fromPoints(
//                                         const Offset(2, 2),
//                                         const Offset(3, 3)));
//                               },
//                               child: Container(
//                                 width: screenWidth < 380
//                                     ? 39
//                                     : screenWidth > 450
//                                         ? 67
//                                         : 45,
//                                 height: screenWidth < 380
//                                     ? 39
//                                     : screenWidth > 450
//                                         ? 67
//                                         : 45,
//                                 padding: EdgeInsets.all(1),
//                                 decoration: BoxDecoration(
//                                   color: CommanColor.darkPrimaryColor
//                                       .withValues(alpha: 0.7),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Center(
//                                   child: Image.asset(
//                                     "assets/icons/share34.png",
//                                     height: screenWidth < 380
//                                         ? 21
//                                         : screenWidth > 450
//                                             ? 40
//                                             : 25,
//                                     width: screenWidth < 380
//                                         ? 21
//                                         : screenWidth > 450
//                                             ? 40
//                                             : 25,
//                                   ),

//                                 ),

//                               ),
//                             ),

//                             // Amen Button
//                             ElevatedButton.icon(
//                               onPressed: () {

//                                 Constants.showToast("Amen!");
//                                 Navigator.of(context).pop();
//                               },
//                               icon: Image.asset(
//                                 "assets/icons/cross1.png",
//                                 height: screenWidth < 380
//                                     ? 19
//                                     : screenWidth > 450
//                                         ? 40
//                                         : 25,
//                                 width: screenWidth < 380
//                                     ? 19
//                                     : screenWidth > 450
//                                         ? 40
//                                         : 25,
//                               ),
//                               label: Text("AMEN",
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: screenWidth < 380
//                                           ? 14
//                                           : screenWidth > 450
//                                               ? 19
//                                               : null)),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: CommanColor.darkPrimaryColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 20,
//                                     vertical: screenWidth < 380
//                                         ? 6
//                                         : screenWidth > 450
//                                             ? 16
//                                             : 12),
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () async {
//                                 try {
//                                   // Show loading indicator
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Row(
//                                         children: [
//                                           CircularProgressIndicator(
//                                               color: Colors.white),
//                                           SizedBox(width: 10),
//                                           Text("Saving verse...",
//                                               style: TextStyle(
//                                                   color: Colors.white)),
//                                         ],
//                                       ),
//                                       backgroundColor: Colors.black87,
//                                       duration: Duration(seconds: 2),
//                                     ),
//                                   );

//                                   // Capture the verse as an image
//                                   RenderRepaintBoundary boundary =
//                                       _verseContainerKey.currentContext
//                                               ?.findRenderObject()
//                                           as RenderRepaintBoundary;
//                                   ui.Image image =
//                                       await boundary.toImage(pixelRatio: 3.0);
//                                   ByteData? byteData = await image.toByteData(
//                                       format: ui.ImageByteFormat.png);
//                                   Uint8List pngBytes =
//                                       byteData!.buffer.asUint8List();

//                                   await saveImageIntoLocal(pngBytes, context);
//                                   // Show success message
//                                   ScaffoldMessenger.of(context)
//                                       .hideCurrentSnackBar();
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         Platform.isAndroid
//                                             ? "Verse saved to Gallery"
//                                             : "Verse saved to Photos",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                       backgroundColor: Colors.green,
//                                       behavior: SnackBarBehavior.floating,
//                                       duration: Duration(seconds: 2),
//                                     ),
//                                   );
//                                 } catch (e) {
//                                   ScaffoldMessenger.of(context)
//                                       .hideCurrentSnackBar();
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                           "Failed to save: ${e.toString()}",
//                                           style:
//                                               TextStyle(color: Colors.white)),
//                                       backgroundColor: Colors.red,
//                                       behavior: SnackBarBehavior.floating,
//                                       duration: Duration(seconds: 2),
//                                     ),
//                                   );
//                                 }
//                               },
//                               child: Container(
//                                 width: screenWidth < 380
//                                     ? 39
//                                     : screenWidth > 450
//                                         ? 67
//                                         : 45,
//                                 height: screenWidth < 380
//                                     ? 39
//                                     : screenWidth > 450
//                                         ? 67
//                                         : 45,
//                                 padding: EdgeInsets.all(1),
//                                 decoration: BoxDecoration(
//                                   color: CommanColor.darkPrimaryColor
//                                       .withValues(alpha: 0.7),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Center(
//                                   child: Image.asset(
//                                     "assets/icons/download34.png",
//                                     height: screenWidth < 380
//                                         ? 21
//                                         : screenWidth > 450
//                                             ? 40
//                                             : 25,
//                                     width: screenWidth < 380
//                                         ? 21
//                                         : screenWidth > 450
//                                             ? 40
//                                             : 25,
//                                   ),

//                                 ),
//                               ),
//                             ),
//                           ]),
//                     ),
//                     SizedBox(
//                       height: 1,
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         });
//       },
//     );
  // _isBottomSheetOpen = false;
  // if (_isBottomSheetOpen == false) {

  //   await _checkAndShowOfferDialog();
  // }
//   }

  // Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _verseContainerKey = GlobalKey();

  // Value Notifiers
  final ValueNotifier<int> _rating = ValueNotifier<int>(0);
  final ValueNotifier<bool> _showFeedbackButton = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> lastInterstitialAdPlayed = ValueNotifier(null);
  final ValueNotifier<String> adsDuration = ValueNotifier('0');

  // Services
  final Connectivity _connectivity = Connectivity();
  final InAppReview inAppReview = InAppReview.instance;
  final AdService _adService = AdService();
  final AudioPlayer audioPlayer = AudioPlayer();
  final GlobalKey<floatingButtonState> _readerAudioFabKey =
      GlobalKey<floatingButtonState>();

  // State variables
  double _fontSize = 19.0;
  bool isAdReady = false;
  bool adsIcon = true;
  bool isLoggedIn = false;
  int swipeCount = 0;
  int _swipeThreshold = 7;
  int appLaunchCount = 0;
  int appLaunchCountoffer = 0;
  int clickCount = 0;
  Availability availability = Availability.loading;
  String? message;
  String? sixMonthPlan;
  String? oneYearPlan;
  String? lifeTimePlan;
  String? RewardAdExpireDate;
  String? selectedcolor;
  String? selectedBookname;

  // Lists
  List<DailyVerseList> dailyVerseList = [];
  List<DailyVerseList> filteredList = [];
  List<ConnectivityResult> result = [];

  // Flags
  bool _isBottomSheetOpen = false;
  bool _hasInitialized = false;
  final ValueNotifier<bool> _showUI = ValueNotifier<bool>(true);
  bool _readerAppBarPinnedVisible = true;
  bool _readerAppBarPendingHide = false;
  bool _readerAppBarUserScrollingDown = false;
  bool _readerAppBarScrollUpIntent = false;
  double _readerAppBarDragDelta = 0;
  static const double _kReaderAppBarToggleThreshold = 20.0;

  /// Re-show top bar after scrolling up about this many verses.
  static const double _kReaderAppBarShowVerseCount = 5.5;

  /// Scroll offset when the bar was hidden / deepest point while hidden.
  double _readerAppBarHiddenAnchorOffset = 0;
  List<VerseBookContentModel>? _lastContentSource;
  BuildContext? _bottomSheetContext; // Track bottom sheet context to dismiss it
  bool _exitOfferCooldownActive =
      false; // Red dot indicator (show after 3 days)
  Timer?
      _exitOfferCooldownRefreshTimer; // Refresh so red dot dismisses after 10 mins
  // dailyverse
  static const int _targetSeconds =
      15; // Show after 15 seconds on Reading screen (allows app-open ad to show and dismiss first)
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _checkerTimer;
  bool _verseShown = false;
  bool _readingScreenWasHidden = false;
  bool _feedbackPendingAtSessionStart = false;
  bool _deferUpgradeAfterStreakRating = false;
  bool _streakRatingSawLifecyclePause = false;
  Timer? _deferUpgradeAfterStreakRatingFallbackTimer;
  int _ratingUiDialogDepth = 0;
  static const Duration _kUpgradeAfterStreakRatingDelay =
      Duration(milliseconds: 300);
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    // Track Home Screen event
    AnalyticsService.trackHomeScreen();
  }

  void _precacheBackupDialogAssets() {
    // Backup dialog is opened from the drawer and can feel slow on low-end devices
    // because several PNG assets are decoded on first open. Precache them after
    // the first frame so the dialog shows instantly when tapped.
    if (!mounted) return;
    const assets = <String>[
      'assets/export_backup/refresh.png',
      'assets/export_backup/lock.png',
      'assets/export_backup/encryption.png',
      'assets/export_backup/encryption-sign.png',
      'assets/export_backup/download.png',
      'assets/export_backup/upload.png',
    ];
    for (final asset in assets) {
      try {
        precacheImage(AssetImage(asset), context);
      } catch (_) {}
    }
  }

  Future<void> _initializeApp() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    await _loadFontSize();
    // Exit offer / red dot commented out
    // await _refreshExitOfferCooldown();
    // _exitOfferCooldownRefreshTimer?.cancel();
    // _exitOfferCooldownRefreshTimer = Timer.periodic(
    //     const Duration(minutes: 1), (_) => _refreshExitOfferCooldown());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      unawaited(downloadProvider.preloadBibleDataFromDatabaseIfNeeded());
      _precacheBackupDialogAssets();
      _runDeferredHomeStartupTasks();
    });

    // _initializeAds();
    loadAds();
  }

  Future<void> _runDeferredHomeStartupTasks() async {
    final pendingCelebration = await SharPreferences.getInt(
        SharPreferences.pendingStreakCompleteCelebration);
    final hasShownLeaveRating = await SharPreferences.getBoolean(
            SharPreferences.hasShownLeaveRatingScreen) ??
        false;
    if (pendingCelebration == 1 && !hasShownLeaveRating) {
      await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
      _deferUpgradeAfterStreakRating = true;
      _streakRatingSawLifecyclePause = false;
    }

    final startupPrefs = await SharedPreferences.getInstance();
    _feedbackPendingAtSessionStart =
        (startupPrefs.getBool(SharPreferences.mainFeedbackPending) ?? false) &&
            (startupPrefs
                    .getBool(SharPreferences.mainFeedbackFromVerseActions) ??
                false);

    await Future.wait([
      _handleAppLaunchCount(),
      checkUserLoggedIn(),
    ]);
    if (!mounted) return;

      await _checkAndShowDailyWelcomeToast();
    if (!mounted) return;

    await Future.wait([
      _handlePendingNotificationAction(),
      _showStreakCompleteCelebrationIfNeeded(),
      DailySlotNotificationHelper.rescheduleEnabledSlots(),
    ]);
    if (!mounted) return;

      SmartNotificationHelper.recordAppOpen();
      SmartNotificationHelper.scheduleSmartNotificationIfNeeded();
      if (mounted) {
        final downloadProvider =
            Provider.of<DownloadProvider>(context, listen: false);
        await updateAllLauncherWidgets(
          dailyVerses: downloadProvider.dailyVerseList,
        );
      }
    if (!mounted) return;

      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (!mounted) return;
      _navigateForWidgetRoute(getBibleWidgetRouteFromUri(initialUri));
      if (!mounted) return;
    _widgetClickSubscription ??= HomeWidget.widgetClicked.listen((uri) {
        if (!mounted) return;
        _navigateForWidgetRoute(getBibleWidgetRouteFromUri(uri));
      });
  }

  Future<void> _showStreakCompleteCelebrationIfNeeded() async {
    // First-streak Apple rating is shown on LeaveRatingScreen after Continue
    // on StreakCompletedScreen. Home only clears a leftover pending flag (e.g.
    // if the user left before the rating flow finished).
    // Day-2+: Home shows a short loader + interstitial (not App Open).
    final count = await SharPreferences.getInt(
        SharPreferences.pendingStreakCompleteCelebration);
    if (count == null || count < 1 || !mounted) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShown = await SharPreferences.getString(
        SharPreferences.streakCelebrationShownDate);
    if (lastShown == today) {
      await SharPreferences.setInt(
          SharPreferences.pendingStreakCompleteCelebration, 0);
      return;
    }
    // Fallback only: rating was not shown on Streak Completed screen.
    await SharPreferences.setString(
        SharPreferences.streakCelebrationShownDate, today);
    final hasShownLeaveRating = await SharPreferences.getBoolean(
            SharPreferences.hasShownLeaveRatingScreen) ??
        false;
    // Day-1 review only once ever (same rule as LeaveRatingScreen).
    if (count == 1 && !hasShownLeaveRating) {
      await SharPreferences.setBoolean(
          SharPreferences.hasShownLeaveRatingScreen, true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('showopenad', 'false');
      await SharPreferences.setString('OpenAd', '1');
      await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
      _deferUpgradeAfterStreakRating = true;
      _streakRatingSawLifecyclePause = false;
      _deferUpgradeAfterStreakRatingFallbackTimer?.cancel();

      final isAvailable = await inAppReview.isAvailable();
      if (isAvailable) {
        try {
          await inAppReview.requestReview();
        } catch (e, st) {
          debugPrint('Streak day-1 review request failed: $e,$st');
        }
        _deferUpgradeAfterStreakRatingFallbackTimer = Timer(
          const Duration(seconds: 5),
          () {
            if (mounted) {
              unawaited(_clearDeferUpgradeAfterStreakRating());
            }
          },
        );
      } else {
        await _clearDeferUpgradeAfterStreakRating();
      }
    } else if (count > 1) {
      // Day-2+ Continue → Home: loader + interstitial only (no App Open).
      await _showPostStreakInterstitialIfNeeded();
    }
    await SharPreferences.setInt(
        SharPreferences.pendingStreakCompleteCelebration, 0);
  }

  /// Additive: after Day-2+ streak Continue, show interstitial once on Home.
  /// Does not change Mark-as-Read / Amen / swipe interstitial call sites.
  Future<void> _showPostStreakInterstitialIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('showopenad', 'false');
      await SharPreferences.setString('OpenAd', '1');

      final shouldLoad = await SharPreferences.shouldLoadAd();
      if (!shouldLoad || !mounted) return;

      // Wait for a preloaded/in-flight interstitial silently.
      // Do not show "Please wait..." unless an ad is actually ready to show.
      for (var i = 0; i < 15; i++) {
        if (_adService.interstitialAd != null) break;
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }

      if (!mounted) return;
      if (_adService.interstitialAd == null) {
        // No ad available — skip loader and proceed with no interstitial.
        return;
      }

      EasyLoading.showInfo('Please wait...');
      try {
        await _showInterstitialAdAndWait();
      } catch (e) {
        debugPrint('Post-streak interstitial error: $e');
      } finally {
        await EasyLoading.dismiss();
        // Reload for later in-session uses (swipe / Amen, etc.).
        if (mounted) {
          final shouldReload = await SharPreferences.shouldLoadAd();
          if (shouldReload) {
            _adService.loadInterstitialAd(() {
              if (mounted) setState(() {});
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Post-streak interstitial setup error: $e');
      try {
        await EasyLoading.dismiss();
      } catch (_) {}
    }
  }

  Future<void> _clearDeferUpgradeAfterStreakRating() async {
    if (!_deferUpgradeAfterStreakRating) return;
    _deferUpgradeAfterStreakRating = false;
    _streakRatingSawLifecyclePause = false;
    _deferUpgradeAfterStreakRatingFallbackTimer?.cancel();
    _deferUpgradeAfterStreakRatingFallbackTimer = null;
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false);
  }

  Future<void> _markRatingUiOpening() async {
    _ratingUiDialogDepth++;
    if (_ratingUiDialogDepth == 1) {
      await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    }
  }

  Future<void> _markRatingUiClosed() async {
    if (_ratingUiDialogDepth <= 0) return;
    _ratingUiDialogDepth--;
    if (_ratingUiDialogDepth == 0 && !_deferUpgradeAfterStreakRating) {
      await SharPreferences.setBoolean(
          SharPreferences.deferUpgradeAlert, false);
    }
  }

  void _scheduleClearDeferAfterStreakRatingDismiss() {
    if (!_deferUpgradeAfterStreakRating) return;
    _deferUpgradeAfterStreakRatingFallbackTimer?.cancel();
    _deferUpgradeAfterStreakRatingFallbackTimer = Timer(
      _kUpgradeAfterStreakRatingDelay,
      () {
        if (mounted) {
          unawaited(_clearDeferUpgradeAfterStreakRating());
        }
      },
    );
  }

  Future<void> _handlePendingNotificationAction() async {
    final action = await SharPreferences.getString(
        SharPreferences.pendingNotificationAction);
    if (action == null || action.isEmpty || !mounted) return;
    await SharPreferences.setString(
        SharPreferences.pendingNotificationAction, '');
    if (!mounted) return;
    switch (action) {
      case 'open_streak':
        Get.to(() => const StreakConnectionScreen());
        break;
      case 'open_faith_journey':
        Get.to(() => const DailyJourneyScreen());
        break;
      case 'open_reading':
        // Already on Home
        break;
      case 'open_chat':
        Get.to(() => const ChatScreen());
        break;
      case 'open_verse':
        await _showDailyVerseBottomSheet(_fontSize, fromNotification: true);
        break;
      case 'open_images':
        Get.to(() => const DailyVerse(fromWidget: true));
        break;
      case 'open_premium':
        if (mounted) SubscriptionScreen.navigateToPaywallFromHome(context);
        break;
      case 'open_quiz':
        // Stay on Home; quiz screen can be added later
        break;
      default:
        break;
    }
  }

  void _navigateForWidgetRoute(BibleWidgetRoute route) {
    if (route == BibleWidgetRoute.none) return;
    if (route == BibleWidgetRoute.verse) {
      Get.to(() => const DailyVerse(fromWidget: true));
    } else if (route == BibleWidgetRoute.prayer) {
      Get.to(() => const PrayerGuidanceScreen());
    } else if (route == BibleWidgetRoute.chat) {
      Get.to(() => const ChatScreen());
    } else if (route == BibleWidgetRoute.streak) {
      // Live Activity / streak widget tap → Faith Journey (same as drawer).
      // Clear native queued action so cold-start does not open this twice.
      unawaited(SharPreferences.setString(
          SharPreferences.pendingNotificationAction, ''));
      Get.to(() => const DailyJourneyScreen());
    }
  }

  // Exit offer red dot: commented out
  // Future<void> _refreshExitOfferCooldown() async {
  //   bool show = false;
  //   final firstSeenStr =
  //       await SharPreferences.getString('paywall_first_seen_date');
  //   final exitOfferShownTime =
  //       await SharPreferences.getString('exit_offer_first_shown_time');
  //   final now = DateTime.now();
  //   try {
  //     if (firstSeenStr == null || firstSeenStr.isEmpty) return;
  //     final firstSeen = DateTime.parse(firstSeenStr);
  //     if (now.difference(firstSeen).inDays < 3) {
  //       if (mounted) setState(() => _exitOfferCooldownActive = false);
  //       return;
  //     }
  //     if (exitOfferShownTime == null || exitOfferShownTime.isEmpty) {
  //       show = true;
  //     } else {
  //       final shownAt = DateTime.parse(exitOfferShownTime);
  //       final minsSince = now.difference(shownAt).inMinutes;
  //       final daysSince = now.difference(shownAt).inDays;
  //       if (daysSince >= 20)
  //         show = true;
  //       else if (minsSince < 10) show = true;
  //     }
  //   } catch (_) {}
  //   if (mounted) setState(() => _exitOfferCooldownActive = show);
  // }

  /// Truncate only long book names (e.g. Song of Solomon); short names stay full.
  static const int _kAppBarBookNameMaxChars = 14;

  String _formatAppBarBookName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= _kAppBarBookNameMaxChars) return trimmed;
    return '${trimmed.substring(0, _kAppBarBookNameMaxChars - 1)}…';
  }

  Widget _buildAppBarBookTitleSelector({
    required BuildContext context,
    required DashBoardController controller,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    final controllerBook = controller.selectedBook.value.toString().trim();
    final effectiveBookName = controllerBook.isNotEmpty
        ? controllerBook
        : (selectedBookname?.toString().trim() ?? '');
    final displayBookName = _formatAppBarBookName(
      effectiveBookName,
    );
    final arrowSize = screenWidth > 450 ? 39.0 : 24.0;

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              displayBookName,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CommanStyle.appBarStyle(context).copyWith(
                fontSize: screenWidth > 450
                    ? BibleInfo.fontSizeScale * 26
                    : BibleInfo.fontSizeScale * 18,
                height: 1.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: CommanColor.whiteBlack(context),
              size: arrowSize,
            ),
          ),
        ],
      ),
    );
  }

  /// Launch-count bookkeeping only; feeling dialog is 20-click verse actions only.
  Future<void> _handleAppLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    appLaunchCount = prefs.getInt('launchCount') ?? 0;

    debugPrint("launchCount is - $appLaunchCount");

    if (appLaunchCount != 2) return;

      final data = prefs.getString("review") ?? "1";
    if (data != '1' || !mounted) return;

            await prefs.setInt('launchCount', 3);
            await prefs.setString('review', '2');
            appLaunchCount = prefs.getInt('launchCount') ?? 0;
            debugPrint("launchCount 3 is - $appLaunchCount");
  }

  Future<void> _checkAndShowDailyWelcomeToast() async {
    if (!mounted) return;

    // Lifetime once only — first time user completes streak and lands on Reading.
    final firstTimeShown = await SharPreferences.getBoolean(
            SharPreferences.dailyWelcomeFirstTimeShown) ??
        false;
    if (firstTimeShown) return;

    // Continue My Journey opens Home with From "splash" after streak completion.
    if (widget.From != "splash") return;

    final streakCompletedDate = await SharPreferences.getString(
        SharPreferences.streakFlowLastShownDate);
    if (streakCompletedDate == null || streakCompletedDate.isEmpty) return;

        await SharPreferences.setBoolean(
            SharPreferences.dailyWelcomeFirstTimeShown, true);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
        Constants.showToast(
            "Welcome You. God's Word is always with you.", 3000);
        }
      });
  }

  Future<void> _showRotatingVerseAmenMessage() async {
    // Rotating Verse of the Day Amen messages
    final amenMessages = [
      "Let this verse stay with you today.",
      "Carry this word into your day.",
    ];

    // Get current message index
    final messageIndex = await SharPreferences.getInt(
            SharPreferences.verseOfDayAmenMessageIndex) ??
        0;

    // Get the message for this tap
    final message = amenMessages[messageIndex % amenMessages.length];

    // Show toast
    Constants.showToast(message, 3000);

    // Rotate to next message index for next tap
    final nextIndex = (messageIndex + 1) % amenMessages.length;
    await SharPreferences.setInt(
        SharPreferences.verseOfDayAmenMessageIndex, nextIndex);
  }

  // void _initializeAds() {
  //   RewardedAdService.loadAd(onAdLoaded: () {
  //     if (mounted) setState(() => isAdReady = true);
  //   });
  // }

  // Rating methods
  void _setRating(int rating) {
    _rating.value = rating;
    _showFeedbackButton.value = rating >= 4;
  }

  // Ad methods
  Future<void> loadAds() async {
    if (!mounted) return;

    final shouldLoadAd = await SharPreferences.shouldLoadAd();
    if (shouldLoadAd) {
      debugPrint("ad is called");
      _adService.loadBannerAd(() {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> loadInterstitialAd(DashBoardController controller) async {
    if (!mounted || controller.adFree.value) return;

    final currentDate = DateTime.now();
    final duration = int.tryParse(adsDuration.value) ?? 0;

    bool shouldShowAd = false;

    if (lastInterstitialAdPlayed.value == null) {
      shouldShowAd = controller.isInterstitialAdLoad.value;
    } else {
      if (duration != 0) {
        final diff =
            currentDate.difference(lastInterstitialAdPlayed.value!).inMinutes;
        shouldShowAd =
            (diff > duration) && controller.isInterstitialAdLoad.value;
      } else {
        shouldShowAd = controller.isInterstitialAdLoad.value;
      }
    }

    if (shouldShowAd) {
      try {
        await controller.interstitialAd?.show();
        DebugConsole.log(" interstitialAd 2 is running ");
        lastInterstitialAdPlayed.value = DateTime.now();
      } catch (e) {
        debugPrint('Error Loading Interstitial Ad: $e');
      }
    }
  }

  void _handleReward() async {
    await SharPreferences.setBoolean("downloadreward", true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('You earned a reward! Now you can download')),
    );
  }

  // Check if 3 minutes have passed since last "Mark as Read" ad
  Future<bool> _canShowMarkAsReadAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAdTimeString = prefs.getString('last_mark_as_read_ad_time');

    if (lastAdTimeString == null) {
      // First time showing ad, allow it
      return true;
    }

    try {
      final lastAdTime = DateTime.parse(lastAdTimeString);
      final now = DateTime.now();
      final diffInMinutes = now.difference(lastAdTime).inMinutes;

      // Show ad only if 3 minutes have passed
      return diffInMinutes >= 3;
    } catch (e) {
      debugPrint('Error parsing last ad time: $e');
      // If error, allow showing ad
      return true;
    }
  }

  // Save the time when "Mark as Read" ad was shown
  Future<void> _saveMarkAsReadAdTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'last_mark_as_read_ad_time', DateTime.now().toIso8601String());
  }

  // Helper method to show interstitial ad and wait for dismissal (for good internet)
  // This ensures ad shows FIRST, then content shows AFTER ad is dismissed
  Future<void> _showInterstitialAdAndWait() async {
    final completer = Completer<void>();

    // Check if ad is available
    final ad = _adService.interstitialAd;
    if (ad == null) {
      completer.complete(); // No ad available, proceed immediately
      return completer.future;
    }

    // Set up callback to complete when ad is dismissed
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        await SharPreferences.setString('OpenAd', '1');
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(); // Ad dismissed, proceed with content
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(); // Ad failed, proceed with content
        }
      },
      onAdShowedFullScreenContent: (ad) async {
        await SharPreferences.setString('OpenAd', '1');
      },
    );

    // Show the ad
    ad.show();

    // Wait for ad to be dismissed or fail (with timeout to prevent infinite wait)
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(); // Timeout - proceed anyway
        }
      },
    );
  }

  /// Additive Mark-as-Read only: pause audio for the ad, then resume.
  /// Leaves existing [_showInterstitialAdAndWait] logic unchanged.
  Future<void> _showMarkAsReadAdPausingAudio() async {
    final fab = _readerAudioFabKey.currentState;
    await fab?.pausePlaybackForAd();
    try {
      await _showInterstitialAdAndWait();
    } finally {
      await fab?.resumePlaybackAfterAd();
    }
  }

  // Future<void> _handleAdDismissed() async {
  //   if (mounted) setState(() => isAdReady = false);

  //   await SharPreferences.setString('OpenAd', '1');
  //   RewardedAdService.loadAd(onAdLoaded: () {
  //     if (mounted) setState(() => isAdReady = true);
  //   });
  // }

  // User and preferences methods
  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(SharPreferences.selectedFontSize);
    var data = await SharPreferences.getString(
          SharPreferences.selectedBook,
        ) ??
        "";

    // If book name is empty (first time), load default book from database
    if (data.isEmpty) {
      try {
        final db = await DBHelper().db;
        if (db != null) {
          final result = await db.rawQuery(
            "SELECT * FROM book WHERE book_num = ?",
            [int.parse("0")],
          );

          if (result.isNotEmpty && result[0]["title"] != null) {
            final title = result[0]["title"].toString();
            data = title;
            // Save to SharedPreferences for future use
            await SharPreferences.setString(
              SharPreferences.selectedBook,
              title,
            );
          }
        }
      } catch (e) {
        debugPrint('Error loading default book name: $e');
      }
    }

    if (mounted) {
      setState(() {
        selectedBookname = data;
        _fontSize = (value != null
            ? double.tryParse(value)
            : Sizecf.scrnWidth! > 450
                ? 25.0
                : 19.0)!;
      });
    }
  }

  Future<void> checkUserLoggedIn() async {
    final adProvider = DownloadProvider();
    await adProvider.init();

    result = await _connectivity.checkConnectivity();
    await checkingappcount(result);

    final dataCount =
        await SharPreferences.getString(SharPreferences.showinterstitialrow);

    _swipeThreshold = int.parse(dataCount ?? "7");
    final shouldLoadAd = await SharPreferences.shouldLoadAd();

    debugPrint("ad count is $_swipeThreshold $shouldLoadAd");

    if (shouldLoadAd) {
      _adService.loadInterstitialAd(() {
        if (mounted) setState(() {});
      });
    }
  }

  // Daily Verse methods
  Future<void> _checkAndShowVerse() async {
    // Only show verse on Reader screen (From == "Read")
    if (widget.From.toString() != "Read") {
      return;
    }

    // Additional check: ensure this route is actually current
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    if (_isBottomSheetOpen) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShownDateRaw = prefs.getString('last_shown_verse_date');
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);

    String lastShownDateFormatted = '';
    if (lastShownDateRaw != null) {
      try {
        final parsed = DateTime.parse(lastShownDateRaw);
        lastShownDateFormatted = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        debugPrint('⚠️ Invalid lastShownDate format: $lastShownDateRaw');
      }
    }

    // Only show if we haven't shown a verse today
    if (lastShownDateFormatted != todayString) {
      // Additional delay to ensure app-open ad has been dismissed
      await Future.delayed(const Duration(seconds: 2));

      // Double-check we're still on Reader screen before showing
      if (mounted && widget.From.toString() == "Read") {
        await _showDailyVerseBottomSheet(_fontSize);
      }
    }
  }

  Future<void> _showDailyVerseBottomSheet(double fontSize,
      {bool fromNotification = false}) async {
    if (_isBottomSheetOpen) return;

    // Verify we're still on Reader screen before showing (unless opened from notification tap)
    if (!fromNotification && widget.From.toString() != "Read") {
      return;
    }

    _isBottomSheetOpen = true;

    try {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      await downloadProvider.loadDailyVerses();

      if (mounted) {
        setState(() {
          dailyVerseList = downloadProvider.dailyVerseList;
        });
      }

      if (dailyVerseList.isEmpty) {
        _isBottomSheetOpen = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Find today's verse
      bool isSameDay(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      final todayVerse = dailyVerseList.firstWhere(
        (verse) =>
            isSameDay(DateTime.parse(verse.date.toString()), DateTime.now()),
        orElse: () => dailyVerseList.first,
      );

      // Random background image
      final random = Random();
      final bgImages = [
        "assets/im1.jpg",
        "assets/im2.jpg",
        "assets/im3.jpg",
        "assets/im4.jpg",
        "assets/im5.jpg",
      ];
      String randomBgImage = bgImages[random.nextInt(bgImages.length)];

      // Save today's date to prefs
      await prefs.setString('last_shown_verse_date', todayString);

      if (!mounted) {
        _isBottomSheetOpen = false;
        return;
      }

      // Final check: ensure we're still on Reader screen and route is current before showing (unless from notification)
      if (!fromNotification && widget.From.toString() != "Read") {
        _isBottomSheetOpen = false;
        return;
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        _isBottomSheetOpen = false;
        return;
      }

      await showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        enableDrag: false,
        builder: (context) {
          _bottomSheetContext = context;
          return _buildVerseBottomSheet(
              context, randomBgImage, todayVerse, fontSize);
        },
      ).then((_) {
        // Clear context when bottom sheet is dismissed
        _bottomSheetContext = null;
      });

      // if (!_isBottomSheetOpen) {
      //   await _checkAndShowOfferDialog();
      // }
    } finally {
      _isBottomSheetOpen = false;
      // _isBottomSheetOpen = false;
      if (_isBottomSheetOpen == false) {
        await _checkAndShowOfferDialog();
      }
    }
  }

  Widget _buildVerseBottomSheet(BuildContext context, String randomBgImage,
      DailyVerseList todayVerse, double fontSize) {
    double screenWidth = MediaQuery.of(context).size.width;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return FractionallySizedBox(
          heightFactor: screenWidth < 380
              ? 0.85
              : screenWidth > 450
                  ? 0.79
                  : 0.73,
          child: GestureDetector(
            onTap: () {
              setState(() {
                randomBgImage = randomBgImage;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              padding: EdgeInsets.all(7),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(screenWidth < 380 ? 3 : 8.0),
                    child: RepaintBoundary(
                      key: _verseContainerKey,
                      child: Stack(
                        children: [
                          FramedVerseContainer(
                            backgroundImagePath: 'assets/verse_image_bg.png',
                            showFrame: false,
                            useBackgroundImage: true,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(height: 9),
                                  Align(
                                    alignment: Alignment.center,
                                    child: AutoSizeHtmlWidget(
                                      html: todayVerse.verse.toString(),
                                      maxLines: 16,
                                      color: const Color(0xFF3E2723),
                                      maxFontSize: screenWidth < 380
                                          ? BibleInfo.fontSizeScale * 22
                                          : screenWidth > 450
                                              ? BibleInfo.fontSizeScale * 36
                                              : BibleInfo.fontSizeScale * 28,
                                      minFontSize: screenWidth < 380 ? 16 : 18,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "- ${todayVerse.book} ${dailyVerseUiChapter(todayVerse.chapter)}:${dailyVerseUiVerse(todayVerse.verseNum)}",
                                        style: TextStyle(
                                          color: const Color(0xFF3E2723),
                                          fontStyle: FontStyle.italic,
                                          fontSize: screenWidth < 380
                                              ? 16
                                              : screenWidth > 450
                                                  ? BibleInfo.fontSizeScale * 22
                                                  : 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 17,
                            right: 10,
                            left: 10,
                            child: Text(
                              "Verse of the Day",
                              style: TextStyle(
                                color: const Color(0xFF3E2723),
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth < 380
                                    ? 20
                                    : screenWidth > 450
                                        ? 28
                                        : 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: 0.52,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                      Images.appIcon1024,
                                      height: 22,
                                      width: 22,
                                  ),
                                    const SizedBox(width: 8),
                                  Text(
                                    BibleInfo.bible_shortName,
                                    style: TextStyle(
                                      color: const Color(0xFF3E2723),
                                        letterSpacing: BibleInfo.letterSpacing,
                                        fontSize: BibleInfo.fontSizeScale * 12,
                                        fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                      height: screenWidth < 380
                          ? 5
                          : screenWidth > 450
                              ? 13
                              : 9),
                  Positioned(
                    bottom: 10,
                    right: 5,
                    left: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShareButton(screenWidth, todayVerse),
                        _buildAmenButton(screenWidth),
                        _buildSaveButton(screenWidth, todayVerse),
                      ],
                    ),
                  ),
                  SizedBox(height: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(double screenWidth, DailyVerseList todayVerse) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => ShareAlertBox(
            verseTitle:
                " ${todayVerse.book} ${dailyVerseUiChapter(todayVerse.chapter)}:${dailyVerseUiVerse(todayVerse.verseNum)}",
            onShareAsText: () async {
              Navigator.of(context).pop();
              final appPackageName =
                  (await PackageInfo.fromPlatform()).packageName;
              String message = '';
              String appid = BibleInfo.apple_AppId;
              if (Platform.isAndroid) {
                message =
                    "${parse(todayVerse.verse.toString()).body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
              } else if (Platform.isIOS) {
                message =
                    '${parse(todayVerse.verse.toString()).body?.text ?? ''}.\n ${todayVerse.book} ${dailyVerseUiChapter(todayVerse.chapter)}:${dailyVerseUiVerse(todayVerse.verseNum)} \n You can read more at:\nhttps://itunes.apple.com/app/id$appid';
              }

              if (message.isNotEmpty) {
                Share.share(message,
                    sharePositionOrigin: Rect.fromPoints(
                        const Offset(2, 2), const Offset(3, 3)));
              } else {
                debugPrint('Message is empty or undefined');
              }
            },
            onShareAsImage: () async {
              Navigator.of(context).pop();
              // Share the same displayed image using RepaintBoundary
              await _shareVerse(todayVerse);
            },
          ),
        );
      },
      child: Container(
        width: screenWidth < 380
            ? 39
            : screenWidth > 450
                ? 67
                : 45,
        height: screenWidth < 380
            ? 39
            : screenWidth > 450
                ? 67
                : 45,
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: CommanColor.darkPrimaryColor.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            "assets/icons/share34.png",
            height: screenWidth < 380
                ? 21
                : screenWidth > 450
                    ? 40
                    : 25,
            width: screenWidth < 380
                ? 21
                : screenWidth > 450
                    ? 40
                    : 25,
          ),
        ),
      ),
    );
  }

  Widget _buildAmenButton(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF763201),
            Color(0xFFD5821F),
            Color(0xFF763201),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          // Check if user is subscribed
          final downloadProvider =
              Provider.of<DownloadProvider>(context, listen: false);
          final subscriptionPlan = await downloadProvider.getSubscriptionPlan();
          final isSubscribed = subscriptionPlan != null &&
              subscriptionPlan.isNotEmpty &&
              ['platinum', 'gold', 'silver']
                  .contains(subscriptionPlan.toLowerCase());

          // Show interstitial ad only for non-subscribed users and when online with good internet
          if (!isSubscribed) {
            // Check internet connectivity - if offline or low internet (2G), skip ad and proceed
            try {
              final hasInternet = await InternetConnection().hasInternetAccess;
              if (hasInternet) {
                // Check connection type - if mobile only (likely 2G/slow), skip ad
                final connectivityResult =
                    await Connectivity().checkConnectivity();
                final isMobileOnly = connectivityResult
                        .contains(ConnectivityResult.mobile) &&
                    !connectivityResult.contains(ConnectivityResult.wifi) &&
                    !connectivityResult.contains(ConnectivityResult.ethernet);

                // Only show ad if online with wifi/ethernet (not mobile only/2G)
                if (!isMobileOnly) {
                  // Show ad FIRST, wait for dismissal, THEN show content
                  try {
                    await _showInterstitialAdAndWait();
                  } catch (e) {
                    debugPrint('Error showing ad in Amen: $e');
                    // If ad fails, proceed anyway
                  }
                }
                // If mobile only (2G), skip ad and proceed
              }
              // If offline, skip ad and proceed
            } catch (e) {
              // If connectivity check fails, skip ad and proceed
              debugPrint('Connectivity check error in Amen: $e');
            }
          }

          // Proceed with action after ad (if shown) or immediately (if skipped)
          await _showRotatingVerseAmenMessage();

          // Add a small delay after ad dismissal to ensure UI is ready before closing
          // This prevents white screen issue when ad is dismissed
          await Future.delayed(const Duration(milliseconds: 500));

          // Check if bottom sheet is still open and context is valid
          if (!_isBottomSheetOpen) {
            return; // Bottom sheet already closed
          }

          // Check if context is still valid before closing bottom sheet
          if (mounted) {
            // Try using the stored bottom sheet context first (more reliable)
            if (_bottomSheetContext != null) {
              try {
                final route = ModalRoute.of(_bottomSheetContext!);
                if (route != null && route.isCurrent) {
                  Navigator.of(_bottomSheetContext!).pop();
                  _bottomSheetContext = null;
                  _isBottomSheetOpen = false;
                  return;
                }
              } catch (e) {
                debugPrint(
                    'Error closing bottom sheet with stored context: $e');
                _bottomSheetContext = null;
              }
            }

            // Fallback: try using the current context
            if (context.mounted) {
              final route = ModalRoute.of(context);
              if (route != null && route.isCurrent) {
                try {
                  Navigator.of(context).pop();
                  _isBottomSheetOpen = false;
                } catch (e) {
                  debugPrint('Error closing bottom sheet after Amen: $e');
                  _isBottomSheetOpen = false;
                }
              }
            }
          }
        },
        icon: Image.asset(
          "assets/icons/cross1.png",
          height: screenWidth < 380
              ? 19
              : screenWidth > 450
                  ? 40
                  : 25,
          width: screenWidth < 380
              ? 19
              : screenWidth > 450
                  ? 40
                  : 25,
        ),
        label: Text("AMEN",
            style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth < 380
                    ? 14
                    : screenWidth > 450
                        ? 19
                        : null)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: screenWidth < 380
                  ? 6
                  : screenWidth > 450
                      ? 16
                      : 12),
        ),
      ),
    );
  }

  Widget _buildSaveButton(double screenWidth, DailyVerseList todayVerse) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop(); // Close the bottom sheet first
        await SharPreferences.setString(
            SharPreferences.selectedBook, todayVerse.book.toString());
        await SharPreferences.setString(SharPreferences.selectedChapter,
            "${dailyVerseUiChapter(todayVerse.chapter)}");
        await SharPreferences.setString(SharPreferences.selectedBookNum,
            "${dailyVerseBookNum(todayVerse.bookId)}");
        Get.offAll(
          () => HomeScreen(
            From: "Daily",
            selectedBookForRead: dailyVerseBookNum(todayVerse.bookId),
            selectedChapterForRead: dailyVerseUiChapter(todayVerse.chapter),
            selectedVerseNumForRead: int.parse(todayVerse.verseNum.toString()),
            selectedBookNameForRead: todayVerse.book.toString(),
            selectedVerseForRead:
                parse(todayVerse.verse.toString()).body?.text.toString() ?? '',
          ),
          transition: Transition.cupertino,
          duration: const Duration(milliseconds: 350),
        );
      },
      child: Container(
        width: screenWidth < 380
            ? 39
            : screenWidth > 450
                ? 67
                : 45,
        height: screenWidth < 380
            ? 39
            : screenWidth > 450
                ? 67
                : 45,
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: CommanColor.darkPrimaryColor.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.menu_book,
            color: Colors.white,
            size: screenWidth < 380
                ? 21
                : screenWidth > 450
                    ? 40
                    : 25,
          ),
        ),
      ),
    );
  }

  Future<void> _shareVerse(DailyVerseList verse) async {
    try {
      final boundary = _verseContainerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imageFile = File("${directory.path}/dailyverse.png");
      await imageFile.writeAsBytes(pngBytes);

      final xFile = XFile(
        imageFile.path,
        mimeType: 'image/png',
        name: 'Daily Verse.png',
      );
      await Share.shareXFiles(
        [xFile],
          sharePositionOrigin:
            Rect.fromPoints(const Offset(2, 2), const Offset(3, 3)),
      );
    } catch (e) {
      debugPrint('Error sharing verse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to share verse"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVerseToGallery() async {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 10),
              Text("Saving verse...", style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );

      final boundary = _verseContainerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await saveImageIntoLocal(pngBytes, context);

      // if (mounted) {
      //   ScaffoldMessenger.of(context).hideCurrentSnackBar();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         Platform.isAndroid
      //             ? "Verse saved to Gallery"
      //             : "Verse saved to Photos",
      //         style: TextStyle(color: Colors.white),
      //       ),
      //       backgroundColor: Colors.green,
      //       behavior: SnackBarBehavior.floating,
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      // }
    } catch (e) {
      debugPrint('Error saving verse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: ${e.toString()}",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ---------- RouteAware overrides ----------
  // Called when this route has been pushed and is now top (visible)
  @override
  void didPush() {
    _refreshPremiumStatusForReadingUi();
    // Only show verse on Reader screen (Home Screen)
    if (widget.From.toString() == "Read" &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _onVisible();
      _maybeShowPendingFeedbackAfterReadingResume();
    }
  }

  // Called when another route has been pushed on top of this one
  @override
  void didPushNext() {
    _onHidden();
    // Dismiss daily verse bottom sheet if open when navigating away
    if (_isBottomSheetOpen && _bottomSheetContext != null) {
      try {
        Navigator.of(_bottomSheetContext!).pop();
        _bottomSheetContext = null;
        _isBottomSheetOpen = false;
      } catch (e) {
        debugPrint('Error dismissing bottom sheet: $e');
        _isBottomSheetOpen = false;
        _bottomSheetContext = null;
      }
    }
  }

  void _restoreReaderAppBarVisibility() {
    _readerAppBarPinnedVisible = true;
    _readerAppBarPendingHide = false;
    _readerAppBarScrollUpIntent = false;
    _readerAppBarDragDelta = 0;
    _readerAppBarUserScrollingDown = false;
    _readerAppBarHiddenAnchorOffset = 0;
    if (!_showUI.value) {
      _showUI.value = true;
    }
  }

  // Called when this route is again visible because the top route was popped
  @override
  void didPopNext() {
    _refreshPremiumStatusForReadingUi();
    void restoreReaderAppBarIfNeeded() {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final hasReaderChapter = Get.isRegistered<DashBoardController>() &&
          Get.find<DashBoardController>().selectedChapter.value.isNotEmpty;
      if (hasReaderChapter || widget.From.toString() == "Read") {
        _restoreReaderAppBarVisibility();
      }
    }

    restoreReaderAppBarIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      restoreReaderAppBarIfNeeded();
    });
    unawaited(_syncReaderChapterAfterChildRoutePop());
    // Only show verse on Reader screen (Home Screen)
    if (widget.From.toString() == "Read" &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _onVisible();
      _maybeShowPendingFeedbackAfterReadingResume();
    }
  }

  Future<void> _refreshPremiumStatusForReadingUi() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (!Get.isRegistered<DashBoardController>()) return;
    await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
  }

  /// After Mark as Read / chapter picker pops, ensure verses match the header chapter.
  Future<void> _syncReaderChapterAfterChildRoutePop() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (!Get.isRegistered<DashBoardController>()) return;
    final controller = Get.find<DashBoardController>();
    if (controller.selectedChapter.value.isEmpty) return;

    _restoreReaderAppBarVisibility();

    if (!controller.displayedContentMatchesSelection()) {
      await controller.forceReloadSelectedChapter();
      _lastVisibleChapterContent = [];
      _lastContentSource = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void didPop() {
    // route was popped; treat as hidden
    _onHidden();
  }

  // ---------- App lifecycle (background/foreground) ----------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_deferUpgradeAfterStreakRating) {
      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        _streakRatingSawLifecyclePause = true;
        _deferUpgradeAfterStreakRatingFallbackTimer?.cancel();
      } else if (state == AppLifecycleState.resumed &&
          _streakRatingSawLifecyclePause) {
        unawaited(_clearDeferUpgradeAfterStreakRating());
      }
    }

    // If app goes to background, treat as hidden; if resumed, treat as visible (only if route is current)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _onHidden();
    } else if (state == AppLifecycleState.resumed) {
      // Exit offer commented out
      // _refreshExitOfferCooldown();
      // only resume if this route is still current
      if (ModalRoute.of(context)?.isCurrent == true) {
        _onVisible();
        _maybeShowPendingFeedbackAfterReadingResume();
        // Live Activity tap may land while Home is already open.
        unawaited(_handlePendingNotificationAction());
      }
    }
  }

  Future<void> _maybeShowPendingFeedbackAfterReadingResume() async {
    if (widget.From.toString() != "Read" || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(SharPreferences.mainFeedbackFromVerseActions) ??
        false)) {
      return;
    }
    if (!(prefs.getBool(SharPreferences.mainFeedbackPending) ?? false)) {
      return;
    }

    if (_feedbackPendingAtSessionStart) {
      _feedbackPendingAtSessionStart = false;
    } else if (!_readingScreenWasHidden) {
      return;
    }

    _readingScreenWasHidden = false;
    await prefs.setBool(SharPreferences.mainFeedbackPending, false);
    if (!mounted) return;
    showMainFeedbackDialog(context);
  }

  // ---------- Pause/Resume helpers ----------
  void _onVisible() {
    debugPrint("Visible HomeScreen!");

    // Only start verse timer on Reader screen (From == "Read")
    if (widget.From.toString() != "Read") {
      return;
    }

    // Additional check: ensure this route is actually current
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    // Auto Verse of the Day popup on reading screen is disabled.
  }

  void _onHidden() {
    debugPrint("Hidden HomeScreen!");
    if (widget.From.toString() == "Read") {
      _readingScreenWasHidden = true;
    }
    // pause stopwatch and cancel checker (but keep elapsed time)
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
    _checkerTimer?.cancel();
    _checkerTimer = null;

    // Dismiss daily verse bottom sheet if open when screen is hidden
    // This ensures it doesn't show on other screens
    if (_isBottomSheetOpen && _bottomSheetContext != null) {
      try {
        Navigator.of(_bottomSheetContext!).pop();
        _bottomSheetContext = null;
        _isBottomSheetOpen = false;
      } catch (e) {
        debugPrint('Error dismissing bottom sheet in _onHidden: $e');
        _isBottomSheetOpen = false;
        _bottomSheetContext = null;
      }
    }
    // setState(() {}); // update UI if you show remaining time
  }

  // Check whether accumulated visible time reached threshold
  void _checkElapsed() {
    // Only check if we're on Reader screen and route is current
    if (widget.From.toString() != "Read" ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      _stopwatch.stop();
      _checkerTimer?.cancel();
      _checkerTimer = null;
      return;
    }

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    if (!_verseShown && elapsedSeconds >= _targetSeconds) {
      _verseShown = true;
      _stopwatch.stop();
      _checkerTimer?.cancel();
      _checkerTimer = null;
      _checkAndShowVerse();
      //setState(() {}); // update UI if you want
    }
  }

  // // Offer dialog methods
  // Future<void> _checkAndShowOfferDialog() async {
  //   if (!mounted) return;

  //   final prefs = await SharedPreferences.getInstance();
  //   bool isDialogShown = prefs.getBool('offerDialogShown') ?? false;
  //   appLaunchCount = prefs.getInt('launchCount') ?? 0;
  //   appLaunchCountoffer = prefs.getInt('launchCountoffer') ?? 0;

  //   await Future.delayed(Duration(seconds: 2));
  //   await NotificationsServices().initialiseNotifications();
  //   await SharPreferences.setBoolean("downloadreward", true);

  //   debugPrint("offer dialog is open $isDialogShown");

  //   if (!isDialogShown) {
  //     await _handleInitialOfferDialog(prefs);
  //   }
  // }

  // Future<void> _handleInitialOfferDialog(SharedPreferences prefs) async {
  //   final dataprovider = Provider.of<AuthNotifier>(context, listen: false);
  //   final data2 = prefs.getString("alrt") ?? '0';

  //   if (data2 != '1') {
  //     await Future.delayed(Duration(seconds: 1));
  //     final check = await Permission.notification.isGranted;

  //     debugPrint("check notification $check");
  //     if (check) {
  //       await SharPreferences.setString('OpenAd', '1');
  //       await showNotificationDialog(context, () async {
  //         await SharPreferences.setString('OpenAd', '1');
  //         return _checkAndShowOfferDialog();
  //       });
  //     } else {
  //       await prefs.setString("alrt", "1");
  //       final data = prefs.getString("notifiyalrt");
  //       if (data != '1') {
  //         await prefs.setString("notifiyalrt", '0');
  //       }
  //       _checkAndShowOfferDialog();
  //     }
  //   }
  //   await _checkAndShowOfferDialog();
  //  // await _handleSecondaryOfferDialog(prefs, dataprovider);
  // }

  // Future<void> _handleSecondaryOfferDialog(
  //     SharedPreferences prefs, AuthNotifier dataprovider) async {
  //   final data = prefs.getString("notifiyalrt");
  //   if (data == '0') {
  //     Random random = Random();
  //     await Future.delayed(Duration(minutes: 1));
  //     final bookofferdata = await dataprovider.getofferbook();

  //     if (bookofferdata != null && bookofferdata.isNotEmpty) {
  //       int randomNumber = random.nextInt(bookofferdata.length);

  //       await prefs.setString("notifiyalrt", '1');
  //       await Future.delayed(Duration.zero, () async {
  //         await SharPreferences.setString('OpenAd', '1');
  //         if (mounted) {
  //           return await showGiftDialog(context, bookofferdata[randomNumber]);
  //         }
  //       });
  //     }
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // subscribe to route changes for this ModalRoute
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  // Other methods
  Future<void> requestReview(List<ConnectivityResult> connectionStatus) async {
    if (!mounted) return;

    if (connectionStatus.first == ConnectivityResult.wifi ||
        connectionStatus.first == ConnectivityResult.mobile) {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        Constants.showToast("Service not available at the moment");
      }
    } else {
      Constants.showToast("No internet connection");
    }
  }

  void checkScreen() {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize;
    debugPrint("sz current width - ${size.width}");
  }

  void updateLoading(bool val, {String? mess}) {
    if (val) {
      EasyLoading.show(status: mess);
    } else {
      EasyLoading.dismiss();
    }

    if (mounted) {
      setState(() {
        message = mess;
      });
    }
  }

  disposead() {
    DashBoardController().bannerAd?.dispose();
  }

  @override
  void dispose() {
    _rating.dispose();
    _showFeedbackButton.dispose();
    lastInterstitialAdPlayed.dispose();
    _showUI.dispose();

    adsDuration.dispose();
    _readerAudioFabKey.currentState?.stopPlaybackOnLeave();
    // audioPlayer.dispose();
    if (mounted) {
      if (audioPlayer.state == PlayerState.playing) {
        audioPlayer.dispose();
      }
    }
    disposead();
    WidgetsBinding.instance.removeObserver(this);
    _checkerTimer?.cancel();
    _deferUpgradeAfterStreakRatingFallbackTimer?.cancel();
    final widgetSub = _widgetClickSubscription;
    _widgetClickSubscription = null;
    widgetSub?.cancel();
    // _exitOfferCooldownRefreshTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String appStoreId = BibleInfo.apple_AppId;
    String microsoftStoreId = '';

    Future<void> openStoreListing() async {
      await inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: microsoftStoreId,
      );
    }

    Future<void> checkAvailability() async {
      try {
        final isAvailable = await inAppReview.isAvailable();

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
      // Future.delayed(Duration.zero, () {
      //   if (context.mounted) {
      //     DebugConsole.show(context);
      //   }
      // });
    });

    double screenWidth = MediaQuery.of(context).size.width;
    var bibleName = BibleInfo.bible_shortName;
    return UpgradeCheckWrapper(
      check: "home",
      child: GetX<DashBoardController>(
        init: DashBoardController(),
        autoRemove: false,
        initState: (state) async {
          final cacheProvider =
              Provider.of<CacheNotifier>(context, listen: false);
          final data = await cacheProvider.readCache(key: 'user');
          if (mounted) {
            // setState(() {
            isLoggedIn = data != null;
            // });
          }
          // Future.delayed(Duration.zero, () async {
          //   int saveRating =
          //       await SharPreferences.getInt(SharPreferences.saveRating) ?? 0;
          //   String lastViewRatingDateTime =
          //       await SharPreferences.getString(SharPreferences.lastViewTime) ??
          //           "";
          //   String lastRatingDateTime = await SharPreferences.getString(
          //           SharPreferences.ratingDateTime) ??
          //       "";
          //   if (lastRatingDateTime != "") {
          //     final startTime = DateFormat('dd-MM-yyyy HH:mm')
          //         .parse(lastViewRatingDateTime.toString());
          //     final currentTime = DateTime.now();
          //     int diffDy = currentTime.difference(startTime).inDays;
          //     if (saveRating <= 4 && diffDy > 3) {
          //       //! i
          //       Future.delayed(
          //         Duration(minutes: 2),
          //         () {
          //           // showDialog(
          //           //     context: context,
          //           //     builder: (BuildContext) {
          //           //       return AlertDialog(
          //           //           shape: RoundedRectangleBorder(
          //           //               borderRadius: BorderRadius.circular(15)),
          //           //           insetPadding:
          //           //               const EdgeInsets.symmetric(horizontal: 15),
          //           //           content: Column(
          //           //             mainAxisSize: MainAxisSize.min,
          //           //             children: [
          //           //               Image.asset(
          //           //                 "assets/feedbacklogo.png",
          //           //                 height: 140,
          //           //                 width: 140,
          //           //                 color: Colors.brown,
          //           //               ),
          //           //               ValueListenableBuilder<int>(
          //           //                 valueListenable: _rating,
          //           //                 builder:
          //           //                     (context, int value, Widget? child) {
          //           //                   String feedbackText = '';
          //           //                   String feedbackText1 = "";
          //           //                   TextStyle style;
          //           //                   TextStyle style1;
          //           //                   Color? colour;
          //           //                   if (value == 0) {
          //           //                     feedbackText = 'Leave Your Experience,';
          //           //                     feedbackText1 = 'Let it Shine Bright';
          //           //                     style = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 13,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     style1 = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 13,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     colour = Colors.grey[500];
          //           //                   } else if (value <= 3) {
          //           //                     feedbackText = 'Please help us';
          //           //                     feedbackText1 =
          //           //                         'with your valuable feedback';
          //           //                     style = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 13,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     style1 = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 13,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     colour = Colors.brown[500];
          //           //                   } else {
          //           //                     feedbackText = 'Great!';
          //           //                     feedbackText1 =
          //           //                         'Give your rating on store';
          //           //                     style = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 13,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     style1 = const TextStyle(
          //           //                         letterSpacing:
          //           //                             BibleInfo.letterSpacing,
          //           //                         fontSize:
          //           //                             BibleInfo.fontSizeScale * 20,
          //           //                         fontWeight: FontWeight.bold,
          //           //                         color: Colors.brown);
          //           //                     colour = Colors.brown[500];
          //           //                   }
          //           //                   return Column(
          //           //                     children: [
          //           //                       Text(feedbackText, style: style1),
          //           //                       const SizedBox(height: 16),
          //           //                       Text(
          //           //                         feedbackText1,
          //           //                         style: style,
          //           //                       ),
          //           //                       const SizedBox(
          //           //                         height: 10,
          //           //                       ),
          //           //                       Row(
          //           //                         mainAxisAlignment:
          //           //                             MainAxisAlignment.center,
          //           //                         children: <Widget>[
          //           //                           for (int i = 1; i <= 5; i++)
          //           //                             GestureDetector(
          //           //                               onTap: () {
          //           //                                 _setRating(i);
          //           //                                 state.controller!.rating
          //           //                                     .value = i;
          //           //                               },
          //           //                               child: Icon(
          //           //                                 Icons.star,
          //           //                                 size: 40,
          //           //                                 color: value >= i
          //           //                                     ? Colors.brown
          //           //                                     : Colors.grey,
          //           //                               ),
          //           //                             ),
          //           //                         ],
          //           //                       ),
          //           //                       const SizedBox(height: 16),
          //           //                       Row(
          //           //                         mainAxisAlignment:
          //           //                             MainAxisAlignment.center,
          //           //                         children: [
          //           //                           ElevatedButton(
          //           //                             style: ElevatedButton.styleFrom(
          //           //                                 backgroundColor:
          //           //                                     Colors.grey[500]),
          //           //                             child: const Text('Not Now',
          //           //                                 style: TextStyle(
          //           //                                     color: Colors.white)),
          //           //                             onPressed: () {
          //           //                               Navigator.of(context).pop();
          //           //                               SharPreferences.setString(
          //           //                                   SharPreferences
          //           //                                       .lastViewTime,
          //           //                                   "$currentTime");
          //           //                             },
          //           //                           ),
          //           //                           const SizedBox(width: 50),
          //           //                           ValueListenableBuilder<bool>(
          //           //                             valueListenable:
          //           //                                 _showFeedbackButton,
          //           //                             builder: (context, bool value,
          //           //                                 Widget? child) {
          //           //                               if (!value) {
          //           //                                 return SizedBox(
          //           //                                   height: 40,
          //           //                                   width: 120,
          //           //                                   child: ElevatedButton(
          //           //                                     style: ElevatedButton
          //           //                                         .styleFrom(
          //           //                                             backgroundColor:
          //           //                                                 colour),
          //           //                                     child: const Text(
          //           //                                       'Feedback',
          //           //                                       style: TextStyle(
          //           //                                           color:
          //           //                                               Colors.white),
          //           //                                     ),
          //           //                                     onPressed: () async {
          //           //                                       Get.back();
          //           //                                       SharPreferences.setInt(
          //           //                                           SharPreferences
          //           //                                               .saveRating,
          //           //                                           state
          //           //                                               .controller!
          //           //                                               .rating
          //           //                                               .value);
          //           //                                       // SharPreferences.setBoolean(SharPreferences.dailyCheack, true);
          //           //                                       SharPreferences.setString(
          //           //                                           SharPreferences
          //           //                                               .ratingDateTime,
          //           //                                           "$currentTime");

          //           //                                       const url =
          //           //                                           'https://bibleoffice.com/m_feedback/API/feedback_form/index.php';
          //           //                                       if (await canLaunch(
          //           //                                           url)) {
          //           //                                         await launch(url);
          //           //                                       } else {
          //           //                                         throw 'Could not launch $url';
          //           //                                       }
          //           //                                     },
          //           //                                   ),
          //           //                                 );
          //           //                               } else {
          //           //                                 return SizedBox(
          //           //                                   height: 40,
          //           //                                   width: 120,
          //           //                                   child: ElevatedButton(
          //           //                                     style: ElevatedButton
          //           //                                         .styleFrom(
          //           //                                             backgroundColor:
          //           //                                                 colour),
          //           //                                     child: const Text(
          //           //                                       'Rate Us',
          //           //                                       style: TextStyle(
          //           //                                           color:
          //           //                                               Colors.white),
          //           //                                     ),
          //           //                                     onPressed: () async {
          //           //                                       Get.back();
          //           //                                       SharPreferences.setInt(
          //           //                                           SharPreferences
          //           //                                               .saveRating,
          //           //                                           state
          //           //                                               .controller!
          //           //                                               .rating
          //           //                                               .value);
          //           //                                       SharPreferences.setString(
          //           //                                           SharPreferences
          //           //                                               .ratingDateTime,
          //           //                                           "$currentTime");
          //           //                                       String appId;
          //           //                                       appId = BibleInfo
          //           //                                           .apple_AppId;
          //           //                                       if (Platform
          //           //                                           .isAndroid) {
          //           //                                         final appPackageName =
          //           //                                             (await PackageInfo
          //           //                                                     .fromPlatform())
          //           //                                                 .packageName;
          //           //                                         try {
          //           //                                           launchUrl(Uri.parse(
          //           //                                               "market://details?id=$appPackageName"));
          //           //                                         } on PlatformException {
          //           //                                           launchUrl(Uri.parse(
          //           //                                               "https://play.google.com/store/apps/details?id=$appPackageName"));
          //           //                                         }
          //           //                                       } else if (Platform
          //           //                                           .isIOS) {
          //           //                                         launchUrl(Uri.parse(
          //           //                                             "https://itunes.apple.com/app/id$appId"));
          //           //                                       }
          //           //                                     },
          //           //                                   ),
          //           //                                 );
          //           //                               }
          //           //                             },
          //           //                           ),
          //           //                         ],
          //           //                       ),
          //           //                     ],
          //           //                   );
          //           //                 },
          //           //               ),
          //           //             ],
          //           //           ));
          //           //     });
          //         },
          //       );
          //     }
          //   }
          // });

          // Future.delayed(const Duration(milliseconds: 1), () {
          //   if (!_scrollListenerAttached) {
          //     _scrollListenerAttached = true;
          //     state.controller?.autoScrollController.value.addListener(() {
          //       final direction = state.controller?.autoScrollController.value
          //           .position.userScrollDirection;
          //       if (direction == ScrollDirection.reverse ||
          //           direction == ScrollDirection.forward) {
          //         state.controller?.scrollHideShowIcon.value = false;
          //         Future.delayed(const Duration(milliseconds: 1), () {
          //           state.controller?.scrollHideShowIcon.value = true;
          //         });
          //       }
          //     });
          //   }
          // });

          // if (state.controller!.selectedChapter.value != "") {
          //   state.controller!.selectChapterChange.value =
          //       int.parse(state.controller!.selectedChapter.value);
          // }
          // state.controller!.selectedBookNumForRead.value =
          //     widget.selectedBookForRead.toString();
          // state.controller!.selectedChapterForRead.value =
          //     widget.selectedChapterForRead.toString();
          // state.controller!.selectedVerseForRead.value =
          //     widget.selectedVerseNumForRead.toString();
          // state.controller!.selectedBookNameForRead.value =
          //     widget.selectedBookNameForRead.toString();
          // SharPreferences.getString(SharPreferences.isRewardAdViewTime)
          //     .then((value) async {
          //   state.controller!.RewardAdExpireDate.value = value.toString();
          //   RewardAdExpireDate = value;
          //   debugPrint("RewardAdExpireDate is $RewardAdExpireDate");
          //   Future.delayed(
          //     Duration.zero,
          //     () {
          //       state.controller!.loadApi();
          //     },
          //   );

          //   if (value != null) {
          //     DateTime CurrentDateTime = DateTime.now();
          //     DateTime SaveTime = DateTime.parse(value.toString());
          //     var diff = CurrentDateTime.difference(SaveTime).inDays;

          //     if (!diff.isNegative) {
          //       state.controller!.initBanner(adUnitId: '');
          //       state.controller!.initInterstitialAd(adUnitId: '');
          //       state.controller!.loadRewardedAd(adUnitId: '');
          //       SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
          //     } else {
          //       SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
          //       state.controller!.adFree.value = true;
          //       state.controller!.isGetRewardAd.value = true;
          //     }
          //   } else {
          //     state.controller!.initBanner(adUnitId: '');
          //     state.controller!.initInterstitialAd(adUnitId: '');
          //     state.controller!.loadRewardedAd(adUnitId: '');
          //   }
          // });

          // state.controller!.selectedIndex.value = -1;
          // Future.delayed(
          //   Duration.zero,
          //   () async {
          //     widget.From.toString() == "Read" ||
          //             widget.From.toString() == "Daily"
          //         ? state.controller!.readHighlight.value = true
          //         : state.controller!.readHighlight.value = false;

          //     widget.From.toString() == "Read" ||
          //             widget.From.toString() == "Daily"
          //         ? state.controller!.getBookContentForRead()
          //         : state.controller!.getSelectedChapterAndBook();

          //     state.controller!.getFont();
          //   },
          // );

          // Future.delayed(
          //   const Duration(seconds: 6),
          //   () {
          //     state.controller?.readHighlight.value = false;
          //   },
          // );

          // Future.delayed(
          //   Duration.zero,
          //   () {
          //     state.controller?.autoScrollController.value =
          //         AutoScrollController(
          //             viewportBoundaryGetter: () => Rect.fromLTRB(
          //                 0, 0, 0, MediaQuery.of(context).padding.bottom),
          //             axis: state.controller!.scrollDirection);
          //   },
          // );

          // Future.delayed(
          //   const Duration(seconds: 1),
          //   () {
          //     if (widget.From.toString() == "Read") {
          //       state.controller!.scrollToIndex(
          //           int.parse(widget.selectedVerseNumForRead.toString()));
          //     }
          //     if (widget.From.toString() == "Daily") {
          //       state.controller?.selectedIndex.value = -1;
          //       state.controller!.scrollToIndex(
          //           int.parse(widget.selectedVerseNumForRead.toString()));
          //     }
          //   },
          // );
          _initializeControllerState(state);
          final cachedController = state.controller;
          final hasCachedContent = cachedController != null &&
              cachedController.selectedBookContent.isNotEmpty;
          final skipReloadPath =
              hasCachedContent && !_homeEntryRequiresContentReload();
          if (!hasCachedContent || _homeEntryRequiresContentReload()) {
          _loadInitialData(state);
          }
          if (hasCachedContent) {
            cachedController.isFetchContent.value = false;
            _hasDisplayedChapterContent = true;
            if (skipReloadPath) {
              cachedController.loadTextToSpeech.value = false;
            }
          }
          _handleAdExpiration(state, skipLoadApi: hasCachedContent);
          _initializeRatingDialog(state);
          final prefs = await SharedPreferences.getInstance();
          if (widget.From.toString() == 'premium') {
            final data = prefs.getString("premiumalrt") ?? "1";
            if (data == '1') {
              await PremiumWelcomeAlert.show(context);
            } else {
              await SharPreferences.setBoolean(
                  SharPreferences.deferUpgradeAlert, false);
            }
          }
        },
        builder: (controller) {
          if (controller.selectedBookContent.isNotEmpty) {
            _hasDisplayedChapterContent = true;
            final content = controller.selectedBookContent;
            // Copy only when the chapter list instance changes — not on every rebuild.
            if (!identical(_lastContentSource, content)) {
              _lastContentSource = content;
              _lastVisibleChapterContent =
                  List<VerseBookContentModel>.from(content);
            }
          } else if (_lastVisibleChapterContent.isNotEmpty &&
              !_staleContentMatchesChapter(controller)) {
            // Additive: drop stale verses when book/chapter advanced (Mark as Read).
            _lastVisibleChapterContent = [];
            _lastContentSource = null;
          }
          final readerVerses = controller.selectedBookContent.isNotEmpty
              ? controller.selectedBookContent
              : (_lastVisibleChapterContent.isNotEmpty &&
                      _staleContentMatchesChapter(controller)
                  ? _lastVisibleChapterContent
                  : controller.selectedBookContent);
          final themeProvider = p.Provider.of<ThemeProvider>(context);
          final isVintage =
              themeProvider.currentCustomTheme == AppCustomTheme.vintage;
          final isDark = themeProvider.themeMode == ThemeMode.dark;
          // White/yellow themes always use their light surface (even in Dark Mode).
          final scaffoldBg = isVintage
              ? (isDark ? CommanColor.black : const Color(0xFFF5F0E6))
              : themeProvider.backgroundColor;

          final readerToolbarHeight = screenWidth > 450 ? 70.0 : 55.0;
          final readerChapterBarHeight = screenWidth > 450 ? 45.0 : 30.0;
          final readerAppBarHeight =
              readerToolbarHeight + readerChapterBarHeight;
          // extendBodyBehindAppBar: list must clear status bar + full app bar.
          final readerContentTopPadding =
              MediaQuery.paddingOf(context).top + readerAppBarHeight;
          return ValueListenableBuilder<bool>(
            valueListenable: _showUI,
            builder: (context, showUI, child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: scaffoldBg,
            // Body stays full-height; app bar fades over content (no list resize jank).
            extendBodyBehindAppBar:
                controller.selectedChapter.value.isNotEmpty,
            appBar: controller.selectedChapter.value.isNotEmpty
                ? _SmoothReaderAppBar(
                    visible: showUI,
                    height: readerAppBarHeight,
                    child: AppBar(
                    toolbarHeight: readerToolbarHeight,
                          iconTheme: IconThemeData(
                              color: CommanColor.whiteBlack(context)),
                    flexibleSpace: Container(
                      color: p.Provider.of<ThemeProvider>(context)
                                  .currentCustomTheme ==
                              AppCustomTheme.vintage
                          ? null
                                  : p.Provider.of<ThemeProvider>(context)
                                      .backgroundColor,
                      decoration: p.Provider.of<ThemeProvider>(context)
                                  .currentCustomTheme ==
                              AppCustomTheme.vintage
                          ? BoxDecoration(
                              color: Provider.of<ThemeProvider>(context)
                                          .themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.black
                                  : p.Provider.of<ThemeProvider>(context)
                                              .currentCustomTheme ==
                                          AppCustomTheme.vintage
                                      ? CommanColor.darkPrimaryColor
                                            : p.Provider.of<ThemeProvider>(
                                                    context)
                                          .backgroundColor,
                              image: DecorationImage(
                                      image:
                                          AssetImage(Images.bgImage((context))),
                                fit: BoxFit.cover,
                              ),
                            )
                          : null,
                    ),
                    backgroundColor: p.Provider.of<ThemeProvider>(context)
                                .currentCustomTheme ==
                            AppCustomTheme.vintage
                        ? Colors.transparent
                        : null,
                    leadingWidth: 96,
                    titleSpacing: 0,
                    leading: Row(
                      children: [
                        SizedBox(width: 12),
                        // Show back button if coming from chat, otherwise show menu
                        widget.From.toString() == "chat"
                            ? GestureDetector(
                                onTap: () {
                                  Get.back();
                                },
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: screenWidth > 450 ? 40 : 24,
                                  color: CommanColor.whiteBlack(context),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                child: Icon(
                                  Icons.menu,
                                  size: screenWidth > 450 ? 40 : 24,
                                ),
                              ),
                        SizedBox(width: 12),
                              // IAP icon is independent of ads being completely disabled
                              // (ads_Type == "0"). Ads stay off; only visibility is uncoupled.
                              controller.adFree.value
                                ? DateTime.tryParse(controller
                                            .RewardAdExpireDate.value) !=
                                        null
                                      // UI only: subscription info icon removed from
                                      // reading bar (same sheet remains in the drawer).
                                      ? const SizedBox.shrink()
                                    : Visibility(
                                          visible: controller
                                                  .isSubscriptionEnabled ??
                                                true,
                                        child: GestureDetector(
                                          onTap: () async {
                                            // Navigate directly to the paywall from Home
                                            // instead of showing the Home exit-offer bottom sheet.
                                            // This keeps purchase logic unchanged and avoids
                                            // displaying the in-place exit-offer sheet on Home.
                                            if (controller.connectionStatus
                                                        .first ==
                                                    ConnectivityResult.wifi ||
                                                controller.connectionStatus
                                                        .first ==
                                                      ConnectivityResult
                                                          .mobile) {
                                              adsIcon = false;
                                              debugPrint(
                                                  "all plans - ${controller.sixMonthPlan} ${controller.oneYearPlan}  ${controller.lifeTimePlan}");
                                              await SubscriptionScreen
                                                  .navigateToPaywallFromHome(
                                                      context);
                                            } else {
                                              Constants.showToast(
                                                  "Check your Internet Connection");
                                            }
                                          },
                                          child: Image.asset(
                                            'assets/no-ad.png',
                                            height:
                                                screenWidth > 450 ? 40 : 24,
                                            width:
                                                screenWidth > 450 ? 40 : 24,
                                            color: CommanColor.whiteBlack(
                                                context),
                                          ),
                                        ))
                                : Visibility(
                                      visible:
                                          controller.isSubscriptionEnabled ??
                                        false,
                                    child: GestureDetector(
                                      onTap: () async {
                                        adsIcon = false;
                                        await SubscriptionScreen
                                              .navigateToPaywallFromHome(
                                                  context);
                                      },
                                      child: Image.asset(
                                        'assets/no-ad.png',
                                        height: screenWidth > 450 ? 35 : 24,
                                        width: screenWidth > 450 ? 35 : 24,
                                        color:
                                            CommanColor.whiteBlack(context),
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                    actions: [
                      BibleInfo.folders.length != 1
                          ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                              child: InkWell(
                                  onTap: () {
                                          if (controller.adFree.value ==
                                              false) {
                                      controller.bannerAd?.dispose();
                                      controller.bannerAd?.load();
                                    }
                                    Get.to(() => BibleVersionsScreen(
                                          from: 'home',
                                        ));
                                  },
                                  child: Image.asset(
                                    "assets/biblebook.png",
                                    height: screenWidth > 450 ? 30 : 24,
                                    width: screenWidth > 450 ? 30 : 24,
                                          color:
                                              CommanColor.whiteBlack(context),
                                  )),
                            )
                          : SizedBox(),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      InkWell(
                          onTap: () {
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(
                                () => SearchScreen(
                                      controller: controller,
                                    ),
                                    transition: Transition.cupertino,
                                          duration: const Duration(
                                              milliseconds: 300));
                          },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            "assets/home icons/search.png",
                            height: screenWidth > 450 ? 30 : 22,
                            width: screenWidth > 450 ? 30 : 22,
                            color: CommanColor.whiteBlack(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                      StreakIconButton(
                        iconSize: screenWidth > 450 ? 28 : 22,
                      ),
                            const SizedBox(width: 6),
                      Padding(
                              padding: const EdgeInsets.all(4),
                        child: ChangeThemeButtonWidget(),
                      ),
                    ],
                        ),
                      ),
                    ],
                    title: _buildAppBarBookTitleSelector(
                      context: context,
                      controller: controller,
                      screenWidth: screenWidth,
                        onTap: () async {
                          if (controller.adFree.value == false) {
                            controller.bannerAd?.dispose();
                            controller.bannerAd?.load();
                          }
                          Get.to(() => const BookListScreen(),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 350));
                      },
                    ),
                    bottom: PreferredSize(
                      preferredSize:
                          Size.fromHeight(readerChapterBarHeight),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            hintColor: CommanColor.whiteAndDark(context)),
                        child: Container(
                          height: readerChapterBarHeight,
                          decoration: () {
                            final themeProvider =
                                p.Provider.of<ThemeProvider>(context);
                            final isDark =
                                themeProvider.themeMode == ThemeMode.dark;
                                  final isVintage =
                                      themeProvider.currentCustomTheme ==
                                AppCustomTheme.vintage;
                                  if (isDark && isVintage) {
                                    final base = CommanColor.darkPrimaryColor;
                              return BoxDecoration(
                                color: Color.lerp(
                                  base,
                                  Colors.white,
                                  0.22,
                                )!
                                    .withOpacity(0.88),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                              );
                            }
                            return BoxDecoration(
                              color: isVintage
                                      ? CommanColor.white
                                  : themeProvider.backgroundColor,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                            );
                          }(),
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              if (controller.adFree.value == false) {
                                controller.bannerAd?.dispose();
                                controller.bannerAd?.load();
                              }
                              Get.to(
                                  () => ChapterListScreen(
                                              book_num: controller
                                                  .selectedBookNum.value,
                                        chapterCount: controller
                                                  .selectedBookChapterCount
                                                  .value,
                                              selectedChapter: controller
                                                  .selectedChapter.value,
                                      ),
                                  transition: Transition.cupertino,
                                        duration:
                                            const Duration(milliseconds: 350),
                                        opaque: true);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                              children: [
                                controller.selectedChapter.value == ""
                                    ? const SizedBox()
                                    : Text(
                                        "Chapter - ${int.parse(controller.selectedChapter.value)}",
                                              style: CommanStyle.bw14500(
                                                      context)
                                            .copyWith(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              20
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                        14)),
                                Padding(
                                        padding: const EdgeInsets.only(
                                            top: 2.0, left: 5),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                          color:
                                              CommanColor.whiteBlack(context),
                                    size: screenWidth > 450 ? 39 : 18,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    centerTitle: true,
                    elevation: 2,
                  ),
                  )
                : null,
            body: child,
            floatingActionButton: !_hasDisplayedChapterContent &&
                    controller.selectedBookContent.isEmpty
                ? const SizedBox()
                : IgnorePointer(
                    ignoring: !showUI,
                    child: Opacity(
                      opacity: showUI ? 1 : 0,
                      child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                        children: [
                          if (BibleInfo.chat == 1)
                            Builder(
                                            builder: (buttonContext) =>
                                                GestureDetector(
                                onTap: () {
                                  if (isOpenChat) {
                                                  if (Navigator.of(
                                                          buttonContext,
                                            rootNavigator: false)
                                        .canPop()) {
                                      Navigator.of(buttonContext,
                                                            rootNavigator:
                                                                false)
                                          .pop();
                                    }
                                    setState(() {
                                      isOpenChat = false;
                                    });
                                  } else {
                                    setState(() {
                                      isOpenChat = true;
                                  });
                                                  _showChatEntryPopover(
                                                      buttonContext);
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth > 600
                                        ? 48
                                        : screenWidth > 450
                                            ? 40
                                            : 32,
                                  ),
                                  child: Container(
                                      height: screenWidth > 600
                                          ? 56
                                          : screenWidth > 450
                                              ? 50
                                              : 35,
                                      width: screenWidth > 600
                                          ? 56
                                          : screenWidth > 450
                                              ? 50
                                              : 35,
                                      decoration: BoxDecoration(
                                                      color: CommanColor
                                                          .whiteLightModePrimary(
                                            context),
                                        shape: BoxShape.circle,
                                                      boxShadow: CommanColor
                                                              .isDarkTheme(
                                                                  context)
                                            ? const [
                                                BoxShadow(
                                                                color: Colors
                                                                    .black45,
                                                  blurRadius: 8,
                                                                offset: Offset(
                                                                    0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: isOpenChat
                                            ? Icon(
                                                Icons.close,
                                                color: CommanColor
                                                                  .darkModePrimaryWhite(
                                                                      context),
                                                              size:
                                                                  screenWidth >
                                                                          450
                                                                      ? 22
                                                                      : 18,
                                              )
                                            : Image.asset(
                                                              CommanColor
                                                                      .isDarkTheme(
                                                                          context)
                                                    ? "assets/dark_modes/new-dark_chat.png"
                                                    : "assets/Chat white.png",
                                                              width: screenWidth >
                                                                      600
                                                    ? 26
                                                                  : screenWidth >
                                                                          450
                                                        ? 24
                                                        : 22,
                                                              height: screenWidth >
                                                                      600
                                                    ? 26
                                                                  : screenWidth >
                                                                          450
                                                        ? 24
                                                        : 22,
                                                color: CommanColor
                                                                  .darkModePrimaryWhite(
                                                                      context),
                                              ),
                                      )),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: screenWidth > 600
                                  ? 56
                                  : screenWidth > 450
                                      ? 50
                                      : 35,
                            ),
                        ],
                      ),
                      floatingButton(
                        key: _readerAudioFabKey,
                                      chapterNum:
                                          controller.selectedChapter.value,
                        bookName: controller.selectedBook.value,
                                      // Prefer full-book verses for TTS next/prev; fall back to
                                      // the on-screen chapter so newly opened books are not empty.
                                      contentList: controller
                                              .selectedVersesContent.isNotEmpty
                                          ? controller.selectedVersesContent
                                          : controller.selectedBookContent,
                                      chapterCount: controller
                                          .selectedBookChapterCount.value,
                        audioData: controller.audioData.value,
                        bookNum: controller.selectedBookNum.value,
                                      internetConnection:
                                          controller.connectionStatus,
                                      textToSpeechLoad:
                                          controller.loadTextToSpeech.value,
                        audioPlayer: audioPlayer,
                      ),
                    ],
                      ),
                        ],
                      ),
                    ),
                    ),
                  ),
            drawer: controller.isFetchContent.value &&
                    controller.selectedBookContent.isEmpty &&
                    !_hasDisplayedChapterContent
                ? const SizedBox()
                    : _buildIosHomeDrawer(
                              context: context,
                        controller: controller,
                        bibleName: bibleName,
                        screenWidth: screenWidth,
                  ),
            bottomNavigationBar: const SizedBox(
              height: 1,
            ),
          );
            },
            child: WillPopScope(
              onWillPop: () async {
                Future.delayed(Duration.zero, () async {
                  int saveRating = await SharPreferences.getInt(
                          SharPreferences.saveRating) ??
                      0;
                  String lastViewRatingDateTime =
                      await SharPreferences.getString(
                              SharPreferences.lastViewTime) ??
                          "";
                  String lastRatingDateTime = await SharPreferences.getString(
                          SharPreferences.ratingDateTime) ??
                      "";
                  if (lastRatingDateTime != "") {
                    final startTime = DateFormat('dd-MM-yyyy HH:mm')
                        .parse(lastViewRatingDateTime.toString());
                    final currentTime = DateTime.now();
                    int diffDy = currentTime.difference(startTime).inDays;
                    if (saveRating <= 4 && diffDy > 3) {
                      Future.delayed(
                        Duration(minutes: 2),
                        () {},
                      );
                    }
                  }
                });
                return false;
              },
              child: GestureDetector(
                onPanEnd: (dragDetail) async {
                  // Avoid triggering chapter navigation while user is scrolling vertically.
                  final vx = dragDetail.velocity.pixelsPerSecond.dx;
                  final vy = dragDetail.velocity.pixelsPerSecond.dy;
                  if (vx.abs() <= vy.abs()) {
                    return;
                  }
                  // Require a meaningful horizontal swipe velocity.
                  if (vx.abs() < 250) {
                    return;
                  }
                  // Show ad every 5 swipes
                  if (vx < 0) {
                    //! AD interstitialAd

                    swipeCount++;

                    if (swipeCount >= _swipeThreshold) {
                      swipeCount = 0; // Reset counter
                      debugPrint(
                          "now Chapter and count is $swipeCount $_swipeThreshold");
                      await Future.delayed(Duration(milliseconds: 500));
                      if (_adService.interstitialAd != null &&
                          controller.adFree.value == false) {
                        EasyLoading.showInfo('Please wait...');
                        await SharPreferences.setString('OpenAd', '1');
                        _adService.showInterstitialAd();
                      }
                    }
                    debugPrint(
                        "Next Chapter and count is $swipeCount $_swipeThreshold");
                    if (controller.selectChapterChange.value + 1 <=
                        int.parse(controller.selectedBookChapterCount.value)) {
                      controller.selectChapterChange.value++;
                      controller.selectedChapter.value =
                          controller.selectChapterChange.value.toString();
                      await SharPreferences.setString(
                          SharPreferences.selectedChapter,
                          controller.selectedChapter.value);

                      await controller.getSelectedChapterAndBook();
                      await controller.getFont();
                    } else {
                      Constants.showToast(
                          "Selected Book is completed. Please change the book.");
                    }
                  } else if (controller.selectChapterChange.value > 1) {
                    swipeCount++;

                    if (swipeCount >= _swipeThreshold) {
                      swipeCount = 0; // Reset counter
                      debugPrint(
                          "now Chapter and count is $swipeCount $_swipeThreshold");
                      await Future.delayed(Duration(milliseconds: 600));
                      if (_adService.interstitialAd != null &&
                          controller.adFree.value == false) {
                        EasyLoading.showInfo('Please wait...');
                        await SharPreferences.setString('OpenAd', '1');
                        _adService.showInterstitialAd();
                      }
                    }
                    debugPrint(
                        "Next Chapter and count is $swipeCount $_swipeThreshold");
                    debugPrint("Previous Chapter");
                    controller.selectChapterChange.value--;
                    controller.selectedChapter.value =
                        controller.selectChapterChange.value.toString();
                    await SharPreferences.setString(
                        SharPreferences.selectedChapter,
                        controller.selectedChapter.value);
                    await controller.getSelectedChapterAndBook();
                    await controller.getFont();
                  }
                },
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  decoration: p.Provider.of<ThemeProvider>(context)
                              .currentCustomTheme ==
                          AppCustomTheme.vintage
                      ? BoxDecoration(
                          // color: Color(0x80605749),
                          image: DecorationImage(
                              image: AssetImage(Images.bgImage(context)),
                              fit: BoxFit.fill))
                      : null,
                  child: controller.isFetchContent.value &&
                          controller.selectedBookContent.isEmpty &&
                          !_hasDisplayedChapterContent
                      ? const Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Loader(),
                          ],
                        ))
                      // UI-only: while chapter header advanced but verses still
                      // belong to the previous chapter, cover with loader so
                      // the old chapter does not flash/flicker.
                      : (controller.selectedChapter.value.isNotEmpty &&
                              readerVerses.isNotEmpty &&
                              !controller.displayedContentMatchesSelection())
                          ? ColoredBox(
                              color: scaffoldBg,
                              child: const Center(child: Loader()),
                            )
                      : controller.selectedBookContent.isEmpty &&
                              !_hasDisplayedChapterContent
                          ? _buildEmptyContentWithChapters(controller)
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                final scrollController =
                                    controller.autoScrollController.value;
                                if (!scrollController.hasClients) {
                                  return false;
                                }
                                _handleReaderScrollForAppBar(
                                  notification,
                                  scrollController.position.pixels,
                                );
                                return false;
                              },
                              child: ListView.builder(
                              key: ValueKey(
                                  'reader_chapter_${controller.selectedChapter.value}'),
                              scrollDirection: controller.scrollDirection,
                                    controller:
                                        controller.autoScrollController.value,
                              itemCount: readerVerses.length,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              cacheExtent: 800,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              padding: EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  bottom: 20,
                                  // Clear status bar + overlay app bar (extendBodyBehindAppBar).
                                  top: controller.selectedChapter.value
                                          .isNotEmpty
                                      ? readerContentTopPadding
                                      : 0),
                              itemBuilder: (context, index) {
                                var data = readerVerses[index];
                                return AutoScrollTag(
                                  key: ValueKey(
                                      '${controller.selectedChapter.value}_$index'),
                                        controller: controller
                                            .autoScrollController.value,
                                  index: index,
                                  child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10.0),
                                        child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                                    controller.selectedIndex
                                                        .value = -1;

                                                    controller.selectedIndex
                                                        .value = index;

                                              controller.selectedVerseView
                                                  .value = index;
                                              controller.printText.value =
                                                  parseVerseContent(
                                                      data.content);
                                            });

                                            await homeContentEditBottomSheet(
                                                    context,
                                                    loadInterstitial:
                                                        loadInterstitialAd,
                                                    callback2: () {
                                              //_handledownloadClick();
                                            }, callback: (v) {
                                              setState(() {
                                                // selectedcolor = v;
                                                      controller.selectedIndex
                                                          .value = index;
                                              });
                                              debugPrint(" step 1 ");
                                            },
                                                    verNum:
                                                        "${displayVerseNumber(data, listIndex: index)}",
                                                    verseBookdata: data,
                                                    selectedColor: data
                                                                .isHighlighted ==
                                                            "no"
                                                        ? 0
                                                        : int.parse(
                                                            selectedcolor ??
                                                                '0x00000000'),
                                                          controller:
                                                              controller)
                                                .then(
                                              (value) {
                                                setState(() {
                                                        controller.selectedIndex
                                                            .value = -1;
                                                });
                                                debugPrint(" step 2 ");
                                                // controller.selectedIndex.value =
                                                //     -1;
                                              },
                                            );
                                          },
                                          child: VerseItemWidget(
                                            index: index,
                                                  currentindex: controller
                                                      .selectedIndex.value,
                                            controller: controller,
                                            data: data,
                                            selectedVerseForRead: widget
                                                .selectedVerseForRead
                                                .toString(),
                                            selectedColor:
                                                selectedcolor.toString(),
                                          ),
                                        ),
                                      ),
                                            controller.selectedBookContent
                                                        .length ==
                                                    1
                                          ? Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 7),
                                              child: Row(
                                                mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () async {
                                                      await SharPreferences
                                                          .setString(
                                                                    'OpenAd',
                                                                    '1');
                                                      await DBHelper()
                                                          .db
                                                          .then((value) {
                                                        value!
                                                            .rawQuery(
                                                                "SELECT * From book WHERE book_num = ${int.parse(controller.selectedBookNum.value)}")
                                                            .then(
                                                                (value) async {
                                                                controller
                                                                    .bookReadPer
                                                                    .value = value[
                                                                            0][
                                                                        "read_per"]
                                                              .toString();
                                                          if (controller
                                                                  .selectedBookContent[
                                                                      0]
                                                                  .isRead ==
                                                              "no") {
                                                                  if (int.tryParse(controller
                                                                        .bookReadPer
                                                                        .value) ==
                                                                0) {
                                                              double readPer = (100 *
                                                                      1) /
                                                                        double.parse(controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                              DBHelper()
                                                                  .updateBookData(
                                                                            int.parse(controller.selectedBookId.value.toString()),
                                                                      "read_per",
                                                                            readPer.toStringAsFixed(1).toString())
                                                                        .then((value) {});
                                                            } else {
                                                              double readPer = (100 *
                                                                      1) /
                                                                        double.parse(controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                                    double finalRead = double.parse(controller
                                                                          .bookReadPer
                                                                          .value
                                                                          .toString()) +
                                                                      readPer;
                                                              DBHelper()
                                                                  .updateBookData(
                                                                            int.parse(controller.selectedBookId.value.toString()),
                                                                      "read_per",
                                                                            finalRead.toStringAsFixed(1).toString())
                                                                        .then((value) {});
                                                            }
                                                            controller
                                                                .isReadLoad
                                                                .value = true;
                                                                  for (var i =
                                                                          0;
                                                                i <
                                                                    controller
                                                                        .selectedBookContent
                                                                        .value
                                                                        .length;
                                                                i++) {
                                                              DBHelper()
                                                                  .updateVersesData(
                                                                            int.parse(controller.selectedBookContent.value[i].id
                                                                          .toString()),
                                                                      "is_read",
                                                                      "yes")
                                                                  .then(
                                                                      (value) {});
                                                              var data = VerseBookContentModel(
                                                                  id: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .id,
                                                                  bookNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .bookNum,
                                                                  chapterNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .chapterNum,
                                                                  verseNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .verseNum,
                                                                  content: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .content,
                                                                        isBookmarked: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isBookmarked,
                                                                        isHighlighted: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isHighlighted,
                                                                  isNoted: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .isNoted,
                                                                        isUnderlined: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isUnderlined,
                                                                  isRead:
                                                                      "yes");
                                                                    controller.selectedBookContent[
                                                                            i] =
                                                                        data;
                                                                  }

                                                                  Future
                                                                      .delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      200),
                                                              () async {
                                                                controller
                                                                    .isReadLoad
                                                                    .value = false;

                                                                // Check internet connectivity first - if offline/low internet, skip ad and navigate directly
                                                                bool
                                                                    shouldSkipAd =
                                                                    false;
                                                                try {
                                                                  final hasInternet =
                                                                            await InternetConnection().hasInternetAccess;
                                                                  if (!hasInternet) {
                                                                    // Offline - skip ad and navigate directly
                                                                    shouldSkipAd =
                                                                        true;
                                                                  } else {
                                                                    // Check if mobile only connection (likely 2G/slow) - skip ad
                                                                    final connectivityResult =
                                                                              await Connectivity().checkConnectivity();
                                                                    final isMobileOnly = connectivityResult.contains(ConnectivityResult.mobile) &&
                                                                              !connectivityResult.contains(ConnectivityResult.wifi) &&
                                                                              !connectivityResult.contains(ConnectivityResult.ethernet);
                                                                    if (isMobileOnly) {
                                                                      // Low internet (2G/mobile only) - skip ad and navigate directly
                                                                      shouldSkipAd =
                                                                          true;
                                                                    }
                                                                  }
                                                                } catch (e) {
                                                                  // If connectivity check fails, skip ad and proceed
                                                                  debugPrint(
                                                                      'Connectivity check error in Mark as Read: $e');
                                                                  shouldSkipAd =
                                                                      true;
                                                                }

                                                                // If should skip ad (offline/low internet), navigate directly
                                                                if (shouldSkipAd) {
                                                                        MarkAsReadScreen
                                                                            .open(
                                                                        ReadedChapter: controller
                                                                            .selectedChapter
                                                                            .value,
                                                                        RededBookName: controller
                                                                            .selectedBook
                                                                            .value,
                                                                        SelectedBookChapterCount: controller
                                                                            .selectedBookChapterCount
                                                                            .value,
                                                                        );
                                                                  return;
                                                                }

                                                                // Only show ad if online with good connection
                                                                      if (_adService.interstitialAd !=
                                                                        null &&
                                                                          controller.adFree.value ==
                                                                        false) {
                                                                  // Check if 3 minutes have passed since last ad
                                                                  final canShowAd =
                                                                      await _canShowMarkAsReadAd();
                                                                  if (canShowAd) {
                                                                    print(
                                                                        'Load Interstitial Ad');
                                                                    await _saveMarkAsReadAdTime();
                                                                    // Show ad FIRST, wait for dismissal, THEN navigate
                                                                    try {
                                                                            await _showMarkAsReadAdPausingAudio();
                                                                    } catch (e) {
                                                                            debugPrint('Error showing ad in Mark as Read: $e');
                                                                      // If ad fails, proceed anyway
                                                                    }
                                                                    // Navigate AFTER ad is dismissed
                                                                          MarkAsReadScreen
                                                                              .open(
                                                                            ReadedChapter:
                                                                                controller.selectedChapter.value,
                                                                            RededBookName:
                                                                                controller.selectedBook.value,
                                                                            SelectedBookChapterCount:
                                                                                controller.selectedBookChapterCount.value,
                                                                          );
                                                                  } else {
                                                                    // Ad shown recently, skip ad but still navigate
                                                                          MarkAsReadScreen
                                                                              .open(
                                                                            ReadedChapter:
                                                                                controller.selectedChapter.value,
                                                                            RededBookName:
                                                                                controller.selectedBook.value,
                                                                            SelectedBookChapterCount:
                                                                                controller.selectedBookChapterCount.value,
                                                                          );
                                                                  }
                                                                } else {
                                                                  print(
                                                                      'Not Load Interstitial Ad');
                                                                        MarkAsReadScreen
                                                                            .open(
                                                                        ReadedChapter: controller
                                                                            .selectedChapter
                                                                            .value,
                                                                        RededBookName: controller
                                                                            .selectedBook
                                                                            .value,
                                                                        SelectedBookChapterCount: controller
                                                                            .selectedBookChapterCount
                                                                            .value,
                                                                        );

                                                                  // Get.to(() =>
                                                                  //     MarkAsReadScreen(
                                                                  //       ReadedChapter: controller
                                                                  //           .selectedChapter
                                                                  //           .value,
                                                                  //       RededBookName: controller
                                                                  //           .selectedBook
                                                                  //           .value,
                                                                  //       SelectedBookChapterCount: controller
                                                                  //           .selectedBookChapterCount
                                                                  //           .value,
                                                                  //     ));
                                                                }
                                                              },
                                                            );
                                                          } else {
                                                            controller
                                                                .isReadLoad
                                                                .value = true;
                                                                  if (int.tryParse(controller
                                                                        .bookReadPer
                                                                        .value) ==
                                                                0) {
                                                            } else {
                                                              double readPer = (100 *
                                                                      1) /
                                                                        double.parse(controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                                    double finalRead = double.parse(controller
                                                                          .bookReadPer
                                                                          .value
                                                                          .toString()) -
                                                                      readPer;
                                                              DBHelper()
                                                                  .updateBookData(
                                                                            int.parse(controller.selectedBookId.value.toString()),
                                                                      "read_per",
                                                                            finalRead.toStringAsFixed(1).toString())
                                                                        .then((value) {});
                                                                  }
                                                                  for (var i =
                                                                          0;
                                                                i <
                                                                    controller
                                                                        .selectedBookContent
                                                                        .length;
                                                                i++) {
                                                              await DBHelper()
                                                                  .updateVersesData(
                                                                            int.parse(controller.selectedBookContent[i].id
                                                                          .toString()),
                                                                      "is_read",
                                                                      "no")
                                                                  .then(
                                                                      (value) {});
                                                              var data = VerseBookContentModel(
                                                                  id: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .id,
                                                                  bookNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .bookNum,
                                                                  chapterNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .chapterNum,
                                                                  verseNum: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .verseNum,
                                                                  content: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .content,
                                                                        isBookmarked: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isBookmarked,
                                                                        isHighlighted: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isHighlighted,
                                                                  isNoted: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .isNoted,
                                                                        isUnderlined: controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isUnderlined,
                                                                        isRead:
                                                                            "no");
                                                                    controller.selectedBookContent[
                                                                            i] =
                                                                        data;
                                                            }
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        200),
                                                                () {
                                                              controller
                                                                  .isReadLoad
                                                                  .value = false;
                                                            });
                                                          }
                                                        });
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 200,
                                                      height: 40,
                                                            decoration:
                                                                BoxDecoration(
                                                        color: controller
                                                                    .selectedBookContent[
                                                                        0]
                                                                    .isRead ==
                                                                "no"
                                                                  ? Colors
                                                                      .black38
                                                            : CommanColor
                                                                .whiteLightModePrimary(
                                                                    context),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    5)),
                                                        boxShadow: [
                                                          const BoxShadow(
                                                              color: Colors
                                                                  .black26,
                                                                    blurRadius:
                                                                        2)
                                                        ],
                                                      ),
                                                      child: Center(
                                                          child: controller
                                                                      .isReadLoad
                                                                      .value ==
                                                                  false
                                                              ? Text(
                                                                        controller.selectedBookContent[0].isRead ==
                                                                          "no"
                                                                      ? 'Mark as Read'
                                                                      : "Marked as Read",
                                                                  style: TextStyle(
                                                                            letterSpacing: BibleInfo
                                                                              .letterSpacing,
                                                                      fontSize: screenWidth > 450
                                                                                ? BibleInfo.fontSizeScale * 20
                                                                                : BibleInfo.fontSizeScale * 14,
                                                                            fontWeight: FontWeight.w500,
                                                                            color: controller.selectedBookContent[0].isRead == "no" ? Colors.white : CommanColor.darkModePrimaryWhite(context)),
                                                                )
                                                              : const SizedBox(
                                                                        height:
                                                                            22,
                                                                        width:
                                                                            22,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                          color:
                                                                              Colors.white,
                                                                    strokeWidth:
                                                                        2.2,
                                                                  ))),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : index ==
                                                        controller
                                                                .selectedBookContent
                                                          .length -
                                                      1
                                              ? Obx(() => Column(
                                                    children: [
                                                      Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 15),
                                                              width:
                                                                  MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                              color: Colors
                                                                  .transparent,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            GestureDetector(
                                                                    onTap:
                                                                        () async {
                                                                      await SharPreferences.setString(
                                                                        'OpenAd',
                                                                        '1');
                                                                await DBHelper()
                                                                    .db
                                                                    .then(
                                                                        (value) {
                                                                  value!
                                                                            .rawQuery("SELECT * From book WHERE book_num = ${int.parse(controller.selectedBookNum.value)}")
                                                                            .then((value) async {
                                                                    controller
                                                                        .bookReadPer
                                                                              .value = value[0]["read_per"].toString();
                                                                          if (controller.selectedBookContent[1].isRead ==
                                                                        "no") {
                                                                            if (controller.bookReadPer.value ==
                                                                          "0") {
                                                                              double readPer = (100 * 1) / double.parse(controller.selectedBookChapterCount.value.toString());
                                                                              await DBHelper().updateBookData(int.parse(controller.selectedBookId.value.toString()), "read_per", readPer.toStringAsFixed(1).toString()).then((value) {});
                                                                      } else {
                                                                              double readPer = (100 * 1) / double.parse(controller.selectedBookChapterCount.value.toString());
                                                                              double finalRead = double.parse(controller.bookReadPer.value.toString()) + readPer;
                                                                              await DBHelper().updateBookData(int.parse(controller.selectedBookId.value.toString()), "read_per", finalRead.toStringAsFixed(1).toString()).then((value) {});
                                                                            }
                                                                            controller.isReadLoad.value =
                                                                                true;
                                                                            for (var i = 0;
                                                                          i < controller.selectedBookContent.length;
                                                                          i++) {
                                                                              await DBHelper().updateVersesData(int.parse(controller.selectedBookContent[i].id.toString()), "is_read", "yes").then((value) {});
                                                                              var data = VerseBookContentModel(id: controller.selectedBookContent[i].id, bookNum: controller.selectedBookContent[i].bookNum, chapterNum: controller.selectedBookContent[i].chapterNum, verseNum: controller.selectedBookContent[i].verseNum, content: controller.selectedBookContent[i].content, isBookmarked: controller.selectedBookContent[i].isBookmarked, isHighlighted: controller.selectedBookContent[i].isHighlighted, isNoted: controller.selectedBookContent[i].isNoted, isUnderlined: controller.selectedBookContent[i].isUnderlined, isRead: "yes");
                                                                              controller.selectedBookContent[i] = data;
                                                                            }

                                                                            Future.delayed(
                                                                              const Duration(milliseconds: 200),
                                                                        () async {
                                                                                controller.isReadLoad.value = false;

                                                                          // Check internet connectivity first - if offline/low internet, skip ad and navigate directly
                                                                                bool shouldSkipAd = false;
                                                                          try {
                                                                                  final hasInternet = await InternetConnection().hasInternetAccess;
                                                                            if (!hasInternet) {
                                                                              // Offline - skip ad and navigate directly
                                                                              shouldSkipAd = true;
                                                                            } else {
                                                                              // Check if mobile only connection (likely 2G/slow) - skip ad
                                                                              final connectivityResult = await Connectivity().checkConnectivity();
                                                                              final isMobileOnly = connectivityResult.contains(ConnectivityResult.mobile) && !connectivityResult.contains(ConnectivityResult.wifi) && !connectivityResult.contains(ConnectivityResult.ethernet);
                                                                              if (isMobileOnly) {
                                                                                // Low internet (2G/mobile only) - skip ad and navigate directly
                                                                                shouldSkipAd = true;
                                                                              }
                                                                            }
                                                                          } catch (e) {
                                                                            // If connectivity check fails, skip ad and proceed
                                                                            debugPrint('Connectivity check error in Mark as Read: $e');
                                                                                  shouldSkipAd = true;
                                                                          }

                                                                          // If should skip ad (offline/low internet), navigate directly
                                                                          if (shouldSkipAd) {
                                                                                  MarkAsReadScreen.open(
                                                                                  ReadedChapter: controller.selectedChapter.value,
                                                                                  RededBookName: controller.selectedBook.value,
                                                                                  SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  );
                                                                            return;
                                                                          }

                                                                          // Only show ad if online with good connection
                                                                                if (_adService.interstitialAd != null && controller.adFree.value == false) {
                                                                            // Check if 3 minutes have passed since last ad
                                                                                  final canShowAd = await _canShowMarkAsReadAd();
                                                                            if (canShowAd) {
                                                                              print('Load Interstitial Ad');
                                                                              await _saveMarkAsReadAdTime();
                                                                              // Show ad FIRST, wait for dismissal, THEN navigate
                                                                              try {
                                                                                      await _showMarkAsReadAdPausingAudio();
                                                                              } catch (e) {
                                                                                debugPrint('Error showing ad in Mark as Read: $e');
                                                                                // If ad fails, proceed anyway
                                                                              }
                                                                              // Navigate AFTER ad is dismissed
                                                                                    MarkAsReadScreen.open(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                    );
                                                                            } else {
                                                                              // Ad shown recently, skip ad but still navigate
                                                                                    MarkAsReadScreen.open(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                    );
                                                                            }
                                                                          } else {
                                                                            print('Not Load Interstitial Ad');
                                                                                  MarkAsReadScreen.open(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  );
                                                                          }
                                                                        },
                                                                      );
                                                                    } else {
                                                                            controller.isReadLoad.value =
                                                                                true;
                                                                            if (controller.bookReadPer.value ==
                                                                          0) {
                                                                      } else {
                                                                              double readPer = (100 * 1) / double.parse(controller.selectedBookChapterCount.value.toString());
                                                                              double finalRead = double.parse(controller.bookReadPer.value.toString()) - readPer;
                                                                              await DBHelper().updateBookData(int.parse(controller.selectedBookId.value.toString()), "read_per", finalRead.toStringAsFixed(1).toString()).then((value) {});
                                                                            }
                                                                            for (var i = 0;
                                                                          i < controller.selectedBookContent.length;
                                                                          i++) {
                                                                              await DBHelper().updateVersesData(int.parse(controller.selectedBookContent[i].id.toString()), "is_read", "no").then((value) {});
                                                                              var data = VerseBookContentModel(id: controller.selectedBookContent[i].id, bookNum: controller.selectedBookContent[i].bookNum, chapterNum: controller.selectedBookContent[i].chapterNum, verseNum: controller.selectedBookContent[i].verseNum, content: controller.selectedBookContent[i].content, isBookmarked: controller.selectedBookContent[i].isBookmarked, isHighlighted: controller.selectedBookContent[i].isHighlighted, isNoted: controller.selectedBookContent[i].isNoted, isUnderlined: controller.selectedBookContent[i].isUnderlined, isRead: "no");
                                                                              controller.selectedBookContent[i] = data;
                                                                            }
                                                                            Future.delayed(const Duration(milliseconds: 200),
                                                                                () {
                                                                              controller.isReadLoad.value = false;
                                                                      });
                                                                    }
                                                                  });
                                                                });
                                                              },
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          40,
                                                                decoration:
                                                                    BoxDecoration(
                                                                        color: controller.selectedBookContent[1].isRead ==
                                                                                "no"
                                                                            ? Colors.black38
                                                                            : CommanColor.whiteLightModePrimary(context),
                                                                        borderRadius: const BorderRadius
                                                                          .all(
                                                                            Radius.circular(5)),
                                                                  boxShadow: [
                                                                    const BoxShadow(
                                                                              color: Colors.black26,
                                                                              blurRadius: 2)
                                                                  ],
                                                                ),
                                                                child: Center(
                                                                          child: controller.isReadLoad.value == false
                                                                        ? Text(
                                                                                  controller.selectedBookContent[1].isRead == "no" ? 'Mark as Read' : "Marked as Read",
                                                                                  style: TextStyle(letterSpacing: BibleInfo.letterSpacing, fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 20 : BibleInfo.fontSizeScale * 14, fontWeight: FontWeight.w500, color: controller.selectedBookContent[1].isRead == "no" ? Colors.white : CommanColor.darkModePrimaryWhite(context)),
                                                                          )
                                                                        : const SizedBox(
                                                                                  height: 22,
                                                                                  width: 22,
                                                                                  child: CircularProgressIndicator(
                                                                              color: Colors.white,
                                                                              strokeWidth: 2.2,
                                                                            ))),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      const Divider(
                                                          thickness: 2),

                                                      ///NEW AD BANNER
                                                      if (controller
                                                                  .popupBannerAdHome !=
                                                              null &&
                                                          controller
                                                              .isPopupBannerAdHomeLoaded
                                                              .value &&
                                                                controller
                                                                        .adFree
                                                                  .value ==
                                                              false)
                                                        Builder(
                                                                builder:
                                                                    (context) {
                                                            try {
                                                                    final ad =
                                                                        controller
                                                                  .popupBannerAdHome!;
                                                              // Check if ad has valid size (indicates it's loaded)
                                                              if (ad.size.width >
                                                                      0 &&
                                                                  ad.size.height >
                                                                      0) {
                                                                return Padding(
                                                                        padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              20,
                                                                          bottom:
                                                                              40),
                                                                  child:
                                                                      SizedBox(
                                                                    height: ad
                                                                        .size
                                                                        .height
                                                                        .toDouble(),
                                                                    width: ad
                                                                        .size
                                                                        .width
                                                                        .toDouble(),
                                                                          child:
                                                                              AdWidget(ad: ad),
                                                                  ),
                                                                );
                                                              }
                                                            } catch (e) {
                                                              debugPrint(
                                                                  'Error displaying ad: $e');
                                                            }
                                                            return const SizedBox
                                                                .shrink();
                                                          },
                                                        ),
                                                    ],
                                                  ))
                                              : const SizedBox(),
                                            p.Provider.of<ThemeProvider>(
                                                            context)
                                                  .currentCustomTheme ==
                                              AppCustomTheme.lightbrown
                                          ? controller.selectedBookContent
                                                      .length !=
                                                  index + 1
                                              ? Padding(
                                                  padding:
                                                            const EdgeInsets
                                                                .only(top: 12),
                                                  child: Row(
                                                          children:
                                                              List.generate(
                                                        150 ~/ 3,
                                                                  (index) =>
                                                                      Expanded(
                                                                        child:
                                                                            Container(
                                                                          color: index % 2 == 0
                                                                              ? Colors.transparent
                                                                              : Colors.grey,
                                                                          height:
                                                                              2,
                                                              ),
                                                            )),
                                                  ),
                                                )
                                              : SizedBox()
                                          : SizedBox(),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

//share and rating
  void showMainFeedbackDialog(BuildContext context) {
    unawaited(_markRatingUiOpening());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;

        return Dialog(
          backgroundColor: CommanColor.white,
          insetPadding: isTablet ? EdgeInsets.symmetric(horizontal: 100) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                  height: 79,
                  width: 79,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: AssetImage(Images.appIcon1024))),
                ),
                // const Icon(Icons.menu_book, size: 48, color: Colors.brown),
                const SizedBox(height: 10),
                Text(
                  'How are you enjoying ${BibleInfo.bible_shortName} so far?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                textWithTrailingEmoji(
                  prefix:
                      'Your feedback helps us improve the app and serve you better. ',
                  emoji: '💛',
                  emojiFontSize: isTablet ? 15 : 14,
                  prefixStyle: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _buildEmojiOption(
                  context,
                  emoji: '😍',
                  text: 'Love It',
                  color: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2D6A4F),
                  onTap: () => _showRateAppDialog(context),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: '😊',
                  text: 'It\'s Good',
                  color: const Color(0xFFFFEDD5),
                  textColor: const Color(0xFF9A3412),
                  onTap: () => _showFeedbackDialog(context, '😊'),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: '😔',
                  text: 'Needs Improvement',
                  color: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFFB91C1C),
                  onTap: () => _showFeedbackDialog(context, '😔'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      unawaited(_markRatingUiClosed());
    });
  }

  Widget _buildEmojiOption(BuildContext context,
      {required String emoji,
      required String text,
      required Color color,
      required Color textColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: emojiTextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: textColor.withOpacity(0.8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    unawaited(_markRatingUiOpening());
    Navigator.of(context).pop(); // close previous dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isTablet = MediaQuery.of(dialogContext).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;
        return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: dialogWidth,
            child: ThanksForLoveRatingDialogContent(
              onClose: () => Navigator.of(dialogContext).pop(),
              onRate: () async {
                Navigator.pop(dialogContext);
                    // Rate us: only block when connectivity explicitly reports none (avoid false "no internet" on 5G etc.)
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (connectivityResult.isNotEmpty &&
                        connectivityResult.first == ConnectivityResult.none) {
                      Constants.showToast("Check your Internet connection");
                      return;
                    }
                    await SharPreferences.setString('OpenAd', '1');
                    _requestReview();
                  },
              onMaybeLater: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    ).whenComplete(() {
      unawaited(_markRatingUiClosed());
    });
  }

  Future<void> _requestReview() async {
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

  void _showFeedbackDialog(BuildContext context, String emoji) {
    unawaited(_markRatingUiOpening());
    Navigator.of(context).pop(); // close previous dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;

        return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                emojiText(emoji, fontSize: 40),
                const SizedBox(height: 15),
                const Text(
                  "Thanks! We'd love to hear your thoughts..",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Got a suggestion to help us improve?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Add your feedback logic here
                    await SharPreferences.setString('OpenAd', '1');
                    final DeviceInfoPlugin deviceInfoPlugin =
                        DeviceInfoPlugin();
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

                    // Open in-app feedback screen instead of chat
                    Get.to(() => const FeedbackWebView());
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  child: Text(
                    "Share Feedback",
                    style: TextStyle(
                      color: CommanColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      unawaited(_markRatingUiClosed());
    });
  }

  // Helper methods extracted from the initState
  Future<void> _initializeRatingDialog(GetXState state) async {
    await Future.delayed(Duration.zero, () async {
      final saveRating =
          await SharPreferences.getInt(SharPreferences.saveRating) ?? 0;
      final lastViewRatingDateTime =
          await SharPreferences.getString(SharPreferences.lastViewTime) ?? "";
      final lastRatingDateTime =
          await SharPreferences.getString(SharPreferences.ratingDateTime) ?? "";

      if (lastRatingDateTime.isNotEmpty) {
        final startTime =
            DateFormat('dd-MM-yyyy HH:mm').parse(lastViewRatingDateTime);
        final currentTime = DateTime.now();
        final diffDays = currentTime.difference(startTime).inDays;

        if (saveRating <= 4 && diffDays > 3) {
          Future.delayed(Duration(minutes: 2),
              () => _showRatingDialog(state, currentTime));
        }
      }
    });
  }

  void _showRatingDialog(GetXState state, DateTime currentTime) {
    unawaited(_markRatingUiOpening());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 15),
          content: _buildRatingDialogContent(state, currentTime),
        );
      },
    ).whenComplete(() {
      unawaited(_markRatingUiClosed());
    });
  }

  Widget _buildRatingDialogContent(GetXState state, DateTime currentTime) {
    return ValueListenableBuilder<int>(
      valueListenable: _rating,
      builder: (context, int value, Widget? child) {
        final (feedbackText, feedbackText1, style, style1, colour) =
            _getFeedbackContent(value);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/feedbacklogo.png",
              height: 140,
              width: 140,
              color: Colors.brown,
            ),
            Text(feedbackText, style: style1),
            const SizedBox(height: 16),
            Text(feedbackText1, style: style),
            const SizedBox(height: 10),
            _buildStarRating(state, value),
            const SizedBox(height: 16),
            _buildRatingButtons(state, value, currentTime, colour),
          ],
        );
      },
    );
  }

  (String, String, TextStyle, TextStyle, Color?) _getFeedbackContent(
      int value) {
    if (value == 0) {
      return (
        'Leave Your Experience,',
        'Let it Shine Bright',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.grey[500],
      );
    } else if (value <= 3) {
      return (
        'Please help us',
        'with your valuable feedback',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.brown[500],
      );
    } else {
      return (
        'Great!',
        'Give your rating on store',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.brown[500],
      );
    }
  }

  Widget _buildStarRating(GetXState state, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          5,
          (i) => GestureDetector(
                onTap: () {
                  _setRating(i + 1);
                  //  state.controller!.rating.value = i + 1;
                },
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: value >= i + 1 ? Colors.brown : Colors.grey,
                ),
              )),
    );
  }

  Widget _buildRatingButtons(
      GetXState state, int value, DateTime currentTime, Color? colour) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[500]),
          child: const Text('Not Now', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pop();
            SharPreferences.setString(
                SharPreferences.lastViewTime, "$currentTime");
          },
        ),
        const SizedBox(width: 50),
        ValueListenableBuilder<bool>(
          valueListenable: _showFeedbackButton,
          builder: (context, bool showButton, Widget? child) {
            return SizedBox(
              height: 40,
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: value == 0 ? Colors.grey[500] : colour,
                  disabledBackgroundColor: Colors.grey[500],
                ),
                child: Text(
                  showButton ? 'Rate Us' : 'Feedback',
                  style: const TextStyle(color: Colors.white),
                ),
                // Keep tappable after stars are selected (value > 0).
                onPressed: value == 0
                    ? null
                    : () => _handleRatingButtonPress(
                        state, showButton, currentTime),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleRatingButtonPress(
      GetXState state, bool showButton, DateTime currentTime) async {
    Get.back();
    // SharPreferences.setInt(
    //     SharPreferences.saveRating, state.controller!.rating.value);
    SharPreferences.setString(SharPreferences.ratingDateTime, "$currentTime");

    if (showButton) {
      await _launchStoreRating();
    } else {
      await _launchFeedbackForm();
    }
  }

  Future<void> _launchStoreRating() async {
    if (Platform.isAndroid) {
      final appPackageName = (await PackageInfo.fromPlatform()).packageName;
      try {
        await launchUrl(Uri.parse("market://details?id=$appPackageName"));
      } on PlatformException {
        await launchUrl(Uri.parse(
            "https://play.google.com/store/apps/details?id=$appPackageName"));
      }
    } else if (Platform.isIOS) {
      await launchUrl(
          Uri.parse("https://itunes.apple.com/app/id${BibleInfo.apple_AppId}"));
    }
  }

  /// iOS-style accordion drawer (visual only). Callbacks keep existing navigation logic.
  Drawer _buildIosHomeDrawer({
    required BuildContext context,
    required DashBoardController controller,
    required String bibleName,
    required double screenWidth,
  }) {
    final isPremium = controller.adFree.value;
    final showPremiumBanner = !(controller.isAdsCompletlyDisabled.value) &&
        (controller.isSubscriptionEnabled ?? false) &&
        !isPremium;

    Future<void> openPaywallFromDrawer() async {
      adsIcon = false;
      await SharPreferences.setString('OpenAd', '1');
      final sixMonthPlan = await SharPreferences.getString('sixMonthPlan') ??
          BibleInfo.sixMonthPlanid;
      final oneYearPlan = await SharPreferences.getString('oneYearPlan') ??
          BibleInfo.oneYearPlanid;
      final lifeTimePlan = await SharPreferences.getString('lifeTimePlan') ??
          BibleInfo.lifeTimePlanid;
      SubscriptionScreen.openPaywallStacked(
        sixMonthPlan: sixMonthPlan,
        oneYearPlan: oneYearPlan,
        lifeTimePlan: lifeTimePlan,
        checkad: 'theme',
      );
    }

    void showSubscriptionInfoSheet() {
      final expiryRaw = '${controller.RewardAdExpireDate}';
      if (DateTime.tryParse(expiryRaw) == null) return;
      final expiryDate = DateTime.parse(expiryRaw);
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (BuildContext sheetContext) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                height: MediaQuery.of(sheetContext).size.height * 0.30,
                child: SingleChildScrollView(
                  physics: const ScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/feedbacklogo.png",
                            height: 120,
                            width: 120,
                            color: CommanColor.lightDarkPrimary(sheetContext),
                          ),
                        ],
                      ),
                      Text(
                        'Subscription Info',
                        style: TextStyle(
                          letterSpacing: BibleInfo.letterSpacing,
                          fontSize: BibleInfo.fontSizeScale * 16,
                          color: CommanColor.lightDarkPrimary(sheetContext),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildSubscriptionInfoDetails(
                        context: sheetContext,
                        expiryDate: expiryDate,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 15,
                child: InkWell(
                  child: Icon(
                    Icons.close,
                    color: CommanColor.lightDarkPrimary(sheetContext),
                    size: 25,
                  ),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ),
            ],
          );
        },
      );
    }

    return Drawer(
      backgroundColor: IosStyleAppDrawer.backgroundOf(context),
      width: MediaQuery.of(context).size.width * 0.82,
      child: IosStyleAppDrawer(
        appTitle: bibleName,
        planLabel: isPremium ? 'Premium Active' : 'Free Plan',
        isPremium: isPremium,
        showPremiumBanner: showPremiumBanner,
        showAskAnything: BibleInfo.chat == 1,
        showBooks: controller.bookAdsStatus.value == 1,
        showEProducts: BibleInfo.enableEShop == true,
        onAccountTap: () {
          Future.microtask(() {
            Get.to(
              () => isLoggedIn
                  ? const ProfileScreen()
                  : LoginScreen(hasSkip: false),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350),
            );
            if (controller.adFree.value == false) {
              Future(() {
                controller.bannerAd?.dispose();
                controller.bannerAd?.load();
              });
            }
          });
        },
        onUpgradeTap: () {
          openPaywallFromDrawer();
        },
        onPremiumInfoTap: () {
          if (DateTime.tryParse('${controller.RewardAdExpireDate}') != null) {
            showSubscriptionInfoSheet();
          } else if (controller.isSubscriptionEnabled ?? false) {
            openPaywallFromDrawer();
          }
        },
        onDailyVerseTap: () {
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          Get.to(() => const DailyVerse(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350));
        },
        onVersesByTopicTap: () {
          Get.to(
            () => const VerseTopicsScreen(),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 350),
          );
        },
        onFaithJourneyTap: () {
          Future.microtask(() {
            Get.to(
              () => const DailyJourneyScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350),
            );
          });
        },
        onAskAnythingTap: () async {
          Get.to(ChatScreen());
        },
        onPrayerGuidanceTap: () {
          Future.microtask(() {
            Get.to(
              () => const PrayerGuidanceScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350),
            );
          });
        },
        onMyLibraryTap: () {
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          Get.to(() => const LibraryScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350));
        },
        onCalendarTap: () {
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          Get.to(() => const CalendarScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350));
        },
        onWallpapersTap: () async {
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            Constants.showToast('No internet connection');
            return;
          }
          try {
            final connectionSpeed = await InternetSpeedChecker.checkSpeed(
              timeout: const Duration(seconds: 5),
            );
            final isSlowConnection =
                connectionSpeed == null || connectionSpeed > 5000;
            if (isSlowConnection) {
              Constants.showToast(kCheckInternetConnectionMessage);
            }
          } catch (_) {
            Constants.showToast(kCheckInternetConnectionMessage);
          }
          Get.to(() => const WallpaperScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350));
        },
        onQuotesTap: () async {
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            Constants.showToast('No internet connection');
            return;
          }
          try {
            final connectionSpeed = await InternetSpeedChecker.checkSpeed(
              timeout: const Duration(seconds: 5),
            );
            final isSlowConnection =
                connectionSpeed == null || connectionSpeed > 5000;
            if (isSlowConnection) {
              Constants.showToast(kCheckInternetConnectionMessage);
            }
          } catch (_) {
            Constants.showToast(kCheckInternetConnectionMessage);
          }
          Get.to(() => const QuoteScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350));
        },
        onShareTap: () async {
          final appPackageName = (await PackageInfo.fromPlatform()).packageName;
          String message = '';
          final appid = BibleInfo.apple_AppId;
          if (Platform.isAndroid) {
            message =
                "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://play.google.com/store/apps/details?id=$appPackageName";
          } else if (Platform.isIOS) {
            message =
                "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://itunes.apple.com/app/id$appid";
          }
          // Include referrer ID when available so invitees can enter it on Sign Up.
          try {
            final cached = await CacheNotifier()
                .readCache(key: OwnReferralCodeDialog.referralCacheKey);
            final referralCode = cached?.toString().trim() ?? '';
            if (referralCode.isNotEmpty && message.isNotEmpty) {
              message =
                  "$message\n\nUse my referral code when you sign up: $referralCode";
            }
          } catch (_) {}
          if (message.isNotEmpty) {
            Share.share(
              message,
              sharePositionOrigin: Rect.fromPoints(
                const Offset(2, 2),
                const Offset(3, 3),
              ),
            );
          }
        },
        onPrayerWallTap: () async {
          await SharPreferences.setString('OpenAd', '1');
          Get.to(
            () => const PrayerWallScreen(),
            transition: Transition.cupertinoDialog,
            duration: const Duration(milliseconds: 300),
          );
        },
        onTelegramTap: () {
          Get.to(
            () => const SocialLinksScreen(),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 350),
          );
        },
        onWidgetsTap: () {
          Future.microtask(() {
            Get.to(
              () => const AddWidgetIntroScreen(),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 350),
            );
          });
        },
        onBackupTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const MainBackupDialog(),
          );
        },
        onSettingsTap: () {
          SharPreferences.getBoolean(SharPreferences.isNotificationOn)
              .then((value) {
            // Default OFF when unset so denied permission never opens as ON.
            final natificationValue = value ?? false;
            Future.microtask(() {
              Get.to(
                () => SettingScreen(
                  notificationValue: natificationValue,
                ),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 350),
              )?.then((_) async {
                final fontSize = await SharPreferences.getString(
                    SharPreferences.selectedFontSize);
                controller.fontSize.value =
                    fontSize == null ? 19.0 : double.parse(fontSize.toString());
                final fontFamily = await SharPreferences.getString(
                    SharPreferences.selectedFontFamily);
                controller.selectedFontFamily.value = fontFamily ?? "Arial";
              });
            });
          });
        },
        onBooksTap: () async {
          await SharPreferences.setString('OpenAd', '1');
          if (controller.adFree.value == false) {
            controller.bannerAd?.dispose();
            controller.bannerAd?.load();
          }
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            Constants.showToast('No internet connection');
            return;
          }
          try {
            final connectionSpeed = await InternetSpeedChecker.checkSpeed(
              timeout: const Duration(seconds: 5),
            );
            final isSlowConnection =
                connectionSpeed == null || connectionSpeed > 5000;
            if (isSlowConnection) {
              Constants.showToast(kCheckInternetConnectionMessage);
            }
          } catch (_) {
            Constants.showToast(kCheckInternetConnectionMessage);
          }
          Get.to(
            () => BooksScreen(bookAdId: controller.bookAdsAppId.value),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 350),
          );
        },
        onMoreAppsTap: () async {
          await SharPreferences.setString('OpenAd', '1');
          final hasInternet = await InternetConnection().hasInternetAccess;
          if (!hasInternet) {
            Constants.showToast('No internet connection');
            return;
          }
          try {
            final connectionSpeed = await InternetSpeedChecker.checkSpeed(
              timeout: const Duration(seconds: 5),
            );
            final isSlowConnection =
                connectionSpeed == null || connectionSpeed > 5000;
            if (isSlowConnection) {
              Constants.showToast(kCheckInternetConnectionMessage);
            }
          } catch (_) {
            Constants.showToast(kCheckInternetConnectionMessage);
          }
          if (controller.adFree.value == false) {
            Future(() {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            });
          }
          Get.to(
            () => const MoreAppsScreen(),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 350),
          );
        },
        onContactUsTap: () async {
          await _launchContactUsEmail();
        },
        onEProductsTap: () async {
          await SharPreferences.setString('OpenAd', '1');
          if (controller.adFree.value == false) {
            controller.bannerAd?.dispose();
            controller.bannerAd?.load();
          }
          Get.to(
            () => const EProductsScreen(),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 350),
          );
        },
      ),
    );
  }

  Future<void> _launchContactUsEmail() async {
    const email = 'support@bibleoffice.com';
    final pkg = await PackageInfo.fromPlatform();
    final subject =
        Uri.encodeComponent('${BibleInfo.bible_shortName} - Contact Us');
    final body = Uri.encodeComponent(
      '\n\n---\nApp: ${pkg.appName}\nVersion: ${pkg.version}\nPackage: ${pkg.packageName}',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Contact Us mailto error: $e');
    }
    if (!mounted) return;
    await Clipboard.setData(const ClipboardData(text: email));
    Constants.showToast(
      'No mail app found. $email copied to clipboard.',
      5000,
    );
  }

  Future<void> _launchFeedbackForm() async {
    // Open feedback screen
    Get.to(const FeedbackWebView());
  }

  /// Approximate average verse row height from current chapter scroll metrics.
  double _estimateReaderVerseExtent(ScrollMetrics metrics) {
    try {
      final controller = Get.find<DashBoardController>();
      final count = controller.selectedBookContent.length;
      if (count <= 0) return 100;
      final total = metrics.maxScrollExtent + metrics.viewportDimension;
      if (total <= 0) return 100;
      return (total / count).clamp(70.0, 200.0);
    } catch (_) {
      return 100;
    }
  }

  void _showReaderAppBarFromScroll() {
    _readerAppBarPinnedVisible = true;
    _readerAppBarPendingHide = false;
    _readerAppBarScrollUpIntent = false;
    _readerAppBarDragDelta = 0;
    _readerAppBarHiddenAnchorOffset = 0;
    if (!_showUI.value && mounted) {
      _showUI.value = true;
    }
  }

  void _handleReaderScrollForAppBar(
    ScrollNotification notification,
    double currentOffset,
  ) {
    if (notification.metrics.pixels < 0) {
      return;
    }
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      return;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _readerAppBarDragDelta = 0;
        _readerAppBarPendingHide = false;
        _readerAppBarUserScrollingDown = false;
        // Keep hide-anchor so upward distance still counts across pauses.
        if (notification.metrics.pixels <= 0 && !_showUI.value && mounted) {
          _showReaderAppBarFromScroll();
        }
        return;
      }

      if (notification.direction == ScrollDirection.reverse) {
        _readerAppBarPendingHide = false;
        _readerAppBarUserScrollingDown = false;
        if (_readerAppBarPinnedVisible) {
          _readerAppBarDragDelta = 0;
          return;
        }
          _readerAppBarScrollUpIntent = true;
        return;
      }

      if (notification.direction == ScrollDirection.forward) {
        _readerAppBarUserScrollingDown = true;
        _readerAppBarScrollUpIntent = false;
        _readerAppBarPendingHide = true;
        _readerAppBarDragDelta = 0;
        return;
      }
    }

    if (notification is! ScrollUpdateNotification) {
      return;
    }

    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) {
      return;
    }

    if (_readerAppBarPinnedVisible) {
      // Reading down — hide after small threshold (unchanged).
      if (delta > 0) {
        _readerAppBarDragDelta += delta;
        if (_readerAppBarDragDelta >= _kReaderAppBarToggleThreshold) {
          _readerAppBarPinnedVisible = false;
          _readerAppBarPendingHide = false;
          _readerAppBarScrollUpIntent = false;
          _readerAppBarDragDelta = 0;
          _readerAppBarHiddenAnchorOffset = currentOffset;
          if (_showUI.value && mounted) {
            _showUI.value = false;
          }
        }
      } else if (delta < 0) {
        _readerAppBarDragDelta = 0;
        _readerAppBarPendingHide = false;
      }
      return;
    }

    // Hidden — track deepest point, show after ~5–6 verses scrolled upward.
    if (currentOffset > _readerAppBarHiddenAnchorOffset) {
      _readerAppBarHiddenAnchorOffset = currentOffset;
    }

    final verseExtent = _estimateReaderVerseExtent(notification.metrics);
    final showAfterPixels = verseExtent * _kReaderAppBarShowVerseCount;
    final scrolledUp = _readerAppBarHiddenAnchorOffset - currentOffset;

    if (delta < 0 && scrolledUp >= showAfterPixels) {
      _showReaderAppBarFromScroll();
    } else if (notification.metrics.pixels <= 0) {
      // Fewer than 5–6 verses left above — show at chapter top.
      _showReaderAppBarFromScroll();
    }
  }

  bool _staleContentMatchesChapter(DashBoardController controller) {
    if (_lastVisibleChapterContent.isEmpty) return false;
    // Additive: require same book — chapter-number-only match re-shows the
    // previous book after switching books (e.g. both on chapter 1).
    final selectedNum = int.tryParse(controller.selectedBookNum.value.trim());
    if (selectedNum != null) {
      final contentBook = _lastVisibleChapterContent.first.bookNum?.toInt();
      if (contentBook == null || contentBook != selectedNum) return false;
    }
    final ch = int.tryParse(controller.selectedChapter.value) ?? 1;
    final safe = ch <= 0 ? 1 : ch;
    final zeroBased =
        _lastVisibleChapterContent.any((v) => (v.chapterNum ?? -1) == 0);
    final stored = zeroBased ? safe - 1 : safe;
    return _lastVisibleChapterContent
        .any((v) => v.chapterNum?.toInt() == stored);
  }

  bool _homeEntryRequiresContentReload() {
    final from = widget.From.toString();
    if (from == 'Chapter' ||
        from == 'Daily' ||
        from == 'chat' ||
        widget.fromSearch) {
      return true;
    }
    if (from == 'Read') {
      return widget.selectedBookForRead.toString().isNotEmpty &&
          widget.selectedChapterForRead.toString().isNotEmpty &&
          widget.selectedVerseNumForRead.toString().isNotEmpty;
    }
    return false;
  }

  void _initializeControllerState(GetXState<DashBoardController> state) {
    if (state.controller!.selectedChapter.value.isNotEmpty) {
      state.controller!.selectChapterChange.value =
          int.parse(state.controller!.selectedChapter.value);
    }

    state.controller!.selectedBookNumForRead.value =
        widget.selectedBookForRead.toString();
    state.controller!.selectedChapterForRead.value =
        widget.selectedChapterForRead.toString();
    state.controller!.selectedVerseForRead.value =
        widget.selectedVerseNumForRead.toString();
    state.controller!.selectedBookNameForRead.value =
        widget.selectedBookNameForRead.toString();
  }

  void _handleAdExpiration(GetXState<DashBoardController> state,
      {bool skipLoadApi = false}) async {
    final value =
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
    state.controller!.RewardAdExpireDate.value = value.toString();
    RewardAdExpireDate = value;
    debugPrint("RewardAdExpireDate is $RewardAdExpireDate");

    if (!skipLoadApi) {
    Future.delayed(Duration.zero, () {
      state.controller!.loadApi();
    });
    }

    if (value != null) {
      final currentDateTime = DateTime.now();
      final saveTime = DateTime.parse(value);
      final diff = currentDateTime.difference(saveTime).inDays;

      if (!diff.isNegative) {
        state.controller!.initBanner(adUnitId: '');
        //  state.controller!.initInterstitialAd(adUnitId: '');
        //  state.controller!.loadRewardedAd(adUnitId: '');
        SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
      } else {
        SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
        state.controller!.adFree.value = true;
        state.controller!.isGetRewardAd.value = true;
      }
    } else {
      state.controller!.initBanner(adUnitId: '');
      // state.controller!.initInterstitialAd(adUnitId: '');
      // state.controller!.loadRewardedAd(adUnitId: '');
    }
  }

  Future<void> _ensureHomeContentLoaded(
      GetXState<DashBoardController> state) async {
    final controller = state.controller;
    if (controller == null || !mounted) return;

    await controller.getSelectedChapterAndBook();
    if (!mounted || state.controller == null) return;

    final chapter = int.tryParse(controller.selectedChapter.value) ?? 1;

    // Additive: non-empty content is not enough — must match book + chapter
    // (shared controller can still hold the previous book's same chapter #).
    if (controller.selectedBookContent.isNotEmpty &&
        controller.displayedContentMatchesSelection()) {
      setState(() {});
      return;
    }

    if (controller.selectedBookContent.isNotEmpty &&
        !controller.displayedContentMatchesSelection()) {
      await controller.forceReloadSelectedChapter();
      if (!mounted || state.controller == null) return;
      if (controller.selectedBookContent.isNotEmpty &&
          controller.displayedContentMatchesSelection()) {
        setState(() {});
        return;
      }
    }

    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    final preloadFuture =
        downloadProvider.preloadBibleDataFromDatabaseIfNeeded();

    for (var attempt = 0; attempt < 5; attempt++) {
      if (!mounted || state.controller == null) return;
      if (controller.selectedBookContent.isNotEmpty &&
          controller.displayedContentMatchesSelection()) {
        return;
      }

      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 150 * attempt));
      }

      await preloadFuture;
      if (!mounted || state.controller == null) return;

      if (controller.selectedBookContent.isEmpty ||
          !controller.displayedContentMatchesSelection()) {
        await controller.getSelectedChapterAndBook();
      }

      if ((controller.selectedBookContent.isEmpty ||
              !controller.displayedContentMatchesSelection()) &&
          downloadProvider.verseList.isNotEmpty) {
        final hydrated = await controller.hydrateChapterFromCachedVerses(
          downloadProvider.verseList,
          chapter,
        );
        if (hydrated &&
            mounted &&
            controller.displayedContentMatchesSelection()) {
          setState(() {});
          return;
        }
      }
    }

    if (!mounted || state.controller == null) return;
    if (controller.selectedBookContent.isEmpty) {
      _attemptedProviderChapterFallback = false;
      if (mounted) setState(() {});
    }
  }

  void _loadInitialData(GetXState<DashBoardController> state) {
    final controller = state.controller;
    if (controller == null) return;

    controller.selectedIndex.value = -1;

    () async {
      if (state.controller == null || !mounted) return;

      final hasReadSelection =
          widget.selectedBookForRead.toString().isNotEmpty &&
              widget.selectedChapterForRead.toString().isNotEmpty &&
              widget.selectedVerseNumForRead.toString().isNotEmpty;
      final isReadOrDaily =
          (widget.From.toString() == "Read" && hasReadSelection) ||
              widget.From.toString() == "Daily";
      final isFromChat = widget.From.toString() == "chat";

      // Set highlight for Read, Daily, or chat
      state.controller!.readHighlight.value = isReadOrDaily || isFromChat;

      if (isReadOrDaily || isFromChat) {
        // Use getBookContentForRead for Read, Daily, and chat to properly load content
        await state.controller!.getBookContentForRead();
      } else {
        // Use normal chapter loading for other flows
        await state.controller!.getSelectedChapterAndBook();
        await _ensureHomeContentLoaded(state);
      }

      if (state.controller == null || !mounted) return;
      await state.controller!.getFont();
      // When opened from Search, use default reading font instead of user-selected font
      if (widget.fromSearch) {
        state.controller!.selectedFontFamily.value = 'Arial';
        state.controller!.fontSize.value =
            MediaQuery.of(context).size.width > 450 ? 25.0 : 19.0;
      }
    }();

    Future.delayed(const Duration(seconds: 6), () {
      state.controller?.readHighlight.value = false;
    });

    Future.delayed(Duration.zero, () {
      final c = state.controller;
      if (c == null) return;
      final scrollController = c.autoScrollController.value;
      if (c.selectedBookContent.isNotEmpty && scrollController.hasClients) {
        return;
      }
      c.autoScrollController.value = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: c.scrollDirection,
      );
    });

    Future.delayed(const Duration(seconds: 1), () {
      final hasReadSelection =
          widget.selectedBookForRead.toString().isNotEmpty &&
              widget.selectedChapterForRead.toString().isNotEmpty &&
              widget.selectedVerseNumForRead.toString().isNotEmpty;
      if ((widget.From.toString() == "Read" && hasReadSelection) ||
          widget.From.toString() == "Daily" ||
          widget.From.toString() == "chat") {
        if (widget.selectedVerseNumForRead != null &&
            widget.selectedVerseNumForRead.toString().isNotEmpty) {
          try {
            final verseIndex =
                int.parse(widget.selectedVerseNumForRead.toString());

            // Wait for data to be loaded before scrolling and highlighting
            _waitForDataAndHighlight(state, verseIndex);
          } catch (e) {
            debugPrint('Error parsing verse index: $e');
            state.controller?.selectedIndex.value = -1;
          }
        } else {
          state.controller?.selectedIndex.value = -1;
        }
      }
    });
  }

  // Helper method to wait for data and then highlight verse
  void _waitForDataAndHighlight(
      GetXState<DashBoardController> state, int verseIndex,
      {int retryCount = 0}) {
    // Maximum retries to prevent infinite loop
    if (retryCount > 20) {
      debugPrint('Timeout waiting for data to load for verse highlighting');
      return;
    }

    // Check if data is loaded
    if (!state.controller!.isFetchContent.value) {
      // Data loading is complete
      if (state.controller!.selectedBookContent.isNotEmpty) {
        // Data is ready, scroll and highlight
        _scrollAndHighlightVerse(state, verseIndex);
      }
    } else {
      // Wait a bit and retry
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _waitForDataAndHighlight(state, verseIndex,
              retryCount: retryCount + 1);
        }
      });
    }
  }

  // Build empty content widget
  Widget _buildEmptyContentWithChapters(DashBoardController controller) {
    // Last-resort fallback: if DB returns empty for this chapter but we already
    // have verses cached in DownloadProvider (loaded at splash), populate from there.
    if (!_attemptedProviderChapterFallback) {
      _attemptedProviderChapterFallback = true;
      Future.microtask(() {
        try {
          final downloadProvider =
              Provider.of<DownloadProvider>(context, listen: false);
          if (downloadProvider.verseList.isEmpty) return;

          var bookNum = int.tryParse(controller.selectedBookNum.value) ?? 0;
          if (bookNum <= 0) {
            bookNum = 1;
          }
          final chapter = int.tryParse(controller.selectedChapter.value) ?? 1;
          final safeChapter = chapter <= 0 ? 1 : chapter;

          List<VerseBookContentModel> matches = downloadProvider.verseList
              .where((v) => (v.bookNum ?? -999) == bookNum)
              .where((v) =>
                  (v.chapterNum ?? -999) == (safeChapter - 1) ||
                  (v.chapterNum ?? -999) == safeChapter)
              .toList();

          // Legacy 1-based book_num fallback as well.
          if (matches.isEmpty && bookNum > 0) {
            final legacyBookNum = bookNum - 1;
            matches = downloadProvider.verseList
                .where((v) => (v.bookNum ?? -999) == legacyBookNum)
                .where((v) =>
                    (v.chapterNum ?? -999) == (safeChapter - 1) ||
                    (v.chapterNum ?? -999) == safeChapter)
                .toList();
            if (matches.isNotEmpty) {
              controller.selectedBookNum.value = legacyBookNum.toString();
              SharPreferences.setString(
                  SharPreferences.selectedBookNum, legacyBookNum.toString());
            }
          }
          // Inverse: prefs 0-based but verse list uses 1-based book indices.
          if (matches.isEmpty) {
            final oneBasedBook = bookNum + 1;
            matches = downloadProvider.verseList
                .where((v) => (v.bookNum ?? -999) == oneBasedBook)
                .where((v) =>
                    (v.chapterNum ?? -999) == (safeChapter - 1) ||
                    (v.chapterNum ?? -999) == safeChapter)
                .toList();
            if (matches.isNotEmpty) {
              controller.selectedBookNum.value = oneBasedBook.toString();
              SharPreferences.setString(
                  SharPreferences.selectedBookNum, oneBasedBook.toString());
            }
          }

          if (matches.isNotEmpty) {
            controller.selectedBookContent.value = matches.toSet().toList();
            controller.isFetchContent.value = false;
            if (mounted) setState(() {});
          }
        } catch (e) {
          debugPrint('testapp Provider fallback failed: $e');
        }
      });
    }

    // Still empty after DB + in-memory/provider fallbacks.
    final book = controller.selectedBook.value.toString().trim();
    final chapter = controller.selectedChapter.value.toString().trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: CommanColor.lightDarkPrimary(context).withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No content for this chapter',
              style: CommanStyle.bw16500(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Book: ${book.isEmpty ? "Selected Bible" : book} • Chapter: ${chapter.isEmpty ? "1" : chapter}',
              style: CommanStyle.placeholderText(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'If verses are missing, the selected Bible file may not be synced to this device yet. Please try again.',
              style: CommanStyle.placeholderText(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _attemptedProviderChapterFallback = false;
                controller.getSelectedChapterAndBook();
                if (mounted) setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to scroll to verse and highlight it
  void _scrollAndHighlightVerse(
      GetXState<DashBoardController> state, int verseIndex) {
    try {
      final contentLen = state.controller!.selectedBookContent.length;
      if (contentLen == 0) return;

      // Daily Verse_Num is 1-based; match by verse text then verse_num.
      final listIndex = widget.From.toString() == "Daily"
          ? resolveDailyVerseListIndex(
              verseIndex,
              state.controller!.selectedBookContent,
              versePlainText: widget.selectedVerseForRead?.toString(),
            )
          : widget.From.toString() == "chat"
              ? verseIndex - 1
              : verseIndex;
      final safeIndex = listIndex.clamp(0, contentLen - 1);

      state.controller!.scrollToIndex(safeIndex);

      if (widget.From.toString() == "chat" ||
          widget.From.toString() == "Daily" ||
          widget.From.toString() == "Read") {
        state.controller!.selectedIndex.value = safeIndex;
          state.controller!.readHighlight.value = true;

        Future.delayed(
            Duration(seconds: widget.From.toString() == "chat" ? 10 : 6), () {
            if (mounted) {
              state.controller?.readHighlight.value = false;
              state.controller?.selectedIndex.value = -1;
            }
          });
      } else {
        state.controller?.selectedIndex.value = -1;
      }
    } catch (e) {
      debugPrint('Error scrolling to verse: $e');
      state.controller?.selectedIndex.value = -1;
    }
  }

  Future<void> checkingappcount(List<ConnectivityResult> result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    appLaunchCount = prefs.getInt('launchCount') ?? 0;
    // appLaunchCount++;
    // debugPrint(" lanuchCount is - $appLaunchCount ");
    // if (appLaunchCount == 2) {
    //   // setState(() {
    //   //   appLaunchCount = 3;
    //   // });
    //   debugPrint(" lanuchCount 2 is - $appLaunchCount ");
    //   Future.delayed(
    //     Duration(minutes: 1),
    //     () async {
    //       await prefs.setInt('launchCount', 3);
    //       appLaunchCount = prefs.getInt('launchCount') ?? 0;
    //       debugPrint("lanuchCount 3 is - $appLaunchCount");
    //       await requestReview(result);
    //     },
    //   );
    // }

    // final currentDate = DateTime.now();
    final getLastOfferShown =
        await SharPreferences.getString(SharPreferences.offerenabled);
    if (getLastOfferShown == '1') {
      // appLaunchCountoffer = prefs.getInt('launchCountoffer') ?? 0;
      // appLaunchCountoffer++;
      debugPrint(" lanuchCount offer is - $appLaunchCountoffer ");
      // if (getLastOfferShown != null) {
      //   final lastOfferShownDate = DateTime.parse(getLastOfferShown);
      //   final diff = currentDate.difference(lastOfferShownDate);
      //   if (diff.inDays >
      //       (int.tryParse(controller.offerDays ?? '') ?? 1)) {
      //     await SharPreferences.setString(
      //         SharPreferences.lastOfferShown, currentDate.toString());
      //     showOfferDialog(controller);
      //   }
      // } else {
      //   await SharPreferences.setString(
      //       SharPreferences.lastOfferShown, currentDate.toString());
      // }
      if (appLaunchCountoffer == 3) {
        setState(() {
          appLaunchCountoffer = 4;
        });
        // Future.delayed(Duration(seconds: 10), () async {
        //   showOfferDialog(controller);
        //   await prefs.setInt('launchCountoffer', appLaunchCountoffer);
        // });
      } else {
        await prefs.setInt('launchCountoffer', appLaunchCountoffer);
      }
    }
  }

  void backupNotification({
    required BuildContext context,
    required String message,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            backgroundColor: CommanColor.white,
            insetPadding: screenWidth > 450
                ? const EdgeInsets.symmetric(horizontal: 120)
                : null,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 16,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: CommanColor.black,
                        fontSize: screenWidth > 450 ? 19 : null),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => LoginScreen(hasSkip: false),
                          transition: Transition.cupertino,
                          duration: const Duration(milliseconds: 350));
                    },
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: CommanColor.darkPrimaryColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          'Sign in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: screenWidth > 450
                                  ? BibleInfo.fontSizeScale * 19
                                  : BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w500,
                              color: CommanColor.white),
                        )),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: CommanColor.lightGrey1,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: screenWidth > 450
                                  ? BibleInfo.fontSizeScale * 19
                                  : BibleInfo.fontSizeScale * 14,
                              fontWeight: FontWeight.w400,
                              color: CommanColor.black),
                        )),
                  )
                ],
              ),
            ));
      },
    );
  }
}

/// Checks if personalized ads are allowed
Future<bool> isTrackingAllowed() async {
  try {
    // 1. Platform-specific tracking (iOS ATT)
    bool platformTrackingAllowed = true;
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      platformTrackingAllowed = status == TrackingStatus.authorized;
    }

    // 2. UMP consent status (for both platforms)
    final umpConsent = await ConsentInformation.instance.canRequestAds();

    // 3. Combined consent status
    return platformTrackingAllowed && umpConsent;
  } catch (e) {
    // DebugConsole.log("Consent check error: $e");
    return false; // Fail-safe to non-personalized
  }
}

class _SmoothReaderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _SmoothReaderAppBar({
    required this.visible,
    required this.height,
    required this.child,
  });

  final bool visible;
  final double height;
  final Widget child;

  /// Keep height stable so the verse ListView does not resize mid-scroll.
  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class MyAdBanner extends StatefulWidget {
  const MyAdBanner({super.key});

  @override
  State<MyAdBanner> createState() => _MyAdBannerState();
}

class _MyAdBannerState extends State<MyAdBanner> {
  late BannerAd _bannerAd;
  bool _isLoaded = false;

  String? bannerid = '';

  @override
  void initState() {
    super.initState();
    fetchbanner();
  }

  fetchbanner() async {
    bool? isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi) ??
            true;

    if (isAdEnabledFromApi) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // final trackingAllowed = await isTrackingAllowed();
      if (mounted) {
        setState(() {
          bannerid = prefs.getString(SharPreferences.googleBannerId);
        });
      }
      // debugPrint('ad banner id - $bannerid  ${!trackingAllowed}');
      _bannerAd = BannerAd(
        adUnitId: bannerid.toString(),
        size: AdSize.banner,
        request: await AdConsentManager.getAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            // DebugConsole.log(
            //     'BannerAd home show Ad error1: ${error.message} - $ad -$bannerid');
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose(); // Very important
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? SizedBox(
            width: _bannerAd.size.width.toDouble(),
            height: _bannerAd.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd),
          )
        : SizedBox.shrink();
  }
}

class FramedVerseContainer extends StatelessWidget {
  final String backgroundImagePath;
  final Widget child;
  final bool showFrame;
  final bool useBackgroundImage;

  const FramedVerseContainer({
    super.key,
    required this.backgroundImagePath,
    required this.child,
    this.showFrame = true,
    this.useBackgroundImage = true,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: screenWidth < 380
          ? MediaQuery.of(context).size.height * 0.72
          : screenWidth > 450
              ? MediaQuery.of(context).size.height * 0.67
              : MediaQuery.of(context).size.height * 0.62,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useBackgroundImage) ...[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImagePath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (showFrame)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/icons/Frame_1.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
          ] else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(screenWidth < 380
                ? 19
                : screenWidth > 450
                    ? 34
                    : 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class MyAdBanner2 extends StatefulWidget {
  const MyAdBanner2({super.key});

  @override
  State<MyAdBanner2> createState() => _MyAdBanner2State();
}

class _MyAdBanner2State extends State<MyAdBanner2> {
  late BannerAd _bannerAd;
  bool _isLoaded = false;

  String? bannerid = '';

  @override
  void initState() {
    super.initState();
    fetchbanner();
  }

  fetchbanner() async {
    bool? isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi) ??
            true;

    if (isAdEnabledFromApi) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // final trackingAllowed = await isTrackingAllowed();
      if (mounted) {
        setState(() {
          bannerid = prefs.getString('bannerAdUnitId');
        });
      }
      // debugPrint('ad banner id - $bannerid  ${!trackingAllowed}');
      _bannerAd = BannerAd(
        adUnitId: bannerid.toString(),
        size: AdSize.banner,
        request: await AdConsentManager.getAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            // DebugConsole.log(
            //     'BannerAd home show Ad error1: ${error.message} - $ad -$bannerid');
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose(); // Very important
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? SizedBox(
            width: _bannerAd.size.width.toDouble(),
            height: _bannerAd.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd),
          )
        : SizedBox.shrink();
  }
}

class PremiumWelcomeAlert {
  static const Color _ink = Color(0xFF3D2914);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _cardFill = Color(0xFFF5F0E6);
  static const Color _dialogFill = Color(0xFFF8F4EB);

  static const String _heroIcon = 'assets/gold-premium-icons/top_crown.png';
  static const String _bookIcon = 'assets/gold-premium-icons/book_icon.png';
  static const String _audioIcon = 'assets/gold-premium-icons/audio.png';
  static const String _calendarIcon =
      'assets/gold-premium-icons/calendar_icon.png';
  static const String _shieldIcon = 'assets/gold-premium-icons/Shield_icon.png';

  static const Duration _kClearUpgradeDeferDelay = Duration(milliseconds: 300);

  static Future<void> show(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final prefs = await SharedPreferences.getInstance();
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, true);
    await prefs.setString('premiumalrt', '2');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.18 : 20,
            vertical: isTablet ? size.height * 0.08 : 28,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: _dialogFill,
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: close,
                      icon: Icon(
                        Icons.close,
                        color: _ink.withValues(alpha: 0.72),
                        size: 22,
                      ),
                      splashRadius: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 28 : 20,
                      isTablet ? 28 : 24,
                      isTablet ? 28 : 20,
                      isTablet ? 24 : 20,
                    ),
                    child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                          Center(
                            child: Image.asset(
                              _heroIcon,
                              height: isTablet ? 140 : 120,
                  fit: BoxFit.contain,
                ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                Text(
                            'Premium Unlocked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          _premiumDivider(),
                          SizedBox(height: isTablet ? 12 : 10),
                          _premiumDescription(isTablet),
                          SizedBox(height: isTablet ? 18 : 14),
                          _premiumFeatureGrid(isTablet),
                          SizedBox(height: isTablet ? 22 : 18),
                          SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                              onPressed: close,
                      style: ElevatedButton.styleFrom(
                                backgroundColor: _brown,
                                elevation: 0,
                        padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14,
                                  horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                                'Start Exploring',
                                textAlign: TextAlign.center,
                        style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                            ),
                          ),
                        ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
    await Future.delayed(_kClearUpgradeDeferDelay);
    await SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false);
  }

  static Widget _premiumDescription(bool isTablet) {
    return Text(
      'Your premium access is now active. Enjoy deeper Bible study, audio features, devotionals, and a richer reading experience to support your walk with God.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: isTablet ? 16 : 13.5,
        height: 1.45,
        color: _ink.withValues(alpha: 0.88),
      ),
    );
  }

  static Widget _premiumDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: _ink.withValues(alpha: 0.18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.diamond_outlined,
            size: 10,
            color: _ink.withValues(alpha: 0.45),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: _ink.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }

  static Widget _premiumFeatureGrid(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _premiumFeatureCard(
                isTablet: isTablet,
                iconPath: _bookIcon,
                title: 'Study Tools',
                subtitle: 'Powerful tools to understand Scripture better.',
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: _premiumFeatureCard(
                isTablet: isTablet,
                iconPath: _audioIcon,
                title: 'Audio Bible',
                subtitle: "Listen to God's Word anytime, anywhere.",
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Row(
          children: [
            Expanded(
              child: _premiumFeatureCard(
                isTablet: isTablet,
                iconPath: _calendarIcon,
                title: 'Devotionals',
                subtitle: 'Daily devotionals to encourage your faith.',
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: _premiumFeatureCard(
                isTablet: isTablet,
                iconPath: _shieldIcon,
                title: 'Ad-Free Reading',
                subtitle: 'Enjoy a peaceful, distraction-free experience.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _premiumFeatureCard({
    required bool isTablet,
    required String iconPath,
    required String title,
    required String subtitle,
  }) {
    final iconSlotHeight = isTablet ? 68.0 : 58.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: _cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: iconSlotHeight,
            child: Center(
              child: Image.asset(
                iconPath,
                height: iconSlotHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isTablet ? 11.5 : 10,
              height: 1.3,
              color: _ink.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
