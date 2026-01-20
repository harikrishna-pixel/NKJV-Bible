import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
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
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
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
      bibleAudioInfo.isTextToSpeechAvailableIos = BibleInfo.isTextToSpeechAvailableIos;
      bibleAudioInfo.textToSpeechLanguageCodeIos = BibleInfo.textToSpeechLanguageCodeIos;
      bibleAudioInfo.textToSpeechIdentifierIos = BibleInfo.textToSpeechIdentifierIos;
      bibleAudioInfo.isTextToSpeechAvailableAndroid = BibleInfo.isTextToSpeechAvailableAndroid;
      bibleAudioInfo.textToSpeechLanguageCodeAndroid = BibleInfo.textToSpeechLanguageCodeAndroid;
      
      // Set audio info to data
      constantsData.bibleAudioInfo = bibleAudioInfo;
      constantsData.appAudioBasepath = BibleInfo.audioBasePath;
      constantsData.appAudioBasepathType = BibleInfo.audioBasePathType;
      
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

      debugPrint('Initialized with constants successfully - Audio and Text-to-Speech data from constants');
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
    await Future.wait([
      SharPreferences.setString(
          SharPreferences.wallpaperCatID, value.data?.wallpaperCatId ?? ''),
      SharPreferences.setString(
          SharPreferences.imageAppID, value.data?.imageAppId ?? ''),
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
    sixMonthPlan = value.data?.subIdentifierSixMonth?.isNotEmpty == true
        ? value.data!.subIdentifierSixMonth!
        : BibleInfo.sixMonthPlanid;
    oneYearPlan = value.data?.subIdentifierOneyear?.isNotEmpty == true
        ? value.data!.subIdentifierOneyear!
        : BibleInfo.oneYearPlanid;
    lifeTimePlan = value.data?.subIdentifierLifetime?.isNotEmpty == true
        ? value.data!.subIdentifierLifetime!
        : BibleInfo.lifeTimePlanid;

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
    // await initInterstitialAd(adUnitId: adIds['interstitialAdUnitId'] ?? '');
    // ]);

    // Load rewarded ad separately as it might need special handling
    // loadRewardedAd(adUnitId: adIds['rewardedAdUnitId'] ?? '');
  }

  Future<void> _handleApiError(dynamic e) async {
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

  Future<void> getBookContentForRead() async {
    try {
      selectedBookContent.clear();
      selectedVersesContent.clear();
      isFetchContent.value = true;
      loadTextToSpeech.value = true;

      selectedChapter.value = selectedChapterForRead.value;
      selectedBook.value = selectedBookNameForRead.value;
      selectedBookNum.value = selectedBookNumForRead.value;
      selectedBook.value = selectedBookNameForRead.value;
      await SharPreferences.setString(
        SharPreferences.selectedBook,
        selectedBook.value,
      );

      // Validate and parse selectedChapter with default value
      final chapterValue =
          selectedChapter.value.isNotEmpty ? selectedChapter.value : "1";
      selectChapterChange.value = int.tryParse(chapterValue) ?? 1;

      // Validate and parse selectedBookNumForRead with default value
      final bookNumForRead = selectedBookNumForRead.value.isNotEmpty
          ? selectedBookNumForRead.value
          : (selectedBookNum.value.isNotEmpty ? selectedBookNum.value : "0");
      final parsedBookNum = int.tryParse(bookNumForRead) ?? 0;

      // Validate and parse selectedChapterForRead with default value
      final chapterForRead = selectedChapterForRead.value.isNotEmpty
          ? selectedChapterForRead.value
          : chapterValue;
      final parsedChapterForRead = int.tryParse(chapterForRead) ?? 1;

      DBHelper().db.then((value) {
        value!
            .rawQuery("SELECT * From verse WHERE book_num ='$parsedBookNum'")
            .then((selectedBookResponse) {
          selectedVersesContent.value = selectedBookResponse
              .map<VerseBookContentModel>(
                  (e) => VerseBookContentModel.fromJson(e))
              .toList();
          loadTextToSpeech.value = false;
        });
        value
            .rawQuery(
                "SELECT * From verse WHERE book_num ='$parsedBookNum' AND chapter_num = '${parsedChapterForRead - 1}'")
            .then((selectedBookResponse) {
          selectedBookContent.value = filterContent(selectedBookResponse
              .map<VerseBookContentModel>(
                  (e) => VerseBookContentModel.fromJson(e))
              .toList());
          isFetchContent.value = false;
        });
      });

      DBHelper().db.then((value) {
        value!
            .rawQuery("SELECT * From book WHERE book_num = $parsedBookNum")
            .then((value) {
          if (value.isNotEmpty) {
            selectedBookChapterCount.value =
                value[0]["chapter_count"].toString();
            bookReadPer.value = value[0]["read_per"].toString();
            selectedBookId.value = value[0]["id"].toString();
          }
        });
      });
    } catch (e, st) {
      log('Error: $e,$st');
    }
  }

  Future<void> getSelectedChapterAndBook() async {
    try {
      selectedBookContent.clear();
      selectedVersesContent.clear();
      isFetchContent.value = true;
      loadTextToSpeech.value = true;
      selectedBook.value =
          await SharPreferences.getString(SharPreferences.selectedBook) ?? "";
      SharPreferences.getString(SharPreferences.selectedBookNum)
          .then((selectedBookValue) async {
        selectedBookValue == null
            ? selectedBookNum.value = "0"
            : selectedBookNum.value = selectedBookValue.toString();
        SharPreferences.getString(SharPreferences.selectedChapter)
            .then((getChapter) async {
          getChapter == null
              ? selectedChapter.value = "1"
              : selectedChapter.value = getChapter;
          selectChapterChange.value = int.parse(selectedChapter.value);

          await DBHelper().db.then((value) {
            if (value != null) {
              value
                  .rawQuery(
                      "SELECT * From verse WHERE book_num ='${int.parse(selectedBookNum.value)}'")
                  .then((selectedBookResponse) {
                selectedVersesContent.value = selectedBookResponse
                    .map<VerseBookContentModel>(
                        (e) => VerseBookContentModel.fromJson(e))
                    .toList();
                loadTextToSpeech.value = false;
              });
              value
                  .rawQuery(
                      "SELECT * From verse WHERE book_num ='${int.parse(selectedBookNum.value)}' AND chapter_num = '${int.parse(selectedChapter.value) - 1}'")
                  .then((selectedBookResponse) {
                selectedBookContent.value = filterContent(selectedBookResponse
                    .map<VerseBookContentModel>(
                        (e) => VerseBookContentModel.fromJson(e))
                    .toSet()
                    .toList());
                isFetchContent.value = false;
              });
            }
          });
        });
        await DBHelper().db.then((db) async {
          if (db != null) {
            final bookNum = int.tryParse(selectedBookNum.value) ?? 0;

            final result = await db.rawQuery(
              "SELECT * FROM book WHERE book_num = ?",
              [bookNum],
            );

            if (result.isNotEmpty) {
              final item = result[0];
              if (item["chapter_count"] != null &&
                  item["read_per"] != null &&
                  item["id"] != null) {
                selectedBookChapterCount.value =
                    item["chapter_count"].toString();
                bookReadPer.value = item["read_per"].toString();
                selectedBookId.value = item["id"].toString();
              } else {
                debugPrint(
                    "testapp One or more fields are null in the selected book.");
              }
            } else {
              debugPrint("testapp No book found with book_num = $bookNum");
            }
          } else {
            debugPrint("testapp Database instance is null");
          }
        });

        // await DBHelper().db.then((value) {
        //   if (value != null) {
        //     value
        //         .rawQuery(
        //             "SELECT * From book WHERE book_num = ${int.parse(selectedBookNum.value)}")
        //         .then((value1) {
        //       if (value1 != null && value1[0] != null) {
        //         selectedBookChapterCount.value =
        //             value1[0]["chapter_count"].toString();
        //         bookReadPer.value = value1[0]["read_per"].toString();
        //         selectedBookId.value = value1[0]["id"].toString();
        //       }
        //     });
        //   }
        // });
      });
    } catch (e) {
      debugPrint(" error on getSelectedChapterAndBook - $e ");
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

    popupBannerAd = BannerAd(
        size: AdSize.mediumRectangle,
        adUnitId: adUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          if (kDebugMode) {}
          isPopupBannerAdLoaded.value = true;
          //  DebugConsole.log('initPopUpAd Ad loaded1:  - adUnitId - $adUnitId');
        }, onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // DebugConsole.log(
          // 'initPopUpAd Ad error1: ${error.message} - ${ad.responseInfo} adUnitId - $adUnitId');
        }),
        request: await AdConsentManager.getAdRequest());
    popupBannerAd?.load();
    //  DebugConsole.log(" popup2BannerAd is running ");
  }

  final openAdIsPaused = false.obs;

  @override
  onInit() async {
    await initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
    _connectivitySubscription.cancel();
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

  disableAd(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    var expiryDate = DateTime.now().add(duration);

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
