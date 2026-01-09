import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:biblebookapp/Model/bookoffer_model.dart';
import 'package:biblebookapp/Model/highLightContentModal.dart';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/bottom.notifier.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/utils/rating_dialog_helper.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Model/bookMarkModel.dart';
import '../../Model/saveImagesModel.dart';
import '../../Model/saveNotesModel.dart';
import '../../Model/verseBookContentModel.dart';
import '../constants/colors.dart';
import 'package:screenshot/screenshot.dart';
import '../constants/theme_provider.dart';
import '../screens/intro_subcribtion_screen.dart';
import '../screens/chat/chat_screen.dart';

// Future<dynamic> homeContentEditBottomSheet(BuildContext context,
//     {String? verNum,
//     VerseBookContentModel? verseBookdata,
//     required Function(DashBoardController) loadInterstitial,
//     int? selectedColor,
//     DashBoardController? controller,
//     Function? callback,
//     Function? callback2,
//     int? clickcount}) async {
//   double screenWidth = MediaQuery.of(context).size.width;
//   debugPrint("sz current width - $screenWidth ");
//   for (var i = 0; i < controller!.colors.value.length; i++) {
//     if (verseBookdata!.isHighlighted ==
//         controller.colors.value[i]
//             .toString()
//             .split("(")
//             .last
//             .split(")")
//             .first) {
//       controller.colorsCheack.value = i;
//     }
//   }
//   controller.selectedColorOrNot.value = verseBookdata!.isHighlighted.toString();

//   bool isBookmarked = verseBookdata.isBookmarked == "yes";
//   bool isunderlined = verseBookdata.isUnderlined == "yes";

//   late int adcountview;

//   Color? selectedColor;

//   int? selectedindex;

//   final countprovider = Provider.of<DownloadProvider>(context, listen: false);

//   await Get.bottomSheet(
//     barrierColor: Colors.black12,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(15), topRight: Radius.circular(15)),
//     ),
//     enableDrag: true,
//     StatefulBuilder(builder: (context, setState) {
//       return Obx(
//         () => Container(
//             height: MediaQuery.of(context).size.height * 0.4,
//             decoration: const BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20)),
//                 color: Colors.white),
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 15),
//                   Container(
//                     height: 3,
//                     width: 45,
//                     decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(3),
//                         color: CommanColor.lightDarkPrimary(context)),
//                   ),
//                   const SizedBox(height: 25),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         "${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum",
//                         style: TextStyle(
//                             color: CommanColor.lightDarkPrimary(context),
//                             letterSpacing: BibleInfo.letterSpacing,
//                             fontSize:
//                                 BibleInfo.fontSizeScale * screenWidth > 450
//                                     ? 25
//                                     : 14,
//                             fontWeight: FontWeight.w600),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 25),
//                   SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.75,
//                     child: Row(
//                       mainAxisAlignment: screenWidth > 450
//                           ? MainAxisAlignment.center
//                           : MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           children: [
//                             StatefulBuilder(builder:
//                                 (BuildContext context, StateSetter setState) {
//                               return GestureDetector(
//                                 onTap: () async {
//                                   DebugConsole.log("bookmark started");
//                                   // try {
//                                   await SharPreferences.setString(
//                                       'OpenAd', '1');

//                                   await countprovider.decrementCount(context);
//                                   var isCurrentlyBookmarked =
//                                       verseBookdata.isBookmarked == "yes";

//                                   var data = VerseBookContentModel(
//                                     id: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .id,
//                                     bookNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .bookNum,
//                                     chapterNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .chapterNum,
//                                     verseNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .verseNum,
//                                     content: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .content,
//                                     isBookmarked:
//                                         isCurrentlyBookmarked ? "no" : "yes",
//                                     isHighlighted: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .isHighlighted,
//                                     isNoted: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .isNoted,
//                                     isUnderlined: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .isUnderlined,
//                                     isRead: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .isRead,
//                                   );
//                                   DebugConsole.log("bookmark step 1");
//                                   controller.selectedBookContent[
//                                       int.parse(verNum.toString()) - 1] = data;

//                                   if (isCurrentlyBookmarked) {
//                                     DebugConsole.log("bookmark rm step 1");
//                                     await DBHelper().updateVersesData(
//                                         int.parse(verseBookdata.id.toString()),
//                                         "is_bookmarked",
//                                         "no");
//                                     DebugConsole.log("bookmark rm step 1.5");
//                                     await DBHelper().deleteBookmarkByContent(
//                                         controller.printText.value.toString());
//                                     // Get.back();
//                                     isBookmarked = false;
//                                     DebugConsole.log("bookmark rm step 2");
//                                     if (context.mounted) {
//                                       await SharPreferences.setString(
//                                           'OpenAd', '1');
//                                       DebugConsole.log("bookmark removed");
//                                       await Future.delayed(
//                                           Duration(milliseconds: 600));
//                                       return showDialog(
//                                           context: context,
//                                           builder: ((context) {
//                                             return AlertDialog(
//                                               content: SizedBox(
//                                                 width: 400,
//                                                 child: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     ///NEW AD BANNER
//                                                     (controller.popupBannerAd !=
//                                                                 null &&
//                                                             controller
//                                                                 .isPopupBannerAdLoaded
//                                                                 .value &&
//                                                             controller.adFree
//                                                                     .value ==
//                                                                 false)
//                                                         ? SizedBox(
//                                                             height: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .height
//                                                                 .toDouble(),
//                                                             width: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .width
//                                                                 .toDouble(),
//                                                             child: AdWidget(
//                                                                 ad: controller
//                                                                     .popupBannerAd!),
//                                                           )
//                                                         : SizedBox(
//                                                             height: 150,
//                                                             child: Image.asset(
//                                                               Images
//                                                                   .aboutPlaceHolder(
//                                                                       context),
//                                                               height: 150,
//                                                               width: 150,
//                                                               color:
//                                                                   Colors.brown,
//                                                             ),
//                                                           ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     const Divider(
//                                                       thickness: 2,
//                                                       color: Colors.brown,
//                                                     ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     const Text(
//                                                       "Removed Successfully!",
//                                                       style: TextStyle(
//                                                           letterSpacing:
//                                                               BibleInfo
//                                                                   .letterSpacing,
//                                                           fontSize: BibleInfo
//                                                                   .fontSizeScale *
//                                                               20,
//                                                           fontWeight:
//                                                               FontWeight.bold),
//                                                     ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     SizedBox(
//                                                       height: 40,
//                                                       width: 150,
//                                                       child: ElevatedButton(
//                                                           style: ButtonStyle(
//                                                             backgroundColor:
//                                                                 WidgetStateProperty.all<
//                                                                         Color>(
//                                                                     const Color
//                                                                         .fromARGB(
//                                                                         255,
//                                                                         220,
//                                                                         220,
//                                                                         220)),
//                                                             shape: WidgetStateProperty
//                                                                 .all<
//                                                                     RoundedRectangleBorder>(
//                                                               RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             8.0),
//                                                               ),
//                                                             ), // Add rounded corners
//                                                           ),
//                                                           onPressed: () async {
//                                                             await SharPreferences
//                                                                 .setString(
//                                                                     'OpenAd',
//                                                                     '1');
//                                                             Get.back();

//                                                             Provider.of<DownloadProvider>(
//                                                                     context,
//                                                                     listen:
//                                                                         false)
//                                                                 .incrementBookmarkCount(
//                                                                     context);
//                                                           },
//                                                           child: const Text(
//                                                             "Dismiss",
//                                                             style: TextStyle(
//                                                                 letterSpacing:
//                                                                     BibleInfo
//                                                                         .letterSpacing,
//                                                                 fontSize: BibleInfo
//                                                                         .fontSizeScale *
//                                                                     20,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black),
//                                                           )),
//                                                     )
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           }));
//                                     }
//                                   } else {
//                                     isBookmarked = true;
//                                     await DBHelper().updateVersesData(
//                                         int.parse(verseBookdata.id.toString()),
//                                         "is_bookmarked",
//                                         "yes");

//                                     DebugConsole.log("bookmark step 2.1");

//                                     await DBHelper()
//                                         .insertBookmark(
//                                       BookMarkModel(
//                                         bookNum: int.parse(controller
//                                             .selectedBookNum.value
//                                             .toString()),
//                                         chapterNum: int.parse(controller
//                                             .selectedChapter.value
//                                             .toString()),
//                                         content: controller.printText.value
//                                             .toString(),
//                                         plaincontent:
//                                             verseBookdata.id.toString(),
//                                         bookName: controller.selectedBook.value
//                                             .toString(),
//                                         timestamp: DateTime.now().toString(),
//                                         verseNum: int.parse(verNum.toString()),
//                                       ),
//                                     )
//                                         .catchError((e) {
//                                       DebugConsole.log(
//                                           "bookmark database error - $e");
//                                     });

//                                     DebugConsole.log("bookmark step 3");
//                                     Future.delayed(
//                                             const Duration(milliseconds: 400))
//                                         .then((value) async {
//                                       await SharPreferences.setString(
//                                           'OpenAd', '1');
//                                       DebugConsole.log("bookmarked !");
//                                       await Future.delayed(
//                                           Duration(milliseconds: 600));
//                                       if (context.mounted) {
//                                         return showDialog(
//                                             context: context,
//                                             builder: ((context) {
//                                               return AlertDialog(
//                                                 content: SizedBox(
//                                                   width: 400,
//                                                   child: Column(
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: [
//                                                       (controller.isPopupBannerAdLoaded
//                                                                   .value &&
//                                                               controller.adFree
//                                                                       .value ==
//                                                                   false)
//                                                           ? SizedBox(
//                                                               height: controller
//                                                                   .popupBannerAd
//                                                                   ?.size
//                                                                   .height
//                                                                   .toDouble(),
//                                                               width: controller
//                                                                   .popupBannerAd
//                                                                   ?.size
//                                                                   .width
//                                                                   .toDouble(),
//                                                               child: AdWidget(
//                                                                   ad: controller
//                                                                       .popupBannerAd!),
//                                                             )
//                                                           : SizedBox(
//                                                               height: 150,
//                                                               child:
//                                                                   Image.asset(
//                                                                 Images
//                                                                     .aboutPlaceHolder(
//                                                                         context),
//                                                                 height: 150,
//                                                                 width: 150,
//                                                                 color: Colors
//                                                                     .brown,
//                                                               ),
//                                                             ),
//                                                       const SizedBox(
//                                                         height: 20,
//                                                       ),
//                                                       const Divider(
//                                                         thickness: 2,
//                                                         color: Colors.brown,
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 20,
//                                                       ),
//                                                       const Text(
//                                                         "Marked Successfully!",
//                                                         style: TextStyle(
//                                                             letterSpacing:
//                                                                 BibleInfo
//                                                                     .letterSpacing,
//                                                             fontSize: BibleInfo
//                                                                     .fontSizeScale *
//                                                                 20,
//                                                             fontWeight:
//                                                                 FontWeight
//                                                                     .bold),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 20,
//                                                       ),
//                                                       SizedBox(
//                                                         height: 40,
//                                                         width: 150,
//                                                         child: ElevatedButton(
//                                                             style: ButtonStyle(
//                                                               backgroundColor:
//                                                                   WidgetStateProperty.all<
//                                                                           Color>(
//                                                                       const Color
//                                                                           .fromARGB(
//                                                                           255,
//                                                                           220,
//                                                                           220,
//                                                                           220)),
//                                                               shape: WidgetStateProperty
//                                                                   .all<
//                                                                       RoundedRectangleBorder>(
//                                                                 RoundedRectangleBorder(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               8.0),
//                                                                 ),
//                                                               ), // Add rounded corners
//                                                             ),
//                                                             onPressed:
//                                                                 () async {
//                                                               await SharPreferences
//                                                                   .setString(
//                                                                       'OpenAd',
//                                                                       '1');
//                                                               Get.back();

//                                                               Provider.of<DownloadProvider>(
//                                                                       context,
//                                                                       listen:
//                                                                           false)
//                                                                   .incrementBookmarkCount(
//                                                                       context);
//                                                             },
//                                                             child: const Text(
//                                                               "Dismiss",
//                                                               style: TextStyle(
//                                                                   letterSpacing:
//                                                                       BibleInfo
//                                                                           .letterSpacing,
//                                                                   fontSize:
//                                                                       BibleInfo
//                                                                               .fontSizeScale *
//                                                                           20,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   color: Colors
//                                                                       .black),
//                                                             )),
//                                                       )
//                                                     ],
//                                                   ),
//                                                 ),
//                                               );
//                                             }));
//                                       }
//                                     });
//                                   }
//                                 },
//                                 child: isBookmarked
//                                     ? Image.asset(
//                                         "assets/lightMode/icons/bookmark1.png",
//                                         height: screenWidth > 450 ? 60 : 50,
//                                         width: screenWidth > 450 ? 45 : 35,
//                                       )
//                                     : Image.asset(
//                                         "assets/lightMode/icons/bookmark.png",
//                                         height: screenWidth > 450 ? 60 : 50,
//                                         width: screenWidth > 450 ? 45 : 35,
//                                       ),
//                               );
//                             }),
//                             const SizedBox(height: 10),
//                             Text(
//                               "Bookmark",
//                               style: TextStyle(
//                                   letterSpacing: BibleInfo.letterSpacing,
//                                   fontSize:
//                                       BibleInfo.fontSizeScale * screenWidth >
//                                               450
//                                           ? 16
//                                           : 12,
//                                   fontWeight: FontWeight.bold,
//                                   color: CommanColor.lightDarkPrimary(context)),
//                             )
//                           ],
//                         ),
//                         screenWidth > 450
//                             ? const SizedBox(width: 20)
//                             : SizedBox(),
//                         GestureDetector(
//                           onTap: () async {
//                             await SharPreferences.setString('OpenAd', '1');
//                             if (controller
//                                     .selectedBookContent[
//                                         int.parse(verNum.toString()) - 1]
//                                     .isNoted !=
//                                 "no") {
//                               controller.notesController.value.text = controller
//                                   .selectedBookContent[
//                                       int.parse(verNum.toString()) - 1]
//                                   .isNoted
//                                   .toString();
//                             } else {
//                               controller.notesController.value.text = "";
//                             }

//                             return Get.bottomSheet(
//                               barrierColor: Colors.black12,
//                               shape: const RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.only(
//                                     topLeft: Radius.circular(15),
//                                     topRight: Radius.circular(15)),
//                               ),
//                               enableDrag: true,
//                               Container(
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.only(
//                                       topLeft: Radius.circular(20),
//                                       topRight: Radius.circular(20)),
//                                 ),
//                                 padding:
//                                     const EdgeInsets.symmetric(horizontal: 15),
//                                 child: SingleChildScrollView(
//                                   physics: const ScrollPhysics(),
//                                   child: Column(
//                                     children: [
//                                       const SizedBox(height: 15),
//                                       Container(
//                                         height: 3,
//                                         width: 45,
//                                         decoration: BoxDecoration(
//                                             borderRadius:
//                                                 BorderRadius.circular(3),
//                                             color: Provider.of<ThemeProvider>(
//                                                             context,
//                                                             listen: false)
//                                                         .themeMode ==
//                                                     ThemeMode.dark
//                                                 ? CommanColor.darkPrimaryColor
//                                                 : CommanColor.lightModePrimary),
//                                       ),
//                                       const SizedBox(height: 25),
//                                       Text(
//                                         controller.printText.value,
//                                         style: const TextStyle(
//                                             color: Colors.black,
//                                             letterSpacing:
//                                                 BibleInfo.letterSpacing,
//                                             fontSize:
//                                                 BibleInfo.fontSizeScale * 15,
//                                             fontWeight: FontWeight.w500),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.end,
//                                         children: [
//                                           Text(
//                                             "${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum",
//                                             style: const TextStyle(
//                                                 color: Colors.black,
//                                                 letterSpacing:
//                                                     BibleInfo.letterSpacing,
//                                                 fontSize:
//                                                     BibleInfo.fontSizeScale *
//                                                         12,
//                                                 fontWeight: FontWeight.w500),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 20),
//                                       TextFormField(
//                                         maxLines: 4,
//                                         textCapitalization:
//                                             TextCapitalization.sentences,
//                                         controller:
//                                             controller.notesController.value,
//                                         style: const TextStyle(
//                                             color: Colors.black87,
//                                             fontWeight: FontWeight.w500,
//                                             letterSpacing:
//                                                 BibleInfo.letterSpacing,
//                                             fontSize:
//                                                 BibleInfo.fontSizeScale * 14),
//                                         decoration: const InputDecoration(
//                                           focusedBorder: OutlineInputBorder(
//                                             borderSide: BorderSide(
//                                                 width: 1,
//                                                 color: CommanColor.lightGrey),
//                                           ),
//                                           errorBorder: OutlineInputBorder(
//                                             borderSide: BorderSide(
//                                                 width: 1,
//                                                 color: CommanColor.lightGrey),
//                                           ),
//                                           enabledBorder: OutlineInputBorder(
//                                             borderSide: BorderSide(
//                                                 width: 1,
//                                                 color: CommanColor.lightGrey),
//                                           ),
//                                           hintText: "Enter Notes",
//                                           hintStyle: CommanStyle.grey13400,
//                                           floatingLabelBehavior:
//                                               FloatingLabelBehavior.never,
//                                           contentPadding: EdgeInsets.only(
//                                               top: 8.0,
//                                               left: 14.0,
//                                               right: 14.0,
//                                               bottom: 8.0),
//                                           border: OutlineInputBorder(),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         height: 20,
//                                       ),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           SizedBox(
//                                             width: 100,
//                                             child: ElevatedButton(
//                                               onPressed: () async {
//                                                 await SharPreferences.setString(
//                                                     'OpenAd', '1');
//                                                 if (controller
//                                                         .selectedBookContent[
//                                                             int.parse(verNum
//                                                                     .toString()) -
//                                                                 1]
//                                                         .isNoted ==
//                                                     "no") {
//                                                   Get.back();
//                                                 } else {
//                                                   if (controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isNoted !=
//                                                       "no") {
//                                                     var data =
//                                                         VerseBookContentModel(
//                                                       id: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .id,
//                                                       bookNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .bookNum,
//                                                       chapterNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .chapterNum,
//                                                       verseNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .verseNum,
//                                                       content: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .content,
//                                                       isBookmarked: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isBookmarked,
//                                                       isHighlighted: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isHighlighted,
//                                                       isNoted: "no",
//                                                       isUnderlined: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isUnderlined,
//                                                       isRead: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isRead,
//                                                     );
//                                                     controller
//                                                         .selectedBookContent[int
//                                                             .parse(verNum
//                                                                 .toString()) -
//                                                         1] = data;

//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_bookmarked",
//                                                             "no");
//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_noted",
//                                                             "no");
//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_highlighted",
//                                                             "no");
//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_underlined",
//                                                             "no");
//                                                     await DBHelper()
//                                                         .deleteNotesByContent(
//                                                             controller
//                                                                 .printText.value
//                                                                 .toString());

//                                                     await Future.delayed(
//                                                         const Duration(
//                                                             milliseconds: 300),
//                                                         () async {
//                                                       Get.back();
//                                                       await SharPreferences
//                                                           .setString(
//                                                               'OpenAd', '1');
//                                                       await Future.delayed(
//                                                           Duration(
//                                                               milliseconds:
//                                                                   600));
//                                                       if (context.mounted) {
//                                                         return showDialog(
//                                                             context: context,
//                                                             builder:
//                                                                 ((context) {
//                                                               return AlertDialog(
//                                                                 content:
//                                                                     SizedBox(
//                                                                   width: 400,
//                                                                   child: Column(
//                                                                     mainAxisSize:
//                                                                         MainAxisSize
//                                                                             .min,
//                                                                     children: [
//                                                                       (controller.isPopupBannerAdLoaded.value &&
//                                                                               controller.popupBannerAd != null &&
//                                                                               controller.adFree.value == false)
//                                                                           ? SizedBox(
//                                                                               height: controller.popupBannerAd?.size.height.toDouble(),
//                                                                               width: controller.popupBannerAd?.size.width.toDouble(),
//                                                                               child: AdWidget(ad: controller.popupBannerAd!),
//                                                                             )
//                                                                           : SizedBox(
//                                                                               height: 150,
//                                                                               child: Image.asset(
//                                                                                 Images.aboutPlaceHolder(context),
//                                                                                 height: 150,
//                                                                                 width: 150,
//                                                                                 color: Colors.brown,
//                                                                               ),
//                                                                             ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Divider(
//                                                                         thickness:
//                                                                             2,
//                                                                         color: Colors
//                                                                             .brown,
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Text(
//                                                                         "Deleted Successfully!",
//                                                                         style: TextStyle(
//                                                                             letterSpacing: BibleInfo
//                                                                                 .letterSpacing,
//                                                                             fontSize: BibleInfo.fontSizeScale *
//                                                                                 20,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       SizedBox(
//                                                                         height:
//                                                                             40,
//                                                                         width:
//                                                                             150,
//                                                                         child: ElevatedButton(
//                                                                             style: ButtonStyle(
//                                                                               backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 220, 220, 220)),
//                                                                               shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                                                                                 RoundedRectangleBorder(
//                                                                                   borderRadius: BorderRadius.circular(8.0),
//                                                                                 ),
//                                                                               ), // Add rounded corners
//                                                                             ),
//                                                                             onPressed: () async {
//                                                                               await SharPreferences.setString('OpenAd', '1');
//                                                                               Get.back();
//                                                                               Provider.of<DownloadProvider>(context, listen: false).incrementBookmarkCount(context);
//                                                                             },
//                                                                             child: const Text(
//                                                                               "Dismiss",
//                                                                               style: TextStyle(letterSpacing: BibleInfo.letterSpacing, fontSize: BibleInfo.fontSizeScale * 20, fontWeight: FontWeight.bold, color: Colors.black),
//                                                                             )),
//                                                                       )
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }));
//                                                       }
//                                                     });
//                                                   }
//                                                 }
//                                               },
//                                               style: const ButtonStyle(
//                                                   backgroundColor:
//                                                       WidgetStatePropertyAll(
//                                                           Color(0xfffd5d5d5))),
//                                               child: Text(
//                                                 controller
//                                                             .selectedBookContent[
//                                                                 int.parse(verNum
//                                                                         .toString()) -
//                                                                     1]
//                                                             .isNoted ==
//                                                         "no"
//                                                     ? "Cancel"
//                                                     : "Delete",
//                                                 style: TextStyle(
//                                                     color: controller
//                                                                 .selectedBookContent[
//                                                                     int.parse(verNum
//                                                                             .toString()) -
//                                                                         1]
//                                                                 .isNoted ==
//                                                             "no"
//                                                         ? Colors.black
//                                                         : Colors.black,
//                                                     letterSpacing:
//                                                         BibleInfo.letterSpacing,
//                                                     fontSize: BibleInfo
//                                                             .fontSizeScale *
//                                                         14),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 25,
//                                           ),
//                                           SizedBox(
//                                             width: 100,
//                                             child: ElevatedButton(
//                                               onPressed: () async {
//                                                 try {
//                                                   await SharPreferences
//                                                       .setString('OpenAd', '1');
//                                                   await countprovider
//                                                       .decrementCount(context);
//                                                   if (controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isNoted ==
//                                                       "no") {
//                                                     var data =
//                                                         VerseBookContentModel(
//                                                       id: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .id,
//                                                       bookNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .bookNum,
//                                                       chapterNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .chapterNum,
//                                                       verseNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .verseNum,
//                                                       content: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .content,
//                                                       isBookmarked: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isBookmarked,
//                                                       isHighlighted: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isHighlighted,
//                                                       isNoted: controller
//                                                           .notesController
//                                                           .value
//                                                           .text,
//                                                       isUnderlined: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isUnderlined,
//                                                       isRead: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isRead,
//                                                     );

