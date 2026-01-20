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
  // static String adsGoogleBannerIdIos = "ca-app-pub-4194577750257069/5888490615";
  // static String adsGoogleBannerId_2Ios = "";
  // static String adsGoogleBannerId_3Ios = "";
  // static String adsGoogleInterstitialIdIos =
  //     "ca-app-pub-4194577750257069/3990737976";
  // static String adsGoogleRewardIdIos = "ca-app-pub-4194577750257069/3262327277";
  // static String adsGoogleOpenAppIdIos =
  //     "ca-app-pub-4194577750257069/1949245605";
  // static String adsGoogleNativeIdIos = "ca-app-pub-4194577750257069/2933990334";
  // static String adsGoogleRewardInterstitialIdIos = "";

  // TEST Ads IDs - iOS
  static String adsGoogleBannerIdIos = "ca-app-pub-3940256099942544/2934735716";
  static String adsGoogleBannerId_2Ios =
      "ca-app-pub-3940256099942544/2934735716";
  static String adsGoogleBannerId_3Ios =
      "ca-app-pub-3940256099942544/2934735716";
  static String adsGoogleInterstitialIdIos =
      "ca-app-pub-3940256099942544/4411468910";
  static String adsGoogleRewardIdIos = "ca-app-pub-3940256099942544/1712485313";
  static String adsGoogleOpenAppIdIos =
      "ca-app-pub-3940256099942544/5575463023";
  static String adsGoogleNativeIdIos = "ca-app-pub-3940256099942544/3986624511";
  static String adsGoogleRewardInterstitialIdIos =
      "ca-app-pub-3940256099942544/6978759866";

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

  // Wallpaper and Quotes IDs (fallback when API data is not available)
  // These are the ACTUAL IDs for Geneva Bible app (confirmed from API response)
  static String wallpaperCatId =
      "177"; // Actual wallpaper category ID for Geneva Bible
  static String imageAppId =
      "322"; // Actual quote/image app ID for Geneva Bible

  // More Apps fallback data (when API data is not available)
  // These are default apps to show when API fails
  static List<Map<String, dynamic>> getMoreAppsFallbackData() {
    return [
      {
        'appId': '132',
        'appName': 'The Amplified Bible Flutter iOS',
        'appurl': 'https://apps.apple.com/app/id6459793603',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb132_1745498978.webp',
        'thumburl_2': '',
      },
      {
        'appId': '133',
        'appName': 'Bible Word Search Puzzle',
        'appurl': 'https://apps.apple.com/app/id6739329590',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb133_1745313891.png',
        'thumburl_2': '',
      },
      {
        'appId': '143',
        'appName': 'KJV Bible',
        'appurl': 'https://apps.apple.com/app/id6461349171',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb143_1745499032.webp',
        'thumburl_2': '',
      },
      {
        'appId': '154',
        'appName': 'New Jerusalem Bible',
        'appurl': 'https://apps.apple.com/app/id6460890871',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb154_1745499573.webp',
        'thumburl_2': '',
      },
      {
        'appId': '163',
        'appName': 'Messianic Bible',
        'appurl': 'https://apps.apple.com/app/id6472878164',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb163_1745499221.webp',
        'thumburl_2': '',
      },
      {
        'appId': '170',
        'appName': 'Geneva Bible Pro',
        'appurl': 'https://apps.apple.com/app/id6478524481',
        'developed_by': 'MBX',
        'apptype': 'ios',
        'thumburl':
            'https://bibleoffice.com/BibleReplications/dev/v1/uploads/moreapp_img/moreapp_thumb_1745584375.png',
        'thumburl_2': '',
      },
    ];
  }
}
