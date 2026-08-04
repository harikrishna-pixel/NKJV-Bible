import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// Additive Unity LevelPlay (IronSource) helper for Chat interstitial.
/// Does not replace AdMob elsewhere — Chat may fall back to existing AdService.
class LevelPlayAds {
  LevelPlayAds._();
  static final LevelPlayAds instance = LevelPlayAds._();

  static const String appKey = BibleInfo.ironSourceAppKey;

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return BibleInfo.ironSourceInterstitialAdUnitIdAndroid.trim();
    }
    if (Platform.isIOS) {
      return BibleInfo.ironSourceInterstitialAdUnitIdIos.trim();
    }
    return '';
  }

  bool get hasInterstitialAdUnit => _interstitialAdUnitId.isNotEmpty;

  bool _initStarted = false;
  bool _initialized = false;
  LevelPlayInterstitialAd? _interstitialAd;
  Completer<void>? _initCompleter;
  Completer<void>? _showCompleter;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (_initStarted && _initCompleter != null) {
      return _initCompleter!.future;
    }
    _initStarted = true;
    _initCompleter = Completer<void>();
    try {
      LevelPlay.setFlutterVersion('3.5.4');
      final request = LevelPlayInitRequest.builder(appKey).build();
      await LevelPlay.init(
        initRequest: request,
        initListener: _InitListener(
          onSuccess: () {
            _initialized = true;
            if (!(_initCompleter?.isCompleted ?? true)) {
              _initCompleter!.complete();
            }
            debugPrint('LevelPlay init success (appKey=$appKey)');
            _createAndLoadInterstitial();
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

  void preloadChatInterstitial() {
    // Always init with app key so LevelPlay is ready.
    unawaited(ensureInitialized().then((_) {
      if (!hasInterstitialAdUnit) {
        debugPrint(
          'LevelPlay: set BibleInfo.ironSourceInterstitialAdUnitId'
          '${Platform.isIOS ? 'Ios' : 'Android'} '
          '(LevelPlay dashboard → Ad Units → Interstitial) to show IronSource ads on Chat',
        );
        return;
      }
      _createAndLoadInterstitial();
    }));
  }

  void _createAndLoadInterstitial() {
    if (!_initialized || !hasInterstitialAdUnit) return;
    try {
      _interstitialAd ??= LevelPlayInterstitialAd(
        adUnitId: _interstitialAdUnitId,
      );
      _interstitialAd!.setListener(_InterstitialListener(
        onClosedOrFailed: () {
          if (!(_showCompleter?.isCompleted ?? true)) {
            _showCompleter!.complete();
          }
          // Preload next
          _interstitialAd?.loadAd();
        },
      ));
      _interstitialAd!.loadAd();
    } catch (e) {
      debugPrint('LevelPlay load interstitial error: $e');
    }
  }

  /// Returns true if a LevelPlay interstitial was shown (or attempted).
  Future<bool> showChatInterstitialAndWait() async {
    if (!hasInterstitialAdUnit) return false;
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
        return false;
      }
      _showCompleter = Completer<void>();
      await ad.showAd(placementName: 'Default');
      await _showCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      return true;
    } catch (e) {
      debugPrint('LevelPlay show interstitial error: $e');
      return false;
    }
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