//                                                     controller
//                                                         .selectedBookContent[int
//                                                             .parse(verNum
//                                                                 .toString()) -
//                                                         1] = data;

//                                                     debugPrint(
//                                                         " check note 1-  ${int.parse(verseBookdata.id.toString())}  ");
//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_noted",
//                                                             controller
//                                                                 .notesController
//                                                                 .value
//                                                                 .text);
//                                                     await DBHelper()
//                                                         .insertNotes(
//                                                             SaveNotesModel(
//                                                       bookNum: int.parse(
//                                                           controller
//                                                               .selectedBookNum
//                                                               .value
//                                                               .toString()),
//                                                       chapterNum: int.parse(
//                                                           controller
//                                                               .selectedChapter
//                                                               .value
//                                                               .toString()),
//                                                       content: controller
//                                                           .printText.value
//                                                           .toString(),
//                                                       plaincontent:
//                                                           verseBookdata.id
//                                                               .toString(),
//                                                       bookName: controller
//                                                           .selectedBook.value
//                                                           .toString(),
//                                                       notes: controller
//                                                           .notesController
//                                                           .value
//                                                           .text,
//                                                       timestamp: DateTime.now()
//                                                           .toString(),
//                                                       verseNum: int.parse(
//                                                           verNum.toString()),
//                                                     ))
//                                                         .then((value) {
//                                                       debugPrint("Data Add");
//                                                     }).onError((error,
//                                                             stackTrace) {
//                                                       // print(error.toString());
//                                                     }).whenComplete(() async {
//                                                       Constants.showToast(
//                                                           "Notes added Successfully");
//                                                       Navigator.of(context)
//                                                           .pop(true);
//                                                       await SharPreferences
//                                                           .setString(
//                                                               'OpenAd', '1');
//                                                       await Future.delayed(
//                                                           Duration(
//                                                               milliseconds:
//                                                                   600));
//                                                       if (context.mounted) {
//                                                         controller
//                                                             .notesController
//                                                             .value
//                                                             .clear();
//                                                         return showDialog(
//                                                             context: context,
//                                                             builder:
//                                                                 ((context) {
//                                                               return AlertDialog(
//                                                                 content:
//                                                                     SizedBox(
//                                                                   width: 400,
//                                                                   child: Column(
//                                                                     mainAxisSize:
//                                                                         MainAxisSize
//                                                                             .min,
//                                                                     children: [
//                                                                       (controller.isPopupBannerAdLoaded.value &&
//                                                                               controller.popupBannerAd != null &&
//                                                                               controller.adFree.value == false)
//                                                                           ? SizedBox(
//                                                                               height: controller.popupBannerAd?.size.height.toDouble(),
//                                                                               width: controller.popupBannerAd?.size.width.toDouble(),
//                                                                               child: AdWidget(ad: controller.popupBannerAd!),
//                                                                             )
//                                                                           : SizedBox(
//                                                                               height: 150,
//                                                                               child: Image.asset(
//                                                                                 Images.aboutPlaceHolder(context),
//                                                                                 height: 150,
//                                                                                 width: 150,
//                                                                                 color: Colors.brown,
//                                                                               ),
//                                                                             ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Divider(
//                                                                         thickness:
//                                                                             2,
//                                                                         color: Colors
//                                                                             .brown,
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Text(
//                                                                         "Added Successfully!",
//                                                                         style: TextStyle(
//                                                                             letterSpacing: BibleInfo
//                                                                                 .letterSpacing,
//                                                                             fontSize: BibleInfo.fontSizeScale *
//                                                                                 20,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       SizedBox(
//                                                                         height:
//                                                                             40,
//                                                                         width:
//                                                                             150,
//                                                                         child: ElevatedButton(
//                                                                             style: ButtonStyle(
//                                                                               backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 220, 220, 220)),
//                                                                               shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                                                                                 RoundedRectangleBorder(
//                                                                                   borderRadius: BorderRadius.circular(8.0),
//                                                                                 ),
//                                                                               ), // Add rounded corners
//                                                                             ),
//                                                                             onPressed: () async {
//                                                                               Get.back();
//                                                                               await SharPreferences.setString('OpenAd', '1');
//                                                                               Provider.of<DownloadProvider>(context, listen: false).incrementBookmarkCount(context);
//                                                                             },
//                                                                             child: const Text(
//                                                                               "Dismiss",
//                                                                               style: TextStyle(letterSpacing: BibleInfo.letterSpacing, fontSize: BibleInfo.fontSizeScale * 20, fontWeight: FontWeight.bold, color: Colors.black),
//                                                                             )),
//                                                                       )
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }));
//                                                       }
//                                                     });
//                                                   } else {
//                                                     debugPrint("Update notes");
//                                                     var data =
//                                                         VerseBookContentModel(
//                                                       id: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .id,
//                                                       bookNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .bookNum,
//                                                       chapterNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .chapterNum,
//                                                       verseNum: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .verseNum,
//                                                       content: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .content,
//                                                       isBookmarked: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isBookmarked,
//                                                       isHighlighted: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isHighlighted,
//                                                       isNoted: controller
//                                                           .notesController
//                                                           .value
//                                                           .text,
//                                                       isUnderlined: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isUnderlined,
//                                                       isRead: controller
//                                                           .selectedBookContent[
//                                                               int.parse(verNum
//                                                                       .toString()) -
//                                                                   1]
//                                                           .isRead,
//                                                     );
//                                                     controller
//                                                         .selectedBookContent[int
//                                                             .parse(verNum
//                                                                 .toString()) -
//                                                         1] = data;
//                                                     await DBHelper()
//                                                         .updateVersesData(
//                                                             int.parse(
//                                                                 verseBookdata.id
//                                                                     .toString()),
//                                                             "is_noted",
//                                                             controller
//                                                                 .notesController
//                                                                 .value
//                                                                 .text);
//                                                     await DBHelper()
//                                                         .updateNotesData(
//                                                             controller
//                                                                 .printText.value
//                                                                 .toString(),
//                                                             "notes",
//                                                             controller
//                                                                 .notesController
//                                                                 .value
//                                                                 .text)
//                                                         .then((value) {
//                                                       debugPrint("Data Add");
//                                                     }).onError((error,
//                                                             stackTrace) {
//                                                       DebugConsole.log(
//                                                           "note error 2 - $error");
//                                                       debugPrint(
//                                                           error.toString());
//                                                     }).whenComplete(() async {
//                                                       await SharPreferences
//                                                           .setString(
//                                                               'OpenAd', '1');
//                                                       Constants.showToast(
//                                                           "Update notes successfully");
//                                                       Navigator.of(context)
//                                                           .pop(true);
//                                                       await Future.delayed(
//                                                           Duration(
//                                                               milliseconds:
//                                                                   600));
//                                                       if (context.mounted) {
//                                                         controller
//                                                             .notesController
//                                                             .value
//                                                             .clear();
//                                                         return showDialog(
//                                                             context: context,
//                                                             builder:
//                                                                 ((context) {
//                                                               return AlertDialog(
//                                                                 content:
//                                                                     SizedBox(
//                                                                   width: 400,
//                                                                   child: Column(
//                                                                     mainAxisSize:
//                                                                         MainAxisSize
//                                                                             .min,
//                                                                     children: [
//                                                                       (controller.isPopupBannerAdLoaded.value &&
//                                                                               controller.popupBannerAd != null &&
//                                                                               controller.adFree.value == false)
//                                                                           ? SizedBox(
//                                                                               height: controller.popupBannerAd?.size.height.toDouble(),
//                                                                               width: controller.popupBannerAd?.size.width.toDouble(),
//                                                                               child: AdWidget(ad: controller.popupBannerAd!),
//                                                                             )
//                                                                           : SizedBox(
//                                                                               height: 150,
//                                                                               child: Image.asset(
//                                                                                 Images.aboutPlaceHolder(context),
//                                                                                 height: 150,
//                                                                                 width: 150,
//                                                                                 color: Colors.brown,
//                                                                               ),
//                                                                             ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Divider(
//                                                                         thickness:
//                                                                             2,
//                                                                         color: Colors
//                                                                             .brown,
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       const Text(
//                                                                         "Update Successfully!",
//                                                                         style: TextStyle(
//                                                                             letterSpacing: BibleInfo
//                                                                                 .letterSpacing,
//                                                                             fontSize: BibleInfo.fontSizeScale *
//                                                                                 20,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       SizedBox(
//                                                                         height:
//                                                                             40,
//                                                                         width:
//                                                                             150,
//                                                                         child: ElevatedButton(
//                                                                             style: ButtonStyle(
//                                                                               backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 220, 220, 220)),
//                                                                               shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                                                                                 RoundedRectangleBorder(
//                                                                                   borderRadius: BorderRadius.circular(8.0),
//                                                                                 ),
//                                                                               ), // Add rounded corners
//                                                                             ),
//                                                                             onPressed: () async {
//                                                                               Get.back();
//                                                                               await SharPreferences.setString('OpenAd', '1');
//                                                                             },
//                                                                             child: const Text(
//                                                                               "Dismiss",
//                                                                               style: TextStyle(letterSpacing: BibleInfo.letterSpacing, fontSize: BibleInfo.fontSizeScale * 20, fontWeight: FontWeight.bold, color: Colors.black),
//                                                                             )),
//                                                                       )
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }));
//                                                       }
//                                                     });
//                                                   }
//                                                 } catch (e) {
//                                                   DebugConsole.log(
//                                                       "note error - $e");
//                                                 }
//                                               },
//                                               style: ButtonStyle(
//                                                   backgroundColor: controller
//                                                               .selectedBookContent[
//                                                                   int.parse(verNum
//                                                                           .toString()) -
//                                                                       1]
//                                                               .isNoted ==
//                                                           "no"
//                                                       ? const WidgetStatePropertyAll(
//                                                           Color(0xfffd5d5d5))
//                                                       : WidgetStatePropertyAll(Provider.of<
//                                                                           ThemeProvider>(
//                                                                       context,
//                                                                       listen:
//                                                                           false)
//                                                                   .themeMode ==
//                                                               ThemeMode.dark
//                                                           ? CommanColor
//                                                               .darkPrimaryColor
//                                                           : CommanColor
//                                                               .lightModePrimary)),
//                                               child: Text(
//                                                 controller
//                                                             .selectedBookContent[
//                                                                 int.parse(verNum
//                                                                         .toString()) -
//                                                                     1]
//                                                             .isNoted ==
//                                                         "no"
//                                                     ? "Save"
//                                                     : "Update",
//                                                 style: TextStyle(
//                                                     color: controller
//                                                                 .selectedBookContent[
//                                                                     int.parse(verNum
//                                                                             .toString()) -
//                                                                         1]
//                                                                 .isNoted ==
//                                                             "no"
//                                                         ? Colors.black
//                                                         : Colors.white,
//                                                     letterSpacing:
//                                                         BibleInfo.letterSpacing,
//                                                     fontSize: BibleInfo
//                                                             .fontSizeScale *
//                                                         14),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ).then((value) async {
//                               controller.notesController.value.clear();
//                             });
//                           },
//                           child: Column(
//                             children: [
//                               controller
//                                           .selectedBookContent[
//                                               int.parse(verNum.toString()) - 1]
//                                           .isNoted ==
//                                       "no"
//                                   ? Image.asset(
//                                       "assets/lightMode/icons/notes.png",
//                                       height: screenWidth > 450 ? 60 : 50,
//                                       width: screenWidth > 450 ? 45 : 35,
//                                     )
//                                   : Image.asset(
//                                       "assets/lightMode/icons/notes1.png",
//                                       height: screenWidth > 450 ? 60 : 50,
//                                       width: screenWidth > 450 ? 45 : 35,
//                                     ),
//                               const SizedBox(
//                                 height: 10,
//                               ),
//                               Text("Notes",
//                                   style: TextStyle(
//                                     letterSpacing: BibleInfo.letterSpacing,
//                                     fontSize:
//                                         BibleInfo.fontSizeScale * screenWidth >
//                                                 450
//                                             ? 16
//                                             : 12,
//                                     fontWeight: FontWeight.bold,
//                                     color:
//                                         CommanColor.lightDarkPrimary(context),
//                                   ))
//                             ],
//                           ),
//                         ),
//                         screenWidth > 450
//                             ? const SizedBox(width: 20)
//                             : SizedBox(),
//                         ////////
//                         ///Images
//                         ///
//                         ////////
//                         StatefulBuilder(
//                           builder:
//                               (BuildContext context, StateSetter setState) {
//                             bool isTextVisible = true;
//                             void toggleTextVisibility() {
//                               setState(() {
//                                 isTextVisible = !isTextVisible;
//                               });
//                             }

//                             return GestureDetector(
//                               onTap: () async {
//                                 String bibleName;
//                                 bibleName = BibleInfo.bible_shortName;

//                                 await SharPreferences.setString('OpenAd', '1');
//                                 return showModalBottomSheet(
//                                   isScrollControlled: true,
//                                   backgroundColor: Colors.transparent,
//                                   context: context,
//                                   builder: (context) {
//                                     double screenWidth =
//                                         MediaQuery.of(context).size.width;
//                                     return Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         controller.isImageBannerAdLoaded
//                                                     .value &&
//                                                 controller.imageBannerAd !=
//                                                     null &&
//                                                 controller.adFree.value == false
//                                             ? SizedBox(
//                                                 height: controller
//                                                     .imageBannerAd?.size.height
//                                                     .toDouble(),
//                                                 width: controller
//                                                     .imageBannerAd?.size.width
//                                                     .toDouble(),
//                                                 child: Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                           top: 5),
//                                                   child: AdWidget(
//                                                       ad: controller
//                                                           .imageBannerAd!),
//                                                 ),
//                                               )
//                                             : SizedBox(
//                                                 height:
//                                                     screenWidth < 380 ? 2 : 100,
//                                               ),
//                                         Flexible(
//                                           child: FractionallySizedBox(
//                                             heightFactor: screenWidth < 380
//                                                 ? 0.85
//                                                 : screenWidth > 450
//                                                     ? 0.82
//                                                     : 0.81,
//                                             child: Container(
//                                                 decoration: const BoxDecoration(
//                                                     borderRadius:
//                                                         BorderRadius.only(
//                                                             topLeft: Radius
//                                                                 .circular(0),
//                                                             topRight:
//                                                                 Radius.circular(
//                                                                     0)),
//                                                     color: Colors.white),
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 10),
//                                                 child: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     const SizedBox(height: 15),
//                                                     Stack(
//                                                       children: [
//                                                         Screenshot(
//                                                           controller: controller
//                                                               .screenshotController
//                                                               .value,
//                                                           child:
//                                                               GestureDetector(
//                                                             onTap: () {
//                                                               controller.selectedBgImage
//                                                                           .value ==
//                                                                       9
//                                                                   ? controller
//                                                                       .selectedBgImage
//                                                                       .value = 0
//                                                                   : controller
//                                                                       .selectedBgImage
//                                                                       .value = controller
//                                                                           .selectedBgImage
//                                                                           .value +
//                                                                       1;
//                                                             },
//                                                             child: Stack(
//                                                               children: [
//                                                                 SizedBox(
//                                                                     height: screenWidth <
//                                                                             380
//                                                                         ? MediaQuery.of(context).size.height *
//                                                                             0.735
//                                                                         : screenWidth >
//                                                                                 450
//                                                                             ? MediaQuery.of(context).size.height *
//                                                                                 0.69
//                                                                             : MediaQuery.of(context).size.height *
//                                                                                 0.62,
//                                                                     width: MediaQuery.sizeOf(
//                                                                             context)
//                                                                         .width,
//                                                                     child: Obx(
//                                                                       () =>
//                                                                           Image(
//                                                                         image: AssetImage(controller.bgImagesList[controller
//                                                                             .selectedBgImage
//                                                                             .value]),
//                                                                         fit: BoxFit
//                                                                             .fill,
//                                                                       ),
//                                                                     )),
//                                                                 Positioned(
//                                                                     left: 10,
//                                                                     right: 10,
//                                                                     bottom: 0,
//                                                                     top: 0,
//                                                                     child: Obx(
//                                                                         () =>
//                                                                             Column(
//                                                                               mainAxisAlignment: MainAxisAlignment.center,
//                                                                               children: [
//                                                                                 Padding(
//                                                                                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                                                                                   child: AutoSizeHtmlWidget(
//                                                                                     html: controller.selectedBookContent[controller.selectedVerseView.value].content,
//                                                                                     maxLines: 16, // Your desired max lines
//                                                                                     maxFontSize: screenWidth < 380
//                                                                                         ? BibleInfo.fontSizeScale * 14.5
//                                                                                         : screenWidth > 450
//                                                                                             ? BibleInfo.fontSizeScale * 31
//                                                                                             : controller.fontSize.value - 0.9,
//                                                                                     minFontSize: screenWidth < 380 ? 11.5 : 10.9,
//                                                                                   ),
//                                                                                 ),
//                                                                                 const SizedBox(
//                                                                                   height: 10,
//                                                                                 ),
//                                                                                 Row(
//                                                                                   mainAxisAlignment: MainAxisAlignment.end,
//                                                                                   children: [
//                                                                                     Text(
//                                                                                       "${controller.selectedBook.value} ${controller.selectedChapter.value}:${controller.selectedVerseView.value + 1}",
//                                                                                       style: TextStyle(
//                                                                                         color: Colors.black,
//                                                                                         letterSpacing: BibleInfo.letterSpacing,
//                                                                                         fontSize: screenWidth > 450 ? BibleInfo.fontSizeScale * 28 : BibleInfo.fontSizeScale * 15,
//                                                                                         fontWeight: FontWeight.w500,
//                                                                                         height: 1.2,
//                                                                                         fontStyle: FontStyle.italic,
//                                                                                       ),
//                                                                                       textAlign: TextAlign.center,
//                                                                                     ),
//                                                                                     const SizedBox(
//                                                                                       width: 10,
//                                                                                     )
//                                                                                   ],
//                                                                                 ),
//                                                                               ],
//                                                                             ))),
//                                                                 Positioned(
//                                                                     left: 0,
//                                                                     right: 0,
//                                                                     bottom: 7,
//                                                                     child: isTextVisible
//                                                                         ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                                                                             Image.asset(
//                                                                               "assets/Icon-1024.png",
//                                                                               height: 30,
//                                                                               width: 30,
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 10,
//                                                                             ),
//                                                                             Column(
//                                                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                                                               children: [
//                                                                                 Text(
//                                                                                   bibleName,
//                                                                                   style: const TextStyle(color: Color.fromARGB(255, 135, 130, 130), letterSpacing: BibleInfo.letterSpacing, fontSize: BibleInfo.fontSizeScale * 16, fontWeight: FontWeight.w500, height: 1.3),
//                                                                                   textAlign: TextAlign.center,
//                                                                                 ),
//                                                                                 if (Platform.isAndroid)
//                                                                                   const Text(
//                                                                                     "Search in PlayStore",
//                                                                                     style: TextStyle(color: Color.fromARGB(255, 135, 130, 130)),
//                                                                                   )
//                                                                                 else if (Platform.isIOS)
//                                                                                   const Text(
//                                                                                     "Search in AppStore",
//                                                                                     style: TextStyle(color: Color.fromARGB(255, 135, 130, 130)),
//                                                                                   )
//                                                                               ],
//                                                                             ),
//                                                                           ])
//                                                                         : const SizedBox.shrink()),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         Positioned(
//                                                             right: 10,
//                                                             bottom: 25,
//                                                             child: InkWell(
//                                                               onTap: () async {
//                                                                 final adProvider =
//                                                                     context.read<
//                                                                         DownloadProvider>();
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'OpenAd',
//                                                                         '1');
//                                                                 // Increase ad count
//                                                                 await adProvider
//                                                                     .updateAdCount(
//                                                                         adProvider.adCount +
//                                                                             1);

