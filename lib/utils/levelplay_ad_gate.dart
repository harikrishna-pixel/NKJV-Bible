import 'package:biblebookapp/utils/levelplay_ads.dart';
import 'package:biblebookapp/utils/levelplay_config.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';

/// LevelPlay-first gate. Falls back to AdMob only when LevelPlay cannot show.
/// Does not change [shouldLoadAd] eligibility or credit/download business logic.
class LevelPlayAdGate {
  LevelPlayAdGate._();

  /// Returns true if LevelPlay showed (caller should skip AdMob).
  static Future<bool> tryInterstitial(String placementName) async {
    try {
      final shouldLoad = await SharPreferences.shouldLoadAd();
      if (!shouldLoad) return false;

      await LevelPlayAds.instance.ensureInitialized();
      final ids = await LevelPlayConfig.loadCached();
      if (!ids.hasInterstitial) return false;

      if (!await LevelPlayAds.instance.isInterstitialReady()) {
        LevelPlayAds.instance.preloadInterstitial();
        return false;
      }

      final shown =
          await LevelPlayAds.instance.showInterstitialAndWait(placementName);
      debugPrint(
          'LevelPlayAdGate interstitial placement=$placementName shown=$shown');
      return shown;
    } catch (e) {
      debugPrint('LevelPlayAdGate interstitial error: $e');
      return false;
    }
  }

  static Future<void> interstitialOrFallback({
    required String placementName,
    required Future<void> Function() admobFallback,
  }) async {
    final shown = await tryInterstitial(placementName);
    if (shown) return;
    await admobFallback();
  }

  /// `null` = LevelPlay not available → use AdMob.
  /// `true` = LevelPlay showed and user earned reward.
  /// `false` = LevelPlay showed but no reward (do not fall back to AdMob).
  static Future<bool?> tryRewarded(String placementName) async {
    try {
      final shouldLoad = await SharPreferences.shouldLoadAd();
      if (!shouldLoad) return null;

      await LevelPlayAds.instance.ensureInitialized();
      final ids = await LevelPlayConfig.loadCached();
      if (!ids.hasRewarded) return null;

      if (!await LevelPlayAds.instance.isRewardedReady()) {
        LevelPlayAds.instance.preloadRewarded();
        return null;
      }

      final earned =
          await LevelPlayAds.instance.showRewardedAndWait(placementName);
      debugPrint(
          'LevelPlayAdGate rewarded placement=$placementName earned=$earned');
      return earned;
    } catch (e) {
      debugPrint('LevelPlayAdGate rewarded error: $e');
      return null;
    }
  }

  static Future<void> rewardedOrFallback({
    required String placementName,
    required Future<void> Function() admobFallback,
    required Future<void> Function() onRewardEarned,
  }) async {
    final result = await tryRewarded(placementName);
    if (result != null) {
      if (result == true) await onRewardEarned();
      return;
    }
    await admobFallback();
  }
}
