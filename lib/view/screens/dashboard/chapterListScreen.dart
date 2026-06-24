import 'dart:math' as math;

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/constant.dart';
import '../../constants/images.dart';
import 'package:get/get.dart';

import '../../constants/share_preferences.dart';
import 'home_screen.dart';

class ChapterListScreen extends StatefulWidget {
  var chapterCount;
  var selectedChapter;
  var book_num;
  ChapterListScreen(
      {super.key,
      required this.chapterCount,
      required this.selectedChapter,
      required this.book_num});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  int selectedChapter = 0;
  int selectedChangeChapter = 0;
  List<VerseBookContentModel> selectedVersesContent = [];
  bool loader = false;
  bool? _chapterNumIsZeroBased;
  // var allChapterlist = {};
  @override
  void initState() {
    super.initState();
    loadChapter();
    selectedChapter = int.parse(widget.selectedChapter.toString()) - 1;
  }

  @override
  void activate() {
    super.activate();
    loadChapter();
  }

  /// DB stores chapter_num 0-based (ch.1 = 0) or 1-based (ch.1 = 1).
  bool _usesZeroBasedChapterNums() {
    if (_chapterNumIsZeroBased != null) return _chapterNumIsZeroBased!;
    _chapterNumIsZeroBased =
        selectedVersesContent.any((v) => (v.chapterNum ?? -1) == 0);
    return _chapterNumIsZeroBased!;
  }

  int _storedChapterNumForUiIndex(int index) {
    return _usesZeroBasedChapterNums() ? index : index + 1;
  }

  bool _isUiChapterRead(int index) {
    final storedChapter = _storedChapterNumForUiIndex(index);
    final chapterVerses = selectedVersesContent.where((v) {
      return v.chapterNum?.toInt() == storedChapter;
    }).toList();
    if (chapterVerses.isEmpty) return false;
    return chapterVerses.any((v) => v.isRead == 'yes');
  }

  Future<void> loadChapter() async {
    try {
      final db = await DBHelper().db;
      if (db == null) return;

      final bookNum = int.parse(widget.book_num.toString());
      final rows = await db.rawQuery(
        "SELECT * FROM verse WHERE book_num = ?",
        [bookNum],
      );

      if (!mounted) return;
      setState(() {
        _chapterNumIsZeroBased = null;
        selectedVersesContent = rows
            .map<VerseBookContentModel>(
                (e) => VerseBookContentModel.fromJson(e))
            .toList();
      });
    } catch (e) {
      debugPrint('ChapterListScreen load error: $e');
    } finally {
      if (mounted) {
        setState(() => loader = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterCount =
        math.max(0, int.tryParse(widget.chapterCount.toString()) ?? 0);

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
          child: loader == false
              ? const Center(
                  child: Loader(),
                )
              : chapterCount == 0
                  ? Center(
                      child: Text(
                        'No chapters available',
                        style: CommanStyle.bw16500(context),
                      ),
                    )
                  : ListView(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  children: [
                    const SizedBox(
                      height: 10,
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
                              size: 20,
                              color: CommanColor.whiteBlack(context),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Text("Chapter",
                              style: CommanStyle.appBarStyle(context)),
                        ),
                        const SizedBox()
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: chapterCount,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 2 / 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10,
                      ),
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final isChapterRead = _isUiChapterRead(index);
                        final isSelected = selectedChapter == index;
                        final progressColor =
                            CommanColor.progressFillColor(context);
                        final trackColor =
                            CommanColor.progressUnFillColor(context);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedChapter = index;
                              selectedChangeChapter = index;
                              SharPreferences.setString(
                                  SharPreferences.selectedChapter,
                                  "${index + 1}");
                              // Future.delayed(Duration.zero,() {
                              //   DashBoardController().getSelectedChapterAndBook();
                              //   DashBoardController().getFont();
                              //   DashBoardController().loadApi();
                              // },);

                              //Navigator.of(context).push(CustomPageRoute(child: HomeScreen(), direction:AxisDirection.left));
                              Get.offAll(
                                  () => HomeScreen(
                                      From: "Chapter",
                                      selectedVerseNumForRead: "",
                                      selectedBookForRead: "",
                                      selectedChapterForRead: "",
                                      selectedBookNameForRead: "",
                                      selectedVerseForRead: ""),
                                  transition: Transition.fadeIn,
                                  duration: Duration(milliseconds: 300));
                            });
                            // Navigator.of(context).pushAndRemoveUntil(
                            //     MaterialPageRoute(
                            //         builder: (c) => HomeScreen(
                            //             From: "Chapter",
                            //             selectedVerseNumForRead: "",
                            //             selectedBookForRead: "",
                            //             selectedChapterForRead: "",
                            //             selectedBookNameForRead: "",
                            //             selectedVerseForRead: "")),
                            //     (v) => true);
                          },
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: isChapterRead
                                  ? progressColor.withOpacity(0.28)
                                  : (isSelected
                                      ? trackColor.withOpacity(0.35)
                                      : Colors.transparent),
                              border: Border.all(
                                width: isSelected ? 2 : 1.5,
                                color: isChapterRead
                                    ? progressColor
                                    : (isSelected
                                        ? CommanColor
                                            .inDarkWhiteAndInLightPrimary(
                                                context)
                                        : CommanColor.whiteBlack(context)),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isChapterRead
                                      ? progressColor
                                      : CommanColor.whiteBlack(context),
                                  fontWeight: isSelected || isChapterRead
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: BibleInfo.fontSizeScale * 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  ],
                )),
    );
  }
}
