import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/Model/product_details_model.dart' as m;
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../Model/get_audio_model.dart';
import '../../core/notifiers/download.notifier.dart';

// final List<PurchaseDetails> _purchases = [];

class SubscriptionScreen extends StatefulWidget {
  final String sixMonthPlan;
  final String oneYearPlan;
  final String lifeTimePlan;
  final String checkad;

  const SubscriptionScreen({
    super.key,
    required this.sixMonthPlan,
    required this.oneYearPlan,
    required this.lifeTimePlan,
    required this.checkad,
  });

  /// Public entry point to show the exit offer from Home.
  /// Forwards to the state helper while keeping existing logic intact.
  static Future<void> showExitOfferFromHomeScreen(
      BuildContext context, DashBoardController controller) {
    return _SubscriptionScreenState.showExitOfferFromHomeScreen(
        context, controller);
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isPurchaseLoading = false;
//  bool isRestoreLoading = false;
  bool userTap = false;
  int selectedindex = 0;
  List<ProductDetails> _products = [];
  ProductDetails? _exitOfferProduct; // Store exit offer product for purchase
  bool _isExitOfferShowing =
      false; // Track if exit offer is currently being shown

  void _sortProducts() {
    _products.sort((a, b) {
      // Define order: 6 months (0), 1 year (1), lifetime (2)
      int getOrder(String id) {
        if (id == widget.sixMonthPlan) return 0;
        if (id == widget.oneYearPlan) return 1;
        if (id == widget.lifeTimePlan) return 2;
        return 3;
      }

      return getOrder(a.id).compareTo(getOrder(b.id));
    });
  }

  DownloadProvider? _myProvider;
//// In App Purchase
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
// subscription that listens to a stream of updates to purchase details
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  late Stream<List<PurchaseDetails>> _purchaseUpdatedStream;

  bool _isAvailable = false;

  // checks if a user has purchased a certain product
  PurchaseDetails? _hasUserPurchased(String productID) {
    return null;
  }

  /// Add six months to a given date (or current date if not provided)
  /// Handles month overflow and day adjustments for months with fewer days
  DateTime addSixMonths({DateTime? customDate}) {
    final date = customDate ?? DateTime.now();
    int year = date.year;
    int month = date.month + 6;

    if (month > 12) {
      year += 1;
      month -= 12;
    }

    int day = date.day;

    // Adjust the day if it exceeds the number of days in the target month
    int daysInNewMonth = DateTime(year, month + 1, 0).day;
    if (day > daysInNewMonth) {
      day = daysInNewMonth;
    }

    return DateTime(year, month, day);
  }

  Future<void> _buyProduct(ProductDetails prod) async {
    // Check connectivity FIRST before showing loader
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast("No Internet connection");
      return; // Return early - don't show loader or proceed
    }

    if (!userTap) {
      debugPrint("Buy Product");
      try {
        if (mounted) {
        setState(() {
          userTap = true;
        });
        }
        EasyLoading.show();
        await SharPreferences.setString('OpenAd', '1');

        final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
        _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        // setState(() {
        //   userTap = false;
        // });
      } catch (e) {
        debugPrint('Error: $e');
      } finally {
        if (mounted) {
        setState(() {
          userTap = false;
        });
        }
      }
    }
  }

  /// Mark that paywall has been shown (for first time tracking)
  Future<void> _markPaywallShown() async {
    final hasShownPaywall =
        await SharPreferences.getBoolean('has_shown_paywall_first_time') ??
            false;
    if (!hasShownPaywall) {
      await SharPreferences.setBoolean('has_shown_paywall_first_time', true);
      await SharPreferences.setBoolean('is_first_time_paywall_cancel', true);
    }
  }

