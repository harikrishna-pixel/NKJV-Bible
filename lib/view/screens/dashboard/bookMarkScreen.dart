import 'dart:io';

import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/widget/library_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:html/parser.dart' as html;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../Model/bookMarkModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/colors.dart';
import '../../constants/constant.dart';
import '../../constants/share_preferences.dart';
import 'package:biblebookapp/view/widget/library_list_ads_helper.dart';
import 'package:biblebookapp/utils/library_bible_guard.dart';
import 'package:biblebookapp/utils/library_bible_version_tag.dart';

class BookMarkScreen extends StatefulWidget {
  const BookMarkScreen({super.key});

  @override
  State<BookMarkScreen> createState() => _BookMarkScreenState();
}

class _BookMarkScreenState extends State<BookMarkScreen> {
  Future<List<BookMarkModel>> bookmarkDataList = Future.value(const []);
  double fontSize = Sizecf.scrnWidth! > 450 ? 25.0 : 15.0;
  var fontSizeS = "";
  var selectedFontFamily = "";

  /// Display-only ads (same pattern as Explore Topics detail).
  late final LibraryListAdsHelper _libraryAds =
      LibraryListAdsHelper(onChanged: () {
        if (mounted) setState(() {});
      });

  Future<void> getFont() async {
    fontSizeS =
        await SharPreferences.getString(SharPreferences.selectedFontSize) ??
            "${Sizecf.scrnWidth! > 450 ? 25.0 : 15.0}";
    fontSize = double.parse(fontSizeS);
    selectedFontFamily =
        await SharPreferences.getString(SharPreferences.selectedFontFamily) ??
            "Arial";
  }

  @override
  void initState() {
    super.initState();
    getFont();
    bookmarkDataList = _loadData();
  }

  Future<List<BookMarkModel>> _loadData() async {
    // CRITICAL: Always try to restore legacy data first
    await DBMigrationHelper.tryRestoreLibraryDataFromLegacy();
    final bookmarks = await DBHelper().getBookMark();
    
    // Debug logging to help diagnose issues
    debugPrint('BookMarkScreen: loaded ${bookmarks.length} bookmarks');
    if (bookmarks.isEmpty) {
      debugPrint('BookMarkScreen: No bookmarks found. Legacy restore may have failed.');
      // Print DB file status for debugging
      await DBHelper.debugPrintDatabaseFiles();
      await DBHelper.debugPrintLibraryTableCounts();
    }
    
    return bookmarks;
  }

  void loadData() {
    if (!mounted) return;
    setState(() {
      bookmarkDataList = _loadData();
    });
  }

