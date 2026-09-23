import 'dart:convert';

import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:intl/intl.dart';

/// Recent Activity for Reading Progress.
///
/// Triggered only after existing Mark as Read persist — not on chapter open.
/// Upserts by book + chapter so the same chapter is not listed twice.
class ReadingActivity {
  ReadingActivity({
    required this.bookName,
    required this.chapter,
    required this.bookNum,
    required this.at,
    this.inferred = false,
  });

  final String bookName;
  final int chapter;
  final int bookNum;
  final DateTime at;
  final bool inferred;

  String get title => 'Read $bookName $chapter';

  /// Display-only: newest real completion first. Does not change save/upsert.
  static int compareNewestCompletedFirst(ReadingActivity a, ReadingActivity b) {
    if (a.inferred != b.inferred) return a.inferred ? 1 : -1;
    final now = DateTime.now();
    DateTime key(ReadingActivity item) =>
        item.at.isAfter(now) ? DateTime.fromMillisecondsSinceEpoch(0) : item.at;
    final byTime = key(b).compareTo(key(a));
    if (byTime != 0) return byTime;
    return b.at.compareTo(a.at);
  }

  String get whenLabel => whenLabelFor();

  /// Display-only. "Already completed" only when that book is fully read.
  String whenLabelFor({bool bookFullyRead = false}) {
    if (inferred) {
      return bookFullyRead ? 'Already completed' : 'Previously read';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final time = DateFormat('h:mm a').format(at);
    if (day == today) return 'Today, $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return DateFormat('MMM d, yyyy').format(at);
  }

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'bookNum': bookNum,
        'at': at.toIso8601String(),
        'inferred': inferred,
      };

  static ReadingActivity? fromJson(Map<String, dynamic> json) {
    final book = (json['bookName'] ?? '').toString().trim();
    final chapter = (json['chapter'] as num?)?.toInt() ?? 0;
    final atRaw = json['at']?.toString();
    if (book.isEmpty || chapter <= 0 || atRaw == null) return null;
    final at = DateTime.tryParse(atRaw);
    if (at == null) return null;
    return ReadingActivity(
      bookName: book,
      chapter: chapter,
      bookNum: (json['bookNum'] as num?)?.toInt() ?? 0,
      at: at,
      inferred: json['inferred'] == true || at.year <= 2001,
    );
  }
}

class ReadingActivityService {
  ReadingActivityService._();

  static const _maxItems = 50;

  static String _keyFor(int bookNum, String bookName, int chapter) {
    if (bookNum > 0) return '$bookNum:$chapter';
    return '${bookName.toLowerCase()}:$chapter';
  }

  static Future<List<ReadingActivity>> loadAll() async {
    final raw =
        await SharPreferences.getString(SharPreferences.readingRecentActivity);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = <ReadingActivity>[];
      for (final row in decoded) {
        if (row is Map) {
          final item =
              ReadingActivity.fromJson(Map<String, dynamic>.from(row));
          if (item != null) items.add(item);
        }
      }
      items.sort((a, b) => b.at.compareTo(a.at));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Call after existing Mark as Read persist. Same chapter updates time only.
  static Future<void> recordChapterRead({
    required String bookName,
    required int chapter,
    int bookNum = 0,
  }) async {
    final name = bookName.trim();
    if (name.isEmpty || chapter <= 0) return;

    final now = DateTime.now();
    final key = _keyFor(bookNum, name, chapter);
    final existing = await loadAll();
    existing.removeWhere(
      (item) => _keyFor(item.bookNum, item.bookName, item.chapter) == key,
    );
    existing.insert(
      0,
      ReadingActivity(
        bookName: name,
        chapter: chapter,
        bookNum: bookNum,
        at: now,
      ),
    );
    if (existing.length > _maxItems) {
      existing.removeRange(_maxItems, existing.length);
    }
    await SharPreferences.setString(
      SharPreferences.readingRecentActivity,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  /// Additive hook after [DashBoardController.persistMarkChapterReadProgress].
  static Future<void> recordFromController(DashBoardController controller) {
    final book = controller.selectedBook.value.trim();
    final chapter =
        int.tryParse(controller.selectedChapter.value.trim()) ?? 0;
    final bookNum =
        int.tryParse(controller.selectedBookNum.value.trim()) ?? 0;
    return recordChapterRead(
      bookName: book,
      chapter: chapter,
      bookNum: bookNum,
    );
  }

  /// Fill Recent Activity from already-read chapters (existing users / update).
  /// Does not change is_read or read_per. Does not overwrite newer Mark as Read rows.
  static Future<List<ReadingActivity>> mergeExistingReads({
    required List<({int bookNum, int chapter, String bookName})> reads,
  }) async {
    if (reads.isEmpty) return loadAll();
    final existing = await loadAll();
    final keys = existing
        .map((e) => _keyFor(e.bookNum, e.bookName, e.chapter))
        .toSet();
    var added = 0;
    for (var i = 0; i < reads.length; i++) {
      final read = reads[i];
      if (read.chapter <= 0 || read.bookName.isEmpty) continue;
      final key = _keyFor(read.bookNum, read.bookName, read.chapter);
      if (keys.contains(key)) continue;
      existing.add(
        ReadingActivity(
          bookName: read.bookName,
          chapter: read.chapter,
          bookNum: read.bookNum,
          at: DateTime(2000, 1, 1).add(Duration(minutes: i)),
          inferred: true,
        ),
      );
      keys.add(key);
      added++;
    }
    if (added > 0) {
      existing.sort((a, b) {
        if (a.inferred != b.inferred) return a.inferred ? 1 : -1;
        return b.at.compareTo(a.at);
      });
      final trimmed = existing.length > _maxItems
          ? existing.take(_maxItems).toList()
          : existing;
      await SharPreferences.setString(
        SharPreferences.readingRecentActivity,
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
      return trimmed;
    }
    existing.sort((a, b) {
      if (a.inferred != b.inferred) return a.inferred ? 1 : -1;
      return b.at.compareTo(a.at);
    });
    return existing;
  }
}
