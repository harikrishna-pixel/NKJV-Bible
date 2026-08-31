// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
// import 'package:biblebookapp/Model/product_details_model.dart' as m;
// import 'package:biblebookapp/core/notifiers/download.notifier.dart';
// import 'package:biblebookapp/utils/debugprint.dart';
// import 'package:biblebookapp/view/constants/share_preferences.dart';
// import 'package:biblebookapp/view/constants/theme_provider.dart';
// import 'package:biblebookapp/view/screens/dashboard/constants.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:http/http.dart' as http;
// import 'package:biblebookapp/controller/api_service.dart';
// import 'package:biblebookapp/view/constants/colors.dart';
// import 'package:biblebookapp/view/constants/constant.dart';
// import 'package:biblebookapp/view/constants/images.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher_string.dart';
// import '../../../controller/dashboard_controller.dart';
//
// DateTime addSixMonths({DateTime? customDate}) {
//   final date = customDate ?? DateTime.now();
//   int year = date.year;
//   int month = date.month + 6;
//
//   if (month > 12) {
//     year += 1;
//     month -= 12;
//   }
//
//   int day = date.day;
//
//   // Adjust the day if it exceeds the number of days in the target month
//   int daysInNewMonth = DateTime(year, month + 1, 0).day;
//   if (day > daysInNewMonth) {
//     day = daysInNewMonth;
//   }
//
//   return DateTime(year, month, day);
// }
//
// rewardEarned(BuildContext context, Function() onTap) {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog(
//           backgroundColor: CommanColor.white,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           elevation: 16,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   "Rewards claimed! Enjoy ad-free reward for 3 days from now!",
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 20),
//                 GestureDetector(
//                   onTap: onTap,
//                   child: Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 32),
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         color: CommanColor.whiteLightModePrimary(context),
//                         borderRadius:
//                             const BorderRadius.all(Radius.circular(5)),
//                         boxShadow: const [
//                           BoxShadow(color: Colors.black26, blurRadius: 2)
//                         ],
//                       ),
//                       child: Text(
//                         'Okay',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             letterSpacing: BibleInfo.letterSpacing,
//                             fontSize: BibleInfo.fontSizeScale * 14,
//                             fontWeight: FontWeight.w500,
//                             color: CommanColor.darkModePrimaryWhite(context)),
//                       )),
//                 ),
//               ],
//             ),
//           ));
//     },
//   );
// }
//
// class RemoveAddScreen extends StatefulWidget {
//   final String sixMonthPlan;
//   final String oneYearPlan;
//   final String lifeTimePlan;
//   final String checkad;
//   Function? onclick;
//   RemoveAddScreen(
//       {super.key,
//       required this.sixMonthPlan,
//       required this.oneYearPlan,
//       required this.lifeTimePlan,
//       required this.checkad,
//       this.onclick});
//
//   @override
//   State<RemoveAddScreen> createState() => _RemoveAddScreenState();
// }
//
// class _RemoveAddScreenState extends State<RemoveAddScreen> {
//   bool isPurchaseLoading = false;
//   bool isRestoreLoading = false;
//   bool userTap = false;
//   List<ProductDetails> _products = [];
//
//   DownloadProvider? _myProvider;
// //// In App Purchase
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
// // subscription that listens to a stream of updates to purchase details
//   StreamSubscription<List<PurchaseDetails>>? _subscription;
//   late Stream<List<PurchaseDetails>> _purchaseUpdatedStream;
// // checks if the API is available on this device
//   bool _isAvailable = false;
// // keeps a list of products queried from Playstore or app store
//
// // List of users past purchases
//
//   // checks if a user has purchased a certain product
//   PurchaseDetails? _hasUserPurchased(String productID) {
//     return null;
//   }
//
//   Future<void> _buyProduct(ProductDetails prod) async {
//     // Check connectivity FIRST before showing loader
//     final hasInternet = await InternetConnection().hasInternetAccess;
//     if (!hasInternet) {
//       Constants.showToast("No Internet connection");
//       return; // Return early - don't show loader or proceed
//     }
//
//     if (!userTap) {
//       log("Buy Product");
//       try {
//         setState(() {
//           userTap = true;
//         });
//         EasyLoading.show();
//         await SharPreferences.setString('OpenAd', '1');
//
//         final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
//         await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
//       } catch (e) {
//         log('Error: $e');
//       } finally {
//         setState(() {
//           userTap = false;
//         });
//       }
//     }
//   }
//
//   restorePurchaseHandle(
//       String productId, String date, DashBoardController controller, {BuildContext? context}) async {
//     await SharPreferences.setString('OpenAd', '1');
//     final dateTime = DateTime.tryParse(date) ?? DateTime.now();
//     await Future.delayed(Duration(seconds: 2));
//     final data = await SharPreferences.getBoolean('restorepurches');
//     debugPrint("restore data 1 is $data");
//     if (data == true) {
//       // Get DownloadProvider to set subscription plan
//       DownloadProvider? downloadProvider;
//       if (context != null) {
//         downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
//       } else {
//         // Try to get from Get.context as fallback
//         final getContext = Get.context;
//         if (getContext != null) {
//           downloadProvider = Provider.of<DownloadProvider>(getContext, listen: false);
//         }
//       }
//
//       if (productId == widget.lifeTimePlan) {
//         await controller.disableAd(const Duration(days: 3650012345));
//         // Set subscription plan to platinum for lifetime plan
//         if (downloadProvider != null) {
//           await downloadProvider.setSubscriptionPlan('platinum');
//         }
//         await Future.delayed(Duration(seconds: 1));
//         EasyLoading.dismiss();
//         await SharPreferences.setBoolean('closead', true);
//         Constants.showToast('Restore Successful');
//         await Future.delayed(Duration(seconds: 1));
//         return Get.back();
//       } else if (productId == widget.oneYearPlan) {
//         final dur = DateTime(dateTime.year + 1, dateTime.month, dateTime.day);
//         final diff = dur.difference(DateTime.now());
//         await controller.disableAd(diff);
//         // Set subscription plan to gold for one year plan
//         if (downloadProvider != null) {
//           await downloadProvider.setSubscriptionPlan('gold');
//         }
//         await Future.delayed(Duration(seconds: 1));
//         EasyLoading.dismiss();
//         // Constants.showToast('Restore Successful');
//         await SharPreferences.setBoolean('closead', true);
//
//         Constants.showToast('Restore Successful');
//         await Future.delayed(Duration(seconds: 1));
//         return Get.back();
//       } else if (productId == widget.sixMonthPlan) {
//         final dur = addSixMonths(customDate: dateTime);
//         final diff = dur.difference(DateTime.now());
//         await controller.disableAd(diff);
//         // Set subscription plan to silver for six month plan
//         if (downloadProvider != null) {
//           await downloadProvider.setSubscriptionPlan('silver');
//         }
//         await Future.delayed(Duration(seconds: 1));
//         EasyLoading.dismiss();
//         await SharPreferences.setBoolean('closead', true);
//         Constants.showToast('Restore Successful');
//         await Future.delayed(Duration(seconds: 1));
//         return Get.back();
//       }
//     }
//     // final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//     //     _inAppPurchase
//     //         .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//     // await iosPlatformAddition.setDelegate(null);
//     // await _subscription?.cancel();
//
//     // await Future.delayed(Duration(seconds: 1));
//     // EasyLoading.dismiss();
//     // await SharPreferences.setBoolean('closead', true);
//     // Get.back();
//     // return Get.offAll(() => HomeScreen(
//     //       From: "splash",
//     //       selectedVerseNumForRead: "",
//     //       selectedBookForRead: "",
//     //       selectedChapterForRead: "",
//     //       selectedBookNameForRead: "",
//     //       selectedVerseForRead: "",
//     //     ));
//   }
//
//   void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList,
//       DashBoardController controller) {
//     // ignore: avoid_function_literals_in_foreach_calls
//     purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//       log("Purchase State: ${purchaseDetails.status}");
//       await SharPreferences.setString('OpenAd', '1');
//       if (purchaseDetails.status == PurchaseStatus.pending) {
//       } else {
//         if (purchaseDetails.status == PurchaseStatus.error) {
//           log('Error: ${purchaseDetails.error}');
//           EasyLoading.dismiss();
//           DebugConsole.log(" purchases error - $purchaseDetails");
//         } else if (purchaseDetails.status == PurchaseStatus.purchased ||
//             purchaseDetails.status == PurchaseStatus.restored) {
//           if (purchaseDetails.status == PurchaseStatus.purchased) {
//             final data1 = await SharPreferences.getBoolean('startpurches');
//             debugPrint("purchase data 5 is $data1");
//             if (data1 == true) {
//               if (Platform.isIOS) {
//                 //  var response =
//                 http.post(
//                   Uri.parse(kDebugMode
//                       ? 'https://sandbox.itunes.apple.com/verifyReceipt'
//                       : 'https://buy.itunes.apple.com/verifyReceipt'),
//                   headers: {
//                     'Accept': 'application/json',
//                     'Content-Type': 'application/json',
//                   },
//                   body: {
//                     'receipt-data':
//                         purchaseDetails.verificationData.localVerificationData,
//                     'exclude-old-transactions': true,
//                     'password': controller.sharedSecret
//                   },
//                 );
//
//                 // DebugConsole.log(
//                 //     "  purchases sucess frist : ${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()} - ${response.body}");
//
//                 // final data = parseHtmlAndExtractJson(response.body);
//                 await Future.delayed(Duration(seconds: 1));
//                 // DebugConsole.log(" purchases sucess - $data");
//                 await purchaseSubmit(
//                     receiptData:
//                         '${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()}');
//                 final todayDate = DateTime.now();
//                 await SharPreferences.setBoolean("downloadreward", true);
//                 await Future.delayed(Duration(seconds: 1));
//                 if (purchaseDetails.productID == widget.sixMonthPlan) {
//                   final expiryDate = addSixMonths();
//                   final diff = expiryDate.difference(todayDate);
//                   await controller.disableAd(diff);
//                   await Future.delayed(Duration(seconds: 2));
//                   EasyLoading.dismiss();
//                   await SharPreferences.setBoolean('closead', true);
//                   return Get.back();
//                 } else if (purchaseDetails.productID == widget.oneYearPlan) {
//                   await controller.disableAd(const Duration(days: 366));
//                   await Future.delayed(Duration(seconds: 2));
//                   EasyLoading.dismiss();
//                   await SharPreferences.setBoolean('closead', true);
//                   return Get.back();
//                 } else if (purchaseDetails.productID == widget.lifeTimePlan) {
//                   await controller.disableAd(const Duration(days: 3650012345));
//                   await Future.delayed(Duration(seconds: 2));
//                   EasyLoading.dismiss();
//                   await SharPreferences.setBoolean('closead', true);
//                   return Get.back();
//                 }
//                 // final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//                 //     _inAppPurchase.getPlatformAddition<
//                 //         InAppPurchaseStoreKitPlatformAddition>();
//                 // await iosPlatformAddition.setDelegate(null);
//
//                 // return Get.offAll(
//                 //   () => HomeScreen(
//                 //     From: "splash",
//                 //     selectedVerseNumForRead: "",
//                 //     selectedBookForRead: "",
//                 //     selectedChapterForRead: "",
//                 //     selectedBookNameForRead: "",
//                 //     selectedVerseForRead: "",
//                 //   ),
//                 // );
//
//                 // return Get.offAll(() => HomeScreen(
//                 //       From: "splash",
//                 //       selectedVerseNumForRead: "",
//                 //       selectedBookForRead: "",
//                 //       selectedChapterForRead: "",
//                 //       selectedBookNameForRead: "",
//                 //       selectedVerseForRead: "",
//                 //     ));
//               }
//             }
//           } else if (purchaseDetails.status == PurchaseStatus.restored) {
//             // setState(() {
//             //   isRestoreLoading = false;
//             // });
//             // EasyLoading.dismiss();
//             final data =
//                 await SharPreferences.getBoolean('restorepurches') ?? false;
//             if (data == true) {
//               // await restorePurchaseHandle(purchaseDetails.productID,
//               //     purchaseDetails.transactionDate ?? '', controller);
//               _handleRestore(purchaseDetails, controller);
//             }
//             // await restorePurchaseHandle(purchaseDetails.productID,
//             //     purchaseDetails.transactionDate ?? '', controller);
//           }
//         } else if (purchaseDetails.pendingCompletePurchase) {
//           await InAppPurchase.instance.completePurchase(purchaseDetails);
//           EasyLoading.dismiss();
//         } else if (purchaseDetails.status == PurchaseStatus.canceled) {
//           EasyLoading.dismiss();
//           Constants.showToast('Something went wrong');
//         }
//       }
//     });
//   }
//
//   _initialize() async {
//     await SharPreferences.setBoolean('closead', false);
//     await SharPreferences.setString('OpenAd', '1');
//     await SharPreferences.setBoolean('restorepurches', false);
//     await SharPreferences.setBoolean('startpurches', false);
//     // final shouldLoadAd = await SharPreferences.shouldLoadAd();
//     // if (widget.checkad.isNotEmpty && shouldLoadAd) {
//     //   RewardedAdService.loadAd(
//     //       onAdLoaded: () {
//     //         setState(() {
//     //           _isAdLoaded = true;
//     //           isadloaded = true;
//     //         });
//     //         //  _rewardedAd = ad;
//     //       },
//     //       onAdFailed: () {
//     //         setState(() {
//     //           _isAdLoaded = false;
//     //           isadloaded = false;
//     //         });
//     //       },
//     //       data: "iap");
//     // }
//
//     // Provider.of<DownloadProvider>(context, listen: false).disableAd();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _myProvider = Provider.of<DownloadProvider>(context, listen: false);
//       _myProvider?.disableAd();
//     });
//     if (mounted) {
//       setState(() {
//         isPurchaseLoading = true;
//       });
//     }
//     // Check availability of InApp Purchases
//     _isAvailable = await _inAppPurchase.isAvailable();
//     debugPrint('Is Available: $_isAvailable');
//     // perform our async calls only when in-app purchase is available
//     if (_isAvailable) {
//       await _getUserProducts();
//       // _verifyPurchases();
//
//       // listen to new purchases and rebuild the widget whenever
//       // there is a new purchase after adding the new purchase to our
//       // purchase list
//       if (mounted) {
//         setState(() {
//           isPurchaseLoading = false;
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           isPurchaseLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _getUserProducts() async {
//     // setState(() {});
//     await SharPreferences.setBoolean('closead', false);
//     final productprovider =
//         Provider.of<DownloadProvider>(context, listen: false);
//
//     if (Platform.isIOS) {
//       final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//           _inAppPurchase
//               .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//       await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
//
//       Set<String> ids = {
//         widget.sixMonthPlan,
//         widget.oneYearPlan,
//         widget.lifeTimePlan
//       };
//
//       debugPrint(
//           "all plans - $ids  ${_products.isEmpty}  ${await _inAppPurchase.queryProductDetails(ids)}");
//       final datafn = await productprovider.loadProductList();
//
//       final datacheck = datafn.map((data) {
//         return ProductDetails(
//           id: data.id,
//           title: data.title,
//           description: data.description,
//           price: data.price,
//           rawPrice: data.rawPrice,
//           currencyCode: data.currencyCode,
//           currencySymbol: data.currencySymbol,
//         );
//       }).toList();
//
//       if (_products.isEmpty && datacheck.isEmpty) {
//         ProductDetailsResponse response =
//             await _inAppPurchase.queryProductDetails(ids);
//         debugPrint(
//             "all plans product 1 - ${response.error} ${response.notFoundIDs} ${response.productDetails}  ");
//         await Future.delayed(Duration(seconds: 10));
//
//         await productprovider
//             .saveProductList(response.productDetails.map((iapProduct) {
//           return m.ProductDetails(
//             id: iapProduct.id,
//             title: iapProduct.title,
//             description: iapProduct.description,
//             price: iapProduct.price,
//             rawPrice: iapProduct.rawPrice,
//             currencyCode: iapProduct.currencyCode,
//             currencySymbol: iapProduct.currencySymbol,
//           );
//         }).toList());
//         setState(() {
//           _products = response.productDetails;
//           _products.sort((a, b) => a.price.compareTo(b.price));
//         });
//       } else {
//         // ProductDetailsResponse response =
//         //     await _inAppPurchase.queryProductDetails(ids);
//         //  await Future.delayed(Duration(seconds: 1));
//         final data = await productprovider.loadProductList();
//
//         setState(() {
//           _products = data.map((data) {
//             return ProductDetails(
//               id: data.id,
//               title: data.title,
//               description: data.description,
//               price: data.price,
//               rawPrice: data.rawPrice,
//               currencyCode: data.currencyCode,
//               currencySymbol: data.currencySymbol,
//             );
//           }).toList();
//           _products.sort((a, b) => a.price.compareTo(b.price));
//         });
//       }
//
//       // if (_products.isEmpty) {
//       //   _initialize();
//       // }
//
//       // debugPrint("all plans product - $_products");
//     }
//   }
//
//   String? rewardedid;
//   // RewardedAd? _rewardedAd;
//   final bool _isAdShowing = false;
//   final bool _isAdLoaded = false;
//
//   int selectedindex = 0;
//
//   bool? isadloaded;
//   // AppLifecycleState _appState = AppLifecycleState.resumed;
//   final controller = Get.put(DashBoardController());
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//     // WidgetsBinding.instance.addObserver(this);
//     debugPrint("iap ad - WidgetsBinding");
//     // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//     //   _subscription = _inAppPurchase.purchaseStream.listen((data) {
//     //     final controller = Get.find<DashBoardController>();
//     //     _listenToPurchaseUpdated(data, controller);
//     //     setState(() {
//     //       _purchases.addAll(data);
//     //       _verifyPurchases();
//     //     });
//     //   });
//     // });
//     _purchaseUpdatedStream = InAppPurchase.instance.purchaseStream;
//     _purchaseUpdatedStream.listen(
//       (purchases) => _listenToPurchaseUpdated(purchases, controller),
//       onDone: () {
//         // _subscription?.cancel();
//       },
//       onError: (error) {
//         debugPrint("Purchase Stream Error: $error");
//       },
//     );
//     // _loadRewardedAd();
//   }
//
//   @override
//   void dispose() {
//     debugPrint("iap ad - dispose");
//     _subscription?.cancel();
//     // Call async clean-up without awaiting
//     alldispose();
//
//     super.dispose();
//   }
//
//   void alldispose() async {
//     if (Platform.isIOS) {
//       final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
//           _inAppPurchase
//               .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//       await iosPlatformAddition.setDelegate(null);
//       //  await _subscription?.cancel();
//     }
//   }
//
//   double calculateOriginalPrice(
//       double discountPercent, double discountedPrice) {
//     // Convert the discount percentage to a fraction
//     double discountFraction = discountPercent / 100;
//
//     // Calculate the original price using the formula: original price = discounted price / (1 - discount fraction)
//     double originalPrice = discountedPrice / (1 - discountFraction);
//
//     return originalPrice;
//   }
//
//   //new iap logic
//
//   /// 🔹 Handle restored purchases (after pressing restore button)
//   Future<void> _handleRestore(
//     PurchaseDetails purchaseDetails,
//     DashBoardController controller,
//   ) async {
//     //EasyLoading.dismiss();
//     debugPrint("Restored Purchase: ${purchaseDetails.productID}");
//
//     await restorePurchaseHandle(
//       purchaseDetails.productID,
//       purchaseDetails.transactionDate ?? '',
//       controller,
//       context: context,
//     );
//   }
//
//   /// 🔹 Trigger restore (iOS only)
//   Future<void> _restorePurchases(DashBoardController controller) async {
//     // Check connectivity first
//     final connectivityResult = await Connectivity().checkConnectivity();
//     if (connectivityResult[0] == ConnectivityResult.none) {
//       Constants.showToast("Check your Internet connection");
//       return;
//     }
//
//     // if (!Platform.isIOS) {
//     //   Constants.showToast("Restore is only available on iOS");
//     //   return;
//     // }
//
//     // setState(() {
//     //   isRestoreLoading = true;
//     // });
//     EasyLoading.show(status: "Restoring...");
//
//     // try {
//     //   // This triggers restored purchases to come via purchaseStream
//     //   await InAppPurchase.instance.restorePurchases();
//     //   Constants.showToast("Restore request sent");
//     // } catch (e) {
//     //   Constants.showToast("Restore failed: $e");
//     // }
//     await Future.delayed(Duration(seconds: 2));
//     // EasyLoading.dismiss();
//     // setState(() => isRestoreLoading = false);
//     //  await SharPreferences.setBoolean('restorepurches', true);
//     EasyLoading.dismiss();
//     await _inAppPurchase.restorePurchases();
//     // EasyLoading.dismiss();
//     setState(() {
//       isRestoreLoading = true;
//     });
//     await Future.delayed(Duration(seconds: 7));
//     try {
//       final res = await restorePurchase();
//       if (res['status'] == 'success') {
//         final rawData = res['data'].toString().split('-productId:');
//         if (rawData.length == 2) {
//           final data = rawData[1].split('-date:');
//           final productId = data[0].toString();
//           final date = data[1].toString();
//           await restorePurchaseHandle(productId, date, controller, context: context);
//         }
//       } else {
//         Constants.showToast('No active subscription available');
//         EasyLoading.dismiss();
//         setState(() {
//           isRestoreLoading = false;
//         });
//       }
//     } catch (e) {
//       EasyLoading.dismiss();
//       Constants.showToast(' error No active subscription available');
//       // setState(() {
//       isRestoreLoading = false;
//       // });
//       DebugConsole.log("restore No active subscription available error - $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     // return
//     // GetX<DashBoardController>(
//     //     init: DashBoardController(),
//     //     builder: (controller) {
//     // if (!controller.isRewardedAdLoaded!) {
//     //   controller.loadRewardedAd(
//     //       adUnitId: controller.rewardedAdUnitId.value);
//     // }
//     // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//     //   _subscription = _inAppPurchase.purchaseStream.listen((data) {
//     //     _listenToPurchaseUpdated(data, controller);
//     //     setState(() {
//     //       _purchases.addAll(data);
//     //       _verifyPurchases();
//     //     });
//     //   });
//     // });
//     // double? fakeOffer(ProductDetails product) {
//     //   if (product.id == widget.sixMonthPlan) {
//     //     return double.tryParse(controller.sixMonthPlanValue ?? '');
//     //   }
//     //   if (product.id == widget.oneYearPlan) {
//     //     return double.tryParse(controller.oneYearPlanValue ?? '');
//     //   }
//     //   if (product.id == widget.lifeTimePlan) {
//     //     return double.tryParse(controller.lifeTimePlanValue ?? '');
//     //   }
//
//     //   return null;
//     // }
//
//     // String getDiscountedPrice(ProductDetails product) {
//     //   final fakeOfferPercentage = fakeOffer(product);
//     //   if (fakeOfferPercentage != null) {
//     //     final fakePrice =
//     //         calculateOriginalPrice(fakeOfferPercentage, product.rawPrice);
//     //     return '${product.currencySymbol}${fakePrice.toStringAsFixed(2)}';
//     //   }
//     //   return '';
//     // }
//
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) async {
//         if (didPop) return;
//
//         if (_myProvider != null) {
//           _myProvider?.enableAd();
//         }
//         await SharPreferences.setBoolean('closead', true);
//         Get.back();
//       },
//       child: Scaffold(
//         body: Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
//                   AppCustomTheme.vintage
//               ? BoxDecoration(
//                   image: DecorationImage(
//                       image: AssetImage(Images.bgImage(context)),
//                       fit: BoxFit.fill))
//               : null,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             child: SingleChildScrollView(
//               child: SafeArea(
//                 child: Column(
//                   children: [
//                     const SizedBox(
//                       height: 6,
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SizedBox(),
//                         // Jesus Image
//                         Image.asset(
//                           "assets/offer/jesus.png", // Replace with your image
//                           height: size.height * 0.22,
//                           fit: BoxFit.contain,
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(
//                             right: 15.0,
//                             top: 6,
//                           ),
//                           child: GestureDetector(
//                             onTap: () async {
//                               if (_myProvider != null) {
//                                 _myProvider?.enableAd();
//                               }
//                               Get.back();
//                               await SharPreferences.setBoolean('closead', true);
//                               widget.onclick!();
//                             },
//                             child: Icon(
//                               Icons.close,
//                               size: 25,
//                               color: CommanColor.whiteBlack(context),
//                             ),
//                           ),
//                         ),
//                         // Padding(
//                         //   padding: const EdgeInsets.only(right: 40.0),
//                         //   child: Text("Remove Ads",
//                         //       style: CommanStyle.appBarStyle(context)),
//                         // ),
//                       ],
//                     ),
//                     SizedBox(height: size.height * 0.001),
//
//                     const SizedBox(height: 6),
//
//                     // Title
//                     const Text(
//                       "Unlock Your Complete Bible Experience",
//                       textAlign: TextAlign.left,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//
//                     const SizedBox(height: 12),
//
//                     // Features list
//                     // Features list
//                     _buildFeatureItem(
//                         "assets/offer/fe1.png", "Read without distractions"),
//                     _buildFeatureItem("assets/offer/fe2.png",
//                         "Daily Verses & Inspirations"),
//                     _buildFeatureItem(
//                         "assets/offer/fe3.png", "Access all available themes"),
//                     _buildFeatureItem(
//                         "assets/offer/fe4.png", "Backup & Sync across all devices"),
//                     _buildFeatureItem(
//                         "assets/guidance.png", "Biblical guidance when you need clarity"),
//                     _buildFeatureItem(
//                         "assets/coins.png", "Enjoy 5,000 bonus credits with this plan"),
//
//                     const SizedBox(height: 17),
//
//                     // Choose plan text
//                     const Text(
//                       "CHOOSE ANY PREMIUM PLAN",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold, letterSpacing: 1.2),
//                     ),
//                     const SizedBox(height: 5),
//
//                     const SizedBox(height: 6),
//
//                     // Six months plan
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 200),
//                       child: isPurchaseLoading
//                           ? Padding(
//                               padding: const EdgeInsets.only(top: 12),
//                               child: SizedBox(
//                                   height: 100,
//                                   width: 200,
//                                   child: Center(
//                                       child: Column(
//                                     children: [
//                                       const CircularProgressIndicator
//                                           .adaptive(),
//                                       Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Text('Please wait...',
//                                             style:
//                                                 CommanStyle.appBarStyle(context)
//                                                     .copyWith(fontSize: 12)),
//                                       )
//                                     ],
//                                   ))),
//                             )
//                           : _products.isEmpty
//                               ? Center(
//                                   child: Text(
//                                     "We're unable to load subscription options right now.\n Please try again later",
//                                     style: CommanStyle.appBarStyle(context)
//                                         .copyWith(fontSize: 12),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                 )
//                               : MediaQuery.removePadding(
//                                   context: context,
//                                   removeTop: true,
//                                   child: ListView.builder(
//                                     shrinkWrap: true,
//                                     padding: EdgeInsets.zero,
//                                     physics:
//                                         const NeverScrollableScrollPhysics(),
//                                     itemCount: _products.length,
//                                     itemBuilder: (context, index) {
//                                       // Move these helper functions outside the builder
//
//                                       return InkWell(
//                                         onTap: () async {
//                                           await SharPreferences.setString(
//                                               'OpenAd', '1');
//                                           setState(() {
//                                             selectedindex = index;
//                                           });
//
//                                           // _buyProduct(_products[index]);
//                                         },
//                                         child: Stack(
//                                           alignment: Alignment.topRight,
//                                           children: [
//                                             Container(
//                                               margin:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 16,
//                                                       vertical: 8),
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 16,
//                                                       vertical: 12),
//                                               decoration: BoxDecoration(
//                                                 color: selectedindex == index
//                                                     ? Provider.of<ThemeProvider>(
//                                                                     context)
//                                                                 .themeMode ==
//                                                             ThemeMode.dark
//                                                         ? const Color.fromARGB(
//                                                             255, 41, 1, 1)
//                                                         : Colors.brown
//                                                     : const Color.fromARGB(
//                                                         156, 158, 158, 158),
//                                                 border: Border.all(
//                                                     color: selectedindex ==
//                                                             index
//                                                         ? Colors.brown
//                                                         : const Color.fromARGB(
//                                                             156, 158, 158, 158),
//                                                     width: 2),
//                                                 borderRadius:
//                                                     BorderRadiusDirectional
//                                                         .circular(10),
//                                               ),
//                                               child: Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.start,
//                                                 children: [
//                                                   Expanded(
//                                                     child: Column(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .stretch,
//                                                       children: [
//                                                         Text(
//                                                             _products[index]
//                                                                 .description,
//                                                             style: CommanStyle
//                                                                     .bw14500(
//                                                                         context)
//                                                                 .copyWith(
//                                                               color: selectedindex ==
//                                                                       index
//                                                                   ? CommanColor
//                                                                       .white
//                                                                   : CommanColor
//                                                                       .black,
//                                                             )),
//                                                         Visibility(
//                                                           visible:
//                                                               getDiscountedPrice(
//                                                                       _products[
//                                                                           index])
//                                                                   .isNotEmpty,
//                                                           child: Text(
//                                                             getDiscountedPrice(
//                                                                 _products[
//                                                                     index]),
//                                                             style: CommanStyle
//                                                                     .bw14400(
//                                                                         context)
//                                                                 .copyWith(
//                                                                     color: selectedindex ==
//                                                                             index
//                                                                         ? CommanColor
//                                                                             .white
//                                                                         : CommanColor
//                                                                             .black,
//                                                                     decoration:
//                                                                         TextDecoration
//                                                                             .lineThrough),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                       '${_products[index].price}  ',
//                                                       style:
//                                                           CommanStyle.bw17500(
//                                                                   context)
//                                                               .copyWith(
//                                                         color: selectedindex ==
//                                                                 index
//                                                             ? CommanColor.white
//                                                             : CommanColor.black,
//                                                       )),
//                                                   const SizedBox(width: 24),
//                                                 ],
//                                               ),
//                                             ),
//                                             Positioned(
//                                               right: 8,
//                                               top: -2,
//                                               child: Visibility(
//                                                 visible: fakeOffer(
//                                                         _products[index]) !=
//                                                     null,
//                                                 child: Image.asset(
//                                                   'assets/offer.png',
//                                                   height: 70,
//                                                 ),
//                                               ),
//                                             ),
//                                             Positioned(
//                                               right: 13,
//                                               top: 14,
//                                               child: Visibility(
//                                                 visible: fakeOffer(
//                                                         _products[index]) !=
//                                                     null,
//                                                 child: RotationTransition(
//                                                   turns:
//                                                       const AlwaysStoppedAnimation(
//                                                           45 / 360),
//                                                   child: Text(
//                                                     '${fakeOffer(_products[index])?.toStringAsFixed(0)}% off',
//                                                     style: const TextStyle(
//                                                       letterSpacing: BibleInfo
//                                                           .letterSpacing,
//                                                       fontSize: BibleInfo
//                                                               .fontSizeScale *
//                                                           10,
//                                                       fontWeight:
//                                                           FontWeight.w500,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             )
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                     ),
//
//                     // const SizedBox(height: 6),
//
//                     // // One Year plan
//
//                     // const Text(
//                     //   "Auto renewal, cancel anytime",
//                     //   style: TextStyle(
//                     //     fontSize: 12,
//                     //     // color: Colors.black54,
//                     //   ),
//                     // ),
//                     const SizedBox(height: 12),
//
//                     // Free trial button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               Provider.of<ThemeProvider>(context).themeMode ==
//                                       ThemeMode.dark
//                                   ? Colors.black
//                                   : const Color(0xFF7B5C3D),
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () async {
//                           await SharPreferences.setString('OpenAd', '1');
//                           await SharPreferences.setBoolean(
//                               'startpurches', true);
//                           // await controller.disableAd(const Duration(days: 3));
//                           // return Get.back();
//                           await _buyProduct(_products[selectedindex]);
//                         },
//                         child: Text(
//                           // "Start My Free Trial",
//                           'Get Full Access',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color:
//                                 Provider.of<ThemeProvider>(context).themeMode ==
//                                         ThemeMode.dark
//                                     ? Colors.white
//                                     : Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     TextButton(
//                       onPressed: () async {
//                         if (_myProvider != null) {
//                           _myProvider?.enableAd();
//                         }
//                         Get.back();
//                         await SharPreferences.setBoolean('closead', true);
//                         widget.onclick!();
//                         // Check for exit offer before navigating away
//                         // await _checkAndShowExitOfferBeforeClose(controller);
//                       },
//                       child: const Text(
//                         "Continue Free Version",
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//
//                     // Footer links
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         GestureDetector(
//                           onTap: () async {
//                             launchUrlString(
//                                 'https://bibleoffice.com/terms_conditions.html');
//                           },
//                           child: Text(
//                             "Terms of Use",
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 decoration: TextDecoration.underline),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () async {
//                             await SharPreferences.setBoolean('restorepurches', true);
//                             await _restorePurchases(controller);
//                           },
//                           child: const Text(
//                             "Restore",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () async {
//                             launchUrlString(
//                                 'https://bibleoffice.com/privacy_policy.html');
//                           },
//                           child: Text(
//                             "Privacy Policy",
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 decoration: TextDecoration.underline),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 9),
//                     // Expanded(
//                     //   child: ListView(
//                     //     padding: const EdgeInsets.only(bottom: 30, top: 30),
//                     //     children: [
//                     //       CarouselSlider.builder(
//                     //         itemCount: controller.caroausalList.length,
//                     //         itemBuilder: (context, index, realIndex) {
//                     //           var data = controller.caroausalList[index];
//                     //           var card = controller.card[index];
//                     //           var cardtext = controller.cardText[index];
//                     //           return Container(
//                     //             height:
//                     //                 MediaQuery.of(context).size.height * 0.25,
//                     //             width: MediaQuery.of(context).size.width * 0.9,
//                     //             decoration: BoxDecoration(
//                     //                 color: controller.colors.value[index],
//                     //                 border: Border.all(
//                     //                     width: 2,
//                     //                     color: controller.colors.value[index]),
//                     //                 // image: DecorationImage(
//                     //                 //     image: AssetImage(data),
//                     //                 //     fit: BoxFit.fill),
//                     //                 borderRadius: BorderRadius.circular(12)),
//                     //             child: Row(
//                     //               children: [
//                     //                 Padding(
//                     //                   padding: const EdgeInsets.all(8.0),
//                     //                   child: Image.asset(card),
//                     //                 ),
//                     //                 Expanded(
//                     //                   // Use Expanded widget to allow the Text widget to take available space
//                     //                   child: Column(
//                     //                     mainAxisAlignment:
//                     //                         MainAxisAlignment.center,
//                     //                     children: [
//                     //                       Padding(
//                     //                         padding: EdgeInsets.symmetric(
//                     //                             horizontal: 27),
//                     //                         child: Text(
//                     //                           cardtext,
//                     //                           textAlign: TextAlign.center,
//                     //                           style: TextStyle(
//                     //                             letterSpacing:
//                     //                                 BibleInfo.letterSpacing,
//                     //                             fontSize:
//                     //                                 BibleInfo.fontSizeScale *
//                     //                                     17,
//                     //                           ),
//                     //                         ),
//                     //                       ),
//                     //                     ],
//                     //                   ),
//                     //                 )
//                     //               ],
//                     //             ),
//                     //           );
//                     //         },
//                     //         options: CarouselOptions(
//                     //             autoPlay: true,
//                     //             height:
//                     //                 MediaQuery.of(context).size.height * 0.10,
//                     //             enlargeCenterPage: true,
//                     //             animateToClosest: false,
//                     //             viewportFraction: 1,
//                     //             aspectRatio: 2.0,
//                     //             initialPage: controller.caroausalList.length,
//                     //             // scrollDirection: Axis.horizontal,
//                     //             onPageChanged: (index, reason) {
//                     //               controller.currentCarosal.value = index;
//                     //             }),
//                     //       ),
//                     //       ////
//                     //       ///Slider Indicator
//                     //       ///
//                     //       Center(
//                     //         child: Padding(
//                     //           padding: const EdgeInsets.only(top: 12),
//                     //           child: DotsIndicator(
//                     //               dotsCount: controller.caroausalList.length,
//                     //               position: controller.currentCarosal.value
//                     //                   .toDouble(),
//                     //               axis: Axis.horizontal,
//                     //               reversed: false,
//                     //               mainAxisAlignment: MainAxisAlignment.center,
//                     //               decorator: DotsDecorator(
//                     //                 activeColor:
//                     //                     CommanColor.whiteLightModePrimary(
//                     //                         context),
//                     //                 color: CommanColor.lightDarkPrimary200(
//                     //                     context),
//                     //                 size: const Size(10, 10),
//                     //                 activeSize: const Size(10, 10),
//                     //               )),
//                     //         ),
//                     //       ),
//                     //       const SizedBox(
//                     //         height: 15,
//                     //       ),
//                     //       _products.isEmpty
//                     //           ? Center(
//                     //               child: Text('',
//                     //                   style: CommanStyle.appBarStyle(context)))
//                     //           : Center(
//                     //               child: Text('Get Premium',
//                     //                   style: CommanStyle.appBarStyle(context))),
//                     //       const SizedBox(
//                     //         height: 10,
//                     //       ),
//                     //       _products.isEmpty
//                     //           ? Center(
//                     //               child: Text('',
//                     //                   style: CommanStyle.appBarStyle(context)))
//                     //           : const Padding(
//                     //               padding: EdgeInsets.symmetric(horizontal: 25),
//                     //               child: Text(
//                     //                 'Get this Ad free Bible to Enjoy the Unlimited Features without Any interruption',
//                     //                 style: TextStyle(
//                     //                   letterSpacing: BibleInfo.letterSpacing,
//                     //                   fontSize: BibleInfo.fontSizeScale * 15.0,
//                     //                   height:
//                     //                       2, //You can set your custom height here
//                     //                 ),
//                     //                 textAlign: TextAlign.center,
//                     //               )),
//                     //       AnimatedSwitcher(
//                     //         duration: const Duration(milliseconds: 200),
//                     //         child: isPurchaseLoading
//                     //             ? SizedBox(
//                     //                 height: 100,
//                     //                 width: 200,
//                     //                 child: Center(
//                     //                     child: Column(
//                     //                   children: [
//                     //                     const CircularProgressIndicator
//                     //                         .adaptive(),
//                     //                     Padding(
//                     //                       padding: const EdgeInsets.all(8.0),
//                     //                       child: Text('Please wait...',
//                     //                           style: CommanStyle.appBarStyle(
//                     //                                   context)
//                     //                               .copyWith(fontSize: 12)),
//                     //                     )
//                     //                   ],
//                     //                 )))
//                     //             : _products.isEmpty
//                     //                 ? Center(
//                     //                     child: Text(
//                     //                       "We're unable to load subscription options right now.\n Please try again later",
//                     //                       style:
//                     //                           CommanStyle.appBarStyle(context)
//                     //                               .copyWith(fontSize: 12),
//                     //                       textAlign: TextAlign.center,
//                     //                     ),
//                     //                   )
//                     //                 : MediaQuery.removePadding(
//                     //                     context: context,
//                     //                     removeTop: true,
//                     //                     child: ListView.builder(
//                     //                       shrinkWrap: true,
//                     //                       padding: EdgeInsets.zero,
//                     //                       physics:
//                     //                           const NeverScrollableScrollPhysics(),
//                     //                       itemCount: _products.length,
//                     //                       itemBuilder: (context, index) {
//                     //                         return InkWell(
//                     //                           onTap: () async {
//                     //                             await SharPreferences.setString(
//                     //                                 'OpenAd', '1');
//                     //                             _buyProduct(_products[index]);
//                     //                           },
//                     //                           child: Stack(
//                     //                             alignment: Alignment.topRight,
//                     //                             children: [
//                     //                               Container(
//                     //                                 margin: const EdgeInsets
//                     //                                     .symmetric(
//                     //                                     horizontal: 16,
//                     //                                     vertical: 8),
//                     //                                 padding: const EdgeInsets
//                     //                                     .symmetric(
//                     //                                     horizontal: 16,
//                     //                                     vertical: 12),
//                     //                                 decoration: BoxDecoration(
//                     //                                   border: Border.all(
//                     //                                       color: Colors.white
//                     //                                           .withOpacity(0.5),
//                     //                                       width: 2),
//                     //                                   borderRadius:
//                     //                                       BorderRadiusDirectional
//                     //                                           .circular(10),
//                     //                                 ),
//                     //                                 child: Row(
//                     //                                   mainAxisAlignment:
//                     //                                       MainAxisAlignment
//                     //                                           .start,
//                     //                                   children: [
//                     //                                     Expanded(
//                     //                                       child: Column(
//                     //                                         crossAxisAlignment:
//                     //                                             CrossAxisAlignment
//                     //                                                 .stretch,
//                     //                                         children: [
//                     //                                           Text(
//                     //                                               _products[
//                     //                                                       index]
//                     //                                                   .description,
//                     //                                               style: CommanStyle
//                     //                                                   .bw14500(
//                     //                                                       context)),
//                     //                                           Visibility(
//                     //                                             visible: getDiscountedPrice(
//                     //                                                     _products[
//                     //                                                         index])
//                     //                                                 .isNotEmpty,
//                     //                                             child: Text(
//                     //                                               getDiscountedPrice(
//                     //                                                   _products[
//                     //                                                       index]),
//                     //                                               style: CommanStyle
//                     //                                                       .bw14400(
//                     //                                                           context)
//                     //                                                   .copyWith(
//                     //                                                       decoration:
//                     //                                                           TextDecoration.lineThrough),
//                     //                                             ),
//                     //                                           ),
//                     //                                         ],
//                     //                                       ),
//                     //                                     ),
//                     //                                     Text(
//                     //                                         '${_products[index].price}  ',
//                     //                                         style: CommanStyle
//                     //                                             .bw17500(
//                     //                                                 context)),
//                     //                                     const SizedBox(
//                     //                                         width: 24),
//                     //                                   ],
//                     //                                 ),
//                     //                               ),
//                     //                               Positioned(
//                     //                                 right: 8,
//                     //                                 top: -2,
//                     //                                 child: Visibility(
//                     //                                   visible: fakeOffer(
//                     //                                           _products[
//                     //                                               index]) !=
//                     //                                       null,
//                     //                                   child: Image.asset(
//                     //                                     'assets/offer.png',
//                     //                                     height: 70,
//                     //                                   ),
//                     //                                 ),
//                     //                               ),
//                     //                               Positioned(
//                     //                                 right: 13,
//                     //                                 top: 14,
//                     //                                 child: Visibility(
//                     //                                   visible: fakeOffer(
//                     //                                           _products[
//                     //                                               index]) !=
//                     //                                       null,
//                     //                                   child: RotationTransition(
//                     //                                     turns:
//                     //                                         const AlwaysStoppedAnimation(
//                     //                                             45 / 360),
//                     //                                     child: Text(
//                     //                                       '${fakeOffer(_products[index])?.toStringAsFixed(0)}% off',
//                     //                                       style:
//                     //                                           const TextStyle(
//                     //                                         letterSpacing:
//                     //                                             BibleInfo
//                     //                                                 .letterSpacing,
//                     //                                         fontSize: BibleInfo
//                     //                                                 .fontSizeScale *
//                     //                                             10,
//                     //                                         fontWeight:
//                     //                                             FontWeight.w500,
//                     //                                         color: Colors.white,
//                     //                                       ),
//                     //                                     ),
//                     //                                   ),
//                     //                                 ),
//                     //                               )
//                     //                             ],
//                     //                           ),
//                     //                         );
//                     //                       },
//                     //                     ),
//                     //                   ),
//                     //       ),
//
//                     //       const SizedBox(
//                     //         height: 5,
//                     //       ),
//                     //       _isAdLoaded == false
//                     //           ? SizedBox()
//                     //           : Center(
//                     //               child: Text(
//                     //                 "or",
//                     //                 style: CommanStyle.bw14500(context),
//                     //               ),
//                     //             ),
//                     //       const SizedBox(
//                     //         height: 15,
//                     //       ),
//                     //       _isAdLoaded == false
//                     //           ? SizedBox()
//                     //           : const Padding(
//                     //               padding: EdgeInsets.symmetric(horizontal: 35),
//                     //               child: Text(
//                     //                 'You can watch a short rewarded video to remove all Ads for 3 days',
//                     //                 textAlign: TextAlign.center,
//                     //                 style: TextStyle(
//                     //                     letterSpacing: BibleInfo.letterSpacing,
//                     //                     fontSize: BibleInfo.fontSizeScale * 14,
//                     //                     height: 2),
//                     //               ),
//                     //             ),
//                     //       _isAdLoaded == false
//                     //           ? SizedBox()
//                     //           : const SizedBox(
//                     //               height: 15,
//                     //             ),
//                     //       _isAdLoaded == false
//                     //           ? SizedBox()
//                     //           : Row(
//                     //               mainAxisAlignment: MainAxisAlignment.center,
//                     //               children: [
//                     //                 InkWell(
//                     //                   onTap: () async {
//                     //                     // debugPrint(
//                     //                     //     "isAppInForeground  _rewardedAd - $_rewardedAd _isAdShowing - ${!_isAdShowing}   _isAdLoaded - $_isAdLoaded");
//                     //                     debugPrint(" RewardedAdService 1");
//                     //                     if (_isAdLoaded) {
//                     //                       RewardedAdService.showAd(
//                     //                           onRewardEarned: () async {
//                     //                             // debugPrint(
//                     //                             //     "User earned reward: ${reward.amount} ${reward.type}");
//                     //                           },
//                     //                           onAdDismissed: () async {
//                     //                             debugPrint(
//                     //                                 " RewardedAdService is done ");
//                     //                             await controller.disableAd(
//                     //                                 const Duration(days: 3));
//                     //                             Get.back();
//                     //                             // Get.replace(() => HomeScreen(
//                     //                             //     From: "splash",
//                     //                             //     selectedVerseNumForRead: "",
//                     //                             //     selectedBookForRead: "",
//                     //                             //     selectedChapterForRead: "",
//                     //                             //     selectedBookNameForRead: "",
//                     //                             //     selectedVerseForRead: ""));
//                     //                           },
//                     //                           data: "iap");
//                     //                     } else {
//                     //                       debugPrint(
//                     //                           "App not in foreground or ad not ready");
//                     //                     }
//                     //                   },
//                     //                   child: Container(
//                     //                     height:
//                     //                         MediaQuery.of(context).size.height *
//                     //                             0.07,
//                     //                     width:
//                     //                         MediaQuery.of(context).size.width *
//                     //                             0.9,
//                     //                     padding: const EdgeInsets.symmetric(
//                     //                         horizontal: 20, vertical: 12),
//                     //                     decoration: BoxDecoration(
//                     //                       color: const Color(0XFF1C46B2),
//                     //                       borderRadius:
//                     //                           BorderRadius.circular(5),
//                     //                     ),
//                     //                     child: const Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.center,
//                     //                       children: [
//                     //                         Icon(
//                     //                           Icons.video_call_outlined,
//                     //                           size: 20,
//                     //                           color: Colors.white,
//                     //                         ),
//                     //                         SizedBox(
//                     //                           width: 10,
//                     //                         ),
//                     //                         Text(
//                     //                           "Watch Video Ad",
//                     //                           style: TextStyle(
//                     //                               color: Colors.white),
//                     //                         )
//                     //                       ],
//                     //                     ),
//                     //                   ),
//                     //                 )
//                     //               ],
//                     //             ),
//                     //       const SizedBox(
//                     //         height: 15,
//                     //       ),
//                     //       isRestoreLoading
//                     //           ? const Row(
//                     //               mainAxisAlignment: MainAxisAlignment.center,
//                     //               children: [
//                     //                 CircularProgressIndicator.adaptive(),
//                     //               ],
//                     //             )
//                     //           : GestureDetector(
//                     //               onTap: () async {
//                     //                 await _inAppPurchase.restorePurchases();
//                     //                 setState(() {
//                     //                   isRestoreLoading = true;
//                     //                 });
//                     //                 await Future.delayed(Duration(seconds: 7));
//                     //                 try {
//                     //                   final res = await restorePurchase();
//                     //                   if (res['status'] == 'success') {
//                     //                     final rawData = res['data']
//                     //                         .toString()
//                     //                         .split('-productId:');
//                     //                     if (rawData.length == 2) {
//                     //                       final data =
//                     //                           rawData[1].split('-date:');
//                     //                       final productId = data[0].toString();
//                     //                       final date = data[1].toString();
//                     //                       await restorePurchaseHandle(
//                     //                           productId, date, controller);
//                     //                       Constants.showToast(
//                     //                           'Restore Successful');
//                     //                     }
//                     //                   } else {
//                     //                     Constants.showToast(
//                     //                         'No active subscription available');
//                     //                   }
//                     //                 } catch (e) {
//                     //                   Constants.showToast(
//                     //                       ' error No active subscription available');
//
//                     //                   DebugConsole.log(
//                     //                       "restore No active subscription available error - $e");
//                     //                 }
//                     //                 setState(() {
//                     //                   isRestoreLoading = false;
//                     //                 });
//                     //               },
//                     //               child: Text(
//                     //                 'Restore Purchases',
//                     //                 textAlign: TextAlign.center,
//                     //                 style: CommanStyle.bw15500(context),
//                     //               ),
//                     //             ),
//                     //       const SizedBox(
//                     //         height: 15,
//                     //       ),
//                     //       const Padding(
//                     //         padding: EdgeInsets.symmetric(horizontal: 40),
//                     //         child: Text(
//                     //           '''If you have reinstalled the application on your device or restored a backup onto a new device you can recover ads free version you have already purchased.''',
//                     //           textAlign: TextAlign.center,
//                     //           style: TextStyle(
//                     //               letterSpacing: BibleInfo.letterSpacing,
//                     //               fontSize: BibleInfo.fontSizeScale * 12,
//                     //               height: 2),
//                     //         ),
//                     //       ),
//                     //       const SizedBox(
//                     //         height: 15,
//                     //       ),
//                     //       Padding(
//                     //         padding: const EdgeInsets.symmetric(horizontal: 15),
//                     //         child: Row(
//                     //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     //           children: [
//                     //             GestureDetector(
//                     //               onTap: () async {
//                     //                 launchUrlString(
//                     //                     'https://bibleoffice.com/privacy_policy.html');
//                     //               },
//                     //               child: const Text("Privacy Policy",
//                     //                   style: TextStyle(
//                     //                       letterSpacing:
//                     //                           BibleInfo.letterSpacing,
//                     //                       fontSize:
//                     //                           BibleInfo.fontSizeScale * 12,
//                     //                       decoration:
//                     //                           TextDecoration.underline)),
//                     //             ),
//                     //             GestureDetector(
//                     //               onTap: () async {
//                     //                 launchUrlString(
//                     //                     'https://bibleoffice.com/terms_conditions.html');
//                     //               },
//                     //               child: const Text("Terms and Conditions",
//                     //                   style: TextStyle(
//                     //                       letterSpacing:
//                     //                           BibleInfo.letterSpacing,
//                     //                       fontSize:
//                     //                           BibleInfo.fontSizeScale * 12,
//                     //                       decoration:
//                     //                           TextDecoration.underline)),
//                     //             )
//                     //           ],
//                     //         ),
//                     //       ),
//                     //       // _buildProductList(),
//                     //     ],
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//     // });
//   }
//
//   double? fakeOffer(ProductDetails product) {
//     if (product.id == widget.sixMonthPlan) {
//       return double.tryParse(controller.sixMonthPlanValue ?? '');
//     }
//     if (product.id == widget.oneYearPlan) {
//       return double.tryParse(controller.oneYearPlanValue ?? '');
//     }
//     if (product.id == widget.lifeTimePlan) {
//       return double.tryParse(controller.lifeTimePlanValue ?? '');
//     }
//     // final sixMonthPlanValue =
//     //     SharPreferences.getString('sixMonthPlanvalue') ?? "";
//     // final oneYearPlanValue =
//     //     SharPreferences.getString('oneYearPlanvalue') ?? "";
//     // final lifeTimePlanValue =
//     //     SharPreferences.getString('lifeTimePlanvalue') ?? "";
//
//     // if (product.id == widget.sixMonthPlan) {
//     //   return double.tryParse(sixMonthPlanValue.toString());
//     //   //  return double.tryParse(controller.sixMonthPlanValue ?? '');
//     // }
//     // if (product.id == widget.oneYearPlan) {
//     //   return double.tryParse(oneYearPlanValue.toString());
//     //   //  return double.tryParse(controller.oneYearPlanValue ?? '');
//     // }
//     // if (product.id == widget.lifeTimePlan) {
//     //   return double.tryParse(lifeTimePlanValue.toString());
//     //   //  return double.tryParse(controller.lifeTimePlanValue ?? '');
//     // }
//     return null;
//   }
//
//   String getDiscountedPrice(ProductDetails product) {
//     final fakeOfferPercentage = fakeOffer(product);
//     if (fakeOfferPercentage != null) {
//       final fakePrice =
//           calculateOriginalPrice(fakeOfferPercentage, product.rawPrice);
//       return '${product.currencySymbol}${fakePrice.toStringAsFixed(2)}';
//     }
//     return '';
//   }
//
//   Widget _buildFeatureItem(String image, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
//       child: Row(
//         children: [
//           Image.asset(image, width: 28, height: 28), // ✅ use image, not Icon
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// Example implementation of the
// /// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
// ///
// /// The payment queue delegate can be implementated to provide information
// /// needed to complete transactions.
// class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
//   @override
//   bool shouldContinueTransaction(
//       SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
//     return true;
//   }
//
//   @override
//   bool shouldShowPriceConsent() {
//     return false;
//   }
// }
