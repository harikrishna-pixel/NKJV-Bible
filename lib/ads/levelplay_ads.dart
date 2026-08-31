import 'dart:async';
import 'dart:developer';

import 'package:biblebookapp/ads/levelplay_placements.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// LevelPlay (IronSource) ads. IDs from cached API Network-1 fields only.
/// Open ads stay on Google AdMob.
class LevelPlayAds implements LevelPlayInitListener {
  LevelPlayAds._();
  static final LevelPlayAds instance = LevelPlayAds._();

  bool _initStarted = false;
  bool initOk = false;
  Completer<void>? _initCompleter;

  LevelPlayInterstitialAd? _interstitial;
  bool interstitialReady = false;
  Completer<void>? _interstitialShowCompleter;
  late final _InterstitialListener _interstitialListener =
      _InterstitialListener(this);

  LevelPlayRewardedAd? _rewarded;
  bool rewardedReady = false;
  VoidCallback? onRewardedCallback;
  VoidCallback? onRewardedClosedCallback;
  Completer<void>? _rewardedShowCompleter;
  late final _RewardedListener _rewardedListener = _RewardedListener(this);

  Future<String> _id(String key) async {
    final v = await SharPreferences.getString(key);
    return (v ?? '').trim();
  }

  Future<void> ensureInitialized() async {
    final appKey = await _id(SharPreferences.levelPlayAppKey);
    if (appKey.isEmpty) return;
    if (initOk) return;
    if (_initStarted && _initCompleter != null) {
      return _initCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );
    }
    _initStarted = true;
    _initCompleter = Completer<void>();
    try {
      final initRequest = LevelPlayInitRequest.builder(appKey).build();
      await LevelPlay.init(initRequest: initRequest, initListener: this);
      await _initCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );
    } catch (e) {
      log('LevelPlay init error: $e');
      initOk = false;
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter!.complete();
      }
    }
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    initOk = true;
    if (!(_initCompleter?.isCompleted ?? true)) {
      _initCompleter!.complete();
    }
    unawaited(preloadInterstitial());
    unawaited(preloadRewarded());
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    initOk = false;
    log('LevelPlay init failed: $error');
    if (!(_initCompleter?.isCompleted ?? true)) {
      _initCompleter!.complete();
    }
  }

  Future<void> preloadInterstitial() async {
    await ensureInitialized();
    if (!initOk) return;
    final unitId = await _id(SharPreferences.levelPlayInterstitialId);
    if (unitId.isEmpty) return;
    try {
      interstitialReady = false;
      _interstitial = LevelPlayInterstitialAd(adUnitId: unitId);
      _interstitial!.setListener(_interstitialListener);
      _interstitial!.loadAd();
    } catch (e) {
      log('LevelPlay interstitial load error: $e');
      interstitialReady = false;
    }
  }

  void completeInterstitialShow() {
    if (!(_interstitialShowCompleter?.isCompleted ?? true)) {
      _interstitialShowCompleter!.complete();
    }
  }

  Future<bool> showInterstitial({
    String placement = LevelPlayPlacements.chapterBetweenInterstitial,
  }) async {
    await ensureInitialized();
    if (!initOk) return false;
    try {
      final ad = _interstitial;
      if (ad == null) {
        await preloadInterstitial();
        return false;
      }
      final ready = await ad.isAdReady();
      if (!ready) return false;
      _interstitialShowCompleter = Completer<void>();
      ad.showAd(placementName: placement);
      await _interstitialShowCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      return true;
    } catch (e) {
      log('LevelPlay interstitial show error: $e');
      return false;
    }
  }

  Future<void> preloadRewarded() async {
    await ensureInitialized();
    if (!initOk) return;
    final unitId = await _id(SharPreferences.levelPlayRewardedId);
    if (unitId.isEmpty) return;
    try {
      rewardedReady = false;
      _rewarded = LevelPlayRewardedAd(adUnitId: unitId);
      _rewarded!.setListener(_rewardedListener);
      _rewarded!.loadAd();
    } catch (e) {
      log('LevelPlay rewarded load error: $e');
      rewardedReady = false;
    }
  }

  void completeRewardedShow() {
    if (!(_rewardedShowCompleter?.isCompleted ?? true)) {
      _rewardedShowCompleter!.complete();
    }
  }

  Future<bool> showRewarded({
    required String placement,
    VoidCallback? onRewarded,
    VoidCallback? onClosed,
  }) async {
    await ensureInitialized();
    if (!initOk) return false;
    try {
      final ad = _rewarded;
      if (ad == null) {
        await preloadRewarded();
        return false;
      }
      final ready = await ad.isAdReady();
      if (!ready) return false;
      onRewardedCallback = onRewarded;
      onRewardedClosedCallback = onClosed;
      _rewardedShowCompleter = Completer<void>();
      ad.showAd(placementName: placement);
      await _rewardedShowCompleter!.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {},
      );
      return true;
    } catch (e) {
      log('LevelPlay rewarded show error: $e');
      return false;
    }
  }
}

