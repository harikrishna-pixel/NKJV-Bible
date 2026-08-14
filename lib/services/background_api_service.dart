import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:biblebookapp/ads/levelplay_ads.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/Model/get_audio_model.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background API Service that loads APIs immediately when app starts
/// without blocking the UI
class BackgroundApiService {
  static final BackgroundApiService _instance = BackgroundApiService._internal();
  factory BackgroundApiService() => _instance;
  BackgroundApiService._internal();

  bool _isLoading = false;
  bool _isCompleted = false;
  Completer<void>? _loadingCompleter;

  /// Check if APIs are still loading
  bool get isLoading => _isLoading;

  /// Check if APIs have completed loading
  bool get isCompleted => _isCompleted;

  /// Start loading APIs in background (non-blocking)
  /// This should be called immediately when app starts
  void startBackgroundLoading() {
    if (_isLoading || _isCompleted) {
      return; // Already loading or completed
    }

    _isLoading = true;
    _loadingCompleter = Completer<void>();

    // Start loading in background without blocking
    // Use a small delay to ensure app is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadApisInBackground().then((_) {
        _isLoading = false;
        _isCompleted = true;
        _loadingCompleter?.complete();
        debugPrint('Background API loading completed');
      }).catchError((error) {
        _isLoading = false;
        _loadingCompleter?.completeError(error);
        debugPrint('Background API loading error: $error');
      });
    });
  }

  /// Wait for APIs to complete loading
  /// Returns immediately if already completed
  Future<void> waitForCompletion() async {
    if (_isCompleted) {
      return; // Already completed
    }

    if (_loadingCompleter != null) {
      try {
        await _loadingCompleter!.future;
      } catch (e) {
        debugPrint('Error waiting for API completion: $e');
      }
    } else {
      // If not started yet, start it now
      startBackgroundLoading();
      await waitForCompletion();
    }
  }

  /// Load all APIs in background directly without creating controller
  Future<void> _loadApisInBackground() async {
    try {
      // Load main API (getAppInfo.php) and cache it
      final value = await getMusicDetails();
      if (value != null) {
        // Cache the response
        await _cacheApiResponse(value);
        debugPrint('Background API: Main API loaded and cached');
        
        // Process the response to save preferences and load additional data
        await _processApiResponse(value);
      } else {
        debugPrint('Background API: Main API returned null, will use cache when needed');
      }
    } catch (e) {
      debugPrint('Error in background API loading: $e');
      // Continue - cache will be used when controller loads
    }
  }

  /// Cache API response to SharedPreferences
  Future<void> _cacheApiResponse(GetAudioModel value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value.data != null) {
        try {
          final jsonString = jsonEncode(value.toJson());
          await prefs.setString('cached_api_response', jsonString);
          debugPrint('Background API: Response cached successfully');
        } catch (jsonError) {
          debugPrint('Background API: Error encoding to JSON: $jsonError');
        }
      }
    } catch (e) {
      debugPrint('Background API: Error caching response: $e');
    }
  }

  /// Process API response - save preferences and load additional data
  Future<void> _processApiResponse(GetAudioModel value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save basic preferences
      await Future.wait([
        _saveBasicPreferences(value),
        _processSubscriptionData(value),
      ]);

      // Load more apps and books
      try {
        final appdata = await getMoreApps();
        int? bookAdsAppId = int.tryParse(value.data?.bookAdsAppId ?? '0') ?? 0;
        
        if (bookAdsAppId > 0) {
          final bookdata = await getBookCategories(bookAdsAppId);
          await StorageHelper.saveBooksAndApps(apps: appdata, books: bookdata);
        } else {
          await StorageHelper.saveBooksAndApps(apps: appdata);
        }
        debugPrint('Background API: More apps and books loaded');
      } catch (e) {
        debugPrint('Background API: Error loading more apps/books: $e');
        // Continue even if this fails
      }

      // Save ad preferences
      final adIds = await _getPlatformAdIds(value);
      await _saveAdPreferences(adIds, value);

      // Determine if ads are disabled
      bool isAdsDisabled = false;
      if (value.data != null && value.data?.adsType != null) {
        isAdsDisabled = value.data!.adsType == "0";
      } else {
        // We can't access BibleInfo here, so we'll let the controller handle it
        isAdsDisabled = false;
      }

      // Update ads status in preferences
      await prefs.setBool('ad_enabled', !isAdsDisabled);
      await prefs.setBool('isAdsEnabledApi', !isAdsDisabled);
      
      debugPrint('Background API: All preferences saved');
      
      // Trigger paywall preloading after product IDs are saved
      // This will load paywall data in background
      PaywallPreloadService.preloadPaywallData();
      debugPrint('Background API: Paywall preloading triggered');
    } catch (e) {
      debugPrint('Background API: Error processing response: $e');
    }
  }

  /// Save basic preferences
  Future<void> _saveBasicPreferences(GetAudioModel value) async {
    try {
      // Import needed for SharPreferences
      // We'll use SharedPreferences directly to avoid dependency issues
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallpaperCatID', value.data?.wallpaperCatId ?? '');
      await prefs.setString('imageAppID', value.data?.imageAppId ?? '');
      await prefs.setString('adPauseDiff', value.data?.adsDuration ?? '');
    } catch (e) {
      debugPrint('Background API: Error saving basic preferences: $e');
    }
  }

  /// Process subscription data
  Future<void> _processSubscriptionData(GetAudioModel value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int bookAdsStatus = int.tryParse(value.data?.bookAdsStatus ?? '0') ?? 0;
      int bookAdsAppId = int.tryParse(value.data?.bookAdsAppId ?? '0') ?? 0;
      
      await prefs.setInt('bookAdsStatus', bookAdsStatus);
      await prefs.setInt('bookAdsAppId', bookAdsAppId);
      await prefs.setBool('isSubscriptionEnabled', value.data?.isSubscriptionEnabled == '1');
      await prefs.setString('subSharedsecret', value.data?.subSharedsecret ?? '');
      
      // Save subscription plans - Use constants as fallback when API data is not available
      await prefs.setString(
          'sixMonthPlan',
          AppApiConstant.resolveSubscriptionProductId(
            value.data?.subIdentifierSixMonth,
            BibleInfo.sixMonthPlanid,
          ));
      await prefs.setString(
          'oneYearPlan',
          AppApiConstant.resolveSubscriptionProductId(
            value.data?.subIdentifierOneyear,
            BibleInfo.oneYearPlanid,
          ));
      await prefs.setString(
          'lifeTimePlan',
          AppApiConstant.resolveSubscriptionProductId(
            value.data?.subIdentifierLifetime,
            BibleInfo.lifeTimePlanid,
          ));
      await prefs.setString('sixMonthPlanvalue', value.data?.subIdentifierSixMonthValue ?? '');
      await prefs.setString('oneYearPlanvalue', value.data?.subIdentifierOneyearValue ?? '');
      await prefs.setString('lifeTimePlanvalue', value.data?.subIdentifierLifetimeValue ?? '');
      
      // Extract and save exit offer ID from subFields
      String exitOfferId = BibleInfo.exitOfferPlanid; // Default to constant
      if (value.data?.subFields != null) {
        for (var field in value.data!.subFields!) {
          if (field?.identifier != null && 
              field!.identifier!.isNotEmpty && 
              field.identifier!.contains('exitoffer')) {
            exitOfferId = field.identifier!;
            break;
          }
        }
      }
      await prefs.setString('exitOfferPlan', exitOfferId);
      
      // Extract coin pack IDs from subFields
      String coinPack1Id = BibleInfo.coinPack1Id; // Default to constant
      String coinPack2Id = BibleInfo.coinPack2Id; // Default to constant
      String coinPack3Id = BibleInfo.coinPack3Id; // Default to constant
      if (value.data?.subFields != null) {
        for (var field in value.data!.subFields!) {
          if (field?.identifier != null && 
              field!.identifier!.isNotEmpty && 
              field.identifier!.contains('coinspack')) {
            if (field.identifier!.contains('coinspack1')) {
              coinPack1Id = field.identifier!;
            } else if (field.identifier!.contains('coinspack2')) {
              coinPack2Id = field.identifier!;
            } else if (field.identifier!.contains('coinspack3')) {
              coinPack3Id = field.identifier!;
            }
          }
        }
      }
      await prefs.setString('coinPack1Id', coinPack1Id);
      await prefs.setString('coinPack2Id', coinPack2Id);
      await prefs.setString('coinPack3Id', coinPack3Id);
      
      // Save offer data
      await prefs.setString('offerenabled', value.data?.offerEnabled ?? '');
      await prefs.setInt('offercount', int.tryParse(value.data?.offerCount.toString() ?? '') ?? 5);
      
      // Save coin pack data from sub_fields (keep existing JSON structure for backward compatibility)
      if (value.data?.subFields != null) {
        // Print full API response for wallet credits/coin packs
        debugPrint('═══════════════════════════════════════════════════════════════════════');
        debugPrint('Wallet Credits API Response:');
        try {
          debugPrint('Full API Response Data: ${value.data?.toJson()}');
        } catch (e) {
          debugPrint('Could not serialize full API response: $e');
        }
        debugPrint('SubFields Count: ${value.data!.subFields!.length}');
        
        final coinPacks = <String, dynamic>{};
        for (var field in value.data!.subFields!) {
          if (field?.identifier != null && 
              field!.identifier!.isNotEmpty && 
              field.identifier!.contains('coinspack')) {
            // Print individual coin pack field details
            debugPrint('Coin Pack Field Found:');
            debugPrint('  - Identifier: ${field.identifier}');
            debugPrint('  - Credits (item_1): ${field.item_1}');
            debugPrint('  - Discount (value): ${field.value}');
            debugPrint('  - Field Num: ${field.fieldNum}');
            try {
              debugPrint('  - Full Field Data: ${field.toJson()}');
            } catch (e) {
              debugPrint('  - Could not serialize field data: $e');
            }
            
            coinPacks[field.identifier!] = {
              'credits': field.item_1 ?? '0',
              'discount': field.value ?? '0',
              'field_num': field.fieldNum ?? '0',
            };
          }
        }
        if (coinPacks.isNotEmpty) {
          await prefs.setString('coin_packs', jsonEncode(coinPacks));
          debugPrint('Saved Coin Packs JSON: ${jsonEncode(coinPacks)}');
          debugPrint('Background API: Saved ${coinPacks.length} coin packs');
        } else {
          debugPrint('No coin packs found in API response');
        }
        debugPrint('═══════════════════════════════════════════════════════════════════════');
      } else {
        debugPrint('Wallet Credits API Response: No subFields found in API response');
      }
    } catch (e) {
      debugPrint('Background API: Error processing subscription data: $e');
    }
  }

  /// Get platform-specific ad IDs
  Future<Map<String, String>> _getPlatformAdIds(GetAudioModel value) async {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    String getAdId(String androidId, String iosId) =>
        isAndroid ? androidId : (isIOS ? iosId : '');

    return {
      'bannerAdUnitId': getAdId(value.data?.adsGoogleBannerIdAndroid ?? "",
          value.data?.adsGoogleBannerIdIos ?? ""),
      'bannerId2': getAdId(value.data?.adsGoogleBannerId_2Android ?? "",
          value.data?.adsGoogleBannerId_2Ios ?? ""),
      'bannerId3': getAdId(value.data?.adsGoogleBannerId_3Android ?? "",
          value.data?.adsGoogleBannerId_3Ios ?? ""),
      'interstitialAdUnitId': getAdId(
          value.data?.adsGoogleInterstitialIdAndroid ?? "",
          value.data?.adsGoogleInterstitialIdIos ?? ""),
      'rewardedAdUnitId': getAdId(value.data?.adsGoogleRewardIdAndroid ?? "",
          value.data?.adsGoogleRewardIdIos ?? ""),
      'appOpenAdUnitId': getAdId(value.data?.adsGoogleOpenAppIdAndroid ?? "",
          value.data?.adsGoogleOpenAppIdIos ?? ""),
      'nativeAdId': getAdId(value.data?.adsGoogleNativeIdAndroid ?? "",
          value.data?.adsGoogleNativeIdIos ?? ""),
      'rewaredInterstitialAd': getAdId(
          value.data?.adsGoogleRewardInterstitialIdAndroid ?? "",
          value.data?.adsGoogleRewardInterstitialIdIos ?? ""),
      'levelPlayAppKey': getAdId(value.data?.adsNetwork_1Field_1Android ?? "",
          value.data?.adsNetwork_1Field_1Ios ?? ""),
      'levelPlayBannerId': getAdId(value.data?.adsNetwork_1Field_2Android ?? "",
          value.data?.adsNetwork_1Field_2Ios ?? ""),
      'levelPlayInterstitialId': getAdId(
          value.data?.adsNetwork_1Field_3Android ?? "",
          value.data?.adsNetwork_1Field_3Ios ?? ""),
      'levelPlayNativeId': getAdId(value.data?.adsNetwork_1Field_4Android ?? "",
          value.data?.adsNetwork_1Field_4Ios ?? ""),
      'levelPlayRewardedId': getAdId(
          value.data?.adsNetwork_1Field_5Android ?? "",
          value.data?.adsNetwork_1Field_5Ios ?? ""),
    };
  }

  /// Save ad preferences
  Future<void> _saveAdPreferences(Map<String, String> adIds, GetAudioModel value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bannerAdUnitId', adIds['bannerAdUnitId'] ?? '');
      await prefs.setString('openAppId', adIds['appOpenAdUnitId'] ?? '');
      await prefs.setString('rewardedInterstitialAd', adIds['rewaredInterstitialAd'] ?? '');
      await prefs.setString('rewardedAd', adIds['rewardedAdUnitId'] ?? '');
      await prefs.setString('nativeAdId', adIds['nativeAdId'] ?? '');
      await prefs.setString('googleBannerId', adIds['bannerId3'] ?? '');
      await prefs.setString('googleInterstitialAd', adIds['interstitialAdUnitId'] ?? '');
      await prefs.setString('bookadscatid', value.data?.bookAdsCatId ?? '');
      await prefs.setString('surveyappid', value.data?.surveyAppId ?? '');
      await prefs.setString('surveyappenable', value.data?.surveyEnable ?? '');
      await prefs.setString('showinterstitialrow', value.data?.showInterstitialRow ?? '');
      Future<void> cacheIfPresent(String key, String? value) async {
        final v = (value ?? '').trim();
        if (v.isEmpty) return;
        await prefs.setString(key, v);
      }
      await cacheIfPresent('levelPlayAppKey', adIds['levelPlayAppKey']);
      await cacheIfPresent('levelPlayBannerId', adIds['levelPlayBannerId']);
      await cacheIfPresent(
          'levelPlayInterstitialId', adIds['levelPlayInterstitialId']);
      await cacheIfPresent('levelPlayNativeId', adIds['levelPlayNativeId']);
      await cacheIfPresent('levelPlayRewardedId', adIds['levelPlayRewardedId']);
      unawaited(LevelPlayAds.instance.ensureInitialized());
    } catch (e) {
      debugPrint('Background API: Error saving ad preferences: $e');
    }
  }

  /// Reset the service (useful for testing or re-initialization)
  void reset() {
    _isLoading = false;
    _isCompleted = false;
    _loadingCompleter = null;
  }
}

