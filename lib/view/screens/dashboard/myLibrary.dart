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
import 'package:intl/intl.dart';
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

  /// Selected tab: white icon on brown chip. Unselected: contrast on white chip.
  Color _libraryTabIconColor(BuildContext context, int tabIndex) {
    if (selectedTap == tabIndex) return Colors.white;
    return CommanColor.isDarkTheme(context)
        ? CommanColor.lightDarkPrimary(context)
        : Colors.white;
  }

  Widget _libraryBackupHeaderIcon(BuildContext context, double size) {
    final image = Image.asset(
      "assets/home icons/Frame 3631.png",
      height: size,
      width: size,
    );
    if (!CommanColor.isDarkTheme(context)) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: image,
    );
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
                        child: _libraryBackupHeaderIcon(
                          context,
                          screenWidth > 450 ? 28 : 22,
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
                                            color: _libraryTabIconColor(
                                                context, 0),
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
                                            color: _libraryTabIconColor(
                                                context, 1),
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
                                            color: _libraryTabIconColor(
                                                context, 2),
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
                                              color: _libraryTabIconColor(
                                                  context, 3),
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
                                            color: _libraryTabIconColor(
                                                context, 4),
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
  static const Color _cream = Color(0xFFFDF8F5);
  static const Color _brown = Color(0xFF4E342E);
  static const Color _brownMuted = Color(0xFF6D4C41);
  static const Color _greenBox = Color(0xFFE8F5E9);
  static const Color _greenText = Color(0xFF2E7D32);
  static const Color _tanBox = Color(0xFFF5EDE4);

  static const String _assetRefresh =
      'assets/export_backup/refresh.png';
  static const String _assetLockCloud = 'assets/export_backup/lock.png';
  static const String _assetEncryption =
      'assets/export_backup/encryption.png';
  static const String _assetEncryptionSign =
      'assets/export_backup/encryption-sign.png';
  static const String _assetDownload =
      'assets/export_backup/download.png';
  static const String _assetUpload = 'assets/export_backup/upload.png';

  static const double _kStatusIconSize = 56;
  static const double _kActionIconSize = 56;
  static const double _kCloudLayoutHeight = 88;
  static const double _kCloudImageWidth = 140;
  static const double _kCloudImageHeight = 128;

  Widget _backupIcon(String asset, {double size = 28}) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  String? _userId;
  DateTime? _lastBackup;
  bool _loadingMeta = true;

  void updateLoading(bool val, {String? mess}) {
    if (val) {
      EasyLoading.show(status: mess);
    } else {
      EasyLoading.dismiss();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBackupMeta();
  }

  Future<void> _loadBackupMeta() async {
    final id = await CacheNotifier().readCache(key: 'userid');
    final cloudRaw = await SharPreferences.getString(
        SharPreferences.lastCloudBackupDate);
    final exportRaw =
        await SharPreferences.getString(SharPreferences.lastExportedDate);
    final parsed = DateTime.tryParse(cloudRaw ?? '') ??
        DateTime.tryParse(exportRaw ?? '');
    if (!mounted) return;
    setState(() {
      final trimmed = id?.toString().trim();
      _userId = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      _lastBackup = parsed;
      _loadingMeta = false;
    });
  }

  bool get _isSignedIn => _userId != null;

  String _formatLastBackup() {
    if (_lastBackup == null) return 'Not yet';
    final dt = _lastBackup!.toLocal();
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final dayPart =
        isToday ? 'Today' : DateFormat('MMM d').format(dt);
    return '$dayPart, ${DateFormat('h:mm a').format(dt)}';
  }

  void _closeDialog() => Navigator.of(context).pop();

  void _goToLogin() {
    _closeDialog();
    Get.to(
      () => LoginScreen(hasSkip: false),
      transition: Transition.cupertinoDialog,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _onRestoreFromCloud() async {
    if (!_isSignedIn) {
      _goToLogin();
      return;
    }
    _closeDialog();
    await SharPreferences.setString('OpenAd', '1');
    updateLoading(true, mess: 'Downloading backup...');
    final ok = await LibraryBackupUploadService.downloadAndImportFromCloud();
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
  }

  void _onExportLibrary() {
    _closeDialog();
    SharPreferences.setString('OpenAd', '1');
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (c) => BackupDialog(
        type: "export",
        onPrimaryPressed: () async {
          await SharPreferences.setString('OpenAd', '1');
          if (c.mounted) {
            ExportDb.getAllDataToExport(c);
          }
          await SharPreferences.setString('OpenAd', '1');
        },
        onSecondaryPressed: () => Get.back(),
      ),
    );
  }

  void _onImportBackupFile() {
    _closeDialog();
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
        onSecondaryPressed: () => Get.back(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxW = isTablet ? 420.0 : 360.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 80 : 20,
          vertical: isTablet ? 32 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _loadingMeta
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: _brown),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'Library Backup',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 20,
                                fontWeight: FontWeight.w700,
                                color: _brown,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: _closeDialog,
                                icon: Icon(Icons.close,
                                    size: 22,
                                    color: _brown.withValues(alpha: 0.55)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignedIn
                              ? 'Keep your notes, highlights & bookmarks safe'
                              : 'Protect your notes, bookmarks & highlights',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            height: 1.35,
                            color: _brownMuted.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _cloudIllustration(signedIn: _isSignedIn),
                        const SizedBox(height: 12),
                        if (_isSignedIn)
                          _signedInStatusBox()
                        else
                          _signedOutStatusBox(),
                        const SizedBox(height: 16),
                        if (_isSignedIn) ...[
                          _primaryActionTile(
                            iconAsset: _assetDownload,
                            title: 'Restore from Cloud',
                            subtitle:
                                'Get your library from the latest backup',
                            onTap: _onRestoreFromCloud,
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          const _OrDivider(),
                          const SizedBox(height: 12),
                        ],
                        _secondaryActionTile(
                          iconAsset: _assetUpload,
                          title: 'Export Library',
                          subtitle: 'Save backup file to your device',
                          onTap: _onExportLibrary,
                        ),
                        const SizedBox(height: 10),
                        _secondaryActionTile(
                          iconAsset: _assetDownload,
                          title: 'Import Backup File',
                          subtitle: 'Restore from a saved backup file',
                          onTap: _onImportBackupFile,
                        ),
                        const SizedBox(height: 18),
                        _privacyFooter(signedIn: _isSignedIn),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _cloudIllustration({required bool signedIn}) {
    return SizedBox(
      height: _kCloudLayoutHeight,
      width: double.infinity,
      child: Center(
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: _kCloudImageWidth,
          maxWidth: _kCloudImageWidth,
          minHeight: _kCloudImageHeight,
          maxHeight: _kCloudImageHeight,
          child: Image.asset(
            signedIn ? _assetRefresh : _assetLockCloud,
            width: _kCloudImageWidth,
            height: _kCloudImageHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _signedInStatusBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _greenBox,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _greenText.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backupIcon(_assetEncryption, size: _kStatusIconSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automatic backup is enabled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _greenText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your library is synced securely to the cloud because you\'re signed in.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _brownMuted.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14, color: _brownMuted.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Last backup: ${_formatLastBackup()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _brownMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signedOutStatusBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _tanBox,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brown.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backupIcon(_assetEncryptionSign, size: _kStatusIconSize),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enable Automatic Backup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to sync your library securely across devices and restore anytime.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: _brownMuted.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: _brown,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _goToLogin,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_outline,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sign In to Enable Backup',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryActionTile({
    required String iconAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _brown,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: _kActionIconSize,
                height: _kActionIconSize,
                child: _backupIcon(iconAsset, size: _kActionIconSize),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryActionTile({
    required String iconAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: _kActionIconSize,
                  height: _kActionIconSize,
                  child: _backupIcon(iconAsset, size: _kActionIconSize),
                ),
                const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _brownMuted.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _brownMuted.withValues(alpha: 0.65), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyFooter({required bool signedIn}) {
    final textStyle = TextStyle(
      fontSize: 11.5,
      height: 1.35,
      color: _brownMuted.withValues(alpha: 0.85),
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _tanBox,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: _brownMuted.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your data is private and secure.', style: textStyle),
                Text(
                  signedIn
                      ? 'We never share your personal content.'
                      : 'Sign in to keep your library protected.',
                  style: textStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade400, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade400, height: 1)),
      ],
    );
  }
}
