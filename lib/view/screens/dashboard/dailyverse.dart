import 'dart:async';
import 'dart:convert';
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
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Model/dailyVerseList.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../../controller/dpProvider.dart';
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
        '${v.book} ${dailyVerseUiChapter(v.chapter)}:${dailyVerseUiVerse(v.verseNum)}');
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
            dailyVerseUiChapter(v.chapter) == ch &&
            dailyVerseUiVerse(v.verseNum) == vs) {
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
  final Map<int, String> _bookTitleByNum = {};
  final Map<int, String> _englishTitleByNum = {};

  /// Tamil book titles by `book_num` (0 = Genesis). Used when today's verse
  /// text is Tamil and the open Bible is English.
  static const Map<int, String> _tamilBookTitles = {
    0: 'ஆதியாகமம்',
    1: 'யாத்திராகமம்',
    2: 'லேவியராகமம்',
    3: 'எண்ணாகமம்',
    4: 'உபாகமம்',
    5: 'யோசுவா',
    6: 'நியாயாதிபதிகள்',
    7: 'ரூத்',
    8: '1 சாமுவேல்',
    9: '2 சாமுவேல்',
    10: '1 இராஜாக்கள்',
    11: '2 இராஜாக்கள்',
    12: '1 நாளாகமம்',
    13: '2 நாளாகமம்',
    14: 'எஸ்றா',
    15: 'நெகேமியா',
    16: 'எஸ்தர்',
    17: 'யோபு',
    18: 'சங்கீதம்',
    19: 'நீதிமொழிகள்',
    20: 'பிரசங்கி',
    21: 'உன்னதப்பாட்டு',
    22: 'ஏசாயா',
    23: 'எரேமியா',
    24: 'புலம்பல்',
    25: 'எசேக்கியேல்',
    26: 'தானியேல்',
    27: 'ஓசியா',
    28: 'யோவேல்',
    29: 'ஆமோஸ்',
    30: 'ஒபதியா',
    31: 'யோனா',
    32: 'மீகா',
    33: 'நாகூம்',
    34: 'ஆபகூக்',
    35: 'செப்பனியா',
    36: 'ஆகாய்',
    37: 'சகரியா',
    38: 'மல்கியா',
    39: 'மத்தேயு',
    40: 'மாற்கு',
    41: 'லூக்கா',
    42: 'யோவான்',
    43: 'அப்போஸ்தலர்',
    44: 'ரோமர்',
    45: '1 கொரி',
    46: '2 கொரி',
    47: 'கலாத்தியர்',
    48: 'எபேசியர்',
    49: 'பிலிப்பியர்',
    50: 'கொலோசெயர்',
    51: '1 தெசலோனிக்கேயர்',
    52: '2 தெசலோனிக்கேயர்',
    53: '1 தீமோத்தேயு',
    54: '2 தீமோத்தேயு',
    55: 'தீத்து',
    56: 'பிலேமோன்',
    57: 'எபிரேயர்',
    58: 'யாக்கோபு',
    59: '1 பேதுரு',
    60: '2 பேதுரு',
    61: '1 யோவான்',
    62: '2 யோவான்',
    63: '3 யோவான்',
    64: 'யூதா',
    65: 'வெளிப்படுத்தல்',
  };

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

  /// Book name under the verse, in the same language as the verse text.
  String _bookLabel(DailyVerseList data) {
    final stored = (data.book ?? '').trim();
    final bookId = int.tryParse('${data.bookId}') ?? 0;
    final bookNum = bookId > 0 ? bookId - 1 : bookId;
    final tamil = _titleForBook(_tamilBookTitles, bookNum, bookId);
    final english = _titleForBook(_englishTitleByNum, bookNum, bookId);
    final fromTable = _titleForBook(_bookTitleByNum, bookNum, bookId);
    if (_hasTamil(data.verse ?? '')) {
      if (tamil.isNotEmpty) return tamil;
      if (_hasTamil(fromTable)) return fromTable;
      if (_hasTamil(stored)) return stored;
    } else {
      if (english.isNotEmpty) return english;
      if (fromTable.isNotEmpty && !_hasTamil(fromTable)) return fromTable;
      if (stored.isNotEmpty && !_hasTamil(stored)) return stored;
    }
    if (fromTable.isNotEmpty) return fromTable;
    return stored;
  }

  String _titleForBook(Map<int, String> titles, int bookNum, int bookId) {
    return (titles[bookNum] ?? titles[bookId] ?? '').trim();
  }

  bool _hasTamil(String text) => RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);

  Future<void> _loadBookTitles() async {
    try {
      final db = await DBHelper().db;
      if (db != null) {
        final rows = await db.rawQuery('SELECT book_num, title FROM book');
        final map = <int, String>{};
        for (final row in rows) {
          final bookNum = int.tryParse('${row['book_num']}');
          final title = row['title']?.toString().trim() ?? '';
          if (bookNum == null || title.isEmpty) continue;
          map[bookNum] = title;
        }
        if (!mounted) return;
        setState(() {
          _bookTitleByNum
            ..clear()
            ..addAll(map);
          if (!map.values.any(_hasTamil)) {
            _englishTitleByNum
              ..clear()
              ..addAll(map);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    _showCachedDailyVersesImmediately(provider);
    _loadBookTitles();
    loaddata();
    getFont();
    // Track Daily Verses event
    AnalyticsService.trackDailyVerses();
  }

  void _showCachedDailyVersesImmediately(DownloadProvider provider) {
    if (provider.dailyVerseList.isNotEmpty) {
      _applyDailyVersesFromAll(provider.dailyVerseList);
      provider.isLoadingDailyVerse = false;
      return;
    }

    Future.microtask(() async {
      await _showSavedVersesIfWaiting();
    });
  }

  Future<void> _applyWidgetVerseOrderingIfNeeded() async {
    if (!widget.fromWidget || dailyVerseList.isEmpty) return;

    final widgetData = await getVerseOfTheDayWidgetData();
    final widgetRef = (widgetData['reference'] ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (widgetRef.isEmpty) return;

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
    }
  }

  void _applyDailyVersesFromAll(List<DailyVerseList> allVerses) {
    final todayOnly = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

    if (dailyVerseList.isEmpty && allVerses.isNotEmpty) {
      dailyVerseList = List<DailyVerseList>.from(allVerses);
    }

    dailyVerseList.sort((a, b) {
      try {
        final da = DateTime.parse(a.date.toString());
        final db = DateTime.parse(b.date.toString());
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });
  }

  /// Shows the last saved verses so the screen does not stay on "loading..."
  /// while a refresh is still reading the database.
  Future<void> _showSavedVersesIfWaiting() async {
    if (dailyVerseList.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('cachedDailyVerseList_v2');
    if (cachedJson == null || cachedJson.isEmpty) return;
    try {
      final decoded = jsonDecode(cachedJson);
      if (decoded is! List || decoded.isEmpty) return;
      final all = decoded
          .whereType<Map>()
          .map((e) => DailyVerseList.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (all.isEmpty) return;
      _applyDailyVersesFromAll(all);
      if (!mounted) return;
      Provider.of<DownloadProvider>(context, listen: false)
          .isLoadingDailyVerse = false;
      setState(() {});
    } catch (_) {}
  }

  void loaddata() async {
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    final hadVisibleContent = dailyVerseList.isNotEmpty;

    if (!hadVisibleContent) {
      await _showSavedVersesIfWaiting();
      if (dailyVerseList.isEmpty && provider.dailyVerseList.isNotEmpty) {
        _applyDailyVersesFromAll(provider.dailyVerseList);
        provider.isLoadingDailyVerse = false;
        if (mounted) setState(() {});
      }
    }

    if (dailyVerseList.isNotEmpty) {
      unawaited(_refreshDailyVersesInBackground(provider));
      return;
    }

    try {
      await provider.loadDailyVerses();

      var allVerses = provider.dailyVerseList;
      if (allVerses.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cats = prefs.getStringList('selected_categories') ?? [];
        if (cats.isNotEmpty) {
          await prefs.setBool('dataIsChanged', true);
          await provider.loadDailyVerses();
          allVerses = provider.dailyVerseList;
        }
        if (allVerses.isEmpty) {
          await prefs.setBool('dataIsChanged', true);
          await provider.loadDailyVerses();
          allVerses = provider.dailyVerseList;
        }
      }

      _applyDailyVersesFromAll(allVerses);
      await _applyWidgetVerseOrderingIfNeeded();
    } catch (_) {
      provider.isLoadingDailyVerse = false;
    }

    if (mounted) setState(() {});
  }

  Future<void> _refreshDailyVersesInBackground(
      DownloadProvider provider) async {
    await provider.loadDailyVerses();
    if (!mounted) return;

    var allVerses = provider.dailyVerseList;
    if (allVerses.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dataIsChanged', true);
      await provider.loadDailyVerses();
      allVerses = provider.dailyVerseList;
    }

    if (allVerses.isEmpty) return;

    _applyDailyVersesFromAll(allVerses);
    await _applyWidgetVerseOrderingIfNeeded();
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
                          "${_bookLabel(data)} ${dailyVerseUiChapter(data.chapter)}: ${dailyVerseUiVerse(data.verseNum)}",
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
                                  "${parse(data.verse).body?.text} \n${_bookLabel(data)} ${dailyVerseUiChapter(data.chapter)}:${dailyVerseUiVerse(data.verseNum)}"));
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
                          final sheetContext = context;
                          final bookId = int.parse(data.bookId.toString());
                          final bookNum = dailyVerseBookNum(bookId);
                          final chapter = dailyVerseUiChapter(data.chapter);
                          final verseNum =
                              int.parse(data.verseNum.toString());
                          final verseText =
                              parse(data.verse).body?.text.toString() ?? '';
                          // Same source as Mark as Read: title from book_num.
                          var bookName = data.book.toString();
                          try {
                            final db = await DBHelper().db;
                            if (db != null) {
                              final rows = await db.rawQuery(
                                'SELECT title FROM book WHERE book_num = ? LIMIT 1',
                                [bookNum],
                              );
                              final title = rows.isNotEmpty
                                  ? rows.first['title']?.toString().trim()
                                  : null;
                              if (title != null && title.isNotEmpty) {
                                bookName = title;
                              }
                            }
                          } catch (_) {}

                          Navigator.of(sheetContext).pop();
                          await Future<void>.delayed(
                              const Duration(milliseconds: 220));

                          await SharPreferences.setString(
                              SharPreferences.selectedBook, bookName);
                          await SharPreferences.setString(
                              SharPreferences.selectedChapter, "$chapter");
                          await SharPreferences.setString(
                              SharPreferences.selectedBookNum, "$bookNum");

                          try {
                            final controller =
                                Get.find<DashBoardController>();
                            controller.selectedBook.value = bookName;
                            controller.selectedBookNum.value = "$bookNum";
                            controller.selectedChapter.value = "$chapter";
                            controller.selectChapterChange.value = chapter;
                            controller.selectedBookNameForRead.value =
                                bookName;
                            controller.selectedBookNumForRead.value =
                                "$bookNum";
                            controller.selectedChapterForRead.value =
                                "$chapter";
                            Get.until((route) => route.isFirst);
                            await Future<void>.delayed(
                                const Duration(milliseconds: 120));
                            controller.isFetchContent.value = true;
                            controller.selectedBookContent.clear();
                            await controller.getBookContentForRead();
                            controller.isFetchContent.value = false;
                            final listIndex = resolveDailyVerseListIndex(
                              verseNum,
                              controller.selectedBookContent,
                              versePlainText: verseText,
                            );
                            controller.selectedVerseForRead.value =
                                "$listIndex";
                            controller.readHighlight.value = true;
                            controller.selectedIndex.value = listIndex;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Future.delayed(
                                  const Duration(milliseconds: 400), () async {
                                try {
                                  await controller.scrollToIndex(listIndex);
                                } catch (_) {}
                                Future.delayed(const Duration(seconds: 6), () {
                                  controller.readHighlight.value = false;
                                  controller.selectedIndex.value = -1;
                                });
                              });
                            });
                          } catch (_) {
                            Get.offAll(
                              () => HomeScreen(
                                From: "Daily",
                                selectedBookForRead: bookNum,
                                selectedChapterForRead: chapter,
                                selectedVerseNumForRead: verseNum,
                                selectedBookNameForRead: bookName,
                                selectedVerseForRead: verseText,
                              ),
                              transition: Transition.fadeIn,
                              duration: const Duration(milliseconds: 400),
                              opaque: true,
                            );
                          }
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
                                  " ${_bookLabel(data)} ${dailyVerseUiChapter(data.chapter)}:${dailyVerseUiVerse(data.verseNum)}",
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
                                      "${html.parse("${data.verse}").body?.text ?? ''}.\n\nYou can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                } else if (Platform.isIOS) {
                                  message =
                                      '${html.parse("${data.verse}").body?.text ?? ''}.\n${_bookLabel(data)} ${dailyVerseUiChapter(data.chapter)}:${dailyVerseUiVerse(data.verseNum)}\n\nYou can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
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
                                final appPackageName =
                                    (await PackageInfo.fromPlatform())
                                        .packageName;
                                final appid = BibleInfo.apple_AppId;
                                final shareFooterMessage = Platform.isAndroid
                                    ? '\n\nYou can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName'
                                    : '\n\nYou can read more at:\nhttps://itunes.apple.com/app/id$appid';
                                final controller = DashBoardController();
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (context) {
                                    return ImageBottomSheets.dailyVerse(
                                      controller: controller,
                                      content: data.verse.toString(),
                                      selectedBook: _bookLabel(data),
                                      selectedChapter:
                                          "${dailyVerseUiChapter(data.chapter)}",
                                      selectedVerseView:
                                          "${dailyVerseUiVerse(data.verseNum)}",
                                      shareFooterMessage: shareFooterMessage,
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
                                'book': _bookLabel(data),
                                'chapter':
                                    '${dailyVerseUiChapter(data.chapter)}',
                                'verse':
                                    '${dailyVerseUiVerse(data.verseNum)}',
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

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isVintage
          ? (isDark ? CommanColor.black : const Color(0xFFF5F0E6))
          : (isDark
              ? CommanColor.darkPrimaryColor
              : themeProvider.backgroundColor),
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: isVintage
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
                        "Verse For You",
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
                            color: Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .themeMode ==
                                    ThemeMode.dark
                                ? Colors.transparent
                                : CommanColor.lightDarkPrimary(context)
                                    .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Provider.of<ThemeProvider>(context,
                                              listen: false)
                                          .themeMode ==
                                      ThemeMode.dark
                                  ? Colors.white
                                  : CommanColor.lightDarkPrimary(context)
                                      .withOpacity(0.45),
                              width: Provider.of<ThemeProvider>(context,
                                              listen: false)
                                          .themeMode ==
                                      ThemeMode.dark
                                  ? 1.2
                                  : 1,
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
                                'Topics',
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
                  child: provider.isLoadingDailyVerse &&
                          dailyVerseList.isEmpty
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
                                final formattedDate =
                                    DateFormat("dd-MM-yyyy").format(date);
                                final String dateLabel =
                                    formattedDate == currentDate
                                        ? "Today"
                                        : formattedDate == yesterdayDate
                                            ? "Yesterday"
                                            : DateFormat('MMMM d, yyyy')
                                                .format(date);
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
                                              dateLabel,
                                              style: CommanStyle.bw16500(
                                                      context)
                                                  .copyWith(
                                                      fontSize: fontSize,
                                                      color: CommanColor
                                                          .whiteBlack(
                                                              context)),
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
                                                "${_bookLabel(data)} ${dailyVerseUiChapter(data.chapter)}:${dailyVerseUiVerse(data.verseNum)}",
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
