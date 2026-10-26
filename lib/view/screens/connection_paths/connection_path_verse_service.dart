import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';

/// Loads verse `content` using 0-based indexes from connection_paths JSON.
/// Uses the existing Bible DB only — does not change schema or onboarding.
class ConnectionPathVerseService {
  ConnectionPathVerseService._();

  static Future<String> textForDay(PathDay day) async {
    final parts = <String>[];
    for (final v in day.verses) {
      final t = await _content(v);
      if (t.isNotEmpty) parts.add(t);
    }
    return parts.join(' ');
  }

  static Future<String> textForRefs(List<PathVerseRef> refs) async {
    final parts = <String>[];
    for (final v in refs) {
      final t = await _content(v);
      if (t.isNotEmpty) parts.add(t);
    }
    return parts.join(' ');
  }

  static Future<String> _content(PathVerseRef ref) async {
    final db = await DBHelper().db;
    if (db == null) return '';
    try {
      // JSON indexes are 0-based (same as verse_json / this app's DB).
      var rows = await db.rawQuery(
        'SELECT content FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
        [ref.bookNum, ref.chapterNum, ref.verseNum],
      );
      if (rows.isEmpty) {
        // Fallback if a DB stores 1-based chapter/verse.
        rows = await db.rawQuery(
          'SELECT content FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
          [ref.bookNum, ref.chapterNum + 1, ref.verseNum + 1],
        );
      }
      if (rows.isEmpty) return '';
      return _clean((rows.first['content'] ?? '').toString());
    } catch (_) {
      return '';
    }
  }

  static String _clean(String raw) => raw
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .trim();

  /// Optional typed model list (unused by UI; kept for callers that need it).
  static Future<List<VerseBookContentModel>> modelsForDay(PathDay day) async {
    final db = await DBHelper().db;
    if (db == null) return const [];
    final out = <VerseBookContentModel>[];
    for (final ref in day.verses) {
      try {
        var rows = await db.rawQuery(
          'SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
          [ref.bookNum, ref.chapterNum, ref.verseNum],
        );
        if (rows.isEmpty) {
          rows = await db.rawQuery(
            'SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
            [ref.bookNum, ref.chapterNum + 1, ref.verseNum + 1],
          );
        }
        if (rows.isNotEmpty) {
          out.add(VerseBookContentModel.fromJson(rows.first));
        }
      } catch (_) {}
    }
    return out;
  }
}
