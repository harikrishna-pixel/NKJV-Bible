import 'package:biblebookapp/services/study_plan_verse_service.dart';
import 'package:biblebookapp/controller/dpProvider.dart';

void main() async {
  // Test the verse parsing for Joshua 1:9
  final reference = "Joshua 1:9";
  print("Testing verse reference: $reference");
  
  final parsed = StudyPlanVerseService.parseVerseReference(reference);
  print("Parsed result: $parsed");
  
  if (parsed != null) {
    final bookName = parsed['bookName'] as String;
    final chapter = parsed['chapter'] as int;
    final verses = parsed['verses'] as List<int>;
    
    print("Book name: '$bookName'");
    print("Chapter: $chapter");
    print("Verses: $verses");
    
    // Get book number
    final bookNum = await StudyPlanVerseService.getBookNumber(bookName);
    print("Book number found: $bookNum");
    
    if (bookNum != null) {
      // Test database query directly
      final db = await DBHelper().db;
      if (db != null) {
        for (final verseNum in verses) {
          print("\nQuerying: book_num=$bookNum, chapter_num=$chapter, verse_num=$verseNum");
          
          final result = await db.rawQuery(
            "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
            [bookNum, chapter, verseNum],
          );
          
          print("Query result count: ${result.length}");
          if (result.isNotEmpty) {
            print("Found verse content: ${result[0]}");
          } else {
            // Debug: Let's see what's in the database for this book and chapter
            final chapterVerses = await db.rawQuery(
              "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? ORDER BY verse_num",
              [bookNum, chapter],
            );
            print("All verses in Joshua chapter $chapter: ${chapterVerses.length}");
            if (chapterVerses.isNotEmpty) {
              print("First verse in chapter: ${chapterVerses[0]}");
              print("Last verse in chapter: ${chapterVerses.last}");
            }
          }
        }
      }
    } else {
      print("Book number not found for '$bookName'");
      
      // Debug: Check all books available
      final db = await DBHelper().db;
      if (db != null) {
        final allBooks = await db.rawQuery("SELECT * FROM book ORDER BY book_num");
        print("All books in database:");
        for (final book in allBooks) {
          print("  Book ${book['book_num']}: '${book['title']}' (short: '${book['short_title']}')");
        }
      }
    }
  }
}