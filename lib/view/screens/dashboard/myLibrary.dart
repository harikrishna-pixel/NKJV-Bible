// ignore_for_file: use_full_hex_values_for_flutter_colors
import 'package:biblebookapp/core/export_db.dart';
import 'package:biblebookapp/core/library_backup_upload_service.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/quotes_library_widget.dart';
import 'package:biblebookapp/view/screens/dashboard/underLine_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/wallpaper_library_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import 'bookMarkScreen.dart';
import 'highlight_screen.dart';
import 'image_screen.dart';
import 'notes_screen.dart';

void showImportExportInfo(BuildContext context, Function() onTap) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  BibleInfo.exportText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onTap();
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CommanColor.whiteLightModePrimary(context),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                      child: Text(
                        'Okay, Export',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.w500,
                            color: CommanColor.darkModePrimaryWhite(context)),
                      )),
                )
              ],
            ),
          ));
    },
  );
}

void showImportInfo(BuildContext context, Function() onTap) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  BibleInfo.importText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onTap();
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CommanColor.whiteLightModePrimary(context),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                      child: Text(
                        'Okay, Import',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.w500,
                            color: CommanColor.darkModePrimaryWhite(context)),
                      )),
                )
              ],
            ),
          ));
    },
  );
}

class LibraryScreen extends StatefulWidget {
  final int initialIndex;
  const LibraryScreen({super.key, this.initialIndex = 0});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
// TabController? _tabcontroller;
  late TabController tabController;
  int selectedTap = 0;
  bool isLoading = false;
  String? message;
  String? user;
  // late User? user;
  @override
  void initState() {
    super.initState();
    checkuserloggedin();
    // user = FirebaseAuth.instance.currentUser;
    tabController = TabController(
        vsync: this, length: 7, initialIndex: widget.initialIndex);
  }

