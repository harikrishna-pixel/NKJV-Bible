/// Per-app analytics switches.
///
/// Same Flutter source ships multiple Bible apps — flip these per app build.
/// Old Paper Bible: both providers ON.
///
/// Never put Mixpanel **API Secret** in the client. Mobile SDK uses
/// [mixpanelToken] (project token) only.
class AnalyticsConfig {
  AnalyticsConfig._();

  /// Firebase Analytics (GA4).
  static bool enableFirebaseAnalytics = true;

  /// Mixpanel.
  static bool enableMixpanelAnalytics = true;

  /// Mixpanel project token (not API secret).
  static String mixpanelToken = 'caf3cf6808c9153ba577226684fc2078';

  /// After init, send one Phase-1 verification event to enabled providers.
  static bool sendPhase1TestEvent = true;
}
