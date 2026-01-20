class BibleInfo {
  static String apple_AppId = "6460891065";

  // 6484270584  //6459793603
  static String ios_Bundle_Id = "com.balaklrapps.genevabible";
  static String bible_shortName = "Geneva Bible";
  static String current_Version = "1.0.69";
  static String android_Package_Name = "com.whitebibles.genevabible";
  static String appID = '11656bd4-ed0c-11ef-b28e-fa163e8c011b';
  //static int surveyAppId = 3;

//IAP
  static String sixMonthPlanid = 'com.balaklrapps.genevabible.sixmonthadsfree';
  static String oneYearPlanid = 'com.balaklrapps.genevabible.oneyearadsfree';
  static String lifeTimePlanid = 'com.balaklrapps.genevabible.lifetimeadsfree';
  static String exitOfferPlanid =
      'com.balaklrapps.genevabible.lifetime.exitoffer';

  // Coin Pack IDs
  static String coinPack1Id = 'com.balaklrapps.genevabible.coinspack1';
  static String coinPack2Id = 'com.balaklrapps.genevabible.coinspack2';
  static String coinPack3Id = 'com.balaklrapps.genevabible.coinspack3';

  // Coin Pack Prices (for offline mode)
  static String coinPack1Price = '\$4.99';
  static String coinPack2Price = '\$9.99';
  static String coinPack3Price = '\$19.99';

  static bool enableIAP = true;

  // enable-> true or disable-> false e-products here
  static bool enableEShop = false;

  // AD Enable - Set to true to enable ads, false to disable
  static bool enableAds = true;

  // Ads IDs - Android
  static String adsGoogleBannerIdAndroid = "";
  static String adsGoogleBannerId_2Android = "";
  static String adsGoogleBannerId_3Android = "";
  static String adsGoogleInterstitialIdAndroid = "";
  static String adsGoogleRewardIdAndroid = "";
  static String adsGoogleOpenAppIdAndroid = "";
  static String adsGoogleNativeIdAndroid = "";
  static String adsGoogleRewardInterstitialIdAndroid = "";

  // Ads IDs - iOS
  static String adsGoogleBannerIdIos = "ca-app-pub-4194577750257069/5888490615";
  static String adsGoogleBannerId_2Ios = "";
  static String adsGoogleBannerId_3Ios = "";
  static String adsGoogleInterstitialIdIos =
      "ca-app-pub-4194577750257069/3990737976";
  static String adsGoogleRewardIdIos = "ca-app-pub-4194577750257069/3262327277";
  static String adsGoogleOpenAppIdIos =
      "ca-app-pub-4194577750257069/1949245605";
  static String adsGoogleNativeIdIos = "ca-app-pub-4194577750257069/2933990334";
  static String adsGoogleRewardInterstitialIdIos = "";

// add folder names here  assets/zipped/
  static List<String> folders = [
    "Geneva Bible"
    // "Bengali Bible",
  ];

  static String emailVerify = "0";

  static int appcount = 5;

  static String thankyoucontent = "";

  static String thankyoutitle = " 🙏 Help Us Keep the Bible App Free ";

  static int old_testament_count =
      39; //book count 65 - olt 39, book count 72 - olt 45
  static String new_testament_count = "27";

  static String exportText =
      'Save your Bookmarked verses, Highlights, Notes and Verse Images directly to your device. This option stores a backup file locally, which can be transferred or accessed later. You can import this file into the app whenever needed, even on another device.';
  static String importText = 'Please select the file you exported last time.';

  static String termsandConditionURL =
      "https://bibleoffice.com/terms_conditions.html";
  static String privacyPolicyURL =
      "https://bibleoffice.com/privacy_policy.html";

  static int imageMaxLines = 7;

  static const double fontSizeScale = 1.0;
  static const double letterSpacing = 0.4;

  // Chat feature visibility: 0 = hide, 1 = show
  static int chat = 1;

  // Audio and Text to Speech Constants (fallback when API data is not available)
  // Audio Settings
  static String audioBasePath =
      "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/";
  static String audioBasePathType = "3";
  static String isShowMp3Audio = "1";

  // Text to Speech Settings - iOS
  static String isTextToSpeechAvailableIos = "0";
  static String textToSpeechLanguageCodeIos = "";
  static String textToSpeechIdentifierIos = "";

  // Text to Speech Settings - Android
  static String isTextToSpeechAvailableAndroid = "0";
  static String textToSpeechLanguageCodeAndroid = "";

  // Subscription Plan IDs (for fallback)
  static String subIdentifierSixMonth = sixMonthPlanid;
  static String subIdentifierOneYear = oneYearPlanid;
  static String subIdentifierLifetime = lifeTimePlanid;

  // Basic App Settings
  static String isSubscriptionEnabled = "1";
  static String adsDuration = "3";
  static String offerEnabled = "1";
  static int offerDays = 20;
  static int offerCount = 200;
}
