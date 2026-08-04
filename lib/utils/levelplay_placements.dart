/// Hardcoded Unity LevelPlay placement names.
/// Must match names configured in the LevelPlay dashboard exactly.
class LevelPlayPlacements {
  LevelPlayPlacements._();

  // Interstitial
  static const String chapterEndInterstitial = 'chapter_end_interstitial';
  static const String chapterBetweenInterstitial =
      'chapter_between_interstitial';
  static const String readingClickCountInterstitial =
      'reading_clickcount_interstitial';
  static const String wallpaperBetweenInterstitial =
      'wallpaper_between_interstitial';
  static const String wallpaperDownloadInterstitial =
      'wallpaper_download_interstitial';

  // Rewarded
  static const String wallpaperDownloadRewarded =
      'wallpaper_download_rewarded';
  static const String walletCreditRewarded = 'wallet_credit_rewarded';
}
