import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:html/parser.dart' show parse;

/// UI guard for Library → Read when the active Bible differs from
/// the Bible the item was saved from. Does not change DB / switch logic.
class LibraryBibleGuard {
  LibraryBibleGuard._();

  static const differentBibleMessage =
      "You're in a different Bible. Switch to that Bible to read this.";

  static String _plain(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final text = parse(raw).body?.text ?? raw;
    return text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  /// Returns true when the saved verse matches the current Bible DB row.
  static Future<bool> matchesCurrentBible({
    required num? bookNum,
    required num? chapterNum,
    required num? verseNum,
    String? savedContent,
  }) async {
    final book = bookNum?.toInt();
    final chapter = chapterNum?.toInt();
    final verse = verseNum?.toInt();
    if (book == null || chapter == null || verse == null) return true;

    try {
      final db = await DBHelper().db;
      if (db == null) return true;

      // Library / Daily Verse pass UI 1-based chapter+verse; verse table is
      // 0-based. Try both so lookup works without changing Read navigation.
      Future<List<Map<String, Object?>>> lookup(int ch, int vs) {
        return db.rawQuery(
          'SELECT content FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ? LIMIT 1',
          [book, ch, vs],
        );
      }

      final chapterCandidates = <int>{
        chapter,
        if (chapter > 0) chapter - 1,
      };
      final verseCandidates = <int>{
        verse,
        if (verse > 0) verse - 1,
      };

      var rows = <Map<String, Object?>>[];
      for (final ch in chapterCandidates) {
        for (final vs in verseCandidates) {
          rows = await lookup(ch, vs);
          if (rows.isNotEmpty) break;
        }
        if (rows.isNotEmpty) break;
      }
      if (rows.isEmpty) {
        // Book/chapter may not exist in this Bible version.
        return false;
      }

      final saved = _plain(savedContent);
      if (saved.isEmpty) return true;

      final current = _plain(rows.first['content']?.toString());
      if (current.isEmpty) return false;

      if (current == saved) return true;
      // Allow minor HTML/whitespace differences.
      final a = saved.length > 40 ? saved.substring(0, 40) : saved;
      final b = current.length > 40 ? current.substring(0, 40) : current;
      return a == b || current.contains(a) || saved.contains(b);
    } catch (_) {
      return true;
    }
  }

  /// Shows toast and returns false when item is from another Bible.
  /// UI gate disabled: always allow navigation (same as pre-guard behavior).
  static Future<bool> allowReadOrToast({
    required num? bookNum,
    required num? chapterNum,
    required num? verseNum,
    String? savedContent,
  }) async {
    return true;
  }
}
