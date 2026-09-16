import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/firebase_options.dart';
import 'package:biblebookapp/services/analytics/analytics_config.dart';
import 'package:biblebookapp/services/analytics/analytics_events.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Single entry point for product analytics.
///
/// Screens must call this service — never Firebase / Mixpanel SDKs directly.
/// Providers are optional per app via [AnalyticsConfig].
///
/// Existing [trackHomeScreen]-style helpers keep the same event names; they
/// now fan out to enabled providers. No app business logic changes here.
class AnalyticsService {
  static bool _initialized = false;
  static FirebaseAnalytics? _firebase;
  static Mixpanel? _mixpanel;
  static bool _phase1TestSent = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (AnalyticsConfig.enableFirebaseAnalytics) {
        await _initFirebase();
      }
      if (AnalyticsConfig.enableMixpanelAnalytics) {
        await _initMixpanel();
      }
      _initialized = true;

      if (AnalyticsConfig.sendPhase1TestEvent && !_phase1TestSent) {
        _phase1TestSent = true;
        await track(
          AnalyticsEvents.phase1Test,
          properties: {
            AnalyticsProps.phase: 1,
            AnalyticsProps.appName: BibleInfo.bible_shortName,
            AnalyticsProps.provider: _enabledProvidersLabel(),
          },
        );
        // Push Mixpanel queue promptly so Phase-1 Live View can confirm.
        try {
          await _mixpanel?.flush();
        } catch (_) {}
        debugPrint(
          'AnalyticsService: Phase-1 test event sent '
          '(${_enabledProvidersLabel()})',
        );
      }
    } catch (e) {
      debugPrint('AnalyticsService initialization error: $e');
    }
  }

  static Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        // iOS should rely on `GoogleService-Info.plist` (added to Runner),
        // otherwise the `firebase_options.dart` bundle-id/project can mismatch.
        if (!kIsWeb && Platform.isIOS) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      }
      _firebase = FirebaseAnalytics.instance;
      await _firebase!.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('AnalyticsService Firebase init error: $e');
      _firebase = null;
    }
  }

  static Future<void> _initMixpanel() async {
    try {
      final token = AnalyticsConfig.mixpanelToken.trim();
      if (token.isEmpty) {
        debugPrint('AnalyticsService: Mixpanel token empty — skipped');
        return;
      }
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: false,
      );
    } catch (e) {
      debugPrint('AnalyticsService Mixpanel init error: $e');
      _mixpanel = null;
    }
  }

  static String _enabledProvidersLabel() {
    final parts = <String>[];
    if (AnalyticsConfig.enableFirebaseAnalytics && _firebase != null) {
      parts.add('firebase');
    }
    if (AnalyticsConfig.enableMixpanelAnalytics && _mixpanel != null) {
      parts.add('mixpanel');
    }
    return parts.isEmpty ? 'none' : parts.join('+');
  }

  /// Preferred API for all new tracking. Properties must not include private
  /// user content (messages, notes, search text, etc.).
  static Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    final name = eventName.trim();
    if (name.isEmpty) return;

    final props = _sanitizeProperties(properties);

    if (AnalyticsConfig.enableFirebaseAnalytics && _firebase != null) {
      try {
        await _firebase!.logEvent(
          name: _firebaseEventName(name),
          parameters: props.isEmpty ? null : Map<String, Object>.from(props),
        );
      } catch (e) {
        debugPrint('AnalyticsService Firebase track error: $e');
      }
    }

    if (AnalyticsConfig.enableMixpanelAnalytics && _mixpanel != null) {
      try {
        await _mixpanel!.track(name, properties: props.isEmpty ? null : props);
      } catch (e) {
        debugPrint('AnalyticsService Mixpanel track error: $e');
      }
    }
  }

  static void trackSync(
    String eventName, {
    Map<String, dynamic>? properties,
  }) {
    unawaited(track(eventName, properties: properties));
  }

  /// Firebase: name max 40 chars, alphanumeric + underscore.
  static String _firebaseEventName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (cleaned.length <= 40) return cleaned;
    return cleaned.substring(0, 40);
  }

  /// Keep only analytics-safe primitives for both SDKs.
  static Map<String, dynamic> _sanitizeProperties(
    Map<String, dynamic>? properties,
  ) {
    if (properties == null || properties.isEmpty) return {};
    final out = <String, dynamic>{};
    properties.forEach((key, value) {
      if (key.trim().isEmpty || value == null) return;
      if (value is String || value is num || value is bool) {
        out[key] = value is bool ? (value ? 1 : 0) : value;
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }

  // ---------------------------------------------------------------------------
  // Legacy helpers — same event names as before; now dual-provider.
  // Do not remove; call sites across the app depend on these.
  // ---------------------------------------------------------------------------

  static Future<void> _trackEvent(String eventName) => track(eventName);

  static void _trackEventSync(String eventName) {
    unawaited(_trackEvent(eventName));
  }

  static void trackHomeScreen() =>
      _trackEventSync(AnalyticsEvents.homeScreen);

  static void trackGenevaBibleChat() =>
      _trackEventSync(AnalyticsEvents.genevaBibleChat);

  static void trackDailyVerses() =>
      _trackEventSync(AnalyticsEvents.dailyVerses);

  static void trackWallpaper() => _trackEventSync(AnalyticsEvents.wallpaper);

  static void trackQuotes() => _trackEventSync(AnalyticsEvents.quotes);

  static void trackBooks() => _trackEventSync(AnalyticsEvents.books);

  static void trackShare() => _trackEventSync(AnalyticsEvents.share);

  static void trackPaywallScreen() =>
      _trackEventSync(AnalyticsEvents.paywallScreen);
}
