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
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/bible_select_screen.dart';
import 'package:biblebookapp/view/screens/books/books_screen.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/calendar_screen/view/calendar_screen.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
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
import 'package:biblebookapp/view/screens/more_apps/model/app_model.dart';
import 'package:biblebookapp/view/screens/more_apps/more_apps_screen.dart';
import 'package:biblebookapp/view/screens/profile/view/profile_screen.dart';
import 'package:biblebookapp/view/screens/quote_screen/quote_screen.dart';
import 'package:biblebookapp/view/screens/wallpaper_screen/wallpaper_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/chat/prayer_guidance_screen.dart';
import 'package:biblebookapp/view/screens/tawk_chat/tawk_chat_screen.dart';
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
import '../../constants/share_preferences.dart';
import '../../widget/home_content_edit_bottom_sheet.dart';
import '../authenitcation/view/login_screen.dart';
import 'book_list_screen.dart';
import 'chapterListScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as p;
import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:html/parser.dart' as html;

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  var selectedBookForRead;
  var selectedBookNameForRead;
  var selectedChapterForRead;
  var selectedVerseNumForRead;
  var selectedVerseForRead;
  var From;

  HomeScreen(
      {super.key,
      required this.selectedBookForRead,
      required this.selectedChapterForRead,
      required this.selectedVerseNumForRead,
      required this.From,
      required this.selectedBookNameForRead,
      required this.selectedVerseForRead});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  bool isOpenChat = false;
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

  // State variables
  double _fontSize = 19.0;
  bool isAdReady = false;
  bool adsIcon = true;
  bool isLoggedIn = false;
  bool _scrollListenerAttached = false;
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
  bool _showUI = true; // Track UI visibility for scroll-based hide/show
  BuildContext? _bottomSheetContext; // Track bottom sheet context to dismiss it
  bool _exitOfferCooldownActive = false; // Dot indicator flag

  // dailyverse
  static const int _targetSeconds =
      15; // Show after 15 seconds on Reading screen (allows app-open ad to show and dismiss first)
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _checkerTimer;
  bool _verseShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    // Track Home Screen event
    StatsigService.trackHomeScreen();
  }

  Future<void> _initializeApp() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    await _loadFontSize();
    await _refreshExitOfferCooldown();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
