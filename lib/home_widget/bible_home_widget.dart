// Home Screen Widget support for iOS only.
// Provides 10 old-paper widget designs (+ legacy Bible Prayer / Bible Chat).
// Uses the home_widget package; native Widget Extension must be set up in Xcode.

import 'dart:io';

import 'package:biblebookapp/Model/dailyVerseList.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/live_activity/live_activity_queue.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Route to open when user taps a home widget. App should navigate to the matching screen.
enum BibleWidgetRoute { verse, reading, prayer, chat, streak, random, none }

/// Parses a widget launch URI (e.g. biblebookapp://prayer?homeWidget) and returns the route.
BibleWidgetRoute getBibleWidgetRouteFromUri(Uri? uri) {
  if (uri == null) return BibleWidgetRoute.none;
  final host = uri.host.toLowerCase();
  if (host == kWidgetRouteVerse) return BibleWidgetRoute.verse;
  if (host == kWidgetRouteReading) return BibleWidgetRoute.reading;
  if (host == kWidgetRoutePrayer) return BibleWidgetRoute.prayer;
  if (host == kWidgetRouteChat) return BibleWidgetRoute.chat;
  if (host == kWidgetRouteStreak) return BibleWidgetRoute.streak;
  if (host == kWidgetRouteRandom) return BibleWidgetRoute.random;
  return BibleWidgetRoute.none;
}

/// App Group ID for sharing data between the app and the Widget Extension.
/// Must match the App Group identifier added in Xcode for both Runner and the Widget Extension.
const String _kAppGroupId = 'group.com.balaklrapps.newkingsjamesversion';

/// Widget kinds (must match the `kind` in each Widget struct in the iOS Widget Extension).
const String _kVerseOfTheDayKind = 'VerseOfTheDayWidget';
const String _kBiblePrayerKind = 'BiblePrayerWidget';
const String _kBibleChatKind = 'BibleChatWidget';
const String _kContinueReadingKind = 'ContinueReadingWidget';
const String _kWeeklyStreakKind = 'WeeklyReadingStreakWidget';
const String _kFavoriteVerseKind = 'FavoriteVerseWidget';
const String _kHourlyVerseKind = 'HourlyVerseWidget';
const String _kRandomVerseKind = 'RandomBibleVerseWidget';
const String _kVerseImageKind = 'VerseImageWidget';

/// Public kind ids for additive widget-prompt checks (match iOS Widget structs).
const String kVerseOfTheDayWidgetKind = _kVerseOfTheDayKind;
const String kBiblePrayerWidgetKind = _kBiblePrayerKind;
const String kBibleChatWidgetKind = _kBibleChatKind;
const String kContinueReadingWidgetKind = _kContinueReadingKind;
const String kWeeklyStreakWidgetKind = _kWeeklyStreakKind;
const String kFavoriteVerseWidgetKind = _kFavoriteVerseKind;
const String kHourlyVerseWidgetKind = _kHourlyVerseKind;
const String kRandomVerseWidgetKind = _kRandomVerseKind;
const String kVerseImageWidgetKind = _kVerseImageKind;

/// Data keys stored in UserDefaults (App Group) for the widgets.
const String _kVerseTextKey = 'widget_verse_text';
const String _kVerseReferenceKey = 'widget_verse_reference';

