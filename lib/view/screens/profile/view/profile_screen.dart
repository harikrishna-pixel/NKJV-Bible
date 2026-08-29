import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/myLibrary.dart';
import 'package:biblebookapp/view/screens/profile/bloc/user_bloc.dart';
import 'package:biblebookapp/view/screens/profile/model/library_status_model.dart';
import 'package:biblebookapp/view/screens/profile/view/edit_profile_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/own_referral_code_dialog.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/referral_code_bottom_sheet.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart' as P;
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as p;
import 'package:biblebookapp/core/api/auth/profile_update.api.dart';
import '../../../../core/notifiers/cache.notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

                    final logoutEmail =
                        (await cacheprovider.readCache(key: 'user') ?? '')
                            .toString();
                    await PrayerWallLocalStore.snapshotBlockedIdsForEmail(
                      logoutEmail,
                    );

                    await cacheprovider.removeCache(key: 'userid');
                    await cacheprovider.removeCache(key: 'user');
                    await cacheprovider.removeCache(key: 'name');
                    await cacheprovider.removeCache(key: 'authtoken');
                    await cacheprovider.removeCache(key: 'profile_image');
                    await cacheprovider.removeCache(
                        key: OwnReferralCodeDialog.referralCacheKey);
                    await PrayerWallLocalStore.clearAccountScopedData();
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
  String? _referralCode = '';
  String? _referredBy = '';
  int? _referralRewardClaimed;
  String? _profileImageUrl;
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
    final referralCode = await cacheprovider.readCache(
        key: OwnReferralCodeDialog.referralCacheKey);
    final referredBy = await cacheprovider.readCache(key: 'referred_by');

    debugPrint(' name is $dataname');

    if (dataname != null) {
      setState(() {
        user = dataname;
        _referralCode = referralCode?.trim() ?? '';
        _referredBy = referredBy?.toString().trim() ?? '';
      });
      // Additive: pick up referrer credits when referral_count grew on backend.
      syncReferrerCreditsFromSession();
      // Additive: show cached / API profile photo (does not change login logic).
      _loadProfileImage();
    } else {
      setState(() {
        user = '';
        _referralCode = '';
        _referredBy = '';
        _referralRewardClaimed = null;
        _profileImageUrl = null;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final url = await ProfileUpdateApi().loadAndCacheProfileImageUrl();
      if (!mounted) return;
      setState(() => _profileImageUrl = url);
    } catch (e) {
      debugPrint('_loadProfileImage: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      loadDB();
      syncReferrerCreditsFromSession();
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
        backgroundColor:
        p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
            AppCustomTheme.vintage
            ? const Color(0xFFF5F0E6)
            : p.Provider.of<ThemeProvider>(context).backgroundColor,
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
                        : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFBD5B2),
                                        shape: BoxShape.circle,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (_profileImageUrl != null &&
                                              _profileImageUrl!.trim().isNotEmpty)
                                          ? CachedNetworkImage(
                                              imageUrl: _profileImageUrl!.trim(),
                                              width: 92,
                                              height: 92,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Center(
                                                child: Text(
                                                  _safeInitials,
                                                  style: TextStyle(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Georgia',
                                                    color: CommanColor
                                                        .whiteBlack(context),
                                                  ),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Text(
                                                  _safeInitials,
                                                  style: TextStyle(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Georgia',
                                                    color: CommanColor
                                                        .whiteBlack(context),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                _safeInitials,
                                                style: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Georgia',
                                                  color: CommanColor.whiteBlack(
                                                      context),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.start,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              user ?? '',
                                              style: TextStyle(
                                                  letterSpacing:
                                                  BibleInfo.letterSpacing,
                                                  fontSize:
                                                  BibleInfo.fontSizeScale * 22,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Georgia',
                                                  color: CommanColor.whiteBlack(
                                                      context)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Read and study the ${BibleInfo.bible_shortName} with us.',
                                              style: TextStyle(
                                                color: CommanColor.whiteBlack(
                                                    context)
                                                    .withOpacity(0.68),
                                                fontSize:
                                                BibleInfo.fontSizeScale * 13,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
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
                                                        vertical: 8,
                                                        horizontal: 12),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                        color: const Color(
                                                            0xFF472F1F)),
                                                    child: Row(
                                                      mainAxisSize:
                                                      MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.edit_outlined,
                                                          color: Colors.white,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          "Edit Profile",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            letterSpacing: BibleInfo
                                                                .letterSpacing,
                                                            fontSize: BibleInfo
                                                                .fontSizeScale *
                                                                13,
                                                            fontWeight:
                                                            FontWeight.w600,
                                                            fontFamily: 'Georgia',
                                                          ),
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
                                SizedBox(height: mheight * 0.035),
                                Text(
                                  'My Library Status'.toUpperCase(),
                                  style: TextStyle(
                                      letterSpacing: 0.8,
                                      fontSize: BibleInfo.fontSizeScale * 13,
                                      fontWeight: FontWeight.w700,
                                      color: CommanColor.whiteBlack(context)),
                                ),
                                const SizedBox(height: 14),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  itemCount: status.length,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.88,
                                  ),
                                  itemBuilder: (context, index) => LibraryItem(
                                    item: status[index],
                                    index: index,
                                  ),
                                ),
                                SizedBox(height: mheight * 0.028),
                                InkWell(
                                  onTap: () async {
                                    await SharPreferences.setString(
                                        'OpenAd', '1');
                                    if (!context.mounted) return;
                                    await showDialog(
                                      context: context,
                                      builder: (context) =>
                                      const MainBackupDialog(),
                                    );
                                    lastExportedDate = DateTime.tryParse(
                                      (await SharPreferences.getString(
                                          SharPreferences
                                              .lastExportedDate) ??
                                          ''),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: CommanColor
                                          .lightDarkPrimary200(context)
                                          .withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF472F1F),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Backup Library',
                                                style: TextStyle(
                                                  letterSpacing:
                                                  BibleInfo.letterSpacing,
                                                  fontSize:
                                                  BibleInfo.fontSizeScale *
                                                      16,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Georgia',
                                                  color: CommanColor.whiteBlack(
                                                      context),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Last Backup Date: ${(lastExportedDate) == null ? 'Not Yet' : DateFormat('yyyy/MM/dd').format(lastExportedDate!)}',
                                                style: TextStyle(
                                                  letterSpacing:
                                                  BibleInfo.letterSpacing,
                                                  fontSize:
                                                  BibleInfo.fontSizeScale *
                                                      12,
                                                  fontWeight: FontWeight.w400,
                                                  color: CommanColor.whiteBlack(
                                                      context)
                                                      .withOpacity(0.62),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: CommanColor.whiteBlack(context)
                                              .withOpacity(0.7),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: mheight * 0.032),
                                ReferralCodeProfileSection(
                                  referralCode: _referralCode ?? '',
                                  referredBy: _referredBy,
                                  referralRewardClaimed: _referralRewardClaimed,
                                  onEnterReferralTap: () async {
                                    await ReferralCodeBottomSheet
                                        .showForLoggedInUser(
                                      context: context,
                                      ownReferralCode:
                                      (_referralCode ?? '').trim().isEmpty
                                          ? null
                                          : _referralCode,
                                      initialReferredBy: _referredBy,
                                      initialReferralRewardClaimed:
                                      _referralRewardClaimed,
                                    );
                                    if (mounted) {
                                      await checkuserloggedin();
                                    }
                                  },
                                ),
                                SizedBox(height: mheight * 0.02),
                              ],
                            ),
                          ),
                        );
                      },
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

  String get _countLabel {
    if (item.title == 'Images') return '${item.count} images';
    if (item.title == 'Wallpapers') return '${item.count} wallpapers';
    if (item.title == 'Quotes') return '${item.count} quotes';
    if (item.title == 'Notes') return '${item.count} notes';
    return '${item.count} verses';
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = CommanColor.whiteBlack(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(() => LibraryScreen(initialIndex: index),
              transition: Transition.cupertinoDialog,
              duration: const Duration(milliseconds: 300));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: CommanColor.lightDarkPrimary200(context).withOpacity(0.28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: item.leading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CommanStyle.bw16500(context).copyWith(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: BibleInfo.fontSizeScale * 11.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _countLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CommanStyle.bw16500(context).copyWith(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: BibleInfo.fontSizeScale * 10.5,
                  fontWeight: FontWeight.w400,
                  color: titleColor.withOpacity(0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}