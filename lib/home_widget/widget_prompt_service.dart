import 'dart:io';

import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/live_activity/content_live_activity.dart';
import 'package:biblebookapp/live_activity/live_activity_queue.dart';
import 'package:biblebookapp/streak/streak_live_activity.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/add_widget_intro_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Additive widget-prompt ids from Old Paper PREMIUM mockups.
enum WidgetPromptId { a1, a2, a6, a8, a8b }

/// Prompt visibility, decline cooldown, and how-to add — does not change
/// streak, IAP, ads, or mark-as-read eligibility.
class WidgetPromptService {
  WidgetPromptService._();

  static int sessionChapterCompletes = 0;

  static const _lifetimeChaptersKey = 'widget_prompt_lifetime_chapters';
  static const _prayerGeneratedKey = 'widget_prompt_prayer_generated_count';

  static String _declineKey(WidgetPromptId id) =>
      'widget_prompt_${id.name}_decline_count';
  static String _hideUntilKey(WidgetPromptId id) =>
      'widget_prompt_${id.name}_hide_until_ms';

  static String kindFor(WidgetPromptId id) {
    switch (id) {
      case WidgetPromptId.a1:
        return kContinueReadingWidgetKind;
      case WidgetPromptId.a2:
        return kWeeklyStreakWidgetKind;
      case WidgetPromptId.a6:
        return kFavoriteVerseWidgetKind;
      case WidgetPromptId.a8:
      case WidgetPromptId.a8b:
        return kBiblePrayerWidgetKind;
    }
  }

