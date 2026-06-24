import 'package:biblebookapp/Model/dailyVersesMainListModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;

class VerseTopicVerse {
  const VerseTopicVerse({
    required this.reference,
    required this.contentHtml,
    required this.plainText,
    required this.bookName,
    required this.bookNum,
    required this.chapterNum,
    required this.verseNum,
  });

  final String reference;
  final String contentHtml;
  final String plainText;
  final String bookName;
  final int bookNum;
  final int chapterNum;
  final int verseNum;
}

class VerseTopicsData {
  static const String backgroundAsset = 'assets/verse-topics-bg.png';

  static Future<List<String>> loadCategories() async {
    final icons = await _loadCategoryIcons();
    final names = icons.keys.toList()..sort();
    return names;
  }

  static Future<Map<String, String>> _loadCategoryIcons() async {
    Map<String, String> categoryIcons = {};

    try {
      final dbClient = await DBHelper().db;
      List<Map<String, dynamic>>? raw =
          await dbClient?.rawQuery('SELECT * FROM dailyVersesMainList');
      var dailyVersesMainData = raw ?? [];

      if (dailyVersesMainData.isEmpty) {
        await _seedDailyVersesMainListFromJson();
        final dbAfter = await DBHelper().db;
        raw = await dbAfter?.rawQuery('SELECT * FROM dailyVersesMainList');
        dailyVersesMainData = raw ?? [];
      }

      for (final item in dailyVersesMainData) {
        final categoryName = _categoryNameFromRow(item);
        if (categoryName != null && categoryName.isNotEmpty) {
          categoryIcons[categoryName] = categoryName;
        }
      }

      if (categoryIcons.isEmpty) {
        final jsonString =
            await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
        categoryIcons = await compute(
          preferenceSelectionCategoryMapFromJsonString,
          jsonString,
        );
      }
    } catch (e, st) {
      debugPrint('VerseTopicsData loadCategories: $e\n$st');
      try {
        final jsonString =
            await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
        categoryIcons = await compute(
          preferenceSelectionCategoryMapFromJsonString,
          jsonString,
        );
      } catch (e2) {
        debugPrint('VerseTopicsData asset fallback failed: $e2');
      }
    }

    return categoryIcons;
  }

  static String? _categoryNameFromRow(Map<String, dynamic> row) {
    for (final e in row.entries) {
      if (e.key.toLowerCase() == 'category_name') {
        final v = e.value?.toString();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static Future<void> _seedDailyVersesMainListFromJson() async {
    try {
      final db = await DBHelper().db;
      if (db == null) return;
      final String jsonString =
          await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
      final List<DailyVersesMainListModel> dataList = await compute(
        preferenceSelectionParseDailyVerseModels,
        jsonString,
      );
      if (dataList.isEmpty) return;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final item in dataList) {
          batch.insert('dailyVersesMainList', {
            'Category_Name': item.mainCategory ?? item.categoryName ?? '',
            'Category_Id': item.categoryId,
            'Book': item.book,
            'Book_Id': item.bookId,
            'Chapter': item.chapter,
            'Verse': item.verse?.toString() ?? '',
          });
        }
        await batch.commit();
      });
    } catch (e) {
      debugPrint('VerseTopicsData seed error: $e');
    }
  }

  static Future<List<VerseTopicVerse>> loadVersesForCategory(
    String categoryName,
  ) async {
    final db = await DBHelper().db;
    if (db == null) return [];

    var rows = await db.rawQuery(
      'SELECT * FROM dailyVersesMainList WHERE Category_Name = ?',
      [categoryName],
    );

    if (rows.isEmpty) {
      await _seedDailyVersesMainListFromJson();
      rows = await db.rawQuery(
        'SELECT * FROM dailyVersesMainList WHERE Category_Name = ?',
        [categoryName],
      );
    }

    final verses = <VerseTopicVerse>[];
    final seen = <String>{};

    for (final row in rows) {
      final bookId = int.tryParse(row['Book_Id']?.toString() ?? '') ?? 0;
      final chapterStored = int.tryParse(row['Chapter']?.toString() ?? '') ?? 0;
      final verseRaw = row['Verse']?.toString() ?? '';
      if (bookId <= 0 || chapterStored <= 0 || verseRaw.isEmpty) continue;

      final verseStored = verseRaw.length == 2
          ? int.parse(verseRaw) - 1
          : int.parse(verseRaw.split('-').first) - 1;

      final selectedVerse = await db.rawQuery(
        "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
        [bookId - 1, chapterStored - 1, verseStored],
      );
      if (selectedVerse.isEmpty) continue;

      final contentHtml = selectedVerse.first['content']?.toString() ?? '';
      final plainText = html.parse(contentHtml).body?.text ?? '';
      if (plainText.trim().isEmpty) continue;

      final bookData = await db.rawQuery(
        'SELECT DISTINCT title FROM book WHERE book_num = ? LIMIT 1',
        [bookId - 1],
      );
      final bookName = bookData.isNotEmpty
          ? bookData.first['title']?.toString() ?? row['Book']?.toString() ?? ''
          : row['Book']?.toString() ?? '';

      final displayChapter = chapterStored;
      final displayVerse = verseStored + 1;
      final reference = '$bookName $displayChapter:$displayVerse';
      final dedupeKey = '$bookId-$chapterStored-$verseRaw';
      if (seen.contains(dedupeKey)) continue;
      seen.add(dedupeKey);

      verses.add(
        VerseTopicVerse(
          reference: reference,
          contentHtml: contentHtml,
          plainText: plainText,
          bookName: bookName,
          bookNum: bookId - 1,
          chapterNum: chapterStored - 1,
          verseNum: verseStored,
        ),
      );
    }

    return verses;
  }

  static String iconPathForCategory(String categoryName) {
    return 'assets/lightMode/icons/$categoryName.png';
  }

  static String subtitleForCategory(String categoryName) {
    return 'Verses about ${categoryName.toLowerCase()} to inspire your journey.';
  }
}
