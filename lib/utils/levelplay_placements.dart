import 'package:biblebookapp/view/screens/dashboard/constants.dart';

/// Alias to [AdPlacements] in constants.dart — single source of truth.
/// Call sites keep working; values stay dashboard snake_case.
class LevelPlayPlacements {
  LevelPlayPlacements._();

  // Interstitial
  static const String chapterEndInterstitial =
      AdPlacements.chapterEndInterstitial;
  static const String chapterBetweenInterstitial =
      AdPlacements.chapterBetweenInterstitial;
  static const String readingClickCountInterstitial =
      AdPlacements.readingClickCountInterstitial;
  static const String wallpaperBetweenInterstitial =
      AdPlacements.wallpaperBetweenInterstitial;
  static const String wallpaperDownloadInterstitial =
      AdPlacements.wallpaperDownloadInterstitial;

  // Rewarded
  static const String wallpaperDownloadRewarded =
      AdPlacements.wallpaperDownloadRewarded;
  static const String walletCreditRewarded = AdPlacements.walletCreditRewarded;
}