  checkuserloggedin() async {
    final cacheprovider = Provider.of<CacheNotifier>(context, listen: false);

    final data = await cacheprovider.readCache(key: 'user');
    // final dataname = await cacheprovider.readCache(key: 'name');
    if (data != null) {
      setState(() {
        user = data;
      });
    }
    // else {
    //   setState(() {
    //     isLoggedIn = false;
    //   });
    // }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  updateLoading(bool val, {String? mess}) {
    setState(() {
      isLoading = val;
      message = mess;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // debugPrint("sz current width - $screenWidth ");
    return Scaffold(
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                  AppCustomTheme.vintage
              ? BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(Images.bgImage(context)),
                      fit: BoxFit.fill))
              : null,
          child: SafeArea(
            child: Column(
              children: [
                // const SizedBox(
                //   height: 5,
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: screenWidth > 450 ? 30 : 20,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Text(
                        "My Library",
                        style: CommanStyle.appBarStyle(context).copyWith(
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 30
                                : BibleInfo.fontSizeScale * 18,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Subscription gate temporarily disabled — open backup directly.
                        // final downloadProvider =
                        //     Provider.of<DownloadProvider>(context,
                        //         listen: false);
                        // final subscriptionPlan =
                        //     await downloadProvider.getSubscriptionPlan();
                        // final isSubscribed = subscriptionPlan != null &&
                        //     subscriptionPlan.isNotEmpty &&
                        //     ['platinum', 'gold', 'silver'].contains(
                        //         subscriptionPlan.toLowerCase());
                        // if (isSubscribed) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const MainBackupDialog(),
                        );
                        // } else {
                        //   await SharPreferences.setString('OpenAd', '1');
                        //   if (!context.mounted) return;
                        //   showDialog(
                        //     context: context,
                        //     barrierDismissible: false,
                        //     builder: (ctx) {
                        //       final dlgWidth =
                        //           MediaQuery.of(ctx).size.width;
                        //       return Dialog(
                        //         backgroundColor: CommanColor.white,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius:
                        //               BorderRadius.circular(15),
                        //         ),
                        //         elevation: 16,
                        //         child: Padding(
                        //           padding: const EdgeInsets.symmetric(
                        //               horizontal: 16, vertical: 24),
                        //           child: Column(
                        //             mainAxisSize: MainAxisSize.min,
                        //             crossAxisAlignment:
                        //                 CrossAxisAlignment.stretch,
                        //             children: [
                        //               Text(
                        //                 "You're not subscribed. Subscribe to export and import your data.",
                        //                 textAlign: TextAlign.center,
                        //                 style: TextStyle(
                        //                   color: CommanColor.black,
                        //                   fontSize:
                        //                       dlgWidth > 450 ? 19 : 15,
                        //                 ),
                        //               ),
                        //               const SizedBox(height: 20),
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   Navigator.pop(ctx);
                        //                   final sixMonthPlan =
                        //                       BibleInfo.sixMonthPlanid;
                        //                   final oneYearPlan =
                        //                       BibleInfo.oneYearPlanid;
                        //                   final lifeTimePlan =
                        //                       BibleInfo.lifeTimePlanid;
                        //                   Get.to(
                        //                     () => SubscriptionScreen(
                        //                       sixMonthPlan: sixMonthPlan,
                        //                       oneYearPlan: oneYearPlan,
                        //                       lifeTimePlan: lifeTimePlan,
                        //                       checkad: 'library',
                        //                     ),
                        //                     transition:
                        //                         Transition.cupertinoDialog,
                        //                     duration: const Duration(
                        //                         milliseconds: 300),
                        //                   );
                        //                 },
                        //                 child: Container(
                        //                   padding: const EdgeInsets
                        //                       .symmetric(vertical: 8),
                        //                   decoration: BoxDecoration(
                        //                     color: CommanColor
                        //                         .lightDarkPrimary(ctx),
                        //                     borderRadius:
                        //                         const BorderRadius.all(
                        //                             Radius.circular(5)),
                        //                     boxShadow: const [
                        //                       BoxShadow(
                        //                           color: Colors.black26,
                        //                           blurRadius: 2)
                        //                     ],
                        //                   ),
                        //                   child: Text(
                        //                     'Subscribe',
                        //                     textAlign: TextAlign.center,
                        //                     style: TextStyle(
                        //                       letterSpacing:
                        //                           BibleInfo.letterSpacing,
                        //                       fontSize:
                        //                           BibleInfo.fontSizeScale *
                        //                               14,
                        //                       fontWeight: FontWeight.w500,
                        //                       color: Colors.white,
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //               const SizedBox(height: 12),
                        //               GestureDetector(
                        //                 onTap: () =>
                        //                     Navigator.pop(ctx),
                        //                 child: Container(
                        //                   padding: const EdgeInsets
                        //                       .symmetric(vertical: 8),
                        //                   decoration: BoxDecoration(
                        //                     color: CommanColor.lightGrey1,
                        //                     borderRadius:
                        //                         const BorderRadius.all(
                        //                             Radius.circular(5)),
                        //                     boxShadow: const [
                        //                       BoxShadow(
                        //                           color: Colors.black26,
                        //                           blurRadius: 2)
                        //                     ],
                        //                   ),
                        //                   child: Text(
                        //                     'Cancel',
                        //                     textAlign: TextAlign.center,
                        //                     style: TextStyle(
                        //                       letterSpacing:
                        //                           BibleInfo.letterSpacing,
                        //                       fontSize:
                        //                           BibleInfo.fontSizeScale *
                        //                               14,
                        //                       fontWeight: FontWeight.w500,
                        //                       color: CommanColor.black),
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   );
                        // }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Image.asset(
                          "assets/home icons/Frame 3631.png",
                          height: screenWidth > 450 ? 28 : 22,
                          width: screenWidth > 450 ? 28 : 22,
                        ),
                      ),
                    ),
                    // PopupMenuButton(
                    //   color: Provider.of<ThemeProvider>(context).themeMode ==
                    //           ThemeMode.dark
                    //       ? CommanColor.darkPrimaryColor
                    //       : CommanColor.white,
                    //   child: Icon(
                    //     size: screenWidth > 450 ? 35 : 20,
                    //     Icons.menu_rounded,
                    //     color:
                    //         CommanColor.inDarkWhiteAndInLightPrimary(context),
                    //   ),
                    //   onSelected: (val) async {
                    //     if (user != null) {
                    //       if (val == 'export') {
                    //         await SharPreferences.setString('OpenAd', '1');
                    //         Constants.showToast(
                    //             "Save your Verse markings in My Library");

                    //         showDialog(
                    //           context: context,
                    //           builder: (_) => BackupDialog(
                    //             type: "export",
                    //             onPrimaryPressed: () async {
                    //               final permission =
                    //                   await ExportDb.requestStoragePermission();
                    //               if (permission) {
                    //                 updateLoading(true, mess: 'Please wait...');
                    //                 await SharPreferences.setString(
                    //                     'OpenAd', '1');
                    //                 if (context.mounted) {
                    //                   await ExportDb.getAllDataToExport(
                    //                       context);
                    //                 }
                    //                 await SharPreferences.setString(
                    //                     'OpenAd', '1');

                    //                 updateLoading(false);
                    //               } else {
                    //                 await SharPreferences.setString(
                    //                     'OpenAd', '1');
                    //                 Constants.showToast(
                    //                     "Permission is required to export the data.");
                    //               }
                    //             },
                    //             onSecondaryPressed: () {
                    //               Navigator.of(context).pop();
                    //             },
                    //           ),
                    //         );

                    //         // showImportExportInfo(context, () async {
                    //         //   await SharPreferences.setString(
                    //         //       'OpenAd', '1');
                    //         //   final permission = await ExportDb
                    //         //       .requestStoragePermission();
                    //         //   if (permission) {
                    //         //     updateLoading(true,
                    //         //         mess:
                    //         //             'Exporting the data. Please wait');
                    //         //     if (context.mounted) {
                    //         //       await ExportDb.getAllDataToExport(
                    //         //           context);
                    //         //     }
                    //         //     await SharPreferences.setString(
                    //         //         'OpenAd', '1');
                    //         //     updateLoading(false);
                    //         //   } else {
                    //         //     await SharPreferences.setString(
                    //         //         'OpenAd', '1');
                    //         //     Constants.showToast(
                    //         //         "Permission is required to export the data.");
                    //         //   }
                    //         // });
                    //       } else {
                    //         showDialog(
                    //           context: context,
                    //           builder: (_) => BackupDialog(
                    //             type: "import",
                    //             onPrimaryPressed: () async {
                    //               await SharPreferences.setString(
                    //                   'OpenAd', '1');
                    //               updateLoading(true, mess: 'Please wait...');

                    //               await ExportDb.importData().then((v) {
                    //                 updateLoading(false);
                    //                 if (v == "File is not selected") {
                    //                   Constants.showToast(
                    //                       "File is not selected");
                    //                 }
                    //               });
                    //               await SharPreferences.setString(
                    //                   'OpenAd', '1');

                    //               Get.offAll(() => HomeScreen(
                    //                   From: "splash",
                    //                   selectedVerseNumForRead: "",
                    //                   selectedBookForRead: "",
                    //                   selectedChapterForRead: "",
                    //                   selectedBookNameForRead: "",
                    //                   selectedVerseForRead: ""));
                    //             },
                    //             onSecondaryPressed: () {
                    //               Navigator.of(context).pop();
                    //             },
                    //           ),
                    //         );
                    //         // showImportInfo(context, () async {
                    //         //   await SharPreferences.setString(
                    //         //       'OpenAd', '1');
                    //         //   updateLoading(true,
                    //         //       mess:
                    //         //           'Importing the data. Please wait');
                    //         //   await ExportDb.importData();

                    //         //   await SharPreferences.setString(
                    //         //       'OpenAd', '1');
                    //         //   updateLoading(false);
                    //         //   Get.offAll(() => HomeScreen(
                    //         //       From: "splash",
                    //         //       selectedVerseNumForRead: "",
                    //         //       selectedBookForRead: "",
                    //         //       selectedChapterForRead: "",
                    //         //       selectedBookNameForRead: "",
                    //         //       selectedVerseForRead: ""));
                    //         // });
                    //       }
                    //     } else {
                    //       await SharPreferences.setString('OpenAd', '1');
                    //       updateLoading(false);
                    //       backupNotification(
                    //           context: context,
                    //           message:
                    //               " Account is required to access this feature ");
                    //       // Constants.showToast('You have to login first');
                    //       // Get.to(() => LoginScreen(hasSkip: false),
                    //       //     transition: Transition.cupertinoDialog,
                    //       //     duration:
                    //       //         const Duration(milliseconds: 300));
                    //     }
                    //   },
                    //   itemBuilder: (BuildContext bc) {
                    //     return [
                    //       PopupMenuItem(
                    //           value: 'export',
                    //           child: Row(
                    //             children: [
                    //               Icon(
                    //                 Icons.file_upload_outlined,
                    //                 color: CommanColor.whiteBlack(context),
                    //               ),
                    //               const Text('Export')
                    //             ],
                    //           )),
                    //       PopupMenuItem(
                    //           value: 'Import',
                    //           child: Row(
                    //             children: [
                    //               Icon(
                    //                 Icons.file_download_outlined,
                    //                 color: CommanColor.whiteBlack(context),
                    //               ),
                    //               const Text('Import')
                    //             ],
                    //           ))
                    //     ];
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: DefaultTabController(
                      length: 5,
                      initialIndex: 0,
                      animationDuration: const Duration(milliseconds: 300),
                      child: Builder(builder: (context) {
                        Future.delayed(
                          Duration.zero,
                          () {
                            setState(() {
                              selectedTap = tabController.index;
                            });
                          },
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: screenWidth > 450 ? 55 : 45,
                              child: TabBar(
                                controller: tabController,
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                indicatorWeight: 0,
                                padding: EdgeInsets.zero,
                                indicatorPadding: const EdgeInsets.only(
                                    right: 2, bottom: 10, left: 0),
                                labelPadding: const EdgeInsets.only(
                                    right: 8, bottom: 10, left: 5),
                                indicatorSize: TabBarIndicatorSize.label,
                                indicator: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    shape: BoxShape.rectangle,
                                    color:
                                        CommanColor.lightDarkPrimary(context)),
                                onTap: (value) {
                                  setState(() {
                                    selectedTap = value;
                                  });
                                },
                                tabs: [
                                  Tab(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 0
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            "assets/Library icons/Bookmark.png",
                                            color: CommanColor.whiteAndDark(
                                                context),
                                            width: 20,
                                            height: 15,
                                          ),
                                          // Icon(
                                          //   Icons.bookmark,
                                          //   color: selectedTap == 0
                                          //       ? Colors.white
                                          //       : CommanColor.whiteAndDark(
                                          //           context),
                                          //   size: screenWidth > 450 ? 22 : 18,
                                          // ),
                                          // SizedBox(width: 2,),
                                          Text(
                                            "BookMark",
                                            style: selectedTap == 0
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      // height: screenWidth > 450 ? 55 : 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 1
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            "assets/Library icons/Highlights.png",
                                            color: CommanColor.whiteAndDark(
                                                context),
                                            width: 20,
                                            height: 15,
                                          ),
                                          // Icon(
                                          //   Icons.brush_sharp,
                                          //   color: selectedTap == 1
                                          //       ? Colors.white
                                          //       : CommanColor.whiteAndDark(
                                          //           context),
                                          //   size: screenWidth > 450 ? 22 : 18,
                                          // ),
                                          Text(
                                            "Highlights",
                                            style: selectedTap == 1
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      //  height: 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 2
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            "assets/Library icons/underline.png",
                                            color: CommanColor.whiteAndDark(
                                                context),
                                            width: 20,
                                            height: 15,
                                          ),
                                          // Icon(
                                          //   Icons.format_underline_sharp,
                                          //   color: selectedTap == 2
                                          //       ? Colors.white
                                          //       : CommanColor.whiteAndDark(
                                          //           context),
                                          //   size: screenWidth > 450 ? 22 : 18,
                                          // ),
                                          Text(
                                            "Underline",
                                            style: selectedTap == 2
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      // height: 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 3
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                              "assets/Library icons/notes.png",
                                              color: CommanColor.whiteAndDark(
                                                  context),
                                              width:
                                                  screenWidth > 450 ? 22 : 18),
                                          // Icon(
                                          //   Icons.sticky_note_2_sharp,
                                          //   color: selectedTap == 3
                                          //       ? Colors.white
                                          //       : CommanColor.whiteAndDark(
                                          //           context),
                                          //   size: screenWidth > 450 ? 22 : 18,
                                          // ),

                                          Text(
                                            "Notes",
                                            style: selectedTap == 3
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      // height: 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 4
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Image.asset("assets/bookmark_1.png",color: CommanColor.whiteAndDark(context),width: 20,height: 15,),
                                          Icon(
                                            Icons.image_rounded,
                                            color: selectedTap == 4
                                                ? Colors.white
                                                : CommanColor.whiteAndDark(
                                                    context),
                                            size: screenWidth > 450 ? 22 : 18,
                                          ),

                                          Text(
                                            "Images",
                                            style: selectedTap == 4
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      //  height: 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 5
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            Images.wallpaper,
                                            width: 20,
                                            height: 15,
                                            color: selectedTap == 5
                                                ? Colors.white
                                                : CommanColor.whiteAndDark(
                                                    context),
                                            colorBlendMode: BlendMode.srcATop,
                                          ),
                                          Text(
                                            "Wallpapers",
                                            style: selectedTap == 5
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Container(
                                      //  height: 35,
                                      height: screenWidth > 450 ? 50 : 35,
                                      width: screenWidth > 450 ? 135 : 110,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 0.5,
                                              spreadRadius: 1,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                          color: selectedTap == 6
                                              ? CommanColor.lightDarkPrimary(
                                                  context)
                                              : CommanColor.whiteBlack45(
                                                  context)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            Images.quote,
                                            width: 20,
                                            height: 15,
                                            color: selectedTap == 6
                                                ? Colors.white
                                                : CommanColor.whiteAndDark(
                                                    context),
                                            colorBlendMode: BlendMode.srcATop,
                                          ),
                                          Text(
                                            "Quotes",
                                            style: selectedTap == 6
                                                ? CommanStyle.white12400.copyWith(
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            17
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            12)
                                                : CommanStyle
                                                        .inDarkPrimaryInLightWhite12400(
                                                            context)
                                                    .copyWith(
                                                        fontSize: screenWidth >
                                                                450
                                                            ? BibleInfo
                                                                    .fontSizeScale *
                                                                17
                                                            : BibleInfo
                                                                    .fontSizeScale *
                                                                12),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: TabBarView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: tabController,
                                  children: const [
                                    BookMarkScreen(),
                                    HighLightScreen(),
                                    UnderLineScreen(),
                                    NotesScreen(),
                                    ImageScreen(),
                                    WallpaperLibraryWidget(),
                                    QuotesLibraryWidget(),
                                  ]),
                            ),
                          ],
                        );
                      })),
                ),
              ],
            ),
          )),
    );
  }

  void backupNotification({
    required BuildContext context,
    required String message,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: !isTablet,
          onPopInvokedWithResult: (didPop, result) {
            // Prevent automatic dismissal on iPad - only allow manual close via buttons
            if (didPop && isTablet) return;
          },
          child: Dialog(
              backgroundColor: CommanColor.white,
              insetPadding: screenWidth > 450
                  ? const EdgeInsets.symmetric(horizontal: 150)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 16,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
              )),
        );
      },
    );
  }
}

