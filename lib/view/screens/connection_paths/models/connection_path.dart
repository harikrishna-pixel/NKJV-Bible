import 'package:flutter/material.dart';

/// One verse pointer from `connection_paths_en.json` (0-based indexes).
class PathVerseRef {
  const PathVerseRef({
    required this.bookNum,
    required this.bookName,
    required this.chapterNum,
    required this.verseNum,
  });

  final int bookNum;
  final String bookName;
  final int chapterNum;
  final int verseNum;

  factory PathVerseRef.fromJson(Map<String, dynamic> j) => PathVerseRef(
        bookNum: (j['book_num'] as num?)?.toInt() ?? 0,
        bookName: j['book_name']?.toString() ?? '',
        chapterNum: (j['chapter_num'] as num?)?.toInt() ?? 0,
        verseNum: (j['verse_num'] as num?)?.toInt() ?? 0,
      );
}

class PathDay {
  const PathDay({
    required this.dayIndex,
    required this.dayLabel,
    required this.title,
    required this.reference,
    required this.verses,
    required this.devotion,
    required this.reflection,
    required this.prayer,
    required this.completionMessage,
  });

  final int dayIndex;
  final String dayLabel;
  final String title;
  final String reference;
  final List<PathVerseRef> verses;
  final String devotion;
  final String reflection;
  final String prayer;
  final String completionMessage;

  /// Display label used by older screens.
  String get verseRef => reference;
  String get subtitle => reference;

  factory PathDay.fromJson(Map<String, dynamic> j) {
    final verses = ((j['verses'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => PathVerseRef.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return PathDay(
      dayIndex: (j['day_index'] as num?)?.toInt() ?? 0,
      dayLabel: j['day_label']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      reference: j['reference']?.toString() ?? '',
      verses: verses,
      devotion: j['devotion']?.toString() ?? '',
      reflection: j['reflection']?.toString() ?? '',
      prayer: j['prayer']?.toString() ?? '',
      completionMessage: j['completion_message']?.toString() ?? '',
    );
  }
}

class ConnectionPath {
  const ConnectionPath({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.categoryId,
    required this.coverAssetId,
    required this.durationDays,
    required this.dailyTime,
    required this.estimatedTimeMin,
    required this.estimatedTimeMax,
    required this.includes,
    required this.bestFor,
    required this.summaryReference,
    required this.summaryVerses,
    required this.completionMessage,
    required this.days,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String categoryId;
  final String coverAssetId;
  final int durationDays;
  final String dailyTime;
  final int estimatedTimeMin;
  final int estimatedTimeMax;
  final List<String> includes;
  final String bestFor;
  final String summaryReference;
  final List<PathVerseRef> summaryVerses;
  final String completionMessage;
  final List<PathDay> days;

  /// Aliases for older screens.
  String get tagline => subtitle;
  String get about => description;
  String get durationLabel => '$durationDays days';

  IconData get icon {
    switch (categoryId) {
      case 'prayer':
        return Icons.volunteer_activism_outlined;
      case 'faith':
        return Icons.shield_outlined;
      case 'peace':
        return Icons.spa_outlined;
      case 'gratitude':
        return Icons.favorite_border_rounded;
      case 'difficult-times':
        return Icons.waves_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  factory ConnectionPath.fromJson(Map<String, dynamic> j) {
    final summary = Map<String, dynamic>.from(
        (j['summary_verse'] as Map?) ?? const {});
    final summaryVerses = <PathVerseRef>[];
    if (summary.isNotEmpty) {
      final start = (summary['verse_start'] as num?)?.toInt();
      final end = (summary['verse_end'] as num?)?.toInt() ?? start;
      if (start != null && end != null) {
        for (var v = start; v <= end; v++) {
          summaryVerses.add(PathVerseRef(
            bookNum: (summary['book_num'] as num?)?.toInt() ?? 0,
            bookName: summary['book_name']?.toString() ?? '',
            chapterNum: (summary['chapter_num'] as num?)?.toInt() ?? 0,
            verseNum: v,
          ));
        }
      }
    }
    return ConnectionPath(
      id: j['plan_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      subtitle: j['subtitle']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      categoryId: j['category_id']?.toString() ?? '',
      coverAssetId: j['cover_asset_id']?.toString() ?? '',
      durationDays: (j['duration_days'] as num?)?.toInt() ?? 0,
      dailyTime: j['daily_time']?.toString() ?? '5–10 mins',
      estimatedTimeMin: (j['estimated_time_min'] as num?)?.toInt() ?? 5,
      estimatedTimeMax: (j['estimated_time_max'] as num?)?.toInt() ?? 10,
      includes: ((j['includes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      bestFor: j['best_for']?.toString() ?? '',
      summaryReference: summary['reference']?.toString() ?? '',
      summaryVerses: summaryVerses,
      completionMessage: j['completion_message']?.toString() ?? '',
      days: ((j['days'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => PathDay.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

/// The four daily steps shown on the Daily Connection screen.
enum PathStep { verse, devotion, reflection, prayer }
