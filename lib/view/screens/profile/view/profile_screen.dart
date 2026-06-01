import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/export_db.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/myLibrary.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/profile/bloc/user_bloc.dart';
import 'package:biblebookapp/view/screens/profile/model/library_status_model.dart';
import 'package:biblebookapp/view/screens/profile/view/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart' as P;
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as p;
import '../../../../core/notifiers/cache.notifier.dart';

void confirmLogoutAccount(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 16,
          insetPadding:
              screenWidth > 450 ? EdgeInsets.symmetric(horizontal: 260) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: CommanColor.black,
                      fontSize: screenWidth > 450 ? 19 : null),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final cacheprovider =
                        P.Provider.of<CacheNotifier>(context, listen: false);

                    await cacheprovider.removeCache(key: 'userid');
                    await cacheprovider.removeCache(key: 'user');
                    await cacheprovider.removeCache(key: 'name');
                    await cacheprovider.removeCache(key: 'authtoken');
                    //   FirebaseAuth.instance.signOut();
                    Constants.showToast("Logged Out Successfully");
                    Get.offAll(() => HomeScreen(
                        From: "splash",
                        selectedVerseNumForRead: "",
                        selectedBookForRead: "",
                        selectedChapterForRead: "",
                        selectedBookNameForRead: "",
                        selectedVerseForRead: ""));
                  },
                  child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CommanColor.darkPrimaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Text(
                        'Yes, Logout',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 19
                                : BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      )),
                ),
                const SizedBox(height: 17),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
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

class ProfileScreen extends StatefulHookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with WidgetsBindingObserver {
  int bookmarkCount = 0;
  int highlightCount = 0;
  int underlineCount = 0;
  int notesCount = 0;
  int imageCount = 0;
  DateTime? lastExportedDate;
  bool isLoading = false;
  String? message;
  String? user = '';
  loadDB() async {
    final db = DBHelper();
    if (mounted) {
      bookmarkCount = (await db.getBookMark()).length;
      highlightCount = (await db.getHighlight()).length;
      underlineCount = (await db.getUnderLine()).length;
      notesCount = (await db.getNotes()).length;
      imageCount = (await db.getImage()).length;
      lastExportedDate = DateTime.tryParse(
          (await SharPreferences.getString(SharPreferences.lastExportedDate) ??
              ''));
      setState(() {});
    }
  }

  updateLoading(bool val, {String? mess}) {
    setState(() {
      isLoading = val;
      message = mess;
    });
  }

  @override
  initState() {
    super.initState();
    checkuserloggedin();
    WidgetsBinding.instance.addObserver(this);
    loadDB();
  }

  checkuserloggedin() async {
    final cacheprovider = P.Provider.of<CacheNotifier>(context, listen: false);

    // final data = await cacheprovider.readCache(key: 'user');
    final dataname = await cacheprovider.readCache(key: 'name');

    debugPrint(' name is $dataname');

    if (dataname != null) {
      setState(() {
        user = dataname;
      });
    } else {
      setState(() {
        user = '';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      loadDB();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final bookmark = ref.watch(bookmarkSharedPrefBloc);
    final userState = ref.watch(userBloc);
    //  final user = userState.user;

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) async {
        ref.read(bookmarkSharedPrefBloc).getBookmarks();
        lastExportedDate = DateTime.tryParse((await SharPreferences.getString(
                SharPreferences.lastExportedDate) ??
            ''));
        setState(() {});
      });
    });
    List<LibraryStatusModel> status = [
      LibraryStatusModel(
          leading: Icon(Icons.bookmark_outline,
              size: 32, color: CommanColor.whiteBlack(context)),
          count: bookmarkCount,
          title: "Bookmark"),
      LibraryStatusModel(
          count: highlightCount,
          leading: Icon(Icons.brush_sharp,
              size: 32, color: CommanColor.whiteBlack(context)),
          title: "Highlights"),
      LibraryStatusModel(
          count: underlineCount,
          leading: Icon(Icons.format_underline_sharp,
              size: 32, color: CommanColor.whiteBlack(context)),
          title: "Underline"),
      LibraryStatusModel(
          count: notesCount,
          leading: Image.asset("assets/dark_modes/stickynote.png",height: 32, color: CommanColor.whiteBlack(context)),
          title: "Notes"),
      LibraryStatusModel(
          count: imageCount,
          leading: Icon(Icons.image_rounded,
              size: 32, color: CommanColor.whiteBlack(context)),
          title: "Images"),
      LibraryStatusModel(
          count: bookmark.wallpaperBookmark.length,
          leading: Icon(Icons.wallpaper_rounded,
              size: 32, color: CommanColor.whiteBlack(context)),
          title: "Wallpapers"),
      LibraryStatusModel(
          count: bookmark.quotesBookmark.length,
          leading: Image.asset(
            Images.quote,
            height: 24,
            width: 32,
            color: CommanColor.whiteBlack(context),
            colorBlendMode: BlendMode.srcATop,
          ),
          title: "Quotes"),
    ];

    final mheight = MediaQuery.of(context).size.height;

