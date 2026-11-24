import 'dart:async';
import 'dart:convert';

import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/services/analytics/mixpanel_config.dart';
import 'package:biblebookapp/services/analytics/mixpanel_tracking_gate.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixpanel analytics for Old Paper (15 mandatory events only).
/// Keeps Firebase [AnalyticsService] unchanged.
class MixpanelAnalyticsService {
  MixpanelAnalyticsService._();

  static const _prefsConfig = 'mixpanel_remote_config_v1';
  static const _prefsSampled = 'mixpanel_sampled_in_v1';
  static const _prefsEventsDate = 'mixpanel_events_date_v1';
  static const _prefsEventsCount = 'mixpanel_events_count_v1';
  static const _prefsAppOpenDate = 'mixpanel_app_open_date_v1';
  static const _prefsFirstOpen = 'mixpanel_first_open_date_v1';
  static const _prefsStreak = 'mixpanel_streak_day_v1';
  static const _prefsLastOpen = 'mixpanel_last_open_date_v1';
  static const _prefsOnboardingStart = 'mixpanel_onboarding_start_ms_v1';
  static const _prefsWidgetPrefix = 'mixpanel_widget_added_';

  static Mixpanel? _mixpanel;
  static MixpanelRemoteConfig? _config;
  static bool? _sampledIn;
  static String _anonymousId = '';
  static bool _initStarted = false;
  static bool _ready = false;
  static final Set<String> _featuresUsedThisSession = <String>{};
  static DateTime? _paywallShownAt;

  /// Non-blocking launch hook. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadCachedConfig(prefs);

      _mixpanel = await Mixpanel.init(
        MixpanelConfig.token,
        trackAutomaticEvents: false,
      );
      _anonymousId = (await _mixpanel!.getDistinctId()).trim();
      await _registerSuperProperties();

      // Config fetch must not block startup — fire and continue.
      unawaited(_fetchRemoteConfig());

