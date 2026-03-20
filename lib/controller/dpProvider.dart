import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as plain;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:biblebookapp/Model/dailyVersesMainListModel.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';

import '../Model/bookMarkModel.dart';
import '../Model/highLightContentModal.dart';
import '../Model/saveImagesModel.dart';
import '../Model/saveNotesModel.dart';
import '../Model/verseBookContentModel.dart';

class DBHelper {
  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDatabase();
    return _db;
  }

  /// Same as [db] — useful for diagnostics snippets.
  Future<Database?> get database async => db;

  /// Debug: log My Library row counts + encrypted DB path (filter logs: `LIBRARY_COUNTS`).
  static Future<void> debugPrintLibraryTableCounts() async {
    try {
      final db = await DBHelper().db;
      if (db == null) {
        print('LIBRARY_COUNTS DB is null');
        return;
      }
      final bookmark =
          await db.rawQuery("SELECT COUNT(*) as c FROM bookmark");
      final highlight =
          await db.rawQuery("SELECT COUNT(*) as c FROM highlight");
      final underline =
          await db.rawQuery("SELECT COUNT(*) as c FROM underline");
      final notes =
          await db.rawQuery("SELECT COUNT(*) as c FROM save_notes");
      print('LIBRARY_COUNTS BOOKMARK: ${bookmark.first['c']}');
      print('LIBRARY_COUNTS HIGHLIGHT: ${highlight.first['c']}');
      print('LIBRARY_COUNTS UNDERLINE: ${underline.first['c']}');
      print('LIBRARY_COUNTS NOTES: ${notes.first['c']}');
      print('LIBRARY_COUNTS DB PATH: ${db.path}');
    } catch (e, st) {
      print('LIBRARY_COUNTS error: $e\n$st');
    }
  }

  initDatabase() async {
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(
      documentDirectory.path,
      'bible_enc.db',
    );

    var db = await openDatabase(
      path,
      version: 3,
      password: dotenv.env[AssetsConstants.dbPasswordKey],
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date"	DATETIME)');
        }
        if (oldVersion < 3) {
          // Changes added in version 3
          await db.execute(
              'CREATE TABLE IF NOT EXISTS "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT, "Category_Name" TEXT, "Category_Id" INTEGER, "Book" TEXT, "Book_Id" INTEGER, "Chapter" INTEGER, "Verse" TEXT, "Date" TEXT, "Verse_Num" INTEGER)');

          try {
            await db.execute(
                'ALTER TABLE bookmark ADD COLUMN plaincontent VARCHAR');
          } catch (e) {
            debugPrint('bookmark: plaincontent already exists or error: $e');
          }

          try {
            await db.execute(
                'ALTER TABLE save_notes ADD COLUMN plaincontent VARCHAR');
          } catch (e) {
            debugPrint('save_notes: plaincontent already exists or error: $e');
          }

          try {
            await db.execute(
                'ALTER TABLE highlight ADD COLUMN plain_content VARCHAR');
          } catch (e) {
            debugPrint('highlight: plain_content already exists or error: $e');
          }

          try {
            await db
                .execute('ALTER TABLE highlight ADD COLUMN verse_id VARCHAR');
          } catch (e) {
            debugPrint('highlight: verse_id already exists or error: $e');
          }
        }
      },
    );
    return db;
  }

  _onCreate(Database db, int version) async {
    try {
      await db.execute(
          'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date"	DATETIME)');
      await db.execute(
          'CREATE TABLE "verse" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num"	INTEGER, "chapter_num"	INTEGER, "verse_num"	INTEGER,"content"	TEXT,"is_read"	TEXT,"is_bookmarked"	TEXT,"is_underlined"	TEXT,"is_highlighted"	TEXT,"is_noted"	TEXT)');
      await db.execute(
          'CREATE TABLE "bookmark" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR,"bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "save_notes" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR,"book_name" VARCHAR, "notes" VARCHAR, "plaincontent" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "highlight" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plain_content" VARCHAR, verse_id VARCHAR, "book_name" VARCHAR,"color" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "underline" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR, "bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "book" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num"	INTEGER,"title"	TEXT,"short_title"	TEXT,"chapter_count"	INTEGER,"read_per"	TEXT)');
      await db.execute(
          'CREATE TABLE "save_images" (id INTEGER PRIMARY KEY AUTOINCREMENT,"image_path"	TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVersesMainList" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVerses" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
      await db.execute(
          'CREATE TABLE "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    } catch (e) {
      debugPrint('Error Creating Tables: $e');
    }
  }

////
  /// Calendar CRUD
  ///
////
  Future<void> saveCalendarData(CalendarModel calendar) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("calendar", calendar.toJson());
    } catch (_) {
      rethrow;
    }
  }

  Future<List<CalendarModel>> getCalendarData() async {
    try {
      var dbAccount = await db;
      final List<Map<String, Object?>> queryResult =
          await dbAccount!.query("calendar");
      return queryResult.map((e) => CalendarModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<int> deleteCalendarData(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("calendar", where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateCalendarData(CalendarModel calendarData) async {
    var dbClient = await db;
    var res = await dbClient!.update("calendar", calendarData.toJson(),
        where: "id = ?", whereArgs: [calendarData.id]);
    return res;
  }

  ////
  /// End of Calendar CRUD
  ///
  ///.

  /// Save images
  Future<SaveImageModel> saveImage(SaveImageModel saveimagemodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("save_images", saveimagemodel.toJson());
    } catch (e) {
      // print(e);
    }
    return saveimagemodel;
  }

  ///
  ///
  ///
  Future<List<SaveImageModel>> getImage() async {
    try {
      var dbAccount = await db;
      final List<Map<String, Object?>> queryResult =
          await dbAccount!.query("save_images", orderBy: "id DESC");
      return queryResult.map((e) => SaveImageModel.fromJson(e)).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<int> deleteImage(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_images", where: "id = ?", whereArgs: [id]);
  }

  /// main Book List content

  Future<int> updateBookData(int id, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!
        .update("book", {title: value}, where: "id = ?", whereArgs: [id]);
    return res;
  }

  /// verse Book content
  Future<List<VerseBookContentModel>> getVerse() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("verse");
    debugPrint("queryResult V is  $queryResult");
    return queryResult.map((e) => VerseBookContentModel.fromJson(e)).toList();
  }

  Future<int> updateVersesData(int? id, String title, String value) async {
    if (id != null) {
      var dbClient = await db;
      var res = await dbClient!
          .update("verse", {title: value}, where: "id = ?", whereArgs: [id]);
      return res;
    }
    return 0;
  }

  Future<int> updateVersesDataBatch(
      int id, Map<String, dynamic> updates) async {
    var dbClient = await db;
    var res = await dbClient!.update(
      "verse",
      updates,
      where: "id = ?",
      whereArgs: [id],
    );
    return res;
  }

  Future<int> updateVersesDataByContent(
      String content, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!.update("verse", {title: value},
        where: "content = ?", whereArgs: [content]);
    return res;
  }

  Future<int> updateVersesDataByContentnew(
      String plainContent, String title, String value) async {
    final dbClient = await db;

    // Step 1: Get all verses
    final List<Map<String, dynamic>> verses = await dbClient!.query("verse");

    // Step 2: Find the one with matching plain text
    for (final verse in verses) {
      final htmlContent = verse["content"] ?? "";
      final parsedText = html_parser.parse(htmlContent).body?.text ?? "";
      // debugPrint(
      //     "check highlight - ${verse["id"]}  ${parsedText.trim()} =  ${plainContent.trim()}");
      if (parsedText.trim() == plainContent.trim()) {
        final int id = verse["id"];

        // Step 3: Update this verse
        return await dbClient.update(
          "verse",
          {title: value},
          where: "id = ?",
          whereArgs: [id],
        );
      }
    }

    return 0; // No match found
  }

  Future<int> updateVersesDataByContentnewcheck(
      String plainContent, String title, String value) async {
    final dbClient = await db;

    // Step 1: Get all verses
    final List<Map<String, dynamic>> verses = await dbClient!.query("verse");

    // Step 2: Find the one with matching plain text
    for (final verse in verses) {
      final htmlContent = verse["content"] ?? "";
      final parsedText = html_parser.parse(htmlContent).body?.text ?? "";

      if (parsedText.trim() == plainContent.trim()) {
        final int id = verse["id"];
        // debugPrint(
        //     "check highlight - ${verse["id"]}  ${parsedText.trim()} =  ${plainContent.trim()}");
        // Step 3: Update this verse
        return await dbClient.update(
          "verse",
          {title: value},
          where: "id = ?",
          whereArgs: [id],
        );
      }
    }

    return 0; // No match found
  }

  Future<int> updateVersesDataByContentmy(
      String content, String title, String value) async {
    // var dbClient = await db;
    // var res = await dbClient!.update("verse", {title: value},
    //     where: "content = ?", whereArgs: [content]);
    // return res;
    final dbClient = await db;
    try {
      final res = await dbClient!.update(
        'verse',
        {title: value},
        where: 'content = ?',
        whereArgs: [content],
      );
      return res;
    } catch (e) {
      debugPrint('Error updating verse: $e');
      return 0; // or -1 based on how you handle failure
    }
  }

  ///BookMark Functions
  Future<BookMarkModel> insertBookmark(BookMarkModel bookmarkmodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("bookmark", bookmarkmodel.toJson());
    } catch (e) {
      // print(e);
    }
    return bookmarkmodel;
  }

  ///
  ///
  ///
  Future<List<BookMarkModel>> getBookMark() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("bookmark");
    return queryResult.map((e) => BookMarkModel.fromJson(e)).toList();
  }

  Future<int> deleteBookmark(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("bookmark", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteBookmarkByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("bookmark", where: "content = ?", whereArgs: [content]);
  }

  Future clearBookMarkTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("bookmark");
    } catch (e) {
      // print(e);
    }
  }

  /// Save Notes Functions
  Future<SaveNotesModel> insertNotes(SaveNotesModel savenotesmodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("save_notes", savenotesmodel.toJson());
    } catch (e) {
      // print(e);
    }
    return savenotesmodel;
  }

  ///
  ///
  ///
  Future<List<SaveNotesModel>> getNotes() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("save_notes");
    // print(queryResult);
    return queryResult.map((e) => SaveNotesModel.fromJson(e)).toList();
  }

  Future<int> updateNotesData(
      String content, String title, String value) async {
    var dbClient = await db;
    var res = await dbClient!.update("save_notes", {title: value},
        where: "content = ?", whereArgs: [content]);
    return res;
  }

  Future<int> deleteNotes(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_notes", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteNotesByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("save_notes", where: "content = ?", whereArgs: [content]);
  }

  Future clearNotesTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("save_notes");
    } catch (e) {
      // print(e);
    }
  }

  ///Highlight Functions

  Future<HighLightContentModal> insertIntoHighLight(
      HighLightContentModal highlightcontentmodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("highlight", highlightcontentmodel.toJson());
    } catch (e) {
      // print(e);
    }
    return highlightcontentmodel;
  }

  ///
  ///
  ///
  Future<List<HighLightContentModal>> getHighlight() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("highlight");
    // print(queryResult);
    return queryResult.map((e) => HighLightContentModal.fromJson(e)).toList();
  }

  Future<String?> getColorByContent(String content) async {
    var dbAccount = await db;
    // final List<Map<String, Object?>> queryResult = await dbAccount!.query(
    //   //   "highlight",
    //   //   where: "content = ?",
    //   //   whereArgs: [content],
    //   //  columns: ["color"],
    //   "highlight",
    //   where: "content = ?",
    //   whereArgs: [content],
    //   limit: 1, // We only need the first match
    // );

    final normalized = normalizeHtml(content);

    // debugPrint("highlight colr parse 2 : $normalized");

    final result = await dbAccount!.query(
      "highlight",
      where: "LOWER(plain_content) = LOWER(?)",
      whereArgs: [normalized],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first["color"]?.toString();
    }

    return null;

    // if (queryResult.isNotEmpty) {

    // return queryResult.first["color"] as String?;
    // }
    //  return null;
  }

  String normalizeHtml(String htmlContent) {
    final unescape = HtmlUnescape();
    final document = html_parser.parse(htmlContent);
    final normalized =
        unescape.convert(document.body?.text ?? htmlContent).trim();
    return normalized.replaceAll("'", '').replaceAll('"', '');
    // return unescape.convert(document.body?.text ?? htmlContent).trim();
    //return document.body?.text.trim() ?? htmlContent.trim();
  }

  // Stream<String?> getColorStreamByContent(String content) {
  //   return Stream.fromFuture(getColorByContent(content));
  // }

  Stream<String?> getColorStreamByContent(String content) async* {
    final color = await getColorByContent(content);
    yield color;
  }

  Future<int> deleteHighlight(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("highlight", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteHighlightByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("highlight", where: "content = ?", whereArgs: [content]);
  }

  Future<int> updateHighLight(
      HighLightContentModal highlight, content, data) async {
    var dbAccount = await db;
    return await dbAccount!.update("highlight", highlight.toJson(),
        where: '$content = ?', whereArgs: [data]);
  }

  Future clearHighLightTable() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("highlight");
    } catch (e) {
      // print(e);
    }
  }

  ///UnderLine Functions
  Future<BookMarkModel> insertUnderLine(BookMarkModel bookmarkmodel) async {
    var dbAccount = await db;
    try {
      await dbAccount!.insert("underline", bookmarkmodel.toJson());
    } catch (e) {
      // print(e);
    }
    return bookmarkmodel;
  }

  ///
  ///
  ///
  Future<List<BookMarkModel>> getUnderLine() async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult =
        await dbAccount!.query("underline");
    print(queryResult);
    return queryResult.map((e) => BookMarkModel.fromJson(e)).toList();
  }

  Future<int> deleteUnderline(int id) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("underline", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteUnderlineByContent(String content) async {
    var dbAccount = await db;
    return await dbAccount!
        .delete("underline", where: "content = ?", whereArgs: [content]);
  }

  Future clearUnderLine() async {
    var dbAccount = await db;
    try {
      await dbAccount!.delete("underline");
    } catch (e) {
      // print(e);
    }
  }

  Future<List<VerseBookContentModel>> getSelectedBookContent(
      selectedBookNum, selectedChapter) async {
    var dbAccount = await db;
    final List<Map<String, Object?>> queryResult = await dbAccount!.rawQuery(
        "SELECT * From verse WHERE book_num ='${int.parse(selectedBookNum)}' AND chapter_num = '${int.parse(selectedChapter) - 1}'");
    return queryResult.map((e) => VerseBookContentModel.fromJson(e)).toList();
  }
}

