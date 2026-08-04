class BibleInfo {
  static String apple_AppId = "6459794212";

  // 6484270584  //6459793603
  static String ios_Bundle_Id = "com.balaklrapps.newkingsjamesversion";
  static String bible_shortName = "NKJV Bible";
  static String current_Version = "1.0.115";
  static String android_Package_Name = "com.whitebibles.genevabible";
  static String appID = '03a0762a-ed0b-11ef-b28e-fa163e8c011b';
  //static int surveyAppId = 3;

//IAP
  static String sixMonthPlanid =
      'com.balaklrapps.newkingsjamesversion.sixmonthadsfree';
  static String oneYearPlanid =
      'com.balaklrapps.newkingsjamesversion.oneyearadsfree';
  static String twoYearPlanid =
      'com.balaklrapps.newkingsjamesversion.twoyearadsfree';
  static String lifeTimePlanid =
      'com.balaklrapps.newkingsjamesversion.lifetimeadsfree';
  static String subIdentifierTwoYear = twoYearPlanid;
  static String exitOfferPlanid =
      'com.balaklrapps.newkingsjamesversion.lifetime.exitoffer';

  // IAP Discounts (for offline mode)
  static String sixMonthPlanDiscount = '0';
  static String oneYearPlanDiscount = '30';
  static String twoYearPlanDiscount = '50';
  static String lifeTimePlanDiscount = 'Best Value';
  static String exitOfferPlanDiscount = '0';

  // Coin Pack IDs
  static String coinPack1Id =
      'com.balaklrapps.newkingsjamesversion.creditpack1';
  static String coinPack2Id =
      'com.balaklrapps.newkingsjamesversion.creditpack2';
  static String coinPack3Id =
      'com.balaklrapps.newkingsjamesversion.creditpack3';

  // Coin Pack Credits (for offline mode)
  static String coinPack1Credits = '500';
  static String coinPack2Credits = '1500';
  static String coinPack3Credits = '3000';

  // Coin Pack Discounts (for offline mode)
  static String coinPack1Discount = '0';
  static String coinPack2Discount = '30';
  static String coinPack3Discount = '50';

  // Coin Pack display prices (offline / IAP-load fallback)
  static String coinPack1Price = '\$0.99';
  static String coinPack2Price = '\$3.99';
  static String coinPack3Price = '\$6.99';

  static bool enableIAP = true;

  // enable-> true or disable-> false e-products here
  static bool enableEShop = false;

  // AD Enable - Set to true to enable ads, false to disable
  static bool enableAds = true;

  // LevelPlay App Key + Ad Unit IDs: fetched from API Network-1 fields
  // (see LevelPlayConfig). Do not hardcode here.

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
  static String adsGoogleBannerIdIos = "ca-app-pub-4194577750257069/3139244514";
  static String adsGoogleBannerId_2Ios = "";
  static String adsGoogleBannerId_3Ios = "";
  static String adsGoogleInterstitialIdIos =
      "ca-app-pub-4194577750257069/4647434167";
  static String adsGoogleRewardIdIos = "ca-app-pub-4194577750257069/5194562213";
  static String adsGoogleOpenAppIdIos =
      "ca-app-pub-4194577750257069/5080965858";
  static String adsGoogleNativeIdIos = "ca-app-pub-4194577750257069/5995854674";
  static String adsGoogleRewardInterstitialIdIos = "";

  // TEST Ads IDs - iOS
  // static String adsGoogleBannerIdIos = "ca-app-pub-4194577750257069~7649128990";
  // static String adsGoogleBannerId_2Ios =
  //     "ca-app-pub-4194577750257069/8207532192";
  // static String adsGoogleBannerId_3Ios =
  //     "ca-app-pub-4194577750257069/8207532192";
  // static String adsGoogleInterstitialIdIos =
  //     "ca-app-pub-4194577750257069/4182309663";
  // static String adsGoogleRewardIdIos = "ca-app-pub-4194577750257069/1556146326";
  // static String adsGoogleOpenAppIdIos =
  //     "ca-app-pub-4194577750257069/6029797702";
  // static String adsGoogleNativeIdIos = "ca-app-pub-4194577750257069/1528575170";
  // static String adsGoogleRewardInterstitialIdIos =
  //     "ca-app-pub-4194577750257069/8842883017";

// add folder names here  assets/zipped/
  static List<String> folders = [
    "NKJV",
    "catholic",
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
      "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/Portuguese/";
  static String audioBasePathType = "3";
  static String isShowMp3Audio = "1";

  // Text to Speech Settings - iOS
  static String isTextToSpeechAvailableIos = "1";
  static String textToSpeechLanguageCodeIos = "en-GB";
  static String textToSpeechIdentifierIos =
      "com.apple.ttsbundle.siri_male_en-GB_compact";

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

/// Unity LevelPlay placement names (must match dashboard exactly).
class AdPlacements {
  AdPlacements._();

  // Interstitial
  static const String chapterEndInterstitial = 'chapter_end_interstitial';
  static const String chapterBetweenInterstitial =
      'chapter_between_interstitial';
  static const String readingClickCountInterstitial =
      'reading_clickcount_interstitial';
  static const String wallpaperBetweenInterstitial =
      'wallpaper_between_interstitial';
  static const String wallpaperDownloadInterstitial =
      'wallpaper_download_interstitial';

  // Rewarded
  static const String wallpaperDownloadRewarded =
      'wallpaper_download_rewarded';
  static const String walletCreditRewarded = 'wallet_credit_rewarded';
}
