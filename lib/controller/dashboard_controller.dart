import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:biblebookapp/ads/levelplay_ads.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/services/background_api_service.dart';
import 'package:biblebookapp/utils/book_apps_helper.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:screenshot/screenshot.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/get_audio_model.dart';
import '../Model/verseBookContentModel.dart';
import '../view/constants/share_preferences.dart';
import 'api_service.dart';
import 'dpProvider.dart';

class DashBoardController extends GetxController with WidgetsBindingObserver {
  final webViewLoading = false.obs;
  final webViewKey = GlobalKey().obs;

  /// Internet Connectivity checker
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  var connectionStatus = <ConnectivityResult>[].obs; // Updated to List
  // final connectionStatus = ConnectivityResult.none.obs;
  // final _connectivity = Connectivity().obs;
  // late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  get developer => null;

  get isBookmarkColorSet => null;
  get isImageCreated => null;

  DateTime? _pausedTime;
  bool wasInBackground = false;
  bool cameFromAd = false;

  void showAppOpenAd() {
    debugPrint("✅ Showing App Open Ad");
    // Call your AppOpenAdManager().showAd() or relevant ad logic here
  }

  void markCameFromAd() {
    cameFromAd = true;
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      //result = await _connectivity.value.checkConnectivity();
      result = await _connectivity.checkConnectivity();

      return _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    connectionStatus.value = result;

    debugPrint("notify 1${result.first} ");
// Check if the device has any active connection
    if (result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet)) {
      loadApi();
    } else {
      // Constants.showToast("No internet connection");
    }
  }

  ///Complete

  final bgImagesList = <String>[
    "assets/content_bg_image1.png",
    "assets/content_bg_image2.png",
    "assets/content_bg_image3.png",
    "assets/content_bg_image4.png",
    "assets/content_bg_image5.png",
    "assets/content_bg_image6.png",
    "assets/content_bg_image7.png",
    "assets/content_bg_image8.png",
    "assets/content_bg_image9.png",
    "assets/content_bg_image10.png",
  ].obs;
  final selectedBgImage = 0.obs;
  final selectedBookChapterCount = "".obs;
  final selectedChapter = "".obs;
  final selectedBook = "".obs;
  final selectedBookNum = "".obs;
  final isFetchContent = true.obs;
  final isReadLoad = false.obs;
  final bookReadPer = "".obs;
  final selectedBookId = "".obs;
  final selectedIndex = 0.obs;
  final printText = "".obs;
  final textSelectedColor = Colors.black26.obs;
  final selectedVersesContent = <VerseBookContentModel>[].obs;
  final selectedBookContent = <VerseBookContentModel>[].obs;
  final isAdsCompletlyDisabled = false.obs;
