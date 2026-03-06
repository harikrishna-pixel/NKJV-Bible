// Home Screen Widget support for iOS only.
// Provides: Verse of the day, Bible Prayer, Bible Chat.
// Uses the home_widget package; native Widget Extension must be set up in Xcode.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Route to open when user taps a home widget. App should navigate to the matching screen.
enum BibleWidgetRoute { verse, prayer, chat, none }

/// Parses a widget launch URI (e.g. biblebookapp://prayer?homeWidget) and returns the route.
BibleWidgetRoute getBibleWidgetRouteFromUri(Uri? uri) {
  if (uri == null) return BibleWidgetRoute.none;
  final host = uri.host.toLowerCase();
  if (host == kWidgetRouteVerse) return BibleWidgetRoute.verse;
  if (host == kWidgetRoutePrayer) return BibleWidgetRoute.prayer;
  if (host == kWidgetRouteChat) return BibleWidgetRoute.chat;
  return BibleWidgetRoute.none;
}

/// App Group ID for sharing data between the app and the Widget Extension.
/// Must match the App Group identifier added in Xcode for both Runner and the Widget Extension.
const String _kAppGroupId = 'group.com.balaklrapps.genevabible';

/// Widget kinds (must match the `kind` in each Widget struct in the iOS Widget Extension).
const String _kVerseOfTheDayKind = 'VerseOfTheDayWidget';
const String _kBiblePrayerKind = 'BiblePrayerWidget';
const String _kBibleChatKind = 'BibleChatWidget';

/// Data keys stored in UserDefaults (App Group) for the widgets.
const String _kVerseTextKey = 'widget_verse_text';
const String _kVerseReferenceKey = 'widget_verse_reference';

/// Keys exposed so app can read widget verse when opening from widget tap.
const String kWidgetVerseTextKey = _kVerseTextKey;
const String kWidgetVerseReferenceKey = _kVerseReferenceKey;
const String _kBiblePrayerTitleKey = 'widget_bible_prayer_title';
const String _kPrayerTextKey = 'widget_prayer_text';
const String _kChatQuestionKey = 'widget_chat_question';
const String _kChatAnswerKey = 'widget_chat_answer';
const String _kBibleChatTitleKey = 'widget_bible_chat_title';

/// Deep-link host names when user taps a widget (must match widgetURL in Swift).
const String kWidgetRouteVerse = 'verse';
const String kWidgetRoutePrayer = 'prayer';
const String kWidgetRouteChat = 'chat';

/// Returns the verse text and reference currently shown on the Verse of the Day widget.
/// Use when opening Daily Verse from widget tap so the same verse is displayed.
Future<Map<String, String?>> getVerseOfTheDayWidgetData() async {
  if (!Platform.isIOS) return {};
  try {
    final text = await HomeWidget.getWidgetData<String>(_kVerseTextKey);
    final ref = await HomeWidget.getWidgetData<String>(_kVerseReferenceKey);
    return {'text': text, 'reference': ref};
  } catch (e) {
    debugPrint('BibleHomeWidget: getVerseOfTheDayWidgetData failed: $e');
    return {};
  }
}

/// Call once at app startup (e.g. from main()) so the app can communicate with the Widget Extension.
/// No-op on non-iOS. Does not change any existing logic.
Future<void> initBibleHomeWidget() async {
  if (!Platform.isIOS) return;
  try {
    await HomeWidget.setAppGroupId(_kAppGroupId);
  } catch (e) {
    debugPrint('BibleHomeWidget: setAppGroupId failed: $e');
  }
}

/// Default verse shown in widget when app has not provided data.
const String _kDefaultVerseText =
    'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.';
const String _kDefaultVerseRef = 'John 3:16';

/// Updates the "Verse of the day" widget with the given verse text and reference.
/// Uses defaults if empty. Call after loading daily verses (e.g. from DownloadProvider.loadDailyVerses).
/// No-op on non-iOS.
Future<void> updateVerseOfTheDayWidget({
  required String verseText,
  required String reference,
}) async {
  if (!Platform.isIOS) return;
  try {
    final text = verseText.trim().isEmpty ? _kDefaultVerseText : verseText;
    final ref = reference.trim().isEmpty ? _kDefaultVerseRef : reference;
    await HomeWidget.saveWidgetData<String>(_kVerseTextKey, text);
    await HomeWidget.saveWidgetData<String>(_kVerseReferenceKey, ref);
    await HomeWidget.updateWidget(iOSName: _kVerseOfTheDayKind);
  } catch (e) {
    debugPrint('BibleHomeWidget: updateVerseOfTheDayWidget failed: $e');
  }
}

/// Updates the "Bible Prayer" widget with optional prayer text (shown in widget).
/// No-op on non-iOS.
Future<void> updateBiblePrayerWidget({String? prayerText}) async {
  if (!Platform.isIOS) return;
  try {
    await HomeWidget.saveWidgetData<String>(
        _kBiblePrayerTitleKey, 'Bible Prayer');
    if (prayerText != null && prayerText.trim().isNotEmpty) {
      final snippet = prayerText.length > 280
          ? '${prayerText.trim().substring(0, 280)}...'
          : prayerText.trim();
      await HomeWidget.saveWidgetData<String>(_kPrayerTextKey, snippet);
    }
    await HomeWidget.updateWidget(iOSName: _kBiblePrayerKind);
  } catch (e) {
    debugPrint('BibleHomeWidget: updateBiblePrayerWidget failed: $e');
  }
}

/// Updates the "Bible Chat" widget with optional question and answer (shown in widget).
/// No-op on non-iOS.
Future<void> updateBibleChatWidget({String? question, String? answer}) async {
  if (!Platform.isIOS) return;
  try {
    await HomeWidget.saveWidgetData<String>(_kBibleChatTitleKey, 'Bible Chat');
    if (question != null && question.trim().isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
          _kChatQuestionKey, question.trim().length > 120 ? '${question.trim().substring(0, 120)}...' : question.trim());
    }
    if (answer != null && answer.trim().isNotEmpty) {
      final snippet = answer.length > 240
          ? '${answer.trim().substring(0, 240)}...'
          : answer.trim();
      await HomeWidget.saveWidgetData<String>(_kChatAnswerKey, snippet);
    }
    await HomeWidget.updateWidget(iOSName: _kBibleChatKind);
  } catch (e) {
    debugPrint('BibleHomeWidget: updateBibleChatWidget failed: $e');
  }
}

/// Call once after app is ready (e.g. when home is first built) to refresh
/// launcher widgets so they show default content. No-op on non-iOS.
Future<void> updateAllLauncherWidgets() async {
  if (!Platform.isIOS) return;
  try {
    await updateBiblePrayerWidget();
    await updateBibleChatWidget();
  } catch (e) {
    debugPrint('BibleHomeWidget: updateAllLauncherWidgets failed: $e');
  }
}
