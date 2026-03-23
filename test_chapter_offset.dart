// import 'package:biblebookapp/services/study_plan_verse_service.dart';
// import 'package:biblebookapp/controller/dpProvider.dart';
//
// void main() async {
//   // Test the verse parsing for Joshua 1:9
//   final bookNum = 6; // Joshua is typically book 6
//   final chapter = 1; // Chapter 1
//   final verse = 9; // Verse 9
//
//   print("Testing Joshua 1:9 with different query approaches:");
//
//   final db = await DBHelper().db;
//   if (db != null) {
//
//     print("\n1. Study plan query (direct chapter):");
//     final studyPlanResult = await db.rawQuery(
//       "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
//       [bookNum, chapter, verse],
//     );
//     print("Result count: ${studyPlanResult.length}");
//     if (studyPlanResult.isNotEmpty) {
//       print("Content: ${studyPlanResult[0]['content']}");
//     }
//
//     print("\n2. Reading Bible query (chapter - 1):");
//     final readingBibleResult = await db.rawQuery(
//       "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
//       [bookNum, chapter - 1, verse],
//     );
//     print("Result count: ${readingBibleResult.length}");
//     if (readingBibleResult.isNotEmpty) {
//       print("Content: ${readingBibleResult[0]['content']}");
//     }
//
//     print("\n3. Check all chapters for Joshua:");
//     for (int c = 0; c <= 2; c++) {
//       final chapterVerses = await db.rawQuery(
//         "SELECT COUNT(*) as count FROM verse WHERE book_num = ? AND chapter_num = ?",
//         [bookNum, c],
//       );
//       final count = chapterVerses[0]['count'];
//       print("  Joshua chapter $c (index $c): $count verses");
//
//       if (count != null && count > 0) {
//         // Show first few verses
//         final sample = await db.rawQuery(
//           "SELECT verse_num FROM verse WHERE book_num = ? AND chapter_num = ? ORDER BY verse_num LIMIT 3",
//           [bookNum, c],
//         );
//         print("    Sample verses: ${sample.map((v) => v['verse_num']).toList()}");
//       }
//     }
//
//     print("\n4. Check different book numbers for Joshua:");
//     for (int b = 5; b <= 7; b++) {
//       final bookCheck = await db.rawQuery(
//         "SELECT COUNT(*) as count FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
//         [b, 0, 9], // Try chapter 0 (common offset)
//       );
//       print("  Book $b, chapter 0, verse 9: ${bookCheck[0]['count']} results");
//     }
//
//     // Test the actual parsing from "Joshua 1:9"
//     print("\n5. Test complete flow with 'Joshua 1:9':");
//     final parsed = StudyPlanVerseService.parseVerseReference("Joshua 1:9");
//     print("Parsed: $parsed");
//
//     if (parsed != null) {
//       final parsedBookNum = await StudyPlanVerseService.getBookNumber(parsed['bookName']);
//       print("Book number from parsing: $parsedBookNum");
//
//       if (parsedBookNum != null) {
//         // Try with the correct chapter offset
//         final correctedResult = await db.rawQuery(
//           "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
//           [parsedBookNum, parsed['chapter'] as int - parsed['verses'][0]],
//         );
//         print("Result with chapter - 1: ${correctedResult.length}");
//         if (correctedResult.isNotEmpty) {
//           print("Corrected content: ${correctedResult[0]['content']}");
//         }
//       }
//     }
//   }
// }