/// Keys exposed so app can read widget verse when opening from widget tap.
const String kWidgetVerseTextKey = _kVerseTextKey;
const String kWidgetVerseReferenceKey = _kVerseReferenceKey;
/// Exact reader location for Verse-of-the-Day widget taps (additive).
const String _kVerseBookNumKey = 'widget_verse_book_num';
const String _kVerseChapterKey = 'widget_verse_chapter';
const String _kVerseVerseNumKey = 'widget_verse_verse_num';
const String _kVerseBookNameKey = 'widget_verse_book_name';
const String _kBiblePrayerTitleKey = 'widget_bible_prayer_title';
const String _kPrayerTextKey = 'widget_prayer_text';
const String _kChatQuestionKey = 'widget_chat_question';
const String _kChatAnswerKey = 'widget_chat_answer';
const String _kBibleChatTitleKey = 'widget_bible_chat_title';
const String _kStreakDaysKey = 'widget_streak_days';
const String _kFavoriteVerseTextKey = 'widget_favorite_verse_text';
const String _kFavoriteVerseReferenceKey = 'widget_favorite_verse_reference';
const String _kRandomVerseTextKey = 'widget_random_verse_text';
const String _kRandomVerseReferenceKey = 'widget_random_verse_reference';
const String _kRandomVerseBookNumKey = 'widget_random_verse_book_num';
const String _kRandomVerseChapterKey = 'widget_random_verse_chapter';
const String _kRandomVerseVerseNumKey = 'widget_random_verse_verse_num';
const String _kRandomVerseBookNameKey = 'widget_random_verse_book_name';
const String _kHourlyVerseTextKey = 'widget_hourly_verse_text';
const String _kHourlyVerseReferenceKey = 'widget_hourly_verse_reference';
const String _kHourlyNextLabelKey = 'widget_hourly_next_label';
const String _kVerseImageTextKey = 'widget_verse_image_text';
const String _kVerseImageReferenceKey = 'widget_verse_image_reference';
const String _kContinueBookChapterKey = 'widget_continue_book_chapter';
const String _kContinueSubtitleKey = 'widget_continue_subtitle';
const String _kContinueProgressKey = 'widget_continue_progress';
const String _kContinueProgressLabelKey = 'widget_continue_progress_label';
const String _kContinueBookNumKey = 'widget_continue_book_num';
const String _kContinueChapterKey = 'widget_continue_chapter';
const String _kContinueBookNameKey = 'widget_continue_book_name';
const String _kWeeklyStreakStatusKey = 'widget_weekly_streak_status';
const String _kWeeklyStreakCountKey = 'widget_weekly_streak_count';
const String _kWeeklyStreakCountStrKey = 'widget_weekly_streak_count_str';

/// Deep-link host names when user taps a widget (must match widgetURL in Swift).
const String kWidgetRouteVerse = 'verse';
/// Continue Reading widget / Live Activity (last-read) — separate from Daily Verse.
const String kWidgetRouteReading = 'reading';
const String kWidgetRoutePrayer = 'prayer';
const String kWidgetRouteChat = 'chat';
const String kWidgetRouteStreak = 'streak';
/// Random Bible Verse widget — must not share Verse For You location keys.
const String kWidgetRouteRandom = 'random';

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

/// Exact book/chapter/verse for Verse-of-the-Day widget open (additive; display sync only).
Future<Map<String, String>> getDailyVerseWidgetLocation() async {
  if (!Platform.isIOS) return {};
  try {
    final bookNum =
        (await HomeWidget.getWidgetData<String>(_kVerseBookNumKey))?.trim() ??
            '';
    final chapter =
        (await HomeWidget.getWidgetData<String>(_kVerseChapterKey))?.trim() ??
            '';
    final verseNum =
        (await HomeWidget.getWidgetData<String>(_kVerseVerseNumKey))?.trim() ??
            '';
    final bookName =
        (await HomeWidget.getWidgetData<String>(_kVerseBookNameKey))?.trim() ??
            '';
    final text =
        (await HomeWidget.getWidgetData<String>(_kVerseTextKey))?.trim() ?? '';
    if (bookNum.isEmpty || chapter.isEmpty || verseNum.isEmpty) return {};
    return {
      'bookNum': bookNum,
      'chapter': chapter,
      'verseNum': verseNum,
      'bookName': bookName,
      'text': text,
    };
  } catch (e) {
    debugPrint('BibleHomeWidget: getDailyVerseWidgetLocation failed: $e');
    return {};
  }
}