      // If we already have a cached allow, send app_open / widgets now.
      if (_canTrack()) {
        await trackAppOpenDaily();
        await checkWidgetAddedOnOpen();
      }
      _ready = true;
    } catch (e) {
      debugPrint('MixpanelAnalyticsService init error: $e');
    }
  }

  static void _loadCachedConfig(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsConfig);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _config = MixpanelRemoteConfig.fromJson(map);
      if (prefs.containsKey(_prefsSampled)) {
        _sampledIn = prefs.getBool(_prefsSampled);
      }
    } catch (e) {
      debugPrint('MixpanelAnalyticsService cache parse error: $e');
    }
  }

  static Future<void> _fetchRemoteConfig() async {
    try {
      final appId = BibleInfo.apple_AppId.trim();
      final uri = Uri.parse(
        '${MixpanelConfig.configUrlBase}?app_id=${Uri.encodeQueryComponent(appId)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      final config =
          MixpanelRemoteConfig.fromJson(Map<String, dynamic>.from(decoded));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsConfig, jsonEncode(config.toJson()));
      _config = config;

      final sampled = MixpanelTrackingGate.isSampledIn(
        anonymousId: _anonymousId,
        samplePct: config.samplePct,
      );
      _sampledIn = sampled;
      await prefs.setBool(_prefsSampled, sampled);

      if (_canTrack()) {
        await trackAppOpenDaily();
        await checkWidgetAddedOnOpen();
      }
    } catch (e) {
      debugPrint('MixpanelAnalyticsService config fetch error: $e');
      // Fail closed if no cache; keep cache if present.
    }
  }

  static Future<void> _registerSuperProperties() async {
    if (_mixpanel == null) return;
    String appVersion = BibleInfo.current_Version;
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.trim().isNotEmpty) appVersion = info.version.trim();
    } catch (_) {}

    final isPro = await BibleInfo.hasActivePremiumPlan();
    final locale = PlatformDispatcher.instance.locale.toString();
    final bibleVersion = _bibleVersionCode(BibleInfo.bible_shortName);

    await _mixpanel!.registerSuperProperties({
      'app_id': BibleInfo.apple_AppId,
      'app_name': BibleInfo.bible_shortName,
      'bible_version': bibleVersion,
      'theme': 'old_paper',
      'app_version': appVersion,
      'is_pro': isPro,
      'locale': locale,
      'environment': MixpanelConfig.environment,
    });
  }

  static String _bibleVersionCode(String shortName) {
    final s = shortName.trim();
    if (s.toLowerCase().endsWith(' bible')) {
      return s.substring(0, s.length - 6).trim();
    }
    return s;
  }

  /// Call after purchase / restore so [is_pro] stays current.
  static Future<void> updateIsPro(bool isPro) async {
    if (_mixpanel == null) return;
    try {
      await _mixpanel!.registerSuperProperties({'is_pro': isPro});
    } catch (e) {
      debugPrint('MixpanelAnalyticsService updateIsPro error: $e');
    }
  }

  static bool _canTrack() {
    return MixpanelTrackingGate.canSendEvent(
      config: _config,
      sampledInCached: _sampledIn,
      anonymousId: _anonymousId,
      eventsSentToday: _eventsSentTodaySync(),
    );
  }

  static int _eventsSentTodaySync() {
    // Best-effort; async path refreshes before each track.
    return 0;
  }

  static Future<bool> _prepareTrack() async {
    if (_mixpanel == null) return false;
    final prefs = await SharedPreferences.getInstance();
    if (_config == null) _loadCachedConfig(prefs);

    final today = MixpanelTrackingGate.dateYmd(DateTime.now());
    final storedDate = prefs.getString(_prefsEventsDate);
    var count = prefs.getInt(_prefsEventsCount) ?? 0;
    if (storedDate != today) {
      count = 0;
      await prefs.setString(_prefsEventsDate, today);
      await prefs.setInt(_prefsEventsCount, 0);
    }

    final allowed = MixpanelTrackingGate.canSendEvent(
      config: _config,
      sampledInCached: _sampledIn,
      anonymousId: _anonymousId,
      eventsSentToday: count,
    );
    return allowed;
  }

  static Future<void> _track(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    try {
      if (!await _prepareTrack()) return;
      if (_mixpanel == null) return;

      // Never attach free-form user text.
      final safe = <String, dynamic>{};
      if (properties != null) {
        for (final e in properties.entries) {
          final v = e.value;
          if (v == null) continue;
          if (v is String || v is num || v is bool) {
            safe[e.key] = v;
          }
        }
      }

      await _mixpanel!.track(eventName, properties: safe);

      final prefs = await SharedPreferences.getInstance();
      final today = MixpanelTrackingGate.dateYmd(DateTime.now());
      final storedDate = prefs.getString(_prefsEventsDate);
      var count = prefs.getInt(_prefsEventsCount) ?? 0;
      if (storedDate != today) count = 0;
      count += 1;
      await prefs.setString(_prefsEventsDate, today);
      await prefs.setInt(_prefsEventsCount, count);
    } catch (e) {
      debugPrint('MixpanelAnalyticsService track $eventName error: $e');
    }
  }

  // ─── 15 mandatory events ───────────────────────────────────────────

  static Future<void> trackAppOpenDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = MixpanelTrackingGate.dateYmd(now);
    final lastSent = prefs.getString(_prefsAppOpenDate);
    if (!MixpanelTrackingGate.shouldSendAppOpenDaily(
      lastSentDateYmd: lastSent,
      now: now,
    )) {
      return;
    }

    var firstOpen = prefs.getString(_prefsFirstOpen);
    if (firstOpen == null || firstOpen.isEmpty) {
      firstOpen = today;
      await prefs.setString(_prefsFirstOpen, firstOpen);
    }

    final lastOpen = prefs.getString(_prefsLastOpen);
    final prevStreak = prefs.getInt(_prefsStreak) ?? 0;
    final streak = MixpanelTrackingGate.nextStreakDay(
      lastOpenDateYmd: lastOpen,
      previousStreak: prevStreak,
      now: now,
    );
    final days = MixpanelTrackingGate.daysSinceInstall(
      firstOpenDateYmd: firstOpen,
      now: now,
    );

    await _track('app_open_daily', {
      'days_since_install': days,
      'streak_day': streak,
    });

    await prefs.setString(_prefsAppOpenDate, today);
    await prefs.setString(_prefsLastOpen, today);
    await prefs.setInt(_prefsStreak, streak);
  }

  static Future<void> trackOnboardingStepViewed({
    required int stepIndex,
    required String stepName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_prefsOnboardingStart) == null) {
      await prefs.setInt(
        _prefsOnboardingStart,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    await _track('onboarding_step_viewed', {
      'step_index': stepIndex,
      'step_name': stepName,
    });
  }

  static Future<void> trackOnboardingCompleted({
    required int stepsTotal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_prefsOnboardingStart);
    final seconds = startMs == null
        ? 0
        : ((DateTime.now().millisecondsSinceEpoch - startMs) / 1000)
            .round()
            .clamp(0, 86400);
    await _track('onboarding_completed', {
      'steps_total': stepsTotal,
      'seconds_total': seconds,
    });
  }

  static Future<void> trackFeatureUsed(String featureName) async {
    final key = featureName.trim();
    if (key.isEmpty) return;
    if (_featuresUsedThisSession.contains(key)) return;
    _featuresUsedThisSession.add(key);
    await _track('feature_used', {'feature_name': key});
  }

  static Future<void> trackPrayerWallOpened({String source = 'home'}) async {
    await _track('prayer_wall_opened', {'source': source});
  }

  /// Never pass prayer text.
  static Future<void> trackPrayerWallPostCreated({String? category}) async {
    final props = <String, dynamic>{};
    final c = (category ?? '').trim();
    if (c.isNotEmpty) props['category'] = c;
    await _track('prayer_wall_post_created', props);
  }

  static Future<void> trackCustomPrayerGenerated({
    required String method,
  }) async {
    await _track('custom_prayer_generated', {
      'method': method == 'manual' ? 'manual' : 'ai',
    });
  }

  static Future<void> trackCustomPrayerRead({
    required int readSeconds,
  }) async {
    final capped = readSeconds.clamp(5, 120);
    await _track('custom_prayer_read', {'read_seconds': capped});
  }

  static Future<void> trackWidgetAdded({
    required String widgetType,
    required String family,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsWidgetPrefix$widgetType';
    if (prefs.getBool(key) == true) return;
    await _track('widget_added', {
      'widget_type': widgetType,
      'family': family,
    });
    await prefs.setBool(key, true);
  }

  static Future<void> checkWidgetAddedOnOpen() async {
    try {
      final kinds = await installedHomeWidgetKinds();
      for (final kind in kinds) {
        await trackWidgetAdded(
          widgetType: kind,
          family: _familyForWidgetKind(kind),
        );
      }
    } catch (e) {
      debugPrint('MixpanelAnalyticsService widget check error: $e');
    }
  }

  static String _familyForWidgetKind(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('small')) return 'small';
    if (k.contains('large')) return 'large';
    if (k.contains('medium')) return 'medium';
    return 'medium';
  }

  static Future<void> trackPaywallShown({
    String trigger = 'unknown',
    String placement = 'full_screen',
    String variant = 'default',
  }) async {
    _paywallShownAt = DateTime.now();
    await _track('paywall_shown', {
      'trigger': trigger,
      'placement': placement,
      'variant': variant,
    });
  }

  static Future<void> trackPaywallPlanSelected({
    required String planId,
    String priceTier = 'unknown',
  }) async {
    await _track('paywall_plan_selected', {
      'plan_id': planId,
      'price_tier': priceTier,
    });
  }

  static Future<void> trackPaywallDismissed({
    String trigger = 'unknown',
  }) async {
    final started = _paywallShownAt;
    final seconds = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds.clamp(0, 3600);
    await _track('paywall_dismissed', {
      'trigger': trigger,
      'seconds_visible': seconds,
    });
  }

  static Future<void> trackExitOfferShown({
    String trigger = 'unknown',
    String offerId = 'exit_yearly',
  }) async {
    await _track('exit_offer_shown', {
      'trigger': trigger,
      'offer_id': offerId,
    });
  }

  static Future<void> trackExitOfferConverted({
    required String planId,
    String offerId = 'exit_yearly',
  }) async {
    await _track('exit_offer_converted', {
      'offer_id': offerId,
      'plan_id': planId,
    });
  }

  static Future<void> trackPurchaseSuccess({
    required String planId,
    String trigger = 'unknown',
    bool isTrial = false,
  }) async {
    await _track('purchase_success', {
      'plan_id': planId,
      'trigger': trigger,
      'is_trial': isTrial,
    });
    await updateIsPro(true);
  }

  // Visible for tests / debug.
  static bool get debugHasConfig => _config != null;
  static bool get debugReady => _ready;
  static MixpanelRemoteConfig? get debugConfig => _config;
}