//                                                                 // Check and possibly show ad
//                                                                 await adProvider
//                                                                     .checkAndShowAd(
//                                                                         context);
//                                                                 print(controller
//                                                                     .selectedVerseView
//                                                                     .value);
//                                                                 print(controller
//                                                                     .selectedBookContent
//                                                                     .length);
//                                                                 // controller.selectedBgImage.value == 9?controller.selectedBgImage.value = 9 :  controller.selectedBgImage.value = controller.selectedBgImage.value +1;
//                                                                 controller
//                                                                             .selectedVerseView
//                                                                             .value ==
//                                                                         controller.selectedBookContent.length -
//                                                                             1
//                                                                     ? controller
//                                                                         .selectedVerseView
//                                                                         .value = controller
//                                                                             .selectedBookContent
//                                                                             .length -
//                                                                         1
//                                                                     : controller
//                                                                         .selectedVerseView
//                                                                         .value = controller
//                                                                             .selectedVerseView
//                                                                             .value +
//                                                                         1;
//                                                               },
//                                                               child: Container(
//                                                                 height:
//                                                                     screenWidth >
//                                                                             450
//                                                                         ? 45
//                                                                         : 25,
//                                                                 width:
//                                                                     screenWidth >
//                                                                             450
//                                                                         ? 45
//                                                                         : 25,
//                                                                 decoration:
//                                                                     const BoxDecoration(
//                                                                   shape: BoxShape
//                                                                       .circle,
//                                                                   color: Colors
//                                                                       .black38,
//                                                                 ),
//                                                                 child: Center(
//                                                                     child: Image
//                                                                         .asset(
//                                                                   "assets/next.png",
//                                                                   color: Colors
//                                                                       .white,
//                                                                   height: 15,
//                                                                   width: 15,
//                                                                 )),
//                                                               ),
//                                                             )),
//                                                         Positioned(
//                                                             left: 10,
//                                                             bottom: 25,
//                                                             child: InkWell(
//                                                               onTap: () async {
//                                                                 try {
//                                                                   await SharPreferences
//                                                                       .setString(
//                                                                           'OpenAd',
//                                                                           '1');
//                                                                   final adProvider =
//                                                                       context.read<
//                                                                           DownloadProvider>();

//                                                                   // Increase ad count
//                                                                   await adProvider
//                                                                       .updateAdCount(
//                                                                           adProvider.adCount +
//                                                                               1);

//                                                                   // Check and possibly show ad
//                                                                   await adProvider
//                                                                       .checkAndShowAd(
//                                                                           context);
//                                                                   controller.selectedVerseView
//                                                                               .value ==
//                                                                           0
//                                                                       ? controller
//                                                                               .selectedVerseView
//                                                                               .value =
//                                                                           0
//                                                                       : controller
//                                                                           .selectedVerseView
//                                                                           .value = controller
//                                                                               .selectedVerseView
//                                                                               .value -
//                                                                           1;
//                                                                 } catch (e) {
//                                                                   DebugConsole.log(
//                                                                       "image priv error - $e");
//                                                                 }
//                                                                 // controller.selectedBgImage.value == 0?controller.selectedBgImage.value = 0: controller.selectedBgImage.value = controller.selectedBgImage.value -1;
//                                                               },
//                                                               child: Container(
//                                                                 height:
//                                                                     screenWidth >
//                                                                             450
//                                                                         ? 45
//                                                                         : 25,
//                                                                 width:
//                                                                     screenWidth >
//                                                                             450
//                                                                         ? 45
//                                                                         : 25,
//                                                                 decoration:
//                                                                     const BoxDecoration(
//                                                                   shape: BoxShape
//                                                                       .circle,
//                                                                   color: Colors
//                                                                       .black38,
//                                                                 ),
//                                                                 child: Center(
//                                                                     child: Image
//                                                                         .asset(
//                                                                   "assets/priv.png",
//                                                                   color: Colors
//                                                                       .white,
//                                                                   height: 15,
//                                                                   width: 15,
//                                                                 )),
//                                                               ),
//                                                             )),
//                                                       ],
//                                                     ),
//                                                     Spacer(),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceEvenly,
//                                                       children: [
//                                                         SizedBox(
//                                                           width: 100,
//                                                           height:
//                                                               screenWidth > 450
//                                                                   ? 60
//                                                                   : null,
//                                                           child: ElevatedButton(
//                                                               onPressed:
//                                                                   () async {
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'OpenAd',
//                                                                         '1');
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'bottom',
//                                                                         '1');
//                                                                 final image = await controller
//                                                                     .screenshotController
//                                                                     .value
//                                                                     .capture(
//                                                                         delay: const Duration(
//                                                                             milliseconds:
//                                                                                 10));
//                                                                 if (image ==
//                                                                     null) {
//                                                                   await SharPreferences
//                                                                       .setString(
//                                                                           'bottom',
//                                                                           '0');
//                                                                   return;
//                                                                 }
//                                                                 final appPackageName =
//                                                                     (await PackageInfo
//                                                                             .fromPlatform())
//                                                                         .packageName;
//                                                                 String appid;
//                                                                 appid = BibleInfo
//                                                                     .apple_AppId;

//                                                                 String message =
//                                                                     "";
//                                                                 if (Platform
//                                                                     .isAndroid) {
//                                                                   message =
//                                                                       " \n Read More at: https://play.google.com/store/apps/details?id=$appPackageName";
//                                                                 } else if (Platform
//                                                                     .isIOS) {
//                                                                   message =
//                                                                       " \n Read More at: https://itunes.apple.com/app/id$appid";
//                                                                 }
//                                                                 saveAndShare(
//                                                                     image,
//                                                                     "bible",
//                                                                     message);

//                                                                 await countprovider
//                                                                     .decrementCount(
//                                                                         context);
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'bottom',
//                                                                         '0');
//                                                               },
//                                                               style: ButtonStyle(
//                                                                   backgroundColor:
//                                                                       WidgetStatePropertyAll(
//                                                                           CommanColor.lightDarkPrimary(
//                                                                               context))),
//                                                               child: Center(
//                                                                 child: Text(
//                                                                   "Share",
//                                                                   style: TextStyle(
//                                                                       color: Colors
//                                                                           .white,
//                                                                       letterSpacing:
//                                                                           BibleInfo
//                                                                               .letterSpacing,
//                                                                       fontSize: screenWidth > 450
//                                                                           ? BibleInfo.fontSizeScale *
//                                                                               17
//                                                                           : BibleInfo.fontSizeScale *
//                                                                               14),
//                                                                 ),
//                                                               )),
//                                                         ),
//                                                         SizedBox(
//                                                           width: 100,
//                                                           height:
//                                                               screenWidth > 450
//                                                                   ? 60
//                                                                   : null,
//                                                           child: ElevatedButton(
//                                                               onPressed:
//                                                                   () async {
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'OpenAd',
//                                                                         '1');
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'bottom',
//                                                                         '1');
//                                                                 final image =
//                                                                     await controller
//                                                                         .screenshotController
//                                                                         .value
//                                                                         .capture();
//                                                                 if (image ==
//                                                                     null) {
//                                                                   await SharPreferences
//                                                                       .setString(
//                                                                           'bottom',
//                                                                           '0');
//                                                                   return;
//                                                                 }

//                                                                 await saveImageIntoLocal(
//                                                                     image,
//                                                                     context);
//                                                                 await countprovider
//                                                                     .decrementCount(
//                                                                         context);
//                                                                 await SharPreferences
//                                                                     .setString(
//                                                                         'bottom',
//                                                                         '0');
//                                                               },
//                                                               style: ButtonStyle(
//                                                                   backgroundColor:
//                                                                       WidgetStatePropertyAll(
//                                                                           CommanColor.lightDarkPrimary(
//                                                                               context))),
//                                                               child: Center(
//                                                                 child: Text(
//                                                                   "Save",
//                                                                   style: TextStyle(
//                                                                       color: Colors
//                                                                           .white,
//                                                                       letterSpacing:
//                                                                           BibleInfo
//                                                                               .letterSpacing,
//                                                                       fontSize: screenWidth > 450
//                                                                           ? BibleInfo.fontSizeScale *
//                                                                               17
//                                                                           : BibleInfo.fontSizeScale *
//                                                                               14),
//                                                                 ),
//                                                               )),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     Spacer(),
//                                                     const SizedBox(height: 1),
//                                                   ],
//                                                 )),
//                                           ),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 );
//                               },
//                               child: Column(
//                                 children: [
//                                   Image.asset(
//                                     "assets/lightMode/icons/Create-Image.png",
//                                     height: screenWidth > 450 ? 60 : 50,
//                                     width: screenWidth > 450 ? 45 : 35,
//                                   ),
//                                   const SizedBox(
//                                     height: 10,
//                                   ),
//                                   Text(
//                                     "  Image   ",
//                                     style: TextStyle(
//                                         letterSpacing: BibleInfo.letterSpacing,
//                                         fontSize: BibleInfo.fontSizeScale *
//                                                     screenWidth >
//                                                 450
//                                             ? 16
//                                             : 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: CommanColor.lightDarkPrimary(
//                                             context)),
//                                   )
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                         screenWidth > 450
//                             ? const SizedBox(width: 20)
//                             : SizedBox(),
//                         //////////
//                         /////Under Line
//                         ////////
//                         StatefulBuilder(builder:
//                             (BuildContext context, StateSetter setState) {
//                           return GestureDetector(
//                               onTap: () async {
//                                 DebugConsole.log("underline started");
//                                 try {
//                                   await SharPreferences.setString(
//                                       'OpenAd', '1');
//                                   // Provider.of<DownloadProvider>(context,
//                                   //         listen: false)
//                                   //     .incrementBookmarkCount(context);
//                                   await countprovider.decrementCount(context);
//                                   int index = int.parse(verNum.toString()) - 1;
//                                   if (verseBookdata.isUnderlined == "no") {
//                                     // Create updated verse data
//                                     isunderlined = true;
//                                     var data = VerseBookContentModel(
//                                       id: controller
//                                           .selectedBookContent[index].id,
//                                       bookNum: controller
//                                           .selectedBookContent[index].bookNum,
//                                       chapterNum: controller
//                                           .selectedBookContent[index]
//                                           .chapterNum,
//                                       verseNum: controller
//                                           .selectedBookContent[index].verseNum,
//                                       content: controller
//                                           .selectedBookContent[index].content,
//                                       isBookmarked: controller
//                                           .selectedBookContent[index]
//                                           .isBookmarked,
//                                       isHighlighted: controller
//                                           .selectedBookContent[index]
//                                           .isHighlighted,
//                                       isNoted: controller
//                                           .selectedBookContent[index].isNoted,
//                                       isUnderlined: "yes",
//                                       isRead: controller
//                                           .selectedBookContent[index].isRead,
//                                     );

//                                     controller.selectedBookContent[index] =
//                                         data;

//                                     await DBHelper().updateVersesData(
//                                       int.parse(verseBookdata.id.toString()),
//                                       "is_underlined",
//                                       "yes",
//                                     );

//                                     await DBHelper()
//                                         .insertUnderLine(
//                                       BookMarkModel(
//                                         bookNum: int.parse(controller
//                                             .selectedBookNum.value
//                                             .toString()),
//                                         chapterNum: int.parse(controller
//                                             .selectedChapter.value
//                                             .toString()),
//                                         content: controller.printText.value,
//                                         plaincontent:
//                                             verseBookdata.id.toString(),
//                                         bookName: controller.selectedBook.value,
//                                         timestamp: DateTime.now().toString(),
//                                         verseNum: int.parse(verNum.toString()),
//                                       ),
//                                     )
//                                         .then((value) async {
//                                       debugPrint("Data Added");
//                                       await SharPreferences.setString(
//                                           'OpenAd', '1');
//                                       await Future.delayed(
//                                           Duration(milliseconds: 600));
//                                       if (context.mounted) {
//                                         return showDialog(
//                                           context: context,
//                                           builder: (context) {
//                                             return AlertDialog(
//                                               content: SizedBox(
//                                                 width: 400,
//                                                 child: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     // Ad Banner or Placeholder
//                                                     (controller.isPopupBannerAdLoaded
//                                                                 .value &&
//                                                             controller
//                                                                     .popupBannerAd !=
//                                                                 null &&
//                                                             controller.adFree
//                                                                     .value ==
//                                                                 false)
//                                                         ? SizedBox(
//                                                             height: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .height
//                                                                 .toDouble(),
//                                                             width: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .width
//                                                                 .toDouble(),
//                                                             child: AdWidget(
//                                                                 ad: controller
//                                                                     .popupBannerAd!),
//                                                           )
//                                                         : SizedBox(
//                                                             height: 150,
//                                                             child: Image.asset(
//                                                               Images
//                                                                   .aboutPlaceHolder(
//                                                                       context),
//                                                               height: 150,
//                                                               width: 150,
//                                                               color:
//                                                                   Colors.brown,
//                                                             ),
//                                                           ),
//                                                     const SizedBox(height: 20),
//                                                     const Divider(
//                                                         thickness: 2,
//                                                         color: Colors.brown),
//                                                     const SizedBox(height: 20),
//                                                     const Text(
//                                                       "Underlined Successfully!",
//                                                       style: TextStyle(
//                                                         letterSpacing: BibleInfo
//                                                             .letterSpacing,
//                                                         fontSize: BibleInfo
//                                                                 .fontSizeScale *
//                                                             20,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                       textAlign:
//                                                           TextAlign.center,
//                                                     ),
//                                                     const SizedBox(height: 20),
//                                                     SizedBox(
//                                                       height: 40,
//                                                       width: 150,
//                                                       child: ElevatedButton(
//                                                         style: ButtonStyle(
//                                                           backgroundColor:
//                                                               WidgetStateProperty.all<
//                                                                       Color>(
//                                                                   const Color
//                                                                       .fromARGB(
//                                                                       255,
//                                                                       220,
//                                                                       220,
//                                                                       220)),
//                                                           shape: WidgetStateProperty
//                                                               .all<
//                                                                   RoundedRectangleBorder>(
//                                                             RoundedRectangleBorder(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           8.0),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         onPressed: () async {
//                                                           Get.back();
//                                                           await SharPreferences
//                                                               .setString(
//                                                                   'OpenAd',
//                                                                   '1');
//                                                           Provider.of<DownloadProvider>(
//                                                                   context,
//                                                                   listen: false)
//                                                               .incrementBookmarkCount(
//                                                                   context);
//                                                         },
//                                                         child: const Text(
//                                                           "Dismiss",
//                                                           style: TextStyle(
//                                                             letterSpacing:
//                                                                 BibleInfo
//                                                                     .letterSpacing,
//                                                             fontSize: BibleInfo
//                                                                     .fontSizeScale *
//                                                                 20,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             color: Colors.black,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     )
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         );
//                                       }
//                                       // Optional: pop previous screen if needed
//                                       Get.back();
//                                     }).onError((error, stackTrace) {
//                                       debugPrint("Insert error: $error");
//                                       DebugConsole.log(
//                                           "underline insert error - $error");
//                                     });
//                                   } else {
//                                     isunderlined = false;
//                                     // Create updated verse data with isUnderlined set to "no"
//                                     var data = VerseBookContentModel(
//                                       id: controller
//                                           .selectedBookContent[index].id,
//                                       bookNum: controller
//                                           .selectedBookContent[index].bookNum,
//                                       chapterNum: controller
//                                           .selectedBookContent[index]
//                                           .chapterNum,
//                                       verseNum: controller
//                                           .selectedBookContent[index].verseNum,
//                                       content: controller
//                                           .selectedBookContent[index].content,
//                                       isBookmarked: controller
//                                           .selectedBookContent[index]
//                                           .isBookmarked,
//                                       isHighlighted: controller
//                                           .selectedBookContent[index]
//                                           .isHighlighted,
//                                       isNoted: controller
//                                           .selectedBookContent[index].isNoted,
//                                       isUnderlined: "no",
//                                       isRead: controller
//                                           .selectedBookContent[index].isRead,
//                                     );

// // Update local state
//                                     controller.selectedBookContent[index] =
//                                         data;
//                                     await SharPreferences.setString(
//                                         'OpenAd', '1');
// // Update DB
//                                     DBHelper().updateVersesData(
//                                       int.parse(verseBookdata.id.toString()),
//                                       "is_underlined",
//                                       "no",
//                                     );