  /// Check if exit offer should be shown and display it (for purchase cancellation)
  Future<void> _checkAndShowExitOffer(DashBoardController controller) async {
    try {
      final isFirstTimeCancel =
          await SharPreferences.getBoolean('is_first_time_paywall_cancel') ??
              false;

      if (!isFirstTimeCancel) {
        // Not the first time, don't show exit offer
        return;
      }

      // Check if exit offer already shown and if 10 minutes have passed
      final hasShownExitOffer =
          await SharPreferences.getBoolean('has_shown_exit_offer') ?? false;
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');

      if (hasShownExitOffer && exitOfferFirstShownTime != null) {
        // Check if 10 minutes have passed
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final now = DateTime.now();
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            return;
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
        }
      }

      // Check API response for exit offer
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null) {
        // Mark that exit offer has been shown and save timestamp
        if (!hasShownExitOffer) {
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', DateTime.now().toIso8601String());
        }
        await SharPreferences.setBoolean('is_first_time_paywall_cancel', false);

        // Show exit offer bottom sheet
        if (mounted) {
          _showExitOfferBottomSheet(exitOffer);
        }
      } else {
        debugPrint('Exit offer not found in API response');
      }
    } catch (e) {
      debugPrint('Error checking exit offer: $e');
    }
  }

  /// Show exit offer from home screen (checking 10 minute limit)
  static Future<void> showExitOfferFromHomeScreen(
      BuildContext context, DashBoardController controller) async {
    try {
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');
      final now = DateTime.now();

      if (exitOfferFirstShownTime != null) {
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            final alreadyNotified = await SharPreferences.getBoolean(
                    'exit_offer_expired_toast_shown') ??
                false;
            if (!alreadyNotified) {
              await SharPreferences.setBoolean(
                  'exit_offer_expired_toast_shown', true);
              Constants.showToast("Limited time offer has expired");
            }
            // Proceed to paywall without exit offer
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
          final alreadyNotified = await SharPreferences.getBoolean(
                  'exit_offer_expired_toast_shown') ??
              false;
          if (!alreadyNotified) {
            await SharPreferences.setBoolean(
                'exit_offer_expired_toast_shown', true);
            Constants.showToast("Limited time offer has expired");
          }
          // Proceed to paywall without exit offer
        }
      } else {
        // First time access from home: start the 10-minute window
        await SharPreferences.setBoolean('has_shown_exit_offer', true);
        await SharPreferences.setString(
            'exit_offer_first_shown_time', now.toIso8601String());
      }
      // Ensure flag is set for subsequent checks
      await SharPreferences.setBoolean('has_shown_exit_offer', true);

      // Navigate to subscription screen which will show the exit offer
      // Use constants as fallback when SharedPreferences are empty (first time loading)
      final sixMonthPlan = await SharPreferences.getString('sixMonthPlan') ??
          BibleInfo.sixMonthPlanid;
      final oneYearPlan = await SharPreferences.getString('oneYearPlan') ??
          BibleInfo.oneYearPlanid;
      final lifeTimePlan = await SharPreferences.getString('lifeTimePlan') ??
          BibleInfo.lifeTimePlanid;

      Get.to(
        () => SubscriptionScreen(
          sixMonthPlan: sixMonthPlan,
          oneYearPlan: oneYearPlan,
          lifeTimePlan: lifeTimePlan,
          checkad: 'home',
        ),
        transition: Transition.cupertinoDialog,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('Error showing exit offer from home: $e');
      Constants.showToast("Unable to load offer");
    }
  }

  /// Check if exit offer should be shown before closing/navigating away from paywall
  Future<void> _checkAndShowExitOfferBeforeClose(
      DashBoardController controller) async {
    try {
      debugPrint('🚪 User is closing/navigating away from paywall');

      // First, check if exit offer timer has expired (10 minutes check)
      final hasShownExitOffer =
          await SharPreferences.getBoolean('has_shown_exit_offer') ?? false;
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');

      if (hasShownExitOffer && exitOfferFirstShownTime != null) {
        // Check if 10 minutes have passed
        try {
          final firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final now = DateTime.now();
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            debugPrint(
                '⏭️ Exit offer time expired (10 minutes passed), navigating away');
            _navigateAwayFromPaywall();
            return;
          } else {
            // 10 minutes haven't passed yet, show exit offer again
            debugPrint(
                '⏰ Exit offer timer still active (${10 - difference.inMinutes} minutes remaining), showing exit offer again');
          }
        } catch (e) {
          debugPrint('Error parsing exit offer timestamp: $e');
        }
      }

      // Check if this is first time (for initial setup only)
      final isFirstTimeCancel =
          await SharPreferences.getBoolean('is_first_time_paywall_cancel') ??
              false;
      debugPrint('🔑 Is first time cancel: $isFirstTimeCancel');

      // Check API response for exit offer
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null) {
        debugPrint('✅ Exit offer found! Showing bottom sheet...');
        // Mark that exit offer has been shown and save timestamp (only on first show)
        if (!hasShownExitOffer) {
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', DateTime.now().toIso8601String());
          debugPrint('📝 First time showing exit offer, timestamp saved');
        }
        // Only set first time flag to false on first show (keep existing logic)
        if (isFirstTimeCancel) {
          await SharPreferences.setBoolean(
              'is_first_time_paywall_cancel', false);
        }

        // Show exit offer bottom sheet (will show again if dismissed and clicked again within 10 minutes)
        if (mounted) {
          _showExitOfferBottomSheet(exitOffer);
        } else {
          debugPrint('⚠️ Widget not mounted, cannot show bottom sheet');
          _navigateAwayFromPaywall();
        }
      } else {
        debugPrint('❌ Exit offer not found in API response - navigating away');
        // No exit offer in API, navigate away normally
        _navigateAwayFromPaywall();
      }
    } catch (e) {
      debugPrint('❌ Error checking exit offer before close: $e');
      // On error, navigate away normally
      _navigateAwayFromPaywall();
    }
  }

  /// Navigate away from paywall screen
  void _navigateAwayFromPaywall() {
    if (_myProvider != null) {
      _myProvider?.enableAd();
    }
    SharPreferences.setBoolean('closead', true);

    // If came from Settings (theme), route back to Settings
    if (widget.checkad == 'theme') {
      Get.back();
    } else {
      // Route to Reader Screen (HomeScreen with From: "Read")
      Get.offAll(() => HomeScreen(
            From: "Read",
            selectedVerseNumForRead: "",
            selectedBookForRead: "",
            selectedChapterForRead: "",
            selectedBookNameForRead: "",
            selectedVerseForRead: "",
          ));
    }
  }

  /// Get exit offer from API response with fallback to constant data
  Future<GetAudioModelDataSubFields?> _getExitOfferFromApi(
      DashBoardController controller) async {
    try {
      debugPrint('🔍 Checking exit offer in API response...');

      // First try to get from controller's audioData
      GetAudioModel? apiData = controller.audioData.value;
      List<GetAudioModelDataSubFields?>? subFields = apiData.data?.subFields;

      // If controller data is empty, try loading from cached SharedPreferences
      if (subFields == null || subFields.isEmpty) {
        debugPrint(
            '⚠️ Controller audioData is empty, trying to load from cache...');
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedJson = prefs.getString('cached_api_response');

          if (cachedJson != null && cachedJson.isNotEmpty) {
            debugPrint('📦 Found cached API response, parsing...');
            final jsonData = jsonDecode(cachedJson);
            apiData = GetAudioModel.fromJson(jsonData);
            subFields = apiData.data?.subFields;
            debugPrint('✅ Loaded API data from cache successfully');
          } else {
            debugPrint(
                '⚠️ No cached API response found, trying to load API directly...');
            // Try to load API directly if cache doesn't exist
            try {
              final loadedData = await getMusicDetails();
              if (loadedData != null && loadedData.data != null) {
                debugPrint('✅ Successfully loaded API data directly');
                // Cache it for future use
                final jsonString = jsonEncode(loadedData.toJson());
                await prefs.setString('cached_api_response', jsonString);
                // Update controller's data
                controller.audioData.value = loadedData;
                apiData = loadedData;
                subFields = loadedData.data?.subFields;
                debugPrint('✅ API data cached and controller updated');
              } else {
                debugPrint('⚠️ API returned null data');
              }
            } catch (apiError) {
              debugPrint('❌ Error loading API directly: $apiError');
            }
          }
        } catch (cacheError) {
          debugPrint('❌ Error loading from cache: $cacheError');
        }
      }

      debugPrint('📊 SubFields count: ${subFields?.length ?? 0}');

      // Get exit offer ID from SharedPreferences (with fallback to constant)
      final exitOfferId = await SharPreferences.getString('exitOfferPlan') ??
          BibleInfo.exitOfferPlanid;

      if (subFields != null && subFields.isNotEmpty) {
        for (var field in subFields) {
          debugPrint('📋 Field identifier: ${field?.identifier}');
          if (field?.identifier == exitOfferId) {
            debugPrint('✅ Exit offer found!');
            return field;
          }
        }
        debugPrint('⚠️ Exit offer identifier not found in subFields');
      } else {
        debugPrint('⚠️ No subFields found in API response');
      }

      // Fallback to constant data if API and cache both failed
      debugPrint(
          '⚠️ Exit offer not found in API/cache, using constant data as fallback');
      try {
        // Create a fallback exit offer using constant lifetime plan ID
        final fallbackExitOffer = GetAudioModelDataSubFields(
          identifier: BibleInfo.lifeTimePlanid, // Use constant lifetime plan ID
          item_1: "Unlock every Premium Bible feature",
          item_2: "30% Off for the next 10 minutes",
          value: "30",
        );
        debugPrint('✅ Created fallback exit offer with constant data');
        return fallbackExitOffer;
      } catch (e) {
        debugPrint('❌ Error creating fallback exit offer: $e');
      }

      debugPrint('❌ Exit offer not found and fallback failed');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting exit offer from API: $e');
      // Try fallback even on error
      try {
        final fallbackExitOffer = GetAudioModelDataSubFields(
          identifier: BibleInfo.lifeTimePlanid,
          item_1: "Unlock every Premium Bible feature",
          item_2: "30% Off for the next 10 minutes",
          value: "30",
        );
        debugPrint('✅ Created fallback exit offer after error');
        return fallbackExitOffer;
      } catch (fallbackError) {
        debugPrint(
            '❌ Error creating fallback exit offer after error: $fallbackError');
        return null;
      }
    }
  }

  /// Show exit offer bottom sheet
  void _showExitOfferBottomSheet(GetAudioModelDataSubFields exitOffer) async {
    // Prevent showing exit offer multiple times
    if (_isExitOfferShowing) {
      debugPrint(
          '⚠️ Exit offer bottom sheet is already showing, skipping duplicate call');
      return;
    }

    // Mark that exit offer is showing immediately to prevent duplicate calls
    _isExitOfferShowing = true;

    final screenWidth = MediaQuery.of(context).size.width;

    // Debug log for exit offer content
    debugPrint(
        'Exit offer full data -> identifier: ${exitOffer.identifier}, item1: ${exitOffer.item_1}, item2: ${exitOffer.item_2}, value: ${exitOffer.value}');

    // Debug log for all product prices
    try {
      final productSummaries = _products
          .map((p) => '${p.id}: ${p.price.isNotEmpty ? p.price : 'n/a'}')
          .join(' | ');
      debugPrint('Available products -> $productSummaries');
    } catch (e) {
      debugPrint('Error logging products: $e');
    }

    // Calculate remaining countdown based on first shown time
    int remainingSeconds = 600; // 10 minutes default
    try {
      final stored =
          await SharPreferences.getString('exit_offer_first_shown_time');
      if (stored != null && stored.isNotEmpty) {
        final firstShown = DateTime.parse(stored);
        final diffSeconds = DateTime.now().difference(firstShown).inSeconds;
        remainingSeconds = (600 - diffSeconds).clamp(0, 600);
      }
    } catch (_) {}

    final initialMinutes = remainingSeconds ~/ 60;
    final initialSeconds = remainingSeconds % 60;

    // Fetch exit offer product from store using the identifier BEFORE showing bottom sheet
    String exitOfferPrice = "\$24.99"; // Fallback
    String originalLifetimePrice = "\$24.99"; // Fallback

    try {
      // Get the exit offer product ID from the API response
      final exitOfferProductId = exitOffer.identifier;

      if (exitOfferProductId == null || exitOfferProductId.isEmpty) {
        debugPrint(
            '⚠️ Exit offer product ID is null or empty, using lifetime product');
        // Use lifetime product as fallback
        try {
          final lifetimeProduct = _products.firstWhere(
            (product) => product.id == widget.lifeTimePlan,
            orElse: () =>
                _products.isNotEmpty ? _products.first : null as ProductDetails,
          );
          if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
            exitOfferPrice = lifetimeProduct.price;
            _exitOfferProduct = lifetimeProduct; // Store for purchase
          }
        } catch (e) {
          debugPrint('⚠️ Error getting lifetime product: $e');
        }
      } else {
        debugPrint('🔍 Fetching exit offer product: $exitOfferProductId');

        // Query the exit offer product from the store
        final Set<String> exitOfferIds = {exitOfferProductId};
        final ProductDetailsResponse exitOfferResponse =
            await _inAppPurchase.queryProductDetails(exitOfferIds);

        if (exitOfferResponse.productDetails.isNotEmpty) {
          final exitOfferProduct = exitOfferResponse.productDetails.first;
          _exitOfferProduct = exitOfferProduct; // Store for purchase
          exitOfferPrice = exitOfferProduct.price;
          debugPrint('✅ Exit offer product loaded: ${exitOfferProduct.id}');
          debugPrint('💰 EXIT OFFER PRICE: $exitOfferPrice');
        } else {
          debugPrint(
              '⚠️ Exit offer product not found in store, using lifetime product');
          if (exitOfferResponse.error != null) {
            debugPrint('❌ Error: ${exitOfferResponse.error}');
          }
          // Fallback to lifetime product
          try {
            final lifetimeProduct = _products.firstWhere(
              (product) => product.id == widget.lifeTimePlan,
              orElse: () => _products.isNotEmpty
                  ? _products.first
                  : null as ProductDetails,
            );
            if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
              exitOfferPrice = lifetimeProduct.price;
              _exitOfferProduct = lifetimeProduct; // Store for purchase
            }
          } catch (e) {
            debugPrint('⚠️ Error getting lifetime product as fallback: $e');
          }
        }
      }

      // Get original lifetime product price for comparison
      try {
        final lifetimeProduct = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () =>
              _products.isNotEmpty ? _products.first : null as ProductDetails,
        );
        if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
          originalLifetimePrice = lifetimeProduct.price;
          debugPrint('📊 Original Lifetime Price: $originalLifetimePrice');
        }
      } catch (e) {
        debugPrint('⚠️ Error getting original lifetime product price: $e');
      }

      // Print exit offer details
      debugPrint(
          '📊 Exit Offer Data - identifier: ${exitOffer.identifier}, item_1: ${exitOffer.item_1}, item_2: ${exitOffer.item_2}, discount_value: ${exitOffer.value}');
      debugPrint('💰 Final Exit Offer Price: $exitOfferPrice');
      debugPrint('💰 Original Lifetime Price: $originalLifetimePrice');
    } catch (e) {
      debugPrint('❌ Error fetching exit offer product: $e');
      // Fallback to original lifetime product price
      try {
        final lifetimeProduct = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () =>
              _products.isNotEmpty ? _products.first : null as ProductDetails,
        );
        if (lifetimeProduct != null && lifetimeProduct.price.isNotEmpty) {
          exitOfferPrice = lifetimeProduct.price;
          _exitOfferProduct = lifetimeProduct; // Store for purchase
        }
      } catch (e2) {
        debugPrint('❌ Error in fallback: $e2');
      }
    }

    final lifetimePrice = exitOfferPrice;

    if (!mounted) {
      _isExitOfferShowing = false; // Reset flag if widget is not mounted
      return;
    }

    // Show bottom sheet after product is fetched
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible:
          false, // Prevent auto-dismiss on iPad - user must take action
      enableDrag: false,
      builder: (BuildContext context) {
        return _ExitOfferBottomSheetContent(
          exitOffer: exitOffer,
          lifetimePrice: lifetimePrice,
          originalLifetimePrice: originalLifetimePrice,
          screenWidth: screenWidth,
          initialMinutes: initialMinutes,
          initialSeconds: initialSeconds,
          onUnlockPremium: () {
            _isExitOfferShowing = false; // Reset flag when dismissed
            Navigator.of(context).pop();
            _handleExitOfferPurchase();
          },
          onMaybeLater: () {
            _isExitOfferShowing = false; // Reset flag when dismissed
            // Mark cooldown active so home icon can show dot for 10 minutes
            SharPreferences.setBoolean('exit_offer_cooldown_active', true);
            Navigator.of(context).pop();
            _navigateAwayFromPaywall();
          },
        );
      },
    ).whenComplete(() {
      // Reset flag when bottom sheet is dismissed (in case of swipe down or back button)
      _isExitOfferShowing = false;
    });
  }

  /// Handle exit offer purchase (lifetime plan)
  Future<void> _handleExitOfferPurchase() async {
    try {
      // Set startpurches flag to true so purchase can be processed
      await SharPreferences.setBoolean('startpurches', true);

      // Use exit offer product if available, otherwise fallback to regular lifetime product
      ProductDetails? productToPurchase = _exitOfferProduct;

      if (productToPurchase == null) {
        debugPrint(
            '⚠️ Exit offer product not available, using regular lifetime product');
        // Fallback to regular lifetime product
        productToPurchase = _products.firstWhere(
          (product) => product.id == widget.lifeTimePlan,
          orElse: () => _products.first,
        );
      } else {
        debugPrint('✅ Using exit offer product: ${productToPurchase.id}');
      }

      // Trigger purchase
      await _buyProduct(productToPurchase);
    } catch (e) {
      debugPrint('Error handling exit offer purchase: $e');
      Constants.showToast('Unable to process purchase. Please try again.');
    }
  }

  Future<void> _verifyPurchases() async {
    PurchaseDetails? purchase = _hasUserPurchased('');
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {}
  }

  restorePurchaseHandle(
      String productId, String date, DashBoardController controller,
      {BuildContext? context}) async {
    await SharPreferences.setString('OpenAd', '1');
    final dateTime = DateTime.tryParse(date) ?? DateTime.now();
    await Future.delayed(Duration(seconds: 2));
    final data = await SharPreferences.getBoolean('restorepurches');
    final startFlag = await SharPreferences.getBoolean('startpurches');
    final successToastMessage =
        (startFlag == true) ? 'Purchase Successful' : 'Restore Successful';
    debugPrint("restore data 1 is $data");
    if (data == true) {
      // Treat Exit Offer product as lifetime plan for premium unlock flow
      final bool isExitOfferLifetime =
          productId.toString().toLowerCase().contains('lifetime.exitoffer') ||
              productId.toString().toLowerCase().contains('exitoffer');

      // Get DownloadProvider to set subscription plan
      DownloadProvider? downloadProvider;
      if (context != null) {
        downloadProvider =
            Provider.of<DownloadProvider>(context, listen: false);
      } else {
        // Try to get from Get.context as fallback
        final getContext = Get.context;
        if (getContext != null) {
          downloadProvider =
              Provider.of<DownloadProvider>(getContext, listen: false);
        }
      }

      if (productId == widget.lifeTimePlan || isExitOfferLifetime) {
        await controller.disableAd(const Duration(days: 3650012345));
        // Set subscription plan to platinum for lifetime plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('platinum');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        return Get.offAll(() => HomeScreen(
              From: "premium",
              selectedVerseNumForRead: "",
              selectedBookForRead: "",
              selectedChapterForRead: "",
              selectedBookNameForRead: "",
              selectedVerseForRead: "",
            ));
      } else if (productId == widget.oneYearPlan) {
        final dur = DateTime(dateTime.year + 1, dateTime.month, dateTime.day);
        final diff = dur.difference(DateTime.now());
        await controller.disableAd(diff);
        // Set subscription plan to gold for one year plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('gold');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        return Get.offAll(() => HomeScreen(
              From: "premium",
              selectedVerseNumForRead: "",
              selectedBookForRead: "",
              selectedChapterForRead: "",
              selectedBookNameForRead: "",
              selectedVerseForRead: "",
            ));
      } else if (productId == widget.sixMonthPlan) {
        final dur = addSixMonths(customDate: dateTime);
        final diff = dur.difference(DateTime.now());
        await controller.disableAd(diff);
        // Set subscription plan to silver for six month plan
        if (downloadProvider != null) {
          await downloadProvider.setSubscriptionPlan('silver');
        }
        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
        Constants.showToast(successToastMessage);
        await SharPreferences.setBoolean('closead', true);
        return Get.offAll(() => HomeScreen(
              From: "premium",
              selectedVerseNumForRead: "",
              selectedBookForRead: "",
              selectedChapterForRead: "",
              selectedBookNameForRead: "",
              selectedVerseForRead: "",
            ));
      }
    }
    // final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
    //     _inAppPurchase
    //         .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    // await iosPlatformAddition.setDelegate(null);
    // await _subscription?.cancel();

    // await Future.delayed(Duration(seconds: 1));
    // EasyLoading.dismiss();
    // await SharPreferences.setBoolean('closead', true);
    // Get.back();
    // return Get.offAll(() => HomeScreen(
    //       From: "premium",
    //       selectedVerseNumForRead: "",
    //       selectedBookForRead: "",
    //       selectedChapterForRead: "",
    //       selectedBookNameForRead: "",
    //       selectedVerseForRead: "",
    //     ));
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList,
      DashBoardController controller) {
    // ignore: avoid_function_literals_in_foreach_calls
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      debugPrint("Purchase State: ${purchaseDetails.status}");
      await SharPreferences.setString('OpenAd', '1');
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Error: ${purchaseDetails.error}');
          DebugConsole.log(" purchases error - $purchaseDetails");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            final data1 = await SharPreferences.getBoolean('startpurches');
            debugPrint("purchase data 5 is $data1");
            if (data1 == true) {
              if (Platform.isIOS) {
                //  var response =
                http.post(
                  Uri.parse(kDebugMode
                      ? 'https://sandbox.itunes.apple.com/verifyReceipt'
                      : 'https://buy.itunes.apple.com/verifyReceipt'),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: {
                    'receipt-data':
                        purchaseDetails.verificationData.localVerificationData,
                    'exclude-old-transactions': true,
                    'password': controller.sharedSecret
                  },
                );

                // DebugConsole.log(
                //     "  purchases sucess frist : ${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()} - ${response.body}");

                // final data = parseHtmlAndExtractJson(response.body);
                await Future.delayed(Duration(seconds: 1));
                // DebugConsole.log(" purchases sucess - $data");
                await purchaseSubmit(
                    receiptData:
                        '${purchaseDetails.purchaseID}-productId:${purchaseDetails.productID}-date:${DateTime.now()}');
                final todayDate = DateTime.now();
                await SharPreferences.setBoolean("downloadreward", true);
                await Future.delayed(Duration(seconds: 1));
                if (purchaseDetails.productID == widget.sixMonthPlan) {
                  final expiryDate = addSixMonths();
                  final diff = expiryDate.difference(todayDate);
                  await controller.disableAd(diff);
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 2");
                  return Get.offAll(() => HomeScreen(
                        From: "premium",
                        selectedVerseNumForRead: "",
                        selectedBookForRead: "",
                        selectedChapterForRead: "",
                        selectedBookNameForRead: "",
                        selectedVerseForRead: "",
                      ));
                } else if (purchaseDetails.productID == widget.oneYearPlan) {
                  await controller.disableAd(const Duration(days: 366));
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 3 ");
                  return Get.offAll(() => HomeScreen(
                        From: "premium",
                        selectedVerseNumForRead: "",
                        selectedBookForRead: "",
                        selectedChapterForRead: "",
                        selectedBookNameForRead: "",
                        selectedVerseForRead: "",
                      ));
                } else if (purchaseDetails.productID == widget.lifeTimePlan) {
                  await controller.disableAd(const Duration(days: 3650012345));
                  // Set subscription plan to platinum for lifetime plan
                  DownloadProvider? downloadProvider = _myProvider;
                  if (downloadProvider == null) {
                    // Try to get from Get.context as fallback
                    final getContext = Get.context;
                    if (getContext != null) {
                      downloadProvider = Provider.of<DownloadProvider>(
                          getContext,
                          listen: false);
                    }
                  }
                  if (downloadProvider != null) {
                    await downloadProvider.setSubscriptionPlan('platinum');
                  }
                  await Future.delayed(Duration(seconds: 2));
                  // Complete the purchase for iOS - critical to prevent infinite loading
                  if (Platform.isIOS) {
                    await _inAppPurchase.completePurchase(purchaseDetails);
                  }
                  EasyLoading.dismiss();
                  Constants.showToast('Purchase Successful');
                  await SharPreferences.setBoolean('closead', true);
                  debugPrint("restore data 4 ");
                  return Get.offAll(() => HomeScreen(
                        From: "premium",
                        selectedVerseNumForRead: "",
                        selectedBookForRead: "",
                        selectedChapterForRead: "",
                        selectedBookNameForRead: "",
                        selectedVerseForRead: "",
                      ));
                } else {
                  // Check if this is exit offer purchase
                  final exitOfferId =
                      await SharPreferences.getString('exitOfferPlan') ??
                          BibleInfo.exitOfferPlanid;
                  if (purchaseDetails.productID == exitOfferId ||
                      (_exitOfferProduct != null &&
                          purchaseDetails.productID == _exitOfferProduct!.id)) {
                    // Handle exit offer purchase success
                    await controller
                        .disableAd(const Duration(days: 3650012345));
                    // Set subscription plan to platinum for exit offer (lifetime) purchase
                    DownloadProvider? downloadProvider = _myProvider;
                    if (downloadProvider == null) {
                      // Try to get from Get.context as fallback
                      final getContext = Get.context;
                      if (getContext != null) {
                        downloadProvider = Provider.of<DownloadProvider>(
                            getContext,
                            listen: false);
                      }
                    }
                    if (downloadProvider != null) {
                      await downloadProvider.setSubscriptionPlan('platinum');
                    }
                    await Future.delayed(Duration(seconds: 2));
                    // Complete the purchase for iOS - critical to prevent infinite loading
                    if (Platform.isIOS) {
                      await _inAppPurchase.completePurchase(purchaseDetails);
                    }
                    EasyLoading.dismiss();
                    Constants.showToast('Purchase Successful');
                    await SharPreferences.setBoolean('closead', true);
                    debugPrint(
                        "exit offer purchase success - redirecting to home");
                    return Get.offAll(() => HomeScreen(
                          From: "premium",
                          selectedVerseNumForRead: "",
                          selectedBookForRead: "",
                          selectedChapterForRead: "",
                          selectedBookNameForRead: "",
                          selectedVerseForRead: "",
                        ));
                  } else {
                    // Fallback: If product ID doesn't match any known plan, treat as lifetime purchase
                    // This ensures loader stops and redirects even for unexpected product IDs
                    debugPrint(
                        "Unknown product ID: ${purchaseDetails.productID}, treating as lifetime purchase");
                    await controller
                        .disableAd(const Duration(days: 3650012345));
                    await Future.delayed(Duration(seconds: 2));
                    // Complete the purchase for iOS - critical to prevent infinite loading
                    if (Platform.isIOS) {
                      await _inAppPurchase.completePurchase(purchaseDetails);
                    }
                    EasyLoading.dismiss();
                    Constants.showToast('Purchase Successful');
                    await SharPreferences.setBoolean('closead', true);
                    debugPrint(
                        "purchase success (fallback) - redirecting to home");
                    return Get.offAll(() => HomeScreen(
                          From: "premium",
                          selectedVerseNumForRead: "",
                          selectedBookForRead: "",
                          selectedChapterForRead: "",
                          selectedBookNameForRead: "",
                          selectedVerseForRead: "",
                        ));
                  }
                }
              }
            }
          } else if (purchaseDetails.status == PurchaseStatus.restored) {
            EasyLoading.dismiss();
            final restoreFlag =
                await SharPreferences.getBoolean('restorepurches');
            final startFlag = await SharPreferences.getBoolean('startpurches');
            debugPrint("restore data 5 is $restoreFlag");

            // If Apple reports "restored" during a Buy flow (already subscribed),
            // handle it using the existing restore logic.
            if (restoreFlag == true || startFlag == true) {
              if (restoreFlag != true) {
                await SharPreferences.setBoolean('restorepurches', true);
              }
              // debugPrint("restore data 6 is $data");
              // await restorePurchaseHandle(purchaseDetails.productID,
              //     purchaseDetails.transactionDate ?? '', controller);
              _handleRestore(purchaseDetails, controller);
            }
          }
        } else if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
          EasyLoading.dismiss();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          EasyLoading.dismiss();
          Constants.showToast('Something went wrong');

          // Check if this is the first time showing paywall and user canceled
          await _checkAndShowExitOffer(controller);
        }
      }
    });
  }

  _initialize() async {
    await SharPreferences.setBoolean('closead', false);
    await SharPreferences.setString('OpenAd', '1');
    await SharPreferences.setBoolean('restorepurches', false);
    await SharPreferences.setBoolean('startpurches', false);

    // Provider.of<DownloadProvider>(context, listen: false).disableAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myProvider = Provider.of<DownloadProvider>(context, listen: false);
      _myProvider?.disableAd();
    });
    if (mounted) {
      setState(() {
        isPurchaseLoading = true;
      });
    }

    // Check if preloaded data is available
    final preloadedAvailability =
        PaywallPreloadService.getPreloadedAvailability();
    final preloadedProducts = PaywallPreloadService.getPreloadedProducts();

    if (preloadedAvailability != null && preloadedProducts.isNotEmpty) {
      // Use preloaded data - instant display
      debugPrint('Using preloaded paywall data');
      _isAvailable = preloadedAvailability;
      if (mounted) {
        setState(() {
          _products = preloadedProducts;
          _sortProducts();
          isPurchaseLoading = false;
        });
      }
      // Save preloaded products to cache
      final productprovider =
          Provider.of<DownloadProvider>(context, listen: false);
      await productprovider.saveProductList(preloadedProducts.map((iapProduct) {
        return m.ProductDetails(
          id: iapProduct.id,
          title: iapProduct.title,
          description: iapProduct.description,
          price: iapProduct.price,
          rawPrice: iapProduct.rawPrice,
          currencyCode: iapProduct.currencyCode,
          currencySymbol: iapProduct.currencySymbol,
        );
      }).toList());
    } else {
      // Fallback to original loading logic if preload not available
      // Check availability of InApp Purchases
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('Is Available: $_isAvailable');
      // perform our async calls only when in-app purchase is available
      if (_isAvailable) {
        await _getUserProducts();
        // _verifyPurchases();

        // listen to new purchases and rebuild the widget whenever
        // there is a new purchase after adding the new purchase to our
        // purchase list

        // If products are still empty after loading, create fallback from constants
        if (_products.isEmpty && mounted) {
          debugPrint(
              '⚠️ Products still empty after load, creating fallback from constants');
          _createFallbackProductsFromConstants();
        }

        if (mounted) {
          setState(() {
            isPurchaseLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isPurchaseLoading = false;
          });
        }
      }
    }
  }

  Future<void> _getUserProducts() async {
    // setState(() {});
    await SharPreferences.setBoolean('closead', false);
    final productprovider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      // Set delegate to null - delegate is optional for querying products
      // Purchase transactions will handle delegate setup separately if needed
      await iosPlatformAddition.setDelegate(null);

      Set<String> ids = {
        widget.sixMonthPlan,
        widget.oneYearPlan,
        widget.lifeTimePlan
      };

      debugPrint("🔍 Querying products - IDs: $ids");
      debugPrint("📦 Current products empty: ${_products.isEmpty}");

      final datafn = await productprovider.loadProductList();
      debugPrint("💾 Loaded from cache: ${datafn.length} products");

      final datacheck = datafn.map((data) {
        return ProductDetails(
          id: data.id,
          title: data.title,
          description: data.description,
          price: data.price,
          rawPrice: data.rawPrice,
          currencyCode: data.currencyCode,
          currencySymbol: data.currencySymbol,
        );
      }).toList();

      if (_products.isEmpty && datacheck.isEmpty) {
        debugPrint("🔄 Cache is empty, querying from App Store...");
        ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(ids);

        debugPrint("📊 Product Details Response:");
        debugPrint("   - Error: ${response.error}");
        debugPrint("   - Not Found IDs: ${response.notFoundIDs}");
        debugPrint(
            "   - Product Details Count: ${response.productDetails.length}");
        debugPrint(
            "   - Products: ${response.productDetails.map((p) => '${p.id}: ${p.price}').join(', ')}");

        if (response.error != null) {
          debugPrint("❌ Error querying products: ${response.error}");
        }

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
              "⚠️ Products not found in App Store: ${response.notFoundIDs.join(', ')}");
        }

        if (response.productDetails.isEmpty) {
          debugPrint("⚠️ No products returned. This might mean:");
          debugPrint("   1. Products not configured in App Store Connect");
          debugPrint("   2. Products not approved yet");
          debugPrint("   3. Network/Store connectivity issue");
        }

        await Future.delayed(Duration(seconds: 2));

        if (response.productDetails.isNotEmpty) {
          await productprovider
              .saveProductList(response.productDetails.map((iapProduct) {
            return m.ProductDetails(
              id: iapProduct.id,
              title: iapProduct.title,
              description: iapProduct.description,
              price: iapProduct.price,
              rawPrice: iapProduct.rawPrice,
              currencyCode: iapProduct.currencyCode,
              currencySymbol: iapProduct.currencySymbol,
            );
          }).toList());
          setState(() {
            _products = response.productDetails;
            _sortProducts();
            debugPrint("✅ Products loaded successfully: ${_products.length}");
          });
        } else {
          debugPrint(
              "⚠️ No products from store, creating fallback products from constants");
          // Create fallback products using constant plan IDs
          _createFallbackProductsFromConstants();
        }
      } else {
        // Using cached products
        debugPrint("💾 Loading products from cache");
        final data = await productprovider.loadProductList();

        if (data.isNotEmpty) {
          setState(() {
            _products = data.map((data) {
              return ProductDetails(
                id: data.id,
                title: data.title,
                description: data.description,
                price: data.price,
                rawPrice: data.rawPrice,
                currencyCode: data.currencyCode,
                currencySymbol: data.currencySymbol,
              );
            }).toList();
            _sortProducts();
            debugPrint("✅ Loaded ${_products.length} products from cache");
          });
        } else {
          debugPrint(
              "⚠️ Cache is empty, creating fallback products from constants");
          // Create fallback products using constant plan IDs
          _createFallbackProductsFromConstants();
        }
      }
    }
  }

  /// Create fallback products using constant plan IDs when store query fails
  void _createFallbackProductsFromConstants() {
    debugPrint('📦 Creating fallback products from constants...');
    final List<ProductDetails> fallbackProducts = [];

    // Create fallback products using constant plan IDs from widget
    // These are already constants when API data is not available
    if (widget.sixMonthPlan.isNotEmpty) {
      fallbackProducts.add(ProductDetails(
        id: widget.sixMonthPlan,
        title: '6 Months Premium',
        description: 'Get 6 months of premium access',
        price: '\$9.99',
        rawPrice: 9.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ));
    }

    if (widget.oneYearPlan.isNotEmpty) {
      fallbackProducts.add(ProductDetails(
        id: widget.oneYearPlan,
        title: '1 Year Premium',
        description: 'Get 1 year of premium access',
        price: '\$19.99',
        rawPrice: 19.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ));
    }

    if (widget.lifeTimePlan.isNotEmpty) {
      fallbackProducts.add(ProductDetails(
        id: widget.lifeTimePlan,
        title: 'Lifetime Premium',
        description: 'Get lifetime premium access',
        price: '\$24.99',
        rawPrice: 24.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ));
    }

    if (fallbackProducts.isNotEmpty && mounted) {
      setState(() {
        _products = fallbackProducts;
        _sortProducts();
        debugPrint(
            '✅ Created ${_products.length} fallback products from constants');
      });
    } else {
      debugPrint('⚠️ Could not create fallback products');
    }
  }

  final controller = Get.put(DashBoardController());
