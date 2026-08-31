// // To parse this JSON data, do
// //
// //     final getAudioModel = getAudioModelFromJson(jsonString);

// import 'dart:convert';

// GetAudioModel getAudioModelFromJson(String str) =>
//     GetAudioModel.fromJson(json.decode(str));

// String getAudioModelToJson(GetAudioModel data) => json.encode(data.toJson());

// class GetAudioModel {
//   String? result;
//   Data? data;

//   GetAudioModel({
//     this.result,
//     this.data,
//   });

//   factory GetAudioModel.fromJson(Map<String, dynamic> json) => GetAudioModel(
//         result: json["result"],
//         data: json["data"] == null ? null : Data.fromJson(json["data"]),
//       );

//   Map<String, dynamic> toJson() => {
//         "result": result,
//         "data": data?.toJson(),
//       };
// }

// class Data {
//   String? pushAppid;
//   String? bibleCategoryId;
//   String? appName;
//   String? appTypeVersion;
//   String? isShowMp3Audio;
//   String? imageAppId;
//   String? quoteAppId;
//   String? videoAppId;
//   String? quizCatId;
//   String? wallpaperCatId;
//   String? verseEditorAppId;
//   String? shareappCode;
//   String? languageCode;
//   String? languageName;
//   String? bookAdsStatus;
//   String? bookAdsAppId;
//   String? shortLangCode;
//   String? appAudioBasepath;
//   String? appAudioBasepathType;
//   String? isMulticategoryAvailable;
//   String? isImageAvailable;
//   String? isQuoteAvailable;
//   String? isVideoAvailable;
//   String? feedbackEmail;
//   String? bibleFeatures;
//   String? showNativeAdsRow;
//   String? showInterstitialRow;
//   String? appShareappLink;
//   BibleAudioInfo? bibleAudioInfo;
//   CopyrightInfo? copyrightInfo;
//   String? appThemeColor;
//   String? appStatusThemeColor;
//   String? isSubscriptionEnabled;
//   String? subIdentifierOneyear;
//   String? subIdentifierLifetime;
//   String? subSharedsecret;
//   String? subIdentifierOnemonth;
//   String? subIdentifierThreeMonth;
//   String? subIdentifierSixMonth;
//   String? offerEnabled;
//   String? offerDays;
//   String? offerCount;
//   String? subIdentifierOneyearValue;
//   String? subIdentifierLifetimeValue;
//   String? subIdentifier1YearAutoRenewableValue;
//   String? subIdentifierOnemonthValue;
//   String? subIdentifierThreeMonthValue;
//   String? subIdentifierSixMonthValue;
//   List<SubField>? subFields;
//   CoinsData? coinsData;
//   Promotion? promotion;
//   String? isNotificationAvailable;
//   String? notificationTitle;
//   String? adsDuration;
//   String? adsType;
//   String? adsGoogleBannerIdAndroid;
//   String? adsGoogleInterstitialIdAndroid;
//   String? adsFacebookBannerIdAndroid;
//   String? adsFacebookInterstitialIdAndroid;
//   String? adsGoogleOpenAppIdAndroid;
//   String? adsGoogleNativeIdAndroid;
//   String? adsGoogleBannerIdIos;
//   String? adsGoogleInterstitialIdIos;
//   String? adsGoogleOpenAppIdIos;
//   String? adsGoogleNativeIdIos;
//   String? adsFacebookBannerIdIos;
//   String? adsFacebookInterstitialIdIos;
//   String? adsGoogleRewardIdIos;
//   String? adsGoogleRewardIdAndroid;
//   String? adsGoogleAppIdAndroid;
//   String? adsFacebookAppIdAndroid;
//   String? adsGoogleAppIdIos;
//   String? adsFacebookAppIdIos;
//   String? adsNetwork1Field1Android;
//   String? adsNetwork1Field2Android;
//   String? adsNetwork1Field3Android;
//   String? adsNetwork1Field4Android;
//   String? adsNetwork1Field5Android;
//   String? adsNetwork1Field6Android;
//   String? adsNetwork1Field1Ios;
//   String? adsNetwork1Field2Ios;
//   String? adsNetwork1Field3Ios;
//   String? adsNetwork1Field4Ios;
//   String? adsNetwork1Field5Ios;
//   String? adsNetwork1Field6Ios;
//   String? adsNetwork2Field1Android;
//   String? adsNetwork2Field2Android;
//   String? adsNetwork2Field3Android;
//   String? adsNetwork2Field4Android;
//   String? adsNetwork2Field5Android;
//   String? adsNetwork2Field6Android;
//   String? adsNetwork2Field1Ios;
//   String? adsNetwork2Field2Ios;
//   String? adsNetwork2Field3Ios;
//   String? adsNetwork2Field4Ios;
//   String? adsNetwork2Field5Ios;
//   String? adsNetwork2Field6Ios;
//   String? rewardedInterstitialAds;
//   String? nativeAds;
//   String? adsGoogleBannerId2Ios;
//   String? adsGoogleBannerId2Android;
//   String? adsGoogleBannerId3Ios;
//   String? adsGoogleBannerId3Android;
//   String? adsGoogleRewardInterstitialIdAndroid;
//   String? adsGoogleRewardInterstitialIdIos;
//   int? isSurveyEnabled;
//   int? surveyId;
//   Data({
//     this.pushAppid,
//     this.bibleCategoryId,
//     this.appName,
//     this.appTypeVersion,
//     this.isShowMp3Audio,
//     this.imageAppId,
//     this.quoteAppId,
//     this.videoAppId,
//     this.quizCatId,
//     this.wallpaperCatId,
//     this.verseEditorAppId,
//     this.shareappCode,
//     this.languageCode,
//     this.languageName,
//     this.bookAdsStatus,
//     this.bookAdsAppId,
//     this.shortLangCode,
//     this.appAudioBasepath,
//     this.appAudioBasepathType,
//     this.isMulticategoryAvailable,
//     this.isImageAvailable,
//     this.isQuoteAvailable,
//     this.isVideoAvailable,
//     this.feedbackEmail,
//     this.bibleFeatures,
//     this.showNativeAdsRow,
//     this.showInterstitialRow,
//     this.appShareappLink,
//     this.bibleAudioInfo,
//     this.copyrightInfo,
//     this.appThemeColor,
//     this.appStatusThemeColor,
//     this.isSubscriptionEnabled,
//     this.subIdentifierOneyear,
//     this.subIdentifierLifetime,
//     this.subSharedsecret,
//     this.subIdentifierOnemonth,
//     this.subIdentifierThreeMonth,
//     this.subIdentifierSixMonth,
//     this.offerEnabled,
//     this.offerDays,
//     this.offerCount,
//     this.subIdentifierOneyearValue,
//     this.subIdentifierLifetimeValue,
//     this.subIdentifier1YearAutoRenewableValue,
//     this.subIdentifierOnemonthValue,
//     this.subIdentifierThreeMonthValue,
//     this.subIdentifierSixMonthValue,
//     this.subFields,
//     this.coinsData,
//     this.promotion,
//     this.isNotificationAvailable,
//     this.notificationTitle,
//     this.adsDuration,
//     this.adsType,
//     this.adsGoogleBannerIdAndroid,
//     this.adsGoogleInterstitialIdAndroid,
//     this.adsFacebookBannerIdAndroid,
//     this.adsFacebookInterstitialIdAndroid,
//     this.adsGoogleOpenAppIdAndroid,
//     this.adsGoogleNativeIdAndroid,
//     this.adsGoogleBannerIdIos,
//     this.adsGoogleInterstitialIdIos,
//     this.adsGoogleOpenAppIdIos,
//     this.adsGoogleNativeIdIos,
//     this.adsFacebookBannerIdIos,
//     this.adsFacebookInterstitialIdIos,
//     this.adsGoogleRewardIdIos,
//     this.adsGoogleRewardIdAndroid,
//     this.adsGoogleAppIdAndroid,
//     this.adsFacebookAppIdAndroid,
//     this.adsGoogleAppIdIos,
//     this.adsFacebookAppIdIos,
//     this.adsNetwork1Field1Android,
//     this.adsNetwork1Field2Android,
//     this.adsNetwork1Field3Android,
//     this.adsNetwork1Field4Android,
//     this.adsNetwork1Field5Android,
//     this.adsNetwork1Field6Android,
//     this.adsNetwork1Field1Ios,
//     this.adsNetwork1Field2Ios,
//     this.adsNetwork1Field3Ios,
//     this.adsNetwork1Field4Ios,
//     this.adsNetwork1Field5Ios,
//     this.adsNetwork1Field6Ios,
//     this.adsNetwork2Field1Android,
//     this.adsNetwork2Field2Android,
//     this.adsNetwork2Field3Android,
//     this.adsNetwork2Field4Android,
//     this.adsNetwork2Field5Android,
//     this.adsNetwork2Field6Android,
//     this.adsNetwork2Field1Ios,
//     this.adsNetwork2Field2Ios,
//     this.adsNetwork2Field3Ios,
//     this.adsNetwork2Field4Ios,
//     this.adsNetwork2Field5Ios,
//     this.adsNetwork2Field6Ios,
//     this.rewardedInterstitialAds,
//     this.nativeAds,
//     this.adsGoogleBannerId2Ios,
//     this.adsGoogleBannerId2Android,
//     this.adsGoogleBannerId3Ios,
//     this.adsGoogleBannerId3Android,
//     this.adsGoogleRewardInterstitialIdAndroid,
//     this.adsGoogleRewardInterstitialIdIos,
//     this.isSurveyEnabled,
//     this.surveyId,
//   });