// class DBMigrationHelper {
//   static const _unencryptedDbName = 'bible.db';
//   static const _encryptedDbName = '.bible.db';
//   static const _newDbName = 'bible_enc.db'; // ✅ Target encrypted DB

//   static Future<String?> getSourceDbPath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final unencryptedPath = p.join(dir.path, _unencryptedDbName);
//     final encryptedPath = p.join(dir.path, _encryptedDbName);

//     if (await File(unencryptedPath).exists()) {
//       debugPrint("testapp Found unencrypted DB at: $unencryptedPath");
//       return unencryptedPath;
//     } else if (await File(encryptedPath).exists()) {
//       debugPrint("testapp Found encrypted DB at: $encryptedPath");
//       return encryptedPath;
//     }
//     return null;
//   }

//   static Future<String> getNewDbPath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return p.join(dir.path, _newDbName);
//   }

//   static Future<void> migrateToEncryptedDatabase(String password) async {
//     final sourceDbPath = await getSourceDbPath();
//     final newDbPath = await getNewDbPath();

//     if (await File(newDbPath).exists()) {
//       //debugPrint('testapp New encrypted DB already exists at $newDbPath');
//       return;
//     }

//     if (sourceDbPath == null || !await File(sourceDbPath).exists()) {
//       debugPrint('testapp No source DB found for migration.');
//       return;
//     }

