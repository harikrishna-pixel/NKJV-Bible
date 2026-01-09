import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/Model/product_details_model.dart' as m;
import 'package:biblebookapp/view/screens/dashboard/remove_add-screen.dart';
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
      final sixMonthPlan = await SharPreferences.getString('sixMonthPlan') ?? '';
      final oneYearPlan = await SharPreferences.getString('oneYearPlan') ?? '';
      final lifeTimePlan = await SharPreferences.getString('lifeTimePlan') ?? '';

      // Skip if product IDs are not available yet
      if (sixMonthPlan.isEmpty || oneYearPlan.isEmpty || lifeTimePlan.isEmpty) {
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

        // Query product details
        Set<String> ids = {sixMonthPlan, oneYearPlan, lifeTimePlan};
        debugPrint('PaywallPreloadService: Querying product details for: $ids');

        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(ids);
        
        if (response.productDetails.isNotEmpty) {
          _preloadedProducts = response.productDetails;
          _preloadedProducts.sort((a, b) => a.price.compareTo(b.price));
          await _cachePreloadedProducts(_preloadedProducts);
          
          // Save to DownloadProvider cache if available
          try {
            // Note: We can't access Provider here without context, so we'll save directly
            // The screen will handle saving to DownloadProvider
            debugPrint('PaywallPreloadService: Preloaded ${_preloadedProducts.length} products');
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

  /// Reset preload status (useful for testing or re-preloading)
  static void reset() {
    _isPreloaded = false;
    _isPreloading = false;
    _isAvailable = null;
    _preloadedProducts.clear();
    _iosDelegateSet = false;
  }
}