    // UI helper: show first two letters of the user's name safely.
    // (Edit Profile uses a similar 2-letter initials style.)
    final _safeInitials = (() {
      final raw = (user ?? '').trim().replaceAll(RegExp(r'\s+'), '');
      if (raw.isEmpty) return '?';
      if (raw.length == 1) return raw[0].toUpperCase();
      return '${raw[0].toUpperCase()}${raw[1].toUpperCase()}';
    })();

    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
              AppCustomTheme.vintage
          ? BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)), fit: BoxFit.fill))
          : null,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                    flex: 2,
                    child: Text("Profile",
                        textAlign: TextAlign.center,
                        style: CommanStyle.appBarStyle(context))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            confirmLogoutAccount(context);
                            // final cacheprovider = P.Provider.of<CacheNotifier>(
                            //     context,
                            //     listen: false);

                            // await cacheprovider.removeCache(key: 'userid');
                            // await cacheprovider.removeCache(key: 'user');
                            // await cacheprovider.removeCache(key: 'name');
                            // await cacheprovider.removeCache(key: 'authtoken');
                            // //   FirebaseAuth.instance.signOut();
                            // Constants.showToast("Logged Out Successfully");
                            // Get.offAll(() => HomeScreen(
                            //     From: "splash",
                            //     selectedVerseNumForRead: "",
                            //     selectedBookForRead: "",
                            //     selectedChapterForRead: "",
                            //     selectedBookNameForRead: "",
                            //     selectedVerseForRead: ""));
                          },
                          child: Icon(
                            Icons.logout,
                            size: 20,
                            color: CommanColor.whiteBlack(context),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
                child: isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator.adaptive(),
                          const SizedBox(height: 20),
                          Text(message ?? '')
                        ],
                      )
                    : userState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator.adaptive(),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      clipBehavior: Clip.hardEdge,
                                      foregroundDecoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              width: 2,
                                              color: CommanColor
                                                  .lightDarkPrimary200(
                                                      context))),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              width: 2,
                                              color: CommanColor
                                                  .lightDarkPrimary200(
                                                      context))),
                                      child: user != null
                                          ? CircleAvatar(
                                              backgroundColor: CommanColor
                                                      .lightDarkPrimary200(
                                                          context)
                                                  .withOpacity(
                                                      0.4), // Background color
                                              radius:
                                                  50, // Adjust size as needed
                                              child: Text(
                                                _safeInitials,
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors
                                                      .black, // Text color
                                                ),
                                              ),
                                            )
                                          : SizedBox(
                                              height: 84,
                                              width: 84,
                                              child: Center(
                                                child: Text(
                                                  (((user ?? 'N A')
                                                              .replaceAll(
                                                                  ' ', '')
                                                              .isNotEmpty)
                                                          ? '${(user ?? 'N A').replaceAll(' ', '')[0].toUpperCase()}${(user ?? 'N A').replaceAll(' ', '').length > 1 ? (user ?? 'N A').replaceAll(' ', '')[1].toUpperCase() : ''}'
                                                          : '?'),
                                                  style: const TextStyle(
                                                      letterSpacing: BibleInfo
                                                          .letterSpacing,
                                                      fontSize: BibleInfo
                                                              .fontSizeScale *
                                                          20),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                        child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          user ?? '',
                                          style: const TextStyle(
                                              letterSpacing:
                                                  BibleInfo.letterSpacing,
                                              fontSize:
                                                  BibleInfo.fontSizeScale * 20,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                            'Read and study the ${BibleInfo.bible_shortName} with us.'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                Get.to(
                                                    () => EditProfileScreen());
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 8),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.rectangle,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black38,
                                                        blurRadius: 0.5,
                                                        spreadRadius: 1,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                    color: CommanColor
                                                        .whiteBlack45(context)),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: CommanColor
                                                          .whiteAndDark(
                                                              context),
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Edit Profile",
                                                      style: CommanStyle
                                                              .inDarkPrimaryInLightWhite12400(
                                                                  context)
                                                          .copyWith(
                                                              letterSpacing:
                                                                  BibleInfo
                                                                      .letterSpacing,
                                                              fontSize: BibleInfo
                                                                      .fontSizeScale *
                                                                  14),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ))
                                  ],
                                ),
                                SizedBox(height: mheight * 0.03),
                                Text(
                                  'My Library Status'.toUpperCase(),
                                  style: const TextStyle(
                                      letterSpacing: BibleInfo.letterSpacing,
                                      fontSize: BibleInfo.fontSizeScale * 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                MediaQuery.removePadding(
                                  context: context,
                                  removeTop: true,
                                  removeBottom: true,
                                  child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) =>
                                          LibraryItem(
                                              item: status[index],
                                              index: index),
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            indent: 8,
                                            endIndent: 8,
                                            color:
                                                CommanColor.whiteBlack(context)
                                                    .withOpacity(0.5),
                                          ),
                                      itemCount: status.length),
                                ),
                                SizedBox(height: mheight * 0.01),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                      // Same logic as Library hamburger: if subscribed show Export dialog, else show Subscribe dialog
                                      final downloadProvider =
                                          P.Provider.of<DownloadProvider>(
                                              context,
                                              listen: false);
                                      final subscriptionPlan =
                                          await downloadProvider
                                              .getSubscriptionPlan();
                                      final isSubscribed =
                                          subscriptionPlan != null &&
                                              subscriptionPlan.isNotEmpty &&
                                              ['platinum', 'gold', 'silver']
                                                  .contains(subscriptionPlan
                                                      .toLowerCase());
                                      if (isSubscribed) {
                                        showDialog(
                                          context: context,
                                          builder: (ct) => BackupDialog(
                                            type: "export",
                                            onPrimaryPressed: () async {
                                              await SharPreferences.setString(
                                                  'OpenAd', '1');
                                              if (ct.mounted) {
                                                await ExportDb
                                                    .getAllDataToExport(ct)
                                                    .then((v) async {
                                                  lastExportedDate =
                                                      DateTime.tryParse(
                                                          (await SharPreferences
                                                                  .getString(
                                                                      SharPreferences.lastExportedDate) ??
                                                              ''));
                                                  setState(() {});
                                                });
                                              }
                                              await SharPreferences.setString(
                                                  'OpenAd', '1');
                                            },
                                            onSecondaryPressed: () {
                                              Get.back();
                                            },
                                          ),
                                        );
                                      } else {
                                        await SharPreferences.setString(
                                            'OpenAd', '1');
                                        if (!context.mounted) return;
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) {
                                            final dlgWidth =
                                                MediaQuery.of(ctx).size.width;
                                            return Dialog(
                                              backgroundColor:
                                                  CommanColor.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 16,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 24),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      "You're not subscribed. Subscribe to export and import your data.",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color:
                                                            CommanColor.black,
                                                        fontSize: dlgWidth > 450
                                                            ? 19
                                                            : 15,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 20),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.pop(ctx);
                                                        Get.to(
                                                          () =>
                                                              SubscriptionScreen(
                                                            sixMonthPlan:
                                                                BibleInfo
                                                                    .sixMonthPlanid,
                                                            oneYearPlan:
                                                                BibleInfo
                                                                    .oneYearPlanid,
                                                            lifeTimePlan:
                                                                BibleInfo
                                                                    .lifeTimePlanid,
                                                            checkad: 'profile',
                                                          ),
                                                          transition:
                                                              Transition
                                                                  .cupertinoDialog,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: CommanColor
                                                              .lightDarkPrimary(
                                                                  ctx),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                                      Radius.circular(5)),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .black26,
                                                                blurRadius: 2)
                                                          ],
                                                        ),
                                                        child: Text(
                                                          'Subscribe',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            letterSpacing:
                                                                BibleInfo
                                                                    .letterSpacing,
                                                            fontSize: BibleInfo
                                                                    .fontSizeScale *
                                                                14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 12),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          Navigator.pop(ctx),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: CommanColor
                                                              .lightGrey1,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                                      Radius.circular(5)),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .black26,
                                                                blurRadius: 2)
                                                          ],
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            letterSpacing:
                                                                BibleInfo
                                                                    .letterSpacing,
                                                            fontSize: BibleInfo
                                                                    .fontSizeScale *
                                                                14,
                                                            fontWeight:
                                                                FontWeight
                                                                .w500,
                                                            color: CommanColor
                                                                .black),
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
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: CommanColor
                                                .whiteLightModePrimary(context),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(5)),
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 2)
                                            ],
                                          ),
                                          child: Text(
                                            'Back Up',
                                            style: CommanStyle.bw16500(context)
                                                .copyWith(
                                                    color:
                                                        CommanColor.Blackwhite(
                                                            context),
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize: BibleInfo
                                                            .fontSizeScale *
                                                        18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Last Backup Date: ${(lastExportedDate) == null ? 'Not Yet' : DateFormat('yyyy/MM/dd').format(lastExportedDate!)}',
                                        textAlign: TextAlign.center,
                                        style: CommanStyle.bw16500(context)
                                            .copyWith(
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        12,
                                                fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ))
          ],
        ),
      ),
    ));
  }
}

class LibraryItem extends StatelessWidget {
  const LibraryItem({super.key, required this.index, required this.item});
  final LibraryStatusModel item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Get.to(() => LibraryScreen(initialIndex: index),
              transition: Transition.cupertinoDialog,
              duration: const Duration(milliseconds: 300));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            item.leading,
            const SizedBox(width: 8),
            Text(
              item.title,
              style: CommanStyle.bw16500(context).copyWith(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: BibleInfo.fontSizeScale * 18),
            ),
            const SizedBox(width: 4),
            Text(
              item.title == 'Images'
                  ? '(${item.count} images)'
                  : item.title == 'Wallpapers'
                      ? '(${item.count} wallpapers)'
                      : item.title == 'Quotes'
                          ? '(${item.count} quotes)'
                          : '(${item.count} verses)',
              style: CommanStyle.bw16500(context).copyWith(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: BibleInfo.fontSizeScale * 14,
                  fontWeight: FontWeight.w400),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_right_outlined,
              color: CommanColor.whiteBlack(context),
              size: 28,
            )
          ],
        ),
      ),
    );
  }
}