Future<void> _saveDailyVerseWidgetLocation(DailyVerseList verse) async {
  final bookNum = dailyVerseBookNum(verse.bookId);
  final chapter = dailyVerseUiChapter(verse.chapter);
  final verseNum = dailyVerseUiVerse(verse.verseNum);
  final bookName = (verse.book ?? '').toString().trim();
  await HomeWidget.saveWidgetData<String>(_kVerseBookNumKey, '$bookNum');
  await HomeWidget.saveWidgetData<String>(_kVerseChapterKey, '$chapter');
  await HomeWidget.saveWidgetData<String>(_kVerseVerseNumKey, '$verseNum');
  await HomeWidget.saveWidgetData<String>(_kVerseBookNameKey, bookName);
}

Future<void> _saveRandomVerseWidgetLocation(DailyVerseList verse) async {
  final bookNum = dailyVerseBookNum(verse.bookId);
  final chapter = dailyVerseUiChapter(verse.chapter);
  final verseNum = dailyVerseUiVerse(verse.verseNum);
  final bookName = (verse.book ?? '').toString().trim();
  await HomeWidget.saveWidgetData<String>(_kRandomVerseBookNumKey, '$bookNum');
  await HomeWidget.saveWidgetData<String>(_kRandomVerseChapterKey, '$chapter');
  await HomeWidget.saveWidgetData<String>(_kRandomVerseVerseNumKey, '$verseNum');
  await HomeWidget.saveWidgetData<String>(_kRandomVerseBookNameKey, bookName);
}

/// Exact book/chapter/verse for Random Verse widget open (separate from Verse For You).
Future<Map<String, String>> getRandomVerseWidgetLocation() async {
  if (!Platform.isIOS) return {};
  try {
    final bookNum =
        (await HomeWidget.getWidgetData<String>(_kRandomVerseBookNumKey))
                ?.trim() ??
            '';
    final chapter =
        (await HomeWidget.getWidgetData<String>(_kRandomVerseChapterKey))
                ?.trim() ??
            '';
    final verseNum =
        (await HomeWidget.getWidgetData<String>(_kRandomVerseVerseNumKey))
                ?.trim() ??
            '';
    final bookName =
        (await HomeWidget.getWidgetData<String>(_kRandomVerseBookNameKey))
                ?.trim() ??
            '';
    final text =
        (await HomeWidget.getWidgetData<String>(_kRandomVerseTextKey))
                ?.trim() ??
            '';
    if (bookNum.isEmpty || chapter.isEmpty || verseNum.isEmpty) return {};
    return {
      'bookNum': bookNum,
      'chapter': chapter,
      'verseNum': verseNum,
      'bookName': bookName,
      'text': text,
    };
  } catch (e) {
    debugPrint('BibleHomeWidget: getRandomVerseWidgetLocation failed: $e');
    return {};
  }
}

