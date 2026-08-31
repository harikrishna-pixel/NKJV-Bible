import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';

class StudyPlanVerseService {
  /// Parse verse reference like "Genesis 1:1" or "John 3:16" or "1 Peter 1:8-9"
  static Map<String, dynamic>? parseVerseReference(String reference) {
    try {
      // Remove extra spaces
      reference = reference.trim();

      // Split by space to get book name and chapter:verse
      final parts = reference.split(' ');
      if (parts.length < 2) return null;

      // Handle books with numbers (e.g., "1 Peter", "2 Corinthians")
      String bookName;
      String chapterVerse;

      if (parts[0].contains(RegExp(r'^\d'))) {
        // Book starts with number (e.g., "1 Peter")
        bookName = '${parts[0]} ${parts[1]}';
        chapterVerse = parts[2];
      } else {
        // Normal book (e.g., "Genesis")
        bookName = parts[0];
        chapterVerse = parts[1];
      }

      // Split chapter:verse
      final chapterVerseParts = chapterVerse.split(':');
      if (chapterVerseParts.length != 2) return null;

      final chapter = int.tryParse(chapterVerseParts[0]);
      if (chapter == null) return null;

      // Handle verse ranges like "8-9"
      final verseStr = chapterVerseParts[1];
      List<int> verses = [];

      if (verseStr.contains('-')) {
        final range = verseStr.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]);
          final end = int.tryParse(range[1]);
          if (start != null && end != null) {
            for (int i = start; i <= end; i++) {
              verses.add(i);
            }
          }
        }
      } else {
        final verse = int.tryParse(verseStr);
        if (verse != null) {
          verses.add(verse);
        }
      }

      if (verses.isEmpty) return null;

      return {
        'bookName': bookName,
        'chapter': chapter,
        'verses': verses,
      };
    } catch (e) {
      print('Error parsing verse reference: $e');
      return null;
    }
  }

  /// Get book number from book name
  static Future<int?> getBookNumber(String bookName) async {
    final db = await DBHelper().db;
    if (db == null) return null;

    try {
      // Try exact match with title first
      var result = await db.rawQuery(
        "SELECT book_num FROM book WHERE title = ? LIMIT 1",
        [bookName],
      );

      if (result.isNotEmpty) {
        return result[0]['book_num'] as int?;
      }

      // Try case-insensitive match with title
      result = await db.rawQuery(
        "SELECT book_num FROM book WHERE LOWER(title) = LOWER(?) LIMIT 1",
        [bookName],
      );

      if (result.isNotEmpty) {
        return result[0]['book_num'] as int?;
      }

      // Try short_title
      result = await db.rawQuery(
        "SELECT book_num FROM book WHERE LOWER(short_title) = LOWER(?) LIMIT 1",
        [bookName],
      );

      if (result.isNotEmpty) {
        return result[0]['book_num'] as int?;
      }

      // Try alternative names (e.g., "Psalms" vs "Psalm")
      final altName = bookName.endsWith('s')
          ? bookName.substring(0, bookName.length - 1)
          : '${bookName}s';

      result = await db.rawQuery(
        "SELECT book_num FROM book WHERE LOWER(title) = LOWER(?) OR LOWER(short_title) = LOWER(?) LIMIT 1",
        [altName, altName],
      );

      if (result.isNotEmpty) {
        return result[0]['book_num'] as int?;
      }
    } catch (e) {
      print('Error getting book number: $e');
    }

    return null;
  }

  /// Fetch verse content from database
  static Future<List<VerseBookContentModel>> fetchVerseContent(
    String verseReference,
  ) async {
    final parsed = parseVerseReference(verseReference);
    if (parsed == null) return [];

    final bookName = parsed['bookName'] as String;
    final chapter = parsed['chapter'] as int;
    final verses = parsed['verses'] as List<int>;

    final bookNum = await getBookNumber(bookName);
    if (bookNum == null) return [];

    final db = await DBHelper().db;
    if (db == null) return [];

    try {
      final List<VerseBookContentModel> verseContents = [];

      for (final verseNum in verses) {
        // Primary query: use chapter - 1 (some DBs use 0-based chapter indexing)
        var result = await db.rawQuery(
          "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
          [bookNum, chapter - 1, verseNum],
        );

        // Fallback: if no rows returned, try using the chapter number as-is
        // (handles DBs that store chapter numbers 1-based). This is a
        // presentation-friendly fallback – it doesn't change core logic but
        // increases robustness for different DB formats.
        if (result.isEmpty) {
          result = await db.rawQuery(
            "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
            [bookNum, chapter, verseNum],
          );
        }

        if (result.isNotEmpty) {
          verseContents.add(VerseBookContentModel.fromJson(result[0]));
        }
      }

      return verseContents;
    } catch (e) {
      print('Error fetching verse content: $e');
      return [];
    }
  }

  /// Fetch all verses for a study plan
  static Future<Map<String, List<VerseBookContentModel>>> fetchAllPlanVerses(
    List<String> verseReferences,
  ) async {
    final Map<String, List<VerseBookContentModel>> versesMap = {};

    for (final reference in verseReferences) {
      final verses = await fetchVerseContent(reference);
      versesMap[reference] = verses;
    }

    return versesMap;
  }
}
