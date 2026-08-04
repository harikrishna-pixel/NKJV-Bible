import 'dart:async';

import 'package:biblebookapp/utils/levelplay_ad_gate.dart';
import 'package:biblebookapp/utils/levelplay_banner_native_widgets.dart';
import 'package:biblebookapp/utils/levelplay_placements.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Display-only ads for Library list tabs (Bookmarks / Highlights / Underlines / Notes).
/// Same pattern as Explore Topics → category detail:
/// - Adaptive banner every 4th list item
/// - Interstitial every 10th Read/Copy/Share/Ask tap
/// Does not change library CRUD or navigation logic.
class LibraryListAdsHelper {
  LibraryListAdsHelper({this.onChanged});

  final VoidCallback? onChanged;

  final AdService _adService = AdService();
  bool adsEnabled = false;
  int actionTapCount = 0;
  final Map<int, BannerAd> _bannerAds = {};
  final Set<int> _bannerSlotsLoading = {};
  bool _initStarted = false;

  /// Call once when a non-empty list is first shown.
  Future<void> initIfNeeded({
    required int itemCount,
    required BuildContext context,
  }) async {
    if (_initStarted || itemCount <= 0) return;
    _initStarted = true;

    final shouldLoad = await SharPreferences.shouldLoadAd();
    if (!shouldLoad || !context.mounted) return;

    adsEnabled = true;
    onChanged?.call();

    _adService.loadInterstitialAd(() {
      onChanged?.call();
    });

    await ensureBannerSlots(itemCount: itemCount, context: context);
  }

  /// Loads any missing banner slots when list length grows after reload.
  Future<void> ensureBannerSlots({
    required int itemCount,
    required BuildContext context,
  }) async {
    if (!adsEnabled || itemCount < 4) return;
    final slotCount = itemCount ~/ 4;
    for (var slot = 0; slot < slotCount; slot++) {
      unawaited(_loadAdaptiveBanner(slot, context));
    }
  }

  Future<void> _loadAdaptiveBanner(int slotIndex, BuildContext context) async {
    if (!adsEnabled) return;
    if (_bannerAds.containsKey(slotIndex) ||
        _bannerSlotsLoading.contains(slotIndex)) {
      return;
    }
    _bannerSlotsLoading.add(slotIndex);

    try {
      if (!context.mounted) {
        _bannerSlotsLoading.remove(slotIndex);
        return;
      }
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      );
      if (size == null || !context.mounted) {
        _bannerSlotsLoading.remove(slotIndex);
        return;
      }

      final adUnitId =
          await SharPreferences.getString(SharPreferences.googleBannerId);
      if (adUnitId == null || adUnitId.isEmpty || !context.mounted) {
        _bannerSlotsLoading.remove(slotIndex);
        return;
      }

      final banner = BannerAd(
        size: size,
        adUnitId: adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerSlotsLoading.remove(slotIndex);
            if (!context.mounted) {
              ad.dispose();
              return;
            }
            _bannerAds[slotIndex] = ad as BannerAd;
            onChanged?.call();
          },
          onAdFailedToLoad: (ad, error) {
            _bannerSlotsLoading.remove(slotIndex);
            ad.dispose();
          },
        ),
        request: await AdConsentManager.getAdRequest(),
      );
      await banner.load();
    } catch (_) {
      _bannerSlotsLoading.remove(slotIndex);
    }
  }

  bool shouldShowBannerAfter(int zeroBasedIndex) {
    final oneBased = zeroBasedIndex + 1;
    return adsEnabled && oneBased % 4 == 0;
  }

  int _slotForIndex(int zeroBasedIndex) => ((zeroBasedIndex + 1) ~/ 4) - 1;

  Widget buildInlineBanner(int zeroBasedIndex, {required String keyPrefix}) {
    final slot = _slotForIndex(zeroBasedIndex);
    final ad = _bannerAds[slot];
    final admob = ad == null
        ? const SizedBox(height: 12)
        : Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14),
            child: Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(key: ValueKey('$keyPrefix-banner-$slot'), ad: ad),
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: LevelPlayBannerSlot(
        height: ad?.size.height.toDouble() ?? 50,
        fallback: admob,
      ),
    );
  }

  /// Counts action taps; every 10th shows interstitial, then runs [action].
  Future<void> runCountedAction(FutureOr<void> Function() action) async {
    actionTapCount++;
    if (actionTapCount % 10 == 0) {
      final shouldLoad = await SharPreferences.shouldLoadAd();
      if (shouldLoad) {
        await LevelPlayAdGate.interstitialOrFallback(
          placementName: LevelPlayPlacements.readingClickCountInterstitial,
          admobFallback: () => _adService.showInterstitialAdAndWait(),
        );
      }
    }
    await action();
  }

  void dispose() {
    for (final ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();
    _bannerSlotsLoading.clear();
  }
}