/// Exact book/chapter for Continue Reading widget open (matches what the tile shows).
Future<Map<String, String>> getContinueReadingWidgetLocation() async {
  if (!Platform.isIOS) return {};
  try {
    final bookNum =
        (await HomeWidget.getWidgetData<String>(_kContinueBookNumKey))
                ?.trim() ??
            '';
    final chapter =
        (await HomeWidget.getWidgetData<String>(_kContinueChapterKey))
                ?.trim() ??
            '';
    final bookName =
        (await HomeWidget.getWidgetData<String>(_kContinueBookNameKey))
                ?.trim() ??
            '';
    if (bookNum.isEmpty || chapter.isEmpty) return {};
    return {
      'bookNum': bookNum,
      'chapter': chapter,
      'bookName': bookName,
    };
  } catch (e) {
    debugPrint('BibleHomeWidget: getContinueReadingWidgetLocation failed: $e');
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

/// Plain text for widget display (no visible HTML). Does not change verse source data elsewhere.
String stripHtmlTagsForWidgetVerse(String raw) {
  if (raw.isEmpty) return raw;
  var s = raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _formatDailyVerseReference(DailyVerseList verse) {
  final book = verse.book?.trim() ?? '';
  final chapter = dailyVerseUiChapter(verse.chapter);
  final verseNum = dailyVerseUiVerse(verse.verseNum);
  final ref = '$book $chapter:$verseNum'.trim();
  return ref.isEmpty ? 'Daily Verse' : ref;
}

String _widgetVerseTextFromDaily(DailyVerseList verse) {
  final raw = verse.verse?.trim() ?? '';
  if (raw.isEmpty) return _kDefaultVerseText;
  return stripHtmlTagsForWidgetVerse(raw);
}

String _hourlyNextLabel() {
  final now = DateTime.now();
  final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
  final minutes = nextHour.difference(now).inMinutes.clamp(1, 59);
  return 'Next verse in $minutes min';
}

int _weekDayStatusCode(WeekDayStatus status) {
  switch (status) {
    case WeekDayStatus.completed:
      return 1;
    case WeekDayStatus.ongoing:
      return 2;
    case WeekDayStatus.missed:
    case WeekDayStatus.future:
      return 0;
  }
}

/// Display-only encoding for the weekly streak widget (does not change streak logic).
int _weekDayStatusCodeForWidget(WeekDayStatus status, {required bool todayComplete}) {
  if (status == WeekDayStatus.ongoing) {
    return todayComplete ? 1 : 2;
  }
  return _weekDayStatusCode(status);
}

/// Read-only: whether today's streak is finished (same prefs the app already uses).
Future<bool> _isTodayStreakCompleteForWidget() async {
  final today = DateTime.now().toIso8601String().split('T')[0];
  final lastShown = await SharPreferences.getString(
      SharPreferences.streakFlowLastShownDate);
  if (lastShown == today) return true;

  final lastActivity = await SharPreferences.getString(
      SharPreferences.streakLastActivityDate);
  if (lastActivity == today) {
    final count =
        await SharPreferences.getInt(SharPreferences.streakCount) ?? 0;
    if (count > 0) return true;
  }

  final started =
      await SharPreferences.getString(SharPreferences.streakFlowStartedDate);
  if (started == today) {
    final steps = await SharPreferences.getInt(
            SharPreferences.streakFlowStepsCompletedToday) ??
        0;
    if (steps >= 4) return true;
  }
  return false;
}

/// Read-only mirror: pushes verse-family widgets from [dailyVerseList] (same source as Daily Verse).
Future<void> syncVerseFamilyWidgetsFromDailyList(
  List<DailyVerseList> dailyVerseList,
) async {
  if (!Platform.isIOS || dailyVerseList.isEmpty) return;
  try {
    final daily = dailyVerseList.first;
    final dailyText = _widgetVerseTextFromDaily(daily);
    final dailyRef = _formatDailyVerseReference(daily);
    // Additive: exact location for widget → reader open (does not change reading prefs).
    await _saveDailyVerseWidgetLocation(daily);
    // Keep Verse For You text/ref aligned with the same helpers as location keys.
    await HomeWidget.saveWidgetData<String>(_kVerseTextKey, dailyText);
    await HomeWidget.saveWidgetData<String>(_kVerseReferenceKey, dailyRef);
    await HomeWidget.updateWidget(iOSName: _kVerseOfTheDayKind);

    // Favorite: latest bookmark when available, otherwise second daily verse or first.
    var favoriteText = dailyText;
    var favoriteRef = dailyRef;
    try {
      final bookmarks = await DBHelper().getBookMark();
      if (bookmarks.isNotEmpty) {
        bookmarks.sort((a, b) {
          final ta = a.timestamp ?? '';
          final tb = b.timestamp ?? '';
          return tb.compareTo(ta);
        });
        final bm = bookmarks.first;
        final raw = bm.content?.trim() ?? '';
        if (raw.isNotEmpty) {
          favoriteText = stripHtmlTagsForWidgetVerse(raw);
          final book = bm.bookName?.trim() ?? '';
          final ch = (bm.chapterNum ?? 0).toInt();
          final vs = (bm.verseNum ?? 0).toInt();
          favoriteRef = '$book $ch:$vs'.trim();
          if (favoriteRef.isEmpty) favoriteRef = dailyRef;
        }
      } else if (dailyVerseList.length > 1) {
        final fav = dailyVerseList[1];
        favoriteText = _widgetVerseTextFromDaily(fav);
        favoriteRef = _formatDailyVerseReference(fav);
      }
    } catch (e) {
      debugPrint('BibleHomeWidget: favorite bookmark read failed: $e');
    }

    final daySeed = DateTime.now().day + DateTime.now().month * 31;
    final randomIndex = daySeed % dailyVerseList.length;
    final randomVerse = dailyVerseList[randomIndex];
    final hourlyIndex = DateTime.now().hour % dailyVerseList.length;
    final hourlyVerse = dailyVerseList[hourlyIndex];

    await HomeWidget.saveWidgetData<String>(_kFavoriteVerseTextKey, favoriteText);
    await HomeWidget.saveWidgetData<String>(
        _kFavoriteVerseReferenceKey, favoriteRef);
    await HomeWidget.saveWidgetData<String>(
      _kRandomVerseTextKey,
      _widgetVerseTextFromDaily(randomVerse),
    );
    await HomeWidget.saveWidgetData<String>(
      _kRandomVerseReferenceKey,
      _formatDailyVerseReference(randomVerse),
    );
    await _saveRandomVerseWidgetLocation(randomVerse);
    await HomeWidget.saveWidgetData<String>(
      _kHourlyVerseTextKey,
      _widgetVerseTextFromDaily(hourlyVerse),
    );
    await HomeWidget.saveWidgetData<String>(
      _kHourlyVerseReferenceKey,
      _formatDailyVerseReference(hourlyVerse),
    );
    await HomeWidget.saveWidgetData<String>(_kHourlyNextLabelKey, _hourlyNextLabel());
    await HomeWidget.saveWidgetData<String>(_kVerseImageTextKey, dailyText);
    await HomeWidget.saveWidgetData<String>(_kVerseImageReferenceKey, dailyRef);

    await HomeWidget.updateWidget(iOSName: _kFavoriteVerseKind);
    await HomeWidget.updateWidget(iOSName: _kRandomVerseKind);
    await HomeWidget.updateWidget(iOSName: _kHourlyVerseKind);
    await HomeWidget.updateWidget(iOSName: _kVerseImageKind);
  } catch (e) {
    debugPrint('BibleHomeWidget: syncVerseFamilyWidgetsFromDailyList failed: $e');
  }
}

/// Read-only mirror: continue-reading widget from prefs + DB (no reading-flow changes).
Future<void> syncContinueReadingWidget() async {
  if (!Platform.isIOS) return;
  try {
    final book =
        (await SharPreferences.getString(SharPreferences.selectedBook))?.trim() ??
            '';
    final chapter =
        (await SharPreferences.getString(SharPreferences.selectedChapter))
                ?.trim() ??
            '';
    final bookNumStr =
        (await SharPreferences.getString(SharPreferences.selectedBookNum)) ??
            '0';
    final bookNum = int.tryParse(bookNumStr) ?? 0;

    var bookChapter = [book, chapter].where((s) => s.isNotEmpty).join(' ');
    if (bookChapter.isEmpty) bookChapter = 'Genesis 1';

    var progressLabel = '0';
    var progressValue = 0.0;
    try {
      final db = await DBHelper().db;
      if (db != null && bookNum >= 0) {
        final rows = await db.rawQuery(
          'SELECT read_per FROM book WHERE book_num = ? LIMIT 1',
          [bookNum],
        );
        if (rows.isNotEmpty && rows.first['read_per'] != null) {
          final readPer =
              double.tryParse(rows.first['read_per'].toString()) ?? 0.0;
          progressValue = (readPer / 100.0).clamp(0.0, 1.0);
          progressLabel =
              readPer >= 99.9 ? '100' : readPer.toStringAsFixed(0);
        }
      }
    } catch (e) {
      debugPrint('BibleHomeWidget: continue reading DB read failed: $e');
    }

    final subtitle = chapter.isNotEmpty
        ? 'Chapter $chapter · $progressLabel% of book'
        : '$progressLabel% of book';

    await HomeWidget.saveWidgetData<String>(
        _kContinueBookChapterKey, bookChapter);
    await HomeWidget.saveWidgetData<String>(_kContinueSubtitleKey, subtitle);
    await HomeWidget.saveWidgetData<String>(
        _kContinueProgressKey, progressValue.toStringAsFixed(3));
    await HomeWidget.saveWidgetData<String>(
        _kContinueProgressLabelKey, '$progressLabel%');
    // Exact tap target (same snapshot as the tile) — separate from Daily prefs writes.
    await HomeWidget.saveWidgetData<String>(_kContinueBookNumKey, bookNumStr);
    await HomeWidget.saveWidgetData<String>(
        _kContinueChapterKey, chapter.isNotEmpty ? chapter : '1');
    await HomeWidget.saveWidgetData<String>(
        _kContinueBookNameKey, book.isNotEmpty ? book : 'Genesis');
    await HomeWidget.updateWidget(iOSName: _kContinueReadingKind);
    // Display-only: refresh Live Activity queue + streak widget mirrors.
    await LiveActivityQueue.sync();
    await syncWeeklyStreakWidget();
  } catch (e) {
    debugPrint('BibleHomeWidget: syncContinueReadingWidget failed: $e');
  }
}

/// Read-only mirror: weekly streak widget from [StreakService] (no streak logic changes).
Future<void> syncWeeklyStreakWidget() async {
  if (!Platform.isIOS) return;
  try {
    final statuses = await StreakService.getWeekDayStatuses();
    final streakCount = await StreakService.getCurrentStreak();
    final todayComplete = await _isTodayStreakCompleteForWidget();
    final statusCsv = statuses
        .map((s) => _weekDayStatusCodeForWidget(s, todayComplete: todayComplete))
        .join(',');

    await HomeWidget.saveWidgetData<String>(_kWeeklyStreakStatusKey, statusCsv);
    await HomeWidget.saveWidgetData<int>(_kWeeklyStreakCountKey, streakCount);
    await HomeWidget.saveWidgetData<String>(
        _kWeeklyStreakCountStrKey, '$streakCount');
    await HomeWidget.updateWidget(iOSName: _kWeeklyStreakKind);
  } catch (e) {
    debugPrint('BibleHomeWidget: syncWeeklyStreakWidget failed: $e');
  }
}

Future<void> _mirrorStreakDaysForPrayerWidget() async {
  try {
    final streakCount = await StreakService.getCurrentStreak();
    await HomeWidget.saveWidgetData<int>(_kStreakDaysKey, streakCount);
  } catch (_) {}
}

/// Updates the "Verse of the day" widget with the given verse text and reference.
/// Uses defaults if empty. Call after loading daily verses (e.g. from DownloadProvider.loadDailyVerses).
/// No-op on non-iOS.
Future<void> updateVerseOfTheDayWidget({
  required String verseText,
  required String reference,
  int? bookNum,
  int? chapter,
  int? verseNum,
  String? bookName,
}) async {
  if (!Platform.isIOS) return;
  try {
    final text = verseText.trim().isEmpty
        ? _kDefaultVerseText
        : stripHtmlTagsForWidgetVerse(verseText);
    final ref = reference.trim().isEmpty ? _kDefaultVerseRef : reference;
    await HomeWidget.saveWidgetData<String>(_kVerseTextKey, text);
    await HomeWidget.saveWidgetData<String>(_kVerseReferenceKey, ref);
    if (bookNum != null && chapter != null && verseNum != null) {
      await HomeWidget.saveWidgetData<String>(_kVerseBookNumKey, '$bookNum');
      await HomeWidget.saveWidgetData<String>(_kVerseChapterKey, '$chapter');
      await HomeWidget.saveWidgetData<String>(_kVerseVerseNumKey, '$verseNum');
      await HomeWidget.saveWidgetData<String>(
          _kVerseBookNameKey, (bookName ?? '').trim());
    }
    await HomeWidget.updateWidget(iOSName: _kVerseOfTheDayKind);
    // Display-only: refresh Live Activity queue + streak widget mirrors.
    await LiveActivityQueue.sync();
    await syncWeeklyStreakWidget();
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
    await _mirrorStreakDaysForPrayerWidget();
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
          _kChatQuestionKey,
          question.trim().length > 120
              ? '${question.trim().substring(0, 120)}...'
              : question.trim());
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
/// launcher widgets from existing app data. No-op on non-iOS.
Future<void> updateAllLauncherWidgets({
  List<DailyVerseList>? dailyVerses,
}) async {
  if (!Platform.isIOS) return;
  try {
    await updateBiblePrayerWidget();
    await updateBibleChatWidget();
    await syncContinueReadingWidget();
    await syncWeeklyStreakWidget();
    if (dailyVerses != null && dailyVerses.isNotEmpty) {
      await syncVerseFamilyWidgetsFromDailyList(dailyVerses);
    }
  } catch (e) {
    debugPrint('BibleHomeWidget: updateAllLauncherWidgets failed: $e');
  }
}

/// Additive: true if any home-screen widget of this app is already pinned.
Future<bool> isAnyHomeWidgetInstalled() async {
  try {
    final widgets = await HomeWidget.getInstalledWidgets();
    return widgets.isNotEmpty;
  } catch (e) {
    debugPrint('BibleHomeWidget: isAnyHomeWidgetInstalled failed: $e');
    return false;
  }
}

/// Additive: true if a specific widget kind is already on the Home Screen.
Future<bool> isHomeWidgetKindInstalled(String kind) async {
  if (kind.trim().isEmpty) return false;
  try {
    final widgets = await HomeWidget.getInstalledWidgets();
    for (final w in widgets) {
      final iosKind = (w.iOSKind ?? '').trim();
      final android = (w.androidClassName ?? '').trim();
      if (iosKind == kind || android.contains(kind)) return true;
    }
    return false;
  } catch (e) {
    debugPrint('BibleHomeWidget: isHomeWidgetKindInstalled failed: $e');
    return false;
  }
}

/// Drawer hub families — any size of the same kind counts once.
const List<String> kDrawerHubWidgetKinds = [
  kVerseOfTheDayWidgetKind,
  kRandomVerseWidgetKind,
  kHourlyVerseWidgetKind,
  kVerseImageWidgetKind,
  kContinueReadingWidgetKind,
  kWeeklyStreakWidgetKind,
  kFavoriteVerseWidgetKind,
  kBiblePrayerWidgetKind,
  kBibleChatWidgetKind,
];

/// Additive: unique widget kinds currently pinned on the Home Screen.
Future<Set<String>> installedHomeWidgetKinds() async {
  try {
    final widgets = await HomeWidget.getInstalledWidgets();
    final kinds = <String>{};
    for (final w in widgets) {
      final iosKind = (w.iOSKind ?? '').trim();
      if (iosKind.isNotEmpty) {
        kinds.add(iosKind);
        continue;
      }
      final android = (w.androidClassName ?? '').trim();
      if (android.isNotEmpty) kinds.add(android);
    }
    return kinds;
  } catch (e) {
    debugPrint('BibleHomeWidget: installedHomeWidgetKinds failed: $e');
    return {};
  }
}

/// Additive: drawer-hub widget kinds installed (ignores widget size).
Future<Set<String>> installedDrawerHubWidgetKinds() async {
  final installed = await installedHomeWidgetKinds();
  return kDrawerHubWidgetKinds.where(installed.contains).toSet();
}

/// Additive: how many drawer-hub widget families are on the Home Screen.
Future<int> installedDrawerHubWidgetCount() async {
  return (await installedDrawerHubWidgetKinds()).length;
}
