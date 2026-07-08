import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/Model/product_details_model.dart' as m;
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to preload Paywall Screen data at app startup
class PaywallPreloadService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static bool _isPreloading = false;
  static bool _isPreloaded = false;
  static bool? _isAvailable;
  static List<ProductDetails> _preloadedProducts = [];
  static bool _iosDelegateSet = false;
  static const String _cacheKey = 'product_details_list';

  /// Preload paywall data (call this at app startup)
  static Future<void> preloadPaywallData() async {
    if (_isPreloading || _isPreloaded) {
      return;
    }

    _isPreloading = true;
    debugPrint('PaywallPreloadService: Starting preload...');

    try {
      // Get product IDs from SharedPreferences
      final sixMonthPlan = AppApiConstant.resolveSubscriptionProductId(
        await SharPreferences.getString('sixMonthPlan'),
        BibleInfo.sixMonthPlanid,
      );
      final oneYearPlan = AppApiConstant.resolveSubscriptionProductId(
        await SharPreferences.getString('oneYearPlan'),
        BibleInfo.oneYearPlanid,
      );
      // Skip if product IDs are not available yet
      if (sixMonthPlan.isEmpty || oneYearPlan.isEmpty) {
        debugPrint('PaywallPreloadService: Product IDs not available yet, skipping preload');
        _isPreloading = false;
        return;
      }

      // Check availability of InApp Purchases
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('PaywallPreloadService: IAP Available: $_isAvailable');

      if (_isAvailable == true) {
        // Set iOS delegate if needed (set to null for preloading - delegate will be set in subscription screen)
        if (Platform.isIOS && !_iosDelegateSet) {
          try {
            final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
                _inAppPurchase
                    .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
            // Set delegate to null for preloading - the subscription screen will set proper delegate
            await iosPlatformAddition.setDelegate(null);
            _iosDelegateSet = true;
            debugPrint('PaywallPreloadService: iOS delegate set to null for preloading');
          } catch (e) {
            debugPrint('PaywallPreloadService: Error setting iOS delegate: $e');
          }
        }

        final dotIndex = sixMonthPlan.lastIndexOf('.');
      final bundlePrefix = dotIndex > 0
          ? sixMonthPlan.substring(0, dotIndex)
          : BibleInfo.ios_Bundle_Id;
      final twoYearPlanId = '$bundlePrefix.twoyearadsfree';

      // Query product details (include adfree/adsfree spelling variants)
        final Set<String> ids = AppApiConstant.paywallStoreQueryIds(
          sixMonthPlan: sixMonthPlan,
          oneYearPlan: oneYearPlan,
          twoYearPlan: twoYearPlanId,
        );
        debugPrint('PaywallPreloadService: App bundle prefix: $bundlePrefix');
        debugPrint('PaywallPreloadService: Querying product details for: $ids');

        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(ids);
        
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
              'PaywallPreloadService: Products not found in store: ${response.notFoundIDs}');
        }

        if (response.productDetails.isNotEmpty) {
          _preloadedProducts = response.productDetails
              .where((product) => product.id.startsWith('$bundlePrefix.'))
              .toList();
          if (_preloadedProducts.length != response.productDetails.length) {
            final stale = response.productDetails
                .where((product) => !product.id.startsWith('$bundlePrefix.'))
                .map((product) => product.id)
                .toList();
            debugPrint(
              'PaywallPreloadService: Ignored stale products from other bundle: '
              '$stale',
            );
          }
          _preloadedProducts.sort((a, b) {
            int order(String id) {
              if (id == sixMonthPlan || id.contains('sixmonth')) return 0;
              if (id == oneYearPlan || id.contains('oneyear')) return 1;
              if (id == twoYearPlanId || id.contains('twoyear')) return 2;
              return 3;
            }

            return order(a.id).compareTo(order(b.id));
          });
          await _cachePreloadedProducts(_preloadedProducts);
          
          // Save to DownloadProvider cache if available
          try {
            // Note: We can't access Provider here without context, so we'll save directly
            // The screen will handle saving to DownloadProvider
            debugPrint(
                'PaywallPreloadService: Preloaded ${_preloadedProducts.length} products');
            for (var i = 0; i < _preloadedProducts.length; i++) {
              final product = _preloadedProducts[i];
              final slot = product.id.contains('sixmonth')
                  ? '6M'
                  : product.id.contains('oneyear')
                      ? '1Y'
                      : product.id.contains('twoyear')
                          ? '2Y'
                          : '?';
              debugPrint(
                '  preload[$i] slot=$slot | id=${product.id} | '
                'price=${product.price} | rawPrice=${product.rawPrice} | '
                'currency=${product.currencyCode}',
              );
            }
          } catch (e) {
            debugPrint('PaywallPreloadService: Error saving to cache: $e');
          }
        } else {
          debugPrint('PaywallPreloadService: No products found in response');
        }
      }

      _isPreloaded = true;
      debugPrint('PaywallPreloadService: Preload completed');
    } catch (e) {
      debugPrint('PaywallPreloadService: Error during preload: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Cache preloaded products to shared preferences for quick retrieval
  static Future<void> _cachePreloadedProducts(
      List<ProductDetails> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = products.map((iapProduct) {
        return jsonEncode(m.ProductDetails(
          id: iapProduct.id,
          title: iapProduct.title,
          description: iapProduct.description,
          price: iapProduct.price,
          rawPrice: iapProduct.rawPrice,
          currencyCode: iapProduct.currencyCode,
          currencySymbol: iapProduct.currencySymbol,
        ).toJson());
      }).toList();

      await prefs.setStringList(_cacheKey, jsonList);
      debugPrint(
          'PaywallPreloadService: Cached ${products.length} products for quick load');
    } catch (e) {
      debugPrint('PaywallPreloadService: Error caching products: $e');
    }
  }

  /// Get preloaded IAP availability status
  static bool? getPreloadedAvailability() {
    return _isAvailable;
  }

  /// Get preloaded products
  static List<ProductDetails> getPreloadedProducts() {
    return List.from(_preloadedProducts);
  }

  /// Check if data has been preloaded
  static bool isPreloaded() {
    return _isPreloaded;
  }

  /// Whether onboarding should show the IAP paywall (internet + product data).
  static Future<bool> canShowOnboardingPaywall() async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        debugPrint(
            'PaywallPreloadService: Skip onboarding paywall — no internet');
        return false;
      }

      final sixMonthPlan = AppApiConstant.resolveSubscriptionProductId(
        await SharPreferences.getString('sixMonthPlan'),
        BibleInfo.sixMonthPlanid,
      );
      final oneYearPlan = AppApiConstant.resolveSubscriptionProductId(
        await SharPreferences.getString('oneYearPlan'),
        BibleInfo.oneYearPlanid,
      );
      if (sixMonthPlan.isEmpty || oneYearPlan.isEmpty) {
        debugPrint(
            'PaywallPreloadService: Skip onboarding paywall — product IDs missing');
        return false;
      }

      if (_preloadedProducts.isNotEmpty) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedList = prefs.getStringList(_cacheKey);
      if (cachedList != null && cachedList.isNotEmpty) {
        return true;
      }

      if (_isAvailable == false) {
        debugPrint(
            'PaywallPreloadService: Skip onboarding paywall — IAP unavailable');
        return false;
      }

      debugPrint(
          'PaywallPreloadService: Skip onboarding paywall — no product data');
      return false;
    } catch (e) {
      debugPrint('PaywallPreloadService: canShowOnboardingPaywall error: $e');
      return false;
    }
  }

  /// Reset preload status (useful for testing or re-preloading)
  static void reset() {
    _isPreloaded = false;
    _isPreloading = false;
    _isAvailable = null;
    _preloadedProducts.clear();
    _iosDelegateSet = false;
  }
}