//     // await EasyLoading.showInfo('Please wait... Updating database...');

//     final isUnencrypted = sourceDbPath.endsWith(_unencryptedDbName);

//     // // Step 1: Open source DB (plain or encrypted)
//     // final oldDb = isUnencrypted
//     //     ? await plain.openDatabase(sourceDbPath)
//     //     : await sqlcipher.openDatabase(sourceDbPath, password: password);

//     // // Step 2: Open new encrypted DB
//     // final newDb = await sqlcipher.openDatabase(
//     //   newDbPath,
//     //   password: password,
//     //   version: 3,
//     //   onCreate: (db, version) async {
//     //     await _createTables(db); // replicate schema
//     //   },
//     // );

//     // // Step 3: Copy tables and data
//     // final tables = await oldDb.rawQuery(
//     //     "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

//     // for (final tableMap in tables) {
//     //   final tableName = tableMap['name'] as String;
//     //   final rows = await oldDb.query(tableName);
//     //   for (final row in rows) {
//     //     try {
//     //       await newDb.insert(tableName, row);
//     //     } catch (e) {
//     //       debugPrint("testapp Error inserting into $tableName: $e");
//     //     }
//     //   }
//     // }

//     // Step 1: Open source DB (plain or encrypted)
//     late Database oldDb;
//     try {
//       oldDb = isUnencrypted
//           ? await plain.openDatabase(sourceDbPath)
//           : await sqlcipher.openDatabase(sourceDbPath, password: password);
//     } catch (e) {
//       debugPrint('Error opening source DB: $e');
//       return;
//     }

