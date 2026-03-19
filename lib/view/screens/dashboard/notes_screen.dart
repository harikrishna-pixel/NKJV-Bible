import 'dart:io';

import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:html/parser.dart' as html;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controller/dpProvider.dart';
import '../../constants/colors.dart';
import '../../constants/constant.dart';
import '../../constants/images.dart';
import '../../constants/share_preferences.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<SaveNotesModel>> saveNotesData;
  double fontSize = Sizecf.scrnWidth! > 450 ? 25.0 : 15.0;
  var fontSizeS = "";
  var selectedFontFamily = "";
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
    // TODO: implement initState
    super.initState();
    getFont();
    loadData();
  }

  loadData() async {
    await DBMigrationHelper.tryRestoreLibraryDataFromLegacy();
    if (!mounted) return;
    setState(() {
      saveNotesData = DBHelper().getNotes();
    });
    print(saveNotesData);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
          future: saveNotesData,
          builder: (context, AsyncSnapshot<List<SaveNotesModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.data!.isNotEmpty) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data?.length ?? 0,
                padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                physics: const ScrollPhysics(),
                itemBuilder: (context, index) {
                  var data = snapshot.data?[index];
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.only(right: 2.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () {
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
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                        "${data.bookName} ${data.chapterNum}:${data.verseNum}",
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: CommanStyle
                                                            .black15400),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              await Clipboard.setData(
                                                                  ClipboardData(
                                                                      text:
                                                                          "${parse(data.content).body?.text}\n${data.bookName} ${data.chapterNum}:${data.verseNum}"));
                                                              Constants
                                                                  .showToast(
                                                                      "Copied");
                                                            },
                                                            child: Container(
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
                                                      width: 30,
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
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
                                                      width: 30,
                                                    ),
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
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
                                                              //       "${parse(data.content).body?.text}  \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                              // } else if (Platform
                                                              //     .isIOS) {
                                                              //   message =
                                                              //       "${parse(data.content).body?.text}  \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
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
                                                      onTap: () {
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
                                                          duration: const Duration(
                                                              milliseconds: 300),
                                                        );
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets
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
                                                                                style: TextStyle(color: CommanColor.black, fontWeight: FontWeight.w400, letterSpacing: BibleInfo.letterSpacing, fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14),
                                                                              ))),
                                                                          const SizedBox(
                                                                            width:
                                                                                4,
                                                                          ),
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              debugPrint(" check note -  ${data.plaincontent.toString()}  ");
                                                                              await DBHelper().updateVersesData(
                                                                                int.parse(data.plaincontent.toString()),
                                                                                "is_noted",
                                                                                "no",
                                                                              );
                                                                              // await DBHelper().updateVersesData(int.parse(data.plaincontent.toString()), "is_noted", "no");
                                                                              // await DBHelper().updateVersesDataByContent(data.content.toString(), "is_noted", "no");
                                                                              await DBHelper().deleteNotes(data.id!.toInt()).then((value) {
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
                                                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: BibleInfo.letterSpacing, fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14),
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
                                                  ],
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: HtmlWidget(
                                      data!.content.toString(),
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
                                  Text(
                                      "${data.bookName} ${data.chapterNum}:${data.verseNum}",
                                      style: CommanStyle.bw14500(context)),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        '''Notes : ${data.notes}''',
                                        style: CommanStyle.bw14400(context),
                                        textAlign: TextAlign.start,
                                      )),
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
                                onTap: () {
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
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
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    InkWell(
                                                        onTap: () async {
                                                          await Clipboard.setData(
                                                              ClipboardData(
                                                                  text:
                                                                      "${parse(data.content).body?.text}\n${data.bookName} ${data.chapterNum}:${data.verseNum}"));
                                                          Constants.showToast(
                                                              "Copied");
                                                        },
                                                        child: Container(
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
                                                  width: 30,
                                                ),
                                                InkWell(
                                                  onTap: () async {
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
                                                          //       "${parse(data.content).body?.text}  \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                          // } else if (Platform
                                                          //     .isIOS) {
                                                          //   message =
                                                          //       "${parse(data.content).body?.text}  \n${data.bookName} ${data.chapterNum}:${data.verseNum} \nYou can read more at App \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
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
                                                  onTap: () {
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
                                                          'book': data.bookName
                                                              .toString(),
                                                          'chapter':
                                                              '${int.parse(data.chapterNum.toString()) + 1}',
                                                          'verse':
                                                              '${int.parse(data.verseNum.toString()) + 1}',
                                                        },
                                                      ),
                                                      transition: Transition
                                                          .cupertinoDialog,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                    );
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets
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
                                                                        left:
                                                                            12,
                                                                        right:
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
                                                                            style: TextStyle(
                                                                                color: CommanColor.black,
                                                                                fontWeight: FontWeight.w400,
                                                                                letterSpacing: BibleInfo.letterSpacing,
                                                                                fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14),
                                                                          ))),
                                                                      const SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          debugPrint(
                                                                              " check note -  ${data.plaincontent.toString()}  ");
                                                                          await DBHelper().updateVersesData(
                                                                              int.parse(data.plaincontent.toString()),
                                                                              "is_noted",
                                                                              "no");
                                                                          // DBHelper().updateVersesDataByContent(
                                                                          //     data.content.toString(),
                                                                          //     "is_noted",
                                                                          //     "no");
                                                                          DBHelper()
                                                                              .deleteNotes(data.id!.toInt())
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
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w400,
                                                                              letterSpacing: BibleInfo.letterSpacing,
                                                                              fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 19 : BibleInfo.fontSizeScale * 14),
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
                                            )
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
                          ))
                    ],
                  );
                },
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Images.notesPlaceHolder(context),
                        height: 80, width: 80,color: Colors.transparent.withOpacity(0.3),),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "No relevant content",
                        style: CommanStyle.placeholderText(context),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      InkWell(
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                          Get.offAll(
                              () => HomeScreen(
                                  From: "Go to Read",
                                  selectedVerseNumForRead: "",
                                  selectedBookForRead: "",
                                  selectedChapterForRead: "",
                                  selectedBookNameForRead: "",
                                  selectedVerseForRead: ""),
                              transition: Transition.cupertinoDialog,
                              duration: const Duration(milliseconds: 300));
                        },
                        child: Column(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: CommanColor.lightDarkPrimary300(
                                            context),
                                        width: 1.2),
                                    borderRadius: BorderRadius.circular(3)),
                                child: Image.asset(
                                  "assets/reading_book.png",
                                  height: 25,
                                  width: 15,
                                  color:
                                      CommanColor.lightDarkPrimary300(context),
                                )),
                            const SizedBox(
                              height: 15,
                            ),
                            Text("Go to Read",
                                style: CommanStyle.placeholderText(context)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ],
              );
            }
          }),
    );
  }
}
