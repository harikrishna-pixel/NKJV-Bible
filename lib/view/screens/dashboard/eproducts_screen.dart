import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/Model/bookoffer_model.dart';
import 'package:biblebookapp/core/notifiers/auth/auth.notifier.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/product_details_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/product_subc_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EProductsScreen extends StatefulWidget {
  const EProductsScreen({super.key});

  @override
  State<EProductsScreen> createState() => _EProductsScreenState();
}

class _EProductsScreenState extends State<EProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int selectedTap = 0;
  final List<String> tabs = ['eProducts', 'Favorites', 'Downloads'];
  bool isplanactive = false;
  List<File> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    getofferbook();
    loadFavorites();
    showalt();

    //_loadPdfFiles();
    tabController = TabController(length: tabs.length, vsync: this);
  }

  // Future<void> _loadPdfFiles() async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final files = dir.listSync(); // List all files in the directory
  //   final pdfList = files
  //       .where((file) => file is File && file.path.endsWith('.pdf'))
  //       .map((file) => file as File)
  //       .toList();

  //   setState(() {
  //     pdfFiles = pdfList;
  //   });
  // }

  // Create a stream that emits the list of PDF files
  Stream<List<File>> _pdfFilesStream() async* {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    final pdfList = files
        .where((file) => file is File && file.path.endsWith('.pdf'))
        .map((file) => file as File)
        .toList();

    yield pdfList;
  }

  void _openPdf(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewScreen(filePath: file.path),
      ),
    );
  }

  List<Map<String, String>> favoriteItems = [];

  List<Map<String, String>> items = [
    // {
    //   'title': 'Bible Reading Tracker',
    //   'image': 'assets/im1.jpg',
    // },
    // {
    //   'title': 'Stickers kit',
    //   'image': 'assets/im2.jpg',
    // },
    // {
    //   'title': 'Bible Riddles',
    //   'image': 'assets/im3.jpg',
    // },
    // {
    //   'title': 'Reading Plan',
    //   'image': 'assets/im4.jpg',
    // },
    // {
    //   'title': 'Bible Challenges',
    //   'image': 'assets/im5.jpg',
    // },
    // {
    //   'title': 'Who said it?',
    //   'image': 'assets/im3.jpg',
    // },
  ];

  showalt() async {
    final usedFree = await Provider.of<DownloadProvider>(context, listen: false)
        .hasUsedFreeDownload();

    final bool isConnected = await InternetConnection().hasInternetAccess;

    debugPrint("connectivityResult -$isConnected");

    if (!isConnected) {
      Constants.showToast("Check your Internet connection");
    }
    if (!usedFree) {
      if (mounted) {
        // await Provider.of<DownloadProvider>(context, listen: false)
        //     .usedFreeDownload();
        return showDialog(
          context: context,
          builder: (_) => CustomAlertBox(
            title: "Welcome Bonus!",
            message: "Congrats, You are eligible to buy 1 Product for FREE..",
            buttons: [
              AlertButton(
                text: "Go to List",
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to list screen
                },
              ),
            ],
          ),
        );
      }
    } else {
      // final data = await Provider.of<DownloadProvider>(context).isplanactive();
      // setState(() {
      //   isplanactive = data;
      // });
    }
  }

  getofferbook() async {
    try {
      final dataprovider = Provider.of<AuthNotifier>(context, listen: false);
      final GetBookOffer bookOffer = await dataprovider.getbook();

      if (bookOffer.data != null && bookOffer.data!.isNotEmpty) {
        items = bookOffer.data!
            .map((book) => {
                  'title': book?.bookName ?? 'No Title',
                  'image': book?.bookThumbURL ?? '',
                  'url': book?.bookUrl ?? '',
                  'description': book?.bookDescription ?? '',
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favJsonList = prefs.getStringList('favorites') ?? [];
    favoriteItems = favJsonList
        .map((item) => Map<String, String>.from(json.decode(item)))
        .toList();
    setState(() {});
  }

  Future<void> toggleFavorite(Map<String, String> item) async {
    final prefs = await SharedPreferences.getInstance();
    final index =
        favoriteItems.indexWhere((fav) => fav['title'] == item['title']);

    if (index != -1) {
      favoriteItems.removeAt(index);
      Constants.showToast("Removed from Favorites");
    } else {
      Constants.showToast("Added to Favorites");
      favoriteItems.add(item);
    }

    final favJsonList = favoriteItems.map((e) => json.encode(e)).toList();
    await prefs.setStringList('favorites', favJsonList);

    setState(() {});
  }

  bool isItemFavorite(Map<String, String> item) {
    return favoriteItems.any((fav) => fav['title'] == item['title']);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      // backgroundColor: const Color(0xFFF5E9D2),
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: const BackButton(color: Colors.black),
      //   centerTitle: true,
      //   title: const Text(
      //     'e-Products',
      //     style: TextStyle(
      //       fontSize: 22,
      //       fontWeight: FontWeight.bold,
      //       color: Colors.black,
      //     ),
      //   ),
      //   actions: const [
      //     Padding(
      //       padding: EdgeInsets.only(right: 12),
      //       child: Icon(Icons.card_giftcard, color: Colors.black),
      //     )
      //   ],
      // ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      "e-Products",
                      style: CommanStyle.appBarStyle(context).copyWith(
                          fontSize: screenWidth > 450
                              ? BibleInfo.fontSizeScale * 30
                              : BibleInfo.fontSizeScale * 18,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     isplanactive
                  //         ? DownloadLimitIndicator()
                  //         :
                  //         //SizedBox(),
                  //         GestureDetector(
                  //             onTap: () {
                  //               Get.to(() => const SubscriptionPlanPage(),
                  //                   transition: Transition.cupertinoDialog,
                  //                   duration:
                  //                       const Duration(milliseconds: 300));
                  //             },
                  //             child: Padding(
                  //               padding:
                  //                   const EdgeInsets.symmetric(horizontal: 4),
                  //               child: Image.asset(
                  //                 "assets/crown-2.png",
                  //                 color:
                  //                     CommanColor.inDarkWhiteAndInLightPrimary(
                  //                         context),
                  //                 width: screenWidth < 380 ? 20 : 24,
                  //                 height: screenWidth < 380 ? 20 : 24,
                  //               ),
                  //             ),
                  //           ),
                  //   ],
                  // ),
                  StreamBuilder<bool>(
                    stream: Provider.of<DownloadProvider>(context)
                        .isPlanActiveStream(),
                    builder: (context, snapshot) {
                      // if (!snapshot.hasData) {
                      //   return const SizedBox(
                      //     width: 24,
                      //     height: 24,
                      //     child: CircularProgressIndicator(strokeWidth: 2),
                      //   );
                      // }

                      final isPlanActive = snapshot.data ?? false;
                      return Row(
                        children: [
                          isPlanActive
                              ? const DownloadLimitIndicator()
                              : GestureDetector(
                                  onTap: () async {
                                    final bool isConnected =
                                        await InternetConnection()
                                            .hasInternetAccess;

                                    debugPrint(
                                        "connectivityResult -$isConnected");

                                    if (!isConnected) {
                                      return Constants.showToast(
                                          "Check your Internet connection");
                                    } else {
                                      Get.to(
                                        () => const SubscriptionPlanPage(),
                                        transition: Transition.cupertinoDialog,
                                        duration:
                                            const Duration(milliseconds: 300),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Image.asset(
                                      "assets/crown-2.png",
                                      color: CommanColor
                                          .inDarkWhiteAndInLightPrimary(
                                              context),
                                      width: screenWidth > 450
                                          ? 35
                                          : screenWidth < 380
                                              ? 20
                                              : 24,
                                      height: screenWidth > 450
                                          ? 35
                                          : screenWidth < 380
                                              ? 20
                                              : 24,
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                  )

                  // Icon(
                  //   Icons.file_upload_outlined,
                  //   color: CommanColor.whiteBlack(context),
                  // ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: DefaultTabController(
                    length: 3,
                    initialIndex: 0,
                    animationDuration: const Duration(milliseconds: 300),
                    child: Builder(builder: (context) {
                      Future.delayed(
                        Duration.zero,
                        () {
                          setState(() {
                            selectedTap = tabController.index;
                          });
                        },
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: screenWidth > 450 ? 55 : 45,
                            child: TabBar(
                              controller: tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorWeight: 0,
                              padding: EdgeInsets.zero,
                              dividerColor: Colors.transparent,
                              indicatorPadding: const EdgeInsets.only(
                                  right: 2, bottom: 10, left: 0),
                              labelPadding: const EdgeInsets.only(
                                  right: 8, bottom: 10, left: 5),
                              indicatorSize: TabBarIndicatorSize.label,
                              indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  shape: BoxShape.rectangle,
                                  color: CommanColor.lightDarkPrimary(context)),
                              onTap: (value) {
                                setState(() {
                                  selectedTap = value;
                                });
                              },
                              tabs: [
                                Tab(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    height: screenWidth > 450 ? 50 : 35,
                                    width: screenWidth > 450
                                        ? 160
                                        : screenWidth > 450
                                            ? 135
                                            : 117,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 0.5,
                                            spreadRadius: 1,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                        color: selectedTap == 0
                                            ? Provider.of<ThemeProvider>(
                                                            context)
                                                        .themeMode ==
                                                    ThemeMode.dark
                                                ? CommanColor.black
                                                : CommanColor.lightDarkPrimary(
                                                    context)
                                            : CommanColor.whiteBlack45(
                                                context)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Image.asset(
                                          "assets/eproducts.png",
                                          color: Provider.of<ThemeProvider>(
                                                          context)
                                                      .themeMode ==
                                                  ThemeMode.dark
                                              ? selectedTap == 0
                                                  ? CommanColor.white
                                                  : CommanColor.darkPrimaryColor
                                              : CommanColor.whiteAndDark(
                                                  context),
                                          width: 20,
                                          height: 20,
                                        ),
                                        // Icon(
                                        //   Icons.bookmark,
                                        //   color: selectedTap == 0
                                        //       ? Colors.white
                                        //       : CommanColor.whiteAndDark(context),
                                        //   size: screenWidth > 450 ? 22 : 18,
                                        // ),
                                        // SizedBox(width: 2,),
                                        Text(
                                          " eProducts ",
                                          style: selectedTap == 0
                                              ? CommanStyle.white12400.copyWith(
                                                  fontSize: screenWidth > 450
                                                      ? BibleInfo
                                                              .fontSizeScale *
                                                          17
                                                      : BibleInfo
                                                              .fontSizeScale *
                                                          12)
                                              : CommanStyle
                                                      .inDarkPrimaryInLightWhite12400(
                                                          context)
                                                  .copyWith(
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              17
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                              12),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    // height: screenWidth > 450 ? 55 : 35,
                                    height: screenWidth > 450 ? 50 : 35,
                                    width: screenWidth > 450
                                        ? 160
                                        : screenWidth > 450
                                            ? 135
                                            : 117,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 0.5,
                                            spreadRadius: 1,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                        // color: selectedTap == 1
                                        //     ? CommanColor.lightDarkPrimary(
                                        //         context)
                                        //     : CommanColor.whiteBlack45(
                                        //         context)),
                                        color: selectedTap == 1
                                            ? Provider.of<ThemeProvider>(
                                                            context)
                                                        .themeMode ==
                                                    ThemeMode.dark
                                                ? CommanColor.black
                                                : CommanColor.lightDarkPrimary(
                                                    context)
                                            : CommanColor.whiteBlack45(
                                                context)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Image.asset("assets/bookmark_1.png",color: CommanColor.whiteAndDark(context),width: 20,height: 15,),
                                        // Icon(
                                        //   Icons.brush_sharp,
                                        //   color: selectedTap == 1
                                        //       ? Colors.white
                                        //       : CommanColor.whiteAndDark(context),
                                        //   size: screenWidth > 450 ? 22 : 18,
                                        // ),
                                        Image.asset(
                                          "assets/eheart.png",
                                          // color:
                                          //     CommanColor.whiteAndDark(context),
                                          color: Provider.of<ThemeProvider>(
                                                          context)
                                                      .themeMode ==
                                                  ThemeMode.dark
                                              ? selectedTap == 1
                                                  ? CommanColor.white
                                                  : CommanColor.darkPrimaryColor
                                              : CommanColor.whiteAndDark(
                                                  context),
                                          width: 20,
                                          height: 20,
                                        ),
                                        Text(
                                          " Favorites ",
                                          style: selectedTap == 1
                                              ? CommanStyle.white12400.copyWith(
                                                  fontSize: screenWidth > 450
                                                      ? BibleInfo
                                                              .fontSizeScale *
                                                          17
                                                      : BibleInfo
                                                              .fontSizeScale *
                                                          12)
                                              : CommanStyle
                                                      .inDarkPrimaryInLightWhite12400(
                                                          context)
                                                  .copyWith(
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              17
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                              12),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    //  height: 35,
                                    height: screenWidth > 450 ? 50 : 35,
                                    width: screenWidth > 450
                                        ? 160
                                        : screenWidth > 450
                                            ? 135
                                            : 117,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 0.5,
                                            spreadRadius: 1,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                        // color: selectedTap == 2
                                        //     ? CommanColor.lightDarkPrimary(
                                        //         context)
                                        //     : CommanColor.whiteBlack45(
                                        //         context)),
                                        color: selectedTap == 2
                                            ? Provider.of<ThemeProvider>(
                                                            context)
                                                        .themeMode ==
                                                    ThemeMode.dark
                                                ? CommanColor.black
                                                : CommanColor.lightDarkPrimary(
                                                    context)
                                            : CommanColor.whiteBlack45(
                                                context)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Image.asset("assets/bookmark_1.png",color: CommanColor.whiteAndDark(context),width: 20,height: 15,),
                                        // Icon(
                                        //   Icons.format_underline_sharp,
                                        //   color: selectedTap == 2
                                        //       ? Colors.white
                                        //       : CommanColor.whiteAndDark(context),
                                        //   size: screenWidth > 450 ? 22 : 18,
                                        // ),
                                        Image.asset(
                                          "assets/edownload.png",
                                          // color:
                                          //     CommanColor.whiteAndDark(context),
                                          color: Provider.of<ThemeProvider>(
                                                          context)
                                                      .themeMode ==
                                                  ThemeMode.dark
                                              ? selectedTap == 2
                                                  ? CommanColor.white
                                                  : CommanColor.darkPrimaryColor
                                              : CommanColor.whiteAndDark(
                                                  context),
                                          width: 20,
                                          height: 20,
                                        ),
                                        Text(
                                          " Downloads ",
                                          style: selectedTap == 2
                                              ? CommanStyle.white12400.copyWith(
                                                  fontSize: screenWidth > 450
                                                      ? BibleInfo
                                                              .fontSizeScale *
                                                          17
                                                      : BibleInfo
                                                              .fontSizeScale *
                                                          12)
                                              : CommanStyle
                                                      .inDarkPrimaryInLightWhite12400(
                                                          context)
                                                  .copyWith(
                                                      fontSize: screenWidth >
                                                              450
                                                          ? BibleInfo
                                                                  .fontSizeScale *
                                                              17
                                                          : BibleInfo
                                                                  .fontSizeScale *
                                                              12),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: tabController,
                                children: [
                                  SizedBox(
                                    height: 350,
                                    child: items.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No eProducts',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          )
                                        : GridView.builder(
                                            padding: const EdgeInsets.all(6),
                                            itemCount: items.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  screenWidth > 450 ? 3 : 2,
                                              childAspectRatio:
                                                  screenWidth > 450
                                                      ? 0.75
                                                      : 0.62,
                                              mainAxisSpacing:
                                                  screenWidth > 450 ? 19 : 16,
                                              crossAxisSpacing:
                                                  screenWidth > 450 ? 19 : 12,
                                            ),
                                            itemBuilder: (context, index) {
                                              final item = items[index];
                                              return GestureDetector(
                                                onTap: () {
                                                  Get.to(
                                                      () => ProductDetailPage(
                                                            isfav:
                                                                isItemFavorite(
                                                                    item),
                                                            producttitle:
                                                                item['title']!,
                                                            productdesc: item[
                                                                'description']!,
                                                            productimage:
                                                                item['image']!,
                                                            producturl:
                                                                item['url']!,
                                                          ),
                                                      transition: Transition
                                                          .cupertinoDialog,
                                                      duration: const Duration(
                                                          milliseconds: 300));
                                                },
                                                child: ProductCard(
                                                  title: item['title']!,
                                                  imagePath: item['image']!,
                                                  isFavorite:
                                                      isItemFavorite(item),
                                                  onTap: () {
                                                    // Handle "View Details"
                                                    Get.to(
                                                        () => ProductDetailPage(
                                                              isfav:
                                                                  isItemFavorite(
                                                                      item),
                                                              producttitle:
                                                                  item[
                                                                      'title']!,
                                                              productdesc: item[
                                                                  'description']!,
                                                              productimage:
                                                                  item[
                                                                      'image']!,
                                                              producturl:
                                                                  item['url']!,
                                                            ),
                                                        transition: Transition
                                                            .cupertinoDialog,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300));
                                                  },
                                                  onFavoriteToggle: () =>
                                                      toggleFavorite(item),
                                                ),
                                              );
                                              // ProductCard(
                                              //   title: item['title']!,
                                              //   imagePath: item['image']!,
                                              //   onTap: () {
                                              //     // Handle "View Details" button tap
                                              //   },
                                              // );
                                            },
                                          ),
                                  ),
                                  SizedBox(
                                    height: 350,
                                    child: favoriteItems.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No Favorites',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          )
                                        : GridView.builder(
                                            padding: const EdgeInsets.all(6),
                                            itemCount: favoriteItems.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              // crossAxisCount: 2,
                                              // childAspectRatio: 0.62,
                                              // mainAxisSpacing: 16,
                                              // crossAxisSpacing: 12,
                                              crossAxisCount:
                                                  screenWidth > 450 ? 3 : 2,
                                              childAspectRatio:
                                                  screenWidth > 450
                                                      ? 0.75
                                                      : 0.62,
                                              mainAxisSpacing:
                                                  screenWidth > 450 ? 19 : 16,
                                              crossAxisSpacing:
                                                  screenWidth > 450 ? 19 : 12,
                                            ),
                                            itemBuilder: (context, index) {
                                              final item = favoriteItems[index];
                                              return GestureDetector(
                                                onTap: () {
                                                  Get.to(
                                                      () => ProductDetailPage(
                                                            isfav:
                                                                isItemFavorite(
                                                                    item),
                                                            producttitle:
                                                                item['title']!,
                                                            productdesc: item[
                                                                'description']!,
                                                            productimage:
                                                                item['image']!,
                                                            producturl:
                                                                item['url']!,
                                                          ),
                                                      transition: Transition
                                                          .cupertinoDialog,
                                                      duration: const Duration(
                                                          milliseconds: 300));
                                                },
                                                child: ProductCard(
                                                  title: item['title']!,
                                                  imagePath: item['image']!,
                                                  isFavorite:
                                                      isItemFavorite(item),
                                                  onTap: () {
                                                    // Handle "View Details"
                                                    Get.to(
                                                        () => ProductDetailPage(
                                                              isfav:
                                                                  isItemFavorite(
                                                                      item),
                                                              producttitle:
                                                                  item[
                                                                      'title']!,
                                                              productdesc: item[
                                                                  'description']!,
                                                              productimage:
                                                                  item[
                                                                      'image']!,
                                                              producturl:
                                                                  item['url']!,
                                                            ),
                                                        transition: Transition
                                                            .cupertinoDialog,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300));
                                                  },
                                                  onFavoriteToggle: () =>
                                                      toggleFavorite(item),
                                                ),
                                              );
                                            },
                                          ),
                                  ),

                                  //Text(" Downloads "),
                                  SizedBox(
                                    height: 350,
                                    child: StreamBuilder<List<File>>(
                                      stream: _pdfFilesStream(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No downloads',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          );
                                        }

                                        final pdfFiles = snapshot.data!;

                                        return GridView.builder(
                                          padding: const EdgeInsets.all(6),
                                          itemCount: pdfFiles.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                screenWidth > 450 ? 4 : 3,
                                            childAspectRatio: 0.62,
                                            mainAxisSpacing: 6,
                                            crossAxisSpacing: 6,
                                          ),
                                          itemBuilder: (context, index) {
                                            final file = pdfFiles[index];
                                            final fileName =
                                                file.path.split('/').last;

                                            return GestureDetector(
                                              onTap: () => _openPdf(file),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.doc,
                                                    size: 75,
                                                    color: Provider.of<ThemeProvider>(
                                                                    context)
                                                                .themeMode ==
                                                            ThemeMode.dark
                                                        ? CommanColor.white
                                                        : CommanColor
                                                            .darkPrimaryColor,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: Text(
                                                      fileName,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  )
                                  // SizedBox(
                                  //   height: 350,
                                  //   child: pdfFiles.isEmpty
                                  //       ? Center(
                                  //           child: Text(
                                  //             'No downloads',
                                  //             style: TextStyle(
                                  //                 fontSize: 16,
                                  //                 fontWeight: FontWeight.w500),
                                  //           ),
                                  //         )
                                  //       : GridView.builder(
                                  //           padding: const EdgeInsets.all(6),
                                  //           itemCount: pdfFiles.length,
                                  //           gridDelegate:
                                  //               const SliverGridDelegateWithFixedCrossAxisCount(
                                  //             crossAxisCount: 3,
                                  //             childAspectRatio: 0.62,
                                  //             mainAxisSpacing: 6,
                                  //             crossAxisSpacing: 6,
                                  //           ),
                                  //           itemBuilder: (context, index) {
                                  //             final file = pdfFiles[index];
                                  //             final fileName =
                                  //                 file.path.split('/').last;

                                  //             // if (pdfFiles.isEmpty) {
                                  //             //   return Center(
                                  //             //     child: Text(
                                  //             //       'No downloads',
                                  //             //       style: TextStyle(
                                  //             //           fontSize: 16,
                                  //             //           fontWeight: FontWeight.w500),
                                  //             //     ),
                                  //             //   );
                                  //             // }
                                  //             return GestureDetector(
                                  //                 onTap: () {
                                  //                   _openPdf(file);
                                  //                 },
                                  //                 child: Column(
                                  //                   mainAxisAlignment:
                                  //                       MainAxisAlignment.start,
                                  //                   crossAxisAlignment:
                                  //                       CrossAxisAlignment
                                  //                           .start,
                                  //                   children: [
                                  //                     const Icon(
                                  //                         CupertinoIcons.doc,
                                  //                         size: 75,
                                  //                         color: CommanColor
                                  //                             .darkPrimaryColor),
                                  //                     Padding(
                                  //                       padding:
                                  //                           const EdgeInsets
                                  //                               .all(4.0),
                                  //                       child: Text(fileName),
                                  //                     ),
                                  //                   ],
                                  //                 ));
                                  //           },
                                  //         ),
                                  // ),
                                ]),
                          ),
                        ],
                      );
                    })),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadLimitIndicator extends StatelessWidget {
  final Color backgroundColor;

  const DownloadLimitIndicator({
    super.key,
    this.backgroundColor = const Color(0xFF86502D),
  });

  Future<Map<String, dynamic>> _loadPlan(context) async {
    final plan = await Provider.of<DownloadProvider>(
      context,
    ).getSubscriptionPlan();
    String? planIcon;
    int? limit;

    switch (plan) {
      case "platinum":
        limit = -1; // unlimited
        planIcon = "assets/sp3.png";
        break;
      case "gold":
        limit = 12;
        planIcon = "assets/sp2.png";
        break;
      case "silver":
        limit = 4;
        planIcon = "assets/sp1.png";
        break;
      default:
        limit = 0;
        planIcon = null;
    }

    return {
      "plan": plan ?? "none",
      "limit": limit,
      "planIcon": planIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPlan(context),
      builder: (context, planSnapshot) {
        if (!planSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final planData = planSnapshot.data!;
        final bool isUnlimited =
            planData["limit"] == null || planData["limit"] == -1;

        // 🔥 Directly listen to stream for live updates
        return StreamBuilder<int>(
          stream:
              DownloadProvider.getUsedLimitStream(), // must return Stream<int>
          // initialData: Provider.of<DownloadProvider>(context, listen: false)
          //     .getusedlimit(),
          builder: (context, snapshot) {
            final used = snapshot.data ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context).themeMode ==
                        ThemeMode.dark
                    ? CommanColor.black
                    : backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (planData["planIcon"] != null)
                    Image.asset(
                      planData["planIcon"],
                      width: 21,
                      height: 21,
                    )
                  else
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black54, width: 1),
                      ),
                      child:
                          const Icon(Icons.star, size: 16, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlimited ? '∞' : '$used/${planData["limit"]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// class DownloadLimitIndicator extends StatefulWidget {
//   final Color backgroundColor;

//   const DownloadLimitIndicator({
//     super.key,
//     this.backgroundColor = const Color(0xFF86502D),
//   });

//   @override
//   State<DownloadLimitIndicator> createState() => _DownloadLimitIndicatorState();
// }

// class _DownloadLimitIndicatorState extends State<DownloadLimitIndicator> {
//   String? plan;
//   int used = 0;
//   int? limit; // null/-1 for unlimited
//   String? planIcon;

//   @override
//   void initState() {
//     super.initState();
//     _loadPlanAndUsage();
//   }

//   Future<void> _loadPlanAndUsage() async {
//     final p = await BookDownloadManager.getSubscriptionPlan();
//     final usedCount = await BookDownloadManager.getUsedLimit();

//     setState(() {
//       plan = p ?? "none";
//       used = usedCount;

//       // Set limit and icon based on plan
//       if (plan == "platinum") {
//         limit = -1;
//         planIcon = "assets/sp3.png"; // your image
//       } else if (plan == "gold") {
//         limit = 12;
//         planIcon = "assets/sp2.png";
//       } else if (plan == "silver") {
//         limit = 4;
//         planIcon = "assets/sp1.png";
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isUnlimited = limit == null || limit == -1;
//     //  double screenWidth = MediaQuery.of(context).size.width;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: widget.backgroundColor,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (planIcon != null)
//             Image.asset(
//               planIcon!,
//               width: 21,
//               height: 21,
//             )
//           else
//             Container(
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white,
//                 border: Border.all(color: Colors.black54, width: 1),
//               ),
//               child: const Icon(Icons.star, size: 16, color: Colors.grey),
//             ),
//           const SizedBox(width: 8),
//           Text(
//             isUnlimited ? '$used/∞' : '$used/$limit',
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class ProductCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 157, 112, 95),
            blurRadius: 3,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: screenWidth < 380
                        ? 14
                        : screenWidth > 450
                            ? 17
                            : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Image
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(8),
          //   child: Image.network(
          //     imagePath,
          //     height: 160,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              // useOldImageOnUrlChange: true,
              imageUrl: imagePath,
              height: screenWidth > 450 ? 220 : 160,
              memCacheHeight: screenWidth > 450 ? 220 : 160,
              fit: BoxFit.cover,
              // placeholder: (context, url) => Center(
              //   child: CircularProgressIndicator(
              //     color: CommanColor.darkPrimaryColor,
              //   ),
              // ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          const Spacer(),

          // View Details and Heart Icon
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  // style: ElevatedButton.styleFrom(
                  //   backgroundColor: Colors.brown,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                  // ),
                  child: Container(
                    height: screenWidth < 380
                        ? 30
                        : screenWidth > 450
                            ? 37
                            : 35,
                    decoration: BoxDecoration(
                      color: CommanColor.darkPrimaryColor,
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2)
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'View Details',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 380
                                ? 13
                                : screenWidth > 450
                                    ? 16
                                    : 14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onFavoriteToggle,
                child: Icon(
                  size: screenWidth > 450 ? 35 : null,
                  isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: CommanColor.darkPrimaryColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildCustomButton({
    required BuildContext context,
    required String text,
    required double width,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String text,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    double width = 120,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Alert for already purchased product (from e-product 65.jpg)
  void showProductPurchasedAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isTablet = MediaQuery.of(context).size.width > 600;
        final double dialogWidth =
            isTablet ? 400 : MediaQuery.of(context).size.width * 0.8;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alert!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This product already purchased!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildDialogButton(
                  text: 'OK',
                  onPressed: () => Navigator.of(context).pop(),
                  width: 100,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Alert for needing to buy a plan (from e-product 54.jpg)
  void showBuyPlanAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isTablet = MediaQuery.of(context).size.width > 600;
        final double dialogWidth =
            isTablet ? 450 : MediaQuery.of(context).size.width * 0.85;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alert!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Buy any plan to purchase e-Products!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialogButton(
                      text: 'View Plans',
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to plans page
                      },
                      backgroundColor: Colors.blue,
                    ),
                    _buildDialogButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Alert for reaching download limits (from e-product 64.jpg)
  void showReachedLimitAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isTablet = MediaQuery.of(context).size.width > 600;
        final double dialogWidth =
            isTablet ? 450 : MediaQuery.of(context).size.width * 0.85;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reached your limits!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If you want more products, purchase a plan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialogButton(
                      text: 'Go to Plan',
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to plans page
                      },
                      backgroundColor: Colors.blue,
                    ),
                    _buildDialogButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Alert for successful subscription (from e-product 56.jpg)
  void showSubscriptionSuccessAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isTablet = MediaQuery.of(context).size.width > 600;
        final double dialogWidth =
            isTablet ? 500 : MediaQuery.of(context).size.width * 0.9;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Purchase Successful!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congrats, You are subscribed to the Silver Plan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your favorite 4 products',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildDialogButton(
                  text: 'Go to List',
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to product list
                  },
                  width: 150,
                  backgroundColor: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Note: This is not a subscription. This is a one-time purchase to access digital Bible Product.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class PdfViewScreen extends StatelessWidget {
//   final String filePath;
//   const PdfViewScreen({super.key, required this.filePath});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(filePath.split('/').last)),
//       body: PDFView(
//         filePath: filePath,
//         enableSwipe: true,
//         swipeHorizontal: false,
//         autoSpacing: true,
//         pageFling: true,
//       ),
//     );
//   }
// }

class PdfViewScreen extends StatefulWidget {
  final String filePath;
  const PdfViewScreen({super.key, required this.filePath});

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  final PdfViewerController _controller = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.zoom_in),
          //   onPressed: () => _controller.zoomLevel += 0.25,
          // ),
          // IconButton(
          //   icon: const Icon(Icons.zoom_out),
          //   onPressed: () => _controller.zoomLevel -= 0.25,
          // ),

          // IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () => _controller.previousPage(),
          // ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              saveFileWithShareSheet(widget.filePath);
              // await saveFileToDocumentsOrDownloads(
              //   widget.filePath,
              //   widget.filePath.split('/').last,
              // );
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.filePath),
        controller: _controller,
      ),
    );
  }

// filePath is the local path of the file you want to export
  void saveFileWithShareSheet(String filePath) {
    Share.shareXFiles(
      [XFile(filePath)],
      fileNameOverrides: [filePath.split('/').last],
      sharePositionOrigin: Rect.fromPoints(
        const Offset(2, 2),
        const Offset(3, 3),
      ),
    );
  }

  Future<String> saveFileToDocumentsOrDownloads(
      String tempFilePath, String fileName) async {
    final tempFile = File(tempFilePath);
    if (!await tempFile.exists()) {
      throw Exception("File not found at $tempFilePath");
    }

    Directory? targetDir;

    if (Platform.isAndroid) {
      // Request permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission denied");
      }

      // Android - Downloads folder
      targetDir = Directory("/storage/emulated/0/Download");
      if (!await targetDir.exists()) {
        targetDir = await getExternalStorageDirectory(); // fallback
      }
    } else if (Platform.isIOS) {
      // iOS - Documents directory
      targetDir = await getApplicationDocumentsDirectory();
    }

    final newPath = "${targetDir!.path}/$fileName";
    final savedFile = await tempFile.copy(newPath);
    Constants.showToast("File saved at this path: $newPath");

    debugPrint("new file path - $newPath");

    return savedFile.path;
  }
}
