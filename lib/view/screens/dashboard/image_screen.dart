import 'dart:convert';
import 'dart:io';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/listed_image_detail_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/widget/library_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Model/saveImagesModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/colors.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  late Future<List<SaveImageModel>> imagesData;
  bool loader = false;

  DashBoardController dashBoardController = DashBoardController();
  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    setState(() {
      imagesData = DBHelper().getImage();
    });
    print(imagesData);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: imagesData,
        builder: (context, AsyncSnapshot<List<SaveImageModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader());
          } else if (snapshot.data?.isNotEmpty ?? false) {
            return GridView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 2.5,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10,
              ),
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                var data = snapshot.data![index];
                String? base64Image = data.imagePath;
                return GestureDetector(
                  onTap: () {
                    int currentIndex = index;
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.black12,
                      context: context,
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: screenWidth < 380
                              ? 0.85
                              : screenWidth > 450
                                  ? 0.82
                                  : 0.81,
                          child: StatefulBuilder(
                              builder: (context, setStateBottomSheet) {
                            return Container(
                              // height: screenWidth < 380
                              //     ? MediaQuery.of(context).size.height * 0.735
                              //     : screenWidth > 450
                              //         ? MediaQuery.of(context).size.height *
                              //             0.69
                              //         : MediaQuery.of(context).size.height *
                              //             0.66,
                              //MediaQuery.of(context).size.height * 0.65,
                              width: MediaQuery.of(context).size.width,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  topRight: Radius.circular(0),
                                ),
                                color: Colors.white,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    flex: 0,
                                    //child: const Center(child: Text("Banner Ad")),
                                    // Replace this with your actual ad widget if integrated
                                    child: MyAdBanner(),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: Image.memory(
                                            base64Decode(snapshot
                                                .data![currentIndex]
                                                .imagePath!),
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 3,
                                          left: 20,
                                          child: IconButton(
                                            icon: Container(
                                              height: 25,
                                              width: 25,
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
                                              )),
                                            ),
                                            onPressed: () {
                                              if (currentIndex > 0) {
                                                setStateBottomSheet(() {
                                                  currentIndex--;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 3,
                                          right: 20,
                                          child: IconButton(
                                            icon: Container(
                                              height: 25,
                                              width: 25,
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
                                              )),
                                            ),

                                            // IconButton(
                                            //   icon: const Icon(
                                            //       Icons.arrow_forward_ios,
                                            //       color: Colors.black),
                                            onPressed: () {
                                              if (currentIndex <
                                                  snapshot.data!.length - 1) {
                                                setStateBottomSheet(() {
                                                  currentIndex++;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    // child: Image.memory(
                                    //   base64Decode(base64Image.toString()),
                                    //   fit: BoxFit.fill,
                                    //   width: MediaQuery.of(context).size.width,
                                    // ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      SizedBox(
                                        width: 95,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Get.back();
                                            deleteConfirmation(
                                              context,
                                              () {
                                                Constants.showToast(
                                                    'Successfully Deleted');
                                                DBHelper()
                                                    .deleteImage(
                                                        data.id!.toInt())
                                                    .then((value) {
                                                  loadData();
                                                  Get.back();
                                                });
                                              },
                                            );
                                            // showDialog<void>(
                                            //   context: context,
                                            //   barrierDismissible: false,
                                            //   builder: (BuildContext context) {
                                            //     return Dialog(
                                            //       shape: RoundedRectangleBorder(
                                            //           borderRadius:
                                            //               BorderRadius.circular(
                                            //                   5)),
                                            //       elevation: 16,
                                            //       backgroundColor: Colors.white,
                                            //       insetPadding:
                                            //           EdgeInsets.symmetric(
                                            //               horizontal: 20),
                                            //       child: ListView(
                                            //         shrinkWrap: true,
                                            //         padding: const EdgeInsets
                                            //             .symmetric(
                                            //             vertical: 20),
                                            //         children: [
                                            //           Padding(
                                            //             padding:
                                            //                 EdgeInsets.only(
                                            //                     top: 0,
                                            //                     bottom: 10),
                                            //             child: Text(
                                            //                 "Do you want to delete?",
                                            //                 style: TextStyle(
                                            //                     color: Colors
                                            //                         .black,
                                            //                     letterSpacing:
                                            //                         BibleInfo
                                            //                             .letterSpacing,
                                            //                     fontSize: BibleInfo
                                            //                             .fontSizeScale *
                                            //                         16,
                                            //                     fontWeight:
                                            //                         FontWeight
                                            //                             .w500),
                                            //                 textAlign: TextAlign
                                            //                     .center),
                                            //           ),

                                            //           // SizedBox(height: 15,),
                                            //           Row(
                                            //             mainAxisAlignment:
                                            //                 MainAxisAlignment
                                            //                     .spaceEvenly,
                                            //             children: [
                                            //               ElevatedButton(
                                            //                   onPressed:
                                            //                       () async {
                                            //                     Navigator.pop(
                                            //                         context);
                                            //                   },
                                            //                   style:
                                            //                       ElevatedButton
                                            //                           .styleFrom(
                                            //                     backgroundColor:
                                            //                         Colors
                                            //                             .transparent,
                                            //                     fixedSize: Size(
                                            //                         MediaQuery.of(context)
                                            //                                 .size
                                            //                                 .width *
                                            //                             0.3,
                                            //                         35),
                                            //                     elevation: 0,
                                            //                     shape: RoundedRectangleBorder(
                                            //                         borderRadius:
                                            //                             BorderRadius
                                            //                                 .circular(
                                            //                                     5),
                                            //                         side: BorderSide(
                                            //                             color: CommanColor.lightDarkPrimary(
                                            //                                 context),
                                            //                             width:
                                            //                                 1)),
                                            //                   ),
                                            //                   child: Center(
                                            //                       child: Text(
                                            //                     "Cancel",
                                            //                     style: TextStyle(
                                            //                         color: CommanColor
                                            //                             .lightDarkPrimary(
                                            //                                 context),
                                            //                         fontWeight:
                                            //                             FontWeight
                                            //                                 .w400,
                                            //                         letterSpacing:
                                            //                             BibleInfo
                                            //                                 .letterSpacing,
                                            //                         fontSize:
                                            //                             BibleInfo.fontSizeScale *
                                            //                                 14),
                                            //                   ))),
                                            //               ElevatedButton(
                                            //                 onPressed:
                                            //                     () async {
                                            //                   DBHelper()
                                            //                       .deleteImage(data
                                            //                           .id!
                                            //                           .toInt())
                                            //                       .then(
                                            //                           (value) {
                                            //                     loadData();
                                            //                     Get.back();
                                            //                   });
                                            //                 },
                                            //                 style:
                                            //                     ElevatedButton
                                            //                         .styleFrom(
                                            //                   backgroundColor:
                                            //                       CommanColor
                                            //                           .lightDarkPrimary(
                                            //                               context),
                                            //                   fixedSize: Size(
                                            //                       MediaQuery.of(
                                            //                                   context)
                                            //                               .size
                                            //                               .width *
                                            //                           0.3,
                                            //                       35),
                                            //                   elevation: 0,
                                            //                   shape: RoundedRectangleBorder(
                                            //                       borderRadius:
                                            //                           BorderRadius
                                            //                               .circular(
                                            //                                   5)),
                                            //                 ),
                                            //                 child: Center(
                                            //                   child: Text(
                                            //                     "Delete",
                                            //                     style: TextStyle(
                                            //                         color: Colors
                                            //                             .white,
                                            //                         fontWeight:
                                            //                             FontWeight
                                            //                                 .w400,
                                            //                         letterSpacing:
                                            //                             BibleInfo
                                            //                                 .letterSpacing,
                                            //                         fontSize:
                                            //                             BibleInfo.fontSizeScale *
                                            //                                 14),
                                            //                   ),
                                            //                 ),
                                            //               ),
                                            //             ],
                                            //           ),
                                            //         ],
                                            //       ),
                                            //     );
                                            //   },
                                            // );
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                              CommanColor.lightDarkPrimary(
                                                  context),
                                            ),
                                          ),
                                          child: Center(
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.white,
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // SizedBox(
                                      //   width: 50,
                                      // ),
                                      SizedBox(
                                        width: 90,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Save the image to a temporary file
                                            final tempDir =
                                                await getTemporaryDirectory();
                                            final tempFile = File(
                                                '${tempDir.path}/temp_image.png');
                                            await tempFile.writeAsBytes(
                                                base64Decode(
                                                    base64Image.toString()));

                                            final size =
                                                MediaQuery.of(context).size;

                                            // Define a centered small rectangle for the popover anchor
                                            final centerRect = Rect.fromCenter(
                                              center: Offset(size.width / 2,
                                                  size.height / 2),
                                              width: 1,
                                              height: 1,
                                            );

                                            // Share the temporary file
                                            // Share.share([tempFile.path]);
                                            final xFile = XFile(
                                              tempFile.path,
                                              mimeType: 'image/png',
                                              name: 'Bible Verse.png',
                                            );
                                            await Share.shareXFiles(
                                              [xFile],
                                              sharePositionOrigin: centerRect,
                                            );
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                              CommanColor.lightDarkPrimary(
                                                  context),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Share",
                                              style: TextStyle(
                                                color: Colors.white,
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // SizedBox(
                                      //   width: 50,
                                      // ),
                                      SizedBox(
                                        width: 90,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                              CommanColor.lightDarkPrimary(
                                                  context),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Close",
                                              style: TextStyle(
                                                color: Colors.white,
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    );
                  },
                  child: Image.memory(
                    base64Decode(base64Image.toString()),
                    fit: BoxFit.fill,
                  ),
                );
              },
            );
          } else {
            return const SizedBox.expand(
              child: LibraryEmptyState(
                icon: Icons.image_outlined,
                title: 'No Images Yet',
                subtitle:
                    'Save images while reading to access them anytime.',
              ),
            );
          }
        },
      ),
    );
  }
}
