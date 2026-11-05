import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local "My Digital Library" for BookAds products the user has unlocked.
class DigitalProductsLibraryStore {
  static const _key = 'digital_products_library_v1';

  static Future<List<OwnedDigitalProduct>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              OwnedDigitalProduct.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isOwned(String bookId) async {
    final items = await load();
    return items.any((e) => e.book.bookId == bookId);
  }

  static Future<void> add(BookModel book) async {
    if (book.bookId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final items = await load();
    if (items.any((e) => e.book.bookId == book.bookId)) return;
    items.insert(
      0,
      OwnedDigitalProduct(book: book, purchasedAt: DateTime.now()),
    );
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Folder for [bookId] inside the app's "Digital Products" folder. Resolved
  /// each time because the iOS app container path can change between launches.
  static Future<Directory> _dirFor(String bookId) async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/Digital Products/$bookId');
  }

  /// Where [book] is saved when downloaded (file name = book name).
  static Future<File> fileFor(BookModel book) async {
    final dir = await _dirFor(book.bookId);
    var name = book.bookName
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty) name = book.bookId;
    return File('${dir.path}/$name.pdf');
  }

  /// The downloaded file for [bookId], or null if not downloaded yet.
  static Future<File?> downloadedFile(String bookId) async {
    final dir = await _dirFor(bookId);
    if (!await dir.exists()) return null;
    await for (final e in dir.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.pdf')) return e;
    }
    return null;
  }
}

class OwnedDigitalProduct {
  OwnedDigitalProduct({required this.book, required this.purchasedAt});

  final BookModel book;
  final DateTime purchasedAt;

  factory OwnedDigitalProduct.fromJson(Map<String, dynamic> json) {
    return OwnedDigitalProduct(
      book: BookModel.fromJson(
          Map<String, dynamic>.from(json['book'] as Map? ?? {})),
      purchasedAt: DateTime.tryParse(json['purchasedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'book': book.toJson(),
        'purchasedAt': purchasedAt.toIso8601String(),
      };
}