//     // Step 2: Create & open encrypted target DB
//     late Database newDb;
//     try {
//       newDb = await sqlcipher.openDatabase(
//         newDbPath,
//         password: password,
//         version: 3,
//         onCreate: (db, version) async {
//           await _createTables(db); // Ensure schema
//         },
//       );
//     } catch (e) {
//       debugPrint('Error creating encrypted DB: $e');
//       return;
//     }

//     // Step 3: Copy all tables
//     try {
//       final tables = await oldDb.rawQuery(
//           "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

//       for (final tableMap in tables) {
//         final tableName = tableMap['name'] as String;
//         final rows = await oldDb.query(tableName);
//         for (final row in rows) {
//           try {
//             await newDb.insert(tableName, row);
//           } catch (e) {
//             debugPrint("Insert error in '$tableName': $e");
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error during table migration: $e');
//     }

//     try {
//       final String dailyVerseResponse =
//           await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
//       final dailyVerseData = json.decode(dailyVerseResponse);

//       final dailyVerseDataList = List.from(dailyVerseData)
//           .map<DailyVersesMainListModel>(
//               (item) => DailyVersesMainListModel.fromJson(item))
//           .toList();

//       await newDb.transaction((txn) async {
//         await txn.delete('dailyVersesMainList');
//         final batch = txn.batch();

