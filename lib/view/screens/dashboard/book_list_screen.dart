import 'dart:convert';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/chapterListScreen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../Model/mainBookListModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/images.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/share_preferences.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  var testament_num = BibleInfo.old_testament_count;
  List<MainBookListModel> bookList = [];
  List<MainBookListModel> newTestmentBookList = [];
  bool loader = false;
  Future<void> _openChapterListForBook(MainBookListModel data) async {
    await SharPreferences.setString('OpenAd', '1');
    final previousBookNum =
        await SharPreferences.getString(SharPreferences.selectedBookNum);
    final savedChapter =
        await SharPreferences.getString(SharPreferences.selectedChapter);

    await SharPreferences.setString(
        SharPreferences.selectedBookNum, data.bookNum.toString());
    await SharPreferences.setString(
        SharPreferences.selectedBook, data.title.toString());

    final sameBook = previousBookNum == data.bookNum.toString();
    final chapterArg =
        sameBook ? (int.tryParse(savedChapter ?? '') ?? 1) : 1;

    Get.to(
      () => ChapterListScreen(
        chapterCount: data.chapterCount,
        book_num: data.bookNum,
        selectedChapter: chapterArg,
      ),
      transition: Transition.cupertinoDialog,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _splitTestaments() {
    // Additive: Catholic has more OT books (Mateus starts at 46, not 39).
    testament_num = BibleInfo.resolveOldTestamentCount(bookList);
    BibleInfo.old_testament_count = testament_num;
    newTestmentBookList.clear();
    for (final book in bookList) {
      if ((book.bookNum ?? 0) >= testament_num) {
        newTestmentBookList.add(book);
      }
    }
  }

  List<MainBookListModel> get _oldTestamentBooks => bookList
      .where((book) => (book.bookNum ?? 0) < testament_num)
      .toList();

  Future<void> _loadBooksFromDatabase() async {
    final db = await DBHelper().db;
    if (db == null) return;

    final bookResponse =
        await db.rawQuery("SELECT * FROM book ORDER BY book_num");
    if (!mounted) return;

    bookList = bookResponse
        .map<MainBookListModel>((e) => MainBookListModel.fromJson(e))
        .toList();
    _splitTestaments();
  }

  Future<void> _loadBooksFromCache() async {
    if (bookList.isNotEmpty) return;

    try {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      if (downloadProvider.bookList.isNotEmpty) {
        bookList = List<MainBookListModel>.from(downloadProvider.bookList);
        _splitTestaments();
        return;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final allBookJson = prefs.getString('bookList');
    if (allBookJson != null && allBookJson.isNotEmpty) {
      bookList = (jsonDecode(allBookJson) as List)
          .map((e) => MainBookListModel.fromJson(e))
          .toList();
      _splitTestaments();
    }
  }

  Future<void> readBookJson() async {
    try {
      for (var attempt = 0; attempt < 3 && bookList.isEmpty; attempt++) {
        if (attempt > 0) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
        await _loadBooksFromDatabase();
      }
      if (bookList.isEmpty) {
        await _loadBooksFromCache();
      }
    } catch (e) {
      debugPrint('BookListScreen load error: $e');
      if (bookList.isEmpty) {
        await _loadBooksFromCache();
      }
    } finally {
      if (mounted) {
        setState(() => loader = true);
      }
    }
  }

  // Future<void> filterBookList() async{
  //
  //   Future.delayed(Duration(milliseconds: 500),() {
  //     for (var i = 39 ; i<bookList.length;i++){
  //      setState(() {
  //        newTestmentBookList.add(bookList[i]);
  //      });
  //     }
  //   },).then((value) {
  //     loader = true;
  //   });
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readBookJson();
  }

  @override
  void activate() {
    super.activate();
    readBookJson();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final oldTestamentCount = _oldTestamentBooks.length;
    debugPrint("sz current width - $screenWidth ");
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
      appBar: AppBar(
        toolbarHeight: 50,
        flexibleSpace: Container(
          decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                  AppCustomTheme.vintage
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Images.bgImage((context))),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        backgroundColor: Colors.transparent,
        leadingWidth: 28,
        leading: InkWell(
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
        title: IntrinsicWidth(
          child: Text("Book",
              style: CommanStyle.appBarStyle(context).copyWith(
                  fontSize: screenWidth > 450
                      ? BibleInfo.fontSizeScale * 30
                      : BibleInfo.fontSizeScale * 18,
                  fontWeight: FontWeight.w400)),
        ),
        centerTitle: true,
        elevation: 0,
      ),
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
            ? Center(
                child: Loader(),
              )
            : bookList.isEmpty
                ? Center(
                    child: Text(
                      'No books available',
                      style: CommanStyle.bw16500(context),
                    ),
                  )
                : Column(
                children: [
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      animationDuration: Duration(milliseconds: 200),
                      initialIndex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            // color: Colors.black12,
                            color: CommanColor.white,
                            height: screenWidth > 450 ? 55 : 45,
                            child: TabBar(
                              isScrollable: false,
                              indicatorWeight: 0,
                              padding: EdgeInsets.zero,
                              indicatorPadding: EdgeInsets.zero,
                              labelPadding: EdgeInsets.zero,
                              indicatorSize: TabBarIndicatorSize.label,
                              unselectedLabelStyle:
                                  CommanStyle.darkPrimary16600,
                              labelStyle: CommanStyle.grey16600,
                              labelColor: CommanColor.darkPrimaryColor,
                              unselectedLabelColor: CommanColor.lightGrey,
                              indicator: UnderlineTabIndicator(
                                  borderRadius: BorderRadius.circular(1),
                                  borderSide: BorderSide(
                                      color: CommanColor.darkPrimaryColor,
                                      width: 2.5)),
                              tabs: <Widget>[
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15.0, vertical: 7.0),
                                    child: Text(
                                      'Old Testament',
                                      style: TextStyle(
                                          fontSize: screenWidth > 450
                                              ? BibleInfo.fontSizeScale * 25
                                              : BibleInfo.fontSizeScale * 18),
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15.0, vertical: 7.0),
                                    child: Text(
                                      'New Testament',
                                      style: TextStyle(
                                          fontSize: screenWidth > 450
                                              ? BibleInfo.fontSizeScale * 25
                                              : BibleInfo.fontSizeScale * 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: TabBarView(
                              children: [
                                ListView.builder(
                                  itemCount: oldTestamentCount,
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  cacheExtent: 400,
                                  addAutomaticKeepAlives: false,
                                  itemBuilder: (context, index) {
                                    if (index >= _oldTestamentBooks.length) {
                                      return const SizedBox.shrink();
                                    }
                                    var data = _oldTestamentBooks[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0, bottom: 2),
                                      child: InkWell(
                                        onTap: () => _openChapterListForBook(data),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${data.title}",
                                              style: CommanStyle.bw16500(
                                                      context)
                                                  .copyWith(
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              23
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                              16),
                                            ),
                                            Spacer(),
                                            SizedBox(
                                              width:
                                                  screenWidth > 450 ? 90 : 80,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    height: screenWidth > 450
                                                        ? 50
                                                        : 30,
                                                    width: screenWidth > 450
                                                        ? 50
                                                        : 30,
                                                    child:
                                                        CircularPercentIndicator(
                                                      radius: screenWidth > 450
                                                          ? 25
                                                          : 14.0,
                                                      lineWidth:
                                                          screenWidth > 450
                                                              ? 3
                                                              : 2.5,
                                                      animationDuration: 500,
                                                      percent: (double.parse(data
                                                                  .readPer!) /
                                                              100)
                                                          .clamp(0.0, 1.0),
                                                      animation: true,
                                                      progressColor: CommanColor
                                                          .progressFillColor(
                                                              context),
                                                      backgroundColor: CommanColor
                                                          .progressUnFillColor(
                                                              context),
                                                      center: Text(
                                                        "${(double.parse(data.readPer!) >= 99.9 ? 100 : double.parse(data.readPer!).toInt())} %",
                                                        style: TextStyle(
                                                            letterSpacing:
                                                                BibleInfo
                                                                    .letterSpacing,
                                                            fontSize: screenWidth >
                                                                    450
                                                                ? BibleInfo
                                                                        .fontSizeScale *
                                                                    9
                                                                : BibleInfo
                                                                        .fontSizeScale *
                                                                    6,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${data.chapterCount}",
                                                    style: CommanStyle.bw16500(
                                                            context)
                                                        .copyWith(
                                                            fontSize: screenWidth >
                                                                    450
                                                                ? BibleInfo
                                                                        .fontSizeScale *
                                                                    20
                                                                : BibleInfo
                                                                        .fontSizeScale *
                                                                    16),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ListView.builder(
                                  itemCount: newTestmentBookList.length,
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  cacheExtent: 400,
                                  addAutomaticKeepAlives: false,
                                  itemBuilder: (context, index) {
                                    var data = newTestmentBookList[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: InkWell(
                                        onTap: () => _openChapterListForBook(data),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${data.title}",
                                              style: CommanStyle.bw16500(
                                                      context)
                                                  .copyWith(
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              23
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                              16),
                                            ),
                                            Spacer(),
                                            SizedBox(
                                              width:
                                                  screenWidth > 450 ? 90 : 80,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    height: screenWidth > 450
                                                        ? 50
                                                        : 30,
                                                    width: screenWidth > 450
                                                        ? 50
                                                        : 30,
                                                    child:
                                                        CircularPercentIndicator(
                                                      radius: screenWidth > 450
                                                          ? 25
                                                          : 14.0,
                                                      lineWidth:
                                                          screenWidth > 450
                                                              ? 3
                                                              : 2.5,
                                                      percent: (double.parse(data
                                                                  .readPer!) /
                                                              100)
                                                          .clamp(0.0, 1.0),
                                                      animation: true,
                                                      progressColor: CommanColor
                                                          .progressFillColor(
                                                              context),
                                                      backgroundColor: CommanColor
                                                          .progressUnFillColor(
                                                              context),
                                                      center: Text(
                                                        "${(double.parse(data.readPer!) >= 99.9 ? 100 : double.parse(data.readPer!).toInt())} %",
                                                        style: TextStyle(
                                                            letterSpacing:
                                                                BibleInfo
                                                                    .letterSpacing,
                                                            fontSize: screenWidth >
                                                                    450
                                                                ? BibleInfo
                                                                        .fontSizeScale *
                                                                    9
                                                                : BibleInfo
                                                                        .fontSizeScale *
                                                                    6,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${data.chapterCount}",
                                                    style: CommanStyle.bw16500(
                                                            context)
                                                        .copyWith(
                                                            fontSize: screenWidth >
                                                                    450
                                                                ? BibleInfo
                                                                        .fontSizeScale *
                                                                    20
                                                                : BibleInfo
                                                                        .fontSizeScale *
                                                                    16),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // employee_profile(),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
