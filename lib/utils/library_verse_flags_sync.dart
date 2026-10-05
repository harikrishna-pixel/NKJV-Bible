import 'package:biblebookapp/Model/bookMarkModel.dart';
import 'package:biblebookapp/Model/highLightContentModal.dart';
import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

/// After a Bible version reload replaces the `verse` table, re-stamp BM / HL /
/// UL / Notes flags from My Library onto matching verse rows.
/// Same approach as splash [updateLocalDB] (content match only — verse ids
/// change when the table is rebuilt). Does not change library rows or switch flow.
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

  static Future<void> reapplyToVerseTable() async {
    try {
      final dbHelper = DBHelper();
      final List<BookMarkModel> bookmarks = await dbHelper.getBookMark();
      final List<HighLightContentModal> highlights =
          await dbHelper.getHighlight();
      final List<BookMarkModel> underlines = await dbHelper.getUnderLine();
      final List<SaveNotesModel> notes = await dbHelper.getNotes();

      if (bookmarks.isEmpty &&
          highlights.isEmpty &&
          underlines.isEmpty &&
          notes.isEmpty) {
        debugPrint(
          'LibraryVerseFlagsSync: reapplied BM=0 HL=0 UL=0 Notes=0',
        );
        return;
      }

      final db = await DBHelper().db;
      if (db == null) return;

      // One read of the verse table. Same matches as the per-item scans:
      // first plain-text match, plus every row whose content equals the saved text.
      final verses = await db.query('verse', columns: ['id', 'content']);
      final firstIdByPlain = <String, int>{};
      final idsByExact = <String, List<int>>{};
      var seen = 0;
      for (final verse in verses) {
        final id = int.tryParse('${verse['id']}');
        if (id == null) continue;
        final htmlContent = verse['content']?.toString() ?? '';
        final parsed = _plain(htmlContent);
        if (parsed.isNotEmpty) {
          firstIdByPlain.putIfAbsent(parsed, () => id);
        }
        if (htmlContent.isNotEmpty) {
          (idsByExact[htmlContent] ??= <int>[]).add(id);
        }
        seen++;
        if (seen % 400 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      final batch = db.batch();
      void stamp(int id, String column, String value) {
        batch.update(
          'verse',
          {column: value},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      void stampPlainAndExact({
        required String plain,
        required String raw,
        required String column,
        required String value,
      }) {
        if (plain.isEmpty) return;
        final matched = firstIdByPlain[plain];
        if (matched != null) stamp(matched, column, value);
        if (raw.trim().isEmpty) return;
        for (final id in idsByExact[raw] ?? const <int>[]) {
          stamp(id, column, value);
        }
      }

      for (final e in bookmarks) {
        stampPlainAndExact(
          plain: _plain(e.content?.toString() ?? e.plaincontent?.toString()),
          raw: e.content?.toString() ?? '',
          column: 'is_bookmarked',
          value: 'yes',
        );
      }

      for (final e in highlights) {
        stampPlainAndExact(
          plain: _plain(e.content?.toString() ?? e.plain_content?.toString()),
          raw: e.content?.toString() ?? '',
          column: 'is_highlighted',
          value: '${e.color}',
        );
      }

      for (final e in underlines) {
        stampPlainAndExact(
          plain: _plain(e.content?.toString() ?? e.plaincontent?.toString()),
          raw: e.content?.toString() ?? '',
          column: 'is_underlined',
          value: 'yes',
        );
      }

      for (final e in notes) {
        stampPlainAndExact(
          plain: _plain(e.content?.toString() ?? e.plaincontent?.toString()),
          raw: e.content?.toString() ?? '',
          column: 'is_noted',
          value: '${e.notes}',
        );
      }

      await batch.commit(noResult: true);

      debugPrint(
        'LibraryVerseFlagsSync: reapplied '
        'BM=${bookmarks.length} HL=${highlights.length} '
        'UL=${underlines.length} Notes=${notes.length}',
      );
    } catch (e, st) {
      debugPrint('LibraryVerseFlagsSync error: $e\n$st');
    }
  }
}