//         for (final item in dailyVerseDataList) {
//           final insertData = {
//             "Category_Name": item.mainCategory,
//             "Category_Id": item.categoryId,
//             "Book": item.book,
//             "Book_Id": item.bookId,
//             "Chapter": item.chapter,
//             "Verse": item.verse,
//           };
//           batch.insert('dailyVersesMainList', insertData);
//         }

//         final isUpload = await batch.commit();

//         if (isUpload.isNotEmpty) {
//           debugPrint("testapp dailyVersesMainList inserted successfully.");
//         }
//       });
//     } catch (e) {
//       debugPrint("testapp Error loading daily verses JSON: $e");
//     }

//     await oldDb.close();
//     await newDb.close();
//     // await EasyLoading.dismiss();

//     // try {
//     //   final dir = await getApplicationDocumentsDirectory();
//     //   final oldDbFile = File(p.join(dir.path, 'bible.db'));
//     //   if (await oldDbFile.exists()) {
//     //     await oldDbFile.delete();
//     //     debugPrint('Deleted old unencrypted DB: bible.db');
//     //   }

//     //   final dotDbFile = File(p.join(dir.path, '.bible.db'));
//     //   if (await dotDbFile.exists()) {
//     //     await dotDbFile.delete();
//     //     debugPrint('Deleted old encrypted DB: .bible.db');
//     //   }
//     // } catch (e) {
//     //   debugPrint('Error deleting old DB files: $e');
//     // }

//     debugPrint("testapp Migration to $newDbPath complete.");
//   }

class DBMigrationHelper {
  static const _unencryptedDbName = 'bible.db';
  static const _legacyEncryptedName = '.bible.db';
  static const _encryptedDbName = 'bible2.db';
  static const _newDbName = 'bible_enc.db';

  /// Per-table map: old column name -> new column name.
  /// bookmark uses plaincontent; highlight uses plain_content.
  static final Map<String, Map<String, String>> _columnMapForTable = {
    'bookmark': {
      'plain_content': 'plaincontent',
      'book_name': 'bookName',
    },
    'highlight': {
      'plaincontent': 'plain_content',
      'bookName': 'book_name',
      'verseid': 'verse_id',
    },
    'underline': {
      'plain_content': 'plaincontent',
      'book_name': 'bookName',
    },
    'save_notes': {
      'bookName': 'book_name',
      'plain_content': 'plaincontent',
    },
  };

  /// Rename legacy `.bible.db` → `bible2.db`
  static Future<void> _renameLegacyEncryptedIfAny() async {
    final dir = await getApplicationDocumentsDirectory();
    final legacyPath = p.join(dir.path, _legacyEncryptedName);
    final newNamePath = p.join(dir.path, _encryptedDbName);

    if (await File(legacyPath).exists()) {
      try {
        if (await File(newNamePath).exists()) {
          await File(legacyPath).delete();
          debugPrint(
              "testapp Removed legacy $_legacyEncryptedName (target exists).");
        } else {
          await File(legacyPath).rename(newNamePath);
          debugPrint(
              "testapp Renamed $_legacyEncryptedName → $_encryptedDbName");
        }
      } catch (e) {
        debugPrint("testapp Rename error for $_legacyEncryptedName: $e");
      }
    }
  }

  static Future<bool> _isDatabaseEncrypted(String path) async {
    try {
      final db = await plain.openDatabase(path);
      await db.rawQuery("SELECT name FROM sqlite_master LIMIT 1");
      await db.close();
      debugPrint("testapp DB at $path is UNENCRYPTED.");
      return false;
    } catch (_) {
      debugPrint("testapp DB at $path is ENCRYPTED or not plain.");
      return true;
    }
  }

  static Future<String?> getSourceDbPath() async {
    await _renameLegacyEncryptedIfAny();

    final dir = await getApplicationDocumentsDirectory();
    final unencryptedPath = p.join(dir.path, _unencryptedDbName);
    final maybeEncryptedPath = p.join(dir.path, _encryptedDbName);

    if (await File(unencryptedPath).exists()) {
      debugPrint("testapp Found plain DB at: $unencryptedPath");
      return unencryptedPath;
    }
    if (await File(maybeEncryptedPath).exists()) {
      debugPrint("testapp Found DB at: $maybeEncryptedPath");
      return maybeEncryptedPath;
    }
    return null;
  }

