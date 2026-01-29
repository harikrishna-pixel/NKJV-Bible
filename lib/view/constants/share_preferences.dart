import 'package:shared_preferences/shared_preferences.dart';

class SharPreferences {
  static const theme = "theme";
  static const onboarding = "onboarding";
  static const selectedBookNum = "selectedBookNum";
  static const selectedBook = "selectedBook";
  static const selectedChapter = "selectedChapter";
  static const isLoadBookContent = "isLoadBookContent";
  static const isLoadBookList = "isLoadBookList";
  static const selectedFontSize = "selectedFontSize";
  static const selectedFontFamily = "selectedFontFamily";
  static const notificationTimeHour = "notificationTimeHour";
  static const notificationTimeHour1 = "notificationTimeHour1";
  static const notificationTimeHour2 = "notificationTimeHour2";
  static const notificationTimeMinute = "notificationTimeMinute";
  static const notificationTimeMinute1 = "notificationTimeMinute1";
  static const notificationTimeMinute2 = "notificationTimeMinute2";
  static const isNotificationOn = "isNotificationOn";
  static const isNotificationOn1 = "isNotificationOn1";
  static const isNotificationOn2 = "isNotificationOn2";
  static const isRewardAdViewTime = "isRewardAdViewTime";
  static const selectedDailyVerse = "selectedDailyVerse";
  static const dailyVerseUpdateTime = "dailyVerseUpdateTime";
  static const isVeryFirstTime = "isVeryFirstTime";
  static const saveRating = "saveRating";
  static const ratingDateTime = "ratingDateTime";
  static const lastViewTime = "lastViewTime";
  static const hasShownFirstShareRating = "hasShownFirstShareRating";
  static const lastOfferShown = "lastOfferShown";
  static const imageAppID = "imageAppId";
  static const wallpaperCatID = "wallpaperCatID";
  static const wallpaperBookMark = 'wallpaperBookmark';
  static const quotesBookMark = 'quotesBookmark';
  static const isAdsEnabled = 'isAdsEnabled'; // => Check if Ads Enabled ;
  static const isAdsEnabledApi =
      'isAdsEnabledApi'; // => Check if Ads Enabled from Api;
  static const openAppId = 'openAppId';
  static const rewardedInterstitialAd = 'rewardedInterstitialAd';
  static const rewardedAd = 'rewardedAd';
  static const googleInterstitialAd = 'googleInterstitialAd';
  static const googleBannerId = 'googleBannerId';
  static const nativeAdId = 'nativeAdId';
  static const adPauseDiff = 'adPauseDiff';
  static const isTtsActive = 'isTTSActive';
  static const lastExportedDate = 'lastExportedDate';
  static const userLocalData = 'userLocalData';
  static const calendarLocal = 'calendarLocal';
  static const bookadscatid = 'bookadscatid';
  static const surveyappid = 'surveyappid';
  static const surveyappenable = 'surveyappenable';
  static const showinterstitialrow = 'showinterstitialrow';
  static const offerenabled = 'offer_enabled';
  static const offercount = 'offer_count';

  static const lastInterstitialRewardedAdPlayedTime =
      'lastInterstitialRewardedAdPlayedTime';
  static const dailyWelcomeLastShownDate = 'dailyWelcomeLastShownDate';
  static const dailyWelcomeMessageIndex = 'dailyWelcomeMessageIndex';
  static const dailyWelcomeFirstTimeShown =
      'dailyWelcomeFirstTimeShown'; // Track if first message was shown
  static const prayerAmenMessageIndex = 'prayerAmenMessageIndex';
  static const prayerAmenAdCounter =
      'prayerAmenAdCounter'; // Counter for AMEN ad rotation (every 10 taps)
  static const verseOfDayAmenMessageIndex = 'verseOfDayAmenMessageIndex';
  static const markAsReadMessageIndex = 'markAsReadMessageIndex';

  static Future<bool?> getBoolean(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> setBoolean(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? val = prefs.getString(key);
    // if (val!.isEmpty) {
    //   return null;
    // }
    return val;
  }

  static Future<void> setString(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<double?> getDouble(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  static Future<void> setDouble(String key, double value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<void> setInt(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Check if ad has been shown today for bookmark/notes/images/underline actions
  static Future<bool> hasShownActionAdToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        DateTime.now().toIso8601String().split('T')[0]; // Get YYYY-MM-DD
    final lastShownDate = prefs.getString('action_ad_last_shown_date');

    if (lastShownDate == todayKey) {
      return true; // Ad already shown today
    }
    return false; // Ad not shown today
  }

  // Mark that ad has been shown today for bookmark/notes/images/underline actions
  static Future<void> markActionAdShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        DateTime.now().toIso8601String().split('T')[0]; // Get YYYY-MM-DD
    await prefs.setString('action_ad_last_shown_date', todayKey);
  }

  static Future<void> setListString(String key, List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  static Future<List<String>?> getStringList(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  static clearSharedPreference() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  static Future<bool> shouldLoadAd() async {
    final isAdEnabled =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabled);
    final isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    final shouldLoadAd =
        ((isAdEnabledFromApi ?? true) && (isAdEnabled ?? true));
    return shouldLoadAd;
  }
}