// // Insert record into DB (optional: use remove function instead if that’s intended)
//                                     await DBHelper()
//                                         .deleteUnderlineByContent(
//                                             controller.printText.value)
//                                         .then((value) async {
//                                           debugPrint("remove ");
//                                           await Future.delayed(
//                                               Duration(milliseconds: 600));
//                                           if (context.mounted) {
//                                             showDialog(
//                                               context: context,
//                                               builder: (context) {
//                                                 return AlertDialog(
//                                                   content: SizedBox(
//                                                     width: 400,
//                                                     child: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         // Ad banner or fallback image
//                                                         (controller.isPopupBannerAdLoaded
//                                                                     .value &&
//                                                                 controller
//                                                                         .popupBannerAd !=
//                                                                     null &&
//                                                                 controller
//                                                                         .adFree
//                                                                         .value ==
//                                                                     false)
//                                                             ? SizedBox(
//                                                                 height: controller
//                                                                     .popupBannerAd
//                                                                     ?.size
//                                                                     .height
//                                                                     .toDouble(),
//                                                                 width: controller
//                                                                     .popupBannerAd
//                                                                     ?.size
//                                                                     .width
//                                                                     .toDouble(),
//                                                                 child: AdWidget(
//                                                                     ad: controller
//                                                                         .popupBannerAd!),
//                                                               )
//                                                             : SizedBox(
//                                                                 height: 150,
//                                                                 child:
//                                                                     Image.asset(
//                                                                   Images.aboutPlaceHolder(
//                                                                       context),
//                                                                   height: 150,
//                                                                   width: 150,
//                                                                   color: Colors
//                                                                       .brown,
//                                                                 ),
//                                                               ),
//                                                         const SizedBox(
//                                                             height: 20),
//                                                         const Divider(
//                                                             thickness: 2,
//                                                             color:
//                                                                 Colors.brown),
//                                                         const SizedBox(
//                                                             height: 20),
//                                                         const Text(
//                                                           "Removed Successfully!",
//                                                           style: TextStyle(
//                                                             letterSpacing:
//                                                                 BibleInfo
//                                                                     .letterSpacing,
//                                                             fontSize: BibleInfo
//                                                                     .fontSizeScale *
//                                                                 20,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 20),
//                                                         SizedBox(
//                                                           height: 40,
//                                                           width: 150,
//                                                           child: ElevatedButton(
//                                                             style: ButtonStyle(
//                                                               backgroundColor:
//                                                                   WidgetStateProperty.all<
//                                                                           Color>(
//                                                                       const Color
//                                                                           .fromARGB(
//                                                                           255,
//                                                                           220,
//                                                                           220,
//                                                                           220)),
//                                                               shape: WidgetStateProperty
//                                                                   .all<
//                                                                       RoundedRectangleBorder>(
//                                                                 RoundedRectangleBorder(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               8.0),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             onPressed:
//                                                                 () async {
//                                                               Get.back();
//                                                               await SharPreferences
//                                                                   .setString(
//                                                                       'OpenAd',
//                                                                       '1');
//                                                               Provider.of<DownloadProvider>(
//                                                                       context,
//                                                                       listen:
//                                                                           false)
//                                                                   .incrementBookmarkCount(
//                                                                       context);
//                                                             },
//                                                             child: const Text(
//                                                               "Dismiss",
//                                                               style: TextStyle(
//                                                                 letterSpacing:
//                                                                     BibleInfo
//                                                                         .letterSpacing,
//                                                                 fontSize: BibleInfo
//                                                                         .fontSizeScale *
//                                                                     20,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );

//                                             // Optionally pop the previous screen
//                                             Get.back();
//                                           }
//                                         })
//                                         .whenComplete(() {})
//                                         .onError((error, stackTrace) {
//                                           debugPrint("Insert error: $error");
//                                         });
//                                   }
//                                 } catch (e) {
//                                   DebugConsole.log("underline error - $e");
//                                 }
//                               },
//                               child: Column(
//                                 children: [
//                                   //  Image.asset("assets/lightMode/icons/Underline.png",
//                                   //  color: verseBookdata.isUnderlined == "yes" ? Colors.green : CommanColor.lightDarkPrimary(context), height: 50, width: 35),
//                                   isunderlined
//                                       ? Image.asset(
//                                           "assets/lightMode/icons/Underline.png",
//                                           height: screenWidth > 450 ? 60 : 50,
//                                           width: screenWidth > 450 ? 45 : 35,
//                                         )
//                                       : Image.asset(
//                                           "assets/lightMode/icons/Underline3.png",
//                                           height: screenWidth > 450 ? 60 : 50,
//                                           width: screenWidth > 450 ? 45 : 35,
//                                         ),
//                                   const SizedBox(
//                                     height: 10,
//                                   ),
//                                   Text("Underline",
//                                       style: TextStyle(
//                                         letterSpacing: BibleInfo.letterSpacing,
//                                         fontSize: BibleInfo.fontSizeScale *
//                                                     screenWidth >
//                                                 450
//                                             ? 16
//                                             : 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: CommanColor.lightDarkPrimary(
//                                             context),
//                                       )),
//                                 ],
//                               ));
//                         })
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
// Container(
//   height: 50,
//   width: double.infinity,
//   alignment: Alignment.center,
//   child: ListView.builder(
//     shrinkWrap: true,
//     scrollDirection: Axis.horizontal,
//     itemCount: controller.colors.value.length,
//     itemBuilder: (context, index) {
//       return GestureDetector(
//         onTap: () async {
//           await SharPreferences.setString('OpenAd', '1');

//           final int indexVal = index;
//           final Color color = controller.colors[indexVal];
//           final String colorValueStr = color.value.toString();

//           selectedColor = color; // Color type
//           selectedindex = index;

//           debugPrint('Set BG Color $colorValueStr');

//           final int verseIndex =
//               int.parse(verNum.toString()) - 1;
//           final selectedVerse =
//               controller.selectedBookContent[verseIndex];

//           final bool isSameColor = (int.tryParse(
//                       verseBookdata.isHighlighted ?? '') ??
//                   0) ==
//               color.value;

//           final updatedVerse = selectedVerse.copyWith(
//             isHighlighted:
//                 isSameColor ? "no" : color.value.toString(),
//           );

//           controller.selectedBookContent[verseIndex] =
//               updatedVerse;
//           controller.selectedBookContent
//               .refresh(); // ✅ force list update

//           controller.colorsCheack.value =
//               isSameColor ? -1 : indexVal;
//           controller.selectedColorOrNot.value =
//               isSameColor ? "no" : indexVal.toString();

//           await DBHelper().updateVersesData(
//             int.parse(verseBookdata.id.toString()),
//             "is_highlighted",
//             isSameColor ? "no" : color.value.toString(),
//           );

//           if (isSameColor) {
//             await DBHelper().deleteHighlightByContent(
//                 controller.printText.value);
//             Constants.showToast(
//                 'Removed from Highlight Successfully');
//             Get.back();
//             return;
//           }

//           await DBHelper().deleteHighlightByContent(
//               controller.printText.value);
//           final data =
//               normalizeHtml(controller.printText.value);
//           callback?.call('0x00000000'); // clear first
//           await Future.delayed(
//               const Duration(milliseconds: 300));

//           await DBHelper()
//               .insertIntoHighLight(
//             HighLightContentModal(
//               plain_content: data,
//               bookNum: int.parse(controller
//                   .selectedBookNum.value
//                   .toString()),
//               chapterNum: int.parse(controller
//                   .selectedChapter.value
//                   .toString()),
//               content: controller.printText.value,
//               bookName:
//                   controller.selectedBook.value.toString(),
//               color: color.value.toString(),
//               timestamp: DateTime.now().toString(),
//               verseNum: int.parse(verNum.toString()),
//             ),
//           )
//               .whenComplete(() async {
//             Constants.showToast(
//               verseBookdata.isHighlighted == "no"
//                   ? "Added in Highlight Successfully"
//                   : "Updated in Highlight Successfully",
//             );
//             callback?.call(color.value.toString());
//             await Future.delayed(
//                 const Duration(milliseconds: 500));
//             Get.back();
//           }).catchError((e) {
//             debugPrint("Highlight insert failed: $e");
//           });
//         },
//         child: Obx(() {
//           final verseData = controller.selectedBookContent[
//               int.parse(verNum.toString()) - 1];

//           final bool isHighlightedColor = verseData
//                       .isHighlighted !=
//                   null &&
//               int.tryParse(verseData.isHighlighted!) !=
//                   null &&
//               Color(int.parse(verseData.isHighlighted!)) ==
//                   controller.colors[index];

//           final bool isSelected =
//               selectedColor != null && selectedindex == index;

//           return Container(
//             margin: const EdgeInsets.all(10),
//             width: 30,
//             height: 40,
//             decoration: BoxDecoration(
//               color: controller.colors[index],
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: (verseData.isHighlighted == "no")
//                 ? (isSelected
//                     ? Icon(
//                         Icons.check_circle_rounded,
//                         size: 20,
//                         color: CommanColor.lightDarkPrimary(
//                             context),
//                       )
//                     : const SizedBox())
//                 : (isHighlightedColor
//                     ? Icon(
//                         Icons.check_circle_rounded,
//                         size: 20,
//                         color: CommanColor.lightDarkPrimary(
//                             context),
//                       )
//                     : const SizedBox()),
//           );
//         }),
//       );

//       //       margin: const EdgeInsets.all(10),
//       //       width: 30,
//       //       height: 40,
//       //       decoration: BoxDecoration(
//       //           color: controller.colors[index],
//       //           borderRadius: BorderRadius.circular(2)),
//       //       child: verseBookdata.isHighlighted == "no"
//       //           ? selectedColor != null &&
//       //                   selectedindex == index
//       //               ? Icon(
//       //                   Icons.check_circle_rounded,
//       //                   size: 20,
//       //                   color: CommanColor.lightDarkPrimary(
//       //                       context),
//       //                 )
//       //               : const SizedBox()
//       //           : Color(int.tryParse(
//       //                           verseBookdata.isHighlighted ??
//       //                               '') ??
//       //                       selectedColor!.toARGB32()) ==
//       //                   controller.colors[index]
//       //               ? Icon(
//       //                   Icons.check_circle_rounded,
//       //                   size: 20,
//       //                   color: CommanColor.lightDarkPrimary(
//       //                       context),
//       //                 )
//       //               : const SizedBox(),
//       //     );
//       //   }),
//       // );
//     },
//   ),
// ),
//                   const SizedBox(height: 15),
//                   SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.5,
//                     child: Row(
//                       mainAxisAlignment: screenWidth > 450
//                           ? MainAxisAlignment.center
//                           : MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           children: [
//                             GestureDetector(
//                               onTap: () async {
//                                 await SharPreferences.setString('OpenAd', '1');
//                                 // Provider.of<DownloadProvider>(context,
//                                 //         listen: false)
//                                 //     .incrementBookmarkCount(context);
//                                 await countprovider.decrementCount(context);
//                                 String appId;
//                                 appId = BibleInfo.apple_AppId;
//                                 final appPackageName =
//                                     (await PackageInfo.fromPlatform())
//                                         .packageName;
//                                 if (Platform.isAndroid) {
//                                   await Clipboard.setData(ClipboardData(
//                                       text:
//                                           "${controller.printText.value.toString()} \n${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum \n\n Read more at  \n\nhttps://play.google.com/store/apps/details?id=$appPackageName"));
//                                 } else if (Platform.isIOS) {
//                                   await Clipboard.setData(ClipboardData(
//                                       text:
//                                           "${controller.printText.value.toString()} \n${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum \n\n Read more at  \n\nhttps://itunes.apple.com/app/id$appId"));
//                                 }

//                                 // ignore: use_build_context_synchronously
//                                 if (context.mounted) {
//                                   await SharPreferences.setString(
//                                       'OpenAd', '1');
//                                   await Future.delayed(
//                                       Duration(milliseconds: 600));
//                                   return showDialog(
//                                       context: context,
//                                       builder: ((context) {
//                                         return AlertDialog(
//                                           content: SizedBox(
//                                             width: 400,
//                                             child: Column(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 ///NEW AD BANNER
//                                                 (controller.isPopupBannerAdLoaded
//                                                             .value &&
//                                                         controller
//                                                                 .popupBannerAd !=
//                                                             null &&
//                                                         controller
//                                                                 .adFree.value ==
//                                                             false)
//                                                     ? SizedBox(
//                                                         height: controller
//                                                             .popupBannerAd
//                                                             ?.size
//                                                             .height
//                                                             .toDouble(),
//                                                         width: controller
//                                                             .popupBannerAd
//                                                             ?.size
//                                                             .width
//                                                             .toDouble(),
//                                                         child: AdWidget(
//                                                             ad: controller
//                                                                 .popupBannerAd!),
//                                                       )
//                                                     : SizedBox(
//                                                         height: 150,
//                                                         child: Image.asset(
//                                                           Images
//                                                               .aboutPlaceHolder(
//                                                                   context),
//                                                           height: 150,
//                                                           width: 150,
//                                                           color: Colors.brown,
//                                                         ),
//                                                       ),
//                                                 const SizedBox(
//                                                   height: 20,
//                                                 ),
//                                                 const Divider(
//                                                   thickness: 2,
//                                                   color: Colors.brown,
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 20,
//                                                 ),
//                                                 const Text(
//                                                   "Copied Successfully!",
//                                                   style: TextStyle(
//                                                       letterSpacing: BibleInfo
//                                                           .letterSpacing,
//                                                       fontSize: BibleInfo
//                                                               .fontSizeScale *
//                                                           20,
//                                                       fontWeight:
//                                                           FontWeight.bold),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 20,
//                                                 ),
//                                                 SizedBox(
//                                                   height: 40,
//                                                   width: 150,
//                                                   child: ElevatedButton(
//                                                       style: ButtonStyle(
//                                                         backgroundColor:
//                                                             WidgetStateProperty
//                                                                 .all<
//                                                                         Color>(
//                                                                     const Color
//                                                                         .fromARGB(
//                                                                         255,
//                                                                         220,
//                                                                         220,
//                                                                         220)),
//                                                         shape: WidgetStateProperty
//                                                             .all<
//                                                                 RoundedRectangleBorder>(
//                                                           RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         8.0),
//                                                           ),
//                                                         ), // Add rounded corners
//                                                       ),
//                                                       onPressed: () async {
//                                                         Get.back();
//                                                         await SharPreferences
//                                                             .setString(
//                                                                 'OpenAd', '1');
//                                                         Provider.of<DownloadProvider>(
//                                                                 context,
//                                                                 listen: false)
//                                                             .incrementBookmarkCount(
//                                                                 context);
//                                                       },
//                                                       child: const Text(
//                                                         "Dismiss",
//                                                         style: TextStyle(
//                                                             letterSpacing:
//                                                                 BibleInfo
//                                                                     .letterSpacing,
//                                                             fontSize: BibleInfo
//                                                                     .fontSizeScale *
//                                                                 20,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             color:
//                                                                 Colors.black),
//                                                       )),
//                                                 )
//                                               ],
//                                             ),
//                                           ),
//                                         );
//                                       }));
//                                 }
//                               },
//                               child: Image(
//                                 image: const AssetImage(
//                                     "assets/lightMode/icons/copy.png"),
//                                 color: CommanColor.lightDarkPrimary(context),
//                                 height: screenWidth > 450 ? 60 : 50,
//                                 width: screenWidth > 450 ? 45 : 35,
//                               ),
//                             ),
//                             // const SizedBox(height: 10),
//                             Text(
//                               "Copy",
//                               style: TextStyle(
//                                   color: CommanColor.lightDarkPrimary(context),
//                                   letterSpacing: BibleInfo.letterSpacing,
//                                   fontSize:
//                                       BibleInfo.fontSizeScale * screenWidth >
//                                               450
//                                           ? 16
//                                           : 12,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                         screenWidth > 450
//                             ? const SizedBox(width: 20)
//                             : SizedBox(),
//                         Column(
//                           children: [
//                             GestureDetector(
//                               onTap: () async {
//                                 await SharPreferences.setString('OpenAd', '1');
//                                 selectedColor = null;
//                                 selectedindex = null;

//                                 await countprovider.decrementCount(context);
//                                 controller.changeRotation();
//                                 var data = VerseBookContentModel(
//                                     id: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .id,
//                                     bookNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .bookNum,
//                                     chapterNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .chapterNum,
//                                     verseNum: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .verseNum,
//                                     content: controller
//                                         .selectedBookContent[
//                                             int.parse(verNum.toString()) - 1]
//                                         .content,
//                                     isBookmarked: "no",
//                                     isHighlighted: "no",
//                                     isNoted: "no",
//                                     isUnderlined: "no",
//                                     isRead: controller
//                                         .selectedBookContent[int.parse(verNum.toString()) - 1]
//                                         .isRead);
//                                 controller.selectedBookContent[
//                                     int.parse(verNum.toString()) - 1] = data;
//                                 await DBHelper().updateVersesData(
//                                     int.parse(verseBookdata.id.toString()),
//                                     "is_bookmarked",
//                                     "no");
//                                 await DBHelper().updateVersesData(
//                                     int.parse(verseBookdata.id.toString()),
//                                     "is_noted",
//                                     "no");
//                                 await DBHelper().updateVersesData(
//                                     int.parse(verseBookdata.id.toString()),
//                                     "is_highlighted",
//                                     "no");
//                                 await DBHelper().updateVersesData(
//                                     int.parse(verseBookdata.id.toString()),
//                                     "is_underlined",
//                                     "no");
//                                 await DBHelper()
//                                     .deleteBookmarkByContent(
//                                         controller.printText.value.toString())
//                                     .then((value) {});
//                                 await DBHelper()
//                                     .deleteHighlightByContent(
//                                         controller.printText.value.toString())
//                                     .then((value) {});
//                                 await DBHelper()
//                                     .deleteNotesByContent(
//                                         controller.printText.value.toString())
//                                     .then((value) {});
//                                 await DBHelper()
//                                     .deleteUnderlineByContent(
//                                         controller.printText.value.toString())
//                                     .then((value) {});

//                                 await Future.delayed(
//                                   const Duration(milliseconds: 700),
//                                   () async {
//                                     //  Get.back();
//                                     await SharPreferences.setString(
//                                         'OpenAd', '1');
//                                     if (context.mounted) {
//                                       showDialog(
//                                           context: context,
//                                           builder: ((context) {
//                                             return AlertDialog(
//                                               content: SizedBox(
//                                                 width: 400,
//                                                 child: Column(
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     ///NEW AD BANNER
//                                                     (controller.isPopupBannerAdLoaded
//                                                                 .value &&
//                                                             controller
//                                                                     .popupBannerAd !=
//                                                                 null &&
//                                                             controller.adFree
//                                                                     .value ==
//                                                                 false)
//                                                         ? SizedBox(
//                                                             height: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .height
//                                                                 .toDouble(),
//                                                             width: controller
//                                                                 .popupBannerAd
//                                                                 ?.size
//                                                                 .width
//                                                                 .toDouble(),
//                                                             child: AdWidget(
//                                                                 ad: controller
//                                                                     .popupBannerAd!),
//                                                           )
//                                                         : SizedBox(
//                                                             height: 150,
//                                                             child: Image.asset(
//                                                               Images
//                                                                   .aboutPlaceHolder(
//                                                                       context),
//                                                               height: 150,
//                                                               width: 150,
//                                                               color:
//                                                                   Colors.brown,
//                                                             ),
//                                                           ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     const Divider(
//                                                       thickness: 2,
//                                                       color: Colors.brown,
//                                                     ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     const Text(
//                                                       "Reset Successfully!",
//                                                       style: TextStyle(
//                                                           letterSpacing:
//                                                               BibleInfo
//                                                                   .letterSpacing,
//                                                           fontSize: BibleInfo
//                                                                   .fontSizeScale *
//                                                               20,
//                                                           fontWeight:
//                                                               FontWeight.bold),
//                                                     ),
//                                                     const SizedBox(
//                                                       height: 20,
//                                                     ),
//                                                     SizedBox(
//                                                       height: 40,
//                                                       width: 150,
//                                                       child: ElevatedButton(
//                                                           style: ButtonStyle(
//                                                             backgroundColor:
//                                                                 WidgetStateProperty.all<
//                                                                         Color>(
//                                                                     const Color
//                                                                         .fromARGB(
//                                                                         255,
//                                                                         220,
//                                                                         220,
//                                                                         220)),
//                                                             shape: WidgetStateProperty
//                                                                 .all<
//                                                                     RoundedRectangleBorder>(
//                                                               RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             8.0),
//                                                               ),
//                                                             ), // Add rounded corners
//                                                           ),
//                                                           onPressed: () async {
//                                                             Get.back();
//                                                             await SharPreferences
//                                                                 .setString(
//                                                                     'OpenAd',
//                                                                     '1');
//                                                             Provider.of<DownloadProvider>(
//                                                                     context,
//                                                                     listen:
//                                                                         false)
//                                                                 .incrementBookmarkCount(
//                                                                     context);
//                                                           },
//                                                           child: const Text(
//                                                             "Dismiss",
//                                                             style: TextStyle(
//                                                                 letterSpacing:
//                                                                     BibleInfo
//                                                                         .letterSpacing,
//                                                                 fontSize: BibleInfo
//                                                                         .fontSizeScale *
//                                                                     20,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black),
//                                                           )),
//                                                     )
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           }));
//                                     }
//                                   },
//                                 );
//                               },
//                               child: Container(
//                                 height: screenWidth > 450 ? 45 : 35,
//                                 width: screenWidth > 450 ? 45 : 35,
//                                 margin:
//                                     const EdgeInsets.only(bottom: 8, top: 10),
//                                 decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(3),
//                                     // color: CommanColor.lightDarkPrimary(context),
//                                     border: Border.all(
//                                         color: CommanColor.lightDarkPrimary(
//                                             context),
//                                         width: 1.2)),
//                                 child: AnimatedRotation(
//                                     turns: controller.turns.value,
//                                     duration: const Duration(seconds: 1),
//                                     child: Icon(
//                                       Icons.sync,
//                                       color:
//                                           CommanColor.lightDarkPrimary(context),
//                                       size: 22,
//                                     )),
//                               ),
//                             ),
//                             Text(
//                               "Reset",
//                               style: TextStyle(
//                                   color: CommanColor.lightDarkPrimary(context),
//                                   letterSpacing: BibleInfo.letterSpacing,
//                                   fontSize:
//                                       BibleInfo.fontSizeScale * screenWidth >
//                                               450
//                                           ? 16
//                                           : 12,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                         screenWidth > 450
//                             ? const SizedBox(width: 20)
//                             : SizedBox(),
//                         Column(
//                           children: [
//                             GestureDetector(
//                               onTap: () async {
//                                 await SharPreferences.setString('OpenAd', '1');