  static Future<String> getNewDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _newDbName);
  }

  static Future<bool> _targetDbHasCoreData(
      String targetPath, String password) async {
    try {
      final db = await sqlcipher.openDatabase(targetPath, password: password);
      final verseCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM verse");
      final bookCountRows = await db.rawQuery("SELECT COUNT(*) as c FROM book");
      final verseCount =
          verseCountRows.isNotEmpty ? (verseCountRows.first["c"] as int?) ?? 0 : 0;
      final bookCount =
          bookCountRows.isNotEmpty ? (bookCountRows.first["c"] as int?) ?? 0 : 0;
      await db.close();
      return verseCount > 0 && bookCount > 0;
    } catch (e) {
      debugPrint("testapp Target DB core-data check failed: $e");
      return false;
    }
  }

  /// IMPORTANT: don't delete existing user data.
  /// Some users may already have bookmarks/highlights/notes even when
  /// verse/book tables are empty at migration time.
  static Future<bool> _targetDbHasLibraryData(
      String targetPath, String password) async {
    try {
      final db = await sqlcipher.openDatabase(targetPath, password: password);

      Future<int> countFrom(String table) async {
        try {
          final rows = await db.rawQuery("SELECT COUNT(*) as c FROM $table");
          return (rows.isNotEmpty ? (rows.first['c'] as int?) : null) ?? 0;
        } catch (_) {
          // Table may not exist in very old/corrupt DBs.
          return 0;
        }
      }

      final bookmarkCount = await countFrom('bookmark');
      final highlightCount = await countFrom('highlight');
      final underlineCount = await countFrom('underline');
      final notesCount = await countFrom('save_notes');

      await db.close();
      return bookmarkCount > 0 ||
          highlightCount > 0 ||
          underlineCount > 0 ||
          notesCount > 0;
    } catch (e) {
      debugPrint("testapp Target DB library-data check failed: $e");
      return false;
    }
  }

  /// Get columns from target table
  static Future<List<String>> _getTableColumns(
      sqlcipher.Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.map((row) => row['name'] as String).toList();
  }

  /// Filter + map old row to target schema (table-specific column names)
  static Map<String, Object?> _mapAndFilterRow(
      String tableName, Map<String, Object?> oldRow, List<String> targetColumns) {
    final tableMap = _columnMapForTable[tableName];
    final Map<String, Object?> mapped = {};
    oldRow.forEach((oldCol, value) {
      final newCol = (tableMap != null && tableMap.containsKey(oldCol))
          ? tableMap[oldCol]!
          : oldCol;
      if (targetColumns.contains(newCol)) {
        mapped[newCol] = value;
      }
    });
    return mapped;
  }

  static Future<void> migrateToEncryptedDatabase(String password) async {
    final sourceDbPath = await getSourceDbPath();
    final newDbPath = await getNewDbPath();

    if (await File(newDbPath).exists()) {
      // IMPORTANT for upgrade users:
      // Don't skip migration if the target DB exists but is empty/corrupt.
      final hasCore = await _targetDbHasCoreData(newDbPath, password);
      final hasLibrary = await _targetDbHasLibraryData(newDbPath, password);

      // If core data OR any user library data exists, preserve the DB.
      if (hasCore || hasLibrary) {
        debugPrint(
            'testapp Target encrypted DB exists (core:${hasCore ? 1 : 0}, library:${hasLibrary ? 1 : 0}). Skipping migration.');
        return;
      }

      try {
        // Backup before delete, so field devices can recover.
        final backupPath =
            '$newDbPath.bak.${DateTime.now().millisecondsSinceEpoch}';
        await File(newDbPath).copy(backupPath);
        debugPrint('testapp Backed up empty/corrupt target DB to $backupPath');

        await File(newDbPath).delete();
        debugPrint('testapp Target encrypted DB existed but had no data. Re-migrating.');
      } catch (e) {
        debugPrint('testapp Failed to delete empty target DB: $e');
        // If we can't delete it, we can't safely re-migrate.
        return;
      }
    }
    if (sourceDbPath == null || !await File(sourceDbPath).exists()) {
      debugPrint('testapp No source DB found.');
      return;
    }

    final looksEncrypted = !sourceDbPath.endsWith(_unencryptedDbName)
        ? await _isDatabaseEncrypted(sourceDbPath)
        : false;

    // Open old DB
    dynamic oldDb;
    try {
      oldDb = looksEncrypted
          ? await sqlcipher.openDatabase(sourceDbPath, password: password)
          : await plain.openDatabase(sourceDbPath);
    } catch (e) {
      debugPrint('testapp Error opening source DB: $e');
      return;
    }

    // Create new encrypted DB
    sqlcipher.Database? newDb;
    try {
      newDb = await sqlcipher.openDatabase(
        newDbPath,
        password: password,
        version: 3,
        onCreate: (db, version) async {
          await _createTables(db);
        },
      );
    } catch (e) {
      debugPrint('testapp Error creating new DB: $e');
      await oldDb?.close();
      return;
    }

    /// Map legacy table names to current schema (so e.g. bookmarks -> bookmark).
    final Map<String, String> legacyTableToTarget = {
      'bookmarks': 'bookmark',
      'book_mark': 'bookmark',
      'bookMark': 'bookmark',
      'highlights': 'highlight',
      'high_light': 'highlight',
      'highLight': 'highlight',
      'underlines': 'underline',
      'under_line': 'underline',
      'underLine': 'underline',
      'notes': 'save_notes',
      'note': 'save_notes',
      'saved_notes': 'save_notes',
      'saveNotes': 'save_notes',
      'calender': 'calendar',
      'images': 'save_images',
      'saved_images': 'save_images',
      'saveImages': 'save_images',
      'daily_verses_main_list': 'dailyVersesMainList',
    };

    // Copy tables
    try {
      final tables = await oldDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      for (final tableMap in tables) {
        final legacyTableName = tableMap['name'] as String;
        if (legacyTableName == 'android_metadata') continue;

        final targetTableName =
            legacyTableToTarget[legacyTableName] ?? legacyTableName;

        List<String> targetColumns;
        try {
          targetColumns = await _getTableColumns(newDb, targetTableName);
        } catch (_) {
          debugPrint("testapp Migration: no target table '$targetTableName', skip.");
          continue;
        }
        if (targetColumns.isEmpty) continue;

        final rows = await oldDb.query(legacyTableName);
        for (final row in rows) {
          final mappedRow =
              _mapAndFilterRow(targetTableName, row, targetColumns);
          try {
            if (mappedRow.isNotEmpty) {
              await newDb.insert(targetTableName, mappedRow,
                  conflictAlgorithm: sqlcipher.ConflictAlgorithm.ignore);
            }
          } catch (e) {
            debugPrint("testapp Insert error in '$targetTableName': $e");
          }
        }
        if (rows.isNotEmpty) {
          debugPrint("testapp Migration: copied ${rows.length} rows $legacyTableName -> $targetTableName");
        }
      }

      try {
        final String dailyVerseResponse =
            await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
        final dailyVerseData = json.decode(dailyVerseResponse) as List;
        final dailyVerseDataList = dailyVerseData
            .map<DailyVersesMainListModel>(
                (item) => DailyVersesMainListModel.fromJson(
                    Map<String, dynamic>.from(item as Map)))
            .toList();
        if (dailyVerseDataList.isEmpty) {
          debugPrint("testapp dailyVerse.json empty, keeping migrated data.");
        } else {
          await newDb.transaction((txn) async {
            await txn.delete('dailyVersesMainList');
            final batch = txn.batch();
            for (final item in dailyVerseDataList) {
              batch.insert('dailyVersesMainList', {
                "Category_Name": item.mainCategory ?? item.categoryName ?? '',
                "Category_Id": item.categoryId,
                "Book": item.book,
                "Book_Id": item.bookId,
                "Chapter": item.chapter,
                "Verse": item.verse?.toString() ?? '',
              });
            }
            await batch.commit();
            debugPrint("testapp dailyVersesMainList inserted successfully.");
          });
        }
      } catch (e) {
        debugPrint("testapp Error loading daily verses JSON: $e (keeping migrated data)");
      }

      debugPrint("testapp ✅ Migration finished successfully.");
    } catch (e) {
      debugPrint('testapp Migration error: $e');
    } finally {
      await oldDb?.close();
      await newDb.close();
    }
  }

  /// User-data and config tables to preserve on upgrade
  static const List<String> _userDataTables = [
    'bookmark',
    'highlight',
    'underline',
    'save_notes',
    'calendar',
    'save_images',
    'dailyVersesMainList',
  ];

  /// Call from Library screens when data is empty to retry copying from legacy DB.
  static Future<void> tryRestoreLibraryDataFromLegacy() async {
    final password = dotenv.env[AssetsConstants.dbPasswordKey];
    if (password == null || password.isEmpty) return;
    await copyUserDataFromLegacyIfNeeded(password);
  }

  /// If legacy DB still exists and current DB has no user data, copy it over.
  /// Call after migration and before deleting legacy DB files.
  static Future<void> copyUserDataFromLegacyIfNeeded(String password) async {
    final sourceDbPath = await getSourceDbPath();
    if (sourceDbPath == null || !await File(sourceDbPath).exists()) return;

    final newDbPath = await getNewDbPath();
    if (!await File(newDbPath).exists()) return;

    final looksEncrypted = !sourceDbPath.endsWith(_unencryptedDbName)
        ? await _isDatabaseEncrypted(sourceDbPath)
        : false;

    dynamic legacyDb;
    try {
      legacyDb = looksEncrypted
          ? await sqlcipher.openDatabase(sourceDbPath, password: password)
          : await plain.openDatabase(sourceDbPath);
    } catch (e) {
      debugPrint('testapp copyUserData: could not open legacy DB: $e');
      return;
    }

    sqlcipher.Database? newDb;
    try {
      newDb = await sqlcipher.openDatabase(
        newDbPath,
        password: password,
      );
    } catch (e) {
      debugPrint('testapp copyUserData: could not open new DB: $e');
      await legacyDb?.close();
      return;
    }

    try {
      Future<bool> legacyHasTable(String name) async {
        try {
          final res = await legacyDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            [name],
          );
          return res.isNotEmpty;
        } catch (_) {
          return false;
        }
      }

      Future<String?> pickLegacyTable(List<String> candidates) async {
        for (final t in candidates) {
          if (await legacyHasTable(t)) return t;
        }
        return null;
      }

      final Map<String, List<String>> legacyCandidatesForTarget = {
        'bookmark': ['bookmark', 'bookmarks', 'book_mark', 'bookMark'],
        'highlight': ['highlight', 'highlights', 'high_light', 'highLight'],
        'underline': ['underline', 'underlines', 'under_line', 'underLine'],
        'save_notes': ['save_notes', 'notes', 'note', 'saved_notes', 'saveNotes'],
        'calendar': ['calendar', 'calender'],
        'save_images': ['save_images', 'images', 'saved_images', 'saveImages'],
        'dailyVersesMainList': ['dailyVersesMainList', 'daily_verses_main_list'],
      };

      for (final tableName in _userDataTables) {
        try {
          final newCountRows =
              await newDb.rawQuery("SELECT COUNT(*) as c FROM $tableName");
          final newCount =
              (newCountRows.isNotEmpty ? (newCountRows.first['c'] as int?) : 0) ?? 0;
          if (newCount > 0) continue;

          final legacyTable = await pickLegacyTable(
            legacyCandidatesForTarget[tableName] ?? [tableName],
          );
          if (legacyTable == null) continue;

          final rows = await legacyDb.query(legacyTable);
          if (rows.isEmpty) continue;

          final targetColumns = await _getTableColumns(newDb, tableName);
          for (final row in rows) {
            final mappedRow =
                _mapAndFilterRow(tableName, row, targetColumns);
            mappedRow.remove('id');
            if (mappedRow.isEmpty) continue;
            try {
              await newDb.insert(tableName, mappedRow,
                  conflictAlgorithm: sqlcipher.ConflictAlgorithm.ignore);
            } catch (e) {
              debugPrint("testapp copyUserData insert '$tableName': $e");
            }
          }
          debugPrint(
              'testapp copyUserData: copied ${rows.length} rows from $legacyTable into $tableName');
        } catch (e) {
          debugPrint('testapp copyUserData table $tableName: $e');
        }
      }
    } finally {
      await legacyDb?.close();
      await newDb.close();
    }
  }

  static Future<void> _createTables(sqlcipher.Database db) async {
    try {
      await db.execute(
          'CREATE TABLE "calendar" (id INTEGER PRIMARY KEY AUTOINCREMENT,"title" TEXT,"date" DATETIME)');
      await db.execute(
          'CREATE TABLE "verse" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER,"content" TEXT,"is_read" TEXT,"is_bookmarked" TEXT,"is_underlined" TEXT,"is_highlighted" TEXT,"is_noted" TEXT)');
      await db.execute(
          'CREATE TABLE "bookmark" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR,"bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "save_notes" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR,"book_name" VARCHAR, "notes" VARCHAR, "plaincontent" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "highlight" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plain_content" VARCHAR, verse_id VARCHAR, "book_name" VARCHAR,"color" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "underline" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER, "chapter_num" INTEGER, "verse_num" INTEGER, "content" VARCHAR, "plaincontent" VARCHAR, "bookName" VARCHAR, "timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE "book" (id INTEGER PRIMARY KEY AUTOINCREMENT,"book_num" INTEGER,"title" TEXT,"short_title" TEXT,"chapter_count" INTEGER,"read_per" TEXT)');
      await db.execute(
          'CREATE TABLE "save_images" (id INTEGER PRIMARY KEY AUTOINCREMENT,"image_path" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVersesMainList" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT)');
      await db.execute(
          'CREATE TABLE "dailyVerses" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
      await db.execute(
          'CREATE TABLE "dailyVersesnew" (id INTEGER PRIMARY KEY AUTOINCREMENT,"Category_Name" TEXT,"Category_Id" INTEGER,"Book" TEXT,"Book_Id" INTEGER,"Chapter" INTEGER, "Verse" TEXT,"Date" TEXT,"Verse_Num" INTEGER )');
    } catch (e) {
      debugPrint("testapp Error creating tables: $e");
    }
  }
}
