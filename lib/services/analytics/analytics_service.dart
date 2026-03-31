import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// App analytics via Firebase Analytics (replaces former Statsig event logging).
/// Same event names as before so dashboards can be migrated consistently.
class AnalyticsService {
  static bool _initialized = false;
  static FirebaseAnalytics? _analytics;

  static Future<void> initialize() async {
    if (_initialized) return;

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
      _analytics = FirebaseAnalytics.instance;
      // Ensure analytics collection is enabled even if device/config disables it.
      // This is a no-op when already enabled.
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _initialized = true;
    } catch (e) {
      debugPrint('AnalyticsService initialization error: $e');
    }
  }

  static Future<void> _trackEvent(String eventName) async {
    if (!_initialized || _analytics == null) {
      // Events should not be dropped if user taps screens before init finishes.
      await initialize();
    }
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: eventName,
        parameters: const <String, Object>{},
      );
    } catch (e) {
      debugPrint('AnalyticsService tracking error: $e');
    }
  }

  static void _trackEventSync(String eventName) {
    unawaited(_trackEvent(eventName));
  }

  static void trackHomeScreen() => _trackEventSync('home_screen');

  static void trackGenevaBibleChat() => _trackEventSync('geneva_bible_chat');

  static void trackDailyVerses() => _trackEventSync('daily_verses');

  static void trackWallpaper() => _trackEventSync('wallpaper');

  static void trackQuotes() => _trackEventSync('quotes');

  static void trackBooks() => _trackEventSync('books');

  static void trackShare() => _trackEventSync('share');

  static void trackPaywallScreen() => _trackEventSync('paywall_screen');
}