//   factory Data.fromJson(Map<String, dynamic> json) => Data(
//         pushAppid: json["push_appid"],
//         bibleCategoryId: json["bibleCategoryId"],
//         appName: json["app_name"],
//         appTypeVersion: json["app_type_version"],
//         isShowMp3Audio: json["is_show_MP3_Audio"],
//         imageAppId: json["image_app_id"],
//         quoteAppId: json["quote_app_id"],
//         videoAppId: json["video_app_id"],
//         quizCatId: json["quiz_cat_id"],
//         wallpaperCatId: json["wallpaper_cat_id"],
//         verseEditorAppId: json["verse_editor_app_id"],
//         shareappCode: json["shareapp_code"],
//         languageCode: json["language_code"],
//         languageName: json["language_name"],
//         bookAdsStatus: json["book_ads_status"],
//         bookAdsAppId: json["book_ads_app_id"],
//         shortLangCode: json["short_lang_code"],
//         appAudioBasepath: json["app_Audio_Basepath"],
//         appAudioBasepathType: json["app_Audio_Basepath_Type"],
//         isMulticategoryAvailable: json["is_multicategory_available"],
//         isImageAvailable: json["is_image_available"],
//         isQuoteAvailable: json["is_quote_available"],
//         isVideoAvailable: json["is_video_available"],
//         feedbackEmail: json["feedback_email"],
//         bibleFeatures: json["bible_features"],
//         showNativeAdsRow: json["show_native_ads_row"],
//         showInterstitialRow: json["show_interstitial_row"],
//         appShareappLink: json["app_shareapp_link"],
//         bibleAudioInfo: json["bible_audio_info"] == null
//             ? null
//             : BibleAudioInfo.fromJson(json["bible_audio_info"]),
//         copyrightInfo: json["copyright_info"] == null
//             ? null
//             : CopyrightInfo.fromJson(json["copyright_info"]),
//         appThemeColor: json["app_theme_color"],
//         appStatusThemeColor: json["app_status_theme_color"],
//         isSubscriptionEnabled: json["is_subscription_enabled"],
//         subIdentifierOneyear: json["sub_identifier_oneyear"],
//         subIdentifierLifetime: json["sub_identifier_lifetime"],
//         subSharedsecret: json["sub_sharedsecret"],
//         subIdentifierOnemonth: json["sub_identifier_onemonth"],
//         subIdentifierThreeMonth: json["sub_identifier_three_month"],
//         subIdentifierSixMonth: json["sub_identifier_six_month"],
//         offerEnabled: json["offer_enabled"],
//         offerDays: json["offer_days"]?.toString(),
//         offerCount: json["offer_count"]?.toString(),
//         subIdentifierOneyearValue: json["sub_identifier_oneyear_value"],
//         subIdentifierLifetimeValue: json["sub_identifier_lifetime_value"],
//         subIdentifier1YearAutoRenewableValue:
//             json["sub_identifier_1_year_auto_renewable_value"],
//         subIdentifierOnemonthValue: json["sub_identifier_onemonth_value"],
//         subIdentifierThreeMonthValue: json["sub_identifier_three_month_value"],
//         subIdentifierSixMonthValue: json["sub_identifier_six_month_value"],
//         subFields: json["sub_fields"] == null
//             ? []
//             : List<SubField>.from(
//                 json["sub_fields"]!.map((x) => SubField.fromJson(x))),
//         coinsData: json["coins_data"] == null
//             ? null
//             : CoinsData.fromJson(json["coins_data"]),
//         promotion: json["promotion"] == null
//             ? null
//             : Promotion.fromJson(json["promotion"]),
//         isNotificationAvailable: json["is_notification_available"],
//         notificationTitle: json["notification_title"],
//         adsDuration: json["ads_duration"],
//         adsType: json["ads_Type"],
//         adsGoogleBannerIdAndroid: json["ads_google_banner_id_android"],
//         adsGoogleInterstitialIdAndroid:
//             json["ads_google_interstitial_id_android"],
//         adsFacebookBannerIdAndroid: json["ads_facebook_banner_id_android"],
//         adsFacebookInterstitialIdAndroid:
//             json["ads_facebook_interstitial_id_android"],
//         adsGoogleOpenAppIdAndroid: json["ads_google_openApp_id_android"],
//         adsGoogleNativeIdAndroid: json["ads_google_native_id_android"],
//         adsGoogleBannerIdIos: json["ads_google_banner_id_ios"],
//         adsGoogleInterstitialIdIos: json["ads_google_interstitial_id_ios"],
//         adsGoogleOpenAppIdIos: json["ads_google_openApp_id_ios"],
//         adsGoogleNativeIdIos: json["ads_google_native_id_ios"],
//         adsFacebookBannerIdIos: json["ads_facebook_banner_id_ios"],
//         adsFacebookInterstitialIdIos: json["ads_facebook_interstitial_id_ios"],
//         adsGoogleRewardIdIos: json["ads_google_reward_id_ios"],
//         adsGoogleRewardIdAndroid: json["ads_google_reward_id_android"],
//         adsGoogleAppIdAndroid: json["ads_google_app_id_android"],
//         adsFacebookAppIdAndroid: json["ads_facebook_app_id_android"],
//         adsGoogleAppIdIos: json["ads_google_app_id_ios"],
//         adsFacebookAppIdIos: json["ads_facebook_app_id_ios"],
//         adsNetwork1Field1Android: json["ads_network_1_field_1_android"],
//         adsNetwork1Field2Android: json["ads_network_1_field_2_android"],
//         adsNetwork1Field3Android: json["ads_network_1_field_3_android"],
//         adsNetwork1Field4Android: json["ads_network_1_field_4_android"],
//         adsNetwork1Field5Android: json["ads_network_1_field_5_android"],
//         adsNetwork1Field6Android: json["ads_network_1_field_6_android"],
//         adsNetwork1Field1Ios: json["ads_network_1_field_1_ios"],
//         adsNetwork1Field2Ios: json["ads_network_1_field_2_ios"],
//         adsNetwork1Field3Ios: json["ads_network_1_field_3_ios"],
//         adsNetwork1Field4Ios: json["ads_network_1_field_4_ios"],
//         adsNetwork1Field5Ios: json["ads_network_1_field_5_ios"],
//         adsNetwork1Field6Ios: json["ads_network_1_field_6_ios"],
//         adsNetwork2Field1Android: json["ads_network_2_field_1_android"],
//         adsNetwork2Field2Android: json["ads_network_2_field_2_android"],
//         adsNetwork2Field3Android: json["ads_network_2_field_3_android"],
//         adsNetwork2Field4Android: json["ads_network_2_field_4_android"],
//         adsNetwork2Field5Android: json["ads_network_2_field_5_android"],
//         adsNetwork2Field6Android: json["ads_network_2_field_6_android"],
//         adsNetwork2Field1Ios: json["ads_network_2_field_1_ios"],
//         adsNetwork2Field2Ios: json["ads_network_2_field_2_ios"],
//         adsNetwork2Field3Ios: json["ads_network_2_field_3_ios"],
//         adsNetwork2Field4Ios: json["ads_network_2_field_4_ios"],
//         adsNetwork2Field5Ios: json["ads_network_2_field_5_ios"],
//         adsNetwork2Field6Ios: json["ads_network_2_field_6_ios"],
//         rewardedInterstitialAds: json["rewarded_interstitial_ads"],
//         nativeAds: json["native_ads"],
//         adsGoogleBannerId2Ios: json["ads_google_banner_id_2_ios"],
//         adsGoogleBannerId2Android: json["ads_google_banner_id_2_android"],
//         adsGoogleBannerId3Ios: json["ads_google_banner_id_3_ios"],
//         adsGoogleBannerId3Android: json["ads_google_banner_id_3_android"],
//         adsGoogleRewardInterstitialIdAndroid:
//             json["ads_google_reward_interstitial_id_android"],
//         adsGoogleRewardInterstitialIdIos:
//             json["ads_google_reward_interstitial_id_ios"],
//         isSurveyEnabled:
//             int.tryParse(json["is_survey_enabled"]?.toString() ?? ''),
//         surveyId: int.tryParse(json["survey_id"]?.toString() ?? ''),
//       );

