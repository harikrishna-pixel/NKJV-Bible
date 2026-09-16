/// Centralized analytics event names and property keys.
///
/// Keep names consistent across apps. Do not invent ad-hoc event strings in
/// screens — call [AnalyticsService] with these constants.
///
/// Phase 1: only [phase1Test] is emitted (from [AnalyticsService.initialize]).
/// Onboarding / screen / paywall events are defined here for Phase 2+.
class AnalyticsEvents {
  AnalyticsEvents._();

  // --- Phase 1 verification ---
  static const String phase1Test = 'analytics_phase1_test';

  // --- Onboarding (Phase 2+) ---
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepViewed = 'onboarding_step_viewed';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String onboardingCompleted = 'onboarding_completed';

  // --- Screen / feature engagement (Phase 2+) ---
  static const String screenViewed = 'screen_viewed';
  static const String screenExited = 'screen_exited';
  static const String featureUsed = 'feature_used';

  // --- Paywall / monetization (Phase 2+) ---
  static const String paywallViewed = 'paywall_viewed';
  static const String paywallClosed = 'paywall_closed';
  static const String planSelected = 'plan_selected';
  static const String purchaseStarted = 'purchase_started';
  static const String purchaseSuccess = 'purchase_success';
  static const String purchaseFailed = 'purchase_failed';
  static const String subscriptionRestored = 'subscription_restored';

  // --- Legacy screen taps (existing app calls; keep names stable) ---
  static const String homeScreen = 'home_screen';
  static const String genevaBibleChat = 'geneva_bible_chat';
  static const String dailyVerses = 'daily_verses';
  static const String wallpaper = 'wallpaper';
  static const String quotes = 'quotes';
  static const String books = 'books';
  static const String share = 'share';
  static const String paywallScreen = 'paywall_screen';
}

/// Shared property keys. Never attach private user content (chat text, notes,
/// raw search queries, etc.) — track actions only.
class AnalyticsProps {
  AnalyticsProps._();

  static const String stepNumber = 'step_number';
  static const String stepName = 'step_name';
  static const String durationSeconds = 'duration_seconds';
  static const String screenName = 'screen_name';
  static const String featureName = 'feature_name';
  static const String paywallSource = 'paywall_source';
  static const String plan = 'plan';
  static const String price = 'price';
  static const String currency = 'currency';
  static const String offerType = 'offer_type';
  static const String isTrial = 'is_trial';
  static const String phase = 'phase';
  static const String provider = 'provider';
  static const String appName = 'app_name';
}
