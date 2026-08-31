import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/product_subc_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final bool isfav;
  final String producttitle;
  final String productdesc;
  final String productimage;
  final String producturl;

  const ProductDetailPage(
      {super.key,
      required this.isfav,
      required this.producttitle,
      required this.productdesc,
      required this.productimage,
      required this.producturl});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool check = false;
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint(widget.producturl);
    return Scaffold(
      // //  backgroundColor: const Color(0xFFF2E2C4), // Background similar to image
      // appBar: AppBar(
      //   // backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: const Icon(Icons.arrow_back, color: Colors.black),
      //   title: const Text(
      //     'Product Details',
      //     style: TextStyle(
      //       color: Colors.black,
      //       fontWeight: FontWeight.w600,
      //     ),
      //   ),
      //   centerTitle: true,
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
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 5),
                // Image Section with Title
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
                        "Product Details",
                        style: CommanStyle.appBarStyle(context).copyWith(
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 30
                                : BibleInfo.fontSizeScale * 18,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    SizedBox(),
                  ],
                ),
                SizedBox(height: screenWidth < 380 ? 4 : 15),
                // Container(
                //   margin: EdgeInsets.all(screenWidth < 380 ? 12 : 16),
                //   padding: EdgeInsets.all(screenWidth < 380 ? 12 : 16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.end,
                //         children: [
                //           Padding(
                //             padding: EdgeInsets.only(right: 16.0),
                //             child: Icon(
                //                 isfav
                //                     ? CupertinoIcons.heart_fill
                //                     : CupertinoIcons.heart,
                //                 color: Colors.brown),
                //           ),
                //         ],
                //       ),
                //       SizedBox(height: screenWidth < 380 ? 6 : 12),
                //       // const Text(
                //       //   "Every chapter of the Bible across two pages",
                //       //   style: TextStyle(
                //       //     fontSize: 16,
                //       //     color: Colors.brown,
                //       //     fontWeight: FontWeight.w500,
                //       //   ),
                //       //   textAlign: TextAlign.center,
                //       // ),
                //       // const SizedBox(height: 12),

                //       const SizedBox(height: 12),
                //       // const Icon(
                //       //   Icons.more_horiz,
                //       //   color: Colors.brown,
                //       // )
                //     ],
                //   ),
                // ),
                Stack(
                  children: [
                    // ClipRRect(
                    //   borderRadius: BorderRadius.circular(3),
                    //   child: Image.network(
                    //     widget.productimage, // Replace with your asset
                    //     height: screenWidth < 380 ? 190 : 190,
                    //     width: screenWidth < 380 ? 300 : 290,
                    //     fit: BoxFit.fill,
                    //   ),
                    // ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: CachedNetworkImage(
                        imageUrl: widget.productimage,
                        height: screenWidth > 450
                            ? 350
                            : screenWidth < 380
                                ? 190
                                : 190,
                        width: screenWidth > 450
                            ? 450
                            : screenWidth < 380
                                ? 300
                                : 290,
                        fit: BoxFit.fill,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: CommanColor.darkPrimaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                            color:
                                CommanColor.lightGrey1.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(15)),
                        child: Center(
                          child: Icon(
                              widget.isfav
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: Colors.brown),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // Product Title and Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.producttitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.white
                                  : Colors.brown,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.productdesc,
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                Provider.of<ThemeProvider>(context).themeMode ==
                                        ThemeMode.dark
                                    ? CommanColor.white
                                    : Colors.black87),
                      ),
                      SizedBox(height: 20),

                      // Item details
                      Text(
                        'Item details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.white
                                  : Colors.brown,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Digital download'),
                      Text('• Digital file type(s): 2 PDF, 1 PNG'),
                      SizedBox(height: 20),

                      // Delivery
                      Text(
                        'Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.white
                                  : Colors.brown,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Your files will be available to download once payment is confirmed.',
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Instant download items don’t accept returns, exchanges or cancellations. Please contact the seller about any problems with your order.',
                      ),
                      SizedBox(height: 12), // Bottom spacing for Buy button
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      // Handle buy
                      await handleBookDownload(
                        widget.producttitle,
                        widget.producturl,
                        context,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Provider.of<ThemeProvider>(context).themeMode ==
                                  ThemeMode.dark
                              ? check == true
                                  ? const Color.fromARGB(255, 64, 64, 64)
                                  : CommanColor.black
                              : check == true
                                  ? const Color.fromARGB(255, 105, 94, 89)
                                  : Colors.brown,
                      fixedSize: Size(screenWidth, 45),

                      /// padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      check == true ? 'loading...' : 'Buy',
                      style: TextStyle(
                          fontSize: check == true ? 15 : 18,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleBookDownload(
      String bookId, String bookUrl, context) async {
    // bool hasPermission = await requestPermission(context);
    // if (!hasPermission) return;

    final bookDownloadManager =
        Provider.of<DownloadProvider>(context, listen: false);
    setState(() {
      check = true;
    });
    try {
      final downloaded = await bookDownloadManager.trackDownload(bookId);
      bookDownloadManager.setkbookloading(true);
      if (!downloaded) {
        // Already downloaded
        Constants.showToast("Book already downloaded.");
        bookDownloadManager.setkbookloading(false);
        setState(() {
          check = false;
        });
        return;
      }
      final allowed = await bookDownloadManager.canDownloadMore();
      final isfree = await bookDownloadManager.hasUsedFreeDownload();
      if (allowed == false && isfree == true) {
        // Show alert to upgrade plan
        debugPrint("Upgrade plan to download more books.");
        await bookDownloadManager.resetUsedLimit();
        bookDownloadManager.setkbookloading(false);
        setState(() {
          check = false;
        });
        return showDialog(
          context: context,
          builder: (_) => CustomAlertBox(
            title: "Alert!",
            message: "Buy any plan to purchase e-Products!",
            buttons: [
              AlertButton(
                text: "Views Plans",
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(() => const SubscriptionPlanPage(),
                      transition: Transition.cupertinoDialog,
                      duration: const Duration(milliseconds: 300));
                  //  Navigator.pop(context);
                  // Navigate to list screen
                },
              ),
            ],
          ),
        );
      } else {
        debugPrint('Book downloaded run');
        final path = await downloadBook(bookUrl, bookId, context);
        await bookDownloadManager.markFreeDownloadUsed();
        bookDownloadManager.setkbookloading(false);
        setState(() {
          check = false;
        });
        if (path != null) {
          debugPrint('Book downloaded to: $path');
          // Show success
        }
      }
    } catch (e) {
      bookDownloadManager.setkbookloading(false);
      setState(() {
        check = false;
      });
      debugPrint('Book downloaded error: $e');
    }
  }

  String toDirectDownloadLink(String url) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return "https://drive.google.com/uc?export=download&id=$fileId";
    }
    return url;
  }

  Future<String?> downloadBook(String url, String fileName, context) async {
    final bookDownloadManager =
        Provider.of<DownloadProvider>(context, listen: false);
    final current = await bookDownloadManager.getDownloadedBooks();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName.pdf';

      // debugPrint('Book download path: $savePath');
      String convertedUrl = toDirectDownloadLink(url);
      debugPrint('Book download path: $convertedUrl');
      await Dio().download(convertedUrl, savePath);
      current.add(fileName);
      debugPrint("list of book d - $current");
      await bookDownloadManager.setDownloadedBooks(current);
      await bookDownloadManager.incrementUsedLimit();
      Constants.showToast('Download completed');
      return savePath;
    } catch (e) {
      Constants.showToast('Download failed: $e');
      return null;
    }
  }
}

