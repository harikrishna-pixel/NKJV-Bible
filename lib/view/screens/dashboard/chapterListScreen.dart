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
  // var allChapterlist = {};
  @override
  void initState() {
    super.initState();
    loadChapter();
    selectedChapter = int.parse(widget.selectedChapter.toString()) - 1;
  }

  loadChapter() {
    DBHelper().db.then((value) {
      value!
          .rawQuery(
              "SELECT * From verse WHERE book_num ='${int.parse(widget.book_num.toString())}'")
          .then((value) {
        setState(() {
          selectedVersesContent = value
              .map<VerseBookContentModel>(
                  (e) => VerseBookContentModel.fromJson(e))
              .toList();
          loader = true;
        });

        // for (var i in value) {
        //   setState(() {
        //     selectedVersesContent.add(
        //         VerseBookContentModel(
        //           id: int.parse("${i["id"]}") ,
        //           bookNum: num.parse("${i["book_num"]}"),
        //           chapterNum: num.parse("${i["chapter_num"]}"),
        //           verseNum:num.parse("${i["verse_num"]}"),
        //           content: "${i["content"]}",
        //           isBookmarked:"${i["is_bookmarked"]}",
        //           isHighlighted: "${i["is_highlighted"]}",
        //           isNoted: "${i["is_noted"]}",
        //           isUnderlined: "${i["is_underlined"]}",
        //           isRead: "${i["is_read"]}",
        //         ));
        //   });
        // }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      itemCount: int.parse(widget.chapterCount.toString()),
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
                        var chapterRead = 'no';
                        for (var i = 0; i < selectedVersesContent.length; i++) {
                          if (index == selectedVersesContent[i].chapterNum) {
                            chapterRead =
                                selectedVersesContent[i].isRead.toString();
                            break;
                          }
                        }
                        final isChapterRead = chapterRead != 'no';
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
