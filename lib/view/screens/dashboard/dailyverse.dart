import 'dart:io';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Model/dailyVerseList.dart';
import '../../constants/constant.dart';
import '../../constants/images.dart';
import 'package:flutter/cupertino.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';

String _normalizeDailyVerseRef(String s) =>
    s
        .toLowerCase()
        .replaceAll(RegExp(r'[\u2018\u2019\u201C\u201D]'), "'")
        .replaceAll(RegExp(r'[^a-z0-9: ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

/// Finds the list index for the verse shown on the home widget (handles spacing / parsing).
int _indexOfVerseMatchingWidgetRef(
    List<DailyVerseList> list, String widgetRef) {
  final wNorm = _normalizeDailyVerseRef(widgetRef);
  if (wNorm.isEmpty) return -1;
  for (var i = 0; i < list.length; i++) {
    final v = list[i];
    final listRef = _normalizeDailyVerseRef(
        '${v.book} ${(v.chapter ?? 0) + 1}:${(v.verseNum ?? 0) + 1}');
    if (listRef == wNorm ||
        listRef.replaceAll(' ', '') == wNorm.replaceAll(' ', '')) {
      return i;
    }
  }
  final rm = RegExp(r'^(.*)\s(\d+):(\d+)$').firstMatch(widgetRef.trim());
  if (rm != null) {
    final bookW = rm.group(1)!.trim().toLowerCase();
    final ch = int.tryParse(rm.group(2)!);
    final vs = int.tryParse(rm.group(3)!);
    if (ch != null && vs != null) {
      for (var i = 0; i < list.length; i++) {
        final v = list[i];
        if ((v.book ?? '').toLowerCase().trim() == bookW &&
            (v.chapter ?? 0) + 1 == ch &&
            (v.verseNum ?? 0) + 1 == vs) {
          return i;
        }
      }
    }
  }
  return -1;
}

class DailyVerse extends StatefulWidget {
  const DailyVerse({super.key, this.fromWidget = false});

  final bool fromWidget;

  @override
  State<DailyVerse> createState() => _DailyVerseState();
}

class _DailyVerseState extends State<DailyVerse> {
  List<DailyVerseList> dailyVerseList = [];
  OverlayEntry? _overlayEntry;
  late List<GlobalKey> itemKeys;

  // @override
  // void initState() {
  //   super.initState();

  //   // Load data in microtask to avoid context issues
  //   //  Future.microtask(() {

  //   loaddata(); // call after provider loads data
  //   //  });
  // }

  // void loaddata() async {
  //   Future.microtask(() async {
  //     await Provider.of<DownloadProvider>(context, listen: false)
  //         .loadDailyVerses();
  //   });
  //   final provider = Provider.of<DownloadProvider>(context, listen: false);
  //   final todayOnly = DateFormat('yyyy-MM-dd').format(DateTime.now());

  //   final allVerses = provider.dailyVerseList;

  //   dailyVerseList = allVerses.where((verse) {
  //     try {
  //       final verseDate = DateTime.parse(verse.date.toString());
  //       final verseDateOnly = DateFormat('yyyy-MM-dd').format(verseDate);
  //       return verseDateOnly.compareTo(todayOnly) <= 0; // today or past
  //     } catch (e) {
  //       return false;
  //     }
  //   }).toList();
  // }

  double fontSize = Sizecf.scrnWidth! > 450 ? 25.0 : 15.0;
  var fontSizeS = "";
  var selectedFontFamily = "";
  Future<void> getFont() async {
    final fs =
        await SharPreferences.getString(SharPreferences.selectedFontSize) ??
            "${Sizecf.scrnWidth! > 450 ? 25.0 : 15.0}";
    final ff =
        await SharPreferences.getString(SharPreferences.selectedFontFamily) ??
            "Arial";
    if (mounted) {
      setState(() {
        fontSizeS = fs;
        fontSize = double.parse(fontSizeS);
        selectedFontFamily = ff;
      });
    } else {
      fontSizeS = fs;
      fontSize = double.parse(fontSizeS);
      selectedFontFamily = ff;
    }
  }

  @override
  void initState() {
    super.initState();
    loaddata();
    getFont();
    // Track Daily Verses event
    AnalyticsService.trackDailyVerses();
  }

  void loaddata() async {
    final provider = Provider.of<DownloadProvider>(context, listen: false);

    // Ensure the verses are loaded
    await provider.loadDailyVerses();

    final todayOnly = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allVerses = provider.dailyVerseList;

    dailyVerseList = allVerses
        .where((verse) {
          try {
            final verseDate = DateTime.parse(verse.date.toString());
            final verseDateOnly = DateFormat('yyyy-MM-dd').format(verseDate);
            return verseDateOnly.compareTo(todayOnly) <= 0; // today or past
          } catch (e) {
            return false;
          }
        })
        .toList();

    // Stable ordering: newest (latest date) first so "first" is deterministic.
    dailyVerseList.sort((a, b) {
      try {
        final da = DateTime.parse(a.date.toString());
        final db = DateTime.parse(b.date.toString());
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });

    // When opened from Verse of the Day widget, show the same verse as on the widget first
    if (widget.fromWidget && dailyVerseList.isNotEmpty) {
      final widgetData = await getVerseOfTheDayWidgetData();
      final widgetRef = (widgetData['reference'] ?? '')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
      if (widgetRef.isNotEmpty) {
        var idx = _indexOfVerseMatchingWidgetRef(dailyVerseList, widgetRef);
        if (idx < 0) {
          final widgetPlain =
              stripHtmlTagsForWidgetVerse(widgetData['text'] ?? '');
          final plain = widgetPlain.trim();
          if (plain.length >= 12) {
            final prefixLen = plain.length < 28 ? plain.length : 28;
            final prefix = plain.substring(0, prefixLen).toLowerCase();
            idx = dailyVerseList.indexWhere((v) {
              final t = stripHtmlTagsForWidgetVerse(v.verse ?? '').toLowerCase();
              if (t.startsWith(prefix)) return true;
              if (t.isEmpty) return false;
              final headLen = t.length < prefixLen ? t.length : prefixLen;
              return prefix.startsWith(t.substring(0, headLen));
            });
          }
        }
        if (idx > 0) {
          final item = dailyVerseList.removeAt(idx);
          dailyVerseList.insert(0, item);
          if (mounted) setState(() {});
        }
      }
    }

    // dailyVerseList.sort((a, b) {
    //   final dateA = DateTime.parse(a.date.toString());
    //   final dateB = DateTime.parse(b.date.toString());
    //   return dateB.compareTo(dateA);
    // });

    if (mounted) setState(() {});
  }

  void _showOverlay(BuildContext buttonContext, category) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // final overlay = Overlay.of(context);
    // // final RenderBox renderBox =
    // //     iconKey.currentContext!.findRenderObject() as RenderBox;
    // // final position = renderBox.localToGlobal(Offset.zero);
    // final renderBox = context.findRenderObject() as RenderBox;
    // final position = renderBox.localToGlobal(Offset.zero);
    final renderBox = buttonContext.findRenderObject();
    if (renderBox is RenderBox) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final overlay = Overlay.of(buttonContext);
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          // top: position.dy + 50,
          // right: 20,
          top: position.dy + size.height,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E3E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Category: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: category ?? 'Faith',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(_overlayEntry!);
    }

    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void showModalBottomSheetDaily(DailyVerseList data) {
      showModalBottomSheet(
        enableDrag: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            // height: MediaQuery.of(context).size.height*0.3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 3,
                    width: 45,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: CommanColor.lightDarkPrimary(context)),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  HtmlWidget(
                    '''${data.verse}''',
                    textStyle: CommanStyle.black15400,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                          "${data.book} ${data.chapter! + 1}: ${data.verseNum! + 1}",
                          textAlign: TextAlign.right,
                          style: CommanStyle.black15400),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(
                              text:
                                  "${parse(data.verse).body?.text} \n${data.book} ${data.chapter! + 1}:${data.verseNum! + 1}"));
                          Constants.showToast("Copied");
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: CommanColor.lightDarkPrimary(context),
                                  width: 1.4,
                                ),
                              ),
                              child: Image.asset(
                                "assets/Bookmark icons/Frame 3630.png",
                                height: 28,
                                color: CommanColor.lightDarkPrimary(context),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                              "Copy",
                              style: CommanStyle.bothPrimary14500(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () async {
                          // debugPrint(
                          //   "bookid - ${int.parse(data.bookId.toString())} chapter - ${1 + int.parse(data.chapter.toString())} verseno - ${1 + int.parse(data.verseNum.toString())} book - ${data.book.toString()}  vcontent - ${parse(data.verse).body?.text.toString()} ",
                          // );

                          await SharPreferences.setString(
                              SharPreferences.selectedBook,
                              data.book.toString());

                          await SharPreferences.setString(
                              SharPreferences.selectedChapter,
                              "${1 + int.parse(data.chapter.toString())}");
                          await SharPreferences.setString(
                              SharPreferences.selectedBookNum,
                              "${int.parse(data.bookId.toString())}");
                          Get.offAll(
                              () => HomeScreen(
                                  From: "Daily",
                                  selectedBookForRead:
                                      int.parse(data.bookId.toString()),
                                  selectedChapterForRead:
                                      1 + int.parse(data.chapter.toString()),
                                  selectedVerseNumForRead:
                                      1 + int.parse(data.verseNum.toString()),
                                  selectedBookNameForRead: data.book.toString(),
                                  selectedVerseForRead:
                                      parse(data.verse).body?.text.toString()),
                              transition: Transition.cupertinoDialog,
                              duration: const Duration(milliseconds: 300));
                          // await SharPreferences.setString(
                          //     SharPreferences.selectedBookNum,
                          //     ((data.bookId ?? 1) - 1).toString());
                          // await SharPreferences.setString(
                          //     SharPreferences.selectedChapter,
                          //     data.chapter?.toString() ?? '');
                          // await SharPreferences.setString(
                          //     SharPreferences.selectedBook,
                          //     data.book.toString());
                          // Get.offAll(
                          //     () => HomeScreen(
                          //         From: "Read",
                          //         selectedBookForRead:
                          //             int.parse(data.bookId.toString()),
                          //         selectedChapterForRead:
                          //             int.parse(data.chapter.toString()),
                          //         selectedVerseNumForRead:
                          //             int.parse(data.verseNum.toString()),
                          //         selectedBookNameForRead: data.book.toString(),
                          //         selectedVerseForRead:
                          //             parse(data.verse).body?.text.toString()),
                          //     transition: Transition.cupertinoDialog,
                          //     duration: const Duration(milliseconds: 300));
                        },
                        child: Column(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CommanColor.lightDarkPrimary(
                                            context),
                                        width: 1.2),
                                    borderRadius: BorderRadius.circular(3)),
                                child: Image.asset(
                                  "assets/reading_book.png",
                                  height: 25,
                                  width: 15,
                                  color: CommanColor.lightDarkPrimary(context),
                                )),
                            const SizedBox(
                              height: 15,
                            ),
                            Text("Read",
                                style: CommanStyle.bothPrimary14500(context)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      InkWell(
                        onTap: () async {
                          // final appPackageName =
                          //     (await PackageInfo.fromPlatform()).packageName;
                          // String message =
                          //     ''; // Declare the message variable outside the if-else block
                          // String appid;
                          // appid = BibleInfo.apple_AppId;
                          // if (Platform.isAndroid) {
                          //   message =
                          //       "${parse(data.verse).body?.text} \n${data.book} ${data.chapter}:${data.verseNum} \nYou can read more at App \nhttps://play.google.com/store/apps/details?id=$appPackageName";
                          // } else if (Platform.isIOS) {
                          //   message =
                          //       "${parse(data.verse).body?.text} \n${data.book} ${data.chapter}:${data.verseNum} \nYou can read more at App \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
                          // }

                          // if (message.isNotEmpty) {
                          //   Share.share(message,
                          //       sharePositionOrigin: Rect.fromPoints(
                          //           const Offset(2, 2), const Offset(3, 3)));
                          // } else {
                          //   print('Message is empty or undefined');
                          // }

                          return showDialog(
                            context: context,
                            builder: (context) => ShareAlertBox(
                              verseTitle:
                                  " ${data.book} ${int.parse(data.chapter.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                              onShareAsText: () async {
                                Navigator.of(context).pop();
                                // Your logic here
                                final appPackageName =
                                    (await PackageInfo.fromPlatform())
                                        .packageName;
                                String message =
                                    ''; // Declare the message variable outside the if-else block
                                String appid;
                                appid = BibleInfo.apple_AppId;
                                if (Platform.isAndroid) {
                                  message =
                                      "${html.parse("${data.verse}").body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                } else if (Platform.isIOS) {
                                  message =
                                      '${html.parse("${data.verse}").body?.text ?? ''}.\n ${data.book} ${data.chapter! + 1}:${data.verseNum! + 1} \n You can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
                                }

                                if (message.isNotEmpty) {
                                  Share.share(message,
                                      sharePositionOrigin: Rect.fromPoints(
                                          const Offset(2, 2),
                                          const Offset(3, 3)));
                                } else {
                                  debugPrint('Message is empty or undefined');
                                }
                              },
                              onShareAsImage: () async {
                                Navigator.of(context).pop();
                                final controller = DashBoardController();
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (context) {
                                    return ImageBottomSheets(
                                      controller: controller,
                                      content: data.verse.toString(),
                                      selectedBook: data.book.toString(),
                                      selectedChapter:
                                          "${int.parse(data.chapter.toString()) + 1}",
                                      selectedVerseView:
                                          "${int.parse(data.verseNum.toString()) + 1}",
                                      // data.verseNum.toString(),
                                    );
                                  },
                                );

                                // Your logic here
                                // Navigator.pop(context);
                              },
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset("assets/share.png",
                                height: 40,
                                color: CommanColor.lightDarkPrimary(context)),
                            const SizedBox(
                              height: 15,
                            ),
                            Text("Share",
                                style: CommanStyle.bothPrimary14500(context)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Get.to(
                            () => ChatScreen(
                              verseContext: {
                                'verseText':
                                    parse(data.verse).body?.text.toString() ??
                                        '',
                                'book': data.book.toString(),
                                'chapter':
                                    '${int.parse(data.chapter.toString()) + 1}',
                                'verse':
                                    '${int.parse(data.verseNum.toString()) + 1}',
                              },
                            ),
                            transition: Transition.cupertinoDialog,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color:
                                        CommanColor.lightDarkPrimary(context),
                                    width: 1.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.chat_bubble_2,
                                size: 22,
                                color: CommanColor.lightDarkPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text("Ask",
                                style: CommanStyle.bothPrimary14500(context)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");
    final provider = Provider.of<DownloadProvider>(context, listen: true);
    // dailyVerseList = dailyVerseList.reversed.toList();

    return Scaffold(
      body: Container(
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
                        "Daily Verse",
                        style: CommanStyle.appBarStyle(context).copyWith(
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 30
                                : BibleInfo.fontSizeScale * 18,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Get.to(() => PreferenceSelectionScreen(
                                isSetting: true,
                                from: true,
                              ));
                          if (mounted) loaddata();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                Provider.of<ThemeProvider>(context, listen: false)
                                            .themeMode ==
                                        ThemeMode.dark
                                    ? CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.92)
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: CommanColor.lightDarkPrimary(context)
                                  .withOpacity(0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mood,
                                size: 16,
                                color:
                                    Provider.of<ThemeProvider>(context, listen: false)
                                                .themeMode ==
                                            ThemeMode.dark
                                        ? Colors.white
                                        : CommanColor.lightDarkPrimary(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Choose a feeling',
                                style: TextStyle(
                                  fontSize: screenWidth > 450 ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Provider.of<ThemeProvider>(context,
                                                  listen: false)
                                              .themeMode ==
                                          ThemeMode.dark
                                      ? Colors.white
                                      : CommanColor.lightDarkPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: provider.isLoadingDailyVerse
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //   crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  SizedBox(
                                      height: 50,
                                      width: 50,
                                      child:
                                          CircularProgressIndicator.adaptive()),
                                  Text("loading...")
                                ],
                              ),
                            ),
                          ],
                        )
                      : dailyVerseList.isNotEmpty
                          ? ListView.builder(
                              physics: const ScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: dailyVerseList.length,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              itemBuilder: (context, index) {
                                List<DailyVerseList> reversedDailyVerseList =
                                    dailyVerseList.toList();
                                //  dailyVerseList.reversed.toList();
                                // debugPrint(
                                //     "reversedDailyVerseList - ${reversedDailyVerseList[0].date}, ${reversedDailyVerseList[1].date}");
                                var data = reversedDailyVerseList[index];
                                DateTime date =
                                    DateTime.parse(data.date.toString());
                                String currentDate = DateFormat("dd-MM-yyyy")
                                    .format(DateTime.now());
                                String yesterdayDate = DateFormat("dd-MM-yyyy")
                                    .format(DateTime.now()
                                        .subtract(Duration(days: 1)));
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Container(
                                    padding: const EdgeInsets.all(10.0),
                                    margin: const EdgeInsets.only(bottom: 10.0),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                                CommanColor.whiteBlack(context),
                                            width: 1.3),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat("dd-MM-yyyy")
                                                          .format(date) ==
                                                      yesterdayDate
                                                  ? "Yesterday"
                                                  : DateFormat("dd-MM-yyyy")
                                                              .format(date) ==
                                                          currentDate
                                                      ? "Today"
                                                      : DateFormat("dd-MM-yyyy")
                                                          .format(date),
                                              style: CommanStyle.bw16500(
                                                      context)
                                                  .copyWith(
                                                      fontSize: fontSize,
                                                      // screenWidth >
                                                      //         450
                                                      //     ? BibleInfo
                                                      //             .fontSizeScale *
                                                      //         20
                                                      //     : BibleInfo
                                                      //             .fontSizeScale *
                                                      //         16,
                                                      color: CommanColor
                                                          .whiteBlack(context)),
                                            ),
                                            Row(
                                              children: [
                                                Builder(builder: (context1) {
                                                  return GestureDetector(
                                                    // key: iconKey.toString(),
                                                    onTap: () {
                                                      _showOverlay(context1,
                                                          data.categoryName);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                      child: Icon(
                                                        Icons.info_outline,
                                                        color: CommanColor
                                                            .whiteBlack(
                                                                context),
                                                        //  color: Colors.black87,
                                                        size: 26,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                InkWell(
                                                    onTap: () {
                                                      showModalBottomSheetDaily(
                                                          data);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              0.0),
                                                      child: Icon(
                                                        Icons.more_vert,
                                                        color: CommanColor
                                                            .whiteBlack(
                                                                context),
                                                        size: 24,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        GestureDetector(
                                            onTap: () {
                                              showModalBottomSheetDaily(data);
                                            },
                                            child: HtmlWidget(
                                              data.verse ?? '',
                                              textStyle:
                                                  CommanStyle.bwWithChangeFont(
                                                      context,
                                                      fontSize,
                                                      selectedFontFamily),
                                            )),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${data.book} ${data.chapter! + 1}:${data.verseNum! + 1}",
                                                style: CommanStyle
                                                    .bwWithChangeFont(
                                                        context,
                                                        fontSize,
                                                        selectedFontFamily),
                                                textAlign: TextAlign.end,
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Choose your preferred verse topics",
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 20 : 17,
                                      color: CommanColor.whiteBlack(context),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await Get.to(() =>
                                          PreferenceSelectionScreen(
                                            isSetting: true,
                                            from: true,
                                          ));
                                      if (mounted) loaddata();
                                    },
                                    child: Container(
                                      width: screenWidth > 600 ? 130 : 100,
                                      height: screenWidth > 600 ? 65 : 40,
                                      decoration: BoxDecoration(
                                          color: Provider.of<ThemeProvider>(
                                                          context,
                                                          listen: false)
                                                      .themeMode ==
                                                  ThemeMode.dark
                                              ? CommanColor.backgrondcolor
                                              : const Color(0xFF8B5E3C),
                                          borderRadius: BorderRadius.circular(
                                              9) // Brown color
                                          ),
                                      child: Center(
                                        child: Text(
                                          "Continue",
                                          style: TextStyle(
                                              fontSize:
                                                  screenWidth > 600 ? 20 : 17,
                                              color: Provider.of<ThemeProvider>(
                                                              context,
                                                              listen: false)
                                                          .themeMode ==
                                                      ThemeMode.dark
                                                  ? CommanColor.darkPrimaryColor
                                                  : CommanColor.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                )
              ],
            ),
          )),
    );
  }
}