//  final controller = Get.find<DashBoardController>();
  @override
  void initState() {
    super.initState();
    // Track Paywall Screen event
    StatsigService.trackPaywallScreen();

    // Mark that paywall is being shown for the first time tracking
    _markPaywallShown();

    _initialize();
    // WidgetsBinding.instance.addObserver(this);
    debugPrint("iap ad - WidgetsBinding");

    _purchaseUpdatedStream = InAppPurchase.instance.purchaseStream;
    _purchaseUpdatedStream.listen(
      (purchases) => _listenToPurchaseUpdated(purchases, controller),
      onDone: () {
        // _subscription?.cancel();
      },
      onError: (error) {
        debugPrint("Purchase Stream Error: $error");
      },
    );

    // Removed auto-show exit offer when coming from home screen
    // Exit offer will now only show when user taps Close icon or "Continue with free version"
    // if (widget.checkad == 'home') {
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     await Future.delayed(const Duration(milliseconds: 1000));
    //     if (mounted) {
    //       await _checkAndShowExitOfferFromHome();
    //     }
    //   });
    // }
    // _loadRewardedAd();
  }

  /// Check and show exit offer when accessed from home screen
  Future<void> _checkAndShowExitOfferFromHome() async {
    try {
      final exitOfferFirstShownTime =
          await SharPreferences.getString('exit_offer_first_shown_time');
      final now = DateTime.now();
      DateTime? firstShownDateTime;

      // Check if 10 minutes have passed
      try {
        if (exitOfferFirstShownTime != null) {
          firstShownDateTime = DateTime.parse(exitOfferFirstShownTime);
          final difference = now.difference(firstShownDateTime);

          if (difference.inMinutes >= 10) {
            // 10 minutes have passed, don't show forever
            debugPrint('⏭️ Exit offer time expired (10 minutes passed)');
            return;
          }
        } else {
          // First time access from home: start the 10-minute window
          firstShownDateTime = now;
          await SharPreferences.setBoolean('has_shown_exit_offer', true);
          await SharPreferences.setString(
              'exit_offer_first_shown_time', now.toIso8601String());
        }
      } catch (e) {
        debugPrint('Error parsing exit offer timestamp: $e');
        return;
      }

      // Get exit offer from API using instance controller
      final exitOffer = await _getExitOfferFromApi(controller);

      if (exitOffer != null && mounted) {
        debugPrint('✅ Showing exit offer bottom sheet from home screen');
        // Show exit offer bottom sheet
        _showExitOfferBottomSheet(exitOffer);
      } else {
        debugPrint('⚠️ Exit offer not found or widget not mounted');
      }
    } catch (e) {
      debugPrint('Error showing exit offer from home: $e');
    }
  }

  @override
  void dispose() {
    debugPrint("iap ad - dispose");
    _subscription?.cancel();
    // Reset exit offer flag on dispose
    _isExitOfferShowing = false;
    // Call async clean-up without awaiting
    alldispose();

    super.dispose();
  }

  void alldispose() async {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(null);
      // await _subscription?.cancel();
    }
  }

  double calculateOriginalPrice(
      double discountPercent, double discountedPrice) {
    // Convert the discount percentage to a fraction
    double discountFraction = discountPercent / 100;

    // Calculate the original price using the formula: original price = discounted price / (1 - discount fraction)
    double originalPrice = discountedPrice / (1 - discountFraction);

    return originalPrice;
  }

  //new iap logic

  /// 🔹 Handle restored purchases (after pressing restore button)
  Future<void> _handleRestore(
    PurchaseDetails purchaseDetails,
    DashBoardController controller,
  ) async {
    //EasyLoading.dismiss();
    debugPrint("Restored Purchase: ${purchaseDetails.productID}");

    //  await SharPreferences.setBoolean('restorepurches', true);
    // setState(() {
    //   isRestoreLoading = false;
    // });
    await restorePurchaseHandle(
      purchaseDetails.productID,
      purchaseDetails.transactionDate ?? '',
      controller,
      context: context,
    );
  }

  /// 🔹 Trigger restore (iOS only)
  Future<void> _restorePurchases(DashBoardController controller) async {
    // Check connectivity FIRST before showing loader
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast("Check your Internet connection");
      return; // Return early - don't show loader or proceed
    }

    // if (!Platform.isIOS) {
    //   Constants.showToast("Restore is only available on iOS");
    //   return;
    // }

    // setState(() {
    //   isRestoreLoading = true;
    // });
    EasyLoading.show(status: "Restoring...");

    // try {
    //   // This triggers restored purchases to come via purchaseStream
    //   await InAppPurchase.instance.restorePurchases();
    //   Constants.showToast("Restore request sent");
    // } catch (e) {
    //   Constants.showToast("Restore failed: $e");
    // }

    // EasyLoading.dismiss();
    // setState(() => isRestoreLoading = false);
