import 'dart:convert';

/// Parsed prayer row from `GET /api/prayers`.
class PrayerWallItem {
  PrayerWallItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isAnonymous,
    this.authorName,
    this.authorUserId,
    this.profileImage,
    this.createdAt,
    this.expiresAt,
    this.prayerDuration,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isAnonymous;
  final String? authorName;
  final String? authorUserId;
  /// Profile photo URL from API `profile_image` (when present).
  final String? profileImage;
  final DateTime? createdAt;
  /// From API `expiresAt` when present.
  final DateTime? expiresAt;
  /// From API `prayer_duration` when present.
  final int? prayerDuration;

  static String? _cleanName(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return s;
  }

  static String? _extractAuthorName(Map<String, dynamic> map) {
    final direct = _cleanName(
      map['name'] ??
          map['user_name'] ??
          map['userName'] ??
          map['username'] ??
          map['fullName'] ??
          map['authorName'] ??
          map['prayer_by'],
    );
    if (direct != null) return direct;

    final nestedUser = map['user'];
    if (nestedUser is Map) {
      final userMap = Map<String, dynamic>.from(nestedUser);
      final fromUser = _cleanName(
        userMap['name'] ??
            userMap['user_name'] ??
            userMap['userName'] ??
            userMap['username'] ??
            userMap['fullName'],
      );
      if (fromUser != null) return fromUser;
    }

    final nestedPoster = map['postedBy'] ?? map['createdBy'] ?? map['author'];
    if (nestedPoster is Map) {
      final posterMap = Map<String, dynamic>.from(nestedPoster);
      return _cleanName(
        posterMap['name'] ??
            posterMap['user_name'] ??
            posterMap['userName'] ??
            posterMap['username'] ??
            posterMap['fullName'],
      );
    }
    return null;
  }

  static String? _extractAuthorUserId(Map<String, dynamic> map) {
    final direct = _cleanName(
      map['userId'] ??
          map['user_id'] ??
          map['authorId'] ??
          map['author_id'] ??
          map['createdById'] ??
          map['created_by'],
    );
    if (direct != null) return direct;

    final nestedUser = map['user'];
    if (nestedUser is Map) {
      final userMap = Map<String, dynamic>.from(nestedUser);
      final fromUser = _cleanName(
        userMap['userId'] ?? userMap['user_id'] ?? userMap['_id'] ?? userMap['id'],
      );
      if (fromUser != null) return fromUser;
    }

    final nestedPoster = map['postedBy'] ?? map['createdBy'] ?? map['author'];
    if (nestedPoster is Map) {
      final posterMap = Map<String, dynamic>.from(nestedPoster);
      return _cleanName(
        posterMap['userId'] ??
            posterMap['user_id'] ??
            posterMap['_id'] ??
            posterMap['id'],
      );
    }
    return null;
  }

  static String? _extractProfileImage(Map<String, dynamic> map) {
    final direct = _cleanName(
      map['profile_image'] ??
          map['profileImage'] ??
          map['profile_image_url'] ??
          map['avatar'] ??
          map['avatar_url'] ??
          map['photoURL'] ??
          map['photo_url'],
    );
    if (direct != null) return direct;

    final nestedUser = map['user'];
    if (nestedUser is Map) {
      final userMap = Map<String, dynamic>.from(nestedUser);
      final fromUser = _cleanName(
        userMap['profile_image'] ??
            userMap['profileImage'] ??
            userMap['avatar'] ??
            userMap['photoURL'],
      );
      if (fromUser != null) return fromUser;
    }

    final nestedPoster = map['postedBy'] ?? map['createdBy'] ?? map['author'];
    if (nestedPoster is Map) {
      final posterMap = Map<String, dynamic>.from(nestedPoster);
      return _cleanName(
        posterMap['profile_image'] ??
            posterMap['profileImage'] ??
            posterMap['avatar'] ??
            posterMap['photoURL'],
      );
    }
    return null;
  }

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
    final authorName = _extractAuthorName(map);
    final authorUserId = _extractAuthorUserId(map);
    final profileImage = _extractProfileImage(map);
    DateTime? created;
    final ca = map['createdAt'] ?? map['created_at'];
    if (ca != null) {
      created = DateTime.tryParse(ca.toString());
    }
    DateTime? expires;
    final ea = map['expiresAt'] ?? map['expires_at'];
    if (ea != null) {
      expires = DateTime.tryParse(ea.toString());
    }
    int? duration;
    final pd = map['prayer_duration'] ?? map['prayerDuration'];
    if (pd is int) {
      duration = pd;
    } else if (pd != null) {
      duration = int.tryParse(pd.toString());
    }
    // Prefer API expiresAt; else createdAt + prayer_duration.
    if (expires == null &&
        created != null &&
        duration != null &&
        duration > 0) {
      expires = created.add(Duration(days: duration));
    }
    return PrayerWallItem(
      id: id,
      title: title,
      description: desc,
      category: cat,
      isAnonymous: anon,
      authorName: authorName,
      authorUserId: authorUserId,
      profileImage: profileImage,
      createdAt: created,
      expiresAt: expires,
      prayerDuration: duration,
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
