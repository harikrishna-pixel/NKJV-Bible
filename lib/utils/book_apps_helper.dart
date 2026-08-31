import 'dart:convert';
import 'dart:math';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/more_apps/model/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const _key = 'books_and_apps';

  // static Future<void> saveBooksAndApps(
  //     {List<BookModel>? books, List<AppModel>? apps}) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final storage = StorageModel(books: books, apps: apps);
  //   final jsonStr = jsonEncode(storage.toJson());
  //   await prefs.setString(_key, jsonStr);
  // }

  // static Future<StorageModel?> loadBooksAndApps() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonStr = prefs.getString(_key);
  //   if (jsonStr == null) return null;
  //   return StorageModel.fromJson(jsonDecode(jsonStr));
  // }

  // static Future<dynamic> getRandomBookOrApp() async {
  //   final storage = await loadBooksAndApps();
  //   if (storage == null) return null;

  //   final allItems = [...?storage.books, ...?storage.apps];
  //   if (allItems.isEmpty) return null;

  //   final randomIndex = Random().nextInt(allItems.length);
  //   return allItems[randomIndex]; // BookModel or AppModel
  // }
  static Future<void> saveBooksAndApps(
      {List<BookModel>? books, List<AppModel>? apps}) async {
    // // ✅ Null check
    // if ((books == null || books.isEmpty) && (apps == null || apps.isEmpty)) {
    //   return;
    // }

    final prefs = await SharedPreferences.getInstance();

    // Load old data to avoid duplicate saves
    final oldJson = prefs.getString(_key);

    final storage = StorageModel(
      books: books ?? [],
      apps: apps ?? [],
    );
    final newJson = jsonEncode(storage.toJson());

    // ✅ Save only if changed
    if (oldJson != newJson) {
      await prefs.setString(_key, newJson);
    }
  }

  static Future<StorageModel?> loadBooksAndApps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    return StorageModel.fromJson(jsonDecode(jsonStr));
  }

  static Future<dynamic> getRandomBookOrApp() async {
    final storage = await loadBooksAndApps();
    if (storage == null) return null;

    final allItems = [...?storage.books, ...?storage.apps];
    if (allItems.isEmpty) return null;

    final randomIndex = Random().nextInt(allItems.length);
    return allItems[randomIndex]; // BookModel or AppModel
  }
}

class StorageModel {
  final List<BookModel>? books;
  final List<AppModel>? apps;

  StorageModel({
    this.books,
    this.apps,
  });

  factory StorageModel.fromJson(Map<String, dynamic> json) {
    return StorageModel(
      books: (json['books'] as List).map((e) => BookModel.fromJson(e)).toList(),
      apps: (json['apps'] as List).map((e) => AppModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'books': books?.map((e) => e.toJson()).toList(),
      'apps': apps?.map((e) => e.toJson()).toList(),
    };
  }
}
