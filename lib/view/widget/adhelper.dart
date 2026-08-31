// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class InterstitialAdHelper {
//   static final InterstitialAdHelper _instance =
//       InterstitialAdHelper._internal();
//   factory InterstitialAdHelper() => _instance;

//   InterstitialAdHelper._internal();

//   InterstitialAd? _interstitialAd;
//   bool _isAdLoaded = false;

//   /// Load Interstitial Ad
//   void loadAd({required Function onAdLoaded, Function? onAdFailed}) {
//     InterstitialAd.load(
//       adUnitId:
//           'ca-app-pub-3940256099942544/1033173712', // Replace with your real AdMob ID in production
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (InterstitialAd ad) {
//           _interstitialAd = ad;
//           _isAdLoaded = true;
//           onAdLoaded(); // Notify UI
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           print('InterstitialAd failed to load: $error');
//           _isAdLoaded = false;
//           if (onAdFailed != null) onAdFailed();
//         },
//       ),
//     );
//   }

//   /// Show Interstitial Ad
//   void showAd({required Function onAdClosed}) {
//     if (_isAdLoaded && _interstitialAd != null) {
//       _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//         onAdDismissedFullScreenContent: (ad) {
//           ad.dispose();
//           _isAdLoaded = false;
//           loadAd(onAdLoaded: () {}); // Preload the next ad
//           onAdClosed(); // Notify UI
//         },
//         onAdFailedToShowFullScreenContent: (ad, error) {
//           print('Failed to show interstitial ad: $error');
//           ad.dispose();
//           _isAdLoaded = false;
//           loadAd(onAdLoaded: () {}); // Preload the next ad
//         },
//       );
//       _interstitialAd!.show();
//     } else {
//       print('Ad is not ready yet');
//       onAdClosed(); // Proceed without ad if it's not available
//     }
//   }
// }

import 'dart:async';
import 'package:biblebookapp/ads/levelplay_ads.dart';
import 'package:biblebookapp/ads/levelplay_placements.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService with WidgetsBindingObserver {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  static bool _isShowingAd = false;
  static AppLifecycleState? _lastAppState;

  static final RewardedAdService _instance = RewardedAdService._internal();

  factory RewardedAdService() {
    return _instance;
  }

  RewardedAdService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static Future<void> loadAd({
    required VoidCallback onAdLoaded,
    required VoidCallback onAdFailed,
    String? data,
  }) async {
    if (_isAdLoaded) return;

    unawaited(LevelPlayAds.instance.preloadRewarded());
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.rewardedAd);
    if (data != null && data.isNotEmpty) {
      return RewardedAd.load(
        adUnitId: adUnitId.toString(),
        request: await AdConsentManager.getAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isAdLoaded = true;
            // onAdLoaded();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) =>
                  debugPrint("Ad showed full screen content"),
              onAdDismissedFullScreenContent: (ad) {
                debugPrint("Ad dismissed full screen content");
                ad.dispose();
                _rewardedAd = null;
                _isAdLoaded = false;
                _isShowingAd = false;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint("Ad failed to show full screen content: $error");
                ad.dispose();
                _rewardedAd = null;
                _isAdLoaded = false;
                _isShowingAd = false;
              },
            );

            onAdLoaded();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');

            onAdFailed();
            _isAdLoaded = false;
          },
        ),
      );
    }
    return;
  }

  static void showAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdDismissed,
    String? data,
  }) {
    if (data != null) {
      if (LevelPlayAds.instance.rewardedReady) {
        unawaited(LevelPlayAds.instance.showRewarded(
          placement: LevelPlayPlacements.wallpaperDownloadRewarded,
          onRewarded: onRewardEarned,
          onClosed: onAdDismissed,
        ));
        return;
      }
      if (!_isAdLoaded || _rewardedAd == null || _isShowingAd) {
        Constants.showToast("Ad not available.");
        _rewardedAd = null;
        return;
      }
      debugPrint(" RewardedAdService 1.2");
      if (_lastAppState != null && _lastAppState != AppLifecycleState.resumed) {
        debugPrint("App not in foreground. Skipping ad show.");
        _rewardedAd = null;
        return;
      }

      _isShowingAd = true;
      _isShowingAd = true;
      debugPrint("RewardedAdService - Showing ad");

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint("RewardedAdService - Ad Showed FullScreenContent");
          onAdDismissed();
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("RewardedAdService - AdDismissedFullScreenContent");
          ad.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
          _isShowingAd = false;
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint(
              "RewardedAdService - AdFailedToShowFullScreenContent: $error");
          ad.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
          _isShowingAd = false;
          onAdDismissed();
        },
        onAdImpression: (ad) {
          debugPrint("RewardedAdService - Ad Impression");
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
              "RewardedAdService - onUserEarnedReward: ${reward.amount} ${reward.type}");
          onRewardEarned();
        },
      );
    } else {
      _rewardedAd = null;
      return;
    }
    // debugPrint(" RewardedAdService 2");
    // _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
    //   onAdDismissedFullScreenContent: (ad) async {
    //     debugPrint(" RewardedAdService AdDismissedFullScreenConten");
    //     _rewardedAd = null;
    //     _isAdLoaded = false;
    //     _isShowingAd = false;

    //     ad.dispose();

    //     // await SharPreferences.setString('OpenAd', '1');
    //     onAdDismissed();
    //   },
    //   onAdFailedToShowFullScreenContent: (ad, error) {
    //     debugPrint(" RewardedAdService onAdFailedToShowFullScreenContent");
    //     ad.dispose();
    //     _rewardedAd = null;
    //     _isAdLoaded = false;
    //     _isShowingAd = false;

    //     onAdDismissed();
    //   },
    // );

    // _rewardedAd!.show(
    //   onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
    //     // await SharPreferences.setString('OpenAd', '1');
    //     debugPrint(" RewardedAdService onUserEarnedReward");
    //     onRewardEarned();
    //   },
    // );
  }

  // App Lifecycle tracking
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastAppState = state;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      debugPrint("App backgrounded: disposing ad if needed.");
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _isAdLoaded = false;
      _isShowingAd = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
