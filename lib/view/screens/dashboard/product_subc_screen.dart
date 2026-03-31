import 'dart:async';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  //plan
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loading = false;

  // Product IDs from SharedPreferences
  late String silverID;
  late String goldID;
  late String platinumID;

  @override
  void initState() {
    super.initState();
    _loadProductIDs();
    // Track Paywall Screen event
    AnalyticsService.trackPaywallScreen();
  }

  Future<void> _loadProductIDs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      silverID = prefs.getString('sliverID') ?? '';
      goldID = prefs.getString('goldID') ?? '';
      platinumID = prefs.getString('platinumID') ?? '';
    });

    initStoreInfo();
  }

  // @override
  // void dispose() {
  //   _subscription.cancel();
  //   super.dispose();
  // }

  Future<void> initStoreInfo() async {
    // Check if preloaded data is available first
    final preloadedAvailability = PaywallPreloadService.getPreloadedAvailability();
    final preloadedProducts = PaywallPreloadService.getPreloadedProducts();
    
    if (preloadedAvailability != null && preloadedProducts.isNotEmpty) {
      // Use preloaded data - instant display (no waiting!)
      debugPrint('ProductSubcScreen: Using preloaded paywall data');
      setState(() {
        _isAvailable = preloadedAvailability;
        _products = preloadedProducts;
        _notFoundIds = [];
      });
      return;
    }
    
    // Fallback to original logic if preload not available
    // Use the IDs from SharedPreferences
    final Set<String> kIds = {silverID, goldID, platinumID};

    debugPrint("$kIds");
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _notFoundIds = [];
      });
      return;
    }

    // // For iOS, we need to add payment queue delegate
    // if (Theme.of(context).platform == TargetPlatform.iOS) {
    //   InAppPurchaseIosPlatformAddition.enablePendingPurchases();
    // }

    // // Use the IDs from SharedPreferences
    // final Set<String> kIds = {silverID, goldID, platinumID};
    // final ProductDetailsResponse response =
    //     await _inAppPurchase.queryProductDetails(kIds);

    setState(() {
      _isAvailable = isAvailable;
      _products = response.productDetails;
      _notFoundIds = response.notFoundIDs;
    });
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    // Check connectivity FIRST before showing loader
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast("No Internet connection");
      return; // Return early - don't show loader or proceed
    }
    
    EasyLoading.show(status: "Loading...");
    setState(() {
      _loading = true;
    });

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      _subscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          EasyLoading.dismiss();
          _subscription.cancel();
        },
        onError: (error) {
          EasyLoading.dismiss();
          setState(() {
            _loading = false;
          });
          // Handle error
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      setState(() {
        _loading = false;
      });
      // Handle error
    }
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // final SharedPreferences prefs = await SharedPreferences.getInstance();
        EasyLoading.dismiss();
        // Store the actual product IDs
        if (purchaseDetails.productID == silverID) {
          // await prefs.setString('silverID', purchaseDetails.productID);
          await Provider.of<DownloadProvider>(context, listen: false)
              .setSubscriptionPlan('silver');
        } else if (purchaseDetails.productID == goldID) {
          // await prefs.setString('goldID', purchaseDetails.productID);
          await Provider.of<DownloadProvider>(context, listen: false)
              .setSubscriptionPlan('gold');
        } else if (purchaseDetails.productID == platinumID) {
          // await prefs.setString('platinumID', purchaseDetails.productID);
          await Provider.of<DownloadProvider>(context, listen: false)
              .setSubscriptionPlan('platinum');
        }

        // Important: Always complete the purchase
        await _inAppPurchase.completePurchase(purchaseDetails);

        setState(() {
          _loading = false;
        });

        Get.back();
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        setState(() {
          _loading = false;
        });
        EasyLoading.dismiss();
        // Handle error
      }
    }
  }

  checknetwork() async {
    final bool isConnected = await InternetConnection().hasInternetAccess;

    debugPrint("connectivityResult -$isConnected");

    if (!isConnected) {
      Constants.showToast("Check your Internet connection");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF2E2C4), // Light parchment background
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.fill))
            : null,
        child: SingleChildScrollView(
          // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
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
                        "Subscription Plan",
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
                SizedBox(height: screenWidth < 380 ? 12 : 25),
                Text(
                  'Unlock Bible Treasures!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Provider.of<ThemeProvider>(context).themeMode ==
                            ThemeMode.dark
                        ? CommanColor.white
                        : Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Grow deeper in faith with exclusive\nDigital Bible Products',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),

                // Features grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    // spacing: 30,
                    // runSpacing: 10,
                    // alignment: WrapAlignment.start,

                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FeatureItem(label: 'Reading Tracker'),
                          SizedBox(height: 12),
                          FeatureItem(label: 'Who said it?'),
                          SizedBox(height: 12),
                          FeatureItem(label: 'Bible Challenges'),
                        ],
                      ),
                      Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FeatureItem(label: 'Bible Riddles'),
                          SizedBox(height: 12),
                          FeatureItem(label: 'Prayer Wheel'),
                          SizedBox(height: 12),
                          FeatureItem(label: 'Stickers kit'),
                        ],
                      ),
                      Spacer(),
                    ],
                  ),
                ),

                SizedBox(height: screenWidth < 380 ? 17 : 25),

                // Plan Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SubscriptionCard(
                      title: 'Silver Plan',
                      price: '\$4',
                      description: 'Get 4 Premium\ne-Products',
                      note: 'Instant Access After       \nPurchase',
                      backgroundImage: 'assets/p1.png',
                      starImage: 'assets/sp1.png',
                      buttonColor: Color.fromARGB(255, 152, 147, 147),
                      onPressed: () async {
                        // await Provider.of<DownloadProvider>(context,
                        //         listen: false)
                        //     .setSubscriptionPlan('silver');
                        // Get.back();
                        await checknetwork();
                        final silverProduct = _products.where(
                          (product) => product.id == silverID,
                          // orElse: () => null,
                        );
                        if (silverProduct.isNotEmpty) {
                          await _buyProduct(silverProduct.first);
                        }
                      },
                    ),
                    SubscriptionCard(
                      title: 'Gold Plan',
                      price: '\$10',
                      description: 'Enjoy 12 Premium\ne-Products',
                      note: 'More Value for Your Study\n',
                      backgroundImage: 'assets/p2.png',
                      starImage: 'assets/sp2.png',
                      buttonColor: Color.fromARGB(255, 163, 123, 1),
                      onPressed: () async {
                        // await Provider.of<DownloadProvider>(context,
                        //         listen: false)
                        //     .setSubscriptionPlan('gold');
                        // Get.back();
                        await checknetwork();
                        final goldProduct = _products.where(
                          (product) => product.id == goldID,
                          // orElse: () => null,
                        );
                        if (goldProduct.isNotEmpty) {
                          await _buyProduct(goldProduct.first);
                        }
                      },
                    ),
                    SubscriptionCard(
                      title: 'Platinum Plan',
                      price: '\$20',
                      description: 'Unlimited Access to\nALL e-Products',
                      note: 'Best for Daily Bible    \nExplorers!',
                      backgroundImage: 'assets/p3.png',
                      starImage: 'assets/sp3.png',
                      buttonColor: Color.fromARGB(255, 146, 146, 146),
                      onPressed: () async {
                        // await Provider.of<DownloadProvider>(context,
                        //         listen: false)
                        //     .setSubscriptionPlan('platinum');
                        // Get.back();
                        await checknetwork();
                        final platinumProduct = _products.where(
                          (product) => product.id == platinumID,
                          // orElse: () => null,
                        );
                        if (platinumProduct.isNotEmpty) {
                          await _buyProduct(platinumProduct.first);
                        }
                      },
                    ),
                  ],
                ),

                SizedBox(height: screenWidth < 380 ? 17 : 27),

                // Footer Note
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Note:\n',
                        style: TextStyle(
                          fontSize: screenWidth > 450 ? 19 : null,
                          fontWeight: FontWeight.w300,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.white
                                  : Colors.brown,
                        ),
                      ),
                      TextSpan(
                        text: 'This is not a subscription.\n',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: screenWidth > 450 ? 15 : 11.9),
                      ),
                      TextSpan(
                        text:
                            'This is a one-time purchase to access digital Bible Product.\n(To ',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: screenWidth > 450 ? 15 : 11.9),
                      ),
                      TextSpan(
                        text: 'Remove Ads',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: screenWidth > 450 ? 15 : 11.9),
                      ),
                      TextSpan(
                        text: ', please go to our Subscription section.)',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: screenWidth > 450 ? 15 : 11.9),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String label;
  const FeatureItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          "assets/book3.png",
          width: screenWidth > 450 ? 35 : 20,
          height: screenWidth > 450 ? 35 : 20,
          color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
              ? CommanColor.white
              : null,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: screenWidth > 450 ? 20 : null,
                color: Provider.of<ThemeProvider>(context).themeMode ==
                        ThemeMode.dark
                    ? CommanColor.white
                    : Colors.brown)),
      ],
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String note;
  final String backgroundImage;
  final String starImage; // PNG or SVG path
  final Color buttonColor;
  final VoidCallback onPressed;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.note,
    required this.backgroundImage,
    required this.starImage,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 35),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30), // space for the star
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth > 450 ? 19 : 12,
                      color: CommanColor.black),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                      fontSize: screenWidth > 450 ? 25 : 22,
                      fontWeight: FontWeight.w700,
                      color: CommanColor.black),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: screenWidth > 450 ? 12 : 9,
                      color: CommanColor.black),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Buy',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth > 450 ? 17 : null),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: screenWidth > 450 ? 9 : 7,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Star Image
          Positioned(
            top: 0,
            child: Image.asset(
              starImage,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
