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

  /// R1: first eligible prompt this app process wins the session (all prompt ids).
  static WidgetPromptId? _sessionPromptOwner;
  static String? _sessionToken;
  static Future<void> _sessionClaimChain = Future<void>.value();
  static const _r1TokenKey = 'widget_prompt_r1_session_token_v1';
  static const _r1OwnerKey = 'widget_prompt_r1_session_owner_v1';

  static const _lifetimeChaptersKey = 'widget_prompt_lifetime_chapters';
  static const _prayerGeneratedKey = 'widget_prompt_prayer_generated_count';

  static String _declineKey(WidgetPromptId id) =>
      'widget_prompt_${id.name}_decline_count';
  static String _hideUntilKey(WidgetPromptId id) =>
      'widget_prompt_${id.name}_hide_until_ms';

  /// Library tabs that can host A6 — only the first eligible tab keeps it.
  static const libraryTabBookmark = 'bookmark';
  static const libraryTabHighlight = 'highlight';
  static const libraryTabUnderline = 'underline';
  static const _a6LibraryOwnerKey = 'widget_prompt_a6_library_owner_v1';

  /// UI-only: first Library tab that is eligible to show A6 owns the prompt.
  static Future<bool> _isOrClaimLibraryA6Owner(String tab) async {
    final key = tab.trim();
    if (key.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    var owner = (prefs.getString(_a6LibraryOwnerKey) ?? '').trim();
    if (owner.isEmpty) {
      await prefs.setString(_a6LibraryOwnerKey, key);
      owner = (prefs.getString(_a6LibraryOwnerKey) ?? '').trim();
    }
    return owner == key;
  }

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

  static bool _isSessionPrompt(WidgetPromptId id) {
    // R1: every widget prompt type shares one session slot.
    switch (id) {
      case WidgetPromptId.a1:
      case WidgetPromptId.a2:
      case WidgetPromptId.a6:
      case WidgetPromptId.a8:
      case WidgetPromptId.a8b:
        return true;
    }
  }

  static String _ensureProcessSessionToken() =>
      _sessionToken ??= 'launch_${DateTime.now().microsecondsSinceEpoch}';

  /// R1 — serialize claims so only one prompt wins this process session.
  static Future<bool> _tryClaimSessionPrompt(WidgetPromptId id) {
    if (!_isSessionPrompt(id)) return Future<bool>.value(true);

    late final Future<bool> result;
    result = _sessionClaimChain.then((_) => _claimSessionPromptUnlocked(id));
    _sessionClaimChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Future<bool> _claimSessionPromptUnlocked(WidgetPromptId id) async {
    final token = _ensureProcessSessionToken();
    final prefs = await SharedPreferences.getInstance();
    final storedToken = (prefs.getString(_r1TokenKey) ?? '').trim();
    final storedOwner = (prefs.getString(_r1OwnerKey) ?? '').trim();

    // New app process → new session token; previous launch owner does not apply.
    if (storedToken != token) {
      await prefs.setString(_r1TokenKey, token);
      await prefs.setString(_r1OwnerKey, id.name);
      _sessionPromptOwner = id;
      debugPrint('WidgetPrompt R1: session claimed by ${id.name}');
      return true;
    }

    if (storedOwner.isEmpty) {
      await prefs.setString(_r1OwnerKey, id.name);
      _sessionPromptOwner = id;
      debugPrint('WidgetPrompt R1: session claimed by ${id.name}');
      return true;
    }

    _sessionPromptOwner = WidgetPromptId.values.firstWhere(
      (e) => e.name == storedOwner,
      orElse: () => id,
    );
    final allowed = storedOwner == id.name;
    if (!allowed) {
      debugPrint(
          'WidgetPrompt R1: blocked ${id.name} (owner=$storedOwner)');
    }
    return allowed;
  }

  /// Call when a prompt is actually mounted (reinforces R1 claim).
  static Future<void> notePromptDisplayed(WidgetPromptId id) async {
    if (!_isSessionPrompt(id)) return;
    await _tryClaimSessionPrompt(id);
  }

  static Future<bool> shouldShow(
    WidgetPromptId id, {
    required bool triggerMet,
    String? libraryTab,
  }) async {
    if (!triggerMet) return false;

    final kindInstalled = await isHomeWidgetKindInstalled(kindFor(id));
    if (kindInstalled) return false;

    // A8 keeps always-on eligibility rules, but still respects R1 session slot.
    if (id == WidgetPromptId.a8) {
      return _tryClaimSessionPrompt(id);
    }

    if (await _hasOpenedHowTo(id)) return false;

    if (await isAnyHomeWidgetInstalled()) return false;

    final prefs = await SharedPreferences.getInstance();
    final declines = prefs.getInt(_declineKey(id)) ?? 0;
    if (declines >= 3) return false;
    final hideUntil = prefs.getInt(_hideUntilKey(id)) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < hideUntil) return false;

    // Display-only: A6 appears on one Library tab (first eligible claim).
    if (id == WidgetPromptId.a6 &&
        libraryTab != null &&
        libraryTab.trim().isNotEmpty) {
      if (!await _isOrClaimLibraryA6Owner(libraryTab)) return false;
    }

    // R1: one widget prompt per app session — first eligible wins (all types).
    if (!await _tryClaimSessionPrompt(id)) return false;

    return true;
  }

  static Future<void> markDismissed(WidgetPromptId id) async {
    if (id == WidgetPromptId.a8) return;
    // R1: interacting with this card locks the session to it.
    await _tryClaimSessionPrompt(id);
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

  static const _gallerySeenKey = 'widget_gallery_seen_kinds';

  static const _compressed = 'assets/bible_widget_comopressed';

  static List<String> previewAssetsFor(WidgetPromptId? id) {
    if (id == null) {
      return const [
        '$_compressed/Daily_Verse_1.png',
        '$_compressed/Daily_Verse_2.png',
        '$_compressed/Daily_Verse_3.png',
        '$_compressed/Continue_Reading_1.png',
        '$_compressed/Continue_Reading_2.png',
        '$_compressed/Continue_Reading_3.png',
        '$_compressed/Reading_Streak_1.png',
        '$_compressed/Reading_Streak_2.png',
        '$_compressed/Reading_Streak_3.png',
        '$_compressed/Favorite_Verse.png',
        '$_compressed/Favorite_Verse_2.png',
        '$_compressed/Bible_Prayer_1.png',
        '$_compressed/Bible_Prayer_2.png',
        '$_compressed/Bible_Prayer_3.png',
        '$_compressed/Bible_Chat_1.png',
        '$_compressed/Bible_Chat_2.png',
        '$_compressed/Bible_Chat_3.png',
      ];
    }
    switch (id) {
      case WidgetPromptId.a1:
        return const [
          '$_compressed/Continue_Reading_1.png',
          '$_compressed/Continue_Reading_2.png',
          '$_compressed/Continue_Reading_3.png',
        ];
      case WidgetPromptId.a2:
        return const [
          '$_compressed/Reading_Streak_1.png',
          '$_compressed/Reading_Streak_2.png',
          '$_compressed/Reading_Streak_3.png',
        ];
      case WidgetPromptId.a6:
        return const [
          '$_compressed/Favorite_Verse.png',
          '$_compressed/Favorite_Verse_2.png',
        ];
      case WidgetPromptId.a8:
      case WidgetPromptId.a8b:
        return const [
          '$_compressed/Bible_Prayer_1.png',
          '$_compressed/Bible_Prayer_2.png',
          '$_compressed/Bible_Prayer_3.png',
        ];
    }
  }

  static List<String> previewImagesFor(WidgetPromptId id) =>
      previewAssetsFor(id);

  static Future<void> markGalleryViewed(WidgetPromptId? id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_gallerySeenKey) ?? [];
    final token = id == null ? 'all' : kindFor(id);
    if (list.contains(token)) return;
    list.add(token);
    await prefs.setStringList(_gallerySeenKey, list);
  }

  static Future<int> galleryViewedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_gallerySeenKey) ?? []).length;
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
    // R1: opening steps for a card prompt locks the session to it.
    await _tryClaimSessionPrompt(id);
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