//  await _checkAndShowVerse();
      await _handleAppLaunchCount();
      await checkUserLoggedIn();
      await _checkAndShowDailyWelcomeToast();
    });

    // _initializeAds();
    loadAds();
  }

  Future<void> _refreshExitOfferCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('exit_offer_cooldown_active') ?? false;
    final ts = await SharPreferences.getString('exit_offer_first_shown_time');
    bool show = active;
    if (active && ts != null) {
      try {
        final firstShown = DateTime.parse(ts);
        final diff = DateTime.now().difference(firstShown).inMinutes;
        if (diff >= 10) {
          await SharPreferences.setBoolean('exit_offer_cooldown_active', false);
          show = false;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _exitOfferCooldownActive = show;
      });
    }
  }

  Future<void> _handleAppLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    appLaunchCount = prefs.getInt('launchCount') ?? 0;

    debugPrint("launchCount is - $appLaunchCount");

    if (appLaunchCount == 2) {
      final data = prefs.getString("review") ?? "1";
      if (data == '1') {
        Future.delayed(Duration(minutes: 1), () async {
          if (mounted) {
            await prefs.setInt('launchCount', 3);
            await prefs.setString('review', '2');
            appLaunchCount = prefs.getInt('launchCount') ?? 0;
            debugPrint("launchCount 3 is - $appLaunchCount");
            // await requestReview(result);
          }
          if (mounted) {
            return showMainFeedbackDialog(context);
          }
        });
      }
    }
  }

  Future<void> _checkAndShowDailyWelcomeToast() async {
    if (!mounted) return;

    // Only show on Reading screen (From == "Read")
    if (widget.From != "Read") return;

    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0]; // YYYY-MM-DD format

    // Check if first-time message has been shown
    final firstTimeShown = await SharPreferences.getBoolean(
            SharPreferences.dailyWelcomeFirstTimeShown) ??
        false;

    // Get last shown date
    final lastShownDate = await SharPreferences.getString(
        SharPreferences.dailyWelcomeLastShownDate);

    // Check if it's a new day
    if (lastShownDate != todayKey) {
      String message;

      if (!firstTimeShown) {
        // Very first time - show welcome message only once
        message = "Welcome You. God's Word is always with you.";

        // Mark first-time message as shown
        await SharPreferences.setBoolean(
            SharPreferences.dailyWelcomeFirstTimeShown, true);

        // Initialize message index to 1 (skip the first message for future rotations)
        await SharPreferences.setInt(
            SharPreferences.dailyWelcomeMessageIndex, 1);
      } else {
        // After first time - rotate through other messages (excluding first one)
        final messageIndex = await SharPreferences.getInt(
                SharPreferences.dailyWelcomeMessageIndex) ??
            1;

        // Rotating messages (excluding the first-time welcome)
        final welcomeMessages = [
          "Take a moment. Let God's Word speak to you.",
          "Grace and peace as you read today.",
          "You're never alone. God's Word is here.",
        ];

        // Get the message for today (rotate through messages 1-3)
        message = welcomeMessages[(messageIndex - 1) % welcomeMessages.length];

        // Rotate to next message index for tomorrow (keep in range 1-3)
        final nextIndex = messageIndex % welcomeMessages.length + 1;
        await SharPreferences.setInt(
            SharPreferences.dailyWelcomeMessageIndex, nextIndex);
      }

      // Show toast after a small delay to ensure screen is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Constants.showToast(message, 3000);
        }
      });

      // Update last shown date
      await SharPreferences.setString(
          SharPreferences.dailyWelcomeLastShownDate, todayKey);
    }
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

  Future<void> _showDailyVerseBottomSheet(double fontSize) async {
    if (_isBottomSheetOpen) return;

    // Verify we're still on Reader screen before showing
    if (widget.From.toString() != "Read") {
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

      // Final check: ensure we're still on Reader screen and route is current before showing
      if (widget.From.toString() != "Read" ||
          !mounted ||
          ModalRoute.of(context)?.isCurrent != true) {
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
                            backgroundImagePath: randomBgImage,
                            showFrame: Random().nextBool(),
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
                                      color: CommanColor.white,
                                      maxFontSize: screenWidth < 380
                                          ? BibleInfo.fontSizeScale * 14.9
                                          : screenWidth > 450
                                              ? BibleInfo.fontSizeScale * 32
                                              : DashBoardController()
                                                      .fontSize
                                                      .value *
                                                  1.2,
                                      minFontSize:
                                          screenWidth < 380 ? 11.5 : 10.9,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "${todayVerse.book} ${todayVerse.chapter! + 1}:${todayVerse.verseNum! + 1}",
                                        style: TextStyle(
                                          color: CommanColor.white,
                                          fontStyle: FontStyle.italic,
                                          fontSize: screenWidth < 380
                                              ? 14
                                              : screenWidth > 450
                                                  ? BibleInfo.fontSizeScale * 28
                                                  : fontSize - 2,
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
                                color: CommanColor.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                decorationThickness: 2.0,
                                fontSize: screenWidth < 380
                                    ? 17
                                    : screenWidth > 450
                                        ? 31
                                        : 19,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/Icon-1024.png",
                                    height: 28,
                                    width: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    BibleInfo.bible_shortName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: BibleInfo.letterSpacing,
                                      fontSize: BibleInfo.fontSizeScale * 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
                " ${todayVerse.book} ${int.parse(todayVerse.chapter.toString()) + 1}:${int.parse(todayVerse.verseNum.toString()) + 1}",
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
                    '${parse(todayVerse.verse.toString()).body?.text ?? ''}.\n ${todayVerse.book} ${todayVerse.chapter! + 1}:${todayVerse.verseNum! + 1} \n You can read more at:\nhttps://itunes.apple.com/app/id$appid';
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
            "${int.parse(todayVerse.chapter.toString()) + 1}");
        await SharPreferences.setString(SharPreferences.selectedBookNum,
            "${int.parse(todayVerse.bookId.toString())}");
        Get.offAll(
          () => HomeScreen(
            From: "Daily",
            selectedBookForRead: int.parse(todayVerse.bookId.toString()),
            selectedChapterForRead:
                1 + int.parse(todayVerse.chapter.toString()),
            selectedVerseNumForRead:
                1 + int.parse(todayVerse.verseNum.toString()),
            selectedBookNameForRead: todayVerse.book.toString(),
            selectedVerseForRead:
                parse(todayVerse.verse.toString()).body?.text.toString() ?? '',
          ),
          transition: Transition.cupertinoDialog,
          duration: const Duration(milliseconds: 300),
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

      final xFile = XFile(imageFile.path);
      await Share.shareXFiles([xFile],
          subject: '${BibleInfo.bible_shortName} app',
          text: "",
          sharePositionOrigin:
              Rect.fromPoints(const Offset(2, 2), const Offset(3, 3)));
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
    // Only show verse on Reader screen (Home Screen)
    if (widget.From.toString() == "Read" &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _onVisible();
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

  // Called when this route is again visible because the top route was popped
  @override
  void didPopNext() {
    // Only show verse on Reader screen (Home Screen)
    if (widget.From.toString() == "Read" &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _onVisible();
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
    // If app goes to background, treat as hidden; if resumed, treat as visible (only if route is current)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _onHidden();
    } else if (state == AppLifecycleState.resumed) {
      // only resume if this route is still current
      if (ModalRoute.of(context)?.isCurrent == true) {
        _onVisible();
      }
    }
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

    if (_verseShown) return; // already shown, nothing to do

    // start or resume stopwatch
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    // start periodic checker if not running
    _checkerTimer ??=
        Timer.periodic(const Duration(seconds: 1), (_) => _checkElapsed());
    // setState(() {}); // update UI counter if desired
  }

  void _onHidden() {
    debugPrint("Hidden HomeScreen!");
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

    adsDuration.dispose();
    // audioPlayer.dispose();
    if (mounted) {
      if (audioPlayer.state == PlayerState.playing) {
        audioPlayer.dispose();
      }
    }
    disposead();
    WidgetsBinding.instance.removeObserver(this);
    _checkerTimer?.cancel();
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
    debugPrint("sz current width - $screenWidth ");
    var bibleName = BibleInfo.bible_shortName;
    return UpgradeCheckWrapper(
      check: "home",
      child: GetX<DashBoardController>(
        init: DashBoardController(),
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
          // await _initializeRatingDialog(state);
          _attachScrollListener(state);
          _initializeControllerState(state);
          _handleAdExpiration(state);
          _loadInitialData(state);
          final prefs = await SharedPreferences.getInstance();
          if (widget.From.toString() == 'premium') {
            final data = prefs.getString("premiumalrt") ?? "1";
            if (data == '1') {
              PremiumWelcomeAlert.show(context);
            }
          }
        },
        builder: (controller) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: controller.selectedChapter.value.isNotEmpty && _showUI
                ? AppBar(
                    toolbarHeight: screenWidth > 450 ? 70 : 55,
                    iconTheme:
                        IconThemeData(color: CommanColor.whiteBlack(context)),
                    flexibleSpace: Container(
                      color: p.Provider.of<ThemeProvider>(context)
                                  .currentCustomTheme ==
                              AppCustomTheme.vintage
                          ? null
                          : Provider.of<ThemeProvider>(context).themeMode ==
                                  ThemeMode.dark
                              ? CommanColor.darkPrimaryColor
                              : p.Provider.of<ThemeProvider>(context)
                                          .currentCustomTheme ==
                                      AppCustomTheme.vintage
                                  ? CommanColor.darkPrimaryColor
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
                                      : p.Provider.of<ThemeProvider>(context)
                                          .backgroundColor,
                              image: DecorationImage(
                                image: AssetImage(Images.bgImage((context))),
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
                    leadingWidth: 120,
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
                        controller.isAdsCompletlyDisabled.value
                            ? const SizedBox.shrink()
                            : controller.adFree.value
                                ? DateTime.tryParse(controller
                                            .RewardAdExpireDate.value) !=
                                        null
                                    ? GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(25),
                                              ),
                                            ),
                                            clipBehavior:
                                                Clip.antiAliasWithSaveLayer,
                                            builder: (BuildContext context) {
                                              final startTime = DateTime.parse(
                                                  '${controller.RewardAdExpireDate}');

                                              DateTime ExpiryDate = startTime;

                                              final currentTime =
                                                  DateTime.now();
                                              final diffDy =
                                                  ExpiryDate.difference(
                                                          currentTime)
                                                      .inDays;

                                              return Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .white),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        20),
                                                                topRight: Radius
                                                                    .circular(
                                                                        20))),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.30,
                                                    // color: Colors.white,
                                                    child:
                                                        SingleChildScrollView(
                                                      physics:
                                                          const ScrollPhysics(),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                  "assets/feedbacklogo.png",
                                                                  height: 120,
                                                                  width: 120,
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context)),
                                                            ],
                                                          ),
                                                          // SizedBox(height: 5,),
                                                          Text(
                                                            'Subscription Info',
                                                            style: TextStyle(
                                                                letterSpacing:
                                                                    BibleInfo
                                                                        .letterSpacing,
                                                                fontSize: BibleInfo
                                                                        .fontSizeScale *
                                                                    16,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          ),
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Text(
                                                              diffDy > 365
                                                                  ? 'Your subscription will never expire'
                                                                  : '$diffDy day(s) left for the renewal of the subscription.',
                                                              style: TextStyle(
                                                                  letterSpacing:
                                                                      BibleInfo
                                                                          .letterSpacing,
                                                                  fontSize: screenWidth <
                                                                          380
                                                                      ? BibleInfo
                                                                              .fontSizeScale *
                                                                          13
                                                                      : BibleInfo
                                                                              .fontSizeScale *
                                                                          15,
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400)),
                                                          const SizedBox(
                                                              height: 5),
                                                          Text(
                                                              diffDy > 365
                                                                  ? 'Your subscription period is lifetime'
                                                                  : 'Your subscription expires on ${DateFormat('dd-MM-yyyy').format(ExpiryDate)}',
                                                              style: TextStyle(
                                                                letterSpacing:
                                                                    BibleInfo
                                                                        .letterSpacing,
                                                                fontSize: screenWidth <
                                                                        380
                                                                    ? BibleInfo
                                                                            .fontSizeScale *
                                                                        13
                                                                    : BibleInfo
                                                                            .fontSizeScale *
                                                                        15,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              )),
                                                          const SizedBox(
                                                              height: 5),
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
                                                        color: CommanColor
                                                            .lightDarkPrimary(
                                                                context),
                                                        size: 25,
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Image.asset(
                                          'assets/info.png',
                                          height: screenWidth > 450 ? 40 : 24,
                                        ))
                                    : Visibility(
                                        visible:
                                            controller.isSubscriptionEnabled ??
                                                true,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (controller.connectionStatus
                                                        .first ==
                                                    ConnectivityResult.wifi ||
                                                controller.connectionStatus
                                                        .first ==
                                                    ConnectivityResult.mobile) {
                                              adsIcon = false;
                                              debugPrint(
                                                  "all plans - ${controller.sixMonthPlan} ${controller.oneYearPlan}  ${controller.lifeTimePlan}");
                                              SubscriptionScreen
                                                  .showExitOfferFromHomeScreen(
                                                      context, controller);
                                            } else {
                                              Constants.showToast(
                                                  "Check your Internet Connection");
                                            }
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Image.asset(
                                                'assets/no-ad.png',
                                                height:
                                                    screenWidth > 450 ? 40 : 24,
                                                width:
                                                    screenWidth > 450 ? 40 : 24,
                                                color: CommanColor.whiteBlack(
                                                    context),
                                              ),
                                              if (_exitOfferCooldownActive)
                                                Positioned(
                                                  right: -2,
                                                  top: -2,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ))
                                : Visibility(
                                    visible: controller.isSubscriptionEnabled ??
                                        false,
                                    child: GestureDetector(
                                      onTap: () {
                                        adsIcon = false;
                                        SubscriptionScreen
                                            .showExitOfferFromHomeScreen(
                                                context, controller);
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Image.asset(
                                            'assets/no-ad.png',
                                            height: screenWidth > 450 ? 35 : 24,
                                            width: screenWidth > 450 ? 35 : 24,
                                            color:
                                                CommanColor.whiteBlack(context),
                                          ),
                                          if (_exitOfferCooldownActive)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                    actions: [
                      BibleInfo.folders.length != 1
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: InkWell(
                                  onTap: () {
                                    if (controller.adFree.value == false) {
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
                                    color: CommanColor.whiteBlack(context),
                                  )),
                            )
                          : SizedBox(),
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
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          child: Image.asset(
                            "assets/home icons/search.png",
                            height: screenWidth > 450 ? 30 : 22,
                            width: screenWidth > 450 ? 30 : 22,
                            color: CommanColor.whiteBlack(context),
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ChangeThemeButtonWidget(),
                      ),
                    ],
                    title: IntrinsicWidth(
                      child: InkWell(
                        onTap: () async {
                          if (controller.adFree.value == false) {
                            controller.bannerAd?.dispose();
                            controller.bannerAd?.load();
                          }
                          Get.to(() => const BookListScreen(),
                              transition: Transition.cupertinoDialog,
                              duration: const Duration(milliseconds: 300));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                  "${selectedBookname ?? controller.selectedBook}",
                                  style:
                                      CommanStyle.appBarStyle(context).copyWith(
                                    fontSize: screenWidth > 450
                                        ? BibleInfo.fontSizeScale * 26
                                        : BibleInfo.fontSizeScale * 18,
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0, left: 4),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: CommanColor.whiteBlack(context),
                                size: screenWidth > 450 ? 39 : 24,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(30.0),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            hintColor: CommanColor.whiteAndDark(context)),
                        child: Container(
                          height: screenWidth > 450 ? 45 : 30.0,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? p.Provider.of<ThemeProvider>(context)
                                              .currentCustomTheme ==
                                          AppCustomTheme.vintage
                                      ? CommanColor.darkPrimaryColor
                                      : CommanColor.darkPrimaryColor200
                                  : p.Provider.of<ThemeProvider>(context)
                                              .currentCustomTheme ==
                                          AppCustomTheme.vintage
                                      ? CommanColor.white
                                      : p.Provider.of<ThemeProvider>(context)
                                          .backgroundColor,
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {
                              if (controller.adFree.value == false) {
                                controller.bannerAd?.dispose();
                                controller.bannerAd?.load();
                              }
                              Get.to(
                                  () => ChapterListScreen(
                                        book_num:
                                            controller.selectedBookNum.value,
                                        chapterCount: controller
                                            .selectedBookChapterCount.value,
                                        selectedChapter:
                                            controller.selectedChapter.value,
                                      ),
                                  transition: Transition.cupertinoDialog,
                                  duration: const Duration(milliseconds: 300));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                controller.selectedChapter.value == ""
                                    ? const SizedBox()
                                    : Text(
                                        "Chapter - ${int.parse(controller.selectedChapter.value)}",
                                        style: CommanStyle.bw14500(context)
                                            .copyWith(
                                                fontWeight: FontWeight.w400,
                                                fontSize: screenWidth > 450
                                                    ? BibleInfo.fontSizeScale *
                                                        20
                                                    : BibleInfo.fontSizeScale *
                                                        14)),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2.0, left: 5),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: CommanColor.whiteBlack(context),
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
                  )
                : null,
            body: WillPopScope(
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
                onHorizontalDragEnd: (dragDetail) async {
                  // Show ad every 5 swipes
                  if (dragDetail.velocity.pixelsPerSecond.dx < 1) {
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
                      SharPreferences.setString(SharPreferences.selectedChapter,
                          controller.selectedChapter.value);

                      controller.getSelectedChapterAndBook();
                      controller.getFont();
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
                    SharPreferences.setString(SharPreferences.selectedChapter,
                        controller.selectedChapter.value);
                    controller.getSelectedChapterAndBook();
                    controller.getFont();
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
                  child: controller.isFetchContent.value
                      ? const Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Loader(),
                          ],
                        ))
                      : controller.selectedBookContent.isEmpty
                          ? _buildEmptyContentWithChapters(controller)
                          : ListView.builder(
                              scrollDirection: controller.scrollDirection,
                              controller: controller.autoScrollController.value,
                              itemCount: controller.selectedBookContent.length,
                              physics: const ScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(
                                  left: 15, right: 15, bottom: 20),
                              itemBuilder: (context, index) {
                                var data =
                                    controller.selectedBookContent[index];
                                return AutoScrollTag(
                                  key: ValueKey(index),
                                  controller:
                                      controller.autoScrollController.value,
                                  index: index,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              controller.selectedIndex.value =
                                                  -1;

                                              controller.selectedIndex.value =
                                                  index;

                                              controller.selectedVerseView
                                                  .value = index;
                                              controller.printText.value =
                                                  '${parse(data.content).body?.text ?? data.content}';
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
                                                controller.selectedIndex.value =
                                                    index;
                                              });
                                              debugPrint(" step 1 ");
                                            },
                                                    verNum: "${index + 1}",
                                                    verseBookdata: data,
                                                    selectedColor: data
                                                                .isHighlighted ==
                                                            "no"
                                                        ? 0
                                                        : int.parse(
                                                            selectedcolor ??
                                                                '0x00000000'),
                                                    controller: controller)
                                                .then(
                                              (value) {
                                                setState(() {
                                                  controller
                                                      .selectedIndex.value = -1;
                                                });
                                                debugPrint(" step 2 ");
                                                // controller.selectedIndex.value =
                                                //     -1;
                                              },
                                            );
                                          },
                                          child: VerseItemWidget(
                                            index: index,
                                            currentindex:
                                                controller.selectedIndex.value,
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
                                      controller.selectedBookContent.length == 1
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 7),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () async {
                                                      await SharPreferences
                                                          .setString(
                                                              'OpenAd', '1');
                                                      await DBHelper()
                                                          .db
                                                          .then((value) {
                                                        value!
                                                            .rawQuery(
                                                                "SELECT * From book WHERE book_num = ${int.parse(controller.selectedBookNum.value)}")
                                                            .then(
                                                                (value) async {
                                                          controller.bookReadPer
                                                              .value = value[0]
                                                                  ["read_per"]
                                                              .toString();
                                                          if (controller
                                                                  .selectedBookContent[
                                                                      0]
                                                                  .isRead ==
                                                              "no") {
                                                            if (int.tryParse(
                                                                    controller
                                                                        .bookReadPer
                                                                        .value) ==
                                                                0) {
                                                              double readPer = (100 *
                                                                      1) /
                                                                  double.parse(
                                                                      controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                              DBHelper()
                                                                  .updateBookData(
                                                                      int.parse(controller
                                                                          .selectedBookId
                                                                          .value
                                                                          .toString()),
                                                                      "read_per",
                                                                      readPer
                                                                          .toStringAsFixed(
                                                                              1)
                                                                          .toString())
                                                                  .then(
                                                                      (value) {});
                                                            } else {
                                                              double readPer = (100 *
                                                                      1) /
                                                                  double.parse(
                                                                      controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                              double finalRead =
                                                                  double.parse(controller
                                                                          .bookReadPer
                                                                          .value
                                                                          .toString()) +
                                                                      readPer;
                                                              DBHelper()
                                                                  .updateBookData(
                                                                      int.parse(controller
                                                                          .selectedBookId
                                                                          .value
                                                                          .toString()),
                                                                      "read_per",
                                                                      finalRead
                                                                          .toStringAsFixed(
                                                                              1)
                                                                          .toString())
                                                                  .then(
                                                                      (value) {});
                                                            }
                                                            controller
                                                                .isReadLoad
                                                                .value = true;
                                                            for (var i = 0;
                                                                i <
                                                                    controller
                                                                        .selectedBookContent
                                                                        .value
                                                                        .length;
                                                                i++) {
                                                              DBHelper()
                                                                  .updateVersesData(
                                                                      int.parse(controller
                                                                          .selectedBookContent
                                                                          .value[
                                                                              i]
                                                                          .id
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
                                                                  isBookmarked:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isBookmarked,
                                                                  isHighlighted:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isHighlighted,
                                                                  isNoted: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .isNoted,
                                                                  isUnderlined:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isUnderlined,
                                                                  isRead:
                                                                      "yes");
                                                              controller
                                                                      .selectedBookContent[
                                                                  i] = data;
                                                            }

                                                            Future.delayed(
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
                                                                      await InternetConnection()
                                                                          .hasInternetAccess;
                                                                  if (!hasInternet) {
                                                                    // Offline - skip ad and navigate directly
                                                                    shouldSkipAd =
                                                                        true;
                                                                  } else {
                                                                    // Check if mobile only connection (likely 2G/slow) - skip ad
                                                                    final connectivityResult =
                                                                        await Connectivity()
                                                                            .checkConnectivity();
                                                                    final isMobileOnly = connectivityResult.contains(ConnectivityResult.mobile) &&
                                                                        !connectivityResult.contains(ConnectivityResult
                                                                            .wifi) &&
                                                                        !connectivityResult
                                                                            .contains(ConnectivityResult.ethernet);
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
                                                                  Get.to(() =>
                                                                      MarkAsReadScreen(
                                                                        ReadedChapter: controller
                                                                            .selectedChapter
                                                                            .value,
                                                                        RededBookName: controller
                                                                            .selectedBook
                                                                            .value,
                                                                        SelectedBookChapterCount: controller
                                                                            .selectedBookChapterCount
                                                                            .value,
                                                                      ));
                                                                  return;
                                                                }

                                                                // Only show ad if online with good connection
                                                                if (_adService
                                                                            .interstitialAd !=
                                                                        null &&
                                                                    controller
                                                                            .adFree
                                                                            .value ==
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
                                                                      await _showInterstitialAdAndWait();
                                                                    } catch (e) {
                                                                      debugPrint(
                                                                          'Error showing ad in Mark as Read: $e');
                                                                      // If ad fails, proceed anyway
                                                                    }
                                                                    // Navigate AFTER ad is dismissed
                                                                    Get.to(() =>
                                                                        MarkAsReadScreen(
                                                                          ReadedChapter: controller
                                                                              .selectedChapter
                                                                              .value,
                                                                          RededBookName: controller
                                                                              .selectedBook
                                                                              .value,
                                                                          SelectedBookChapterCount: controller
                                                                              .selectedBookChapterCount
                                                                              .value,
                                                                        ));
                                                                  } else {
                                                                    // Ad shown recently, skip ad but still navigate
                                                                    Get.to(() =>
                                                                        MarkAsReadScreen(
                                                                          ReadedChapter: controller
                                                                              .selectedChapter
                                                                              .value,
                                                                          RededBookName: controller
                                                                              .selectedBook
                                                                              .value,
                                                                          SelectedBookChapterCount: controller
                                                                              .selectedBookChapterCount
                                                                              .value,
                                                                        ));
                                                                  }
                                                                } else {
                                                                  print(
                                                                      'Not Load Interstitial Ad');

                                                                  final randomItem =
                                                                      await StorageHelper
                                                                          .getRandomBookOrApp();

                                                                  if (randomItem
                                                                      is BookModel) {
                                                                    print(
                                                                        "Random Book: ${randomItem.bookName}");

                                                                    final connectivityResult =
                                                                        await Connectivity()
                                                                            .checkConnectivity();
                                                                    if (connectivityResult[
                                                                            0] ==
                                                                        ConnectivityResult
                                                                            .none) {
                                                                      return Get
                                                                          .to(() =>
                                                                              MarkAsReadScreen(
                                                                                ReadedChapter: controller.selectedChapter.value,
                                                                                RededBookName: controller.selectedBook.value,
                                                                                SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                              ));
                                                                      // return Constants
                                                                      //     .showToast(
                                                                      //         "Check your Internet connection");
                                                                    }
                                                                    Get.to(
                                                                      () =>
                                                                          FullScreenAd(
                                                                        networkimage:
                                                                            randomItem.bookThumbURL,
                                                                        title: randomItem
                                                                            .bookName,
                                                                        description:
                                                                            randomItem.bookDescription,
                                                                        iteamurl:
                                                                            randomItem.bookUrl,
                                                                        rededBookName: controller
                                                                            .selectedBook
                                                                            .value,
                                                                        readedChapter: controller
                                                                            .selectedChapter
                                                                            .value,
                                                                        selectedBookChapterCount: controller
                                                                            .selectedBookChapterCount
                                                                            .value,
                                                                      ),
                                                                    );
                                                                  } else if (randomItem
                                                                      is AppModel) {
                                                                    print(
                                                                        "Random App: ${randomItem.appName}");
                                                                    final connectivityResult =
                                                                        await Connectivity()
                                                                            .checkConnectivity();
                                                                    if (connectivityResult[
                                                                            0] ==
                                                                        ConnectivityResult
                                                                            .none) {
                                                                      return Get
                                                                          .to(() =>
                                                                              MarkAsReadScreen(
                                                                                ReadedChapter: controller.selectedChapter.value,
                                                                                RededBookName: controller.selectedBook.value,
                                                                                SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                              ));
                                                                      // return Constants
                                                                      //     .showToast(
                                                                      //         "Check your Internet connection");
                                                                    }
                                                                    Get.to(
                                                                      () =>
                                                                          FullScreenAd(
                                                                        networkimage:
                                                                            randomItem.thumburl,
                                                                        title: randomItem
                                                                            .appName,
                                                                        description:
                                                                            randomItem.apptype,
                                                                        iteamurl:
                                                                            randomItem.appurl,
                                                                        rededBookName: controller
                                                                            .selectedBook
                                                                            .value,
                                                                        readedChapter: controller
                                                                            .selectedChapter
                                                                            .value,
                                                                        selectedBookChapterCount: controller
                                                                            .selectedBookChapterCount
                                                                            .value,
                                                                      ),
                                                                    );
                                                                  }

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
                                                            if (int.tryParse(
                                                                    controller
                                                                        .bookReadPer
                                                                        .value) ==
                                                                0) {
                                                            } else {
                                                              double readPer = (100 *
                                                                      1) /
                                                                  double.parse(
                                                                      controller
                                                                          .selectedBookChapterCount
                                                                          .value
                                                                          .toString());
                                                              double finalRead =
                                                                  double.parse(controller
                                                                          .bookReadPer
                                                                          .value
                                                                          .toString()) -
                                                                      readPer;
                                                              DBHelper()
                                                                  .updateBookData(
                                                                      int.parse(controller
                                                                          .selectedBookId
                                                                          .value
                                                                          .toString()),
                                                                      "read_per",
                                                                      finalRead
                                                                          .toStringAsFixed(
                                                                              1)
                                                                          .toString())
                                                                  .then(
                                                                      (value) {});
                                                            }
                                                            for (var i = 0;
                                                                i <
                                                                    controller
                                                                        .selectedBookContent
                                                                        .length;
                                                                i++) {
                                                              await DBHelper()
                                                                  .updateVersesData(
                                                                      int.parse(controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .id
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
                                                                  isBookmarked:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isBookmarked,
                                                                  isHighlighted:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isHighlighted,
                                                                  isNoted: controller
                                                                      .selectedBookContent[
                                                                          i]
                                                                      .isNoted,
                                                                  isUnderlined:
                                                                      controller
                                                                          .selectedBookContent[
                                                                              i]
                                                                          .isUnderlined,
                                                                  isRead: "no");
                                                              controller
                                                                      .selectedBookContent[
                                                                  i] = data;
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
                                                      decoration: BoxDecoration(
                                                        color: controller
                                                                    .selectedBookContent[
                                                                        0]
                                                                    .isRead ==
                                                                "no"
                                                            ? Colors.black38
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
                                                              blurRadius: 2)
                                                        ],
                                                      ),
                                                      child: Center(
                                                          child: controller
                                                                      .isReadLoad
                                                                      .value ==
                                                                  false
                                                              ? Text(
                                                                  controller.selectedBookContent[0]
                                                                              .isRead ==
                                                                          "no"
                                                                      ? 'Mark as Read'
                                                                      : "Marked as Read",
                                                                  style: TextStyle(
                                                                      letterSpacing:
                                                                          BibleInfo
                                                                              .letterSpacing,
                                                                      fontSize: screenWidth > 450
                                                                          ? BibleInfo.fontSizeScale *
                                                                              20
                                                                          : BibleInfo.fontSizeScale *
                                                                              14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: controller.selectedBookContent[0].isRead ==
                                                                              "no"
                                                                          ? Colors
                                                                              .white
                                                                          : CommanColor.darkModePrimaryWhite(
                                                                              context)),
                                                                )
                                                              : const SizedBox(
                                                                  height: 22,
                                                                  width: 22,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    color: Colors
                                                                        .white,
                                                                    strokeWidth:
                                                                        2.2,
                                                                  ))),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : index ==
                                                  controller.selectedBookContent
                                                          .length -
                                                      1
                                              ? Obx(() => Column(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 15),
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        color:
                                                            Colors.transparent,
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
                                                                    .then(
                                                                        (value) {
                                                                  value!
                                                                      .rawQuery(
                                                                          "SELECT * From book WHERE book_num = ${int.parse(controller.selectedBookNum.value)}")
                                                                      .then(
                                                                          (value) async {
                                                                    controller
                                                                        .bookReadPer
                                                                        .value = value[0]
                                                                            [
                                                                            "read_per"]
                                                                        .toString();
                                                                    if (controller
                                                                            .selectedBookContent[1]
                                                                            .isRead ==
                                                                        "no") {
                                                                      if (controller
                                                                              .bookReadPer
                                                                              .value ==
                                                                          "0") {
                                                                        double
                                                                            readPer =
                                                                            (100 * 1) /
                                                                                double.parse(controller.selectedBookChapterCount.value.toString());
                                                                        await DBHelper()
                                                                            .updateBookData(
                                                                                int.parse(controller.selectedBookId.value.toString()),
                                                                                "read_per",
                                                                                readPer.toStringAsFixed(1).toString())
                                                                            .then((value) {});
                                                                      } else {
                                                                        double
                                                                            readPer =
                                                                            (100 * 1) /
                                                                                double.parse(controller.selectedBookChapterCount.value.toString());
                                                                        double
                                                                            finalRead =
                                                                            double.parse(controller.bookReadPer.value.toString()) +
                                                                                readPer;
                                                                        await DBHelper()
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
                                                                          i < controller.selectedBookContent.length;
                                                                          i++) {
                                                                        await DBHelper()
                                                                            .updateVersesData(
                                                                                int.parse(controller.selectedBookContent[i].id.toString()),
                                                                                "is_read",
                                                                                "yes")
                                                                            .then((value) {});
                                                                        var data = VerseBookContentModel(
                                                                            id: controller.selectedBookContent[i].id,
                                                                            bookNum: controller.selectedBookContent[i].bookNum,
                                                                            chapterNum: controller.selectedBookContent[i].chapterNum,
                                                                            verseNum: controller.selectedBookContent[i].verseNum,
                                                                            content: controller.selectedBookContent[i].content,
                                                                            isBookmarked: controller.selectedBookContent[i].isBookmarked,
                                                                            isHighlighted: controller.selectedBookContent[i].isHighlighted,
                                                                            isNoted: controller.selectedBookContent[i].isNoted,
                                                                            isUnderlined: controller.selectedBookContent[i].isUnderlined,
                                                                            isRead: "yes");
                                                                        controller.selectedBookContent[i] =
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
                                                                            shouldSkipAd =
                                                                                true;
                                                                          }

                                                                          // If should skip ad (offline/low internet), navigate directly
                                                                          if (shouldSkipAd) {
                                                                            Get.to(() =>
                                                                                MarkAsReadScreen(
                                                                                  ReadedChapter: controller.selectedChapter.value,
                                                                                  RededBookName: controller.selectedBook.value,
                                                                                  SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                ));
                                                                            return;
                                                                          }

                                                                          // Only show ad if online with good connection
                                                                          if (_adService.interstitialAd != null &&
                                                                              controller.adFree.value == false) {
                                                                            // Check if 3 minutes have passed since last ad
                                                                            final canShowAd =
                                                                                await _canShowMarkAsReadAd();
                                                                            if (canShowAd) {
                                                                              print('Load Interstitial Ad');
                                                                              await _saveMarkAsReadAdTime();
                                                                              // Show ad FIRST, wait for dismissal, THEN navigate
                                                                              try {
                                                                                await _showInterstitialAdAndWait();
                                                                              } catch (e) {
                                                                                debugPrint('Error showing ad in Mark as Read: $e');
                                                                                // If ad fails, proceed anyway
                                                                              }
                                                                              // Navigate AFTER ad is dismissed
                                                                              Get.to(() => MarkAsReadScreen(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  ));
                                                                            } else {
                                                                              // Ad shown recently, skip ad but still navigate
                                                                              Get.to(() => MarkAsReadScreen(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  ));
                                                                            }
                                                                          } else {
                                                                            print('Not Load Interstitial Ad');

                                                                            if (controller.adFree.value !=
                                                                                false) {
                                                                              return Get.to(() => MarkAsReadScreen(
                                                                                    ReadedChapter: controller.selectedChapter.value,
                                                                                    RededBookName: controller.selectedBook.value,
                                                                                    SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  ));
                                                                            } else {
                                                                              // Get.to(() =>
                                                                              //     MarkAsReadScreen(
                                                                              //       ReadedChapter: controller.selectedChapter.value,
                                                                              //       RededBookName: controller.selectedBook.value,
                                                                              //       SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                              //     ));
                                                                              final randomItem = await StorageHelper.getRandomBookOrApp();

                                                                              if (randomItem is BookModel) {
                                                                                print("Random Book: ${randomItem.bookName}");
                                                                                final connectivityResult = await Connectivity().checkConnectivity();
                                                                                if (connectivityResult[0] == ConnectivityResult.none) {
                                                                                  return Get.to(() => MarkAsReadScreen(
                                                                                        ReadedChapter: controller.selectedChapter.value,
                                                                                        RededBookName: controller.selectedBook.value,
                                                                                        SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                      ));
                                                                                  // return Constants
                                                                                  //     .showToast(
                                                                                  //         "Check your Internet connection");
                                                                                }
                                                                                Get.to(
                                                                                  () => FullScreenAd(
                                                                                    networkimage: randomItem.bookThumbURL,
                                                                                    title: randomItem.bookName,
                                                                                    description: randomItem.bookDescription,
                                                                                    iteamurl: randomItem.bookUrl,
                                                                                    rededBookName: controller.selectedBook.value,
                                                                                    readedChapter: controller.selectedChapter.value,
                                                                                    selectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  ),
                                                                                );
                                                                              } else if (randomItem is AppModel) {
                                                                                final connectivityResult = await Connectivity().checkConnectivity();
                                                                                if (connectivityResult[0] == ConnectivityResult.none) {
                                                                                  return Get.to(() => MarkAsReadScreen(
                                                                                        ReadedChapter: controller.selectedChapter.value,
                                                                                        RededBookName: controller.selectedBook.value,
                                                                                        SelectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                      ));
                                                                                  // return Constants
                                                                                  //     .showToast(
                                                                                  //         "Check your Internet connection");
                                                                                }
                                                                                print("Random App: ${randomItem.appName}");
                                                                                Get.to(
                                                                                  () => FullScreenAd(
                                                                                    networkimage: randomItem.thumburl,
                                                                                    title: randomItem.appName,
                                                                                    description: randomItem.apptype,
                                                                                    iteamurl: randomItem.appurl,
                                                                                    rededBookName: controller.selectedBook.value,
                                                                                    readedChapter: controller.selectedChapter.value,
                                                                                    selectedBookChapterCount: controller.selectedBookChapterCount.value,
                                                                                  ),
                                                                                );
                                                                              }
                                                                            }
                                                                          }
                                                                        },
                                                                      );
                                                                    } else {
                                                                      controller
                                                                          .isReadLoad
                                                                          .value = true;
                                                                      if (controller
                                                                              .bookReadPer
                                                                              .value ==
                                                                          0) {
                                                                      } else {
                                                                        double
                                                                            readPer =
                                                                            (100 * 1) /
                                                                                double.parse(controller.selectedBookChapterCount.value.toString());
                                                                        double
                                                                            finalRead =
                                                                            double.parse(controller.bookReadPer.value.toString()) -
                                                                                readPer;
                                                                        await DBHelper()
                                                                            .updateBookData(
                                                                                int.parse(controller.selectedBookId.value.toString()),
                                                                                "read_per",
                                                                                finalRead.toStringAsFixed(1).toString())
                                                                            .then((value) {});
                                                                      }
                                                                      for (var i =
                                                                              0;
                                                                          i < controller.selectedBookContent.length;
                                                                          i++) {
                                                                        await DBHelper()
                                                                            .updateVersesData(
                                                                                int.parse(controller.selectedBookContent[i].id.toString()),
                                                                                "is_read",
                                                                                "no")
                                                                            .then((value) {});
                                                                        var data = VerseBookContentModel(
                                                                            id: controller.selectedBookContent[i].id,
                                                                            bookNum: controller.selectedBookContent[i].bookNum,
                                                                            chapterNum: controller.selectedBookContent[i].chapterNum,
                                                                            verseNum: controller.selectedBookContent[i].verseNum,
                                                                            content: controller.selectedBookContent[i].content,
                                                                            isBookmarked: controller.selectedBookContent[i].isBookmarked,
                                                                            isHighlighted: controller.selectedBookContent[i].isHighlighted,
                                                                            isNoted: controller.selectedBookContent[i].isNoted,
                                                                            isUnderlined: controller.selectedBookContent[i].isUnderlined,
                                                                            isRead: "no");
                                                                        controller.selectedBookContent[i] =
                                                                            data;
                                                                      }
                                                                      Future.delayed(
                                                                          const Duration(
                                                                              milliseconds: 200),
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
                                                                                  1]
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
                                                                    child: controller.isReadLoad.value ==
                                                                            false
                                                                        ? Text(
                                                                            controller.selectedBookContent[1].isRead == "no"
                                                                                ? 'Mark as Read'
                                                                                : "Marked as Read",
                                                                            style: TextStyle(
                                                                                letterSpacing: BibleInfo.letterSpacing,
                                                                                fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 20 : BibleInfo.fontSizeScale * 14,
                                                                                fontWeight: FontWeight.w500,
                                                                                color: controller.selectedBookContent[1].isRead == "no" ? Colors.white : CommanColor.darkModePrimaryWhite(context)),
                                                                          )
                                                                        : const SizedBox(
                                                                            height:
                                                                                22,
                                                                            width:
                                                                                22,
                                                                            child:
                                                                                CircularProgressIndicator(
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
                                                          controller.adFree
                                                                  .value ==
                                                              false)
                                                        Builder(
                                                          builder: (context) {
                                                            try {
                                                              final ad = controller
                                                                  .popupBannerAdHome!;
                                                              // Check if ad has valid size (indicates it's loaded)
                                                              if (ad.size.width >
                                                                      0 &&
                                                                  ad.size.height >
                                                                      0) {
                                                                return Padding(
                                                                  padding:
                                                                      const EdgeInsets
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
                                                                    child: AdWidget(
                                                                        ad: ad),
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
                                      p.Provider.of<ThemeProvider>(context)
                                                  .currentCustomTheme ==
                                              AppCustomTheme.lightbrown
                                          ? controller.selectedBookContent
                                                      .length !=
                                                  index + 1
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12),
                                                  child: Row(
                                                    children: List.generate(
                                                        150 ~/ 3,
                                                        (index) => Expanded(
                                                              child: Container(
                                                                color: index %
                                                                            2 ==
                                                                        0
                                                                    ? Colors
                                                                        .transparent
                                                                    : Colors
                                                                        .grey,
                                                                height: 2,
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
            floatingActionButton: controller.isFetchContent.value || !_showUI
                ? const SizedBox()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (BibleInfo.chat == 1)
                        Builder(
                          builder: (buttonContext) => GestureDetector(
                            onTap: () {
                              if (isOpenChat) {
                                // Close the popover by popping the navigator
                                if (Navigator.of(buttonContext,
                                        rootNavigator: false)
                                    .canPop()) {
                                  Navigator.of(buttonContext,
                                          rootNavigator: false)
                                      .pop();
                                }
                                setState(() {
                                  isOpenChat = false;
                                });
                              } else {
                                setState(() {
                                  isOpenChat = true;
                                });
                                _showChatEntryPopover(buttonContext);
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
                                    color: CommanColor.whiteLightModePrimary(
                                        context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isOpenChat
                                        ? Icon(
                                            Icons.close,
                                            color: CommanColor
                                                .darkModePrimaryWhite(context),
                                            size: screenWidth > 450 ? 22 : 18,
                                          )
                                        : Image.asset(
                                            CommanColor.isDarkTheme(context)
                                                ? "assets/dark_modes/new-dark_chat.png"
                                                : "assets/Chat white.png",
                                            width: screenWidth > 600
                                                ? 26
                                                : screenWidth > 450
                                                    ? 24
                                                    : 22,
                                            height: screenWidth > 600
                                                ? 26
                                                : screenWidth > 450
                                                    ? 24
                                                    : 22,
                                          ),
                                  )),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: screenWidth > 600
                              ? 56 + (48 * 2)
                              : screenWidth > 450
                                  ? 50 + (40 * 2)
                                  : 35 + (32 * 2),
                        ),
                      floatingButton(
                        chapterNum: controller.selectedChapter.value,
                        bookName: controller.selectedBook.value,
                        contentList: controller.selectedVersesContent,
                        chapterCount: controller.selectedBookChapterCount.value,
                        audioData: controller.audioData.value,
                        bookNum: controller.selectedBookNum.value,
                        internetConnection: controller.connectionStatus,
                        textToSpeechLoad: controller.loadTextToSpeech.value,
                        audioPlayer: audioPlayer,
                      ),
                    ],
                  ),
            drawer: controller.isFetchContent.value
                ? const SizedBox()
                : Drawer(
                    backgroundColor: p.Provider.of<ThemeProvider>(context)
                                .currentCustomTheme ==
                            AppCustomTheme.vintage
                        ? CommanColor.white
                        : p.Provider.of<ThemeProvider>(context).backgroundColor,
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: ListView(
                      // Important: Remove any padding from the ListView.
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(
                          height: 120,
                          child: DrawerHeader(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: CommanColor.lightDarkPrimary(context),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    bibleName,
                                    style: CommanStyle.white16600,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: () {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(
                                () => isLoggedIn
                                    ? const ProfileScreen()
                                    : LoginScreen(hasSkip: false),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/My Account.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'My Account',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(() => const DailyVerse(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          dense: true,
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/Daily verse.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Daily Verses',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        if (BibleInfo.chat == 1)
                          ListTile(
                            dense: true,
                            onTap: () async {
                              Get.to(ChatScreen());
                            },
                            visualDensity:
                                const VisualDensity(horizontal: 0, vertical: 0),
                            leading: Image.asset(
                              "assets/Chat icon.png",
                              height: 24,
                              width: 24,
                            ),
                            title: Text(
                              'Chat',
                              style: CommanStyle.bothPrimary16600(context),
                            ),
                          ),
                        // ListTile(
                        //   dense: true,
                        //   onTap: () async {
                        //     Get.back();

                        //     // Check internet connectivity before opening chat
                        //     try {
                        //       final hasInternet = await InternetConnection()
                        //           .hasInternetAccess
                        //           .timeout(const Duration(seconds: 3),
                        //               onTimeout: () => false);

                        //       if (!hasInternet) {
                        //         Constants.showToast("No internet connection");
                        //         return;
                        //       }
                        //     } catch (e) {
                        //       Constants.showToast("No internet connection");
                        //       return;
                        //     }

                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     Get.to(() => const TawkChatScreen(),
                        //         transition: Transition.cupertinoDialog,
                        //         duration: const Duration(milliseconds: 300));
                        //   },
                        //   visualDensity:
                        //       const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: Icon(
                        //     Icons.support_agent,
                        //     size: 24,
                        //     color:
                        //         Provider.of<ThemeProvider>(context).themeMode ==
                        //                 ThemeMode.dark
                        //             ? CommanColor.darkPrimaryColor
                        //             : CommanColor.lightModePrimary,
                        //   ),
                        //   title: Text(
                        //     'Chat Us',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        // ListTile(
                        //   dense: true,
                        //   onTap: () async {
                        //     Get.back();
                        //     await SharPreferences.setString('OpenAd', '1');
                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     Get.to(
                        //         () => SearchScreen(
                        //               controller: controller,
                        //             ),
                        //         transition: Transition.cupertinoDialog,
                        //         duration: const Duration(milliseconds: 300));
                        //   },
                        //   visualDensity:
                        //       const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: Image.asset(
                        //     "assets/home icons/search.png",
                        //     height: 24,
                        //     width: 24,
                        //   ),
                        //   title: Text(
                        //     'Search',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        ListTile(
                          dense: true,
                          onTap: () {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(() => const LibraryScreen(),
                                    transition: Transition.cupertinoDialog,
                                    duration:
                                        const Duration(milliseconds: 300))!
                                .then((value) {
                              controller.getSelectedChapterAndBook();
                            });
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/My Library.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'My Library',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: () async {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            // Check internet connection before navigating
                            final hasInternet =
                                await InternetConnection().hasInternetAccess;
                            if (!hasInternet) {
                              Constants.showToast(
                                  'Check Your Internet Connection');
                              return;
                            }
                            // Check if connection is slow (mobile only, likely 2G)
                            final connectivity = Connectivity();
                            final connectivityResult =
                                await connectivity.checkConnectivity();
                            final isMobileOnly = connectivityResult
                                    .contains(ConnectivityResult.mobile) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.wifi) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.ethernet);
                            if (isMobileOnly) {
                              // Show toast after a delay if still loading (slow connection)
                              Future.delayed(const Duration(seconds: 2), () {
                                Constants.showToast('Internet is Slow');
                              });
                            }
                            Get.to(() => const WallpaperScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/Wallpaper.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Wallpapers',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: () async {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            // Check internet connection before navigating
                            final hasInternet =
                                await InternetConnection().hasInternetAccess;
                            if (!hasInternet) {
                              Constants.showToast(
                                  'Check Your Internet Connection');
                              return;
                            }
                            // Check if connection is slow (mobile only, likely 2G)
                            final connectivity = Connectivity();
                            final connectivityResult =
                                await connectivity.checkConnectivity();
                            final isMobileOnly = connectivityResult
                                    .contains(ConnectivityResult.mobile) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.wifi) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.ethernet);
                            if (isMobileOnly) {
                              // Show toast after a delay if still loading (slow connection)
                              Future.delayed(const Duration(seconds: 2), () {
                                Constants.showToast('Internet is Slow');
                              });
                            }
                            Get.to(() => const QuoteScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/Quotes.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Quotes',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: () {
                            Get.back();
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(() => const CalendarScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading:
                              // const Icon(
                              //   Icons.calendar_month,
                              //   color: Color(0XFF805531),
                              //   size: 26,
                              // ),
                              Image.asset(
                            "assets/home icons/Artboard – 35.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Calendar',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        // ListTile(
                        //   dense: true,
                        //   onTap: () async {
                        //     // If offline, show toast and do not navigate
                        //     final connectivityResult =
                        //         await Connectivity().checkConnectivity();
                        //     final hasConnection = connectivityResult
                        //             .isNotEmpty &&
                        //         (connectivityResult
                        //                 .contains(ConnectivityResult.wifi) ||
                        //             connectivityResult
                        //                 .contains(ConnectivityResult.mobile) ||
                        //             connectivityResult
                        //                 .contains(ConnectivityResult.ethernet));
                        //     if (!hasConnection) {
                        //       await Future.delayed(
                        //           const Duration(milliseconds: 500));
                        //       final retry =
                        //           await Connectivity().checkConnectivity();
                        //       final retryHasConnection = retry.isNotEmpty &&
                        //           (retry.contains(ConnectivityResult.wifi) ||
                        //               retry.contains(
                        //                   ConnectivityResult.mobile) ||
                        //               retry.contains(
                        //                   ConnectivityResult.ethernet));
                        //       if (!retryHasConnection) {
                        //         try {
                        //           final hasInternet = await InternetConnection()
                        //               .hasInternetAccess;
                        //           if (!hasInternet) {
                        //             return Constants.showToast(
                        //                 "No Internet Connection");
                        //           } else {
                        //             return Constants.showToast(
                        //                 "Check your Internet connection");
                        //           }
                        //         } catch (_) {
                        //           return Constants.showToast(
                        //               "No Internet Connection");
                        //         }
                        //       }
                        //     }

                        //     Get.back();
                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     Get.to(() => const biblebookapp.StudyPlansScreen(),
                        //         transition: Transition.cupertinoDialog,
                        //         duration: const Duration(milliseconds: 300));
                        //   },
                        //   visualDensity:
                        //       const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: Icon(
                        //     Icons.menu_book,
                        //     size: 24,
                        //     color:
                        //         Provider.of<ThemeProvider>(context).themeMode ==
                        //                 ThemeMode.dark
                        //             ? CommanColor.darkPrimaryColor
                        //             : CommanColor.lightModePrimary,
                        //   ),
                        //   title: Text(
                        //     'Study Plans',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        // ListTile(
                        //   dense: true,
                        //   onTap: () {
                        //     Get.back();
                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     if (isLoggedIn) {
                        //       showImportExportInfo(context, () async {
                        //         final permission =
                        //             await ExportDb.requestStoragePermission();
                        //         if (permission) {
                        //           updateLoading(true,
                        //               mess: 'Exporting the data. Please wait');
                        //           await ExportDb.getAllDataToExport(context);
                        //           updateLoading(false);
                        //         } else {
                        //           Constants.showToast(
                        //               "Permission is required to export the data.");
                        //         }
                        //       });
                        //     } else {
                        //       backupNotification(
                        //           context: context,
                        //           message:
                        //               " Account is required to access this feature ");
                        //     }
                        //   },
                        //   visualDensity:
                        //       const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: const Icon(
                        //     Icons.file_upload_outlined,
                        //     color: Color(0XFF805531),
                        //   ),
                        //   title: Text(
                        //     'Export',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (isLoggedIn) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const MainBackupDialog(),
                              );
                            } else {
                              backupNotification(
                                  context: context,
                                  message:
                                      " Account is required to access this feature ");
                              //     }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth > 450 ? 15 : 17),
                                  child:
                                      // Icon(
                                      //   size: screenWidth > 450 ? 27 : 24,
                                      //   Icons.cloud_download,
                                      //   color: Color(0XFF805531),
                                      // ),
                                      Image.asset(
                                    "assets/home icons/Frame 3631.png",
                                    height: 24,
                                    width: 24,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: screenWidth > 450 ? 1 : 20.0),
                                  child: Text(
                                    "Back up",
                                    style:
                                        CommanStyle.bothPrimary16600(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (BibleInfo.enableEShop == true)
                          //! E-Products
                          ListTile(
                            dense: true,
                            onTap: () async {
                              Get.back();
                              await SharPreferences.setString('OpenAd', '1');
                              if (controller.adFree.value == false) {
                                controller.bannerAd?.dispose();
                                controller.bannerAd?.load();
                              }
                              Get.to(() => const EProductsScreen(),
                                  transition: Transition.cupertinoDialog,
                                  duration: const Duration(milliseconds: 300));
                            },
                            visualDensity:
                                const VisualDensity(horizontal: 0, vertical: 0),
                            leading: Image.asset(
                              "assets/eproduct-d.png",
                              color: CommanColor.lightModePrimary,
                              width: 20,
                              height: 20,
                            ),
                            title: Text(
                              'e-Products',
                              style: CommanStyle.bothPrimary16600(context),
                            ),
                          ),
                        //Books

                        if (controller.bookAdsStatus.value == 1)
                          ListTile(
                            dense: true,
                            onTap: () async {
                              Get.back();
                              await SharPreferences.setString('OpenAd', '1');
                              if (controller.adFree.value == false) {
                                controller.bannerAd?.dispose();
                                controller.bannerAd?.load();
                              }
                              // Check internet connection before navigating
                              final hasInternet =
                                  await InternetConnection().hasInternetAccess;
                              if (!hasInternet) {
                                Constants.showToast(
                                    'Check Your Internet Connection');
                                return;
                              }
                              // Check if connection is slow (mobile only, likely 2G)
                              final connectivity = Connectivity();
                              final connectivityResult =
                                  await connectivity.checkConnectivity();
                              final isMobileOnly = connectivityResult
                                      .contains(ConnectivityResult.mobile) &&
                                  !connectivityResult
                                      .contains(ConnectivityResult.wifi) &&
                                  !connectivityResult
                                      .contains(ConnectivityResult.ethernet);
                              if (isMobileOnly) {
                                // Show toast after a delay if still loading (slow connection)
                                Future.delayed(const Duration(seconds: 2), () {
                                  Constants.showToast('Internet is Slow');
                                });
                              }
                              Get.to(
                                  () => BooksScreen(
                                      bookAdId: controller.bookAdsAppId.value),
                                  transition: Transition.cupertinoDialog,
                                  duration: const Duration(milliseconds: 300));
                            },
                            visualDensity:
                                const VisualDensity(horizontal: 0, vertical: 0),
                            leading:
                                // const Icon(
                                //   Icons.menu_book,
                                //   color: Color(0XFF805531),
                                //   size: 26,
                                // ),
                                Image.asset(
                              "assets/home icons/book.png",
                              height: 24,
                              width: 24,
                            ),
                            title: Text(
                              'Books',
                              style: CommanStyle.bothPrimary16600(context),
                            ),
                          ),

                        // Exit Offer / Limited Time Offer
                        // ListTile(
                        //   dense: true,
                        //   onTap: () async {
                        //     Get.back();
                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     await SubscriptionScreen.showExitOfferFromHomeScreen(context, controller);
                        //   },
                        //   visualDensity:
                        //   const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: Container(
                        //     padding: const EdgeInsets.all(4),
                        //     decoration: BoxDecoration(
                        //       color: Colors.red.withOpacity(0.1),
                        //       borderRadius: BorderRadius.circular(4),
                        //     ),
                        //     child: const Icon(
                        //       Icons.local_offer,
                        //       color: Colors.red,
                        //       size: 18,
                        //     ),
                        //   ),
                        //   title: Text(
                        //     'Limited Time Offer',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        // More apps
                        ListTile(
                          dense: true,
                          onTap: () async {
                            Get.back();
                            await SharPreferences.setString('OpenAd', '1');
                            // Check internet connection before showing More Apps
                            final hasInternet =
                                await InternetConnection().hasInternetAccess;
                            if (!hasInternet) {
                              Constants.showToast(
                                  'Check Your Internet Connection');
                              return;
                            }
                            final connectivity = Connectivity();
                            final connectivityResult =
                                await connectivity.checkConnectivity();
                            // Check if connection is slow (mobile only, likely 2G)
                            final isMobileOnly = connectivityResult
                                    .contains(ConnectivityResult.mobile) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.wifi) &&
                                !connectivityResult
                                    .contains(ConnectivityResult.ethernet);
                            if (isMobileOnly) {
                              // Show toast after a delay if still loading (slow connection)
                              Future.delayed(const Duration(seconds: 2), () {
                                Constants.showToast('Internet is Slow');
                              });
                            }
                            if (controller.adFree.value == false) {
                              controller.bannerAd?.dispose();
                              controller.bannerAd?.load();
                            }
                            Get.to(() => const MoreAppsScreen(),
                                transition: Transition.cupertinoDialog,
                                duration: const Duration(milliseconds: 300));
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/More apps.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'More Apps',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        // Survey
                        // ListTile(
                        //   dense: true,
                        //   onTap: () async {
                        //     Get.back();
                        //     if (controller.adFree.value == false) {
                        //       controller.bannerAd?.dispose();
                        //       controller.bannerAd?.load();
                        //     }
                        //     Get.to(() => const FeedbackWebView(),
                        //         transition: Transition.cupertinoDialog,
                        //         duration: const Duration(milliseconds: 300));
                        //   },
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
                        ListTile(
                          dense: true,
                          onTap: () {
                            Get.back();
                            SharPreferences.getBoolean(
                                    SharPreferences.isNotificationOn)
                                .then((value) {
                              bool natificationValue;
                              value != null
                                  ? natificationValue = value
                                  : natificationValue = true;
                              Get.offAll(() => SettingScreen(
                                        notificationValue: natificationValue,
                                      ))!
                                  .then((value) async {
                                SharPreferences.getString(
                                        SharPreferences.selectedFontSize)
                                    .then((value) {
                                  value == null
                                      ? controller.fontSize.value = 19.0
                                      : controller.fontSize.value =
                                          double.parse(value.toString());
                                });
                                SharPreferences.getString(
                                        SharPreferences.selectedFontFamily)
                                    .then((value) {
                                  value == null
                                      ? controller.selectedFontFamily.value =
                                          "Arial"
                                      : controller.selectedFontFamily.value =
                                          value;
                                });
                              });
                            });
                          },
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/setting.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            "Settings",
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: () async {
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
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            "assets/home icons/Share.png",
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Share',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        ListTile(
                          dense: true,
                          onTap: (() async {
                            Get.back();
                            final hasInternet =
                                await InternetConnection().hasInternetAccess;
                            if (!hasInternet) {
                              Constants.showToast(
                                  "No Internet Connection", 5000);
                              return;
                            }
                            await SharPreferences.setString('OpenAd', '1');
                            // Open Tawk chat screen instead of external feedback form
                            Get.to(() => const TawkChatScreen());
                          }),
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: 0),
                          leading: Image.asset(
                            //Images.rateUs(context),
                            'assets/home icons/customer-service 2.png',
                            height: 24,
                            width: 24,
                          ),
                          title: Text(
                            'Contact Us',
                            style: CommanStyle.bothPrimary16600(context),
                          ),
                        ),
                        // ListTile(
                        //   dense: true,
                        //   onTap: () {
                        //     Get.back();
                        //     Get.to(() => const AboutUs(),
                        //         transition: Transition.cupertinoDialog,
                        //         duration: const Duration(milliseconds: 300));
                        //   },
                        //   visualDensity:
                        //       const VisualDensity(horizontal: 0, vertical: 0),
                        //   leading: Image.asset(
                        //     Images.aboutUs(context),
                        //     height: 24,
                        //     width: 24,
                        //   ),
                        //   title: Text(
                        //     'About Us',
                        //     style: CommanStyle.bothPrimary16600(context),
                        //   ),
                        // ),
                        const SizedBox(
                          height: 2,
                        ),
                        controller.isAdsCompletlyDisabled.value
                            ? const SizedBox.shrink()
                            : controller.adFree.value
                                ? DateTime.tryParse(
                                            '${controller.RewardAdExpireDate}') !=
                                        null
                                    ? Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        color: CommanColor.lightDarkPrimary(
                                            context),
                                        child: ListTile(
                                          dense: true,
                                          onTap: () {
                                            Navigator.pop(context);
                                            showModalBottomSheet<void>(
                                              context: context,
                                              backgroundColor: Colors.white,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                  top: Radius.circular(25),
                                                ),
                                              ),
                                              clipBehavior:
                                                  Clip.antiAliasWithSaveLayer,
                                              builder: (BuildContext context) {
                                                final startTime = DateTime.parse(
                                                    '${controller.RewardAdExpireDate}');

                                                DateTime ExpiryDate = startTime;

                                                final currentTime =
                                                    DateTime.now();
                                                final diffDy =
                                                    ExpiryDate.difference(
                                                            currentTime)
                                                        .inDays;

                                                return Stack(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          20),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          20))),
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.30,
                                                      // color: Colors.white,
                                                      child:
                                                          SingleChildScrollView(
                                                        physics:
                                                            const ScrollPhysics(),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: <Widget>[
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Image.asset(
                                                                    "assets/feedbacklogo.png",
                                                                    height: 120,
                                                                    width: 120,
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context)),
                                                              ],
                                                            ),
                                                            // SizedBox(height: 5,),
                                                            Text(
                                                              'Subscription Info',
                                                              style: TextStyle(
                                                                  letterSpacing:
                                                                      BibleInfo
                                                                          .letterSpacing,
                                                                  fontSize:
                                                                      BibleInfo
                                                                              .fontSizeScale *
                                                                          16,
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Text(
                                                                diffDy > 365
                                                                    ? 'Your subscription will never expire'
                                                                    : '$diffDy day(s) left for the renewal of the subscription.',
                                                                style: TextStyle(
                                                                    letterSpacing:
                                                                        BibleInfo
                                                                            .letterSpacing,
                                                                    fontSize: screenWidth <
                                                                            380
                                                                        ? BibleInfo.fontSizeScale *
                                                                            13
                                                                        : BibleInfo.fontSizeScale *
                                                                            15,
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400)),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                                diffDy > 365
                                                                    ? 'Your subscription period is lifetime'
                                                                    : 'Your subscription expires on ${DateFormat('dd-MM-yyyy').format(ExpiryDate)}',
                                                                style:
                                                                    TextStyle(
                                                                  letterSpacing:
                                                                      BibleInfo
                                                                          .letterSpacing,
                                                                  fontSize: screenWidth <
                                                                          380
                                                                      ? BibleInfo
                                                                              .fontSizeScale *
                                                                          13
                                                                      : BibleInfo
                                                                              .fontSizeScale *
                                                                          15,
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                )),
                                                            const SizedBox(
                                                                height: 5),
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
                                                          color: CommanColor
                                                              .lightDarkPrimary(
                                                                  context),
                                                          size: 25,
                                                        ),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    )
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          visualDensity: const VisualDensity(
                                              horizontal: 0, vertical: 0),
                                          leading: const Icon(
                                            Icons.info_outline_rounded,
                                            size: 28,
                                            color: Colors.white,
                                          ),
                                          title: const Text("Subscription Info",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  letterSpacing:
                                                      BibleInfo.letterSpacing,
                                                  fontSize:
                                                      BibleInfo.fontSizeScale *
                                                          16,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      )
                                    : Visibility(
                                        visible:
                                            controller.isSubscriptionEnabled ??
                                                false,
                                        child: Container(
                                          color: CommanColor.lightDarkPrimary(
                                              context),
                                          child: ListTile(
                                            dense: true,
                                            onTap: () async {
                                              adsIcon = false;
                                              Get.back();
                                              await SharPreferences.setString(
                                                  'OpenAd', '1');
                                              // Use constants as fallback when SharedPreferences are empty (first time loading)
                                              final sixMonthPlan =
                                                  await SharPreferences
                                                          .getString(
                                                              'sixMonthPlan') ??
                                                      BibleInfo.sixMonthPlanid;
                                              final oneYearPlan =
                                                  await SharPreferences
                                                          .getString(
                                                              'oneYearPlan') ??
                                                      BibleInfo.oneYearPlanid;
                                              final lifeTimePlan =
                                                  await SharPreferences
                                                          .getString(
                                                              'lifeTimePlan') ??
                                                      BibleInfo.lifeTimePlanid;
                                              Get.to(
                                                () => SubscriptionScreen(
                                                  sixMonthPlan: sixMonthPlan,
                                                  oneYearPlan: oneYearPlan,
                                                  lifeTimePlan: lifeTimePlan,
                                                  checkad: 'theme',
                                                ),
                                                transition:
                                                    Transition.cupertinoDialog,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                              );
                                            },
                                            visualDensity: const VisualDensity(
                                                horizontal: 0, vertical: 0),
                                            leading: Image.asset(
                                              Images.adFree(context),
                                              height: 24,
                                              width: 24,
                                            ),
                                            title: const Text("Remove Ads",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize: BibleInfo
                                                            .fontSizeScale *
                                                        16,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ),
                                      )
                                : Visibility(
                                    visible: controller.isSubscriptionEnabled ??
                                        false,
                                    child: Container(
                                      color:
                                          CommanColor.lightDarkPrimary(context),
                                      child: ListTile(
                                        dense: true,
                                        onTap: () async {
                                          adsIcon = false;
                                          Get.back();
                                          await SharPreferences.setString(
                                              'OpenAd', '1');
                                          // Use constants as fallback when SharedPreferences are empty (first time loading)
                                          final sixMonthPlan =
                                              await SharPreferences.getString(
                                                      'sixMonthPlan') ??
                                                  BibleInfo.sixMonthPlanid;
                                          final oneYearPlan =
                                              await SharPreferences.getString(
                                                      'oneYearPlan') ??
                                                  BibleInfo.oneYearPlanid;
                                          final lifeTimePlan =
                                              await SharPreferences.getString(
                                                      'lifeTimePlan') ??
                                                  BibleInfo.lifeTimePlanid;
                                          Get.to(
                                            () => SubscriptionScreen(
                                              sixMonthPlan: sixMonthPlan,
                                              oneYearPlan: oneYearPlan,
                                              lifeTimePlan: lifeTimePlan,
                                              checkad: 'theme',
                                            ),
                                            transition:
                                                Transition.cupertinoDialog,
                                            duration: const Duration(
                                                milliseconds: 300),
                                          );
                                        },
                                        visualDensity: const VisualDensity(
                                            horizontal: 0, vertical: 0),
                                        leading: Image.asset(
                                          Images.adFree(context),
                                          height: 24,
                                          width: 24,
                                        ),
                                        title: const Text("Remove Ads",
                                            style: TextStyle(
                                                color: Colors.white,
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        16,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                  ),
            bottomNavigationBar: const SizedBox(
              height: 1,
            ),
          );
        },
      ),
    );
  }

//share and rating
  void showMainFeedbackDialog(BuildContext context) {
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
                          image: AssetImage("assets/Icon-1024.png"))),
                ),
                // const Icon(Icons.menu_book, size: 48, color: Colors.brown),
                const SizedBox(height: 10),
                Text(
                  "How are you feeling today\nwhile using the app?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildEmojiOption(
                  context,
                  emoji: "😍",
                  text: "Great!",
                  color: Colors.green.shade100,
                  onTap: () => _showRateAppDialog(context),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: "😊",
                  text: "Okay",
                  color: Colors.orange.shade100,
                  onTap: () => _showFeedbackDialog(context, "😊"),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: "😔",
                  text: "Could be better...",
                  color: Colors.red.shade100,
                  onTap: () => _showFeedbackDialog(context, "😔"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiOption(BuildContext context,
      {required String emoji,
      required String text,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(fontSize: 16, color: CommanColor.black)),
          ],
        ),
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    Navigator.of(context).pop(); // close previous dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;
        double screenWidth = MediaQuery.of(context).size.width;
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
                const Text("😍", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 15),
                Text(
                  "Thanks for the love! 💛",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 19 : 16,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Leave us a quick rating to help others\nexperience God's Word too!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet
                        ? 19
                        : screenWidth < 380
                            ? 12.5
                            : 14,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Add your rate app logic here
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    if (connectivityResult[0] == ConnectivityResult.none) {
                      Constants.showToast("Check your Internet connection");
                    }
                    await SharPreferences.setString('OpenAd', '1');
                    _requestReview();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  child: Text(
                    "Rate the app",
                    style: TextStyle(
                      color: CommanColor.white,
                      fontSize: isTablet ? 17 : null,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Later",
                    style: TextStyle(
                      color: CommanColor.black,
                      fontSize: isTablet ? 17 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                Text(emoji, style: const TextStyle(fontSize: 40)),
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

                    // Open in-app chat screen (TAWK) instead of external feedback URL
                    // This keeps the feedback experience inside the app.
                    Get.to(() => const TawkChatScreen());
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
    );
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
    );
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
                style: ElevatedButton.styleFrom(backgroundColor: colour),
                child: Text(
                  showButton ? 'Rate Us' : 'Feedback',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () =>
                    _handleRatingButtonPress(state, showButton, currentTime),
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

  Future<void> _launchFeedbackForm() async {
    // Open Tawk chat screen for feedback (same as Chat Us)
    Get.to(const TawkChatScreen());
  }

  void _attachScrollListener(GetXState<DashBoardController> state) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_scrollListenerAttached) {
        _scrollListenerAttached = true;
        state.controller?.autoScrollController.value.addListener(() {
          final scrollController = state.controller?.autoScrollController.value;
          if (scrollController == null || !scrollController.hasClients) return;

          // Check if controller has exactly one position to avoid multiple scroll views error
          if (scrollController.positions.length != 1) return;

          final direction = scrollController.position.userScrollDirection;
          final currentOffset = scrollController.position.pixels;

          // If at the top, always show UI
          if (currentOffset <= 0) {
            if (!_showUI && mounted) {
              setState(() {
                _showUI = true;
              });
            }
          } else {
            // Update UI visibility based on scroll direction
            if (direction == ScrollDirection.reverse) {
              // Scrolling up - hide UI
              if (_showUI && mounted) {
                setState(() {
                  _showUI = false;
                });
              }
            } else if (direction == ScrollDirection.forward) {
              // Scrolling down - show UI
              if (!_showUI && mounted) {
                setState(() {
                  _showUI = true;
                });
              }
            }
          }

          // Existing logic for scrollHideShowIcon
          if (direction == ScrollDirection.reverse ||
              direction == ScrollDirection.forward) {
            state.controller?.scrollHideShowIcon.value = false;
            Future.delayed(const Duration(milliseconds: 1), () {
              state.controller?.scrollHideShowIcon.value = true;
            });
          }
        });
      }
    });
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

  void _handleAdExpiration(GetXState<DashBoardController> state) async {
    final value =
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
    state.controller!.RewardAdExpireDate.value = value.toString();
    RewardAdExpireDate = value;
    debugPrint("RewardAdExpireDate is $RewardAdExpireDate");

    Future.delayed(Duration.zero, () {
      state.controller!.loadApi();
    });

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

  void _loadInitialData(GetXState<DashBoardController> state) {
    state.controller!.selectedIndex.value = -1;

    Future.delayed(Duration.zero, () async {
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
        state.controller!.getBookContentForRead();
      } else {
        // Use normal chapter loading for other flows
        state.controller!.getSelectedChapterAndBook();
      }

      state.controller!.getFont();
    });

    Future.delayed(const Duration(seconds: 6), () {
      state.controller?.readHighlight.value = false;
    });

    Future.delayed(Duration.zero, () {
      state.controller?.autoScrollController.value = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: state.controller!.scrollDirection,
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
    // Show empty content message
    return Center(
      child: Text(
        "Content is Empty",
        style: CommanStyle.bw16500(context),
      ),
    );
  }

  // Helper method to scroll to verse and highlight it
  void _scrollAndHighlightVerse(
      GetXState<DashBoardController> state, int verseIndex) {
    try {
      // Scroll to the verse
      state.controller!.scrollToIndex(verseIndex);

      // Highlight the verse when coming from chat
      if (widget.From.toString() == "chat") {
        // Set selectedIndex to highlight the verse (verse numbers are 1-indexed, so subtract 1)
        // Make sure the index is within bounds
        final highlightIndex = verseIndex - 1;
        if (highlightIndex >= 0 &&
            highlightIndex < state.controller!.selectedBookContent.length) {
          state.controller!.selectedIndex.value = highlightIndex;
          state.controller!.readHighlight.value = true;

          // Keep highlight for longer when from chat
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              state.controller?.readHighlight.value = false;
              state.controller?.selectedIndex.value = -1;
            }
          });
        }
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
                          transition: Transition.cupertinoDialog,
                          duration: const Duration(milliseconds: 300));
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
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
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

  const FramedVerseContainer({
    super.key,
    required this.backgroundImagePath,
    required this.child,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final bgImages = [
      "assets/im1.jpg",
      "assets/im2.jpg",
      "assets/im3.jpg",
      "assets/im4.jpg",
      "assets/im5.jpg",
    ];
    String randomBgImage = bgImages[random.nextInt(bgImages.length)];

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
          // Background image with dark blend
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(randomBgImage),
                fit: BoxFit.cover,
                // colorFilter: ColorFilter.mode(

                //   BlendMode.darken,
                // ),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Optional frame overlay
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

          // Main content
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
  static Future<void> show(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600; // detect iPad
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('premiumalrt', '2');
    showDialog(
      context: context,
      barrierDismissible: false, // must tap button
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.2 : 24,
            vertical: isTablet ? size.height * 0.2 : 24,
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 32 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Image
                Image.asset(
                  "assets/welcomeb.png", // replace with your "Welcome" board image
                  height: isTablet ? 110 : 95,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "Welcome to the\nPremium Faith Family!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 14),

                // Description
                Text(
                  "You now have full access to tools\n and verses that'll guide you daily.\n"
                  "Let's walk closer with Jesus together.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 14,
                    height: 1.5,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 28),

                // Join Now Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5C3D),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                        // TODO: add navigation logic
                      },
                      child: Text(
                        "Join now",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