//                                 final appPackageName =
//                                     (await PackageInfo.fromPlatform())
//                                         .packageName;
//                                 String message =
//                                     ''; // Declare the message variable outside the if-else block
//                                 String appid;
//                                 appid = BibleInfo.apple_AppId;
//                                 if (Platform.isAndroid) {
//                                   message =
//                                       "${controller.printText.value} \n\n${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum \n\nRead more at \nhttps://play.google.com/store/apps/details?id=$appPackageName";
//                                 } else if (Platform.isIOS) {
//                                   message =
//                                       "${controller.printText.value} \n\n${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum \n\nRead more at \nhttps://itunes.apple.com/app/id$appid"; // Example iTunes URL
//                                 }

//                                 if (message.isNotEmpty) {
//                                   Share.share(message,
//                                       sharePositionOrigin: Rect.fromPoints(
//                                           const Offset(2, 2),
//                                           const Offset(3, 3)));

//                                   await countprovider.decrementCount(context);
//                                 } else {
//                                   print('Message is empty or undefined');
//                                 }
//                               },
//                               child: Image(
//                                 image: const AssetImage(
//                                     "assets/lightMode/icons/share.png"),
//                                 color: CommanColor.lightDarkPrimary(context),
//                                 height: screenWidth > 450 ? 60 : 50,
//                                 width: screenWidth > 450 ? 45 : 35,
//                               ),
//                             ),
//                             Text(
//                               "Share",
//                               style: TextStyle(
//                                   color: CommanColor.lightDarkPrimary(context),
//                                   letterSpacing: BibleInfo.letterSpacing,
//                                   fontSize:
//                                       BibleInfo.fontSizeScale * screenWidth >
//                                               450
//                                           ? 16
//                                           : 12,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                 ],
//               ),
//             )),
//       );
//     }),
//   );
// }

Future<dynamic> homeContentEditBottomSheet(
  BuildContext context, {
  String? verNum,
  VerseBookContentModel? verseBookdata,
  required Function(DashBoardController) loadInterstitial,
  int? selectedColor,
  DashBoardController? controller,
  Function? callback,
  Function? callback2,
  int? clickcount,
}) async {
  return await Get.bottomSheet(
    barrierColor: Colors.black12,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    enableDrag: true,
    HomeContentEditBottomSheet(
      verNum: verNum,
      verseBookdata: verseBookdata,
      loadInterstitial: loadInterstitial,
      selectedColor: selectedColor,
      controller: controller,
      callback: callback,
      callback2: callback2,
      clickcount: clickcount,
    ),
  );
}

String normalizeHtml(String htmlContent) {
  final unescape = HtmlUnescape();
  final document = html_parser.parse(htmlContent);
  //final plainText = document.body?.text ?? htmlContent;
  final normalized =
      unescape.convert(document.body?.text ?? htmlContent).trim();
  return normalized.replaceAll("'", '').replaceAll('"', '');
  // return unescape.convert(plainText).trim().toLowerCase();
}

Future saveAndShare(Uint8List bytes, String imgname, String mesage,
    {BuildContext? context}) async {
  // Check and show rating dialog on first share if context is provided
  bool ratingShown = false;
  if (context != null) {
    ratingShown =
        await RatingDialogHelper.showRatingDialogOnFirstShare(context);
  }
  if (ratingShown) {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  final directory = await getApplicationDocumentsDirectory();
  final image = File("${directory.path}/$imgname.png");
  image.writeAsBytesSync(bytes);
  // Share the image using XFile
  final xFile = XFile(image.path);
  //await Share.shareXFiles([xFile]);
  await Share.shareXFiles([xFile],
      subject: 'Bible Book app',
      text: mesage,
      sharePositionOrigin:
          Rect.fromPoints(const Offset(2, 2), const Offset(3, 3)));
}

Future<bool> requestPermission([context]) async {
  if (Platform.isAndroid) {
    // final androidVersion = int.parse(androidInfo.version.release.split('.')[0]);
    // if (androidVersion >= 13) {
    //   var status = await Permission.photos.request();
    //   if (status.isGranted) return true;
    // } else {
    //   var status = await Permission.storage.request();
    //   if (status.isGranted) return true;
    // }
    // Constants.showToast("Storage permission is required to save images.");
    // return false;

    if (await Permission.storage.isGranted) return true;

    var status = await Permission.storage.request();

    if (status.isGranted) return true;

    Constants.showToast("Storage permission is required to save images.");
    return false;
  } else if (Platform.isIOS) {
    // var status = await Permission.photos.request();
    // if (status.isGranted) return true;

    // if (status.isPermanentlyDenied) {
    //   Constants.showToast("Enable photo access from Settings to save images.");
    //   //openAppSettings(); // Optional
    // } else {
    //   Constants.showToast("Photo access is needed to save images.");
    // }

    // return false;
    final status = await Permission.photos.status;
    debugPrint("Current iOS permission status: $status");
    if (status.isGranted) return true;

    final newStatus = await Permission.photos.request();
    debugPrint("New iOS permission status: $newStatus");

    if (newStatus.isGranted) return true;

    if (newStatus.isPermanentlyDenied) {
      // Constants.showToast("Photo access permanently denied. Go to Settings.");
      // openAppSettings();
      showPermissionSettingsDialog(context);
    } else {
      Constants.showToast("Photo access is required.");
    }
    return false;
  }
  return false;
}

void showPermissionSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text("Permission Required"),
      content: Text(
        "Please enable photo permissions in settings to use this feature.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Dismiss
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            openAppSettings(); // Opens settings
            Navigator.pop(context);
          },
          child: Text("Open Settings"),
        ),
      ],
    ),
  );
}

Future<String?> saveImage(Uint8List bytes, context) async {
  bool hasPermission = await requestPermission(context);
  if (!hasPermission) return null;

  final time = DateTime.now()
      .toIso8601String()
      .replaceAll(".", "_")
      .replaceAll(":", "_");
  final name = "Bible_$time";

  final result = await ImageGallerySaverPlus.saveImage(bytes, name: name);
  print(result["filePath"]);
  return result["filePath"];
}

Future<void> saveImageIntoLocal(Uint8List base64Image, context) async {
  bool hasPermission = await requestPermission(context);
  if (!hasPermission) return;

  try {
    final appPackageName = (await PackageInfo.fromPlatform()).packageName;
    await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(base64Image),
      name: "Image $appPackageName ${DateTime.now()}",
    );
    DBHelper().saveImage(SaveImageModel(imagePath: base64Encode(base64Image)));
    Constants.showToast("Image saved successfully");
  } catch (e) {
    log('Error: $e');
    Constants.showToast("Failed to save image");
  }
}

// Future<String> saveImage(Uint8List bytes) async {
//   await [Permission.storage].request();
//   final time = DateTime.now()
//       .toIso8601String()
//       .replaceAll(".", "_")
//       .replaceAll(":", "_");
//   final name = "Bible_$time";
//   final result = await ImageGallerySaverPlus.saveImage(bytes, name: name);
//   print(result["filePath"]);
//   return result["filePath"];
// }

// Future<void> saveImageIntoLocal(Uint8List base64Image) async {
//   try {
//     final appPackageName = (await PackageInfo.fromPlatform()).packageName;
//     await ImageGallerySaverPlus.saveImage(Uint8List.fromList(base64Image),
//         name: "Image $appPackageName ${DateTime.now()}");
//     DBHelper().saveImage(SaveImageModel(imagePath: base64Encode(base64Image)));
//     Constants.showToast("Image saved successfully");
//   } catch (e) {
//     log('Error: $e');
//     rethrow;
//   }
// }

Future<void> showGiftDialog2(
    BuildContext context, GetBookOfferData data) async {
  Future<void> launchURL({url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }

  Sizecf().init(context);
  await SharPreferences.setString('OpenAd', '1');
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Icon(
                      Icons.close_rounded,
                      size: Sizecf.blockSizeHorizontal! * 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: CommanColor.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close Button (Top Right)

                  Image.asset(
                    "assets/offer/firework.png", // Update with actual image path
                    width: Sizecf.scrnWidth! * 0.35,
                  ),

                  SizedBox(height: 10),

                  // Title
                  Text(
                    "Congratulations!",
                    style: TextStyle(
                      fontSize: Sizecf.blockSizeVertical! * 2.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 6),

                  // Subtitle
                  Text(
                    "You have a Gift!",
                    style: TextStyle(
                      fontSize: Sizecf.blockSizeVertical! * 1.9,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () async {
                      await launchURL(url: data.bookUrl);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        // showNotificationDialog(context);
                      }

                      // Navigate to Gift Page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF9B6B34), // Brown color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Continue",
                          style: TextStyle(
                              fontSize: Sizecf.blockSizeVertical! * 1.75,
                              color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Small Description
                  Text(
                    "You'll be redirected to the Gift page.",
                    style: TextStyle(
                        fontSize: Sizecf.blockSizeVertical! * 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool> showNotificationDialog(BuildContext context, onclick) async {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: CommanColor.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setString("alrt", "1");
                        final data = prefs.getString("notifiyalrt");
                        if (data != '1') {
                          await prefs.setString("notifiyalrt", '0');
                        }
                        Get.back();
                        onclick();
                        // Navigator.of(context).pushAndRemoveUntil(
                        //     MaterialPageRoute(builder: (context) {
                        //   return HomeScreen(
                        //       From: "splash",
                        //       selectedVerseNumForRead: "",
                        //       selectedBookForRead: "",
                        //       selectedChapterForRead: "",
                        //       selectedBookNameForRead: "",
                        //       selectedVerseForRead: "");
                        // }), (v) => false);
                      },
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: CommanColor.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/alarm.png',
                    height: 30,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 28),
                  // decoration: const BoxDecoration(
                  //     image: DecorationImage(
                  //         fit: BoxFit.fitWidth,
                  //         image: AssetImage('assets/promo.png'))),
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Set Your Sacred Time',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 17),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  "Spend a moment with God's Word each day. Choose your favorite time to receive His message and strengthen your faith.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: CommanColor.black),
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString("alrt", "1");
                    final data = prefs.getString("notifiyalrt");
                    if (data != '1') {
                      await prefs.setString("notifiyalrt", '0');
                    }
                    Get.to(() => SettingScreen(
                          notificationValue: true,
                        ));
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: CommanColor.darkPrimaryColor,
                    ),
                    child: Text(
                      'Go to Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: CommanColor.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
              ],
            ),
          ),
        );
      });

  return true;
}