//   Map<String, dynamic> toJson() => {
//         "push_appid": pushAppid,
//         "bibleCategoryId": bibleCategoryId,
//         "app_name": appName,
//         "app_type_version": appTypeVersion,
//         "is_show_MP3_Audio": isShowMp3Audio,
//         "image_app_id": imageAppId,
//         "quote_app_id": quoteAppId,
//         "video_app_id": videoAppId,
//         "quiz_cat_id": quizCatId,
//         "wallpaper_cat_id": wallpaperCatId,
//         "verse_editor_app_id": verseEditorAppId,
//         "shareapp_code": shareappCode,
//         "language_code": languageCode,
//         "language_name": languageName,
//         "book_ads_status": bookAdsStatus,
//         "book_ads_app_id": bookAdsAppId,
//         "short_lang_code": shortLangCode,
//         "app_Audio_Basepath": appAudioBasepath,
//         "app_Audio_Basepath_Type": appAudioBasepathType,
//         "is_multicategory_available": isMulticategoryAvailable,
//         "is_image_available": isImageAvailable,
//         "is_quote_available": isQuoteAvailable,
//         "is_video_available": isVideoAvailable,
//         "feedback_email": feedbackEmail,
//         "bible_features": bibleFeatures,
//         "show_native_ads_row": showNativeAdsRow,
//         "show_interstitial_row": showInterstitialRow,
//         "app_shareapp_link": appShareappLink,
//         "bible_audio_info": bibleAudioInfo?.toJson(),
//         "copyright_info": copyrightInfo?.toJson(),
//         "app_theme_color": appThemeColor,
//         "app_status_theme_color": appStatusThemeColor,
//         "is_subscription_enabled": isSubscriptionEnabled,
//         "sub_identifier_oneyear": subIdentifierOneyear,
//         "sub_identifier_lifetime": subIdentifierLifetime,
//         "sub_sharedsecret": subSharedsecret,
//         "sub_identifier_onemonth": subIdentifierOnemonth,
//         "sub_identifier_three_month": subIdentifierThreeMonth,
//         "sub_identifier_six_month": subIdentifierSixMonth,
//         "offer_enabled": offerEnabled,
//         "offer_days": offerDays,
//         "offer_count": offerCount,
//         "sub_identifier_oneyear_value": subIdentifierOneyearValue,
//         "sub_identifier_lifetime_value": subIdentifierLifetimeValue,
//         "sub_identifier_1_year_auto_renewable_value":
//             subIdentifier1YearAutoRenewableValue,
//         "sub_identifier_onemonth_value": subIdentifierOnemonthValue,
//         "sub_identifier_three_month_value": subIdentifierThreeMonthValue,
//         "sub_identifier_six_month_value": subIdentifierSixMonthValue,
//         "sub_fields": subFields == null
//             ? []
//             : List<dynamic>.from(subFields!.map((x) => x.toJson())),
//         "coins_data": coinsData?.toJson(),
//         "promotion": promotion?.toJson(),
//         "is_notification_available": isNotificationAvailable,
//         "notification_title": notificationTitle,
//         "ads_duration": adsDuration,
//         "ads_Type": adsType,
//         "ads_google_banner_id_android": adsGoogleBannerIdAndroid,
//         "ads_google_interstitial_id_android": adsGoogleInterstitialIdAndroid,
//         "ads_facebook_banner_id_android": adsFacebookBannerIdAndroid,
//         "ads_facebook_interstitial_id_android":
//             adsFacebookInterstitialIdAndroid,
//         "ads_google_openApp_id_android": adsGoogleOpenAppIdAndroid,
//         "ads_google_native_id_android": adsGoogleNativeIdAndroid,
//         "ads_google_banner_id_ios": adsGoogleBannerIdIos,
//         "ads_google_interstitial_id_ios": adsGoogleInterstitialIdIos,
//         "ads_google_openApp_id_ios": adsGoogleOpenAppIdIos,
//         "ads_google_native_id_ios": adsGoogleNativeIdIos,
//         "ads_facebook_banner_id_ios": adsFacebookBannerIdIos,
//         "ads_facebook_interstitial_id_ios": adsFacebookInterstitialIdIos,
//         "ads_google_reward_id_ios": adsGoogleRewardIdIos,
//         "ads_google_reward_id_android": adsGoogleRewardIdAndroid,
//         "ads_google_app_id_android": adsGoogleAppIdAndroid,
//         "ads_facebook_app_id_android": adsFacebookAppIdAndroid,
//         "ads_google_app_id_ios": adsGoogleAppIdIos,
//         "ads_facebook_app_id_ios": adsFacebookAppIdIos,
//         "ads_network_1_field_1_android": adsNetwork1Field1Android,
//         "ads_network_1_field_2_android": adsNetwork1Field2Android,
//         "ads_network_1_field_3_android": adsNetwork1Field3Android,
//         "ads_network_1_field_4_android": adsNetwork1Field4Android,
//         "ads_network_1_field_5_android": adsNetwork1Field5Android,
//         "ads_network_1_field_6_android": adsNetwork1Field6Android,
//         "ads_network_1_field_1_ios": adsNetwork1Field1Ios,
//         "ads_network_1_field_2_ios": adsNetwork1Field2Ios,
//         "ads_network_1_field_3_ios": adsNetwork1Field3Ios,
//         "ads_network_1_field_4_ios": adsNetwork1Field4Ios,
//         "ads_network_1_field_5_ios": adsNetwork1Field5Ios,
//         "ads_network_1_field_6_ios": adsNetwork1Field6Ios,
//         "ads_network_2_field_1_android": adsNetwork2Field1Android,
//         "ads_network_2_field_2_android": adsNetwork2Field2Android,
//         "ads_network_2_field_3_android": adsNetwork2Field3Android,
//         "ads_network_2_field_4_android": adsNetwork2Field4Android,
//         "ads_network_2_field_5_android": adsNetwork2Field5Android,
//         "ads_network_2_field_6_android": adsNetwork2Field6Android,
//         "ads_network_2_field_1_ios": adsNetwork2Field1Ios,
//         "ads_network_2_field_2_ios": adsNetwork2Field2Ios,
//         "ads_network_2_field_3_ios": adsNetwork2Field3Ios,
//         "ads_network_2_field_4_ios": adsNetwork2Field4Ios,
//         "ads_network_2_field_5_ios": adsNetwork2Field5Ios,
//         "ads_network_2_field_6_ios": adsNetwork2Field6Ios,
//         "rewarded_interstitial_ads": rewardedInterstitialAds,
//         "native_ads": nativeAds,
//         "ads_google_banner_id_2_ios": adsGoogleBannerId2Ios,
//         "ads_google_banner_id_2_android": adsGoogleBannerId2Android,
//         "ads_google_banner_id_3_ios": adsGoogleBannerId3Ios,
//         "ads_google_banner_id_3_android": adsGoogleBannerId3Android,
//         "ads_google_reward_interstitial_id_android":
//             adsGoogleRewardInterstitialIdAndroid,
//         "ads_google_reward_interstitial_id_ios":
//             adsGoogleRewardInterstitialIdIos,
//         "is_survey_enabled": isSurveyEnabled,
//         "survey_id": surveyId,
//       };
// }

// class BibleAudioInfo {
//   String? isShowMp3Audio;
//   String? audioBasepath;
//   String? audioBasepathType;
//   String? isTextToSpeechAvailableIos;
//   String? textToSpeechLanguageCodeIos;
//   String? textToSpeechIdentifierIos;
//   String? isTextToSpeechAvailableAndroid;
//   String? textToSpeechLanguageCodeAndroid;

//   BibleAudioInfo({
//     this.isShowMp3Audio,
//     this.audioBasepath,
//     this.audioBasepathType,
//     this.isTextToSpeechAvailableIos,
//     this.textToSpeechLanguageCodeIos,
//     this.textToSpeechIdentifierIos,
//     this.isTextToSpeechAvailableAndroid,
//     this.textToSpeechLanguageCodeAndroid,
//   });

//   factory BibleAudioInfo.fromJson(Map<String, dynamic> json) => BibleAudioInfo(
//         isShowMp3Audio: json["is_show_mp3_audio"],
//         audioBasepath: json["audio_basepath"],
//         audioBasepathType: json["audio_basepath_type"],
//         isTextToSpeechAvailableIos: json["is_text_to_speech_available_ios"],
//         textToSpeechLanguageCodeIos: json["text_to_speech_language_code_ios"],
//         textToSpeechIdentifierIos: json["text_to_speech_identifier_ios"],
//         isTextToSpeechAvailableAndroid:
//             json["is_text_to_speech_available_android"],
//         textToSpeechLanguageCodeAndroid:
//             json["text_to_speech_language_code_android"],
//       );

//   Map<String, dynamic> toJson() => {
//         "is_show_mp3_audio": isShowMp3Audio,
//         "audio_basepath": audioBasepath,
//         "audio_basepath_type": audioBasepathType,
//         "is_text_to_speech_available_ios": isTextToSpeechAvailableIos,
//         "text_to_speech_language_code_ios": textToSpeechLanguageCodeIos,
//         "text_to_speech_identifier_ios": textToSpeechIdentifierIos,
//         "is_text_to_speech_available_android": isTextToSpeechAvailableAndroid,
//         "text_to_speech_language_code_android": textToSpeechLanguageCodeAndroid,
//       };
// }

// class CoinsData {
//   String? hint;
//   String? viewAnswer;
//   String? the5050;
//   String? tryAgain;
//   String? share;
//   String? timeWait;

//   CoinsData({
//     this.hint,
//     this.viewAnswer,
//     this.the5050,
//     this.tryAgain,
//     this.share,
//     this.timeWait,
//   });

//   factory CoinsData.fromJson(Map<String, dynamic> json) => CoinsData(
//         hint: json["hint"],
//         viewAnswer: json["view_answer"],
//         the5050: json["50_50"],
//         tryAgain: json["try_again"],
//         share: json["share"],
//         timeWait: json["time_wait"],
//       );

//   Map<String, dynamic> toJson() => {
//         "hint": hint,
//         "view_answer": viewAnswer,
//         "50_50": the5050,
//         "try_again": tryAgain,
//         "share": share,
//         "time_wait": timeWait,
//       };
// }

// class CopyrightInfo {
//   String? copyrightName;
//   String? copyrightUrl;

//   CopyrightInfo({
//     this.copyrightName,
//     this.copyrightUrl,
//   });

//   factory CopyrightInfo.fromJson(Map<String, dynamic> json) => CopyrightInfo(
//         copyrightName: json["copyright_name"],
//         copyrightUrl: json["copyright_url"],
//       );

