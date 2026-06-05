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
import '../../constants/share_preferences.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  var testament_num = BibleInfo.old_testament_count;
  TabController? tabController;
  List<MainBookListModel> bookList = [];
  List<MainBookListModel> newTestmentBookList = [];
  // final  newTestmentBookList = <MainBookListModel>[].obs ;
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

  readBookJson() {
    DBHelper().db.then((value) {
      value!.rawQuery("SELECT * From book").then((bookResponse) {
        setState(() {
          bookList = bookResponse
              .map<MainBookListModel>((e) => MainBookListModel.fromJson(e))
              .toList();
          for (var i = testament_num; i < bookList.length; i++) {
            setState(() {
              newTestmentBookList.add(bookList[i]);
            });
          }
          loader = true;
        });
        // for (var i in bookResponse) {
        //   setState(() {
        //     // bookList.add(
        //     //     MainBookListModel(
        //     //       id: int.parse("${i["id"]}") ,
        //     //       bookNum: num.parse("${i["book_num"]}"),
        //     //       chapterCount: num.parse("${i["chapter_count"]}"),
        //     //       title: "${i["title"]}",
        //     //       shortTitle: "${i["short_title"]}",
        //     //       readPer: "${i["read_per"]}",
        //     //     ));
        //   });
        //
        // }
      });
    }).whenComplete(() {});
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
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");
    return Scaffold(
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
                              controller: tabController,
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
                              controller: tabController,
                              children: [
                                ListView.builder(
                                  itemCount: testament_num,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  physics: ScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    var data = bookList[index];
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
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  physics: ScrollPhysics(),
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