// class BookDownloadManager
// //with ChangeNotifier
// {
//   static const _downloadsKey = 'downloaded_books';
//   static const _planKey = 'subscription_plan';
//   static const _usedFreeDownloadKey = 'used_free_download';
//   static const _usedLimitKey = 'used_download_count';

//   // Save user's subscription plan
//   static Future<void> setSubscriptionPlan(String plan) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_planKey, plan);
//     // 'silver', 'gold', 'platinum'
//     // notifyListeners();
//   }

//   static Future<String?> getSubscriptionPlan() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_planKey);
//   }

//   // Get already downloaded book IDs
//   static Future<List<String>> getDownloadedBooks() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getStringList(_downloadsKey) ?? [];
//   }

//   static Future<bool> setDownloadedBooks(List<String> books) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.setStringList(_downloadsKey, books);
//   }

//   // Check if user has used free download
//   static Future<bool> hasUsedFreeDownload() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_usedFreeDownloadKey) ?? false;
//   }

//   static Future<void> markFreeDownloadUsed() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_usedFreeDownloadKey, true);
//   }

//   static Future<int> getUsedLimit() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_usedLimitKey) ?? 0;
//   }

//   static Stream<int> getUsedLimitSteam() async* {
//     final prefs = await SharedPreferences.getInstance();
//     yield prefs.getInt(_usedLimitKey) ?? 0;
//   }