Future<void> showGiftDialogclose(BuildContext context) async {
  Sizecf().init(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: CommanColor.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner Title
              Container(
                height: Sizecf.scrnHeight! * 0.055,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.transparent, // Brownish banner color
                    image: DecorationImage(
                        image: AssetImage('assets/offer/offerbanner.png'))),
                child: Center(
                  child: Text(
                    "⚠️ One-Time Offer!",
                    style: TextStyle(
                      fontSize: Sizecf.blockSizeVertical! * 2.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Description
              Text(
                "This special gift is available only once and cannot be accessed again inside the app. Are you sure you want to close this?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: Sizecf.blockSizeVertical! * 1.9,
                    color: Colors.black87),
              ),

              SizedBox(height: 16),

              // Share & Claim Gift Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle sharing functionality
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                          Sizecf.scrnWidth! * 0.35, Sizecf.scrnHeight! * 0.03),
                      backgroundColor: Color(0xFF9B6B34), // Brown button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      // padding:
                      //     EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    ),
                    label: Text(
                      "✅ Claim Gift",
                      style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Handle sharing functionality
                      // Navigator.of(context).pop();
                      // Navigator.of(context).pop();
                      Navigator.of(context)
                        ..pop()
                        ..pop();

                      // showNotificationDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(
                          Sizecf.scrnWidth! * 0.3, Sizecf.scrnHeight! * 0.03),
                      backgroundColor: Color(0xFF9B6B34), // Brown button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      // padding:
                      //     EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    ),
                    label: Text(
                      "❌ Close",
                      style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showGiftDialog(BuildContext context, GetBookOfferData data) async {
  Sizecf().init(context);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('offerDialogShown', true);
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  await SharPreferences.setString('OpenAd', '1');
                  showGiftDialogclose(context);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            fontSize: Sizecf.blockSizeVertical! * 1.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Icon(
                        Icons.close_rounded,
                        size: Sizecf.blockSizeHorizontal! * 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: CommanColor.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner Title
                    Container(
                      height: Sizecf.scrnHeight! * 0.06,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.transparent, // Brownish banner color
                          image: DecorationImage(
                              image:
                                  AssetImage('assets/offer/offerbanner.png'))),
                      child: Center(
                        child: Text(
                          "Welcome Gift for You!",
                          style: TextStyle(
                            fontSize: Sizecf.blockSizeVertical! * 2.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    CachedNetworkImage(
                      height: Sizecf.scrnWidth! * 0.45,
                      width: Sizecf.scrnWidth! * 0.35,
                      imageUrl: "${data.bookThumbURL}",
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                        child: CircularProgressIndicator.adaptive(
                            value: downloadProgress.progress),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                    // Gift Image
                    // Image.network(
                    //   "${data.bookThumbURL}", // Update with actual image path
                    //   width: Sizecf.scrnWidth! * 0.35,
                    // ),

                    SizedBox(height: 12),

                    // Description
                    Text(
                      "Share this app with friends and unlock a special free gift!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.9,
                          color: Colors.black87),
                    ),

                    SizedBox(height: 16),

                    // Share & Claim Gift Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Handle sharing functionality
                        await SharPreferences.setString('OpenAd', '1');
                        final appPackageName =
                            (await PackageInfo.fromPlatform()).packageName;
                        String message =
                            ''; // Declare the message variable outside the if-else block
                        String appid;
                        appid = BibleInfo.apple_AppId;
                        if (Platform.isAndroid) {
                          message =
                              "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://play.google.com/store/apps/details?id=$appPackageName";
                        } else if (Platform.isIOS) {
                          message =
                              "Hey, I've been using this Bible app that has transformed my daily Bible study experience. Try it now at : https://itunes.apple.com/app/id$appid"; // Example iTunes URL
                        }

                        if (message.isNotEmpty) {
                          // Check and show rating dialog on first share
                          await RatingDialogHelper.showRatingDialogOnFirstShare(
                              context);

                          Share.share(message,
                                  sharePositionOrigin: Rect.fromPoints(
                                      const Offset(2, 2), const Offset(3, 3)))
                              .then((v) {
                            if (context.mounted) {
                              showGiftDialog2(context, data);
                            }
                          });
                        } else {
                          debugPrint('Message is empty or undefined');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(Sizecf.scrnWidth! * 0.65,
                            Sizecf.scrnHeight! * 0.05),
                        backgroundColor:
                            Color(0xFF9B6B34), // Brown button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      icon: Image.asset(
                        'assets/offer/gift.png',
                        width: 25,
                        height: 25,
                      ),
                      label: Text(
                        "Share & Claim Gift",
                        style: TextStyle(
                            fontSize: Sizecf.blockSizeVertical! * 1.9,
                            color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PremiumAccessDialog extends StatelessWidget {
  const PremiumAccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Sizecf().init(context);
    final countprovider = Provider.of<DownloadProvider>(context, listen: false);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: CommanColor.white,
      insetPadding: screenWidth > 450
          ? EdgeInsets.symmetric(horizontal: 150)
          : null, // Approximate background
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                //  await countprovider.resetCount();
                await SharPreferences.setString("premium", 'yes');
                if (context.mounted) {
                  Get.back();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      " X ",
                      style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.7,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            Image.asset(
              "assets/dove.png",
              height: screenWidth > 450 ? 90 : 65,
              width: screenWidth > 450 ? 90 : 65,
            ),
            const SizedBox(height: 25),
            Text(
              "ONE-TIME\nPREMIUM ACCESS",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: screenWidth > 450 ? 25 : 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              "Enjoy a distraction-free Bible journey with no ads and full access to all features.",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: screenWidth > 450 ? 20 : 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "One secure payment — yours forever.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth > 450 ? 20 : 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await SharPreferences.setString("premium", 'yes');
                final countprovider =
                    Provider.of<DownloadProvider>(context, listen: false);
                await countprovider.resetCount();
                // Use constants as fallback when SharedPreferences are empty (first time loading)
                final sixMonthPlan =
                    await SharPreferences.getString('sixMonthPlan') ??
                        BibleInfo.sixMonthPlanid;
                final oneYearPlan =
                    await SharPreferences.getString('oneYearPlan') ??
                        BibleInfo.oneYearPlanid;
                final lifeTimePlan =
                    await SharPreferences.getString('lifeTimePlan') ??
                        BibleInfo.lifeTimePlanid;
                if (context.mounted) {
                  Navigator.pop(context);
                }

                Get.to(() => SubscriptionScreen(
                      sixMonthPlan: sixMonthPlan,
                      oneYearPlan: oneYearPlan,
                      lifeTimePlan: lifeTimePlan,
                      checkad: 'onboard',
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CommanColor.lightModePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text(
                'ACTIVATE PREMIUM ACCESS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: screenWidth > 450 ? 19 : 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No subscriptions. No renewals.\nLifetime access for current users.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth > 450 ? 19 : 14,
                color: CommanColor.black,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class AutoSizeHtmlWidget extends StatefulWidget {
  final String html;
  final int maxLines;
  final double maxFontSize;
  final double minFontSize;
  final Color? color;

  const AutoSizeHtmlWidget(
      {super.key,
      required this.html,
      this.maxLines = 3,
      this.maxFontSize = 31,
      this.minFontSize = 14,
      this.color});

  @override
  AutoSizeHtmlWidgetState createState() => AutoSizeHtmlWidgetState();
}

class AutoSizeHtmlWidgetState extends State<AutoSizeHtmlWidget> {
  double _currentFontSize = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the optimal font size
        _currentFontSize = _calculateOptimalFontSize(
          context,
          widget.html,
          constraints.maxWidth,
          widget.maxLines,
          widget.maxFontSize,
          widget.minFontSize,
        );

        return HtmlWidget(
          widget.html,
          textStyle: TextStyle(
            color: widget.color ?? Colors.black,
            fontSize: _currentFontSize,
          ),
        );
      },
    );
  }

  double _calculateOptimalFontSize(
    BuildContext context,
    String text,
    double maxWidth,
    int maxLines,
    double maxFontSize,
    double minFontSize,
  ) {
    final textSpan = TextSpan(
      text: _stripHtmlTags(text), // Helper to get plain text for measurement
      style: TextStyle(fontSize: maxFontSize),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);

    // If text fits at max font size, use that
    if (!textPainter.didExceedMaxLines) {
      return maxFontSize;
    }

    // Binary search for optimal font size
    double low = minFontSize;
    double high = maxFontSize;
    double currentSize = maxFontSize;

    while ((high - low) > 0.5) {
      currentSize = (low + high) / 2;

      final testSpan = TextSpan(
        text: _stripHtmlTags(text),
        style: TextStyle(fontSize: currentSize),
      );

      final testPainter = TextPainter(
        text: testSpan,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);

      if (testPainter.didExceedMaxLines) {
        high = currentSize;
      } else {
        low = currentSize;
      }
    }

    return currentSize;
  }

  String _stripHtmlTags(String html) {
    // Simple HTML tag stripper - adjust as needed
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class HomeContentEditBottomSheet extends StatefulWidget {
  final String? verNum;
  final VerseBookContentModel? verseBookdata;
  final Function(DashBoardController) loadInterstitial;
  final int? selectedColor;
  final DashBoardController? controller;
  final Function? callback;
  final Function? callback2;
  final int? clickcount;

  const HomeContentEditBottomSheet({
    super.key,
    this.verNum,
    this.verseBookdata,
    required this.loadInterstitial,
    this.selectedColor,
    this.controller,
    this.callback,
    this.callback2,
    this.clickcount,
  });

  @override
  HomeContentEditBottomSheetState createState() =>
      HomeContentEditBottomSheetState();
}

class HomeContentEditBottomSheetState
    extends State<HomeContentEditBottomSheet> {
  late DashBoardController controller;
  late VerseBookContentModel verseBookdata;
  bool isBookmarked = false;
  bool isUnderlined = false;
  String? datac;
  Color? selectedColor;
  int? selectedIndex;
  late double screenWidth;
  int? selectedindex;

  @override
  void initState() {
    super.initState();
    initializeValues();
  }

  void initializeValues() async {
    // Initialize color selection

    controller = widget.controller!;
    verseBookdata = widget.verseBookdata!;

    for (var i = 0; i < controller.colors.length; i++) {
      if (verseBookdata.isHighlighted ==
          controller.colors[i].toString().split("(").last.split(")").first) {
        controller.colorsCheack.value = i;
      }
    }

    controller.selectedColorOrNot.value =
        verseBookdata.isHighlighted.toString();
    isBookmarked = verseBookdata.isBookmarked == "yes";
    isUnderlined = verseBookdata.isUnderlined == "yes";
    final dat =
        await DBHelper().getColorByContent(widget.verseBookdata?.content);
    setState(() {
      datac = dat;
    });
    debugPrint("hg - $datac");
  }

  @override
  Widget build(BuildContext context) {
    bool alreadyhighly = false;
    screenWidth = MediaQuery.of(context).size.width;
    return StatefulBuilder(builder: (context, setState) {
      return Container(
        height: screenWidth < 380
            ? MediaQuery.of(context).size.height * 0.5
            : MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                height: 3,
                width: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: CommanColor.lightDarkPrimary(context),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${controller.selectedBook.value} ${controller.selectedChapter.value}:${widget.verNum}",
                    style: TextStyle(
                      color: CommanColor.lightDarkPrimary(context),
                      letterSpacing: BibleInfo.letterSpacing,
                      fontSize:
                          BibleInfo.fontSizeScale * screenWidth > 450 ? 25 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Row(
                  mainAxisAlignment: screenWidth > 450
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBookmarkButton(),
                    if (screenWidth > 450) const SizedBox(width: 20),
                    _buildNotesButton(),
                    if (screenWidth > 450) const SizedBox(width: 20),
                    _buildImageButton(),
                    if (screenWidth > 450) const SizedBox(width: 20),
                    _buildUnderlineButton(),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // _buildColorPalette(verseBookdata.content, datac, setState),
              Container(
                height: 50,
                width: double.infinity,
                alignment: Alignment.center,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.colors.value.length,
                  itemBuilder: (context, index) {
                    final int verseIndex =
                        int.parse(widget.verNum.toString()) - 1;
                    final verseData =
                        controller.selectedBookContent[verseIndex];

                    final bool isHighlightedColor =
                        verseData.isHighlighted != null &&
                            int.tryParse(verseData.isHighlighted!) != null &&
                            Color(int.parse(verseData.isHighlighted!)) ==
                                controller.colors[index];

                    final bool isSelected =
                        selectedColor != null && selectedindex == index;

                    alreadyhighly = Color(int.tryParse(datac ?? '0') ?? 0) ==
                        controller.colors[index];

                    final bool shouldShowCheckIcon =
                        (verseData.isHighlighted == "no" && isSelected) ||
                            isHighlightedColor ||
                            alreadyhighly;

                    return GestureDetector(
                        onTap: () async {
                          await SharPreferences.setString('OpenAd', '1');

                          final int indexVal = index;
                          final Color color = controller.colors[indexVal];
                          final String colorValueStr = color.value.toString();

                          setState(() {
                            selectedColor = color;
                            selectedindex = index;
                            alreadyhighly = false;
                            datac = null;
                          });

                          debugPrint('Set BG Color $colorValueStr');

                          final int verseIndex =
                              int.parse(widget.verNum.toString()) - 1;
                          final selectedVerse =
                              controller.selectedBookContent[verseIndex];

                          final bool isSameColor = (int.tryParse(
                                      verseBookdata.isHighlighted ?? '') ??
                                  0) ==
                              color.value;

                          final updatedVerse = selectedVerse.copyWith(
                            isHighlighted:
                                isSameColor ? "no" : color.value.toString(),
                          );

                          setState(() {
                            controller.selectedBookContent[verseIndex] =
                                updatedVerse;
                          });

                          controller.colorsCheack.value =
                              isSameColor ? -1 : indexVal;
                          controller.selectedColorOrNot.value =
                              isSameColor ? "no" : indexVal.toString();

                          await DBHelper().updateVersesData(
                            int.parse(verseBookdata.id.toString()),
                            "is_highlighted",
                            isSameColor ? "no" : color.value.toString(),
                          );

                          if (isSameColor) {
                            await DBHelper().deleteHighlightByContent(
                                controller.printText.value);
                            Constants.showToast(
                                'Removed from Highlight Successfully');
                            Get.back();
                            return;
                          }

                          await DBHelper().deleteHighlightByContent(
                              controller.printText.value);
                          final data =
                              normalizeHtml(controller.printText.value);
                          widget.callback?.call('0x00000000');
                          await Future.delayed(
                              const Duration(milliseconds: 300));

                          await DBHelper()
                              .insertIntoHighLight(
                            HighLightContentModal(
                              plain_content: data,
                              bookNum: int.parse(
                                  controller.selectedBookNum.value.toString()),
                              chapterNum: int.parse(
                                  controller.selectedChapter.value.toString()),
                              content: controller.printText.value,
                              bookName:
                                  controller.selectedBook.value.toString(),
                              color: color.value.toString(),
                              timestamp: DateTime.now().toString(),
                              verseNum: int.parse(widget.verNum.toString()),
                            ),
                          )
                              .whenComplete(() async {
                            Constants.showToast(
                              verseBookdata.isHighlighted == "no"
                                  ? "Added in Highlight Successfully"
                                  : "Updated in Highlight Successfully",
                            );
                            widget.callback?.call(color.value.toString());
                            await Future.delayed(
                                const Duration(milliseconds: 500));
                            Get.back();
                          }).catchError((e) {
                            debugPrint("Highlight insert failed: $e");
                          });
                        },
                        child:
                            // Builder(
                            //   builder: (context) {return
                            Container(
                          margin: const EdgeInsets.all(10),
                          width: 30,
                          height: 40,
                          decoration: BoxDecoration(
                            color: controller.colors[index],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: shouldShowCheckIcon
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: CommanColor.lightDarkPrimary(context),
                                )
                              : const SizedBox(),
                        ));
                    //   },

                    // GestureDetector(
                    //   onTap: () async {
                    //     setState(() {
                    //       alreadyhighly = false;
                    //     });
                    //     await SharPreferences.setString('OpenAd', '1');

                    //     final int indexVal = index;
                    //     final Color color = controller.colors[indexVal];
                    //     final String colorValueStr = color.value.toString();

                    //     selectedColor = color; // Color type
                    //     selectedindex = index;

                    //     debugPrint('Set BG Color $colorValueStr');

                    //     final int verseIndex =
                    //         int.parse(widget.verNum.toString()) - 1;
                    //     final selectedVerse =
                    //         controller.selectedBookContent[verseIndex];

                    //     final bool isSameColor =
                    //         (int.tryParse(verseBookdata.isHighlighted ?? '') ??
                    //                 0) ==
                    //             color.value;

                    //     final updatedVerse = selectedVerse.copyWith(
                    //       isHighlighted:
                    //           isSameColor ? "no" : color.value.toString(),
                    //     );

                    //     controller.selectedBookContent[verseIndex] =
                    //         updatedVerse;
                    //     controller.selectedBookContent
                    //         .refresh(); // ✅ force list update

                    //     controller.colorsCheack.value =
                    //         isSameColor ? -1 : indexVal;
                    //     controller.selectedColorOrNot.value =
                    //         isSameColor ? "no" : indexVal.toString();

                    //     await DBHelper().updateVersesData(
                    //       int.parse(verseBookdata.id.toString()),
                    //       "is_highlighted",
                    //       isSameColor ? "no" : color.value.toString(),
                    //     );

                    //     if (isSameColor) {
                    //       await DBHelper().deleteHighlightByContent(
                    //           controller.printText.value);
                    //       Constants.showToast(
                    //           'Removed from Highlight Successfully');
                    //       Get.back();
                    //       return;
                    //     }

                    //     await DBHelper().deleteHighlightByContent(
                    //         controller.printText.value);
                    //     final data = normalizeHtml(controller.printText.value);
                    //     widget.callback?.call('0x00000000'); // clear first
                    //     await Future.delayed(const Duration(milliseconds: 300));

                    //     await DBHelper()
                    //         .insertIntoHighLight(
                    //       HighLightContentModal(
                    //         plain_content: data,
                    //         bookNum: int.parse(
                    //             controller.selectedBookNum.value.toString()),
                    //         chapterNum: int.parse(
                    //             controller.selectedChapter.value.toString()),
                    //         content: controller.printText.value,
                    //         bookName: controller.selectedBook.value.toString(),
                    //         color: color.value.toString(),
                    //         timestamp: DateTime.now().toString(),
                    //         verseNum: int.parse(widget.verNum.toString()),
                    //       ),
                    //     )
                    //         .whenComplete(() async {
                    //       Constants.showToast(
                    //         verseBookdata.isHighlighted == "no"
                    //             ? "Added in Highlight Successfully"
                    //             : "Updated in Highlight Successfully",
                    //       );
                    //       widget.callback?.call(color.value.toString());
                    //       await Future.delayed(
                    //           const Duration(milliseconds: 500));
                    //       Get.back();
                    //     }).catchError((e) {
                    //       debugPrint("Highlight insert failed: $e");
                    //     });
                    //   },
                    //   child: Obx(() {
                    //     final verseData = controller.selectedBookContent[
                    //         int.parse(widget.verNum.toString()) - 1];

                    //     final bool isHighlightedColor =
                    //         verseData.isHighlighted != null &&
                    //             int.tryParse(verseData.isHighlighted!) !=
                    //                 null &&
                    //             Color(int.parse(verseData.isHighlighted!)) ==
                    //                 controller.colors[index];

                    //     final bool isSelected =
                    //         selectedColor != null && selectedindex == index;

                    //     // ✅ This condition is now included safely
                    //     final bool isSameAsStoredColor =
                    //         Color(int.tryParse(datac ?? '0') ?? 0) ==
                    //             controller.colors[index];

                    //     final bool shouldShowCheckIcon =
                    //         (verseData.isHighlighted == "no" && isSelected) ||
                    //             isHighlightedColor ||
                    //             isSameAsStoredColor;

                    //     return Container(
                    //       margin: const EdgeInsets.all(10),
                    //       width: 30,
                    //       height: 40,
                    //       decoration: BoxDecoration(
                    //         color: controller.colors[index],
                    //         borderRadius: BorderRadius.circular(2),
                    //       ),
                    //       child: shouldShowCheckIcon
                    //           ? Icon(
                    //               Icons.check_circle_rounded,
                    //               size: 20,
                    //               color: CommanColor.lightDarkPrimary(context),
                    //             )
                    //           : const SizedBox(),
                    //     );
                    //   }),
                    // );
                  },
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Row(
                  mainAxisAlignment: screenWidth > 450
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCopyButton(),
                    if (screenWidth > 450) const SizedBox(width: 20),
                    _buildResetButton(),
                    if (screenWidth > 450) const SizedBox(width: 20),
                    _buildShareButton(),
                    if (BibleInfo.chat == 1) ...[
                      if (screenWidth > 450) const SizedBox(width: 20),
                      _buildAskButton(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBookmarkButton() {
    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, _) {
        return Column(
          children: [
            GestureDetector(
              onTap: () async {
                //  DebugConsole.log("bookmark started");
                await SharPreferences.setString('OpenAd', '1');
                if (controller.adFree.value == false) {
                  final countProvider =
                      Provider.of<DownloadProvider>(context, listen: false);
                  await countProvider.decrementCount(context);
                }
                final int index = int.parse(widget.verNum.toString()) - 1;
                final originalData = controller.selectedBookContent[index];
                final isBookmarked = originalData.isBookmarked == "yes";

                final newData = originalData.copyWith(
                  isBookmarked: isBookmarked ? "no" : "yes",
                );

                controller.selectedBookContent[index] = newData;

                final bookmarkModel = BookMarkModel(
                  bookNum:
                      int.parse(controller.selectedBookNum.value.toString()),
                  chapterNum:
                      int.parse(controller.selectedChapter.value.toString()),
                  content: controller.printText.value.toString(),
                  plaincontent: originalData.id.toString(),
                  bookName: controller.selectedBook.value.toString(),
                  timestamp: DateTime.now().toString(),
                  verseNum: int.parse(widget.verNum.toString()),
                );

                await bookmarkProvider.toggleBookmark(
                  verseData: originalData,
                  verseId: int.parse(originalData.id.toString()),
                  content: controller.printText.value.toString(),
                  showDialog: _showSuccessDialog,
                  bookmarkModel: bookmarkModel,
                  updateVerseCallback: (updated) {
                    controller.selectedBookContent[index] = updated;
                  },
                );
              },
              child: controller
                          .selectedBookContent[
                              int.parse(widget.verNum.toString()) - 1]
                          .isBookmarked ==
                      "yes"
                  ? Image.asset(
                      "assets/Bookmark icons/cloud-fog2-fill.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    )
                  : Image.asset(
                      "assets/Bookmark icons/cloud-fog2-fill-1.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              "Bookmark",
              style: TextStyle(
                letterSpacing: BibleInfo.letterSpacing,
                fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
                fontWeight: FontWeight.bold,
                color: CommanColor.lightDarkPrimary(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnderlineButton() {
    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, _) {
        return Column(
          children: [
            GestureDetector(
              onTap: () async {
                // DebugConsole.log("underline started");

                await SharPreferences.setString('OpenAd', '1');
                if (controller.adFree.value == false) {
                  final countProvider =
                      Provider.of<DownloadProvider>(context, listen: false);
                  await countProvider.decrementCount(context);
                }

                int index = int.parse(widget.verNum.toString()) - 1;
                final originalData = controller.selectedBookContent[index];
                final isUnderlined = originalData.isUnderlined == "yes";

                final updatedData = originalData.copyWith(
                  isUnderlined: isUnderlined ? "no" : "yes",
                );

                controller.selectedBookContent[index] = updatedData;

                final underlineModel = BookMarkModel(
                  bookNum:
                      int.parse(controller.selectedBookNum.value.toString()),
                  chapterNum:
                      int.parse(controller.selectedChapter.value.toString()),
                  content: controller.printText.value,
                  plaincontent: originalData.id.toString(),
                  bookName: controller.selectedBook.value,
                  timestamp: DateTime.now().toString(),
                  verseNum: int.parse(widget.verNum.toString()),
                );

                await bookmarkProvider.toggleUnderline(
                  verseData: originalData,
                  verseId: int.parse(originalData.id.toString()),
                  content: controller.printText.value,
                  underlineModel: underlineModel,
                  showDialog: _showSuccessDialog,
                  updateVerseCallback: (updated) {
                    controller.selectedBookContent[index] = updated;
                  },
                );
              },
              child: controller
                          .selectedBookContent[
                              int.parse(widget.verNum.toString()) - 1]
                          .isUnderlined ==
                      "yes"
                  ? Image.asset(
                      "assets/Bookmark icons/cloud-fog2-fill-2.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    )
                  : Image.asset(
                      "assets/Bookmark icons/cloud-fog2-fill-3.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              "Underline",
              style: TextStyle(
                letterSpacing: BibleInfo.letterSpacing,
                fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
                fontWeight: FontWeight.bold,
                color: CommanColor.lightDarkPrimary(context),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget _buildBookmarkButton() {
  //   return Column(
  //     children: [
  //       GestureDetector(
  //         onTap: () async {
  //           DebugConsole.log("bookmark started");
  //           await SharPreferences.setString('OpenAd', '1');
  //           final countprovider =
  //               Provider.of<DownloadProvider>(context, listen: false);
  //           await countprovider.decrementCount(context);

  //           bool isCurrentlyBookmarked = verseBookdata.isBookmarked == "yes";

  //           var data = VerseBookContentModel(
  //             id: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .id,
  //             bookNum: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .bookNum,
  //             chapterNum: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .chapterNum,
  //             verseNum: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .verseNum,
  //             content: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .content,
  //             isBookmarked: isCurrentlyBookmarked ? "no" : "yes",
  //             isHighlighted: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .isHighlighted,
  //             isNoted: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .isNoted,
  //             isUnderlined: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .isUnderlined,
  //             isRead: controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
  //                 .isRead,
  //           );

  //           setState(() {
  //             controller.selectedBookContent[
  //                 int.parse(widget.verNum.toString()) - 1] = data;
  //             isBookmarked = !isCurrentlyBookmarked;
  //           });

  //           if (isCurrentlyBookmarked) {
  //             await _removeBookmark();
  //             setState(() {
  //               isBookmarked = false;
  //             });
  //           } else {
  //             await _addBookmark();
  //             setState(() {
  //               isBookmarked = true;
  //             });
  //           }
  //         },
  //         child: isBookmarked
  //             ? Image.asset(
  //                 "assets/lightMode/icons/bookmark1.png",
  //                 height: screenWidth > 450 ? 60 : 50,
  //                 width: screenWidth > 450 ? 45 : 35,
  //               )
  //             : Image.asset(
  //                 "assets/lightMode/icons/bookmark.png",
  //                 height: screenWidth > 450 ? 60 : 50,
  //                 width: screenWidth > 450 ? 45 : 35,
  //               ),
  //       ),
  //       const SizedBox(height: 10),
  //       Text(
  //         "Bookmark",
  //         style: TextStyle(
  //           letterSpacing: BibleInfo.letterSpacing,
  //           fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
  //           fontWeight: FontWeight.bold,
  //           color: CommanColor.lightDarkPrimary(context),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Future<void> _removeBookmark() async {
  //   await DBHelper().updateVersesData(
  //     int.parse(verseBookdata.id.toString()),
  //     "is_bookmarked",
  //     "no",
  //   );

  //   await DBHelper().deleteBookmarkByContent(
  //     controller.printText.value.toString(),
  //   );
  //   initializeValues();
  //   await _showSuccessDialog("Removed Successfully!");
  // }

  // Future<void> _addBookmark() async {
  //   await DBHelper().updateVersesData(
  //     int.parse(verseBookdata.id.toString()),
  //     "is_bookmarked",
  //     "yes",
  //   );

  //   await DBHelper().insertBookmark(
  //     BookMarkModel(
  //       bookNum: int.parse(controller.selectedBookNum.value.toString()),
  //       chapterNum: int.parse(controller.selectedChapter.value.toString()),
  //       content: controller.printText.value.toString(),
  //       plaincontent: verseBookdata.id.toString(),
  //       bookName: controller.selectedBook.value.toString(),
  //       timestamp: DateTime.now().toString(),
  //       verseNum: int.parse(widget.verNum.toString()),
  //     ),
  //   );
  //   initializeValues();
  //   await _showSuccessDialog("Marked Successfully!");
  // }

  Widget _buildNotesButton() {
    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, child) {
        return GestureDetector(
          onTap: () async {
            await SharPreferences.setString('OpenAd', '1');
            if (controller
                    .selectedBookContent[
                        int.parse(widget.verNum.toString()) - 1]
                    .isNoted !=
                "no") {
              controller.notesController.value.text = controller
                  .selectedBookContent[int.parse(widget.verNum.toString()) - 1]
                  .isNoted
                  .toString();
            } else {
              controller.notesController.value.text = "";
            }
            await _showNotesBottomSheet();
          },
          child: Column(
            children: [
              controller
                          .selectedBookContent[
                              int.parse(widget.verNum.toString()) - 1]
                          .isNoted ==
                      "no"
                  ? Image.asset(
                      "assets/Bookmark icons/stickynote.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    )
                  : Image.asset(
                      "assets/Bookmark icons/stickynote-1.png",
                      height: screenWidth > 450 ? 60 : 50,
                      width: screenWidth > 450 ? 45 : 35,
                    ),
              const SizedBox(height: 10),
              Text(
                "Notes",
                style: TextStyle(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize:
                      BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
                  fontWeight: FontWeight.bold,
                  color: CommanColor.lightDarkPrimary(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotesBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Account for keyboard
            ),
            child: NotesBottomSheet(
              controller: controller,
              verNum: widget.verNum,
              verseBookdata: verseBookdata,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await SharPreferences.setString('OpenAd', '1');
            await _showImageBottomSheet();
          },
          child: Image.asset(
            "assets/Bookmark icons/gallery-add.png",
            height: screenWidth > 450 ? 60 : 50,
            width: screenWidth > 450 ? 45 : 35,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Image",
          style: TextStyle(
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
            fontWeight: FontWeight.bold,
            color: CommanColor.lightDarkPrimary(context),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageBottomSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return ImageBottomSheet(controller: controller);
      },
    );
  }

  // Widget _buildColorPalette(content, data) {
  //   return StatefulBuilder(
  //     builder: (context, setState) {
  //       // Move the highlightedColorIndex inside StatefulBuilder to maintain state
  //       int? highlightedColorIndex;

  //       // Set the index initially based on saved `data`
  //       if (data != null) {
  //         final restoredIndex = controller.colors.indexWhere(
  //           (color) => color == Color(int.parse(data)),
  //         );
  //         if (restoredIndex != -1) {
  //           highlightedColorIndex = restoredIndex;
  //         }
  //       }

  //       return Container(
  //         height: 50,
  //         width: double.infinity,
  //         alignment: Alignment.center,
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           scrollDirection: Axis.horizontal,
  //           itemCount: controller.colors.value.length,
  //           itemBuilder: (context, index) {
  //             final Color currentColor = controller.colors[index];
  //             final bool isHighlighted = highlightedColorIndex == index;

  //             return GestureDetector(
  //               onTap: () async {
  //                 await SharPreferences.setString('OpenAd', '1');
  //                 await _handleColorSelection(index, verseBookdata.id);

  //                 final int verseIndex =
  //                     int.parse(widget.verNum.toString()) - 1;

  //                 final String newColorValue = currentColor.value.toString();

  //                 controller.selectedBookContent[verseIndex] =
  //                     controller.selectedBookContent[verseIndex].copyWith(
  //                   isHighlighted: newColorValue,
  //                 );

  //                 selectedIndex = index;
  //                 selectedColor = currentColor;

  //                 // Update the highlighted index
  //                 setState(() {
  //                   highlightedColorIndex = index;
  //                 });
  //               },
  //               child: Container(
  //                 margin: const EdgeInsets.all(10),
  //                 width: 30,
  //                 height: 40,
  //                 decoration: BoxDecoration(
  //                   color: currentColor,
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //                 child: isHighlighted
  //                     ? Icon(
  //                         Icons.check_circle_rounded,
  //                         size: 20,
  //                         color: CommanColor.lightDarkPrimary(context),
  //                       )
  //                     : const SizedBox(),
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildColorPalette(content, data, setStates) {
    bool isDataMatch = false;
    bool isHighlightedColor = false;
    bool shouldShowCheck = false;
    bool fnselect = false;
    String newColorValue = '';
    return Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.center,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: controller.colors.value.length,
        itemBuilder: (context, index) {
          final verseData = controller
              .selectedBookContent[int.parse(widget.verNum.toString()) - 1];
          final Color currentColor = controller.colors[index];
          // Check highlight states
          isHighlightedColor = verseData.isHighlighted != null &&
              int.tryParse(verseData.isHighlighted!) != null &&
              Color(int.parse(verseData.isHighlighted!)) == currentColor;
          isDataMatch = data != null && Color(int.parse(data)) == currentColor;
          final bool isSelected = selectedIndex == index;

          shouldShowCheck = isSelected || isHighlightedColor;

          return GestureDetector(
            onTap: () async {
              await SharPreferences.setString('OpenAd', '1');
              // Update state immediately

              await _handleColorSelection(index, verseBookdata.id);

              final int verseIndex = int.parse(widget.verNum.toString()) - 1;
              newColorValue = currentColor.value.toString();

              controller.selectedBookContent[verseIndex] =
                  controller.selectedBookContent[verseIndex].copyWith(
                isHighlighted: newColorValue,
              );
              setState(() {
                selectedIndex = index;
                selectedColor = currentColor;
                isDataMatch = false;
                isHighlightedColor = false;
                fnselect = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              width: 30,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: shouldShowCheck && !fnselect
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: CommanColor.lightDarkPrimary(context),
                    )
                  : isDataMatch && !fnselect
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: CommanColor.lightDarkPrimary(context),
                        )
                      : const SizedBox(),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildColorPalette(content, data, setState) {
  //   bool fnselected = false;
  //   // return
  //   // StatefulBuilder(builder: (context, setState) {

  //   return Container(
  //     height: 50,
  //     width: double.infinity,
  //     alignment: Alignment.center,
  //     child: ListView.builder(
  //       shrinkWrap: true,
  //       scrollDirection: Axis.horizontal,
  //       itemCount: controller.colors.value.length,
  //       itemBuilder: (context, index) {
  //         return GestureDetector(
  //           onTap: () async {
  //             await SharPreferences.setString('OpenAd', '1');
  //             // Update the state immediately before the async operations
  //             setState(() {
  //               selectedIndex = index;
  //               selectedColor = controller.colors[index];
  //               fnselected = true;
  //             });

  //             await _handleColorSelection(index, verseBookdata.id);

  //             final int verseIndex = int.parse(widget.verNum.toString()) - 1;
  //             final String newColorValue =
  //                 controller.colors[index].value.toString();

  //             controller.selectedBookContent[verseIndex] =
  //                 controller.selectedBookContent[verseIndex].copyWith(
  //               isHighlighted: newColorValue,
  //             );
  //           },
  //           child: Obx(() {
  //             final verseData = controller
  //                 .selectedBookContent[int.parse(widget.verNum.toString()) - 1];

  //             final Color currentColor = controller.colors[index];
  //             // Check if this is the currently selected index (immediate feedback)
  //             final bool isSelected = selectedIndex == index;
  //             // Or if it matches the stored value
  //             final bool isHighlightedColor = verseData.isHighlighted != null &&
  //                 int.tryParse(verseData.isHighlighted!) != null &&
  //                 Color(int.parse(verseData.isHighlighted!)) == currentColor;
  //             final bool isDataMatch =
  //                 data != null && Color(int.parse(data)) == currentColor;

  //             final bool shouldShowCheck =
  //                 isSelected || isHighlightedColor || isDataMatch;

  //             return Container(
  //               margin: const EdgeInsets.all(10),
  //               width: 30,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: currentColor,
  //                 borderRadius: BorderRadius.circular(2),
  //               ),
  //               child: fnselected == true
  //                   ? Icon(
  //                       Icons.check_circle_rounded,
  //                       size: 20,
  //                       color: CommanColor.lightDarkPrimary(context),
  //                     )
  //                   : fnselected == false && shouldShowCheck
  //                       ? Icon(
  //                           Icons.check_circle_rounded,
  //                           size: 20,
  //                           color: CommanColor.lightDarkPrimary(context),
  //                         )
  //                       : const SizedBox(),
  //             );
  //           }),
  //         );
  //       },
  //     ),
  //   );
  //   // });
  // }

  // Widget _buildColorPalette(content, data) {
  //   return StatefulBuilder(builder: (context, setState) {
  //     return Container(
  //       height: 50,
  //       width: double.infinity,
  //       alignment: Alignment.center,
  //       child: ListView.builder(
  //         shrinkWrap: true,
  //         scrollDirection: Axis.horizontal,
  //         itemCount: controller.colors.value.length,
  //         itemBuilder: (context, index) {
  //           return GestureDetector(
  //             onTap: () async {
  //               await SharPreferences.setString('OpenAd', '1');
  //               await _handleColorSelection(index, verseBookdata.id);

  //               final int verseIndex = int.parse(widget.verNum.toString()) - 1;

  //               final String newColorValue =
  //                   controller.colors[index].value.toString();

  //               controller.selectedBookContent[verseIndex] =
  //                   controller.selectedBookContent[verseIndex].copyWith(
  //                 isHighlighted: newColorValue,
  //               );

  //               selectedIndex = index;
  //               selectedColor = controller.colors[index];
  //               setState(() {});
  //             },
  //             child: Obx(() {
  //               final verseData = controller.selectedBookContent[
  //                   int.parse(widget.verNum.toString()) - 1];

  //               final Color currentColor = controller.colors[index];
  //               final bool isHighlightedColor = verseData.isHighlighted !=
  //                       null &&
  //                   int.tryParse(verseData.isHighlighted!) != null &&
  //                   Color(int.parse(verseData.isHighlighted!)) == currentColor;

  //               final bool isDataMatch =
  //                   data != null && Color(int.parse(data)) == currentColor;

  //               final bool shouldShowCheck = isHighlightedColor || isDataMatch;

  //               debugPrint("hg - $data  $isHighlightedColor $shouldShowCheck");

  //               return Container(
  //                 margin: const EdgeInsets.all(10),
  //                 width: 30,
  //                 height: 40,
  //                 decoration: BoxDecoration(
  //                   color: currentColor,
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //                 child: shouldShowCheck
  //                     ? Icon(
  //                         Icons.check_circle_rounded,
  //                         size: 20,
  //                         color: CommanColor.lightDarkPrimary(context),
  //                       )
  //                     : const SizedBox(),
  //               );
  //             }),
  //           );
  //         },
  //       ),
  //     );
  //   });
  // }

  Future<void> _handleColorSelection(int index, verseid) async {
    final int indexVal = index;
    final Color color = controller.colors[indexVal];
    final String colorValueStr = color.value.toString();

    setState(() {
      selectedColor = color;
      selectedIndex = index;
    });

    debugPrint('Set BG Color $colorValueStr');

    final int verseIndex = int.parse(widget.verNum.toString()) - 1;
    final selectedVerse = controller.selectedBookContent[verseIndex];
    final bool isSameColor =
        (int.tryParse(verseBookdata.isHighlighted ?? '') ?? 0) == color.value;

    final updatedVerse = selectedVerse.copyWith(
      isHighlighted: isSameColor ? "no" : color.value.toString(),
    );

    setState(() {
      controller.selectedBookContent[verseIndex] = updatedVerse;
      controller.colorsCheack.value = isSameColor ? -1 : indexVal;
      controller.selectedColorOrNot.value =
          isSameColor ? "no" : indexVal.toString();
    });

    await DBHelper().updateVersesData(
      int.parse(verseBookdata.id.toString()),
      "is_highlighted",
      isSameColor ? "no" : color.value.toString(),
    );

    if (isSameColor) {
      await DBHelper().deleteHighlightByContent(controller.printText.value);
      Constants.showToast('Removed from Highlight Successfully');
      if (mounted) Navigator.pop(context);
      return;
    }

    await DBHelper().deleteHighlightByContent(controller.printText.value);
    final data = normalizeHtml(controller.printText.value);
    widget.callback?.call('0x00000000'); // clear first
    await Future.delayed(const Duration(milliseconds: 300));

    await DBHelper()
        .insertIntoHighLight(
      HighLightContentModal(
        plain_content: data,
        verseid: verseid.toString() ?? '',
        bookNum: int.parse(controller.selectedBookNum.value.toString()),
        chapterNum: int.parse(controller.selectedChapter.value.toString()),
        content: controller.printText.value,
        bookName: controller.selectedBook.value.toString(),
        color: color.value.toString(),
        timestamp: DateTime.now().toString(),
        verseNum: int.parse(widget.verNum.toString()),
      ),
    )
        .whenComplete(() async {
      Constants.showToast(
        verseBookdata.isHighlighted == "no"
            ? "Added in Highlight Successfully"
            : "Updated in Highlight Successfully",
      );
      widget.callback?.call(color.value.toString());
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }).catchError((e) {
      debugPrint("Highlight insert failed: $e");
    });
  }

  Widget _buildCopyButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await SharPreferences.setString('OpenAd', '1');
            if (controller.adFree.value == false) {
              final countprovider =
                  Provider.of<DownloadProvider>(context, listen: false);
              await countprovider.decrementCount(context);
            }
            String appId = BibleInfo.apple_AppId;
            final appPackageName =
                (await PackageInfo.fromPlatform()).packageName;

            if (Platform.isAndroid) {
              await Clipboard.setData(ClipboardData(
                text:
                    "${controller.printText.value.toString()} \n${controller.selectedBook.value} ${controller.selectedChapter.value}:${widget.verNum} \n\n Read more at  \n\nhttps://play.google.com/store/apps/details?id=$appPackageName",
              ));
            } else if (Platform.isIOS) {
              await Clipboard.setData(ClipboardData(
                text:
                    "${controller.printText.value.toString()} \n${controller.selectedBook.value} ${controller.selectedChapter.value}:${widget.verNum} \n\n Read more at  \n\nhttps://itunes.apple.com/app/id$appId",
              ));
            }

            await _showSuccessDialog("Copied Successfully!");
          },
          child: Image(
            image: const AssetImage("assets/Bookmark icons/Frame 3630.png"),
            color: CommanColor.lightDarkPrimary(context),
            height: screenWidth > 450 ? 60 : 50,
            width: screenWidth > 450 ? 45 : 35,
          ),
        ),
        Text(
          "Copy",
          style: TextStyle(
            color: CommanColor.lightDarkPrimary(context),
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, child) {
        return Column(
          children: [
            GestureDetector(
              onTap: () async {
                await SharPreferences.setString('OpenAd', '1');
                if (controller.adFree.value == false) {
                  final countprovider =
                      Provider.of<DownloadProvider>(context, listen: false);
                  await countprovider.decrementCount(context);
                }
                // Create reset data
                var data = VerseBookContentModel(
                  id: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .id,
                  bookNum: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .bookNum,
                  chapterNum: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .chapterNum,
                  verseNum: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .verseNum,
                  content: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .content,
                  isBookmarked: "no",
                  isHighlighted: "no",
                  isNoted: "no",
                  isUnderlined: "no",
                  isRead: controller
                      .selectedBookContent[
                          int.parse(widget.verNum.toString()) - 1]
                      .isRead,
                );

                // Update local state
                setState(() {
                  selectedColor = null;
                  selectedIndex = null;
                  controller.changeRotation();
                  bookmarkProvider.setIsBookmarked = false;
                  bookmarkProvider.setIsNoted = false;
                  controller.selectedBookContent[
                      int.parse(widget.verNum.toString()) - 1] = data;
                });

                // Reset in database
                await bookmarkProvider.resetVerseAttributes(
                  verseId: int.parse(verseBookdata.id.toString()),
                  content: controller.printText.value.toString(),
                  updateVerseCallback: (updated) {
                    controller.selectedBookContent[
                        int.parse(widget.verNum.toString()) - 1] = updated;
                  },
                );

                initializeValues();
                await _showSuccessDialog("Reset Successfully!");
              },
              child: Image(
                image: const AssetImage(
                    "assets/Bookmark icons/arrow-refresh-03.png"),
                color: CommanColor.lightDarkPrimary(context),
                height: screenWidth > 450 ? 60 : 50,
                width: screenWidth > 450 ? 45 : 35,
              ),
            ),
            Text(
              "Reset",
              style: TextStyle(
                color: CommanColor.lightDarkPrimary(context),
                letterSpacing: BibleInfo.letterSpacing,
                fontSize:
                    BibleInfo.fontSizeScale * (screenWidth > 450 ? 16 : 12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await SharPreferences.setString('OpenAd', '1');
            if (controller.adFree.value == false) {
              final countprovider =
                  Provider.of<DownloadProvider>(context, listen: false);
              await countprovider.decrementCount(context);
            }
            final appPackageName =
                (await PackageInfo.fromPlatform()).packageName;
            String message = '';
            String appid = BibleInfo.apple_AppId;

            if (Platform.isAndroid) {
              message =
                  "${controller.printText.value} \n\n${controller.selectedBook.value} ${controller.selectedChapter.value}:${widget.verNum} \n\nRead more at \nhttps://play.google.com/store/apps/details?id=$appPackageName";
            } else if (Platform.isIOS) {
              message =
                  "${controller.printText.value} \n\n${controller.selectedBook.value} ${controller.selectedChapter.value}:${widget.verNum} \n\nRead more at \nhttps://itunes.apple.com/app/id$appid";
            }

            if (message.isNotEmpty) {
              // Check and show rating dialog on first share
              await RatingDialogHelper.showRatingDialogOnFirstShare(context);

              Share.share(
                message,
                sharePositionOrigin: Rect.fromPoints(
                  const Offset(2, 2),
                  const Offset(3, 3),
                ),
              );
              // Track Share event
              StatsigService.trackShare();
            }
          },
          child: Image(
            image: const AssetImage("assets/Bookmark icons/ShareNetwork.png"),
            color: CommanColor.lightDarkPrimary(context),
            height: screenWidth > 450 ? 60 : 50,
            width: screenWidth > 450 ? 45 : 35,
          ),
        ),
        Text(
          "Share",
          style: TextStyle(
            color: CommanColor.lightDarkPrimary(context),
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAskButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Close the bottom sheet
            Navigator.pop(context);
            // Navigate to chat screen with verse context
            Get.to(
              () => ChatScreen(
                verseContext: {
                  'verseText': controller.printText.value,
                  'book': controller.selectedBook.value,
                  'chapter': controller.selectedChapter.value.toString(),
                  'verse': widget.verNum.toString(),
                },
              ),
              transition: Transition.cupertinoDialog,
              duration: const Duration(milliseconds: 300),
            );
          },
          child: Image(
            image: AssetImage(
              Provider.of<ThemeProvider>(context, listen: false).themeMode ==
                      ThemeMode.dark
                  ? "assets/Chat white.png"
                  : "assets/Chat icon.png",
            ),
            height: screenWidth > 450 ? 60 : 50,
            width: screenWidth > 450 ? 45 : 35,
            fit: BoxFit.contain,
          ),
        ),
        Text(
          "Ask",
          style: TextStyle(
            color: CommanColor.lightDarkPrimary(context),
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * screenWidth > 450 ? 16 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _showSuccessDialog(String message) async {
    await SharPreferences.setString('OpenAd', '1');
    await Future.delayed(Duration(milliseconds: 600));

    if (!mounted) return;

    // Check if user is subscribed (premium user)
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final subscriptionPlan = await downloadProvider.getSubscriptionPlan();
    final isSubscribed = subscriptionPlan != null &&
        subscriptionPlan.isNotEmpty &&
        ['platinum', 'gold', 'silver'].contains(subscriptionPlan.toLowerCase());

    // For subscribed users, show toast instead of alert dialog
    if (isSubscribed) {
      return Constants.showToast(message);
    }

    if (controller.adFree.value == true) {
      return Constants.showToast(message);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CommanColor.white,
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                (controller.isPopupBannerAdLoaded.value &&
                        controller.popupBannerAd != null &&
                        controller.adFree.value == false)
                    ? Builder(
                        builder: (context) {
                          try {
                            final ad = controller.popupBannerAd!;
                            // Check if ad has valid size (indicates it's loaded)
                            if (ad.size.width > 0 && ad.size.height > 0) {
                              return SizedBox(
                                height: ad.size.height.toDouble(),
                                width: ad.size.width.toDouble(),
                                child: AdWidget(ad: ad),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error displaying ad: $e');
                          }
                          return SizedBox(
                            height: 150,
                            child: Image.asset(
                              "assets/star.png",
                              height: 150,
                              width: 150,
                              color: Colors.brown,
                            ),
                          );
                        },
                      )
                    : SizedBox(
                        height: 150,
                        child: Image.asset(
                          "assets/star.png",
                          height: 150,
                          width: 150,
                          color: Colors.brown,
                        ),
                      ),
                const SizedBox(height: 20),
                const Divider(thickness: 2, color: Colors.brown),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale * 20,
                    fontWeight: FontWeight.w600,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await SharPreferences.setString('OpenAd', '1');
                      if (controller.adFree.value == false) {
                        Provider.of<DownloadProvider>(context, listen: false)
                            .incrementBookmarkCount(context);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        const Color.fromARGB(255, 220, 220, 220),
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    child: const Text(
                      "Dismiss",
                      style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper widgets for the bottom sheets
class NotesBottomSheet extends StatelessWidget {
  final DashBoardController controller;
  final String? verNum;
  final VerseBookContentModel? verseBookdata;

  const NotesBottomSheet({
    super.key,
    required this.controller,
    this.verNum,
    this.verseBookdata,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 15, right: 15, top: 5, bottom: 20,
        // bottom: MediaQuery.of(context)
        //     .viewInsets
        //     .bottom, // Additional padding for keyboard
      ),
      child: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              height: 3,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Provider.of<ThemeProvider>(context, listen: false)
                            .themeMode ==
                        ThemeMode.dark
                    ? CommanColor.darkPrimaryColor
                    : CommanColor.lightModePrimary,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              controller.printText.value,
              style: const TextStyle(
                color: Colors.black,
                letterSpacing: BibleInfo.letterSpacing,
                fontSize: BibleInfo.fontSizeScale * 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "${controller.selectedBook.value} ${controller.selectedChapter.value}:$verNum",
                  style: const TextStyle(
                    color: Colors.black,
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale * 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              controller: controller.notesController.value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                letterSpacing: BibleInfo.letterSpacing,
                fontSize: BibleInfo.fontSizeScale * 14,
              ),
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: CommanColor.lightGrey,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: CommanColor.lightGrey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1,
                    color: CommanColor.lightGrey,
                  ),
                ),
                hintText: "Enter Notes",
                hintStyle: CommanStyle.grey13400,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: EdgeInsets.only(
                  top: 8.0,
                  left: 14.0,
                  right: 14.0,
                  bottom: 8.0,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      await SharPreferences.setString('OpenAd', '1');
                      FocusScope.of(context).unfocus();
                      final bookmarkProvider =
                          Provider.of<HomeContentEditProvider>(context,
                              listen: false);
                      await bookmarkProvider.deleteNote(
                        verseData: controller.selectedBookContent[
                            int.parse(verNum.toString()) - 1],
                        verseId: int.parse(verseBookdata!.id.toString()),
                        content: controller.printText.value.toString(),
                        updateVerseCallback: (updated) {
                          controller.selectedBookContent[
                              int.parse(verNum.toString()) - 1] = updated;
                        },
                        onSuccess: () {
                          Navigator.pop(context);
                          if (controller
                              .notesController.value.text.isNotEmpty) {
                            Constants.showToast('Removed Notes Successfully');
                          }
                        },
                      );
                    },
                    style: const ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(Color(0xfffd5d5d5)),
                    ),
                    child: Text(
                      controller
                                  .selectedBookContent[
                                      int.parse(verNum.toString()) - 1]
                                  .isNoted ==
                              "no"
                          ? "Cancel"
                          : "Delete",
                      style: TextStyle(
                        color: controller
                                    .selectedBookContent[
                                        int.parse(verNum.toString()) - 1]
                                    .isNoted ==
                                "no"
                            ? Colors.black
                            : Colors.black,
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.notesController.value,
                  builder: (context, noteValue, _) {
                    final hasExistingNote = controller
                            .selectedBookContent[
                                int.parse(verNum.toString()) - 1]
                            .isNoted !=
                        "no";
                    final hasTypedText = noteValue.text.trim().isNotEmpty;
                    final isActive = hasExistingNote || hasTypedText;
                    final primaryColor =
                        Provider.of<ThemeProvider>(context, listen: false)
                                    .themeMode ==
                                ThemeMode.dark
                            ? CommanColor.darkPrimaryColor
                            : CommanColor.lightModePrimary;

                    return SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          try {
                            await SharPreferences.setString('OpenAd', '1');
                            if (controller.adFree.value == false) {
                              final countprovider =
                                  Provider.of<DownloadProvider>(context,
                                      listen: false);
                              await countprovider.decrementCount(context);
                            }
                            final bookmarkProvider =
                                Provider.of<HomeContentEditProvider>(context,
                                    listen: false);
                            await bookmarkProvider.toggleNote(
                              verseData: controller.selectedBookContent[
                                  int.parse(verNum.toString()) - 1],
                              noteContent:
                                  controller.notesController.value.text,
                              verseId: int.parse(verseBookdata!.id.toString()),
                              noteModel: SaveNotesModel(
                                bookNum: int.parse(controller
                                    .selectedBookNum.value
                                    .toString()),
                                chapterNum: int.parse(controller
                                    .selectedChapter.value
                                    .toString()),
                                content: controller.printText.value.toString(),
                                plaincontent: verseBookdata!.id.toString(),
                                bookName:
                                    controller.selectedBook.value.toString(),
                                notes: controller.notesController.value.text,
                                timestamp: DateTime.now().toString(),
                                verseNum: int.parse(verNum.toString()),
                              ),
                              updateVerseCallback: (updated) {
                                controller.selectedBookContent[
                                    int.parse(verNum.toString()) - 1] = updated;
                              },
                              context: context,
                              onSuccess: () {
                                Constants.showToast(controller
                                            .selectedBookContent[
                                                int.parse(verNum.toString()) -
                                                    1]
                                            .isNoted ==
                                        "no"
                                    ? "Notes added Successfully"
                                    : "Update notes successfully");
                                Navigator.of(context).pop(true);
                                controller.notesController.value.clear();
                              },
                              onDelete: () {
                                // This won't be called for save/update, only for delete
                              },
                            );
                          } catch (e) {
                            DebugConsole.log("note error - $e");
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            isActive ? primaryColor : const Color(0xfffd5d5d5),
                          ),
                        ),
                        child: Text(
                          hasExistingNote ? "Update" : "Save",
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black,
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ImageBottomSheet extends StatelessWidget {
  final DashBoardController controller;

  const ImageBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String bibleName = BibleInfo.bible_shortName;

    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            controller.isImageBannerAdLoaded.value &&
                    controller.imageBannerAd != null &&
                    controller.adFree.value == false
                ? IgnorePointer(
                    child: SizedBox(
                      height: controller.imageBannerAd?.size.height.toDouble(),
                      width: controller.imageBannerAd?.size.width.toDouble(),
                      child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: MyAdBanner()
                          //AdWidget(ad: controller.imageBannerAd!),
                          ),
                    ),
                  )
                : SizedBox(height: screenWidth < 380 ? 2 : 95),
            Flexible(
              child: FractionallySizedBox(
                heightFactor: screenWidth < 380
                    ? 0.85
                    : screenWidth > 450
                        ? 0.82
                        : 0.81,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.of(context).pop();
                      //   },
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.end,
                      //     children: [
                      //       const Text(
                      //         "Close",
                      //         style: TextStyle(
                      //             fontSize: 17, color: CommanColor.black),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 2),
                      Stack(
                        children: [
                          Screenshot(
                            controller: controller.screenshotController.value,
                            child: GestureDetector(
                              onTap: () {
                                controller.selectedBgImage.value == 9
                                    ? controller.selectedBgImage.value = 0
                                    : controller.selectedBgImage.value += 1;
                              },
                              child: Obx(
                                () => Stack(
                                  children: [
                                    SizedBox(
                                      height: screenWidth < 380
                                          ? MediaQuery.of(context).size.height *
                                              0.735
                                          : screenWidth > 450
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.69
                                              : MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.62,
                                      width: MediaQuery.sizeOf(context).width,
                                      child:
                                          // Obx(
                                          //   () =>
                                          Image(
                                        image: AssetImage(controller
                                                .bgImagesList[
                                            controller.selectedBgImage.value]),
                                        fit: BoxFit.fill,
                                      ),
                                      // ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      right: 10,
                                      bottom: 0,
                                      top: 0,
                                      child:
                                          // Obx(
                                          //   () =>
                                          Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: AutoSizeHtmlWidget(
                                              html: controller
                                                  .selectedBookContent[
                                                      controller
                                                          .selectedVerseView
                                                          .value]
                                                  .content,
                                              maxLines: 16,
                                              maxFontSize: screenWidth < 380
                                                  ? BibleInfo.fontSizeScale *
                                                      14.5
                                                  : screenWidth > 450
                                                      ? BibleInfo
                                                              .fontSizeScale *
                                                          31
                                                      : controller
                                                              .fontSize.value -
                                                          0.9,
                                              minFontSize: screenWidth < 380
                                                  ? 11.5
                                                  : 10.9,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "${controller.selectedBook.value} ${controller.selectedChapter.value}:${controller.selectedVerseView.value + 1}",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  letterSpacing:
                                                      BibleInfo.letterSpacing,
                                                  fontSize: screenWidth > 450
                                                      ? BibleInfo
                                                              .fontSizeScale *
                                                          28
                                                      : BibleInfo
                                                              .fontSizeScale *
                                                          15,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.2,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 7,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/Icon-1024.png",
                                            height: 30,
                                            width: 30,
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Text(
                                                bibleName,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 135, 130, 130),
                                                  letterSpacing:
                                                      BibleInfo.letterSpacing,
                                                  fontSize:
                                                      BibleInfo.fontSizeScale *
                                                          16,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              if (Platform.isAndroid)
                                                const Text(
                                                  "Search in Playstore}",
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 135, 130, 130)),
                                                )
                                              else if (Platform.isIOS)
                                                const Text(
                                                  "Search in Appstore",
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 135, 130, 130)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 25,
                            child: InkWell(
                              onTap: () async {
                                // Check if already at last verse
                                if (controller.selectedVerseView.value ==
                                    controller.selectedBookContent.length - 1) {
                                  // User is at last verse and tapped again - show "Reached End" toast
                                  Constants.showToast("Reached End");
                                  return;
                                } else {
                                  controller.selectedVerseView.value += 1;
                                }
                                if (controller.adFree.value == false) {
                                  final adProvider =
                                      context.read<DownloadProvider>();
                                  await SharPreferences.setString(
                                      'OpenAd', '1');
                                  await adProvider
                                      .updateAdCount(adProvider.adCount + 1);
                                  try {
                                    if (context.mounted) {
                                      await adProvider.checkAndShowAd(
                                          context, controller.adFree.value);
                                    }
                                  } catch (e) {
                                    debugPrint(e.toString());
                                  }
                                }
                              },
                              child: Container(
                                height: screenWidth > 450 ? 45 : 25,
                                width: screenWidth > 450 ? 45 : 25,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    "assets/next.png",
                                    color: Colors.white,
                                    height: 15,
                                    width: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 25,
                            child: InkWell(
                              onTap: () async {
                                if (controller.selectedVerseView.value == 0) {
                                  controller.selectedVerseView.value = 0;
                                } else {
                                  controller.selectedVerseView.value -= 1;
                                }
                                try {
                                  await SharPreferences.setString(
                                      'OpenAd', '1');
                                  if (controller.adFree.value == false) {
                                    final adProvider =
                                        context.read<DownloadProvider>();
                                    await adProvider
                                        .updateAdCount(adProvider.adCount + 1);
                                    await adProvider.checkAndShowAd(
                                        context, controller.adFree.value);
                                  }
                                } catch (e) {
                                  DebugConsole.log("image priv error - $e");
                                }
                              },
                              child: Container(
                                height: screenWidth > 450 ? 45 : 25,
                                width: screenWidth > 450 ? 45 : 25,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    "assets/priv.png",
                                    color: Colors.white,
                                    height: 15,
                                    width: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareImageButton(context, "Share"),
                          _buildShareImageButton(context, "Save"),
                          _buildShareImageButton(context, "Close"),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareImageButton(BuildContext context, String label) {
    return Consumer<HomeContentEditProvider>(
      builder: (context, bookmarkProvider, child) {
        return SizedBox(
          width: 100,
          height: MediaQuery.of(context).size.width > 450 ? 60 : null,
          child: ElevatedButton(
            onPressed: () async {
              await SharPreferences.setString('OpenAd', '1');
              await SharPreferences.setString('bottom', '1');
              if (controller.adFree.value == false) {
                final countprovider =
                    Provider.of<DownloadProvider>(context, listen: false);
                await countprovider.decrementCount(context);
              }
              final image = await controller.screenshotController.value.capture(
                delay: const Duration(milliseconds: 10),
              );

              if (image == null) {
                await SharPreferences.setString('bottom', '0');
                return;
              }

              if (label == "Share") {
                final appPackageName =
                    (await PackageInfo.fromPlatform()).packageName;
                String appid = BibleInfo.apple_AppId;
                String message = "";

                if (Platform.isAndroid) {
                  message =
                      " \n Read More at: https://play.google.com/store/apps/details?id=$appPackageName";
                } else if (Platform.isIOS) {
                  message =
                      " \n Read More at: https://itunes.apple.com/app/id$appid";
                }

                saveAndShare(image, "bible", message, context: context);
                // Track Share event
                StatsigService.trackShare();
              } else if (label == "Save") {
                await saveImageIntoLocal(image, context);
              } else {
                await SharPreferences.setString('bottom', '0');
                Navigator.of(context).pop();
              }

              await SharPreferences.setString('bottom', '0');
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                CommanColor.lightDarkPrimary(context),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: MediaQuery.of(context).size.width > 450
                      ? BibleInfo.fontSizeScale * 17
                      : BibleInfo.fontSizeScale * 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// class ImageBottomSheet extends StatelessWidget {
//   final DashBoardController controller;

//   const ImageBottomSheet({super.key, required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     String bibleName = BibleInfo.bible_shortName;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         controller.isImageBannerAdLoaded.value &&
//                 controller.imageBannerAd != null &&
//                 controller.adFree.value == false
//             ? SizedBox(
//                 height: controller.imageBannerAd?.size.height.toDouble(),
//                 width: controller.imageBannerAd?.size.width.toDouble(),
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 5),
//                   child: AdWidget(ad: controller.imageBannerAd!),
//                 ),
//               )
//             : SizedBox(height: screenWidth < 380 ? 2 : 100),
//         Flexible(
//           child: FractionallySizedBox(
//             heightFactor: screenWidth < 380
//                 ? 0.85
//                 : screenWidth > 450
//                     ? 0.82
//                     : 0.81,
//             child: Container(
//               decoration: const BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(0),
//                   topRight: Radius.circular(0),
//                 ),
//                 color: Colors.white,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 15),
//                   Stack(
//                     children: [
//                       Screenshot(
//                         controller: controller.screenshotController.value,
//                         child: GestureDetector(
//                           onTap: () {
//                             controller.selectedBgImage.value == 9
//                                 ? controller.selectedBgImage.value = 0
//                                 : controller.selectedBgImage.value += 1;
//                           },
//                           child: Stack(
//                             children: [
//                               SizedBox(
//                                 height: screenWidth < 380
//                                     ? MediaQuery.of(context).size.height * 0.735
//                                     : screenWidth > 450
//                                         ? MediaQuery.of(context).size.height *
//                                             0.69
//                                         : MediaQuery.of(context).size.height *
//                                             0.62,
//                                 width: MediaQuery.sizeOf(context).width,
//                                 child: Obx(
//                                   () => Image(
//                                     image: AssetImage(controller.bgImagesList[
//                                         controller.selectedBgImage.value]),
//                                     fit: BoxFit.fill,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 10,
//                                 right: 10,
//                                 bottom: 0,
//                                 top: 0,
//                                 child: Obx(
//                                   () => Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 10),
//                                         child: AutoSizeHtmlWidget(
//                                           html: controller
//                                               .selectedBookContent[controller
//                                                   .selectedVerseView.value]
//                                               .content,
//                                           maxLines: 16,
//                                           maxFontSize: screenWidth < 380
//                                               ? BibleInfo.fontSizeScale * 14.5
//                                               : screenWidth > 450
//                                                   ? BibleInfo.fontSizeScale * 31
//                                                   : controller.fontSize.value -
//                                                       0.9,
//                                           minFontSize:
//                                               screenWidth < 380 ? 11.5 : 10.9,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.end,
//                                         children: [
//                                           Text(
//                                             "${controller.selectedBook.value} ${controller.selectedChapter.value}:${controller.selectedVerseView.value + 1}",
//                                             style: TextStyle(
//                                               color: Colors.black,
//                                               letterSpacing:
//                                                   BibleInfo.letterSpacing,
//                                               fontSize: screenWidth > 450
//                                                   ? BibleInfo.fontSizeScale * 28
//                                                   : BibleInfo.fontSizeScale *
//                                                       15,
//                                               fontWeight: FontWeight.w500,
//                                               height: 1.2,
//                                               fontStyle: FontStyle.italic,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                           const SizedBox(width: 10),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 0,
//                                 right: 0,
//                                 bottom: 7,
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Image.asset(
//                                       "assets/Icon-1024.png",
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           bibleName,
//                                           style: const TextStyle(
//                                             color: Color.fromARGB(
//                                                 255, 135, 130, 130),
//                                             letterSpacing:
//                                                 BibleInfo.letterSpacing,
//                                             fontSize:
//                                                 BibleInfo.fontSizeScale * 16,
//                                             fontWeight: FontWeight.w500,
//                                             height: 1.3,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                         if (Platform.isAndroid)
//                                           const Text(
//                                             "Search in PlayStore",
//                                             style: TextStyle(
//                                                 color: Color.fromARGB(
//                                                     255, 135, 130, 130)),
//                                           )
//                                         else if (Platform.isIOS)
//                                           const Text(
//                                             "Search in AppStore",
//                                             style: TextStyle(
//                                                 color: Color.fromARGB(
//                                                     255, 135, 130, 130)),
//                                           ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: 10,
//                         bottom: 25,
//                         child: InkWell(
//                           onTap: () async {
//                             final adProvider = context.read<DownloadProvider>();
//                             await SharPreferences.setString('OpenAd', '1');
//                             await adProvider
//                                 .updateAdCount(adProvider.adCount + 1);
//                             await adProvider.checkAndShowAd(context);

//                             if (controller.selectedVerseView.value ==
//                                 controller.selectedBookContent.length - 1) {
//                               controller.selectedVerseView.value =
//                                   controller.selectedBookContent.length - 1;
//                             } else {
//                               controller.selectedVerseView.value += 1;
//                             }
//                           },
//                           child: Container(
//                             height: screenWidth > 450 ? 45 : 25,
//                             width: screenWidth > 450 ? 45 : 25,
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.black38,
//                             ),
//                             child: Center(
//                               child: Image.asset(
//                                 "assets/next.png",
//                                 color: Colors.white,
//                                 height: 15,
//                                 width: 15,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 10,
//                         bottom: 25,
//                         child: InkWell(
//                           onTap: () async {
//                             try {
//                               await SharPreferences.setString('OpenAd', '1');
//                               final adProvider =
//                                   context.read<DownloadProvider>();
//                               await adProvider
//                                   .updateAdCount(adProvider.adCount + 1);
//                               await adProvider.checkAndShowAd(context);

//                               if (controller.selectedVerseView.value == 0) {
//                                 controller.selectedVerseView.value = 0;
//                               } else {
//                                 controller.selectedVerseView.value -= 1;
//                               }
//                             } catch (e) {
//                               DebugConsole.log("image priv error - $e");
//                             }
//                           },
//                           child: Container(
//                             height: screenWidth > 450 ? 45 : 25,
//                             width: screenWidth > 450 ? 45 : 25,
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.black38,
//                             ),
//                             child: Center(
//                               child: Image.asset(
//                                 "assets/priv.png",
//                                 color: Colors.white,
//                                 height: 15,
//                                 width: 15,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildShareImageButton(context, "Share"),
//                       _buildShareImageButton(context, "Save"),
//                     ],
//                   ),
//                   const Spacer(),
//                   const SizedBox(height: 1),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildShareImageButton(BuildContext context, String label) {
//     return SizedBox(
//       width: 100,
//       height: MediaQuery.of(context).size.width > 450 ? 60 : null,
//       child: ElevatedButton(
//         onPressed: () async {
//           await SharPreferences.setString('OpenAd', '1');
//           await SharPreferences.setString('bottom', '1');

//           final countprovider =
//               Provider.of<DownloadProvider>(context, listen: false);
//           await countprovider.decrementCount(context);

//           final image = await controller.screenshotController.value.capture(
//             delay: const Duration(milliseconds: 10),
//           );

//           if (image == null) {
//             await SharPreferences.setString('bottom', '0');
//             return;
//           }

//           if (label == "Share") {
//             final appPackageName =
//                 (await PackageInfo.fromPlatform()).packageName;
//             String appid = BibleInfo.apple_AppId;
//             String message = "";

//             if (Platform.isAndroid) {
//               message =
//                   " \n Read More at: https://play.google.com/store/apps/details?id=$appPackageName";
//             } else if (Platform.isIOS) {
//               message =
//                   " \n Read More at: https://itunes.apple.com/app/id$appid";
//             }

//             saveAndShare(image, "bible", message);
//           } else {
//             await saveImageIntoLocal(image, context);
//           }

//           await SharPreferences.setString('bottom', '0');
//         },
//         style: ButtonStyle(
//           backgroundColor: WidgetStatePropertyAll(
//             CommanColor.lightDarkPrimary(context),
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               color: Colors.white,
//               letterSpacing: BibleInfo.letterSpacing,
//               fontSize: MediaQuery.of(context).size.width > 450
//                   ? BibleInfo.fontSizeScale * 17
//                   : BibleInfo.fontSizeScale * 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