class _InterstitialListener implements LevelPlayInterstitialAdListener {
  _InterstitialListener(this.host);
  final LevelPlayAds host;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    host.interstitialReady = true;
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    host.interstitialReady = false;
    log('LevelPlay interstitial failed: $error');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    unawaited(SharPreferences.setString('OpenAd', '1'));
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    host.interstitialReady = false;
    host.completeInterstitialShow();
    unawaited(host.preloadInterstitial());
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    host.interstitialReady = false;
    host.completeInterstitialShow();
    unawaited(SharPreferences.setString('OpenAd', '1'));
    unawaited(host.preloadInterstitial());
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class _RewardedListener implements LevelPlayRewardedAdListener {
  _RewardedListener(this.host);
  final LevelPlayAds host;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    host.rewardedReady = true;
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    host.rewardedReady = false;
    log('LevelPlay rewarded failed: $error');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    unawaited(SharPreferences.setString('OpenAd', '1'));
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    host.rewardedReady = false;
    host.onRewardedClosedCallback?.call();
    host.onRewardedClosedCallback = null;
    host.completeRewardedShow();
    unawaited(host.preloadRewarded());
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    host.rewardedReady = false;
    host.onRewardedClosedCallback?.call();
    host.onRewardedClosedCallback = null;
    host.completeRewardedShow();
    unawaited(host.preloadRewarded());
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    host.onRewardedCallback?.call();
    host.onRewardedCallback = null;
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

/// Banner: LevelPlay if API id exists, otherwise Google [fallback].
class LevelPlayOrGoogleBanner extends StatefulWidget {
  const LevelPlayOrGoogleBanner({super.key, required this.googleFallback});

  final Widget googleFallback;

  @override
  State<LevelPlayOrGoogleBanner> createState() =>
      _LevelPlayOrGoogleBannerState();
}

class _LevelPlayOrGoogleBannerState extends State<LevelPlayOrGoogleBanner>
    implements LevelPlayBannerAdViewListener {
  String _bannerId = '';
  bool _useLevelPlay = false;
  final _bannerKey = GlobalKey<LevelPlayBannerAdViewState>();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await LevelPlayAds.instance.ensureInitialized();
    final id =
        (await SharPreferences.getString(SharPreferences.levelPlayBannerId) ??
                '')
            .trim();
    if (!mounted) return;
    setState(() {
      _bannerId = id;
      _useLevelPlay = id.isNotEmpty && LevelPlayAds.instance.initOk;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_useLevelPlay || _bannerId.isEmpty) {
      return widget.googleFallback;
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: LevelPlayBannerAdView(
        key: _bannerKey,
        adUnitId: _bannerId,
        adSize: LevelPlayAdSize.BANNER,
        listener: this,
        onPlatformViewCreated: () {
          _bannerKey.currentState?.loadAd();
        },
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    if (!mounted) return;
    setState(() => _useLevelPlay = false);
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}