  static Future<void> noteChapterCompleted() async {
    sessionChapterCompletes++;
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_lifetimeChaptersKey) ?? 0;
    await prefs.setInt(_lifetimeChaptersKey, n + 1);
  }

  static Future<bool> a1TriggerMet() async {
    final prefs = await SharedPreferences.getInstance();
    final lifetime = prefs.getInt(_lifetimeChaptersKey) ?? 0;
    return sessionChapterCompletes >= 2 || lifetime >= 5;
  }

  static Future<void> notePrayerGenerated() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_prayerGeneratedKey) ?? 0;
    await prefs.setInt(_prayerGeneratedKey, n + 1);
  }

  static Future<int> prayerGeneratedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prayerGeneratedKey) ?? 0;
  }

  static Future<bool> shouldShow(
    WidgetPromptId id, {
    required bool triggerMet,
  }) async {
    if (!triggerMet) return false;

    final kindInstalled = await isHomeWidgetKindInstalled(kindFor(id));
    if (kindInstalled) return false;

    // A8 is always-on UI (second action), not a frequency-limited prompt.
    if (id == WidgetPromptId.a8) return true;

    if (await _hasOpenedHowTo(id)) return false;

    if (await isAnyHomeWidgetInstalled()) return false;

    final prefs = await SharedPreferences.getInstance();
    final declines = prefs.getInt(_declineKey(id)) ?? 0;
    if (declines >= 3) return false;
    final hideUntil = prefs.getInt(_hideUntilKey(id)) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < hideUntil) return false;
    return true;
  }

  static Future<void> markDismissed(WidgetPromptId id) async {
    if (id == WidgetPromptId.a8) return;
    final prefs = await SharedPreferences.getInstance();
    final declines = (prefs.getInt(_declineKey(id)) ?? 0) + 1;
    await prefs.setInt(_declineKey(id), declines);
    final now = DateTime.now();
    DateTime until;
    if (declines == 1) {
      until = now.add(const Duration(days: 7));
    } else if (declines == 2) {
      until = now.add(const Duration(days: 30));
    } else {
      until = DateTime(now.year + 50);
    }
    await prefs.setInt(_hideUntilKey(id), until.millisecondsSinceEpoch);
    debugPrint(
        'WidgetPrompt: ${id.name} dismissed count=$declines hideUntil=$until');
  }

  static String titleFor(WidgetPromptId id) {
    switch (id) {
      case WidgetPromptId.a1:
        return 'Continue Reading';
      case WidgetPromptId.a2:
        return 'Weekly Reading Streak';
      case WidgetPromptId.a6:
        return 'Favorite Verse';
      case WidgetPromptId.a8:
      case WidgetPromptId.a8b:
        return 'Bible Prayer';
    }
  }

  /// Same iOS start path as existing Live Activities (`forceStart: true`).
  /// Does not change streak / reading / verse logic — only calls existing sync.
  static Future<void> startExistingIosWidget(WidgetPromptId id) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      switch (id) {
        case WidgetPromptId.a1:
          await ContentLiveActivitySync.syncContinueReading(forceStart: true);
          break;
        case WidgetPromptId.a2:
          await StreakLiveActivitySync.sync(forceStart: true);
          break;
        case WidgetPromptId.a6:
          await ContentLiveActivitySync.syncMemoryVerse(forceStart: true);
          break;
        case WidgetPromptId.a8:
        case WidgetPromptId.a8b:
          await LiveActivityQueue.sync(forceStart: true);
          break;
      }
    } catch (e) {
      debugPrint('WidgetPrompt: startExistingIosWidget failed: $e');
    }
  }

  static List<String> previewImagesFor(WidgetPromptId id) {
    switch (id) {
      case WidgetPromptId.a2:
        return const [
          'assets/bible_widget/Reading_Streak_1.png',
          'assets/bible_widget/Reading_Streak_2.png',
          'assets/bible_widget/Reading_Streak_3.png',
        ];
      case WidgetPromptId.a6:
        return const [
          'assets/bible_widget/Favorite_Verse.png',
          'assets/bible_widget/Favorite_Verse_2.png',
          'assets/bible_widget/Favorite_Verse_3.png',
        ];
      case WidgetPromptId.a8:
      case WidgetPromptId.a8b:
        return const [
          'assets/bible_widget/Bible_Prayer_1.png',
          'assets/bible_widget/Bible_Prayer_2.png',
          'assets/bible_widget/Bible_Prayer_3.png',
        ];
      case WidgetPromptId.a1:
        return const [
          'assets/bible_widget/Continue_Reading_1.png',
          'assets/bible_widget/Continue_Reading_2.png',
          'assets/bible_widget/Continue_Reading_3.png',
        ];
    }
  }

  /// Syncs the matching Home widget, then starts the existing iOS Live Activity
  /// so it appears the same way other iOS widgets already do.
  static Future<void> openHowToAdd(WidgetPromptId id) async {
    Constants.showToast(
      'Follow the steps to add this widget to your Home Screen.',
      2500,
    );
    await Get.to(
      () => AddWidgetIntroScreen(
        iosWidgetKind: kindFor(id),
        widgetTitle: titleFor(id),
        previewImages: previewImagesFor(id),
      ),
      preventDuplicates: true,
    );
    await noteHowToOpened(id);
    await noteWidgetPreviewed(
      iosWidgetKind: kindFor(id),
      widgetTitle: titleFor(id),
    );
    try {
      switch (id) {
        case WidgetPromptId.a1:
          await syncContinueReadingWidget();
          break;
        case WidgetPromptId.a2:
          await syncWeeklyStreakWidget();
          break;
        case WidgetPromptId.a6:
          await updateAllLauncherWidgets();
          break;
        case WidgetPromptId.a8:
        case WidgetPromptId.a8b:
          await updateBiblePrayerWidget();
          break;
      }
    } catch (e) {
      debugPrint('WidgetPrompt: sync before tutorial failed: $e');
    }
    await startExistingIosWidget(id);
  }

  static String _howtoOpenedKey(WidgetPromptId id) =>
      'widget_prompt_${id.name}_howto_opened';

  static Future<bool> _hasOpenedHowTo(WidgetPromptId id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_howtoOpenedKey(id)) ?? false;
  }

  static Future<bool> hasOpenedHowTo(WidgetPromptId id) =>
      _hasOpenedHowTo(id);

  static Future<void> noteHowToOpened(WidgetPromptId id) async {
    if (id == WidgetPromptId.a8) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_howtoOpenedKey(id), true);
  }

  /// Bump when a new home-widget family ships so the drawer gold/red dot returns.
  static const widgetFamilyVersion = 1;
  static const _sessionCountKey = 'widget_prompt_app_session_count';
  static const _familySeenKey = 'widget_prompt_family_seen_version';
  static const _addedKindsKey = 'widget_prompt_added_kinds';
  static bool _sessionCountedThisLaunch = false;

  static String _kindKey(String? iosWidgetKind, String? widgetTitle) {
    final kind = (iosWidgetKind ?? '').trim();
    if (kind.isNotEmpty) return kind;
    final title = (widgetTitle ?? '').trim();
    if (title.isNotEmpty) return title;
    return 'widgets';
  }

  static Future<int> widgetsAddedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_addedKindsKey) ?? []).toSet().length;
  }

  /// Home Screen install count for drawer badge (any size = one family).
  static Future<int> installedDrawerWidgetsCount() =>
      installedDrawerHubWidgetCount();

  /// Home Screen install set for drawer hub UI (read-only).
  static Future<Set<String>> installedDrawerWidgetKinds() =>
      installedDrawerHubWidgetKinds();

  /// Read-only list for drawer widget hub UI (does not change preview logic).
  static Future<Set<String>> previewedWidgetKinds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_addedKindsKey) ?? []).toSet();
  }

  /// Widget families shown in the drawer hub (UI constant only).
  static const int drawerWidgetFamilyCount = 9;

  static Future<int> noteWidgetPreviewed({
    String? iosWidgetKind,
    String? widgetTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final kinds = (prefs.getStringList(_addedKindsKey) ?? []).toSet();
    kinds.add(_kindKey(iosWidgetKind, widgetTitle));
    await prefs.setStringList(_addedKindsKey, kinds.toList());
    return kinds.length;
  }

  static Future<int> noteAppSession() async {
    final prefs = await SharedPreferences.getInstance();
    var count = prefs.getInt(_sessionCountKey) ?? 0;
    if (!_sessionCountedThisLaunch) {
      _sessionCountedThisLaunch = true;
      count += 1;
      await prefs.setInt(_sessionCountKey, count);
    }
    return count;
  }

  static Future<bool> showDrawerAttentionDot() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await noteAppSession();
    final seen = prefs.getInt(_familySeenKey) ?? 0;
    return sessions <= 3 || seen < widgetFamilyVersion;
  }

  static Future<void> markWidgetFamilySeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_familySeenKey, widgetFamilyVersion);
  }
}