//highlight color
  //
  final selectChapterChange = 0.obs;
  final bookAdsStatus = 0.obs;
  final bookAdsAppId = 0.obs;

  final audioLoad = false.obs;
  final audioData = GetAudioModel().obs;
  final loadTextToSpeech = false.obs;
  final adsDuration = ''.obs;
  DateTime? lastIntertitialAdPlayed;
  final rewardedAdUnitId = "".obs;
  String? sixMonthPlan;
  String? oneYearPlan;
  String? lifeTimePlan;
  String? sixMonthPlanValue;
  String? oneYearPlanValue;
  String? lifeTimePlanValue;
  //eshop
  String? sliverValue;
  String? goldValue;
  String? platinumValue;
  //
  String? offerEnabled;
  String? offerDays;
  String? offerCount;
  String? sharedSecret;
  bool? isSubscriptionEnabled;

  Future<void> loadApi() async {
    // Check if background API service is already loading or completed
    final backgroundService = BackgroundApiService();

    if (backgroundService.isCompleted) {
      // APIs already loaded in background and cached
      // Still need to load from cache to initialize controller's reactive variables
      debugPrint(
          'APIs already loaded in background, loading from cache to initialize controller');
      await _loadFromCache();
      return;
    }

    if (backgroundService.isLoading) {
      // APIs are still loading in background, wait for them
      debugPrint('APIs are loading in background, waiting for completion...');
      try {
        await backgroundService.waitForCompletion();
        debugPrint('Background API loading completed, loading from cache');
        // Load from cache to initialize controller's reactive variables
        await _loadFromCache();
        return;
      } catch (e) {
        debugPrint('Error waiting for background APIs: $e');
        // Fall through to load APIs directly if background loading failed
      }
    }

    // If background service hasn't started or failed, load APIs directly
    try {
      final value = await getMusicDetails();
      if (value != null) {
        // Cache the successful API response
        await _cacheApiResponse(value);
        await _processApiResponse(value);
      } else {
        // API returned null, try to load from cache
        await _loadFromCache();
      }
      return;
    } catch (e) {
      // API failed, try to load from cache
      debugPrint('API failed, loading from cache: $e');
      await _loadFromCache();
      return;
    }
  }

  Future<void> _cacheApiResponse(GetAudioModel value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value.data != null) {
        try {
          final jsonString = jsonEncode(value.toJson());
          await prefs.setString('cached_api_response', jsonString);
          debugPrint('API response cached successfully');
        } catch (jsonError) {
          debugPrint('Error encoding to JSON: $jsonError');
        }
      }
    } catch (e) {
      debugPrint('Error caching API response: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_api_response');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final jsonData = jsonDecode(cachedJson);
        final cachedValue = GetAudioModel.fromJson(jsonData);
        await _processApiResponse(cachedValue);
        debugPrint('Loaded data from cache successfully');
      } else {
        // No cache available, initialize with constants (first time loading)
        debugPrint('No cache available, initializing with constants');
        await _initializeWithConstants();
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
      // Initialize with constants when cache loading fails
      await _initializeWithConstants();
    }
  }

  /// Initialize with constants when API data is not available (first time loading)
  Future<void> _initializeWithConstants() async {
    try {
      // Create GetAudioModel with constants data for audio and text-to-speech
      final constantsModel = GetAudioModel();
      constantsModel.result = "1";

      // Create GetAudioModelData with constants
      final constantsData = GetAudioModelData();

      // Set subscription plan IDs from constants
      constantsData.subIdentifierSixMonth = BibleInfo.subIdentifierSixMonth;
      constantsData.subIdentifierOneyear = BibleInfo.subIdentifierOneYear;
      constantsData.subIdentifierLifetime = BibleInfo.subIdentifierLifetime;
      constantsData.isSubscriptionEnabled = BibleInfo.isSubscriptionEnabled;
      constantsData.adsDuration = BibleInfo.adsDuration;
      constantsData.offerEnabled = BibleInfo.offerEnabled;
      constantsData.offerDays = BibleInfo.offerDays;
      constantsData.offerCount = BibleInfo.offerCount;

      // Create BibleAudioInfo with constants for audio and text-to-speech
      final bibleAudioInfo = GetAudioModelDataBibleAudioInfo();
      bibleAudioInfo.isShowMp3Audio = BibleInfo.isShowMp3Audio;
      bibleAudioInfo.audioBasepath = BibleInfo.audioBasePath;
      bibleAudioInfo.audioBasepathType = BibleInfo.audioBasePathType;
      bibleAudioInfo.isTextToSpeechAvailableIos =
          BibleInfo.isTextToSpeechAvailableIos;
      bibleAudioInfo.textToSpeechLanguageCodeIos =
          BibleInfo.textToSpeechLanguageCodeIos;
      bibleAudioInfo.textToSpeechIdentifierIos =
          BibleInfo.textToSpeechIdentifierIos;
      bibleAudioInfo.isTextToSpeechAvailableAndroid =
          BibleInfo.isTextToSpeechAvailableAndroid;
      bibleAudioInfo.textToSpeechLanguageCodeAndroid =
          BibleInfo.textToSpeechLanguageCodeAndroid;

      // Set audio info to data
      constantsData.bibleAudioInfo = bibleAudioInfo;
      constantsData.appAudioBasepath = BibleInfo.audioBasePath;
      constantsData.appAudioBasepathType = BibleInfo.audioBasePathType;

      // Set wallpaper and quotes IDs from constants
      constantsData.wallpaperCatId = BibleInfo.wallpaperCatId;
      constantsData.imageAppId = BibleInfo.imageAppId;

      // Set the data to model
      constantsModel.data = constantsData;

      // Process the constants model
      await _processApiResponse(constantsModel);

      // Save constants to SharedPreferences for IAP plan IDs
      await Future.wait([
        SharPreferences.setString('sixMonthPlan', BibleInfo.sixMonthPlanid),
        SharPreferences.setString('oneYearPlan', BibleInfo.oneYearPlanid),
        SharPreferences.setString('lifeTimePlan', BibleInfo.lifeTimePlanid),
      ]);

      debugPrint(
          'Initialized with constants successfully - Audio and Text-to-Speech data from constants');
    } catch (e) {
      debugPrint('Error initializing with constants: $e');
      await _handleApiError(e);
    }
  }

  Future<void> _processApiResponse(GetAudioModel value) async {
    bool isAdsDisabled = false;
    // Process ads configuration
    final prefs = await SharedPreferences.getInstance();
    if (value.data != null && value.data?.adsType != null) {
      isAdsDisabled = value.data!.adsType == "0";
      isAdsCompletlyDisabled.value = isAdsDisabled;
    } else {
      // Use constants as fallback when API data is not available
      isAdsDisabled = !BibleInfo.enableAds;
      isAdsCompletlyDisabled.value = isAdsDisabled;
    }
    await Future.wait([
      _saveBasicPreferences(value),
      _processSubscriptionData(value),
    ]);
    // Save basic preferences
    //   await _saveBasicPreferences(value);

    // Process subscription data
    //  await _processSubscriptionData(value);

    // Process audio data
    _processAudioData(value);
    // Only call getMoreApps and getBookCategories if we have internet connection
    // This prevents showing "No internet connection" toast when offline
    if (connectionStatus.value.isNotEmpty &&
        (connectionStatus.value.contains(ConnectivityResult.wifi) ||
            connectionStatus.value.contains(ConnectivityResult.mobile) ||
            connectionStatus.value.contains(ConnectivityResult.ethernet))) {
      try {
        final appdata = await getMoreApps();
        //await StorageHelper.saveBooksAndApps(apps: appdata);

        final bookdata = await getBookCategories(bookAdsAppId.value);
        await StorageHelper.saveBooksAndApps(apps: appdata, books: bookdata);
      } catch (e) {
        // Silently handle errors when offline - don't show toast
        debugPrint('Error loading apps/books data (offline): $e');
      }
    } else {
      // Offline - try to load from existing cache if available
      try {
        final prefs = await SharedPreferences.getInstance();
        // Try to get cached apps/books data if available
        // This prevents errors but doesn't show toast
      } catch (e) {
        debugPrint('No cached apps/books data available: $e');
      }
    }
    // Get platform-specific ad IDs
    final adIds = await _getPlatformAdIds(value);

    // Save all ad-related preferences
    await _saveAdPreferences(adIds, value);

    // Initialize ads if not disabled
    if (!isAdsDisabled) {
      await _initializeAds(adIds);
    }

    // Update ads status in preferences
    await SharPreferences.setBoolean(
        SharPreferences.isAdsEnabledApi, !isAdsDisabled);

    await prefs.setBool('ad_enabled', !isAdsDisabled);
  }

  Future<void> _saveBasicPreferences(GetAudioModel value) async {
    // Log actual IDs from API response for Geneva Bible app
    final apiWallpaperId = value.data?.wallpaperCatId ?? '';
    final apiImageId = value.data?.imageAppId ?? '';

    // Always print to see what we're getting from API
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 API Response IDs for Geneva Bible App:');
    debugPrint('   wallpaper_cat_id from API: "$apiWallpaperId"');
    debugPrint('   image_app_id from API: "$apiImageId"');
    debugPrint('   Current constants:');
    debugPrint('   - BibleInfo.wallpaperCatId: "${BibleInfo.wallpaperCatId}"');
    debugPrint('   - BibleInfo.imageAppId: "${BibleInfo.imageAppId}"');
    if (apiWallpaperId.isEmpty && apiImageId.isEmpty) {
      debugPrint('   ⚠️ WARNING: Both IDs are empty in API response!');
    } else if (apiWallpaperId.isNotEmpty || apiImageId.isNotEmpty) {
      debugPrint(
          '   ✅ IDs received from API - will be saved to SharedPreferences');
      debugPrint('   ⚠️ If these differ from constants, update constants.dart');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    await Future.wait([
      SharPreferences.setString(
          SharPreferences.wallpaperCatID,
          value.data?.wallpaperCatId?.isNotEmpty == true
              ? value.data!.wallpaperCatId!
              : BibleInfo.wallpaperCatId),
      SharPreferences.setString(
          SharPreferences.imageAppID,
          value.data?.imageAppId?.isNotEmpty == true
              ? value.data!.imageAppId!
              : BibleInfo.imageAppId),
      SharPreferences.setString(
          SharPreferences.adPauseDiff, value.data?.adsDuration ?? ''),
    ]);
  }

  Future<void> _processSubscriptionData(GetAudioModel value) async {
    bookAdsStatus.value = int.tryParse(value.data?.bookAdsStatus ?? '') ?? 0;
    bookAdsAppId.value = int.tryParse(value.data?.bookAdsAppId ?? '') ?? 0;

    isSubscriptionEnabled = value.data?.isSubscriptionEnabled == '1';
    sharedSecret = value.data?.subSharedsecret ?? "";

    // Use constants as fallback when API data is not available
    sixMonthPlan = AppApiConstant.resolveSubscriptionProductId(
      value.data?.subIdentifierSixMonth,
      BibleInfo.sixMonthPlanid,
    );
    oneYearPlan = AppApiConstant.resolveSubscriptionProductId(
      value.data?.subIdentifierOneyear,
      BibleInfo.oneYearPlanid,
    );
    lifeTimePlan = AppApiConstant.resolveSubscriptionProductId(
      value.data?.subIdentifierLifetime,
      BibleInfo.lifeTimePlanid,
    );

    final iapdatacheck = value.data?.subIdentifierSixMonth;

    sixMonthPlanValue = value.data?.subIdentifierSixMonthValue ?? "";
    oneYearPlanValue = value.data?.subIdentifierOneyearValue ?? "";
    lifeTimePlanValue = value.data?.subIdentifierLifetimeValue ?? "";

    sliverValue = value.data?.subFields?[0]?.identifier ?? '';
    goldValue = value.data?.subFields?[1]?.identifier ?? '';
    platinumValue = value.data?.subFields?[2]?.identifier ?? '';

    // Extract exit offer ID from subFields
    String exitOfferId = BibleInfo.exitOfferPlanid; // Default to constant
    if (value.data?.subFields != null) {
      for (var field in value.data!.subFields!) {
        if (field?.identifier != null &&
            field!.identifier!.contains('exitoffer')) {
          exitOfferId = field.identifier!;
          break;
        }
      }
    }

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

    offerEnabled = value.data?.offerEnabled ?? "";
    offerDays = value.data?.offerDays.toString() ?? "";
    offerCount = value.data?.offerCount.toString() ?? "70";
    debugPrint(" app offer count - $oneYearPlanValue");
    await Future.wait([
      SharPreferences.setString('sixMonthPlan', sixMonthPlan.toString() ?? ""),
      SharPreferences.setString('oneYearPlan', oneYearPlan.toString() ?? ""),
      SharPreferences.setString('lifeTimePlan', lifeTimePlan.toString() ?? ""),
      SharPreferences.setString('exitOfferPlan', exitOfferId),
      SharPreferences.setString('coinPack1Id', coinPack1Id),
      SharPreferences.setString('coinPack2Id', coinPack2Id),
      SharPreferences.setString('coinPack3Id', coinPack3Id),
      SharPreferences.setString(
          'sixMonthPlanvalue', sixMonthPlanValue.toString() ?? ""),
      SharPreferences.setString(
          'oneYearPlanvalue', oneYearPlanValue.toString() ?? ""),
      SharPreferences.setString(
          'lifeTimePlanvalue', lifeTimePlanValue.toString() ?? ""),
      SharPreferences.setString('Iapdatacheck', iapdatacheck.toString() ?? ""),
//e-shop
      SharPreferences.setString('sliverID', sliverValue.toString() ?? ""),
      SharPreferences.setString('goldID', goldValue.toString() ?? ""),
      SharPreferences.setString('platinumID', platinumValue.toString() ?? ""),
//
      SharPreferences.setBoolean(
          'isSubscriptionEnabled', isSubscriptionEnabled ?? true),
      SharPreferences.setString(
          SharPreferences.offerenabled, offerEnabled ?? ''),
      SharPreferences.setInt(SharPreferences.offercount,
          int.tryParse(value.data?.offerCount.toString() ?? '') ?? 5),
      // SharPreferences.setInt('appCount',
      //     int.tryParse(value.data?.offerCount.toString() ?? '') ?? 15),
    ]);
  }

  void _processAudioData(GetAudioModel value) {
    audioLoad.value = false;
    audioData.value = GetAudioModel(); // Reset
    audioData.value = value;
    adsDuration.value = value.data?.adsDuration ?? '';
    audioLoad.value = true;
  }

  Future<Map<String, String>> _getPlatformAdIds(GetAudioModel value) async {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    String getAdId(String androidId, String iosId) =>
        isAndroid ? androidId : (isIOS ? iosId : '');

    // Use constants as fallback when API data is not available
    return {
      'bannerAdUnitId': getAdId(
          value.data?.adsGoogleBannerIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleBannerIdAndroid!
              : BibleInfo.adsGoogleBannerIdAndroid,
          value.data?.adsGoogleBannerIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleBannerIdIos!
              : BibleInfo.adsGoogleBannerIdIos),
      'bannerId2': getAdId(
          value.data?.adsGoogleBannerId_2Android?.isNotEmpty == true
              ? value.data!.adsGoogleBannerId_2Android!
              : BibleInfo.adsGoogleBannerId_2Android,
          value.data?.adsGoogleBannerId_2Ios?.isNotEmpty == true
              ? value.data!.adsGoogleBannerId_2Ios!
              : BibleInfo.adsGoogleBannerId_2Ios),
      'bannerId3': getAdId(
          value.data?.adsGoogleBannerId_3Android?.isNotEmpty == true
              ? value.data!.adsGoogleBannerId_3Android!
              : BibleInfo.adsGoogleBannerId_3Android,
          value.data?.adsGoogleBannerId_3Ios?.isNotEmpty == true
              ? value.data!.adsGoogleBannerId_3Ios!
              : BibleInfo.adsGoogleBannerId_3Ios),
      'interstitialAdUnitId': getAdId(
          value.data?.adsGoogleInterstitialIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleInterstitialIdAndroid!
              : BibleInfo.adsGoogleInterstitialIdAndroid,
          value.data?.adsGoogleInterstitialIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleInterstitialIdIos!
              : BibleInfo.adsGoogleInterstitialIdIos),
      'rewardedAdUnitId': getAdId(
          value.data?.adsGoogleRewardIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleRewardIdAndroid!
              : BibleInfo.adsGoogleRewardIdAndroid,
          value.data?.adsGoogleRewardIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleRewardIdIos!
              : BibleInfo.adsGoogleRewardIdIos),
      'appOpenAdUnitId': getAdId(
          value.data?.adsGoogleOpenAppIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleOpenAppIdAndroid!
              : BibleInfo.adsGoogleOpenAppIdAndroid,
          value.data?.adsGoogleOpenAppIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleOpenAppIdIos!
              : BibleInfo.adsGoogleOpenAppIdIos),
      'nativeAdId': getAdId(
          value.data?.adsGoogleNativeIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleNativeIdAndroid!
              : BibleInfo.adsGoogleNativeIdAndroid,
          value.data?.adsGoogleNativeIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleNativeIdIos!
              : BibleInfo.adsGoogleNativeIdIos),
      'rewaredInterstitialAd': getAdId(
          value.data?.adsGoogleRewardInterstitialIdAndroid?.isNotEmpty == true
              ? value.data!.adsGoogleRewardInterstitialIdAndroid!
              : BibleInfo.adsGoogleRewardInterstitialIdAndroid,
          value.data?.adsGoogleRewardInterstitialIdIos?.isNotEmpty == true
              ? value.data!.adsGoogleRewardInterstitialIdIos!
              : BibleInfo.adsGoogleRewardInterstitialIdIos),
      'levelPlayAppKey': getAdId(
          value.data?.adsNetwork_1Field_1Android ?? '',
          value.data?.adsNetwork_1Field_1Ios ?? ''),
      'levelPlayBannerId': getAdId(
          value.data?.adsNetwork_1Field_2Android ?? '',
          value.data?.adsNetwork_1Field_2Ios ?? ''),
      'levelPlayInterstitialId': getAdId(
          value.data?.adsNetwork_1Field_3Android ?? '',
          value.data?.adsNetwork_1Field_3Ios ?? ''),
      'levelPlayNativeId': getAdId(
          value.data?.adsNetwork_1Field_4Android ?? '',
          value.data?.adsNetwork_1Field_4Ios ?? ''),
      'levelPlayRewardedId': getAdId(
          value.data?.adsNetwork_1Field_5Android ?? '',
          value.data?.adsNetwork_1Field_5Ios ?? ''),
    };
  }

  Future<void> _saveAdPreferences(
      Map<String, String> adIds, GetAudioModel value) async {
    await Future.wait([
      SharPreferences.setString(
          'bannerAdUnitId', adIds['bannerAdUnitId'] ?? ''),
      SharPreferences.setString(
          SharPreferences.openAppId, adIds['appOpenAdUnitId'] ?? ''),
      SharPreferences.setString(SharPreferences.rewardedInterstitialAd,
          adIds['rewaredInterstitialAd'] ?? ''),
      SharPreferences.setString(
          SharPreferences.rewardedAd, adIds['rewardedAdUnitId'] ?? ''),
      SharPreferences.setString(
          SharPreferences.nativeAdId, adIds['nativeAdId'] ?? ''),
      SharPreferences.setString(
          SharPreferences.googleBannerId, adIds['bannerId3'] ?? ''),
      SharPreferences.setString(SharPreferences.googleInterstitialAd,
          adIds['interstitialAdUnitId'] ?? ''),
      SharPreferences.setString(
          SharPreferences.bookadscatid, value.data?.bookAdsCatId ?? ''),
      SharPreferences.setString(
          SharPreferences.surveyappid, value.data?.surveyAppId ?? ''),
      SharPreferences.setString(
          SharPreferences.surveyappenable, value.data?.surveyEnable ?? ''),
      SharPreferences.setString(SharPreferences.showinterstitialrow,
          value.data?.showInterstitialRow ?? ''),
    ]);

    Future<void> cacheIfPresent(String key, String? value) async {
      final v = (value ?? '').trim();
      if (v.isEmpty) return;
      await SharPreferences.setString(key, v);
    }

    await cacheIfPresent(
        SharPreferences.levelPlayAppKey, adIds['levelPlayAppKey']);
    await cacheIfPresent(
        SharPreferences.levelPlayBannerId, adIds['levelPlayBannerId']);
    await cacheIfPresent(SharPreferences.levelPlayInterstitialId,
        adIds['levelPlayInterstitialId']);
    await cacheIfPresent(
        SharPreferences.levelPlayNativeId, adIds['levelPlayNativeId']);
    await cacheIfPresent(
        SharPreferences.levelPlayRewardedId, adIds['levelPlayRewardedId']);

    unawaited(LevelPlayAds.instance.ensureInitialized());

    //  debugPrint("Native ads id is ${adIds['nativeAdId']}");
    debugPrint(
        "Rewarded interstitial ad id is ${adIds['rewaredInterstitialAd']}");

    debugPrint("Rewarded ad id is ${adIds['rewardedAdUnitId']}");
  }

  Future<void> _initializeAds(Map<String, String> adIds) async {
    // Initialize all ads in parallel
    // await Future.wait([
    await initBanner(adUnitId: adIds['bannerAdUnitId'] ?? '');
    await initNewBannerAd(adUnitId: adIds['bannerAdUnitId'] ?? '');
    await initReadMeBelowAd(adUnitId: adIds['bannerId2'] ?? '');
    await initPopUpAd(adUnitId: adIds['bannerId3'] ?? '');
    await initImageBannerAd(adUnitId: adIds['bannerId3'] ?? '');
    unawaited(LevelPlayAds.instance.ensureInitialized());
    // await initInterstitialAd(adUnitId: adIds['interstitialAdUnitId'] ?? '');
    // ]);

    // Load rewarded ad separately as it might need special handling
    // loadRewardedAd(adUnitId: adIds['rewardedAdUnitId'] ?? '');
  }

  Future<void> _handleApiError(dynamic e) async {
    final cachedGoogle =
        await SharPreferences.getString(SharPreferences.googleInterstitialAd);
    final cachedLp =
        await SharPreferences.getString(SharPreferences.levelPlayAppKey);
    if ((cachedGoogle != null && cachedGoogle.isNotEmpty) ||
        (cachedLp != null && cachedLp.isNotEmpty)) {
      debugPrint('loadApi error — using last cached ad IDs: $e');
      unawaited(LevelPlayAds.instance.ensureInitialized());
      return;
    }
    adFree.value = true;
    isInterstitialAdLoad.value = false;
    isBannerAdLoaded.value = false;
    await SharPreferences.setBoolean(SharPreferences.isAdsEnabledApi, false);
    DebugConsole.log(" data api error - $e ");
    // Consider adding error logging here
    debugPrint('Error in loadApi: $e');
    return;
  }

  // loadApi() async {
  //   try {
  //     // adFree.value = false;
  //     // isInterstitialAdLoad.value = true;
  //     // isBannerAdLoaded.value = true;
  //     final value = await getMusicDetails();
  //     isAdsCompletlyDisabled.value = value.data?.adsType == "0";
  //     await SharPreferences.setString(
  //         SharPreferences.wallpaperCatID, value.data?.wallpaperCatId ?? '');
  //     await SharPreferences.setString(
  //         SharPreferences.imageAppID, value.data?.imageAppId ?? '');
  //     String bannerAdUnitId = "";
  //     String interstitialAdUnitId = "";

  //     String appOpenAdUnitId = '';
  //     String bannerId2 = '';
  //     String bannerId3 = '';
  //     bookAdsStatus.value = int.tryParse(value.data?.bookAdsStatus ?? '') ?? 0;
  //     bookAdsAppId.value = int.tryParse(value.data?.bookAdsAppId ?? '') ?? 0;
  //     isSubscriptionEnabled = value.data?.isSubscriptionEnabled == '1';
  //     sharedSecret = value.data?.subSharedsecret;
  //     sixMonthPlan = value.data?.subIdentifierSixMonth;
  //     oneYearPlan = value.data?.subIdentifierOneyear;
  //     lifeTimePlan = value.data?.subIdentifierLifetime;
  //     sixMonthPlanValue = value.data?.subIdentifierSixMonthValue;
  //     oneYearPlanValue = value.data?.subIdentifierOneyearValue;
  //     lifeTimePlanValue = value.data?.subIdentifierLifetimeValue;
  //     offerEnabled = value.data?.offerEnabled;
  //     offerDays = value.data?.offerDays.toString();
  //     offerCount = value.data?.offerCount.toString();

  //     audioLoad.value = false;
  //     audioData.value = GetAudioModel();
  //     audioData.value = value;
  //     audioLoad.value = true;
  //     adsDuration.value = value.data?.adsDuration ?? '';

  //     if (Platform.isAndroid) {
  //       bannerAdUnitId = value.data!.adsGoogleBannerIdAndroid ?? "";
  //     } else if (Platform.isIOS) {
  //       bannerAdUnitId = value.data!.adsGoogleBannerIdIos ?? "";
  //     }
  //     await SharPreferences.setString('sixMonthPlan', sixMonthPlan.toString());
  //     await SharPreferences.setString('oneYearPlan', oneYearPlan.toString());
  //     await SharPreferences.setString('lifeTimePlan', lifeTimePlan.toString());
  //     await SharPreferences.setString('bannerAdUnitId', bannerAdUnitId);
  //     await SharPreferences.setBoolean(
  //         'isSubscriptionEnabled', isSubscriptionEnabled!);
  //     debugPrint(
  //         "isSubscriptionEnabled is enable $isSubscriptionEnabled data ${value.data?.isSubscriptionEnabled}");
  //     appOpenAdUnitId = Platform.isIOS
  //         ? (value.data?.adsGoogleOpenAppIdIos ?? '')
  //         : (value.data?.adsGoogleOpenAppIdAndroid ?? '');
  //     if (Platform.isAndroid) {
  //       bannerId2 = value.data!.adsGoogleBannerId_2Android ?? "";
  //     } else if (Platform.isIOS) {
  //       bannerId2 = value.data!.adsGoogleBannerId_2Ios ?? "";
  //     }

  //     if (Platform.isAndroid) {
  //       bannerId3 = value.data!.adsGoogleBannerId_3Android ?? "";
  //     } else if (Platform.isIOS) {
  //       bannerId3 = value.data!.adsGoogleBannerId_3Ios ?? "";
  //     }
  //     if (Platform.isAndroid) {
  //       interstitialAdUnitId = value.data!.adsGoogleInterstitialIdAndroid ?? "";
  //     } else if (Platform.isIOS) {
  //       interstitialAdUnitId = value.data!.adsGoogleInterstitialIdIos ?? "";
  //     }

  //     if (Platform.isAndroid) {
  //       rewardedAdUnitId.value = value.data!.adsGoogleRewardIdAndroid ?? "";
  //     } else if (Platform.isIOS) {
  //       rewardedAdUnitId.value = value.data!.adsGoogleRewardIdIos ?? "";
  //     }
  //     if (Platform.isAndroid) {
  //       appOpenAdUnitId = value.data!.adsGoogleOpenAppIdAndroid ?? "";
  //     } else if (Platform.isIOS) {
  //       appOpenAdUnitId = value.data!.adsGoogleOpenAppIdIos ?? "";
  //     }

  //     String nativeAdId = Platform.isIOS
  //         ? (value.data?.adsGoogleNativeIdIos ?? '')
  //         : (value.data?.adsGoogleNativeIdAndroid ?? '');

  //     String rewaredInterstitialAd = Platform.isIOS
  //         ? (value.data?.adsGoogleRewardInterstitialIdIos ?? '')
  //         : (value.data?.adsGoogleRewardInterstitialIdAndroid ?? '');

  //     SharPreferences.setString(
  //         SharPreferences.adPauseDiff, value.data?.adsDuration ?? '');
  //     // ad count
  //     SharPreferences.setString(
  //         SharPreferences.offerenabled, value.data?.offerEnabled ?? '');
  //     SharPreferences.setInt(
  //         SharPreferences.offercount, value.data?.offerCount ?? 200);

  //     SharPreferences.setString(SharPreferences.openAppId, appOpenAdUnitId);
  //     SharPreferences.setString(
  //         SharPreferences.rewardedInterstitialAd, rewaredInterstitialAd);
  //     SharPreferences.setString(
  //         SharPreferences.rewardedAd, rewardedAdUnitId.value);
  //     SharPreferences.setString(SharPreferences.nativeAdId, nativeAdId);
  //     SharPreferences.setString(SharPreferences.googleBannerId, bannerId3);
  //     SharPreferences.setString(
  //         SharPreferences.googleInterstitialAd, interstitialAdUnitId);

  //     SharPreferences.setString(
  //         SharPreferences.bookadscatid, value.data?.bookAdsCatId ?? '');

  //     SharPreferences.setString(
  //         SharPreferences.surveyappid, value.data?.surveyAppId ?? '');

  //     SharPreferences.setString(
  //         SharPreferences.surveyappenable, value.data?.surveyEnable ?? '');

  //     SharPreferences.setString(SharPreferences.showinterstitialrow,
  //         value.data?.showInterstitialRow ?? '');

  //     debugPrint(" native ads id is $nativeAdId ");

  //     debugPrint(" rewaredInterstitialAd ads id is $rewaredInterstitialAd ");
  //     // initAppOpenAd(appOpenAdUnitId);

  //     // Load Banner Ad with fetched ad unit ID
  //     initBanner(adUnitId: bannerAdUnitId);

  //     ///Load Banned Ad for below mark as read
  //     initNewBannerAd(adUnitId: bannerAdUnitId);

  //     /// Banner Below Read Me
  //     initReadMeBelowAd(adUnitId: bannerId2);

  //     /// Load Banner Ad for Popup
  //     initPopUpAd(adUnitId: bannerId3);

  //     //// Load ImageBanner Ad
  //     initImageBannerAd(adUnitId: bannerId3);

  //     // Load Interstitial Ad with fetched ad unit ID
  //     initInterstitialAd(adUnitId: interstitialAdUnitId);

  //     // Load Rewarded Ad with fetched ad unit ID
  //     loadRewardedAd(adUnitId: rewardedAdUnitId.value);

  //     if (value.data?.adsType == "0") {
  //       adFree.value = true;
  //       isInterstitialAdLoad.value = false;
  //       isBannerAdLoaded.value = false;
  //       await SharPreferences.setBoolean(
  //           SharPreferences.isAdsEnabledApi, false);
  //     } else {
  //       await SharPreferences.setBoolean(SharPreferences.isAdsEnabledApi, true);
  //     }
  //   } catch (e) {
  //     adFree.value = true;
  //     isInterstitialAdLoad.value = false;
  //     isBannerAdLoaded.value = false;
  //     await SharPreferences.setBoolean(SharPreferences.isAdsEnabledApi, false);
  //   }
  // }

  final selectedBookNumForRead = "".obs;
  final selectedBookNameForRead = "".obs;
  final selectedChapterForRead = "".obs;
  final selectedVerseForRead = "".obs;

  final fontSize = Sizecf.scrnWidth! > 450 ? 25.0.obs : 15.0.obs;
  final fontSizeS = "".obs;
  final selectedFontFamily = "".obs;
  final selectedVerseView = 1.obs;

  final isVeryFirstTime = false.obs;
  final scrollHideShowIcon = true.obs;

  final scrollControllerForList = ScrollController().obs;
  final height = 100.0.obs;
  final readHighlight = true.obs;
  animateToIndex(int index) {
    scrollControllerForList.value.animateTo(
      index - 1 * height.value,
      duration: Duration(seconds: 2),
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  final autoScrollController = AutoScrollController().obs;
  final scrollDirection = Axis.vertical;

  Future scrollToIndex(int index) async {
    await autoScrollController.value
        .scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
  }

  /// Cache: book_num → whether verse.chapter_num is 0-based (ch.1 stored as 0).
  final Map<int, bool> _zeroBasedChapterByBook = {};

  Future<bool> _bookChapterNumsAreZeroBased(dynamic db, int bookNum) async {
    try {
      final rows = await db.rawQuery(
        'SELECT MIN(chapter_num) AS m FROM verse WHERE book_num = ?',
        [bookNum],
      );
      // Additive: only cache when MIN is real. Empty/null used to be stored as
      // zero-based and made Next Chapter reload the previous chapter.
      if (rows.isEmpty || rows.first['m'] == null) {
        return _zeroBasedChapterByBook[bookNum] ?? true;
      }
      final minCh = int.tryParse('${rows.first['m']}');
      if (minCh == null) {
        return _zeroBasedChapterByBook[bookNum] ?? true;
      }
      final zeroBased = minCh == 0;
      _zeroBasedChapterByBook[bookNum] = zeroBased;
      return zeroBased;
    } catch (_) {
      return _zeroBasedChapterByBook[bookNum] ?? true;
    }
  }

  bool _versesLookZeroBased(List<VerseBookContentModel> verses) {
    return verses.any((v) => (v.chapterNum ?? -1) == 0);
  }

  int _storedChapterNumForUi(int uiChapter, {required bool zeroBased}) {
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    return zeroBased ? safe - 1 : safe;
  }

  /// Tries exact DB chapter_num for the UI chapter (0- vs 1-based aware).
  /// Additive: prefer exact match so Next Chapter cannot reload previous chapter.
  Future<List<Map<String, dynamic>>> _rawQueryVerseChapter(
      dynamic db, int bookNum, int uiChapter) async {
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    final zeroBased = await _bookChapterNumsAreZeroBased(db, bookNum);
    final exact = _storedChapterNumForUi(safe, zeroBased: zeroBased);

    Future<List<Map<String, dynamic>>> queryCh(int ch) async {
      if (ch < 0) return [];
      final rows = await db.rawQuery(
          "SELECT * From verse WHERE book_num ='$bookNum' AND chapter_num = '$ch' ORDER BY verse_num");
      return List<Map<String, dynamic>>.from(rows);
    }

    final exactRows = await queryCh(exact);
    if (exactRows.isNotEmpty) return exactRows;

    // One alternate basis fallback (mixed/legacy DBs only).
    final alt = zeroBased ? safe : safe - 1;
    if (alt >= 0 && alt != exact) {
      final altRows = await queryCh(alt);
      if (altRows.isNotEmpty) {
        _zeroBasedChapterByBook[bookNum] = !zeroBased;
        return altRows;
      }
    }
    return [];
  }

  List<int> _bookNumLoadCandidates(int storedBookNum) {
    final ordered = <int>[
      storedBookNum,
      if (storedBookNum > 0) storedBookNum - 1,
      storedBookNum + 1,
      0,
      1,
    ];
    final seen = <int>{};
    return ordered.where((n) => n >= 0 && seen.add(n)).toList();
  }

  Future<bool> _bookNumMatchesSelectedTitle(dynamic db, int bookNum) async {
    var selectedTitle = selectedBook.value.trim();
    if (selectedTitle.isEmpty) {
      selectedTitle =
          (await SharPreferences.getString(SharPreferences.selectedBook) ?? '')
              .trim();
    }
    if (selectedTitle.isEmpty) return true;

    final rows = await db.rawQuery(
      'SELECT title FROM book WHERE book_num = ? LIMIT 1',
      [bookNum],
    );
    if (rows.isEmpty) return true;
    final dbTitle = rows[0]['title']?.toString().trim() ?? '';
    if (dbTitle.isEmpty) return true;
    if (dbTitle.toLowerCase() == selectedTitle.toLowerCase()) return true;
    // Additive: same book_num is trusted for in-book chapter changes
    // (titles may differ after Bible version switch: Matthew vs Mateus).
    final selectedNum = int.tryParse(selectedBookNum.value.trim());
    return selectedNum != null && selectedNum == bookNum;
  }

  Future<void> _applyBookMetadata(
      dynamic db, int bookNum, List<int> candidates) async {
    for (final candidate in candidates) {
      final result = await db.rawQuery(
        'SELECT * FROM book WHERE book_num = ?',
        [candidate],
      );
      if (result.isEmpty) continue;
      final item = result[0];
      if (item['chapter_count'] != null &&
          item['read_per'] != null &&
          item['id'] != null) {
        selectedBookNum.value = candidate.toString();
        await SharPreferences.setString(
            SharPreferences.selectedBookNum, candidate.toString());
        selectedBookChapterCount.value = item['chapter_count'].toString();
        bookReadPer.value = item['read_per'].toString();
        selectedBookId.value = item['id'].toString();
        return;
      }
    }
    debugPrint('testapp No book found with book_num = $bookNum');
  }

  /// Sync id / chapter_count / read_per for [selectedBookNum] before progress writes.
  Future<bool> syncSelectedBookProgressMetadata() async {
    final bookNum = int.tryParse(selectedBookNum.value.trim());
    if (bookNum == null) return false;
    final db = await DBHelper().db;
    if (db == null) return false;
    final rows = await db.rawQuery(
      'SELECT id, chapter_count, read_per FROM book WHERE book_num = ? LIMIT 1',
      [bookNum],
    );
    if (rows.isEmpty) return false;
    final row = rows.first;
    if (row['id'] != null) {
      selectedBookId.value = row['id'].toString();
    }
    if (row['chapter_count'] != null) {
      selectedBookChapterCount.value = row['chapter_count'].toString();
    }
    if (row['read_per'] != null) {
      bookReadPer.value = row['read_per'].toString();
    }
    return selectedBookId.value.trim().isNotEmpty;
  }

  /// Display-only book % (avoids float truncation showing 49/99).
  /// Does not change Mark-as-Read eligibility or ad/streak logic.
  static int displayBookReadPercent(String? readPer) {
    final raw = double.tryParse((readPer ?? '0').trim()) ?? 0.0;
    if (raw <= 0) return 0;
    if (raw >= 99.5) return 100;
    return raw.round().clamp(0, 100);
  }

  /// Same +1 / −1 chapter semantics; avoids float drift from repeated toStringAsFixed.
  String _storedReadPerFromChapterCount({
    required double currentPer,
    required double chapterCount,
    required int deltaChapters,
  }) {
    final total = chapterCount.round().clamp(1, 9999);
    final currentChapters =
        (currentPer * total / 100.0).round().clamp(0, total);
    final nextChapters =
        (currentChapters + deltaChapters).clamp(0, total);
    if (nextChapters <= 0) return '0';
    if (nextChapters >= total) return '100';
    return (nextChapters * 100.0 / total).toStringAsFixed(1);
  }

  /// Persist +1 chapter toward this book's read_per. Always writes the row for
  /// [selectedBookNum] (not a stale previous book id).
  Future<void> persistMarkChapterReadProgress() async {
    if (!await syncSelectedBookProgressMetadata()) return;
    final chapterCount =
        double.tryParse(selectedBookChapterCount.value.trim()) ?? 0;
    final bookId = int.tryParse(selectedBookId.value.trim());
    if (chapterCount <= 0 || bookId == null) return;

    final current = double.tryParse(bookReadPer.value.trim()) ?? 0.0;
    final stored = _storedReadPerFromChapterCount(
      currentPer: current,
      chapterCount: chapterCount,
      deltaChapters: 1,
    );
    await DBHelper().updateBookData(bookId, 'read_per', stored);
    bookReadPer.value = stored;
  }

  /// Persist −1 chapter from this book's read_per (unmark).
  Future<void> persistUnmarkChapterReadProgress() async {
    if (!await syncSelectedBookProgressMetadata()) return;
    final chapterCount =
        double.tryParse(selectedBookChapterCount.value.trim()) ?? 0;
    final bookId = int.tryParse(selectedBookId.value.trim());
    if (chapterCount <= 0 || bookId == null) return;

    final current = double.tryParse(bookReadPer.value.trim()) ?? 0.0;
    if (current <= 0) return;
    final stored = _storedReadPerFromChapterCount(
      currentPer: current,
      chapterCount: chapterCount,
      deltaChapters: -1,
    );
    await DBHelper().updateBookData(bookId, 'read_per', stored);
    bookReadPer.value = stored;
  }

  int _chapterLoadGeneration = 0;

  bool _bookIdMatches(String a, String b) {
    final ai = int.tryParse(a.trim());
    final bi = int.tryParse(b.trim());
    if (ai != null && bi != null) return ai == bi;
    return a.trim() == b.trim();
  }

  bool _displayedContentMatchesUiChapter(int uiChapter) {
    if (selectedBookContent.isEmpty) return false;
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    final sample = selectedVersesContent.isNotEmpty
        ? selectedVersesContent
        : selectedBookContent;
    final zeroBased = _versesLookZeroBased(sample);
    final stored = _storedChapterNumForUi(safe, zeroBased: zeroBased);
    // Require EVERY verse to belong to this chapter — `.any()` let a mixed
    // list (current + next chapter) skip reload after rapid Mark as Read.
    return selectedBookContent.every((v) => v.chapterNum?.toInt() == stored);
  }

  /// Keeps only verses for [uiChapter] when the in-memory list was poisoned
  /// with the next chapter (display/cache hygiene only).
  void _sanitizeSelectedBookContentToUiChapter(int uiChapter) {
    if (selectedBookContent.isEmpty) return;
    if (_displayedContentMatchesUiChapter(uiChapter)) return;
    final source = selectedVersesContent.isNotEmpty
        ? selectedVersesContent
        : selectedBookContent.toList();
    final cleaned = _filterChapterFromVerses(source, uiChapter);
    if (cleaned.isNotEmpty) {
      selectedBookContent.value = cleaned;
    }
  }

  /// Additive: skip/reload must also match book — chapter-only match keeps the
  /// previous book's verses after a book switch when both are on chapter N.
  bool _displayedContentMatchesSelectedBook() {
    if (selectedBookContent.isEmpty) return false;
    final selectedNum = int.tryParse(selectedBookNum.value.trim());
    if (selectedNum == null) return true;
    final contentBook = selectedBookContent.first.bookNum?.toInt();
    return contentBook == null || contentBook == selectedNum;
  }

  /// Public for HomeScreen entry checks (From: Chapter / Mark as Read).
  bool displayedContentMatchesSelection() {
    final uiChapter = int.tryParse(selectedChapter.value);
    if (uiChapter == null || uiChapter <= 0) return false;
    return _displayedContentMatchesSelectedBook() &&
        _displayedContentMatchesUiChapter(uiChapter);
  }

  bool _canSkipChapterReloadSync() {
    if (selectedBookContent.isEmpty || isFetchContent.value) return false;
    final uiChapter = int.tryParse(selectedChapter.value);
    if (uiChapter == null || uiChapter <= 0) return false;
    return _displayedContentMatchesSelectedBook() &&
        _displayedContentMatchesUiChapter(uiChapter);
  }

  bool _versesCacheMatchesBook(int bookNum) {
    if (selectedVersesContent.isEmpty) return false;
    final cachedBook = selectedVersesContent.first.bookNum;
    if (cachedBook == null) return false;
    // Exact book only — ±1 allowed wrong-book chapter reuse after switching books.
    return cachedBook == bookNum;
  }

  /// Additive: cancel in-flight chapter loads (e.g. didPopNext sync) and reload
  /// the current book + chapter from DB. Does not change selection algorithms.
  Future<void> forceReloadSelectedChapter() async {
    _chapterLoadGeneration++;
    // Drop possibly-poisoned 0/1-based chapter cache so Next Chapter re-detects.
    final bookNum = int.tryParse(selectedBookNum.value.trim());
    if (bookNum != null) {
      _zeroBasedChapterByBook.remove(bookNum);
    }
    selectedBookContent.clear();
    selectedVersesContent.clear();
    isFetchContent.value = true;
    loadTextToSpeech.value = true;
    await getSelectedChapterAndBook();
  }

  List<VerseBookContentModel> _filterChapterFromVerses(
    List<VerseBookContentModel> verses,
    int uiChapter,
  ) {
    if (verses.isEmpty) return [];
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    final zeroBased = _versesLookZeroBased(verses);
    final stored = _storedChapterNumForUi(safe, zeroBased: zeroBased);
    final list =
        verses.where((v) => v.chapterNum?.toInt() == stored).toList();
    if (list.isEmpty) return [];
    return filterContent(list.toSet().toList());
  }

  Future<bool> _loadBookChapterFromDb(
    dynamic db,
    int bookNum,
    int safeChapter, {
    required int loadId,
  }) async {
    if (!await _bookNumMatchesSelectedTitle(db, bookNum)) return false;

    final selectedBookResponse = await db.rawQuery(
        "SELECT * From verse WHERE book_num ='$bookNum'");
    if (selectedBookResponse.isEmpty) return false;

    final newVerses = selectedBookResponse
        .map<VerseBookContentModel>(
            (e) => VerseBookContentModel.fromJson(e))
        .toList();
    // Chapter-only changes should not reload the full book into memory;
    // that observable drives the reader FAB and forces a full-screen rebuild.
    if (!_versesCacheMatchesBook(bookNum)) {
      selectedVersesContent.value = newVerses;
    }

    final chapterRows =
        await _rawQueryVerseChapter(db, bookNum, safeChapter);
    var chapterContent = filterContent(chapterRows
        .map<VerseBookContentModel>(
            (e) => VerseBookContentModel.fromJson(e))
        .toSet()
        .toList());
    if (chapterContent.isEmpty) {
      final verses = selectedVersesContent.isNotEmpty
          ? selectedVersesContent
          : newVerses;
      chapterContent = _filterChapterFromVerses(verses, safeChapter);
    }
    if (chapterContent.isEmpty) return false;
    if (loadId != _chapterLoadGeneration) return false;
    selectedBookContent.value = chapterContent;

    selectedBookNum.value = bookNum.toString();
    await SharPreferences.setString(
        SharPreferences.selectedBookNum, bookNum.toString());
    return true;
  }

  /// Fallback when SQL chapter query fails but verses are already in memory.
  Future<bool> hydrateChapterFromCachedVerses(
    List<VerseBookContentModel> cache,
    int uiChapter,
  ) async {
    if (cache.isEmpty) return false;
    final stored = int.tryParse(selectedBookNum.value) ?? 1;
    final safeChapter = uiChapter <= 0 ? 1 : uiChapter;

    for (final bookNum in _bookNumLoadCandidates(stored)) {
      final bookVerses =
          cache.where((v) => (v.bookNum ?? -999) == bookNum).toList();
      if (bookVerses.isEmpty) continue;

      selectedVersesContent.value = bookVerses;
      selectedBookNum.value = bookNum.toString();
      await SharPreferences.setString(
          SharPreferences.selectedBookNum, bookNum.toString());
      await _fillChapterFromVerseListIfNeeded(safeChapter);
      if (selectedBookContent.isNotEmpty) return true;
    }
    return false;
  }

  /// If SQL chapter rows were empty but we already loaded all verses for the book, filter in memory.
  Future<void> _fillChapterFromVerseListIfNeeded(int uiChapter) async {
    final safe = uiChapter <= 0 ? 1 : uiChapter;
    if (selectedBookContent.isNotEmpty &&
        _displayedContentMatchesUiChapter(safe)) {
      return;
    }
    final verses = selectedVersesContent;
    if (verses.isEmpty) return;
    final chapterContent = _filterChapterFromVerses(verses, uiChapter);
    if (chapterContent.isNotEmpty) {
      selectedBookContent.value = chapterContent;
    }
  }

  Future<void> getBookContentForRead() async {
    try {
      if (_canSkipChapterReloadSync() &&
          selectedChapter.value == selectedChapterForRead.value &&
          _bookIdMatches(
              selectedBookNum.value, selectedBookNumForRead.value)) {
        return;
      }

      if (selectedBookContent.isNotEmpty &&
          selectedChapter.value == selectedChapterForRead.value &&
          _bookIdMatches(
              selectedBookNum.value, selectedBookNumForRead.value) &&
          _displayedContentMatchesUiChapter(
              int.tryParse(selectedChapterForRead.value) ?? 1)) {
        return;
      }

      // Avoid clearing visible content while a reload is in flight.
      // Only enter "loading" state when we truly have nothing to show.
      final hadVisibleContent = selectedBookContent.isNotEmpty;
      if (!hadVisibleContent) {
        selectedBookContent.clear();
        selectedVersesContent.clear();
        isFetchContent.value = true;
        loadTextToSpeech.value = true;
      } else {
        loadTextToSpeech.value = true;
      }

      // Do not overwrite live book/chapter with empty/"null" ForRead values
      // (Home init can leave ForRead blank; audio next-chapter sync relies on this).
      final forReadChapter = selectedChapterForRead.value.trim();
      final forReadBook = selectedBookNameForRead.value.trim();
      final forReadBookNum = selectedBookNumForRead.value.trim();
      if (forReadChapter.isNotEmpty && forReadChapter.toLowerCase() != 'null') {
        selectedChapter.value = forReadChapter;
      }
      if (forReadBook.isNotEmpty && forReadBook.toLowerCase() != 'null') {
        selectedBook.value = forReadBook;
      }
      if (forReadBookNum.isNotEmpty && forReadBookNum.toLowerCase() != 'null') {
        selectedBookNum.value = forReadBookNum;
      }
      if (selectedBook.value.isNotEmpty) {
        await SharPreferences.setString(
          SharPreferences.selectedBook,
          selectedBook.value,
        );
      }

      final chapterValue =
          selectedChapter.value.isNotEmpty ? selectedChapter.value : "1";
      selectChapterChange.value = int.tryParse(chapterValue) ?? 1;

      final bookNumForRead = selectedBookNumForRead.value.isNotEmpty
          ? selectedBookNumForRead.value
          : (selectedBookNum.value.isNotEmpty ? selectedBookNum.value : "0");
      var parsedBookNum = int.tryParse(bookNumForRead) ?? 0;

      final chapterForRead = selectedChapterForRead.value.isNotEmpty
          ? selectedChapterForRead.value
          : chapterValue;
      final parsedChapterForReadRaw = int.tryParse(chapterForRead) ?? 1;
      final parsedChapterForRead =
          parsedChapterForReadRaw <= 0 ? 1 : parsedChapterForReadRaw;

      final value = await DBHelper().db;
      if (value == null) {
        debugPrint('getBookContentForRead: DB null');
        return;
      }

      var selectedBookResponse = await value.rawQuery(
          "SELECT * From verse WHERE book_num ='$parsedBookNum'");
      var effectiveBookNum = parsedBookNum;
      var effectiveVersesResponse = selectedBookResponse;

      if (effectiveVersesResponse.isEmpty && effectiveBookNum > 0) {
        final legacyBookNum = effectiveBookNum - 1;
        final retry = await value.rawQuery(
            "SELECT * From verse WHERE book_num ='$legacyBookNum'");
        if (retry.isNotEmpty) {
          effectiveBookNum = legacyBookNum;
          effectiveVersesResponse = retry;
          selectedBookNum.value = legacyBookNum.toString();
          selectedBookNumForRead.value = legacyBookNum.toString();
          await SharPreferences.setString(
              SharPreferences.selectedBookNum, legacyBookNum.toString());
          parsedBookNum = legacyBookNum;
        }
      }
      // Prefs "0" for Genesis but DB uses 1-based book_num.
      if (effectiveVersesResponse.isEmpty && effectiveBookNum == 0) {
        final oneBased = 1;
        final retry = await value.rawQuery(
            "SELECT * From verse WHERE book_num ='$oneBased'");
        if (retry.isNotEmpty) {
          effectiveBookNum = oneBased;
          effectiveVersesResponse = retry;
          selectedBookNum.value = oneBased.toString();
          selectedBookNumForRead.value = oneBased.toString();
          await SharPreferences.setString(
              SharPreferences.selectedBookNum, oneBased.toString());
          parsedBookNum = oneBased;
        }
      }

      final newVerses = effectiveVersesResponse
          .map<VerseBookContentModel>(
              (e) => VerseBookContentModel.fromJson(e))
          .toList();
      if (!_versesCacheMatchesBook(effectiveBookNum)) {
        selectedVersesContent.value = newVerses;
      }

      var chapterRows = await _rawQueryVerseChapter(
          value, effectiveBookNum, parsedChapterForRead);
      var chapterContent = filterContent(chapterRows
          .map<VerseBookContentModel>(
              (e) => VerseBookContentModel.fromJson(e))
          .toList());
      if (chapterContent.isEmpty) {
        final verses = selectedVersesContent.isNotEmpty
            ? selectedVersesContent
            : newVerses;
        chapterContent =
            _filterChapterFromVerses(verses, parsedChapterForRead);
      }
      if (chapterContent.isNotEmpty) {
        selectedBookContent.value = chapterContent;
      }

      var rows =
          await value.rawQuery("SELECT * From book WHERE book_num = ?", [
        parsedBookNum,
      ]);
      if (rows.isEmpty && parsedBookNum > 0) {
        final legacyBookNum = parsedBookNum - 1;
        final retry = await value.rawQuery(
            "SELECT * From book WHERE book_num = ?", [legacyBookNum]);
        if (retry.isNotEmpty) {
          rows = retry;
          selectedBookNum.value = legacyBookNum.toString();
          selectedBookNumForRead.value = legacyBookNum.toString();
          await SharPreferences.setString(
              SharPreferences.selectedBookNum, legacyBookNum.toString());
        }
      }
      if (rows.isNotEmpty) {
        selectedBookChapterCount.value = rows[0]["chapter_count"].toString();
        bookReadPer.value = rows[0]["read_per"].toString();
        selectedBookId.value = rows[0]["id"].toString();
      }
    } catch (e, st) {
      log('Error: $e,$st');
    } finally {
      final uiCh = int.tryParse(selectedChapter.value) ?? 1;
      _sanitizeSelectedBookContentToUiChapter(uiCh <= 0 ? 1 : uiCh);
      if (loadTextToSpeech.value) {
        loadTextToSpeech.value = false;
      }
      if (isFetchContent.value) {
        isFetchContent.value = false;
      }
    }
  }

  Future<void> getSelectedChapterAndBook() async {
    if (_canSkipChapterReloadSync()) {
      return;
    }

    final selectedBookValue =
        await SharPreferences.getString(SharPreferences.selectedBookNum);
    final getChapter =
        await SharPreferences.getString(SharPreferences.selectedChapter) ??
            "1";
    final parsedStoredBookNum = int.tryParse(selectedBookValue ?? '');
    final storedBookNum = (selectedBookValue == null ||
            selectedBookValue.trim().isEmpty ||
            parsedStoredBookNum == null)
        ? '0'
        : selectedBookValue.toString();
    final prefChapter = int.tryParse(getChapter) ?? 1;
    final memChapter = int.tryParse(selectedChapter.value);
    // Swipe/chapter pick may update memory before SharedPreferences finishes.
    final targetChapter =
        (memChapter != null && memChapter > 0) ? memChapter : prefChapter;

    if (selectedBookContent.isNotEmpty &&
        _bookIdMatches(selectedBookNum.value, storedBookNum) &&
        targetChapter == (int.tryParse(selectedChapter.value) ?? 1) &&
        _displayedContentMatchesSelectedBook() &&
        _displayedContentMatchesUiChapter(targetChapter)) {
      return;
    }

    final loadId = ++_chapterLoadGeneration;
    try {
      // Avoid clearing visible content while a reload is in flight.
      // Only enter "loading" state when we truly have nothing to show.
      final hadVisibleContent = selectedBookContent.isNotEmpty;
      if (!hadVisibleContent) {
        selectedBookContent.clear();
        selectedVersesContent.clear();
        isFetchContent.value = true;
        loadTextToSpeech.value = true;
      }
      selectedBook.value =
          await SharPreferences.getString(SharPreferences.selectedBook) ?? "";

      if (loadId != _chapterLoadGeneration) return;

      if (selectedBookValue == null ||
          selectedBookValue.trim().isEmpty ||
          parsedStoredBookNum == null) {
        selectedBookNum.value = '0';
        await SharPreferences.setString(SharPreferences.selectedBookNum, '0');
      } else {
        selectedBookNum.value = selectedBookValue.toString();
      }

      var safeChapter = targetChapter <= 0 ? 1 : targetChapter;
      // After awaits, a newer audio/reader sync may have moved the chapter.
      // Follow the live chapter instead of aborting (abort left content blank
      // after forceReload cleared selectedBookContent).
      final liveChapter = int.tryParse(selectedChapter.value) ?? 0;
      if (liveChapter > 0 && liveChapter != safeChapter) {
        safeChapter = liveChapter;
      }
      if (safeChapter.toString() != selectedChapter.value) {
        selectedChapter.value = safeChapter.toString();
      }
      if (safeChapter != prefChapter) {
        await SharPreferences.setString(
            SharPreferences.selectedChapter, safeChapter.toString());
      }
      selectChapterChange.value = safeChapter;

      final parsedBookNumEarly =
          int.tryParse(selectedBookNum.value) ?? parsedStoredBookNum ?? 1;
      if (selectedVersesContent.isNotEmpty &&
          _versesCacheMatchesBook(parsedBookNumEarly)) {
        final quickChapter =
            _filterChapterFromVerses(selectedVersesContent, safeChapter);
        if (quickChapter.isNotEmpty) {
          selectedBookContent.value = quickChapter;
        }
      }

      if (loadId != _chapterLoadGeneration) return;

      dynamic value;
      for (var attempt = 0; attempt < 5; attempt++) {
        value = await DBHelper().db;
        if (value != null) break;
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
      if (value == null) {
        debugPrint('getSelectedChapterAndBook: DB null after retries');
        return;
      }

      final parsedBookNum = int.tryParse(selectedBookNum.value) ?? 1;
      final candidates = _bookNumLoadCandidates(parsedBookNum);
      var loaded = false;

      for (final bookNum in candidates) {
        if (await _loadBookChapterFromDb(value, bookNum, safeChapter,
            loadId: loadId)) {
          loaded = true;
          break;
        }
      }

      if (!loaded) {
        for (var attempt = 0; attempt < 4 && !loaded; attempt++) {
          if (loadId != _chapterLoadGeneration) return;
          await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
          final count =
              await value.rawQuery('SELECT COUNT(*) as c FROM verse LIMIT 1');
          final verseCount = int.tryParse('${count.first['c']}') ?? 0;
          if (verseCount == 0) continue;
          for (final bookNum in candidates) {
            if (await _loadBookChapterFromDb(value, bookNum, safeChapter,
                loadId: loadId)) {
              loaded = true;
              break;
            }
          }
        }
      }

      if (loadId != _chapterLoadGeneration) return;

      final resolvedBookNum = int.tryParse(selectedBookNum.value) ?? parsedBookNum;
      await _applyBookMetadata(value, resolvedBookNum, candidates);
    } catch (e) {
      debugPrint(" error on getSelectedChapterAndBook - $e ");
    } finally {
      if (loadId != _chapterLoadGeneration) return;
      // Drop any leftover next-chapter verses before showing the reader.
      final uiCh = int.tryParse(selectedChapter.value) ?? 1;
      _sanitizeSelectedBookContentToUiChapter(uiCh <= 0 ? 1 : uiCh);
      if (loadTextToSpeech.value) {
        loadTextToSpeech.value = false;
      }
      if (isFetchContent.value) {
        isFetchContent.value = false;
      }
    }
  }

  Future<void> getFont() async {
    fontSizeS.value =
        await SharPreferences.getString(SharPreferences.selectedFontSize) ??
            "${Sizecf.scrnWidth! > 450 ? 25.0 : 19.0}";
    fontSize.value = double.parse(fontSizeS.value);
    selectedFontFamily.value =
        await SharPreferences.getString(SharPreferences.selectedFontFamily) ??
            "Arial";
  }

  final notesController = TextEditingController().obs;
  final colorsCheack = 0.obs;
  final screenshotController = ScreenshotController().obs;
  final RxList<Color> colors = <Color>[
    Color(0xFFBDDFFA),
    Color(0xFFD1C869),
    Color(0xFFFABBD0),
    Color(0xFFC3E0C4),
    Color(0xFFFED6B2),
    Color(0xFFFE9798),
    Color(0xFFE7B9F8),
    Color(0xFF86DACB)
  ].obs;

  final turns = 0.0.obs;
  Future<void> changeRotation() async {
    turns.value += 1.0 / 1.0;
  }

  final selectedColorOrNot = "".obs;

  /// Banner ad
  BannerAd? bannerAd;
  BannerAd? newBannerAd;
  final isBannerAdLoaded = false.obs;
  final isNewBannerAdLoaded = false.obs;

  /// Image Banner AD
  BannerAd? imageBannerAd;
  final isImageBannerAdLoaded = false.obs;
  // Future<AdRequest> getAdRequest() async {
  //   final trackingAllowed = await ConsentManager.isTrackingAllowed();

  //   final extras = <String, String>{};

  //   if (!trackingAllowed) {
  //     extras['npa'] = '1'; // non-personalized ads
  //   }
  //   debugPrint(" non-personalized ads 1 is ${!trackingAllowed}");

  //   return AdRequest(
  //     nonPersonalizedAds: !trackingAllowed,
  //     keywords:
  //         !trackingAllowed == true ? ['bible', 'education', 'church'] : null,
  //     extras: extras,
  //   );
  // }

  /// Popup Banner AD
  BannerAd? popupBannerAd;
  final isPopupBannerAdLoaded = false.obs;
  Future<void> initBanner({required String adUnitId}) async {
    //final trackingAllowed = await isTrackingAllowed();
    // debugPrint('ad banner trackingAllowed -  ${!trackingAllowed}');
    bannerAd = BannerAd(
        size: AdSize.mediumRectangle,
        adUnitId: adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            isBannerAdLoaded.value = true;
            //  DebugConsole.log('banner Ad loaded:  - adUnitId - $adUnitId');
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            bannerAd?.dispose();
            // DebugConsole.log(
            //     'banner Ad error1: ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
          },
          onAdWillDismissScreen: (ad) {
            ad.dispose();
            bannerAd?.dispose();
          },
          onAdClosed: (ad) {
            ad.dispose();
            bannerAd?.dispose();
          },
        ),
        request: await AdConsentManager.getAdRequest());
    bannerAd?.load();
    // DebugConsole.log(" bannerAd is running ");
  }

  Future<void> initNewBannerAd({required String adUnitId}) async {
    newBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: adUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          isNewBannerAdLoaded.value = true;
          // DebugConsole.log(
          //     'ad initNewBannerAd Ad loaded:  -  adUnitId - $adUnitId');
        }, onAdClosed: (ad) {
          ad.dispose();
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // DebugConsole.log(
          //     'ad initNewBannerAd Ad error1:  ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
        }),
        request: await AdConsentManager.getAdRequest());
    newBannerAd?.load();
    // DebugConsole.log(" newBannerAd is running ");
  }

  ///Image Banner Ad
  Future<void> initImageBannerAd({required String adUnitId}) async {
    //final trackingAllowed = await isTrackingAllowed();
    // debugPrint('ad banner trackingAllowed -  ${!trackingAllowed}');
    imageBannerAd = BannerAd(
        size: AdSize.leaderboard,
        adUnitId: adUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          if (kDebugMode) {}
          isImageBannerAdLoaded.value = true;
          // DebugConsole.log(
          //     'ad initImageBannerAd Ad loaded:  -  adUnitId - $adUnitId');
        }, onAdClosed: (ad) {
          ad.dispose();
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // DebugConsole.log(
          //     'ad initImageBannerAd Ad error1:  ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
        }),
        request: await AdConsentManager.getAdRequest());
    imageBannerAd?.load();
    // DebugConsole.log(" imageBannerAd is running ");
  }

  /// Home Popup Banner AD
  BannerAd? popupBannerAdHome;
  final isPopupBannerAdHomeLoaded = false.obs;

  Future<void> initReadMeBelowAd({required String adUnitId}) async {
    // final trackingAllowed = await isTrackingAllowed();
    // debugPrint('ad banner trackingAllowed -  ${!trackingAllowed}');

    popupBannerAdHome = BannerAd(
        size: AdSize.mediumRectangle,
        adUnitId: adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (kDebugMode) {}
            isPopupBannerAdHomeLoaded.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            // DebugConsole.log(
            //     'popup banner Ad error1: ${error.message} - adUnitId - $adUnitId');
          },
          onAdClosed: (ad) {
            ad.dispose();
          },
          onAdWillDismissScreen: (ad) {
            ad.dispose();
          },
        ),
        request: await AdConsentManager.getAdRequest());
    popupBannerAdHome?.load();
    // DebugConsole.log(" popupBannerAd is running ");
  }

  Future<void> initPopUpAd({required String adUnitId}) async {
    final trackingAllowed = await isTrackingAllowed();
    debugPrint('ad pop trackingAllowed -  ${!trackingAllowed}');

    // Success-dialog banner only: adaptive width (same pattern as topic detail).
    // Display logic unchanged — dialog still uses ad.size.width / ad.size.height.
    final width = _successPopupAdaptiveBannerWidth();
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (adaptiveSize == null) {
      debugPrint('initPopUpAd: adaptive banner size unavailable (width=$width)');
      return;
    }

    popupBannerAd?.dispose();
    popupBannerAd = BannerAd(
        size: adaptiveSize,
        adUnitId: adUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          if (kDebugMode) {}
          isPopupBannerAdLoaded.value = true;
          //  DebugConsole.log('initPopUpAd Ad loaded1:  - adUnitId - $adUnitId');
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isPopupBannerAdLoaded.value = false;
          // DebugConsole.log(
          // 'initPopUpAd Ad error1: ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
        }),
        request: await AdConsentManager.getAdRequest());
    popupBannerAd?.load();
    //  DebugConsole.log(" popup2BannerAd is running ");
  }

  /// Logical width for the success-popup adaptive banner (matches AlertDialog content).
  int _successPopupAdaptiveBannerWidth() {
    const dialogContentWidth = 400;
    if (Sizecf.scrnWidth != null && Sizecf.scrnWidth! > 0) {
      return Sizecf.scrnWidth!.truncate().clamp(320, dialogContentWidth);
    }
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      final view = views.first;
      final logical =
          (view.physicalSize.width / view.devicePixelRatio).truncate();
      return logical.clamp(320, dialogContentWidth);
    }
    return dialogContentWidth;
  }

  final openAdIsPaused = false.obs;

  @override
  onInit() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    await initConnectivity();
    await SharPreferences.getString(SharPreferences.isRewardAdViewTime)
        .then((value) async {
      if (value != null) {
        DateTime CurrentDateTime = DateTime.now();
        DateTime SaveTime = DateTime.parse(value.toString());
        var diff = CurrentDateTime.difference(SaveTime).inDays;
        if (!diff.isNegative) {
        } else {
          openAdIsPaused.value = false;
        }
      } else {}
    });

    WidgetsBinding.instance.addObserver(this);
    super.onInit();
  }

  @override
  onClose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// interstitial ad
  InterstitialAd? interstitialAd;
  final isInterstitialAdLoad = false.obs;
  // initInterstitialAd({required String adUnitId}) async {
  //   final trackingAllowed = await isTrackingAllowed();
  //   debugPrint('ad pop InterstitialAd -  ${!trackingAllowed}');
  //   isInterstitialAdLoad.value = false;
  //   interstitialAd = null;
  //   InterstitialAd.load(
  //       adUnitId: adUnitId,
  //       request: await AdConsentManager.getAdRequest(),
  //       adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
  //         interstitialAd = ad;
  //         isInterstitialAdLoad.value = true;

  //         interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
  //             onAdDismissedFullScreenContent: (ad) async {
  //           ad.dispose();
  //           isInterstitialAdLoad.value = false;
  //           interstitialAd = null;
  //           await SharPreferences.setString('OpenAd', '1');
  //         }, onAdFailedToShowFullScreenContent: (ad, error) {
  //           // DebugConsole.log(
  //           //     'InterstitialAd show Ad error1: ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
  //           isInterstitialAdLoad.value = false;
  //           interstitialAd = null;
  //           ad.dispose();
  //         });
  //       }, onAdFailedToLoad: ((error) {
  //         // DebugConsole.log(
  //         //     'InterstitialAd load Ad error1: ${error.message} - $adUnitId ');
  //         isInterstitialAdLoad.value = false;
  //         interstitialAd = null;
  //         interstitialAd?.dispose();
  //       })));
  // }

  /// Rewarded Ad
  final RewardAdExpireDate = "".obs;
  RewardedAd? rewardedAd;
  bool? isRewardedAdLoaded = false;

  // loadRewardedAd({required String adUnitId}) async {
  //   final trackingAllowed = await isTrackingAllowed();
  //   debugPrint('ad pop loadRewardedAd -  ${!trackingAllowed}');
  //   if (adUnitId.isNotEmpty) {
  //     isRewardedAdLoaded = false;
  //     print("rewarded ads $adUnitId");
  //     RewardedAd.load(
  //         adUnitId: adUnitId,
  //         request: await AdConsentManager.getAdRequest(),
  //         rewardedAdLoadCallback: RewardedAdLoadCallback(
  //           onAdLoaded: (RewardedAd ad) async {
  //             debugPrint("$ad loaded");
  //             rewardedAd = ad;
  //             isRewardedAdLoaded = true;

  //             _setFullScreenContentCallback();
  //           },
  //           onAdFailedToLoad: (error) {
  //             Constants.showToast("Ad not available.");
  //             isRewardedAdLoaded = false;
  //             // DebugConsole.log(
  //             //     'RewardedAd Ad error1: ${error.message} - $adUnitId');
  //           },
  //         ));
  //   }
  // }

  Future<void> refreshPremiumStatusFromPrefs() async {
    final value =
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
    if (value == null || value.isEmpty) return;

    RewardAdExpireDate.value = value;
    try {
      final expiryDate = DateTime.parse(value);
      final diff = DateTime.now().difference(expiryDate).inDays;
      if (diff.isNegative) {
        adFree.value = true;
        isGetRewardAd.value = false;
        adsDisplayTim.value = false;
        await SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
      }
    } catch (e) {
      debugPrint('refreshPremiumStatusFromPrefs parse error: $e');
    }
  }

  disableAd(Duration duration) async {
    // Additive: never persist a past/zero expiry — that re-enables ads and
    // shows "expired" even after a successful Buy that iOS reported as restored.
    var safeDuration = duration;
    if (safeDuration.isNegative || safeDuration.inSeconds <= 0) {
      debugPrint(
        'disableAd: refusing non-positive duration $duration — '
        'using 366 days',
      );
      safeDuration = const Duration(days: 366);
    }
    final prefs = await SharedPreferences.getInstance();
    var expiryDate = DateTime.now().add(safeDuration);

    RewardAdExpireDate.value = expiryDate.toString();
    await SharPreferences.setString(
        SharPreferences.isRewardAdViewTime, expiryDate.toString());
    await SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
    await prefs.setBool('ad_enabled', false);
    adFree.value = true;
    isGetRewardAd.value = false;
    // isGetRewardAd.value = true;
    adsDisplayTim.value = false;
    //  openAdIsPaused.value = false;
    isInterstitialAdLoad.value = false;
    isBannerAdLoaded.value = false;
    await refreshPremiumStatusFromPrefs();
  }

  void _setFullScreenContentCallback() {
    if (rewardedAd == null) return;
    rewardedAd?.fullScreenContentCallback =
        FullScreenContentCallback(onAdShowedFullScreenContent: (RewardedAd ad) {
      print("$ad onAdShowedFullScreenContent");
    }, onAdDismissedFullScreenContent: (RewardedAd ad) async {
      print("$ad onAdDismissedFullScreenContent");
      await SharPreferences.setString('OpenAd', '1');
      ad.dispose();
    }, onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
      // DebugConsole.log('RewardedAd 2 Ad error1: ${error.message} -$ad ');
      ad.dispose();
    }, onAdImpression: (RewardedAd ad) {
      print("$ad Impression occured");
    });
  }

  final adFree = false.obs;
  final isGetRewardAd = false.obs;
  final adsDisplayTim = true.obs;

  void updateBottomSheet() {}

  void updateBookmarkColor(bool bool) {}

  /// Carousel Slider
  final caroausalList = [
    "assets/1.jpg",
    "assets/2.jpg",
    "assets/3.jpg",
    "assets/4.jpg",
    "assets/5.jpg",
    "assets/1.jpg",
    "assets/2.jpg",
    "assets/3.jpg",
  ].obs;

  final card = [
    "assets/card1.png",
    "assets/card2.png",
    "assets/card6.png",
    "assets/card4.png",
    "assets/card5.png",
    "assets/card8.png",
    "assets/card7.png",
    "assets/card9.png",
  ].obs;
  final cardText = [
    BibleInfo.bible_shortName,
    "Make an image of your favorite verse",
    "Audio track with easy navigation",
    "Save your progress & access anytime",
    "Read effortlessly in night mode",
    "Inspiring Wallpapers & Bible Quotes",
    "Make reading yours with stylish themes",
    "Backup and restore your data effortlessly"
  ].obs;

  final currentCarosal = 0.obs;
  final value1 = "6monthplan".obs;
  final value2 = "1yearplan".obs;
  final value3 = "lifetimeplan".obs;
  final SelectOne = "".obs;

  final rating = 1.obs;

  // InApp Purchase *************************************

  // final  _kAutoConsume = Platform.isIOS || true;
}
