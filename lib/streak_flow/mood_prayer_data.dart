import 'dart:convert';
import 'package:flutter/services.dart';

/// One entry from assets/mood_prayer.json (Verse, Devotional, Prayer for a connection level).
class MoodPrayerItem {
  MoodPrayerItem({
    required this.connectionLevel,
    required this.bookName,
    required this.bookNumber,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    required this.devotionalText,
    required this.prayerText,
  });

  final int connectionLevel;
  final String bookName;
  final int bookNumber;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final String devotionalText;
  final String prayerText;

  String get verseReference => '$bookName $chapterNumber:$verseNumber';

  static MoodPrayerItem fromJson(Map<String, dynamic> json) {
    return MoodPrayerItem(
      connectionLevel: (json['Connection_Level'] as num?)?.toInt() ?? 20,
      bookName: json['Book_Name'] as String? ?? '',
      bookNumber: (json['Book_Number'] as num?)?.toInt() ?? 0,
      chapterNumber: (json['Chapter_Number'] as num?)?.toInt() ?? 0,
      verseNumber: (json['Verse_Number'] as num?)?.toInt() ?? 0,
      verseText: json['Verse_Text'] as String? ?? '',
      devotionalText: json['Devotional_Text'] as String? ?? '',
      prayerText: (json['Prayer_Text'] as String? ?? '').replaceAll('\\n', '\n'),
    );
  }
}

/// Loads mood_prayer.json and picks an item (e.g. by connection index or random).
class MoodPrayerLoader {
  static List<MoodPrayerItem>? _cache;

  static Future<List<MoodPrayerItem>> load() async {
    if (_cache != null) return _cache!;
    final str = await rootBundle.loadString('assets/mood_prayer.json');
    final list = jsonDecode(str) as List<dynamic>;
    _cache = list.map((e) => MoodPrayerItem.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  /// Pick one item. connectionIndex 0=Far, 1=Near, 2=Deeply Connected. Uses segment of list or random.
  static Future<MoodPrayerItem?> pickItem({int connectionIndex = 1}) async {
    final list = await load();
    if (list.isEmpty) return null;
    final segment = (list.length / 3).floor();
    final start = (connectionIndex * segment).clamp(0, list.length - 1);
    final end = ((connectionIndex + 1) * segment).clamp(0, list.length);
    final sub = list.sublist(start, end);
    if (sub.isEmpty) return list[list.length ~/ 2];
    return sub[DateTime.now().millisecondsSinceEpoch % sub.length];
  }
}
