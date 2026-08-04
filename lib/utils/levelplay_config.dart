import 'dart:io';

import 'package:biblebookapp/Model/get_audio_model.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';

/// LevelPlay IDs from custom API (Ads Network-1 Field-1…5).
/// Never hardcode — always API, with last successful cache as fallback.
class LevelPlayIds {
  const LevelPlayIds({
    required this.appKey,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.nativeAdUnitId,
    required this.rewardedAdUnitId,
  });

  final String appKey;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String nativeAdUnitId;
  final String rewardedAdUnitId;

  bool get hasAppKey => appKey.trim().isNotEmpty;
  bool get hasBanner => bannerAdUnitId.trim().isNotEmpty;
  bool get hasInterstitial => interstitialAdUnitId.trim().isNotEmpty;
  bool get hasNative => nativeAdUnitId.trim().isNotEmpty;
  bool get hasRewarded => rewardedAdUnitId.trim().isNotEmpty;

  LevelPlayIds copyWith({
    String? appKey,
    String? bannerAdUnitId,
    String? interstitialAdUnitId,
    String? nativeAdUnitId,
    String? rewardedAdUnitId,
  }) {
    return LevelPlayIds(
      appKey: appKey ?? this.appKey,
      bannerAdUnitId: bannerAdUnitId ?? this.bannerAdUnitId,
      interstitialAdUnitId: interstitialAdUnitId ?? this.interstitialAdUnitId,
      nativeAdUnitId: nativeAdUnitId ?? this.nativeAdUnitId,
      rewardedAdUnitId: rewardedAdUnitId ?? this.rewardedAdUnitId,
    );
  }
}

class LevelPlayConfig {
  LevelPlayConfig._();

  static const String prefAppKey = 'levelplay_app_key';
  static const String prefBanner = 'levelplay_banner_ad_unit_id';
  static const String prefInterstitial = 'levelplay_interstitial_ad_unit_id';
  static const String prefNative = 'levelplay_native_ad_unit_id';
  static const String prefRewarded = 'levelplay_rewarded_ad_unit_id';

  /// Prefer non-empty [incoming]; otherwise keep [cached].
  static String _merge(String? incoming, String cached) {
    final v = (incoming ?? '').trim();
    return v.isNotEmpty ? v : cached;
  }

  /// Persist Network-1 LevelPlay fields for the current platform.
  /// Empty API fields do not wipe last successful cache.
  static Future<LevelPlayIds> saveFromApi(GetAudioModelData? data) async {
    final cached = await loadCached();
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    String apiField1 = '';
    String apiField2 = '';
    String apiField3 = '';
    String apiField4 = '';
    String apiField5 = '';

    if (data != null) {
      if (isAndroid) {
        apiField1 = data.adsNetwork_1Field_1Android?.trim() ?? '';
        apiField2 = data.adsNetwork_1Field_2Android?.trim() ?? '';
        apiField3 = data.adsNetwork_1Field_3Android?.trim() ?? '';
        apiField4 = data.adsNetwork_1Field_4Android?.trim() ?? '';
        apiField5 = data.adsNetwork_1Field_5Android?.trim() ?? '';
      } else if (isIOS) {
        apiField1 = data.adsNetwork_1Field_1Ios?.trim() ?? '';
        apiField2 = data.adsNetwork_1Field_2Ios?.trim() ?? '';
        apiField3 = data.adsNetwork_1Field_3Ios?.trim() ?? '';
        apiField4 = data.adsNetwork_1Field_4Ios?.trim() ?? '';
        apiField5 = data.adsNetwork_1Field_5Ios?.trim() ?? '';
      }
    }

    final merged = LevelPlayIds(
      appKey: _merge(apiField1, cached.appKey),
      bannerAdUnitId: _merge(apiField2, cached.bannerAdUnitId),
      interstitialAdUnitId: _merge(apiField3, cached.interstitialAdUnitId),
      nativeAdUnitId: _merge(apiField4, cached.nativeAdUnitId),
      rewardedAdUnitId: _merge(apiField5, cached.rewardedAdUnitId),
    );

    await Future.wait([
      SharPreferences.setString(prefAppKey, merged.appKey),
      SharPreferences.setString(prefBanner, merged.bannerAdUnitId),
      SharPreferences.setString(prefInterstitial, merged.interstitialAdUnitId),
      SharPreferences.setString(prefNative, merged.nativeAdUnitId),
      SharPreferences.setString(prefRewarded, merged.rewardedAdUnitId),
    ]);

    debugPrint('========== LevelPlay IDs (API → cache) ==========');
    debugPrint('Platform: ${isIOS ? 'iOS' : (isAndroid ? 'Android' : 'other')}');
    debugPrint('API Field-1 (App Key):          "$apiField1"');
    debugPrint('API Field-2 (Banner):           "$apiField2"');
    debugPrint('API Field-3 (Interstitial):     "$apiField3"');
    debugPrint('API Field-4 (Native):           "$apiField4"');
    debugPrint('API Field-5 (Rewarded):         "$apiField5"');
    debugPrint('--- Effective (after cache merge) ---');
    debugPrint('App Key:                        "${merged.appKey}"');
    debugPrint('Banner Ad Unit ID:              "${merged.bannerAdUnitId}"');
    debugPrint(
        'Interstitial Ad Unit ID:        "${merged.interstitialAdUnitId}"');
    debugPrint('Native Ad Unit ID:              "${merged.nativeAdUnitId}"');
    debugPrint('Rewarded Ad Unit ID:            "${merged.rewardedAdUnitId}"');
    debugPrint('=================================================');

    return merged;
  }

  static Future<LevelPlayIds> loadCached({bool printIds = false}) async {
    final appKey = await SharPreferences.getString(prefAppKey) ?? '';
    final banner = await SharPreferences.getString(prefBanner) ?? '';
    final interstitial =
        await SharPreferences.getString(prefInterstitial) ?? '';
    final native = await SharPreferences.getString(prefNative) ?? '';
    final rewarded = await SharPreferences.getString(prefRewarded) ?? '';

    final ids = LevelPlayIds(
      appKey: appKey.trim(),
      bannerAdUnitId: banner.trim(),
      interstitialAdUnitId: interstitial.trim(),
      nativeAdUnitId: native.trim(),
      rewardedAdUnitId: rewarded.trim(),
    );

    if (printIds) {
      debugPrint('========== LevelPlay IDs (cached) ==========');
      debugPrint('App Key:                        "${ids.appKey}"');
      debugPrint('Banner Ad Unit ID:              "${ids.bannerAdUnitId}"');
      debugPrint(
          'Interstitial Ad Unit ID:        "${ids.interstitialAdUnitId}"');
      debugPrint('Native Ad Unit ID:              "${ids.nativeAdUnitId}"');
      debugPrint('Rewarded Ad Unit ID:            "${ids.rewardedAdUnitId}"');
      debugPrint('============================================');
    }

    return ids;
  }
}
