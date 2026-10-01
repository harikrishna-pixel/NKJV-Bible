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

      for (final e in bookmarks) {
        final plain =
            _plain(e.content?.toString() ?? e.plaincontent?.toString());
        if (plain.isEmpty) continue;
        await DBHelper()
            .updateVersesDataByContentnew(plain, 'is_bookmarked', 'yes');
        if (e.content != null && e.content.toString().trim().isNotEmpty) {
          await DBHelper().updateVersesDataByContent(
              e.content.toString(), 'is_bookmarked', 'yes');
        }
      }

      for (final e in highlights) {
        final plain =
            _plain(e.content?.toString() ?? e.plain_content?.toString());
        if (plain.isEmpty) continue;
        await DBHelper().updateVersesDataByContentnewcheck(
            plain, 'is_highlighted', '${e.color}');
        if (e.content != null && e.content.toString().trim().isNotEmpty) {
          await DBHelper().updateVersesDataByContent(
              e.content.toString(), 'is_highlighted', '${e.color}');
        }
      }

      for (final e in underlines) {
        final plain =
            _plain(e.content?.toString() ?? e.plaincontent?.toString());
        if (plain.isEmpty) continue;
        await DBHelper()
            .updateVersesDataByContentnew(plain, 'is_underlined', 'yes');
        if (e.content != null && e.content.toString().trim().isNotEmpty) {
          await DBHelper().updateVersesDataByContent(
              e.content.toString(), 'is_underlined', 'yes');
        }
      }

      for (final e in notes) {
        final plain =
            _plain(e.content?.toString() ?? e.plaincontent?.toString());
        if (plain.isEmpty) continue;
        await DBHelper().updateVersesDataByContentnew(
            plain, 'is_noted', '${e.notes}');
        if (e.content != null && e.content.toString().trim().isNotEmpty) {
          await DBHelper().updateVersesDataByContent(
              e.content.toString(), 'is_noted', '${e.notes}');
        }
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
}
