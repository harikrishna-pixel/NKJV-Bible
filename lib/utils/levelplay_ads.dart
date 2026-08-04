import 'dart:async';

import 'package:biblebookapp/utils/levelplay_config.dart';
import 'package:biblebookapp/utils/levelplay_placements.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// Additive Unity LevelPlay helper.
/// IDs come from API/cache via [LevelPlayConfig] — never hardcoded.
/// Placement names stay hardcoded in [LevelPlayPlacements].
/// Does not replace AdMob; callers may fall back to AdMob when this returns false.
class LevelPlayAds {
  LevelPlayAds._();
  static final LevelPlayAds instance = LevelPlayAds._();

  LevelPlayIds? _ids;
  bool _initStarted = false;
  bool _initialized = false;
  String? _initializedAppKey;
  Completer<void>? _initCompleter;

  LevelPlayInterstitialAd? _interstitialAd;
  String? _interstitialAdUnitId;
  Completer<void>? _interstitialShowCompleter;

  LevelPlayRewardedAd? _rewardedAd;
  String? _rewardedAdUnitId;
  Completer<bool>? _rewardedShowCompleter;

  LevelPlayIds? get currentIds => _ids;

  Future<LevelPlayIds> _ensureIds() async {
    _ids ??= await LevelPlayConfig.loadCached();
    return _ids!;
  }

  /// Call after API/cache update so next init/load uses fresh IDs.
  Future<void> applyIds(LevelPlayIds ids) async {
    final appKeyChanged =
        _initializedAppKey != null && _initializedAppKey != ids.appKey;
    final interstitialChanged =
        _interstitialAdUnitId != null &&
            _interstitialAdUnitId != ids.interstitialAdUnitId;
    final rewardedChanged =
        _rewardedAdUnitId != null && _rewardedAdUnitId != ids.rewardedAdUnitId;

    _ids = ids;

    if (appKeyChanged) {
      _initialized = false;
      _initStarted = false;
      _initializedAppKey = null;
      _initCompleter = null;
      _interstitialAd = null;
      _interstitialAdUnitId = null;
      _rewardedAd = null;
      _rewardedAdUnitId = null;
    } else {
      if (interstitialChanged) {
        _interstitialAd = null;
        _interstitialAdUnitId = null;
      }
      if (rewardedChanged) {
        _rewardedAd = null;
        _rewardedAdUnitId = null;
      }
    }

    debugPrint('LevelPlayAds.applyIds appKey=${ids.appKey} '
        'banner=${ids.bannerAdUnitId} interstitial=${ids.interstitialAdUnitId} '
        'native=${ids.nativeAdUnitId} rewarded=${ids.rewardedAdUnitId}');
  }

