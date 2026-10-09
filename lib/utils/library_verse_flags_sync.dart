import 'package:biblebookapp/Model/bookMarkModel.dart';
import 'package:biblebookapp/Model/highLightContentModal.dart';
import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

typedef ReadingProgressSnapshot = ({
  List<Map<String, Object?>> verses,
  List<Map<String, Object?>> books,
});

/// After a Bible version reload replaces the `verse` table, re-stamp BM / HL /
/// UL / Notes flags from My Library onto matching verse rows.
/// Matches book, chapter, and verse first. Verse ids are not used.
/// Does not change library rows or switch flow.
class LibraryVerseFlagsSync {
  LibraryVerseFlagsSync._();

  static String _plain(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      return (html_parser.parse(raw).body?.text ?? raw).trim();
    } catch (_) {
      return raw.trim();
    }
  }

  /// Legacy library rows were just copied. Paint verse flags, then reload the
  /// open chapter so Home shows them on this launch.
  static Future<void> reapplyAfterLegacyCopy(bool inserted) async {
    if (!inserted) return;
    await reapplyToVerseTable();
    reloadOpenChapterAfterLibraryChange();
  }

  static Future<int> _paint({
    required num? bookNum,
    required num? chapterNum,
    required num? verseNum,
    required String plain,
    required String rawContent,
    required String column,
    required String value,
    required Future<int> Function(String text) byPlainText,
  }) async {
    final byPlace = await DBHelper().updateVerseFlagByLibraryPlace(
      bookNum: bookNum,
      chapterNum: chapterNum,
      verseNum: verseNum,
      column: column,
      value: value,
      plainText: plain,
    );
    if (byPlace > 0) return byPlace;
    if (plain.isEmpty) return 0;
    final byText = await byPlainText(plain);
    if (byText > 0) return byText;
    if (rawContent.trim().isEmpty || rawContent.trim() == plain) return 0;
    return DBHelper().updateVersesDataByContent(rawContent, column, value);
  }

  static Future<void> reapplyToVerseTable() async {
    try {
      final dbHelper = DBHelper();
      final List<BookMarkModel> bookmarks = await dbHelper.getBookMark();
      final List<HighLightContentModal> highlights =
          await dbHelper.getHighlight();
      final List<BookMarkModel> underlines = await dbHelper.getUnderLine();
      final List<SaveNotesModel> notes = await dbHelper.getNotes();

      for (final e in bookmarks) {
        final raw = e.content?.toString() ?? '';
        final plain = _plain(raw.isNotEmpty ? raw : e.plaincontent?.toString());
        await _paint(
          bookNum: e.bookNum,
          chapterNum: e.chapterNum,
          verseNum: e.verseNum,
          plain: plain,
          rawContent: raw,
          column: 'is_bookmarked',
          value: 'yes',
          byPlainText: (text) => DBHelper()
              .updateVersesDataByContentnew(text, 'is_bookmarked', 'yes'),
        );
      }

      for (final e in highlights) {
        final raw = e.content?.toString() ?? '';
        final plain =
            _plain(raw.isNotEmpty ? raw : e.plain_content?.toString());
        await _paint(
          bookNum: e.bookNum,
          chapterNum: e.chapterNum,
          verseNum: e.verseNum,
          plain: plain,
          rawContent: raw,
          column: 'is_highlighted',
          value: '${e.color}',
          byPlainText: (text) => DBHelper().updateVersesDataByContentnewcheck(
              text, 'is_highlighted', '${e.color}'),
        );
      }

      for (final e in underlines) {
        final raw = e.content?.toString() ?? '';
        final plain = _plain(raw.isNotEmpty ? raw : e.plaincontent?.toString());
        await _paint(
          bookNum: e.bookNum,
          chapterNum: e.chapterNum,
          verseNum: e.verseNum,
          plain: plain,
          rawContent: raw,
          column: 'is_underlined',
          value: 'yes',
          byPlainText: (text) => DBHelper()
              .updateVersesDataByContentnew(text, 'is_underlined', 'yes'),
        );
      }

      for (final e in notes) {
        final raw = e.content?.toString() ?? '';
        final plain = _plain(raw.isNotEmpty ? raw : e.plaincontent?.toString());
        await _paint(
          bookNum: e.bookNum,
          chapterNum: e.chapterNum,
          verseNum: e.verseNum,
          plain: plain,
          rawContent: raw,
          column: 'is_noted',
          value: '${e.notes}',
          byPlainText: (text) => DBHelper()
              .updateVersesDataByContentnew(text, 'is_noted', '${e.notes}'),
        );
      }

      debugPrint(
        'LibraryVerseFlagsSync: reapplied '
        'BM=${bookmarks.length} HL=${highlights.length} '
        'UL=${underlines.length} Notes=${notes.length}',
      );
    } catch (e, st) {
      debugPrint('LibraryVerseFlagsSync error: $e\n$st');
    }
  }

  /// Read status exists only on `verse` / `book`, so a Bible reload loses it.
  /// Take this before the reload and pass it to [restoreReadingProgress].
  static Future<ReadingProgressSnapshot> saveReadingProgress() async {
    const empty = (
      verses: <Map<String, Object?>>[],
      books: <Map<String, Object?>>[],
    );
    try {
      final db = await DBHelper().db;
      if (db == null) return empty;
      final List<Map<String, Object?>> verses = await db.rawQuery(
        "SELECT book_num, chapter_num, verse_num, is_read FROM verse "
        "WHERE LOWER(TRIM(COALESCE(is_read, ''))) NOT IN ('', 'no')",
      );
      final List<Map<String, Object?>> books = await db.rawQuery(
        "SELECT book_num, read_per FROM book "
        "WHERE TRIM(COALESCE(read_per, '')) NOT IN ('', '0', '0.0')",
      );
      return (verses: verses, books: books);
    } catch (e, st) {
      debugPrint('saveReadingProgress error: $e\n$st');
      return empty;
    }
  }

  static Future<void> restoreReadingProgress(
    ReadingProgressSnapshot progress,
  ) async {
    if (progress.verses.isEmpty && progress.books.isEmpty) return;
    try {
      final db = await DBHelper().db;
      if (db == null) return;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final v in progress.verses) {
          batch.rawUpdate(
            'UPDATE verse SET is_read = ? '
            'WHERE book_num = ? AND chapter_num = ? AND verse_num = ?',
            [v['is_read'], v['book_num'], v['chapter_num'], v['verse_num']],
          );
        }
        for (final b in progress.books) {
          batch.rawUpdate(
            'UPDATE book SET read_per = ? WHERE book_num = ?',
            [b['read_per'], b['book_num']],
          );
        }
        await batch.commit(noResult: true);
      });
      debugPrint(
        'LibraryVerseFlagsSync: restored reading progress '
        'verses=${progress.verses.length} books=${progress.books.length}',
      );
    } catch (e, st) {
      debugPrint('restoreReadingProgress error: $e\n$st');
    }
  }
}
