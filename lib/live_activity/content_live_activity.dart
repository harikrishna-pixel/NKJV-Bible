// iOS Live Activity mirrors for Memory Verse + Continue Reading.
// Display-only — does not change reading, daily-verse, or streak logic.

import 'dart:io';

import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Mirrors Memory Verse + Continue Reading onto iOS Live Activities.
class ContentLiveActivitySync {
  static const MethodChannel _channel =
      MethodChannel('com.biblebookapp/content_live_activity');

  static const int _defaultReviewTotal = 5;

  // Same keys as bible_home_widget (duplicated to avoid circular imports).
  static const String _verseTextKey = 'widget_verse_text';
  static const String _verseReferenceKey = 'widget_verse_reference';

  /// Ends both content Live Activities (display-only; no app data changes).
  static Future<void> endAll() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('endAll');
    } catch (e) {
      debugPrint('ContentLiveActivitySync.endAll failed: $e');
    }
  }

  static Future<void> endMemoryVerse() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('endMemoryVerse');
    } catch (e) {
      debugPrint('ContentLiveActivitySync.endMemoryVerse failed: $e');
    }
  }

  static Future<void> endContinueReading() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('endContinueReading');
    } catch (e) {
      debugPrint('ContentLiveActivitySync.endContinueReading failed: $e');
    }
  }

  /// Today's Memory Verse — uses Verse-of-the-Day widget data when present.
  /// Review counts are display-only prefs (default 0/5); never changes verse logic.
  static Future<void> syncMemoryVerse({
    bool forceStart = false,
    String? reference,
    String? verseText,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      var ref = (reference ?? '').trim();
      var snippet = (verseText ?? '').trim();

      if (ref.isEmpty || snippet.isEmpty) {
        try {
          final storedRef =
              await HomeWidget.getWidgetData<String>(_verseReferenceKey);
          final storedText =
              await HomeWidget.getWidgetData<String>(_verseTextKey);
          if (ref.isEmpty && (storedRef?.trim().isNotEmpty ?? false)) {
            ref = storedRef!.trim();
          }
          if (snippet.isEmpty && (storedText?.trim().isNotEmpty ?? false)) {
            snippet = storedText!.trim();
          }
        } catch (_) {}
      }

      if (ref.isEmpty) ref = _kDefaultMemoryRef;
      if (snippet.isNotEmpty) {
        snippet = _stripHtml(snippet);
        if (snippet.length > 90) {
          snippet = '${snippet.substring(0, 90).trim()}…';
        }
      }

      final reviewed = await SharPreferences.getInt(
              SharPreferences.liveActivityMemoryReviewed) ??
          0;
      final total = await SharPreferences.getInt(
              SharPreferences.liveActivityMemoryReviewTotal) ??
          _defaultReviewTotal;

      await _channel.invokeMethod<void>('syncMemoryVerse', <String, dynamic>{
        'reference': ref,
        'verseSnippet': snippet,
        'reviewedCount': reviewed.clamp(0, total),
        'reviewTotal': total < 1 ? _defaultReviewTotal : total,
        'forceStart': forceStart,
      });
    } catch (e) {
      debugPrint('ContentLiveActivitySync.syncMemoryVerse failed: $e');
    }
  }

  /// Continue Reading — mirrors prefs + DB progress (same sources as home widget).
  static Future<void> syncContinueReading({bool forceStart = false}) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final book =
          (await SharPreferences.getString(SharPreferences.selectedBook))
                  ?.trim() ??
              '';
      final chapter =
          (await SharPreferences.getString(SharPreferences.selectedChapter))
                  ?.trim() ??
              '';
      final bookNumStr =
          (await SharPreferences.getString(SharPreferences.selectedBookNum)) ??
              '0';
      final bookNum = int.tryParse(bookNumStr) ?? 0;
      final chapterNum = int.tryParse(chapter) ?? 1;

      var bookChapter = [book, chapter].where((s) => s.isNotEmpty).join(' ');
      if (bookChapter.isEmpty) bookChapter = 'Genesis 1';

      var progressFraction = 0.0;
      var verseCount = 0;
      try {
        final db = await DBHelper().db;
        if (db != null && bookNum >= 0) {
          final progressRows = await db.rawQuery(
            'SELECT read_per FROM book WHERE book_num = ? LIMIT 1',
            [bookNum],
          );
          if (progressRows.isNotEmpty &&
              progressRows.first['read_per'] != null) {
            final readPer =
                double.tryParse(progressRows.first['read_per'].toString()) ??
                    0.0;
            progressFraction = (readPer / 100.0).clamp(0.0, 1.0);
          }

          // chapter_num in DB is 0-based (UI chapter - 1).
          final countRows = await db.rawQuery(
            'SELECT COUNT(*) as c FROM verse WHERE book_num = ? AND chapter_num = ?',
            [bookNum, (chapterNum - 1).clamp(0, 200)],
          );
          if (countRows.isNotEmpty) {
            verseCount = int.tryParse('${countRows.first['c']}') ?? 0;
          }
        }
      } catch (e) {
        debugPrint('ContentLiveActivitySync continue DB read failed: $e');
      }

      // Display-only estimate of position within the chapter (no reader writes).
      final detailLine = () {
        if (verseCount > 0) {
          final approxVerse =
              (progressFraction * verseCount).round().clamp(1, verseCount);
          return 'Verse $approxVerse of $verseCount';
        }
        final pct = (progressFraction * 100).round();
        return chapter.isNotEmpty
            ? 'Chapter $chapter · $pct% of book'
            : '$pct% of book';
      }();

      // Display-only remaining-time hint from book progress (not a real timer).
      final remainingMinutes =
          ((1.0 - progressFraction) * 25).round().clamp(1, 25);
      final footerText = progressFraction >= 0.999
          ? 'Chapter complete — great job!'
          : '$remainingMinutes minutes remaining';

      await _channel.invokeMethod<void>('syncContinueReading', <String, dynamic>{
        'bookChapter': bookChapter,
        'detailLine': detailLine,
        'footerText': footerText,
        'forceStart': forceStart,
      });
    } catch (e) {
      debugPrint('ContentLiveActivitySync.syncContinueReading failed: $e');
    }
  }

  static String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

const String _kDefaultMemoryRef = 'John 3:16';