//   Map<String, dynamic> toJson() => {
//         "copyright_name": copyrightName,
//         "copyright_url": copyrightUrl,
//       };
// }

// class Promotion {
//   String? promotionEnable;
//   String? proImgUrl;
//   String? proButtonUrl;
//   String? startTime;
//   String? endTime;

//   Promotion({
//     this.promotionEnable,
//     this.proImgUrl,
//     this.proButtonUrl,
//     this.startTime,
//     this.endTime,
//   });

//   factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
//         promotionEnable: json["promotion_enable"],
//         proImgUrl: json["pro_img_url"],
//         proButtonUrl: json["pro_button_url"],
//         startTime: json["start_time"],
//         endTime: json["end_time"],
//       );

//   Map<String, dynamic> toJson() => {
//         "promotion_enable": promotionEnable,
//         "pro_img_url": proImgUrl,
//         "pro_button_url": proButtonUrl,
//         "start_time": startTime,
//         "end_time": endTime,
//       };
// }

// class SubField {
//   String? fieldNum;
//   String? identifier;
//   String? item1;
//   String? item2;
//   String? value;

//   SubField({
//     this.fieldNum,
//     this.identifier,
//     this.item1,
//     this.item2,
//     this.value,
//   });

//   factory SubField.fromJson(Map<String, dynamic> json) => SubField(
//         fieldNum: json["field_num"],
//         identifier: json["identifier"],
//         item1: json["item_1"],
//         item2: json["item_2"],
//         value: json["value"],
//       );

//   Map<String, dynamic> toJson() => {
//         "field_num": fieldNum,
//         "identifier": identifier,
//         "item_1": item1,
//         "item_2": item2,
//         "value": value,
//       };
// }

///
/// Code generated by jsonToDartModel https://ashamp.github.io/jsonToDartModel/
///
class GetAudioModelDataPromotion {
/*
{
  "promotion_enable": "0",
  "pro_img_url": "https://axeraan.com/axeraan_fw/site_dashboard/uploads/portfolio_slider_img/Web_1366_%E2%80%93_27.png",
  "pro_button_url": "https://bibleoffice.com/",
  "start_time": "",
  "end_time": ""
} 
*/

  String? promotionEnable;
  String? proImgUrl;
  String? proButtonUrl;
  String? startTime;
  String? endTime;

  GetAudioModelDataPromotion({
    this.promotionEnable,
    this.proImgUrl,
    this.proButtonUrl,
    this.startTime,
    this.endTime,
  });
  GetAudioModelDataPromotion.fromJson(Map<String, dynamic> json) {
    promotionEnable = json['promotion_enable']?.toString();
    proImgUrl = json['pro_img_url']?.toString();
    proButtonUrl = json['pro_button_url']?.toString();
    startTime = json['start_time']?.toString();
    endTime = json['end_time']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['promotion_enable'] = promotionEnable;
    data['pro_img_url'] = proImgUrl;
    data['pro_button_url'] = proButtonUrl;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    return data;
  }
}

class GetAudioModelDataCoinsData {
/*
{
  "hint": "",
  "view_answer": "",
  "50_50": "",
  "try_again": "",
  "share": "",
  "time_wait": ""
} 
*/

  String? hint;
  String? viewAnswer;
  String? the50_50;
  String? tryAgain;
  String? share;
  String? timeWait;

  GetAudioModelDataCoinsData({
    this.hint,
    this.viewAnswer,
    this.the50_50,
    this.tryAgain,
    this.share,
    this.timeWait,
  });
  GetAudioModelDataCoinsData.fromJson(Map<String, dynamic> json) {
    hint = json['hint']?.toString();
    viewAnswer = json['view_answer']?.toString();
    the50_50 = json['50_50']?.toString();
    tryAgain = json['try_again']?.toString();
    share = json['share']?.toString();
    timeWait = json['time_wait']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['hint'] = hint;
    data['view_answer'] = viewAnswer;
    data['50_50'] = the50_50;
    data['try_again'] = tryAgain;
    data['share'] = share;
    data['time_wait'] = timeWait;
    return data;
  }
}

class GetAudioModelDataSubFields {
/*
{
  "field_num": "0",
  "identifier": "",
  "item_1": "",
  "item_2": "",
  "value": ""
} 
*/

  String? fieldNum;
  String? identifier;
  String? item_1;
  String? item_2;
  String? value;

  GetAudioModelDataSubFields({
    this.fieldNum,
    this.identifier,
    this.item_1,
    this.item_2,
    this.value,
  });
  GetAudioModelDataSubFields.fromJson(Map<String, dynamic> json) {
    fieldNum = json['field_num']?.toString();
    identifier = json['identifier']?.toString();
    item_1 = json['item_1']?.toString();
    item_2 = json['item_2']?.toString();
    value = json['value']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['field_num'] = fieldNum;
    data['identifier'] = identifier;
    data['item_1'] = item_1;
    data['item_2'] = item_2;
    data['value'] = value;
    return data;
  }
}

class GetAudioModelDataCopyrightInfo {
/*
{
  "copyright_name": "",
  "copyright_url": "https://bibleoffice.com/"
} 
*/

  String? copyrightName;
  String? copyrightUrl;

  GetAudioModelDataCopyrightInfo({
    this.copyrightName,
    this.copyrightUrl,
  });
  GetAudioModelDataCopyrightInfo.fromJson(Map<String, dynamic> json) {
    copyrightName = json['copyright_name']?.toString();
    copyrightUrl = json['copyright_url']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['copyright_name'] = copyrightName;
    data['copyright_url'] = copyrightUrl;
    return data;
  }
}

class GetAudioModelDataBibleAudioInfo {
/*
{
  "is_show_mp3_audio": "1",
  "audio_basepath": "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/",
  "audio_basepath_type": "3",
  "is_text_to_speech_available_ios": "0",
  "text_to_speech_language_code_ios": "",
  "text_to_speech_identifier_ios": "",
  "is_text_to_speech_available_android": "0",
  "text_to_speech_language_code_android": ""
} 
*/

  String? isShowMp3Audio;
  String? audioBasepath;
  String? audioBasepathType;
  String? isTextToSpeechAvailableIos;
  String? textToSpeechLanguageCodeIos;
  String? textToSpeechIdentifierIos;
  String? isTextToSpeechAvailableAndroid;
  String? textToSpeechLanguageCodeAndroid;

  GetAudioModelDataBibleAudioInfo({
    this.isShowMp3Audio,
    this.audioBasepath,
    this.audioBasepathType,
    this.isTextToSpeechAvailableIos,
    this.textToSpeechLanguageCodeIos,
    this.textToSpeechIdentifierIos,
    this.isTextToSpeechAvailableAndroid,
    this.textToSpeechLanguageCodeAndroid,
  });
  GetAudioModelDataBibleAudioInfo.fromJson(Map<String, dynamic> json) {
    isShowMp3Audio = json['is_show_mp3_audio']?.toString();
    audioBasepath = json['audio_basepath']?.toString();
    audioBasepathType = json['audio_basepath_type']?.toString();
    isTextToSpeechAvailableIos =
        json['is_text_to_speech_available_ios']?.toString();
    textToSpeechLanguageCodeIos =
        json['text_to_speech_language_code_ios']?.toString();
    textToSpeechIdentifierIos =
        json['text_to_speech_identifier_ios']?.toString();
    isTextToSpeechAvailableAndroid =
        json['is_text_to_speech_available_android']?.toString();
    textToSpeechLanguageCodeAndroid =
        json['text_to_speech_language_code_android']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['is_show_mp3_audio'] = isShowMp3Audio;
    data['audio_basepath'] = audioBasepath;
    data['audio_basepath_type'] = audioBasepathType;
    data['is_text_to_speech_available_ios'] = isTextToSpeechAvailableIos;
    data['text_to_speech_language_code_ios'] = textToSpeechLanguageCodeIos;
    data['text_to_speech_identifier_ios'] = textToSpeechIdentifierIos;
    data['is_text_to_speech_available_android'] =
        isTextToSpeechAvailableAndroid;
    data['text_to_speech_language_code_android'] =
        textToSpeechLanguageCodeAndroid;
    return data;
  }
}