//    await SharPreferences.setBoolean('restorepurches', true);
    await _inAppPurchase.restorePurchases();
    // setState(() {
    //   isRestoreLoading = true;
    // });
    await Future.delayed(Duration(seconds: 9));
    try {
      final res = await restorePurchase();
      if (res['status'] == 'success') {
        final rawData = res['data'].toString().split('-productId:');
        if (rawData.length == 2) {
          final data = rawData[1].split('-date:');
          final productId = data[0].toString();
          final date = data[1].toString();
          await restorePurchaseHandle(productId, date, controller,
              context: context);
          Constants.showToast('Restore Successful');
        }
      } else {
        Constants.showToast('No active subscription available');
      }
    } catch (e) {
      //  Constants.showToast(' error No active subscription available');

      DebugConsole.log("restore No active subscription available error - $e");
    }
    // setState(() {
    //   isRestoreLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // final controller =
    //     Get.put(DashBoardController()); // Initialize controller here
    //final controller = Get.find<DashBoardController>();

    // Move these helper functions outside the builder

    // Setup purchase stream listener once
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   _subscription = _inAppPurchase.purchaseStream.listen((data) {
    //     _listenToPurchaseUpdated(data, controller);
    //     // Use controller update instead of setState
    //     setState(() {
    //       _purchases.addAll(data);
    //       _verifyPurchases();
    //     });
    //   });
    // });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Check for exit offer before navigating away
        await _checkAndShowExitOfferBeforeClose(controller);
      },
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Images.bgImage(context)), // background texture
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none, // keep overlay elements fixed/visible
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button when coming from wallpaper
                          widget.checkad == 'image'
                              ? SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          color:
                                              CommanColor.whiteBlack(context),
                                          size: 24),
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        // Directly go back when coming from wallpaper (skip exit offer)
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          // Jesus Image
                          // Image.asset(
                          //   "assets/offer/jesus.png", // Replace with your image
                          //   height: size.height * 0.19,
                          //   fit: BoxFit.contain,
                          // ),
                          SizedBox(width: 15), // Space for fixed close button
                        ],
                      ),

                      SizedBox(height: size.height * 0.002),

                      // // Jesus Image
                      // Image.asset(
                      //   "assets/offer/jesus.png", // Replace with your image
                      //   height: size.height * 0.14,
                      //   fit: BoxFit.contain,
                      // ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        "GROW CLOSER TO GOD",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Features list
                      _buildFeatureItem(
                          "assets/offer/fe1.png", "Focus on God’s Word",
                          highlightWords: ["God’s Word"]),
                      _buildFeatureItem("assets/offer/fe2.png",
                          "Daily Guidance From Scripture",
                          highlightWords: ["Daily Guidance"]),
                      _buildFeatureItem("assets/offer/fe3.png",
                          "Understand God’s Word Clearly",
                          highlightWords: ["God’s Word"]),
                      _buildFeatureItem(
                          "assets/offer/fe4.png", "Your Bible, Always With You",
                          highlightWords: ["Your Bible"]),
                      // _buildFeatureItem("assets/guidance.png",
                      //     "Scripture Explanations & Answers",
                      //     highlightWords: ["Explanations & Answers"]),
                      // _buildFeatureItem("assets/coins.png", _currentBonusLabel,
                      //     highlightWords: [_currentBonusHighlight]),

                      const SizedBox(height: 15),
                      Text(
                          "Build a deeper, stronger relationship with God every day",
                          style: TextStyle(
                              color: CommanColor.whiteBlack(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            "assets/Line 217.png",
                            height: 20,
                            width: 20,
                            fit: BoxFit.fitWidth,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "CHOOSE YOUR PREMIUM PLAN",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: CommanColor.whiteBlack(context)),
                          ),
                          const SizedBox(width: 10),
                          Image.asset("assets/Line 216.png",
                              height: 20, width: 20),
                        ],
                      ),
                      // Choose plan text
                      // const Text(
                      //   "Unlock Premium Access",
                      //   style: TextStyle(color: Colors.black54),
                      // ),
                      // const Text(
                      //   "Try All Features Free for 3 Days",
                      //   style: TextStyle(color: Colors.black54),
                      // ),
                      const SizedBox(height: 12),

                      // Six months plan
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isPurchaseLoading
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                    height: 100,
                                    width: 200,
                                    child: Center(
                                        child: Column(
                                      children: [
                                        const CircularProgressIndicator
                                            .adaptive(),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Please wait...',
                                              style: CommanStyle.appBarStyle(
                                                      context)
                                                  .copyWith(fontSize: 12)),
                                        )
                                      ],
                                    ))),
                              )
                            : Column(
                                children: [
                                  // First row: Two plans side by side
                                  if (_products.length >= 2)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildPlanCard(0, controller),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildPlanCard(1, controller),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 15),
                                  // Second row: One plan full width
                                  if (_products.length >= 3)
                                    _buildPlanCard(2, controller),
                                  // Handle case with less than 3 products
                                  if (_products.length == 1)
                                    _buildPlanCard(2, controller),
                                ],
                              ),
                      ),

                      const SizedBox(height: 15),
                      Text("No Risk. No hidden charges",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CommanColor.whiteBlack(context)
                                  .withOpacity(0.7))),
                      const SizedBox(height: 15),

                      // One Year plan

                      // const Text(
                      //   "Auto renewal, cancel anytime",
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.black54,
                      //   ),
                      // ),
                      // const SizedBox(height: 12),

                      // Free trial button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await SharPreferences.setString('OpenAd', '1');
                              await SharPreferences.setBoolean(
                                  'startpurches', true);
                              _buyProduct(_products[selectedindex]);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero, // REQUIRED for gradient
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF763201),
                                    Color(0xFFD5821F),
                                    Color(0xFF763201),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Get Full Access',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),
                      TextButton(
                        onPressed: () async {
                          // Check for exit offer before navigating away
                          await _checkAndShowExitOfferBeforeClose(controller);
                        },
                        child: Text(
                          "Continue Free Version",
                          style: TextStyle(
                            color: CommanColor.whiteBlack(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            // decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              launchUrlString(
                                  'https://bibleoffice.com/terms_conditions.html');
                            },
                            child: Text(
                              "Terms of Use",
                              style: TextStyle(
                                fontSize: 12,
                                color: CommanColor.whiteBlack(context),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await SharPreferences.setBoolean(
                                  'restorepurches', true);
                              await _restorePurchases(controller);
                            },
                            child: Text(
                              "Restore",
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              launchUrlString(
                                  'https://bibleoffice.com/privacy_policy.html');
                            },
                            child: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                fontSize: 12,
                                color: CommanColor.whiteBlack(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              // Fixed Close Button - Always visible in top right corner
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(Icons.close,
                          color: CommanColor.whiteBlack(context), size: 20),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        // Check for exit offer before navigating away
                        await _checkAndShowExitOfferBeforeClose(controller);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _fakeOffer(ProductDetails product, DashBoardController controller) {
    if (product.id == widget.sixMonthPlan) {
      return double.tryParse(controller.sixMonthPlanValue ?? '');
    }
    if (product.id == widget.oneYearPlan) {
      return double.tryParse(controller.oneYearPlanValue ?? '');
    }
    if (product.id == widget.lifeTimePlan) {
      return double.tryParse(controller.lifeTimePlanValue ?? '');
    }
    return null;
  }

  String _getDiscountedPrice(
      ProductDetails product, DashBoardController controller) {
    final fakeOfferPercentage = _fakeOffer(product, controller);
    if (fakeOfferPercentage != null) {
      final fakePrice =
          calculateOriginalPrice(fakeOfferPercentage, product.rawPrice);
      return '${product.currencySymbol}${fakePrice.toStringAsFixed(2)}';
    }
    return '';
  }

  String _getPlanTitle(int index) {
    if (_products[index].id == widget.sixMonthPlan) return '6 Months';
    if (_products[index].id == widget.oneYearPlan) return '1 Year';
    if (_products[index].id == widget.lifeTimePlan) return 'Lifetime';
    return _products[index].description;
  }

  String _getPlanSubtitle(int index) {
    if (_products[index].id == widget.sixMonthPlan) return 'Daily Habit Plan';
    if (_products[index].id == widget.oneYearPlan) return 'Best Yearly Plan';
    if (_products[index].id == widget.lifeTimePlan)
      return 'Pay once, Grow forever';
    return '';
  }

  String get _currentBonusLabel {
    String label = "Get 5,000 Bonus credits with this plan";
    if (_products.isNotEmpty &&
        selectedindex >= 0 &&
        selectedindex < _products.length) {
      final currentId = _products[selectedindex].id;
      if (currentId == widget.sixMonthPlan) {
        label = "Get 500 Bonus credits with this plan";
      } else if (currentId == widget.oneYearPlan) {
        label = "Get 1,000 Bonus credits with this plan";
      } else if (currentId == widget.lifeTimePlan) {
        label = "Get 5,000 Bonus credits with this plan";
      }
    }
    return label;
  }

  String get _currentBonusHighlight {
    String highlight = "5,000 Bonus credits";
    if (_products.isNotEmpty &&
        selectedindex >= 0 &&
        selectedindex < _products.length) {
      final currentId = _products[selectedindex].id;
      if (currentId == widget.sixMonthPlan) {
        highlight = "500 Bonus credits";
      } else if (currentId == widget.oneYearPlan) {
        highlight = "1,000 Bonus credits";
      } else if (currentId == widget.lifeTimePlan) {
        highlight = "5,000 Bonus credits";
      }
    }
    return highlight;
  }

  String? _getBadgeText(int index, DashBoardController controller) {
    final fakeOfferValue = _fakeOffer(_products[index], controller);
    if (_products[index].id == widget.oneYearPlan && fakeOfferValue != null) {
      return 'Save ${fakeOfferValue.toStringAsFixed(0)}%';
    }
    if (_products[index].id == widget.lifeTimePlan) {
      return 'Best Value';
    }
    return null;
  }

  Widget _buildPlanCard(int index, DashBoardController controller) {
    final isSelected = selectedindex == index;
    final discountedPrice = _getDiscountedPrice(_products[index], controller);
    final badgeText = _getBadgeText(index, controller);
    final isLifetime = _products[index].id == widget.lifeTimePlan;

    return InkWell(
      onTap: () {
        setState(() {
          selectedindex = index;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: EdgeInsets.symmetric(
              horizontal: isLifetime ? 12 : 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? (CommanColor.isDarkTheme(context)
                        ? Colors.white
                        : const Color(0xFF6B5642))
                    : (CommanColor.isDarkTheme(context)
                        ? const Color(0xFFC4B5A0).withOpacity(0.3)
                        : const Color(0xFFC4B5A0)),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLifetime
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title on left
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPlanTitle(index),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CommanColor.whiteBlack(context),
                            ),
                          ),
                          Text("One Time Payment",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: CommanColor.whiteBlack(context)))
                        ],
                      ),
                      // Prices on right
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Strikethrough price (if exists)
                          if (discountedPrice.isNotEmpty) ...[
                            Text(
                              discountedPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CommanColor.whiteBlack(context)
                                    .withOpacity(0.6),
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Actual price
                          Text(
                            _products[index].price,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CommanColor.whiteBlack(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        _getPlanTitle(index),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CommanColor.whiteBlack(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      // Price Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Strikethrough price (if exists)
                          if (discountedPrice.isNotEmpty) ...[
                            Text(
                              discountedPrice,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CommanColor.whiteBlack(context)
                                    .withOpacity(0.6),
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Actual price
                          Text(
                            _products[index].price,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: CommanColor.whiteBlack(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Badge
          if (badgeText != null)
            Positioned(
              right: 10,
              top: -6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: CommanColor.isDarkTheme(context)
                      ? const Color(0xFFD4C5B0)
                      : const Color(0xFFA37030),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CommanColor.isDarkTheme(context)
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
      String text, List<String> highlightWords, BuildContext context) {
    List<TextSpan> spans = [];
    String remainingText = text;
    final highlightColor = CommanColor.isDarkTheme(context)
        ? Colors.white
        : const Color(0xFF805531);

    while (remainingText.isNotEmpty) {
      int earliestIndex = -1;
      String? foundWord;

      // Find the earliest occurrence of any highlight word
      for (String word in highlightWords) {
        int index = remainingText.toLowerCase().indexOf(word.toLowerCase());
        if (index != -1 && (earliestIndex == -1 || index < earliestIndex)) {
          earliestIndex = index;
          foundWord = word;
        }
      }

      if (earliestIndex == -1) {
        // No more highlights, add remaining text
        spans.add(TextSpan(text: remainingText));
        break;
      } else {
        // Add text before highlight
        if (earliestIndex > 0) {
          spans.add(TextSpan(text: remainingText.substring(0, earliestIndex)));
        }

        // Add highlighted word
        final actualWord = remainingText.substring(
            earliestIndex, earliestIndex + foundWord!.length);
        spans.add(TextSpan(
          text: actualWord,
          style: TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.w700,
          ),
        ));

        // Update remaining text
        remainingText =
            remainingText.substring(earliestIndex + foundWord.length);
      }
    }

    return spans;
  }

  Widget _buildFeatureItem(String image, String text,
      {List<String>? highlightWords}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 50),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(image, width: 28, height: 28), // ✅ use image, not Icon
          const SizedBox(width: 12),
          highlightWords != null && highlightWords.isNotEmpty
              ? RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 14, color: CommanColor.whiteBlack(context)),
                    children:
                        _buildHighlightedText(text, highlightWords, context),
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: CommanColor.whiteBlack(context)),
                ),
        ],
      ),
    );
  }
}

/// Exit Offer Bottom Sheet Content Widget with countdown timer
class _ExitOfferBottomSheetContent extends StatefulWidget {
  final GetAudioModelDataSubFields exitOffer;
  final String lifetimePrice;
  final String originalLifetimePrice;
  final double screenWidth;
  final int initialMinutes;
  final int initialSeconds;
  final VoidCallback onUnlockPremium;
  final VoidCallback onMaybeLater;

  const _ExitOfferBottomSheetContent({
    required this.exitOffer,
    required this.lifetimePrice,
    required this.originalLifetimePrice,
    required this.screenWidth,
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onUnlockPremium,
    required this.onMaybeLater,
  });

  @override
  State<_ExitOfferBottomSheetContent> createState() =>
      _ExitOfferBottomSheetContentState();
}

class _ExitOfferBottomSheetContentState
    extends State<_ExitOfferBottomSheetContent> {
  Timer? _countdownTimer;
  late int _countdownMinutes;
  late int _countdownSeconds;

  @override
  void initState() {
    super.initState();
    _countdownMinutes = widget.initialMinutes;
    _countdownSeconds = widget.initialSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else if (_countdownMinutes > 0) {
            _countdownMinutes--;
            _countdownSeconds = 59;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          false, // Prevent back button dismissal on iPad - user must take action
      child: Container(
        decoration: BoxDecoration(
          color: CommanColor.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button (X) at top right
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    // Red "LIMITED TIME OFFER" banner
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Special Faith Offer",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 12),
                    // Description
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: widget.screenWidth > 450 ? 16 : 18,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text: "Unlock every Premium Bible feature. Now ",
                          ),
                          const TextSpan(
                            text: "30% Off",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: " for the next 10 minutes",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Purple offer box
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0XFFF1F1F1), // Light purple
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFCDCDCD),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Lifetime Premium",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Original price with strike-through (if different from discounted price)
                          if (widget.originalLifetimePrice !=
                                  widget.lifetimePrice &&
                              widget.originalLifetimePrice.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.originalLifetimePrice,
                                  style: TextStyle(
                                    fontSize:
                                        widget.screenWidth > 450 ? 20 : 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87.withOpacity(0.6),
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.lifetimePrice,
                                  style: TextStyle(
                                    fontSize:
                                        widget.screenWidth > 450 ? 32 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            )
                          ],
                          // Discounted price

                          const SizedBox(height: 8),
                          const Text(
                            "One-Time Blessing. Lifetime Access.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Offer ends in ${_countdownMinutes.toString().padLeft(2, '0')}:${_countdownSeconds.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Unlock Bible Premium button (purple)
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: () {
                          _countdownTimer?.cancel();
                          widget.onUnlockPremium();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // REQUIRED for gradient
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF763201),
                                Color(0xFFD5821F),
                                Color(0xFF763201),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Text(
                              'Unlock Bible Premium',
                              style: TextStyle(
                                fontSize: widget.screenWidth > 450 ? 18 : 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Maybe Later text
                    TextButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        widget.onMaybeLater();
                      },
                      child: Text(
                        "Maybe later",
                        style: TextStyle(
                          fontSize: widget.screenWidth > 450 ? 16 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
