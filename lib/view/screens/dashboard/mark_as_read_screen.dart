import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkAsReadScreen extends StatefulWidget {
  String RededBookName;
  String ReadedChapter;
  String SelectedBookChapterCount;
  MarkAsReadScreen(
      {super.key,
      required this.ReadedChapter,
      required this.RededBookName,
      required this.SelectedBookChapterCount});

  @override
  State<MarkAsReadScreen> createState() => _MarkAsReadScreenState();
}

class _MarkAsReadScreenState extends State<MarkAsReadScreen> {
  String _currentMessage = "";

  @override
  void initState() {
    super.initState();
    _loadRotatingMessage();
  }

  Future<void> _loadRotatingMessage() async {
    final List<String> markAsReadMessages = [
      "Well done. Keep walking in His Word!",
      "You're growing closer through Scripture!",
      "God's Word is shaping your life!",
      "A faithful step today. Go ahead!",
    ];
    final prefs = await SharedPreferences.getInstance();
    int messageIndex =
        prefs.getInt(SharPreferences.markAsReadMessageIndex) ?? 0;
    if (messageIndex >= markAsReadMessages.length) {
      messageIndex = 0;
    }
    if (mounted) {
      setState(() {
        _currentMessage = markAsReadMessages[messageIndex];
      });
    }
    final nextIndex = (messageIndex + 1) % markAsReadMessages.length;
    await SharPreferences.setInt(
        SharPreferences.markAsReadMessageIndex, nextIndex);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                    Provider.of<DownloadProvider>(context, listen: false)
                        .incrementBookmarkCount(context);
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
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            // Stack(
            //   children: [
            //     SizedBox(
            //         height: 120,
            //         child: Image(
            //           image: AssetImage("assets/tick.png"),
            //           fit: BoxFit.fill,
            //           color: CommanColor.lightDarkPrimary(context),
            //         )),
            //     Positioned(
            //         left: 30,
            //         right: 30,
            //         top: 30,
            //         bottom: 30,
            //         child: Container(
            //           decoration: BoxDecoration(
            //             color: CommanColor.lightDarkPrimary(context),
            //             image: DecorationImage(
            //                 image: AssetImage("assets/whitetick.png"),
            //                 fit: BoxFit.fill),
            //           ),
            //         )),
            //   ],
            // ),
            SizedBox(
                height: 120,
                child: Provider.of<ThemeProvider>(context).themeMode ==
                        ThemeMode.dark
                    ? Image(
                        image: AssetImage("assets/whitetick2.png"),
                        fit: BoxFit.contain,
                        // color: CommanColor.lightDarkPrimary(context),
                      )
                    : Image(
                        image: AssetImage("assets/tick.png"),
                        fit: BoxFit.contain,
                        // color: CommanColor.lightDarkPrimary(context),
                      )),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: Text(
                "Successful",
                style: CommanStyle.bw20500(context),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                _currentMessage.isEmpty ? "Loading..." : _currentMessage,
                style: CommanStyle.bw18400(context),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                widget.RededBookName,
                style: CommanStyle.bw22500(context),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                "Ch ${widget.ReadedChapter}",
                style: CommanStyle.bw20500(context),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                DateFormat("dd/MM/yyyy").format(DateTime.now()),
                style: CommanStyle.bw22500(context),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
            ),
            InkWell(
              onTap: () async {
                debugPrint('ReadedChapter : ${widget.ReadedChapter}');
                debugPrint(
                    'SelectedBookChapterCount : ${widget.SelectedBookChapterCount}');
                if (int.parse(widget.ReadedChapter) + 1 <=
                    int.parse(
                        "${int.parse(widget.SelectedBookChapterCount)}")) {
                  // Next Chapter
                  SharPreferences.setString(SharPreferences.selectedChapter,
                      (int.parse(widget.ReadedChapter) + 1).toString());
                  debugPrint('Get off All');
                  await SharPreferences.setString('OpenAd', '1');
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
                  Provider.of<DownloadProvider>(context, listen: false)
                      .incrementBookmarkCount(context);
                } else {
                  // Next Book - Get the next book and navigate to first chapter
                  try {
                    // Get current book number from SharedPreferences
                    final currentBookNumStr = await SharPreferences.getString(
                            SharPreferences.selectedBookNum) ??
                        "0";
                    final currentBookNum = int.parse(currentBookNumStr);

                    // Get next book from database
                    final db = await DBHelper().db;
                    if (db != null) {
                      final nextBookNum = currentBookNum + 1;
                      final result = await db.rawQuery(
                          "SELECT * FROM book WHERE book_num = $nextBookNum LIMIT 1");

                      if (result.isNotEmpty) {
                        final nextBook = MainBookListModel.fromJson(result[0]);
                        final nextBookNumValue = nextBook.bookNum!.toInt();
                        final nextBookName = nextBook.title ?? "";
                        final nextBookChapterCount =
                            nextBook.chapterCount!.toInt();

                        // Update SharedPreferences for next book and first chapter
                        await SharPreferences.setString(
                            SharPreferences.selectedBook, nextBookName);
                        await SharPreferences.setString(
                            SharPreferences.selectedChapter, "1");
                        await SharPreferences.setString(
                            SharPreferences.selectedBookNum,
                            nextBookNumValue.toString());

                        // Update controller if available
                        try {
                          final controller = Get.find<DashBoardController>();
                          controller.selectedBook.value = nextBookName;
                          controller.selectedBookNum.value =
                              nextBookNumValue.toString();
                          controller.selectedChapter.value = "1";
                          controller.selectChapterChange.value = 1;
                          controller.selectedBookChapterCount.value =
                              nextBookChapterCount.toString();
                          controller.selectedBookNameForRead.value =
                              nextBookName;
                          controller.selectedBookNumForRead.value =
                              nextBookNumValue.toString();
                          controller.selectedChapterForRead.value = "1";

                          // Load content
                          controller.getSelectedChapterAndBook();
                          controller.getBookContentForRead();
                        } catch (e) {
                          debugPrint("DashBoardController not available: $e");
                          // Controller will be initialized when HomeScreen loads
                        }

                        // Navigate to reading screen
                        await SharPreferences.setString('OpenAd', '1');
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
                        Provider.of<DownloadProvider>(context, listen: false)
                            .incrementBookmarkCount(context);
                      } else {
                        // No next book found
                        Constants.showToast(
                            "Selected Book is completed. Please change the book.");
                      }
                    } else {
                      Constants.showToast(
                          "Selected Book is completed. Please change the book.");
                    }
                  } catch (e) {
                    debugPrint("Error getting next book: $e");
                    Constants.showToast(
                        "Selected Book is completed. Please change the book.");
                  }
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.07,
                decoration: BoxDecoration(
                  color: Provider.of<ThemeProvider>(context).themeMode ==
                          ThemeMode.dark
                      ? CommanColor.white
                      : CommanColor.darkPrimaryColor,
                  border: Border.all(color: Colors.transparent, width: 1.5),
                  borderRadius: BorderRadiusDirectional.circular(50),
                ),
                child: Center(
                    child: int.parse(widget.ReadedChapter) + 1 <=
                            int.parse(
                                "${int.parse(widget.SelectedBookChapterCount)}")
                        ? Text(
                            "Next Chapter",
                            style:
                                Provider.of<ThemeProvider>(context).themeMode !=
                                        ThemeMode.dark
                                    ? CommanStyle.white18400
                                    : CommanStyle.white18400.copyWith(
                                        color: CommanColor.lightModePrimary),
                          )
                        : Text(
                            "Next Book",
                            style:
                                Provider.of<ThemeProvider>(context).themeMode !=
                                        ThemeMode.dark
                                    ? CommanStyle.white18400
                                    : CommanStyle.white18400.copyWith(
                                        color: CommanColor.lightModePrimary),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