//   static Future<void> setUsedLimit(int count) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_usedLimitKey, count);
//   }

//   static Future<void> incrementUsedLimit() async {
//     final prefs = await SharedPreferences.getInstance();
//     int current = prefs.getInt(_usedLimitKey) ?? 0;
//     await prefs.setInt(_usedLimitKey, current + 1);
//   }

//   static Future<void> resetUsedLimit() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_usedLimitKey, 0);
//   }

//   // Main logic: Can user download another book?
//   static Future<bool> canDownloadMore() async {
//     final usedFree = await hasUsedFreeDownload();
//     final downloads = await getDownloadedBooks();
//     final plan = await getSubscriptionPlan();
//     debugPrint(
//         "check download $plan ${downloads.length}  $usedFree  ${downloads.isEmpty} - ${usedFree && downloads.isEmpty}");
//     // Allow 1st download if free not used
//     if (usedFree && downloads.isEmpty) return true;

//     // final plan = await getSubscriptionPlan();
//     if (plan == 'platinum') return true;
//     if (plan == 'gold') return downloads.length < 13;
//     if (plan == 'silver') return downloads.length < 5;
//     return false;
//   }

// // check plan active
//   static Future<bool> isplanactive() async {
//     final plan = await getSubscriptionPlan();
//     debugPrint("check plan $plan ");

//     // final plan = await getSubscriptionPlan();
//     if (plan == 'platinum') return true;
//     if (plan == 'gold') return true;
//     if (plan == 'silver') return true;
//     return false;
//   }

//   static Stream<bool> isPlanActiveStream() async* {
//     // Emit initial value
//     final plan = await getSubscriptionPlan();
//     yield _isActive(plan);

//     // // Listen for future changes in SharedPreferences (if any)
//     // final prefs = await SharedPreferences.getInstance();
//     // yield* prefs
//     //     .getKeysStream() // <-- needs a wrapper function to detect changes
//     //     .asyncMap((_) async {
//     //   final newPlan = await getSubscriptionPlan();
//     //   return _isActive(newPlan);
//     // });
//   }

// // Helper function to avoid repeating logic
//   static bool _isActive(String? plan) {
//     if (plan == null) return false;
//     return ['platinum', 'gold', 'silver'].contains(plan.toLowerCase());
//   }

//   // Track download: mark it and track free/plan-based
//   static Future<bool> trackDownload(String bookId) async {
//     // final prefs = await SharedPreferences.getInstance();
//     final current = await getDownloadedBooks();

//     if (current.contains(bookId)) return false;

//     // If first-time free, mark it
//     final usedFree = await hasUsedFreeDownload();
//     if (!usedFree && current.isEmpty) {
//       await markFreeDownloadUsed();
//     }

//     // current.add(bookId);
//     // debugPrint("list of book d - $current");
//     // await setDownloadedBooks(current);
//     // await prefs.setStringList(_downloadsKey, current);
//     return true;
//   }
// }