class MainBackupDialog extends StatefulWidget {
  const MainBackupDialog({super.key});

  @override
  State<MainBackupDialog> createState() => _MainBackupDialogState();
}

class _MainBackupDialogState extends State<MainBackupDialog> {
  String? message;
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

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Prevent automatic dismissal on iPad - only allow manual close via X button
        if (didPop) return;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 150 : 24,
          vertical: isTablet ? 26 : 24,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CommanColor.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Backup",
                      style: TextStyle(
                          fontSize: isTablet ? 22 : 17.9,
                          fontWeight: FontWeight.w500,
                          color: CommanColor.black),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: isTablet ? 20 : 14,
                        child: Icon(Icons.close,
                            size: isTablet ? 22 : 17, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  BibleInfo.autoCloudBackupText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    height: 1.45,
                    color: CommanColor.black.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                context,
                label: "EXPORT (Manual)",
                icon: 'assets/sd.png',
                onTap: () async {
                  Get.back();
                  // Implement export logic
                  await SharPreferences.setString('OpenAd', '1');
                  // Constants.showToast(
                  //     "Save your Verse markings in My Library");
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (c) => BackupDialog(
                        type: "export",
                        onPrimaryPressed: () async {
                          await SharPreferences.setString('OpenAd', '1');
                          // final permission =
                          //     await ExportDb.requestStoragePermission();
                          // if (permission) {
                          debugPrint("clicked");

                          // updateLoading(true, mess: 'Please wait...');

                          if (c.mounted) {
                            ExportDb.getAllDataToExport(c);
                          }
                          await SharPreferences.setString('OpenAd', '1');

                          //  updateLoading(false);
                          //Get.back();
                          // Navigator.of(context).pop();
                          // Navigator.of(context).pop();
                          // } else {
                          //   await SharPreferences.setString('OpenAd', '1');
                          //   Constants.showToast(
                          //       "Permission is required to export the data.");
                          // }
                        },
                        onSecondaryPressed: () {
                          Get.back();
                          // Navigator.of(context).pop();
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                label: "IMPORT (Manual)",
                icon: 'assets/rd.png',
                onTap: () {
                  Get.back();
                  //    Navigator.of(context).pop();
                  // Implement import logic
                  showDialog(
                    context: context,
                    builder: (_) => BackupDialog(
                      type: "import",
                      onPrimaryPressed: () async {
                        await SharPreferences.setString('OpenAd', '1');
                        updateLoading(true, mess: 'Please wait...');

                        await ExportDb.importData().then((v) {
                          updateLoading(false);
                          if (v == "File is not selected") {
                            Constants.showToast("File is not selected");
                          }
                        });
                        await SharPreferences.setString('OpenAd', '1');

                        Get.offAll(() => HomeScreen(
                            From: "splash",
                            selectedVerseNumForRead: "",
                            selectedBookForRead: "",
                            selectedChapterForRead: "",
                            selectedBookNameForRead: "",
                            selectedVerseForRead: ""));
                      },
                      onSecondaryPressed: () {
                        // Navigator.of(context).pop();
                        Get.back();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                label: "IMPORT FROM CLOUD",
                icon: 'assets/rd.png',
                onTap: () async {
                  Get.back();
                  await SharPreferences.setString('OpenAd', '1');
                  updateLoading(true, mess: 'Downloading backup...');
                  final ok =
                      await LibraryBackupUploadService.downloadAndImportFromCloud();
                  updateLoading(false);
                  await SharPreferences.setString('OpenAd', '1');
                  if (ok) {
                    Get.offAll(() => HomeScreen(
                        From: "splash",
                        selectedVerseNumForRead: "",
                        selectedBookForRead: "",
                        selectedChapterForRead: "",
                        selectedBookNameForRead: "",
                        selectedVerseForRead: ""));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
      required String icon,
      required VoidCallback onTap}) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Image.asset(
          icon,
          height: isTablet ? 27 : 20,
          width: isTablet ? 27 : 20,
        ),
        label: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: isTablet ? 19 : 15),
        ),
      ),
    );
  }
}
