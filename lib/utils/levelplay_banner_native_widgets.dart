import 'package:biblebookapp/utils/levelplay_ads.dart';
import 'package:biblebookapp/utils/levelplay_config.dart';
import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// LevelPlay banner when API/cache has a banner ad unit; otherwise [fallback].
class LevelPlayBannerSlot extends StatefulWidget {
  const LevelPlayBannerSlot({
    super.key,
    this.fallback,
    this.height = 50,
  });

  final Widget? fallback;
  final double height;

  @override
  State<LevelPlayBannerSlot> createState() => _LevelPlayBannerSlotState();
}

class _LevelPlayBannerSlotState extends State<LevelPlayBannerSlot>
    implements LevelPlayBannerAdViewListener {
  final GlobalKey<LevelPlayBannerAdViewState> _bannerKey =
      GlobalKey<LevelPlayBannerAdViewState>();
  String? _adUnitId;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await LevelPlayAds.instance.ensureInitialized();
      final ids = await LevelPlayConfig.loadCached();
      if (!mounted) return;
      if (!ids.hasBanner) {
        setState(() => _failed = true);
        return;
      }
      setState(() => _adUnitId = ids.bannerAdUnitId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bannerKey.currentState?.loadAd();
      });
    } catch (e) {
      debugPrint('LevelPlayBannerSlot error: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _adUnitId == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LevelPlayBannerAdView(
        key: _bannerKey,
        adUnitId: _adUnitId!,
        adSize: LevelPlayAdSize.BANNER,
        listener: this,
        onPlatformViewCreated: () {
          _bannerKey.currentState?.loadAd();
        },
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlayBannerSlot loaded adUnitId=$_adUnitId');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('LevelPlayBannerSlot failed: $error');
    if (mounted) setState(() => _failed = true);
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {
    if (mounted) setState(() => _failed = true);
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}

/// LevelPlay native template when native unit is configured; else [fallback].
class LevelPlayNativeSlot extends StatefulWidget {
  const LevelPlayNativeSlot({
    super.key,
    this.fallback,
    this.height = 300,
  });

  final Widget? fallback;
  final double height;

  @override
  State<LevelPlayNativeSlot> createState() => _LevelPlayNativeSlotState();
}

class _LevelPlayNativeSlotState extends State<LevelPlayNativeSlot>
    implements LevelPlayNativeAdListener {
  LevelPlayNativeAd? _nativeAd;
  bool _failed = false;
  bool _hasNativeUnit = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await LevelPlayAds.instance.ensureInitialized();
      final ids = await LevelPlayConfig.loadCached();
      if (!mounted) return;
      if (!ids.hasNative) {
        setState(() => _failed = true);
        return;
      }
      debugPrint('LevelPlayNativeSlot using nativeAdUnitId=${ids.nativeAdUnitId}');
      _hasNativeUnit = true;
      _nativeAd = LevelPlayNativeAd.builder()
          .withListener(this)
          .build();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nativeAd?.loadAd();
      });
    } catch (e) {
      debugPrint('LevelPlayNativeSlot error: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _nativeAd?.destroyAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_hasNativeUnit || _nativeAd == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LevelPlayNativeAdView(
        nativeAd: _nativeAd,
        templateType: LevelPlayTemplateType.MEDIUM,
        height: widget.height,
        onPlatformViewCreated: () {
          _nativeAd?.loadAd();
        },
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayNativeAd nativeAd, AdInfo adInfo) {
    debugPrint('LevelPlayNativeSlot loaded');
  }

  @override
  void onAdLoadFailed(LevelPlayNativeAd nativeAd, IronSourceError error) {
    debugPrint('LevelPlayNativeSlot failed: $error');
    if (mounted) setState(() => _failed = true);
  }

  @override
  void onAdClicked(LevelPlayNativeAd nativeAd, AdInfo adInfo) {}

  @override
  void onAdImpression(LevelPlayNativeAd nativeAd, AdInfo adInfo) {}
}