class GetAudioModelData {
/*
{
  "push_appid": "138",
  "bibleCategoryId": "138",
  "app_name": "Amplified_Bible_Flutter",
  "app_type_version": "Smart",
  "is_show_MP3_Audio": "1",
  "image_app_id": "322",
  "quote_app_id": "8",
  "video_app_id": "104",
  "quiz_cat_id": "174",
  "wallpaper_cat_id": "177",
  "verse_editor_app_id": "317",
  "shareapp_code": "aede982",
  "language_code": "",
  "language_name": "",
  "book_ads_status": "1",
  "book_ads_app_id": "6",
  "survey_enable": "1",
  "book_ads_cat_id": "16",
  "survey_app_id": "3",
  "short_lang_code": "",
  "app_Audio_Basepath": "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/",
  "app_Audio_Basepath_Type": "3",
  "is_multicategory_available": "1",
  "is_image_available": "1",
  "is_quote_available": "1",
  "is_video_available": "0",
  "feedback_email": "feedback@bibleoffice.com",
  "bible_features": "User-friendly interface and quick access to books,chapters and verses.@@@@@A Beautiful Reading and Listening Experience@@@@@Create and Share Inspirational Bible Art",
  "show_native_ads_row": "20",
  "show_interstitial_row": "10",
  "app_shareapp_link": "https://bibleoffice.com/aede982",
  "bible_audio_info": {
    "is_show_mp3_audio": "1",
    "audio_basepath": "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/",
    "audio_basepath_type": "3",
    "is_text_to_speech_available_ios": "0",
    "text_to_speech_language_code_ios": "",
    "text_to_speech_identifier_ios": "",
    "is_text_to_speech_available_android": "0",
    "text_to_speech_language_code_android": ""
  },
  "copyright_info": {
    "copyright_name": "",
    "copyright_url": "https://bibleoffice.com/"
  },
  "app_theme_color": "#31419E",
  "app_status_theme_color": "#7583D1",
  "is_subscription_enabled": "1",
  "sub_identifier_oneyear": "com.balaklrapps.amplifiedbible.oneyearadsfree",
  "sub_identifier_lifetime": "com.balaklrapps.amplifiedbible.lifetimeadsfree",
  "sub_sharedsecret": "ccd8c651502d42afa0b390e0f8e48f79",
  "sub_identifier_onemonth": "",
  "sub_identifier_three_month": "",
  "sub_identifier_six_month": "com.balaklrapps.amplifiedbible.sixmonthadsfree",
  "offer_enabled": "1",
  "offer_days": 20,
  "offer_count": 200,
  "sub_identifier_oneyear_value": "50",
  "sub_identifier_lifetime_value": "80",
  "sub_identifier_1_year_auto_renewable_value": "",
  "sub_identifier_onemonth_value": "",
  "sub_identifier_three_month_value": "",
  "sub_identifier_six_month_value": "",
  "sub_fields": [
    {
      "field_num": "0",
      "identifier": "",
      "item_1": "",
      "item_2": "",
      "value": ""
    }
  ],
  "coins_data": {
    "hint": "",
    "view_answer": "",
    "50_50": "",
    "try_again": "",
    "share": "",
    "time_wait": ""
  },
  "promotion": {
    "promotion_enable": "0",
    "pro_img_url": "https://axeraan.com/axeraan_fw/site_dashboard/uploads/portfolio_slider_img/Web_1366_%E2%80%93_27.png",
    "pro_button_url": "https://bibleoffice.com/",
    "start_time": "",
    "end_time": ""
  },
  "is_notification_available": "1",
  "notification_title": "Verse of the Day",
  "ads_duration": "3",
  "ads_Type": "5",
  "ads_google_banner_id_android": "",
  "ads_google_interstitial_id_android": "",
  "ads_facebook_banner_id_android": "",
  "ads_facebook_interstitial_id_android": "",
  "ads_google_openApp_id_android": "",
  "ads_google_native_id_android": "",
  "ads_google_banner_id_ios": "ca-app-pub-4194577750257069/3829303484",
  "ads_google_interstitial_id_ios": "ca-app-pub-4194577750257069/8121554676",
  "ads_google_openApp_id_ios": "ca-app-pub-4194577750257069/6808473007",
  "ads_google_native_id_ios": "ca-app-pub-4194577750257069/5043409277",
  "ads_facebook_banner_id_ios": "",
  "ads_facebook_interstitial_id_ios": "",
  "ads_google_reward_id_ios": "ca-app-pub-4194577750257069/3146777206",
  "ads_google_reward_id_android": "",
  "ads_google_app_id_android": "",
  "ads_facebook_app_id_android": "",
  "ads_google_app_id_ios": "ca-app-pub-4194577750257069~9442429107",
  "ads_facebook_app_id_ios": "",
  "ads_network_1_field_1_android": "",
  "ads_network_1_field_2_android": "",
  "ads_network_1_field_3_android": "",
  "ads_network_1_field_4_android": "",
  "ads_network_1_field_5_android": "",
  "ads_network_1_field_6_android": "",
  "ads_network_1_field_1_ios": "",
  "ads_network_1_field_2_ios": "",
  "ads_network_1_field_3_ios": "",
  "ads_network_1_field_4_ios": "",
  "ads_network_1_field_5_ios": "",
  "ads_network_1_field_6_ios": "",
  "ads_network_2_field_1_android": "",
  "ads_network_2_field_2_android": "",
  "ads_network_2_field_3_android": "",
  "ads_network_2_field_4_android": "",
  "ads_network_2_field_5_android": "",
  "ads_network_2_field_6_android": "",
  "ads_network_2_field_1_ios": "",
  "ads_network_2_field_2_ios": "",
  "ads_network_2_field_3_ios": "",
  "ads_network_2_field_4_ios": "",
  "ads_network_2_field_5_ios": "",
  "ads_network_2_field_6_ios": "",
  "rewarded_interstitial_ads": "",
  "native_ads": "",
  "ads_google_banner_id_2_ios": "ca-app-pub-4194577750257069/3829303484",
  "ads_google_banner_id_2_android": "",
  "ads_google_banner_id_3_ios": "ca-app-pub-4194577750257069/3829303484",
  "ads_google_banner_id_3_android": "",
  "ads_google_reward_interstitial_id_android": "",
  "ads_google_reward_interstitial_id_ios": "ca-app-pub-4194577750257069/5165864053"
} 
*/

  String? pushAppid;
  String? bibleCategoryId;
  String? appName;
  String? appTypeVersion;
  String? isShowMP3Audio;
  String? imageAppId;
  String? quoteAppId;
  String? videoAppId;
  String? quizCatId;
  String? wallpaperCatId;
  String? verseEditorAppId;
  String? shareappCode;
  String? languageCode;
  String? languageName;
  String? bookAdsStatus;
  String? bookAdsAppId;
  String? surveyEnable;
  String? bookAdsCatId;
  String? surveyAppId;
  String? shortLangCode;
  String? appAudioBasepath;
  String? appAudioBasepathType;
  String? isMulticategoryAvailable;
  String? isImageAvailable;
  String? isQuoteAvailable;
  String? isVideoAvailable;
  String? feedbackEmail;
  String? bibleFeatures;
  String? showNativeAdsRow;
  String? showInterstitialRow;
  String? appShareappLink;
  GetAudioModelDataBibleAudioInfo? bibleAudioInfo;
  GetAudioModelDataCopyrightInfo? copyrightInfo;
  String? appThemeColor;
  String? appStatusThemeColor;
  String? isSubscriptionEnabled;
  String? subIdentifierOneyear;
  String? subIdentifierLifetime;
  String? subSharedsecret;
  String? subIdentifierOnemonth;
  String? subIdentifierThreeMonth;
  String? subIdentifierSixMonth;
  String? offerEnabled;
  int? offerDays;
  int? offerCount;
  String? subIdentifierOneyearValue;
  String? subIdentifierLifetimeValue;
  String? subIdentifier_1YearAutoRenewableValue;
  String? subIdentifierOnemonthValue;
  String? subIdentifierThreeMonthValue;
  String? subIdentifierSixMonthValue;
  List<GetAudioModelDataSubFields?>? subFields;
  GetAudioModelDataCoinsData? coinsData;
  GetAudioModelDataPromotion? promotion;
  String? isNotificationAvailable;
  String? notificationTitle;
  String? adsDuration;
  String? adsType;
  String? adsGoogleBannerIdAndroid;
  String? adsGoogleInterstitialIdAndroid;
  String? adsFacebookBannerIdAndroid;
  String? adsFacebookInterstitialIdAndroid;
  String? adsGoogleOpenAppIdAndroid;
  String? adsGoogleNativeIdAndroid;
  String? adsGoogleBannerIdIos;
  String? adsGoogleInterstitialIdIos;
  String? adsGoogleOpenAppIdIos;
  String? adsGoogleNativeIdIos;
  String? adsFacebookBannerIdIos;
  String? adsFacebookInterstitialIdIos;
  String? adsGoogleRewardIdIos;
  String? adsGoogleRewardIdAndroid;
  String? adsGoogleAppIdAndroid;
  String? adsFacebookAppIdAndroid;
  String? adsGoogleAppIdIos;
  String? adsFacebookAppIdIos;
  String? adsNetwork_1Field_1Android;
  String? adsNetwork_1Field_2Android;
  String? adsNetwork_1Field_3Android;
  String? adsNetwork_1Field_4Android;
  String? adsNetwork_1Field_5Android;
  String? adsNetwork_1Field_6Android;
  String? adsNetwork_1Field_1Ios;
  String? adsNetwork_1Field_2Ios;
  String? adsNetwork_1Field_3Ios;
  String? adsNetwork_1Field_4Ios;
  String? adsNetwork_1Field_5Ios;
  String? adsNetwork_1Field_6Ios;
  String? adsNetwork_2Field_1Android;
  String? adsNetwork_2Field_2Android;
  String? adsNetwork_2Field_3Android;
  String? adsNetwork_2Field_4Android;
  String? adsNetwork_2Field_5Android;
  String? adsNetwork_2Field_6Android;
  String? adsNetwork_2Field_1Ios;
  String? adsNetwork_2Field_2Ios;
  String? adsNetwork_2Field_3Ios;
  String? adsNetwork_2Field_4Ios;
  String? adsNetwork_2Field_5Ios;
  String? adsNetwork_2Field_6Ios;
  String? rewardedInterstitialAds;
  String? nativeAds;
  String? adsGoogleBannerId_2Ios;
  String? adsGoogleBannerId_2Android;
  String? adsGoogleBannerId_3Ios;
  String? adsGoogleBannerId_3Android;
  String? adsGoogleRewardInterstitialIdAndroid;
  String? adsGoogleRewardInterstitialIdIos;