  //final bookMarkKey = GlobalKey<ScaffoldState>();
  @override
  void dispose() {
    _libraryAds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
          future: bookmarkDataList,
          builder: (context, AsyncSnapshot<List<BookMarkModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: CommanColor.lightDarkPrimary(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load bookmarks.',
                        textAlign: TextAlign.center,
                        style: CommanStyle.placeholderText(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: CommanStyle.placeholderText(context)
                            .copyWith(fontSize: 12),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = snapshot.data;
            if (items != null && items.isNotEmpty) {
              // Display-only: adaptive banners between items + interstitial every 10 actions.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _libraryAds.initIfNeeded(
                  itemCount: items.length,
                  context: context,
                );
              });
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                physics: const ScrollPhysics(),
                itemBuilder: (context, index) {
                  var data = items[index];
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      showModalBottomSheet(
                                        enableDrag: true,
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20))),
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(20),
                                                    topRight:
                                                        Radius.circular(20))),
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      height: 3,
                                                      width: 45,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(3),
                                                          color: CommanColor
                                                              .lightDarkPrimary(
                                                                  context)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                HtmlWidget(
                                                  data.content.toString(),
                                                  textStyle:
                                                      CommanStyle.black15400,
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  children: [
                                                    LibraryBibleVersionChip(
                                                      bookName: data.bookName,
                                                      content: data.content ??
                                                          data.plaincontent,
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                        "${data.bookName} ${data.chapterNum}:${data.verseNum}",
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: CommanStyle
                                                            .black15400),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 25,
                                                ),
                                                SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              await _libraryAds.runCountedAction(() async {
                                                              await Clipboard.setData(
                                                                  ClipboardData(
                                                                      text:
                                                                          "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum}"));
                                                              Constants
                                                                  .showToast(
                                                                      "Copied");
                                                              });
                                                            },
                                                            child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(6),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border.all(
                                                                      color: CommanColor
                                                                          .lightDarkPrimary(
                                                                              context),
                                                                      width:
                                                                          1.4),
                                                                ),
                                                                child: Image.asset(
                                                                    "assets/Bookmark icons/Frame 3630.png",
                                                                    height: 28,
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context)))),
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Text(
                                                          "Copy",
                                                          style: CommanStyle
                                                              .bothPrimary14500(
                                                                  context),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: 25,
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        await _libraryAds.runCountedAction(() async {
                                                        final canRead =
                                                            await LibraryBibleGuard
                                                                .allowReadOrToast(
                                                          bookNum: data.bookNum,
                                                          chapterNum:
                                                              data.chapterNum,
                                                          verseNum:
                                                              data.verseNum,
                                                          savedContent:
                                                              data.content ??
                                                                  data.plaincontent,
                                                        );
                                                        if (!canRead) return;
                                                        // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                                                        await SharPreferences
                                                            .setString(
                                                                SharPreferences
                                                                    .selectedBook,
                                                                data.bookName
                                                                    .toString());

                                                        await SharPreferences.setString(
                                                            SharPreferences
                                                                .selectedChapter,
                                                            "${int.parse(data.chapterNum.toString())}");
                                                        await SharPreferences.setString(
                                                            SharPreferences
                                                                .selectedBookNum,
                                                            "${int.parse(data.bookNum.toString())}");
                                                        debugPrint(
                                                          "bookid bnk - ${int.parse(data.bookNum.toString())} chapter - ${int.parse(data.chapterNum.toString())} verseno - ${int.parse(data.verseNum.toString())} book - ${data.bookName.toString()}  vcontent -  ",
                                                        );
                                                        Get.offAll(
                                                            () => HomeScreen(
                                                                From: "Read",
                                                                selectedBookForRead:
                                                                    int.parse(data
                                                                        .bookNum
                                                                        .toString()),
                                                                selectedChapterForRead: int.parse(data
                                                                    .chapterNum
                                                                    .toString()),
                                                                selectedVerseNumForRead:
                                                                    int.parse(data
                                                                        .verseNum
                                                                        .toString()),
                                                                selectedBookNameForRead: data
                                                                    .bookName
                                                                    .toString(),
                                                                selectedVerseForRead:
                                                                    parse(data.content)
                                                                        .body
                                                                        ?.text
                                                                        .toString()),
                                                            transition: Transition
                                                                .cupertinoDialog,
                                                            duration: const Duration(milliseconds: 300));
                                                        });
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              height: 40,
                                                              width: 40,
                                                              decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                      color: CommanColor
                                                                          .lightDarkPrimary(
                                                                              context),
                                                                      width:
                                                                          1.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3)),
                                                              child:
                                                                  Image.asset(
                                                                "assets/reading_book.png",
                                                                height: 25,
                                                                width: 15,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context),
                                                              )),
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Text("Read",
                                                              style: CommanStyle
                                                                  .bothPrimary14500(
                                                                      context)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 25,
                                                    ),
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              await _libraryAds.runCountedAction(() async {
                                                              // final appPackageName =
                                                              //     (await PackageInfo
                                                              //             .fromPlatform())
                                                              //         .packageName;
                                                              // String message =
                                                              //     ''; // Declare the message variable outside the if-else block
                                                              // String appid;
                                                              // appid = BibleInfo
                                                              //     .apple_AppId;
                                                              // if (Platform
                                                              //     .isAndroid) {
                                                              //   message =
                                                              //       "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                              // } else if (Platform
                                                              //     .isIOS) {
                                                              //   message =
                                                              //       "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
                                                              // }

                                                              // if (message
                                                              //     .isNotEmpty) {
                                                              //   Share.share(
                                                              //       message,
                                                              //       sharePositionOrigin: Rect.fromPoints(
                                                              //           const Offset(
                                                              //               2,
                                                              //               2),
                                                              //           const Offset(
                                                              //               3,
                                                              //               3)));
                                                              // } else {
                                                              //   print(
                                                              //       'Message is empty or undefined');
                                                              // }
                                                              return showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        ShareAlertBox(
                                                                  verseTitle:
                                                                      " ${data.bookName} ${int.parse(data.chapterNum.toString())}:${int.parse(data.verseNum.toString())}",
                                                                  onShareAsText:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    // Your logic here
                                                                    final appPackageName =
                                                                        (await PackageInfo.fromPlatform())
                                                                            .packageName;
                                                                    String
                                                                        message =
                                                                        ''; // Declare the message variable outside the if-else block
                                                                    String
                                                                        appid;
                                                                    appid = BibleInfo
                                                                        .apple_AppId;
                                                                    if (Platform
                                                                        .isAndroid) {
                                                                      message =
                                                                          "${html.parse("${data.content}").body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                                    } else if (Platform
                                                                        .isIOS) {
                                                                      message =
                                                                          '${html.parse("${data.content}").body?.text ?? ''}.\n You can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
                                                                    }

                                                                    if (message
                                                                        .isNotEmpty) {
                                                                      Share.share(
                                                                          message,
                                                                          sharePositionOrigin: Rect.fromPoints(
                                                                              const Offset(2, 2),
                                                                              const Offset(3, 3)));
                                                                    } else {
                                                                      print(
                                                                          'Message is empty or undefined');
                                                                    }
                                                                  },
                                                                  onShareAsImage:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    final controller =
                                                                        DashBoardController();
                                                                    await showModalBottomSheet(
                                                                      isScrollControlled:
                                                                          true,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) {
                                                                        return ImageBottomSheets(
                                                                          controller:
                                                                              controller,
                                                                          content: data
                                                                              .content
                                                                              .toString(),
                                                                          selectedBook: data
                                                                              .bookName
                                                                              .toString(),
                                                                          selectedChapter: data
                                                                              .chapterNum
                                                                              .toString(),
                                                                          selectedVerseView: data
                                                                              .verseNum
                                                                              .toString(),
                                                                        );
                                                                      },
                                                                    );

                                                                    // Your logic here
                                                                    // Navigator.pop(context);
                                                                  },
                                                                ),
                                                              );
                                                              });
                                                            },
                                                            child: Image.asset(
                                                                "assets/share.png",
                                                                height: 40,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context))),
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Text("Share",
                                                            style: CommanStyle
                                                                .bothPrimary14500(
                                                                    context)),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: 25,
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        await _libraryAds.runCountedAction(() async {
                                                        Get.back();
                                                        Get.to(
                                                          () => ChatScreen(
                                                            verseContext: {
                                                              'verseText': parse(
                                                                          data.content)
                                                                      .body
                                                                      ?.text
                                                                      .toString() ??
                                                                  '',
                                                              'book': data
                                                                  .bookName
                                                                  .toString(),
                                                              'chapter': data
                                                                  .chapterNum
                                                                  .toString(),
                                                              'verse': data
                                                                  .verseNum
                                                                  .toString(),
                                                            },
                                                          ),
                                                          transition: Transition
                                                              .cupertinoDialog,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                        );
                                                        });
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            height: 40,
                                                            width: 40,
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Image.asset(
                                                              'assets/Chat icon.png',
                                                              height: 22,
                                                              width: 22,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          Text("Ask",
                                                              style: CommanStyle
                                                                  .bothPrimary14500(
                                                                      context)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 25,
                                                    ),
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            Get.back();
                                                            showDialog<void>(
                                                              context: context,
                                                              barrierDismissible:
                                                                  false,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return Dialog(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              5)),
                                                                  elevation: 16,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  insetPadding: EdgeInsets.symmetric(
                                                                      horizontal: screenWidth >
                                                                              450
                                                                          ? 65
                                                                          : 20),
                                                                  child:
                                                                      ListView(
                                                                    shrinkWrap:
                                                                        true,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            20),
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsets.only(
                                                                            top:
                                                                                0,
                                                                            left:
                                                                                12,
                                                                            right:
                                                                                12,
                                                                            bottom:
                                                                                5),
                                                                        child: Text(
                                                                            "After removing the content, you can't Undo",
                                                                            style: TextStyle(
                                                                                color: Colors.black,
                                                                                letterSpacing: BibleInfo.letterSpacing,
                                                                                fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 20 : BibleInfo.fontSizeScale * 16,
                                                                                fontWeight: FontWeight.w400),
                                                                            textAlign: TextAlign.center),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsets.only(
                                                                            top:
                                                                                0,
                                                                            bottom:
                                                                                10),
                                                                        child: Text(
                                                                            '${data.bookName} ${data.chapterNum}:${data.verseNum}',
                                                                            style: TextStyle(
                                                                                color: Colors.black,
                                                                                letterSpacing: BibleInfo.letterSpacing,
                                                                                fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 20 : BibleInfo.fontSizeScale * 16,
                                                                                fontWeight: FontWeight.w500),
                                                                            textAlign: TextAlign.center),
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceEvenly,
                                                                        children: [
                                                                          const SizedBox(
                                                                            width:
                                                                                9,
                                                                          ),
                                                                          ElevatedButton(
                                                                              onPressed: () async {
                                                                                Navigator.pop(context);
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: CommanColor.lightGrey1,
                                                                                fixedSize: Size(MediaQuery.of(context).size.width * 0.3, 35),
                                                                                elevation: 0,
                                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: BorderSide(color: CommanColor.lightGrey1, width: 1)),
                                                                              ),
                                                                              child: Center(
                                                                                  child: Text(
                                                                                "Cancel",
                                                                                style: TextStyle(
                                                                                  color: CommanColor.black,
                                                                                  fontWeight: FontWeight.w400,
                                                                                  letterSpacing: BibleInfo.letterSpacing,
                                                                                  fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14,
                                                                                ),
                                                                              ))),
                                                                          const SizedBox(
                                                                            width:
                                                                                4,
                                                                          ),
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              await DBHelper().updateVersesData(
                                                                                int.parse(data.plaincontent.toString()),
                                                                                "is_bookmarked",
                                                                                "no",
                                                                              );
                                                                              // DBHelper().updateVersesDataByContent((parse(data.content).body?.text ?? '').toString(), "is_bookmarked", "no").then((value) {});
                                                                              DBHelper().deleteBookmark(data.id!.toInt()).then((value) {
                                                                                loadData();
                                                                                Get.back();
                                                                              });
                                                                            },
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: CommanColor.lightDarkPrimary(context),
                                                                              fixedSize: Size(MediaQuery.of(context).size.width * 0.3, 35),
                                                                              elevation: 0,
                                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              "Remove",
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.w400,
                                                                                letterSpacing: BibleInfo.letterSpacing,
                                                                                fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                9,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                          child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5),
                                                              height: 40,
                                                              width: 40,
                                                              decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                      color: CommanColor
                                                                          .lightDarkPrimary(
                                                                              context),
                                                                      width:
                                                                          1.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3)),
                                                              child:
                                                                  Image.asset(
                                                                "assets/delete.png",
                                                                height: 25,
                                                                width: 20,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context),
                                                              )),
                                                        ),
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Text("Delete",
                                                            style: CommanStyle
                                                                .bothPrimary14500(
                                                                    context)),
                                                      ],
                                                    ),
                                                    // InkWell(
                                                    //   onTap: () {
                                                    //     // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                                                    //     Get.offAll(
                                                    //         () => HomeScreen(
                                                    //             From:
                                                    //                 "Go to Read",
                                                    //             selectedBookForRead:
                                                    //                 int.parse(data
                                                    //                     .bookNum
                                                    //                     .toString()),
                                                    //             selectedChapterForRead: int.parse(data
                                                    //                 .chapterNum
                                                    //                 .toString()),
                                                    //             selectedVerseNumForRead: int.parse(data
                                                    //                 .verseNum
                                                    //                 .toString()),
                                                    //             selectedBookNameForRead: data
                                                    //                 .bookName
                                                    //                 .toString(),
                                                    //             selectedVerseForRead:
                                                    //                 parse(data.content)
                                                    //                     .body
                                                    //                     ?.text
                                                    //                     .toString()),
                                                    //         transition: Transition
                                                    //             .cupertinoDialog,
                                                    //         duration: const Duration(milliseconds: 300));
                                                    //   },
                                                    //   child: Column(
                                                    //     children: [
                                                    //       Container(
                                                    //           padding:
                                                    //               const EdgeInsets
                                                    //                   .all(8),
                                                    //           height: 40,
                                                    //           width: 40,
                                                    //           decoration: BoxDecoration(
                                                    //               border: Border.all(
                                                    //                   color: CommanColor.lightDarkPrimary(
                                                    //                       context),
                                                    //                   width:
                                                    //                       1.2),
                                                    //               borderRadius:
                                                    //                   BorderRadius.circular(
                                                    //                       3)),
                                                    //           child:
                                                    //               Image.asset(
                                                    //             "assets/reading_book.png",
                                                    //             height: 25,
                                                    //             width: 15,
                                                    //             color: CommanColor
                                                    //                 .lightDarkPrimary(
                                                    //                     context),
                                                    //           )),
                                                    //       const SizedBox(
                                                    //         height: 15,
                                                    //       ),
                                                    //       Text("Go to Read",
                                                    //           style: CommanStyle
                                                    //               .bothPrimary14500(
                                                    //                   context)),
                                                    //     ],
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: HtmlWidget(
                                      '''${data!.content}''',
                                      textStyle: CommanStyle.bw14500withBgColor(
                                          context,
                                          index,
                                          -1,
                                          fontSize,
                                          selectedFontFamily),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    children: [
                                      LibraryBibleVersionChip(
                                        bookName: data.bookName,
                                        content:
                                            data.content ?? data.plaincontent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${data.bookName} ${data.chapterNum}:${data.verseNum}",
                                          textAlign: TextAlign.right,
                                          style: CommanStyle.bw14500(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () async {
                                  showModalBottomSheet(
                                    enableDrag: true,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20))),
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20))),
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  height: 3,
                                                  width: 45,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                      color: CommanColor
                                                          .lightDarkPrimary(
                                                              context)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            HtmlWidget(
                                              data.content.toString(),
                                              textStyle: CommanStyle.black15400,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              children: [
                                                LibraryBibleVersionChip(
                                                  bookName: data.bookName,
                                                  content: data.content ??
                                                      data.plaincontent,
                                                ),
                                                const Spacer(),
                                                Text(
                                                    "${data.bookName} ${data.chapterNum}:${data.verseNum}",
                                                    textAlign: TextAlign.right,
                                                    style:
                                                        CommanStyle.black15400),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 35,
                                            ),
                                            SingleChildScrollView(
                                              scrollDirection:
                                                  Axis.horizontal,
                                              child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Column(
                                                  children: [
                                                    InkWell(
                                                        onTap: () async {
                                                          await _libraryAds.runCountedAction(() async {
                                                          await Clipboard.setData(
                                                              ClipboardData(
                                                                  text:
                                                                      "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum}"));
                                                          Constants.showToast(
                                                              "Copied");
                                                          });
                                                        },
                                                        child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border: Border.all(
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  width: 1.4),
                                                            ),
                                                            child: Image.asset(
                                                              "assets/Bookmark icons/Frame 3630.png",
                                                              height: 28,
                                                            ))),
                                                    const SizedBox(
                                                      height: 15,
                                                    ),
                                                    Text(
                                                      "Copy",
                                                      style: CommanStyle
                                                          .bothPrimary14500(
                                                              context),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  width: 30,
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    await _libraryAds.runCountedAction(() async {
                                                    final canRead =
                                                        await LibraryBibleGuard
                                                            .allowReadOrToast(
                                                      bookNum: data.bookNum,
                                                      chapterNum:
                                                          data.chapterNum,
                                                      verseNum: data.verseNum,
                                                      savedContent:
                                                          data.content ??
                                                              data.plaincontent,
                                                    );
                                                    if (!canRead) return;
                                                    await SharPreferences
                                                        .setString(
                                                            SharPreferences
                                                                .selectedBook,
                                                            data.bookName
                                                                .toString());

                                                    await SharPreferences.setString(
                                                        SharPreferences
                                                            .selectedChapter,
                                                        "${int.parse(data.chapterNum.toString())}");
                                                    await SharPreferences.setString(
                                                        SharPreferences
                                                            .selectedBookNum,
                                                        "${int.parse(data.bookNum.toString())}");
                                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                                                    Get.offAll(
                                                        () => HomeScreen(
                                                            From: "Read",
                                                            selectedBookForRead:
                                                                int.parse(data
                                                                    .bookNum
                                                                    .toString()),
                                                            selectedChapterForRead:
                                                                int.parse(data
                                                                    .chapterNum
                                                                    .toString()),
                                                            selectedVerseNumForRead:
                                                                int.parse(data
                                                                    .verseNum
                                                                    .toString()),
                                                            selectedBookNameForRead:
                                                                data.bookName
                                                                    .toString(),
                                                            selectedVerseForRead:
                                                                parse(data.content)
                                                                    .body
                                                                    ?.text
                                                                    .toString()),
                                                        transition: Transition.cupertinoDialog,
                                                        duration: const Duration(milliseconds: 300));
                                                    });
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          height: 40,
                                                          width: 40,
                                                          decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3)),
                                                          child: Image.asset(
                                                            "assets/reading_book.png",
                                                            height: 25,
                                                            width: 15,
                                                            color: CommanColor
                                                                .lightDarkPrimary(
                                                                    context),
                                                          )),
                                                      const SizedBox(
                                                        height: 15,
                                                      ),
                                                      Text("Read",
                                                          style: CommanStyle
                                                              .bothPrimary14500(
                                                                  context)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 30,
                                                ),
                                                Column(
                                                  children: [
                                                    InkWell(
                                                        onTap: () async {
                                                          await _libraryAds.runCountedAction(() async {
                                                          // final appPackageName =
                                                          //     (await PackageInfo
                                                          //             .fromPlatform())
                                                          //         .packageName;
                                                          // String message =
                                                          //     ''; // Declare the message variable outside the if-else block
                                                          // String appid;
                                                          // appid = BibleInfo
                                                          //     .apple_AppId;
                                                          // if (Platform
                                                          //     .isAndroid) {
                                                          //   message =
                                                          //       "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                          // } else if (Platform
                                                          //     .isIOS) {
                                                          //   message =
                                                          //       "${parse(data.content).body?.text} \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
                                                          // }

                                                          // if (message
                                                          //     .isNotEmpty) {
                                                          //   Share.share(message,
                                                          //       sharePositionOrigin:
                                                          //           Rect.fromPoints(
                                                          //               const Offset(
                                                          //                   2,
                                                          //                   2),
                                                          //               const Offset(
                                                          //                   3,
                                                          //                   3)));
                                                          // } else {
                                                          //   print(
                                                          //       'Message is empty or undefined');
                                                          // }
                                                          return showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                ShareAlertBox(
                                                              verseTitle:
                                                                  " ${data.bookName} ${int.parse(data.chapterNum.toString())}:${int.parse(data.verseNum.toString())}",
                                                              onShareAsText:
                                                                  () async {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                // Your logic here
                                                                final appPackageName =
                                                                    (await PackageInfo
                                                                            .fromPlatform())
                                                                        .packageName;
                                                                String message =
                                                                    ''; // Declare the message variable outside the if-else block
                                                                String appid;
                                                                appid = BibleInfo
                                                                    .apple_AppId;
                                                                if (Platform
                                                                    .isAndroid) {
                                                                  message =
                                                                      "${html.parse("${data.content}").body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                                } else if (Platform
                                                                    .isIOS) {
                                                                  message =
                                                                      '${html.parse("${data.content}").body?.text ?? ''}.\n You can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
                                                                }

                                                                if (message
                                                                    .isNotEmpty) {
                                                                  Share.share(
                                                                      message,
                                                                      sharePositionOrigin: Rect.fromPoints(
                                                                          const Offset(
                                                                              2,
                                                                              2),
                                                                          const Offset(
                                                                              3,
                                                                              3)));
                                                                } else {
                                                                  print(
                                                                      'Message is empty or undefined');
                                                                }
                                                              },
                                                              onShareAsImage:
                                                                  () async {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                final controller =
                                                                    DashBoardController();
                                                                await showModalBottomSheet(
                                                                  isScrollControlled:
                                                                      true,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return ImageBottomSheets(
                                                                      controller:
                                                                          controller,
                                                                      content: data
                                                                          .content
                                                                          .toString(),
                                                                      selectedBook: data
                                                                          .bookName
                                                                          .toString(),
                                                                      selectedChapter: data
                                                                          .chapterNum
                                                                          .toString(),
                                                                      selectedVerseView: data
                                                                          .verseNum
                                                                          .toString(),
                                                                    );
                                                                  },
                                                                );

                                                                // Your logic here
                                                                // Navigator.pop(context);
                                                              },
                                                            ),
                                                          );
                                                          });
                                                        },
                                                        child: Image.asset(
                                                            "assets/share.png",
                                                            height: 40,
                                                            color: CommanColor
                                                                .lightDarkPrimary(
                                                                    context))),
                                                    const SizedBox(
                                                      height: 15,
                                                    ),
                                                    Text("Share",
                                                        style: CommanStyle
                                                            .bothPrimary14500(
                                                                context)),
                                                  ],
                                                ),
                                                const SizedBox(width: 25),
                                                InkWell(
                                                  onTap: () async {
                                                    await _libraryAds.runCountedAction(() async {
                                                    Get.back();
                                                    Get.to(
                                                      () => ChatScreen(
                                                        verseContext: {
                                                          'verseText': parse(data
                                                                      .content)
                                                                  .body
                                                                  ?.text
                                                                  .toString() ??
                                                              '',
                                                          'book': data.bookName
                                                              .toString(),
                                                          'chapter': data
                                                              .chapterNum
                                                              .toString(),
                                                          'verse': data.verseNum
                                                              .toString(),
                                                        },
                                                      ),
                                                      transition: Transition
                                                          .cupertinoDialog,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                    );
                                                    });
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        height: 40,
                                                        width: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: CommanColor
                                                                  .lightDarkPrimary(
                                                                      context),
                                                              width: 1.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Image.asset(
                                                          'assets/Chat icon.png',
                                                          height: 22,
                                                          width: 22,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 15),
                                                      Text("Ask",
                                                          style: CommanStyle
                                                              .bothPrimary14500(
                                                                  context)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 30,
                                                ),
                                                Column(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        Get.back();
                                                        showDialog<void>(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (BuildContext
                                                              context) {
                                                            return Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5)),
                                                              elevation: 16,
                                                              backgroundColor:
                                                                  Colors.white,
                                                              insetPadding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      screenWidth >
                                                                              450
                                                                          ? 65
                                                                          : 20),
                                                              child: ListView(
                                                                shrinkWrap:
                                                                    true,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            20),
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsets.only(
                                                                        top: 0,
                                                                        right:
                                                                            12,
                                                                        left:
                                                                            12,
                                                                        bottom:
                                                                            5),
                                                                    child: Text(
                                                                        "After removing the content, you can't Undo",
                                                                        style: TextStyle(
                                                                            color: Colors
                                                                                .black,
                                                                            letterSpacing: BibleInfo
                                                                                .letterSpacing,
                                                                            fontSize: screenWidth > 450
                                                                                ? BibleInfo.fontSizeScale * 20
                                                                                : BibleInfo.fontSizeScale * 16,
                                                                            fontWeight: FontWeight.w400),
                                                                        textAlign: TextAlign.center),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsets.only(
                                                                        top: 0,
                                                                        bottom:
                                                                            10),
                                                                    child: Text(
                                                                        '${data.bookName} ${data.chapterNum}:${data.verseNum}',
                                                                        style: TextStyle(
                                                                            color: Colors
                                                                                .black,
                                                                            letterSpacing: BibleInfo
                                                                                .letterSpacing,
                                                                            fontSize: screenWidth > 450
                                                                                ? BibleInfo.fontSizeScale * 20
                                                                                : BibleInfo.fontSizeScale * 16,
                                                                            fontWeight: FontWeight.w500),
                                                                        textAlign: TextAlign.center),
                                                                  ),
                                                                  // Row(
                                                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                                                  //   children: [
                                                                  //     Stack(
                                                                  //       children: [
                                                                  //         Container(
                                                                  //             decoration: BoxDecoration(
                                                                  //               color:Color(0xFFFFEDEA),
                                                                  //               borderRadius: BorderRadius.circular(5),
                                                                  //             ),
                                                                  //             width: MediaQuery.of(context).size.width*0.8,
                                                                  //             padding: EdgeInsets.symmetric(horizontal: 5,vertical: 8),
                                                                  //             height: 60,
                                                                  //             child: Row(
                                                                  //               mainAxisAlignment: MainAxisAlignment.start,
                                                                  //               crossAxisAlignment: CrossAxisAlignment.start,
                                                                  //               children: [
                                                                  //                 Icon(Icons.warning_rounded,color:Color(0xFFf35627) ,),
                                                                  //                 SizedBox(width: 10,),
                                                                  //                 Column(
                                                                  //                   crossAxisAlignment: CrossAxisAlignment.start,
                                                                  //                   mainAxisAlignment: MainAxisAlignment.start,
                                                                  //                   children: [
                                                                  //                     SizedBox(height: 3,),
                                                                  //                     Text("Warning",style: TextStyle(color: Color(0xFFA85346),letterSpacing: BibleInfo.letterSpacing ,  fontSize: BibleInfo.fontSizeScale * 14,fontWeight: FontWeight.w500),),
                                                                  //                     SizedBox(height: 2,),
                                                                  //                     Text("After remove these Bookmark you can't Undo.",style: TextStyle(color: Color(0xFFC05D44),letterSpacing: BibleInfo.letterSpacing ,  fontSize: BibleInfo.fontSizeScale * 12,fontWeight: FontWeight.w400),),
                                                                  //                   ],
                                                                  //                 )
                                                                  //               ],
                                                                  //             )
                                                                  //
                                                                  //         ),
                                                                  //         Positioned(
                                                                  //           left: 0,
                                                                  //           top: 0,
                                                                  //           bottom: 0,
                                                                  //           child: Container(
                                                                  //             //padding: EdgeInsets.only(left: 10),
                                                                  //             // margin: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                                                                  //             decoration: BoxDecoration(
                                                                  //               color:Color(0xFFf35627),
                                                                  //               borderRadius: BorderRadius.horizontal(left: Radius.circular(5)),
                                                                  //             ),
                                                                  //             width: 3.5,
                                                                  //             height: 70,
                                                                  //           ),)
                                                                  //       ],
                                                                  //     ),
                                                                  //   ],
                                                                  // ),

                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceEvenly,
                                                                    children: [
                                                                      const SizedBox(
                                                                        width:
                                                                            9,
                                                                      ),
                                                                      ElevatedButton(
                                                                          onPressed:
                                                                              () async {
                                                                            Navigator.pop(context);
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                CommanColor.lightGrey1,
                                                                            fixedSize:
                                                                                Size(MediaQuery.of(context).size.width * 0.3, 35),
                                                                            elevation:
                                                                                0,
                                                                            shape:
                                                                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: BorderSide(color: CommanColor.lightGrey1, width: 1)),
                                                                          ),
                                                                          child: Center(
                                                                              child: Text(
                                                                            "Cancel",
                                                                            style:
                                                                                TextStyle(
                                                                              color: CommanColor.black,
                                                                              fontWeight: FontWeight.w400,
                                                                              letterSpacing: BibleInfo.letterSpacing,
                                                                              fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14,
                                                                            ),
                                                                          ))),
                                                                      const SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          await DBHelper().updateVersesData(
                                                                              int.parse(data.plaincontent.toString()),
                                                                              "is_bookmarked",
                                                                              "no");
                                                                          await DBHelper()
                                                                              .deleteBookmark(data.id!.toInt())
                                                                              .then((value) {
                                                                            loadData();
                                                                            Get.back();
                                                                          });
                                                                        },
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              CommanColor.lightDarkPrimary(context),
                                                                          fixedSize: Size(
                                                                              MediaQuery.of(context).size.width * 0.3,
                                                                              35),
                                                                          elevation:
                                                                              0,
                                                                          shape:
                                                                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          "Remove",
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            letterSpacing:
                                                                                BibleInfo.letterSpacing,
                                                                            fontSize: screenWidth > 450
                                                                                ? BibleInfo.fontSizeScale * 19
                                                                                : BibleInfo.fontSizeScale * 14,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            9,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          height: 40,
                                                          width: 40,
                                                          decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3)),
                                                          child: Image.asset(
                                                            "assets/delete.png",
                                                            height: 25,
                                                            width: 20,
                                                            color: CommanColor
                                                                .lightDarkPrimary(
                                                                    context),
                                                          )),
                                                    ),
                                                    const SizedBox(
                                                      height: 15,
                                                    ),
                                                    Text("Delete",
                                                        style: CommanStyle
                                                            .bothPrimary14500(
                                                                context)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Icon(
                                    Icons.more_vert,
                                    color: CommanColor.whiteBlack(context),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                          height: 2,
                          child: Divider(
                            thickness: 0.5,
                            color: CommanColor.whiteBlack(context),
                          )),
                      if (_libraryAds.shouldShowBannerAfter(index))
                        _libraryAds.buildInlineBanner(index, keyPrefix: 'bookmark'),
                    ],
                  );
                },
              );
            } else {
              return const SizedBox.expand(
                child: LibraryEmptyState(
                  icon: Icons.bookmark,
                  title: 'No Bookmarks Yet',
                  subtitle:
                      'Bookmark verses while reading to access them anytime.',
                ),
              );
            }
          }),
    );
  }
}
