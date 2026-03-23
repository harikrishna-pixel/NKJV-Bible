import 'dart:convert';

/// Parsed prayer row from `GET /api/prayers`.
class PrayerWallItem {
  PrayerWallItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isAnonymous,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isAnonymous;
  final DateTime? createdAt;

  static PrayerWallItem? fromDynamic(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final title = map['prayer_title']?.toString() ?? '';
    final desc = map['prayer_description']?.toString() ?? '';
    final cat = map['prayer_category']?.toString() ?? 'Others';
    final anon = map['isAnonymous'] is bool
        ? map['isAnonymous'] as bool
        : true;
    DateTime? created;
    final ca = map['createdAt'] ?? map['created_at'];
    if (ca != null) {
      created = DateTime.tryParse(ca.toString());
    }
    return PrayerWallItem(
      id: id,
      title: title,
      description: desc,
      category: cat,
      isAnonymous: anon,
      createdAt: created,
    );
  }

  static List<PrayerWallItem> listFromResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
    final out = <PrayerWallItem>[];
    for (final e in decoded) {
      final p = fromDynamic(e);
      if (p != null) out.add(p);
    }
    return out;
  }
}