  GetAudioModelData({
    this.pushAppid,
    this.bibleCategoryId,
    this.appName,
    this.appTypeVersion,
    this.isShowMP3Audio,
    this.imageAppId,
    this.quoteAppId,
    this.videoAppId,
    this.quizCatId,
    this.wallpaperCatId,
    this.verseEditorAppId,
    this.shareappCode,
    this.languageCode,
    this.languageName,
    this.bookAdsStatus,
    this.bookAdsAppId,
    this.surveyEnable,
    this.bookAdsCatId,
    this.surveyAppId,
    this.shortLangCode,
    this.appAudioBasepath,
    this.appAudioBasepathType,
    this.isMulticategoryAvailable,
    this.isImageAvailable,
    this.isQuoteAvailable,
    this.isVideoAvailable,
    this.feedbackEmail,
    this.bibleFeatures,
    this.showNativeAdsRow,
    this.showInterstitialRow,
    this.appShareappLink,
    this.bibleAudioInfo,
    this.copyrightInfo,
    this.appThemeColor,
    this.appStatusThemeColor,
    this.isSubscriptionEnabled,
    this.subIdentifierOneyear,
    this.subIdentifierLifetime,
    this.subSharedsecret,
    this.subIdentifierOnemonth,
    this.subIdentifierThreeMonth,
    this.subIdentifierSixMonth,
    this.offerEnabled,
    this.offerDays,
    this.offerCount,
    this.subIdentifierOneyearValue,
    this.subIdentifierLifetimeValue,
    this.subIdentifier_1YearAutoRenewableValue,
    this.subIdentifierOnemonthValue,
    this.subIdentifierThreeMonthValue,
    this.subIdentifierSixMonthValue,
    this.subFields,
    this.coinsData,
    this.promotion,
    this.isNotificationAvailable,
    this.notificationTitle,
    this.adsDuration,
    this.adsType,
    this.adsGoogleBannerIdAndroid,
    this.adsGoogleInterstitialIdAndroid,
    this.adsFacebookBannerIdAndroid,
    this.adsFacebookInterstitialIdAndroid,
    this.adsGoogleOpenAppIdAndroid,
    this.adsGoogleNativeIdAndroid,
    this.adsGoogleBannerIdIos,
    this.adsGoogleInterstitialIdIos,
    this.adsGoogleOpenAppIdIos,
    this.adsGoogleNativeIdIos,
    this.adsFacebookBannerIdIos,
    this.adsFacebookInterstitialIdIos,
    this.adsGoogleRewardIdIos,
    this.adsGoogleRewardIdAndroid,
    this.adsGoogleAppIdAndroid,
    this.adsFacebookAppIdAndroid,
    this.adsGoogleAppIdIos,
    this.adsFacebookAppIdIos,
    this.adsNetwork_1Field_1Android,
    this.adsNetwork_1Field_2Android,
    this.adsNetwork_1Field_3Android,
    this.adsNetwork_1Field_4Android,
    this.adsNetwork_1Field_5Android,
    this.adsNetwork_1Field_6Android,
    this.adsNetwork_1Field_1Ios,
    this.adsNetwork_1Field_2Ios,
    this.adsNetwork_1Field_3Ios,
    this.adsNetwork_1Field_4Ios,
    this.adsNetwork_1Field_5Ios,
    this.adsNetwork_1Field_6Ios,
    this.adsNetwork_2Field_1Android,
    this.adsNetwork_2Field_2Android,
    this.adsNetwork_2Field_3Android,
    this.adsNetwork_2Field_4Android,
    this.adsNetwork_2Field_5Android,
    this.adsNetwork_2Field_6Android,
    this.adsNetwork_2Field_1Ios,
    this.adsNetwork_2Field_2Ios,
    this.adsNetwork_2Field_3Ios,
    this.adsNetwork_2Field_4Ios,
    this.adsNetwork_2Field_5Ios,
    this.adsNetwork_2Field_6Ios,
    this.rewardedInterstitialAds,
    this.nativeAds,
    this.adsGoogleBannerId_2Ios,
    this.adsGoogleBannerId_2Android,
    this.adsGoogleBannerId_3Ios,
    this.adsGoogleBannerId_3Android,
    this.adsGoogleRewardInterstitialIdAndroid,
    this.adsGoogleRewardInterstitialIdIos,
  });
  GetAudioModelData.fromJson(Map<String, dynamic> json) {
    pushAppid = json['push_appid']?.toString();
    bibleCategoryId = json['bibleCategoryId']?.toString();
    appName = json['app_name']?.toString();
    appTypeVersion = json['app_type_version']?.toString();
    isShowMP3Audio = json['is_show_MP3_Audio']?.toString();
    imageAppId = json['image_app_id']?.toString();
    quoteAppId = json['quote_app_id']?.toString();
    videoAppId = json['video_app_id']?.toString();
    quizCatId = json['quiz_cat_id']?.toString();
    wallpaperCatId = json['wallpaper_cat_id']?.toString();
    verseEditorAppId = json['verse_editor_app_id']?.toString();
    shareappCode = json['shareapp_code']?.toString();
    languageCode = json['language_code']?.toString();
    languageName = json['language_name']?.toString();
    bookAdsStatus = json['book_ads_status']?.toString();
    bookAdsAppId = json['book_ads_app_id']?.toString();
    surveyEnable = json['survey_enable']?.toString();
    bookAdsCatId = json['book_ads_cat_id']?.toString();
    surveyAppId = json['survey_app_id']?.toString();
    shortLangCode = json['short_lang_code']?.toString();
    appAudioBasepath = json['app_Audio_Basepath']?.toString();
    appAudioBasepathType = json['app_Audio_Basepath_Type']?.toString();
    isMulticategoryAvailable = json['is_multicategory_available']?.toString();
    isImageAvailable = json['is_image_available']?.toString();
    isQuoteAvailable = json['is_quote_available']?.toString();
    isVideoAvailable = json['is_video_available']?.toString();
    feedbackEmail = json['feedback_email']?.toString();
    bibleFeatures = json['bible_features']?.toString();
    showNativeAdsRow = json['show_native_ads_row']?.toString();
    showInterstitialRow = json['show_interstitial_row']?.toString();
    appShareappLink = json['app_shareapp_link']?.toString();
    bibleAudioInfo = (json['bible_audio_info'] != null)
        ? GetAudioModelDataBibleAudioInfo.fromJson(json['bible_audio_info'])
        : null;
    copyrightInfo = (json['copyright_info'] != null)
        ? GetAudioModelDataCopyrightInfo.fromJson(json['copyright_info'])
        : null;
    appThemeColor = json['app_theme_color']?.toString();
    appStatusThemeColor = json['app_status_theme_color']?.toString();
    isSubscriptionEnabled = json['is_subscription_enabled']?.toString();
    subIdentifierOneyear = json['sub_identifier_oneyear']?.toString();
    subIdentifierLifetime = json['sub_identifier_lifetime']?.toString();
    subSharedsecret = json['sub_sharedsecret']?.toString();
    subIdentifierOnemonth = json['sub_identifier_onemonth']?.toString();
    subIdentifierThreeMonth = json['sub_identifier_three_month']?.toString();
    subIdentifierSixMonth = json['sub_identifier_six_month']?.toString();
    offerEnabled = json['offer_enabled']?.toString();
    offerDays = json['offer_days']?.toInt();
    offerCount = json['offer_count']?.toInt();
    subIdentifierOneyearValue =
        json['sub_identifier_oneyear_value']?.toString();
    subIdentifierLifetimeValue =
        json['sub_identifier_lifetime_value']?.toString();
    subIdentifier_1YearAutoRenewableValue =
        json['sub_identifier_1_year_auto_renewable_value']?.toString();
    subIdentifierOnemonthValue =
        json['sub_identifier_onemonth_value']?.toString();
    subIdentifierThreeMonthValue =
        json['sub_identifier_three_month_value']?.toString();
    subIdentifierSixMonthValue =
        json['sub_identifier_six_month_value']?.toString();
    if (json['sub_fields'] != null) {
      final v = json['sub_fields'];
      final arr0 = <GetAudioModelDataSubFields>[];
      v.forEach((v) {
        arr0.add(GetAudioModelDataSubFields.fromJson(v));
      });
      subFields = arr0;
    }
    coinsData = (json['coins_data'] != null)
        ? GetAudioModelDataCoinsData.fromJson(json['coins_data'])
        : null;
    promotion = (json['promotion'] != null)
        ? GetAudioModelDataPromotion.fromJson(json['promotion'])
        : null;
    isNotificationAvailable = json['is_notification_available']?.toString();
    notificationTitle = json['notification_title']?.toString();
    adsDuration = json['ads_duration']?.toString();
    adsType = json['ads_Type']?.toString();
    adsGoogleBannerIdAndroid = json['ads_google_banner_id_android']?.toString();
    adsGoogleInterstitialIdAndroid =
        json['ads_google_interstitial_id_android']?.toString();
    adsFacebookBannerIdAndroid =
        json['ads_facebook_banner_id_android']?.toString();
    adsFacebookInterstitialIdAndroid =
        json['ads_facebook_interstitial_id_android']?.toString();
    adsGoogleOpenAppIdAndroid =
        json['ads_google_openApp_id_android']?.toString();
    adsGoogleNativeIdAndroid = json['ads_google_native_id_android']?.toString();
    adsGoogleBannerIdIos = json['ads_google_banner_id_ios']?.toString();
    adsGoogleInterstitialIdIos =
        json['ads_google_interstitial_id_ios']?.toString();
    adsGoogleOpenAppIdIos = json['ads_google_openApp_id_ios']?.toString();
    adsGoogleNativeIdIos = json['ads_google_native_id_ios']?.toString();
    adsFacebookBannerIdIos = json['ads_facebook_banner_id_ios']?.toString();
    adsFacebookInterstitialIdIos =
        json['ads_facebook_interstitial_id_ios']?.toString();
    adsGoogleRewardIdIos = json['ads_google_reward_id_ios']?.toString();
    adsGoogleRewardIdAndroid = json['ads_google_reward_id_android']?.toString();
    adsGoogleAppIdAndroid = json['ads_google_app_id_android']?.toString();
    adsFacebookAppIdAndroid = json['ads_facebook_app_id_android']?.toString();
    adsGoogleAppIdIos = json['ads_google_app_id_ios']?.toString();
    adsFacebookAppIdIos = json['ads_facebook_app_id_ios']?.toString();
    adsNetwork_1Field_1Android =
        json['ads_network_1_field_1_android']?.toString();
    adsNetwork_1Field_2Android =
        json['ads_network_1_field_2_android']?.toString();
    adsNetwork_1Field_3Android =
        json['ads_network_1_field_3_android']?.toString();
    adsNetwork_1Field_4Android =
        json['ads_network_1_field_4_android']?.toString();
    adsNetwork_1Field_5Android =
        json['ads_network_1_field_5_android']?.toString();
    adsNetwork_1Field_6Android =
        json['ads_network_1_field_6_android']?.toString();
    adsNetwork_1Field_1Ios = json['ads_network_1_field_1_ios']?.toString();
    adsNetwork_1Field_2Ios = json['ads_network_1_field_2_ios']?.toString();
    adsNetwork_1Field_3Ios = json['ads_network_1_field_3_ios']?.toString();
    adsNetwork_1Field_4Ios = json['ads_network_1_field_4_ios']?.toString();
    adsNetwork_1Field_5Ios = json['ads_network_1_field_5_ios']?.toString();
    adsNetwork_1Field_6Ios = json['ads_network_1_field_6_ios']?.toString();
    adsNetwork_2Field_1Android =
        json['ads_network_2_field_1_android']?.toString();
    adsNetwork_2Field_2Android =
        json['ads_network_2_field_2_android']?.toString();
    adsNetwork_2Field_3Android =
        json['ads_network_2_field_3_android']?.toString();
    adsNetwork_2Field_4Android =
        json['ads_network_2_field_4_android']?.toString();
    adsNetwork_2Field_5Android =
        json['ads_network_2_field_5_android']?.toString();
    adsNetwork_2Field_6Android =
        json['ads_network_2_field_6_android']?.toString();
    adsNetwork_2Field_1Ios = json['ads_network_2_field_1_ios']?.toString();
    adsNetwork_2Field_2Ios = json['ads_network_2_field_2_ios']?.toString();
    adsNetwork_2Field_3Ios = json['ads_network_2_field_3_ios']?.toString();
    adsNetwork_2Field_4Ios = json['ads_network_2_field_4_ios']?.toString();
    adsNetwork_2Field_5Ios = json['ads_network_2_field_5_ios']?.toString();
    adsNetwork_2Field_6Ios = json['ads_network_2_field_6_ios']?.toString();
    rewardedInterstitialAds = json['rewarded_interstitial_ads']?.toString();
    nativeAds = json['native_ads']?.toString();
    adsGoogleBannerId_2Ios = json['ads_google_banner_id_2_ios']?.toString();
    adsGoogleBannerId_2Android =
        json['ads_google_banner_id_2_android']?.toString();
    adsGoogleBannerId_3Ios = json['ads_google_banner_id_3_ios']?.toString();
    adsGoogleBannerId_3Android =
        json['ads_google_banner_id_3_android']?.toString();
    adsGoogleRewardInterstitialIdAndroid =
        json['ads_google_reward_interstitial_id_android']?.toString();
    adsGoogleRewardInterstitialIdIos =
        json['ads_google_reward_interstitial_id_ios']?.toString();
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['push_appid'] = pushAppid;
    data['bibleCategoryId'] = bibleCategoryId;
    data['app_name'] = appName;
    data['app_type_version'] = appTypeVersion;
    data['is_show_MP3_Audio'] = isShowMP3Audio;
    data['image_app_id'] = imageAppId;
    data['quote_app_id'] = quoteAppId;
    data['video_app_id'] = videoAppId;
    data['quiz_cat_id'] = quizCatId;
    data['wallpaper_cat_id'] = wallpaperCatId;
    data['verse_editor_app_id'] = verseEditorAppId;
    data['shareapp_code'] = shareappCode;
    data['language_code'] = languageCode;
    data['language_name'] = languageName;
    data['book_ads_status'] = bookAdsStatus;
    data['book_ads_app_id'] = bookAdsAppId;
    data['survey_enable'] = surveyEnable;
    data['book_ads_cat_id'] = bookAdsCatId;
    data['survey_app_id'] = surveyAppId;
    data['short_lang_code'] = shortLangCode;
    data['app_Audio_Basepath'] = appAudioBasepath;
    data['app_Audio_Basepath_Type'] = appAudioBasepathType;
    data['is_multicategory_available'] = isMulticategoryAvailable;
    data['is_image_available'] = isImageAvailable;
    data['is_quote_available'] = isQuoteAvailable;
    data['is_video_available'] = isVideoAvailable;
    data['feedback_email'] = feedbackEmail;
    data['bible_features'] = bibleFeatures;
    data['show_native_ads_row'] = showNativeAdsRow;
    data['show_interstitial_row'] = showInterstitialRow;
    data['app_shareapp_link'] = appShareappLink;
    if (bibleAudioInfo != null) {
      data['bible_audio_info'] = bibleAudioInfo!.toJson();
    }
    if (copyrightInfo != null) {
      data['copyright_info'] = copyrightInfo!.toJson();
    }
    data['app_theme_color'] = appThemeColor;
    data['app_status_theme_color'] = appStatusThemeColor;
    data['is_subscription_enabled'] = isSubscriptionEnabled;
    data['sub_identifier_oneyear'] = subIdentifierOneyear;
    data['sub_identifier_lifetime'] = subIdentifierLifetime;
    data['sub_sharedsecret'] = subSharedsecret;
    data['sub_identifier_onemonth'] = subIdentifierOnemonth;
    data['sub_identifier_three_month'] = subIdentifierThreeMonth;
    data['sub_identifier_six_month'] = subIdentifierSixMonth;
    data['offer_enabled'] = offerEnabled;
    data['offer_days'] = offerDays;
    data['offer_count'] = offerCount;
    data['sub_identifier_oneyear_value'] = subIdentifierOneyearValue;
    data['sub_identifier_lifetime_value'] = subIdentifierLifetimeValue;
    data['sub_identifier_1_year_auto_renewable_value'] =
        subIdentifier_1YearAutoRenewableValue;
    data['sub_identifier_onemonth_value'] = subIdentifierOnemonthValue;
    data['sub_identifier_three_month_value'] = subIdentifierThreeMonthValue;
    data['sub_identifier_six_month_value'] = subIdentifierSixMonthValue;
    if (subFields != null) {
      final v = subFields;
      final arr0 = [];
      for (var v in v!) {
        arr0.add(v!.toJson());
      }
      data['sub_fields'] = arr0;
    }
    if (coinsData != null) {
      data['coins_data'] = coinsData!.toJson();
    }
    if (promotion != null) {
      data['promotion'] = promotion!.toJson();
    }
    data['is_notification_available'] = isNotificationAvailable;
    data['notification_title'] = notificationTitle;
    data['ads_duration'] = adsDuration;
    data['ads_Type'] = adsType;
    data['ads_google_banner_id_android'] = adsGoogleBannerIdAndroid;
    data['ads_google_interstitial_id_android'] = adsGoogleInterstitialIdAndroid;
    data['ads_facebook_banner_id_android'] = adsFacebookBannerIdAndroid;
    data['ads_facebook_interstitial_id_android'] =
        adsFacebookInterstitialIdAndroid;
    data['ads_google_openApp_id_android'] = adsGoogleOpenAppIdAndroid;
    data['ads_google_native_id_android'] = adsGoogleNativeIdAndroid;
    data['ads_google_banner_id_ios'] = adsGoogleBannerIdIos;
    data['ads_google_interstitial_id_ios'] = adsGoogleInterstitialIdIos;
    data['ads_google_openApp_id_ios'] = adsGoogleOpenAppIdIos;
    data['ads_google_native_id_ios'] = adsGoogleNativeIdIos;
    data['ads_facebook_banner_id_ios'] = adsFacebookBannerIdIos;
    data['ads_facebook_interstitial_id_ios'] = adsFacebookInterstitialIdIos;
    data['ads_google_reward_id_ios'] = adsGoogleRewardIdIos;
    data['ads_google_reward_id_android'] = adsGoogleRewardIdAndroid;
    data['ads_google_app_id_android'] = adsGoogleAppIdAndroid;
    data['ads_facebook_app_id_android'] = adsFacebookAppIdAndroid;
    data['ads_google_app_id_ios'] = adsGoogleAppIdIos;
    data['ads_facebook_app_id_ios'] = adsFacebookAppIdIos;
    data['ads_network_1_field_1_android'] = adsNetwork_1Field_1Android;
    data['ads_network_1_field_2_android'] = adsNetwork_1Field_2Android;
    data['ads_network_1_field_3_android'] = adsNetwork_1Field_3Android;
    data['ads_network_1_field_4_android'] = adsNetwork_1Field_4Android;
    data['ads_network_1_field_5_android'] = adsNetwork_1Field_5Android;
    data['ads_network_1_field_6_android'] = adsNetwork_1Field_6Android;
    data['ads_network_1_field_1_ios'] = adsNetwork_1Field_1Ios;
    data['ads_network_1_field_2_ios'] = adsNetwork_1Field_2Ios;
    data['ads_network_1_field_3_ios'] = adsNetwork_1Field_3Ios;
    data['ads_network_1_field_4_ios'] = adsNetwork_1Field_4Ios;
    data['ads_network_1_field_5_ios'] = adsNetwork_1Field_5Ios;
    data['ads_network_1_field_6_ios'] = adsNetwork_1Field_6Ios;
    data['ads_network_2_field_1_android'] = adsNetwork_2Field_1Android;
    data['ads_network_2_field_2_android'] = adsNetwork_2Field_2Android;
    data['ads_network_2_field_3_android'] = adsNetwork_2Field_3Android;
    data['ads_network_2_field_4_android'] = adsNetwork_2Field_4Android;
    data['ads_network_2_field_5_android'] = adsNetwork_2Field_5Android;
    data['ads_network_2_field_6_android'] = adsNetwork_2Field_6Android;
    data['ads_network_2_field_1_ios'] = adsNetwork_2Field_1Ios;
    data['ads_network_2_field_2_ios'] = adsNetwork_2Field_2Ios;
    data['ads_network_2_field_3_ios'] = adsNetwork_2Field_3Ios;
    data['ads_network_2_field_4_ios'] = adsNetwork_2Field_4Ios;
    data['ads_network_2_field_5_ios'] = adsNetwork_2Field_5Ios;
    data['ads_network_2_field_6_ios'] = adsNetwork_2Field_6Ios;
    data['rewarded_interstitial_ads'] = rewardedInterstitialAds;
    data['native_ads'] = nativeAds;
    data['ads_google_banner_id_2_ios'] = adsGoogleBannerId_2Ios;
    data['ads_google_banner_id_2_android'] = adsGoogleBannerId_2Android;
    data['ads_google_banner_id_3_ios'] = adsGoogleBannerId_3Ios;
    data['ads_google_banner_id_3_android'] = adsGoogleBannerId_3Android;
    data['ads_google_reward_interstitial_id_android'] =
        adsGoogleRewardInterstitialIdAndroid;
    data['ads_google_reward_interstitial_id_ios'] =
        adsGoogleRewardInterstitialIdIos;
    return data;
  }
}