  Future<void> ensureInitialized() async {
    final ids = await _ensureIds();
    if (!ids.hasAppKey) {
      debugPrint('LevelPlay: no app key in API/cache — skip init');
      return;
    }
    if (_initialized && _initializedAppKey == ids.appKey) return;
    if (_initStarted && _initCompleter != null) {
      return _initCompleter!.future;
    }

    _initStarted = true;
    _initCompleter = Completer<void>();
    try {
      LevelPlay.setFlutterVersion('3.5.4');
      final request = LevelPlayInitRequest.builder(ids.appKey).build();
      await LevelPlay.init(
        initRequest: request,
        initListener: _InitListener(
          onSuccess: () {
            _initialized = true;
            _initializedAppKey = ids.appKey;
            if (!(_initCompleter?.isCompleted ?? true)) {
              _initCompleter!.complete();
            }
            debugPrint('LevelPlay init success (appKey=${ids.appKey})');
            debugPrint(
                'LevelPlay IDs in use → banner=${ids.bannerAdUnitId} '
                'interstitial=${ids.interstitialAdUnitId} '
                'native=${ids.nativeAdUnitId} '
                'rewarded=${ids.rewardedAdUnitId}');
            _createAndLoadInterstitial();
            _createAndLoadRewarded();
          },
          onFailed: (error) {
            debugPrint('LevelPlay init failed: $error');
            if (!(_initCompleter?.isCompleted ?? true)) {
              _initCompleter!.complete();
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('LevelPlay init error: $e');
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter!.complete();
      }
    }
    return _initCompleter!.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
  }

  /// Safe entry after API save: init + preload interstitial/rewarded if IDs exist.
  Future<void> bootstrapFromConfig() async {
    try {
      final ids = await LevelPlayConfig.loadCached(printIds: true);
      await applyIds(ids);
      if (!ids.hasAppKey) return;
      await ensureInitialized();
    } catch (e) {
      debugPrint('LevelPlay bootstrap error: $e');
    }
  }

  void preloadChatInterstitial() {
    unawaited(ensureInitialized().then((_) {
      _createAndLoadInterstitial();
    }));
  }

  void preloadInterstitial() {
    unawaited(ensureInitialized().then((_) {
      _createAndLoadInterstitial();
    }));
  }

  void preloadRewarded() {
    unawaited(ensureInitialized().then((_) {
      _createAndLoadRewarded();
    }));
  }

  void _createAndLoadInterstitial() {
    final ids = _ids;
    if (!_initialized || ids == null || !ids.hasInterstitial) {
      if (ids != null && !ids.hasInterstitial) {
        debugPrint(
            'LevelPlay: interstitial ad unit empty — AdMob fallback available');
      }
      return;
    }
    try {
      if (_interstitialAd == null ||
          _interstitialAdUnitId != ids.interstitialAdUnitId) {
        _interstitialAdUnitId = ids.interstitialAdUnitId;
        _interstitialAd = LevelPlayInterstitialAd(
          adUnitId: ids.interstitialAdUnitId,
        );
        _interstitialAd!.setListener(_InterstitialListener(
          onClosedOrFailed: () {
            if (!(_interstitialShowCompleter?.isCompleted ?? true)) {
              _interstitialShowCompleter!.complete();
            }
            _interstitialAd?.loadAd();
          },
        ));
      }
      _interstitialAd!.loadAd();
      debugPrint(
          'LevelPlay load interstitial adUnitId=${ids.interstitialAdUnitId}');
    } catch (e) {
      debugPrint('LevelPlay load interstitial error: $e');
    }
  }

  void _createAndLoadRewarded() {
    final ids = _ids;
    if (!_initialized || ids == null || !ids.hasRewarded) return;
    try {
      if (_rewardedAd == null || _rewardedAdUnitId != ids.rewardedAdUnitId) {
        _rewardedAdUnitId = ids.rewardedAdUnitId;
        _rewardedAd = LevelPlayRewardedAd(adUnitId: ids.rewardedAdUnitId);
        _rewardedAd!.setListener(_RewardedListener(
          onClosed: ({required bool rewarded}) {
            if (!(_rewardedShowCompleter?.isCompleted ?? true)) {
              _rewardedShowCompleter!.complete(rewarded);
            }
            _rewardedAd?.loadAd();
          },
        ));
      }
      _rewardedAd!.loadAd();
      debugPrint('LevelPlay load rewarded adUnitId=${ids.rewardedAdUnitId}');
    } catch (e) {
      debugPrint('LevelPlay load rewarded error: $e');
    }
  }

  Future<bool> isInterstitialReady() async {
    final ad = _interstitialAd;
    if (ad == null || !_initialized) return false;
    try {
      return await ad.isAdReady();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isRewardedReady() async {
    final ad = _rewardedAd;
    if (ad == null || !_initialized) return false;
    try {
      return await ad.isAdReady();
    } catch (_) {
      return false;
    }
  }

  /// Chat back interstitial — uses reading click-count placement.
  Future<bool> showChatInterstitialAndWait() {
    return showInterstitialAndWait(
      LevelPlayPlacements.readingClickCountInterstitial,
    );
  }

  Future<bool> showInterstitialAndWait(String placementName) async {
    final ids = await _ensureIds();
    if (!ids.hasInterstitial) return false;
    await ensureInitialized();
    final ad = _interstitialAd;
    if (ad == null) {
      _createAndLoadInterstitial();
      return false;
    }
    try {
      final ready = await ad.isAdReady();
      if (!ready) {
        ad.loadAd();
        debugPrint(
            'LevelPlay interstitial not ready (placement=$placementName)');
        return false;
      }
      _interstitialShowCompleter = Completer<void>();
      debugPrint(
          'LevelPlay show interstitial adUnitId=${ids.interstitialAdUnitId} '
          'placement=$placementName');
      await ad.showAd(placementName: placementName);
      await _interstitialShowCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      return true;
    } catch (e) {
      debugPrint('LevelPlay show interstitial error: $e');
      return false;
    }
  }

  /// Returns true if user earned the reward.
  Future<bool> showRewardedAndWait(String placementName) async {
    final ids = await _ensureIds();
    if (!ids.hasRewarded) return false;
    await ensureInitialized();
    final ad = _rewardedAd;
    if (ad == null) {
      _createAndLoadRewarded();
      return false;
    }
    try {
      final ready = await ad.isAdReady();
      if (!ready) {
        ad.loadAd();
        debugPrint('LevelPlay rewarded not ready (placement=$placementName)');
        return false;
      }
      _rewardedShowCompleter = Completer<bool>();
      debugPrint(
          'LevelPlay show rewarded adUnitId=${ids.rewardedAdUnitId} '
          'placement=$placementName');
      await ad.showAd(placementName: placementName);
      return await _rewardedShowCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('LevelPlay show rewarded error: $e');
      return false;
    }
  }

  Future<String?> bannerAdUnitId() async {
    final ids = await _ensureIds();
    return ids.hasBanner ? ids.bannerAdUnitId : null;
  }

  Future<String?> nativeAdUnitId() async {
    final ids = await _ensureIds();
    return ids.hasNative ? ids.nativeAdUnitId : null;
  }
}

class _InitListener implements LevelPlayInitListener {
  _InitListener({required this.onSuccess, required this.onFailed});
  final VoidCallback onSuccess;
  final void Function(LevelPlayInitError error) onFailed;

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) => onSuccess();

  @override
  void onInitFailed(LevelPlayInitError error) => onFailed(error);
}

class _InterstitialListener implements LevelPlayInterstitialAdListener {
  _InterstitialListener({required this.onClosedOrFailed});
  final VoidCallback onClosedOrFailed;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay interstitial loaded');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('LevelPlay interstitial load failed: $error');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    onClosedOrFailed();
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    onClosedOrFailed();
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class _RewardedListener implements LevelPlayRewardedAdListener {
  _RewardedListener({required this.onClosed});
  final void Function({required bool rewarded}) onClosed;
  bool _rewarded = false;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay rewarded loaded');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('LevelPlay rewarded load failed: $error');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    _rewarded = false;
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    onClosed(rewarded: false);
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    onClosed(rewarded: _rewarded);
  }

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    _rewarded = true;
    debugPrint('LevelPlay rewarded earned: ${reward.name} ${reward.amount}');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}