class GetAudioModel {
/*
{
  "result": "1",
  "data": {
    "push_appid": "138",
    "bibleCategoryId": "138",
    "app_name": "Amplified_Bible_Flutter",
    "app_type_version": "Smart",
    "is_show_MP3_Audio": "1",
    "image_app_id": "322",
    "quote_app_id": "8",
    "video_app_id": "104",
    "quiz_cat_id": "174",
    "wallpaper_cat_id": "177",
    "verse_editor_app_id": "317",
    "shareapp_code": "aede982",
    "language_code": "",
    "language_name": "",
    "book_ads_status": "1",
    "book_ads_app_id": "6",
    "survey_enable": "1",
    "book_ads_cat_id": "16",
    "survey_app_id": "3",
    "short_lang_code": "",
    "app_Audio_Basepath": "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/",
    "app_Audio_Basepath_Type": "3",
    "is_multicategory_available": "1",
    "is_image_available": "1",
    "is_quote_available": "1",
    "is_video_available": "0",
    "feedback_email": "feedback@bibleoffice.com",
    "bible_features": "User-friendly interface and quick access to books,chapters and verses.@@@@@A Beautiful Reading and Listening Experience@@@@@Create and Share Inspirational Bible Art",
    "show_native_ads_row": "20",
    "show_interstitial_row": "10",
    "app_shareapp_link": "https://bibleoffice.com/aede982",
    "bible_audio_info": {
      "is_show_mp3_audio": "1",
      "audio_basepath": "https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English/",
      "audio_basepath_type": "3",
      "is_text_to_speech_available_ios": "0",
      "text_to_speech_language_code_ios": "",
      "text_to_speech_identifier_ios": "",
      "is_text_to_speech_available_android": "0",
      "text_to_speech_language_code_android": ""
    },
    "copyright_info": {
      "copyright_name": "",
      "copyright_url": "https://bibleoffice.com/"
    },
    "app_theme_color": "#31419E",
    "app_status_theme_color": "#7583D1",
    "is_subscription_enabled": "1",
    "sub_identifier_oneyear": "com.balaklrapps.amplifiedbible.oneyearadsfree",
    "sub_identifier_lifetime": "com.balaklrapps.amplifiedbible.lifetimeadsfree",
    "sub_sharedsecret": "ccd8c651502d42afa0b390e0f8e48f79",
    "sub_identifier_onemonth": "",
    "sub_identifier_three_month": "",
    "sub_identifier_six_month": "com.balaklrapps.amplifiedbible.sixmonthadsfree",
    "offer_enabled": "1",
    "offer_days": 20,
    "offer_count": 200,
    "sub_identifier_oneyear_value": "50",
    "sub_identifier_lifetime_value": "80",
    "sub_identifier_1_year_auto_renewable_value": "",
    "sub_identifier_onemonth_value": "",
    "sub_identifier_three_month_value": "",
    "sub_identifier_six_month_value": "",
    "sub_fields": [
      {
        "field_num": "0",
        "identifier": "",
        "item_1": "",
        "item_2": "",
        "value": ""
      }
    ],
    "coins_data": {
      "hint": "",
      "view_answer": "",
      "50_50": "",
      "try_again": "",
      "share": "",
      "time_wait": ""
    },
    "promotion": {
      "promotion_enable": "0",
      "pro_img_url": "https://axeraan.com/axeraan_fw/site_dashboard/uploads/portfolio_slider_img/Web_1366_%E2%80%93_27.png",
      "pro_button_url": "https://bibleoffice.com/",
      "start_time": "",
      "end_time": ""
    },
    "is_notification_available": "1",
    "notification_title": "Verse of the Day",
    "ads_duration": "3",
    "ads_Type": "5",
    "ads_google_banner_id_android": "",
    "ads_google_interstitial_id_android": "",
    "ads_facebook_banner_id_android": "",
    "ads_facebook_interstitial_id_android": "",
    "ads_google_openApp_id_android": "",
    "ads_google_native_id_android": "",
    "ads_google_banner_id_ios": "ca-app-pub-4194577750257069/3829303484",
    "ads_google_interstitial_id_ios": "ca-app-pub-4194577750257069/8121554676",
    "ads_google_openApp_id_ios": "ca-app-pub-4194577750257069/6808473007",
    "ads_google_native_id_ios": "ca-app-pub-4194577750257069/5043409277",
    "ads_facebook_banner_id_ios": "",
    "ads_facebook_interstitial_id_ios": "",
    "ads_google_reward_id_ios": "ca-app-pub-4194577750257069/3146777206",
    "ads_google_reward_id_android": "",
    "ads_google_app_id_android": "",
    "ads_facebook_app_id_android": "",
    "ads_google_app_id_ios": "ca-app-pub-4194577750257069~9442429107",
    "ads_facebook_app_id_ios": "",
    "ads_network_1_field_1_android": "",
    "ads_network_1_field_2_android": "",
    "ads_network_1_field_3_android": "",
    "ads_network_1_field_4_android": "",
    "ads_network_1_field_5_android": "",
    "ads_network_1_field_6_android": "",
    "ads_network_1_field_1_ios": "",
    "ads_network_1_field_2_ios": "",
    "ads_network_1_field_3_ios": "",
    "ads_network_1_field_4_ios": "",
    "ads_network_1_field_5_ios": "",
    "ads_network_1_field_6_ios": "",
    "ads_network_2_field_1_android": "",
    "ads_network_2_field_2_android": "",
    "ads_network_2_field_3_android": "",
    "ads_network_2_field_4_android": "",
    "ads_network_2_field_5_android": "",
    "ads_network_2_field_6_android": "",
    "ads_network_2_field_1_ios": "",
    "ads_network_2_field_2_ios": "",
    "ads_network_2_field_3_ios": "",
    "ads_network_2_field_4_ios": "",
    "ads_network_2_field_5_ios": "",
    "ads_network_2_field_6_ios": "",
    "rewarded_interstitial_ads": "",
    "native_ads": "",
    "ads_google_banner_id_2_ios": "ca-app-pub-4194577750257069/3829303484",
    "ads_google_banner_id_2_android": "",
    "ads_google_banner_id_3_ios": "ca-app-pub-4194577750257069/3829303484",
    "ads_google_banner_id_3_android": "",
    "ads_google_reward_interstitial_id_android": "",
    "ads_google_reward_interstitial_id_ios": "ca-app-pub-4194577750257069/5165864053"
  }
} 
*/

  String? result;
  GetAudioModelData? data;

  GetAudioModel({
    this.result,
    this.data,
  });
  GetAudioModel.fromJson(Map<String, dynamic> json) {
    result = json['result']?.toString();
    data = (json['data'] != null)
        ? GetAudioModelData.fromJson(json['data'])
        : null;
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['result'] = result;
    data['data'] = this.data!.toJson();
    return data;
  }
}
