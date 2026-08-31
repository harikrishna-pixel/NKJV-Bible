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
    this.email,
    this.identityUserId,
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
  /// Login email stored on the prayer when posted.
  final String? email;
  /// Resolve `user_id` stored as identityUserId on the prayer.
  final String? identityUserId;
  final String? profileImage;
  final DateTime? createdAt;
  /// From API `expiresAt` when present.
  final DateTime? expiresAt;
  /// From API `prayer_duration` when present.
  final int? prayerDuration;

  /// True after postedAt + duration (or API expiresAt). Used for Expired tab.
  bool get isDurationExpired {
    final expires = expiresAt ??
        (createdAt != null && (prayerDuration ?? 0) > 0
            ? createdAt!.add(Duration(days: prayerDuration!))
            : null);
    if (expires == null) return false;
    return !DateTime.now().isBefore(expires.toLocal());
  }

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

  /// Poster Mongo / Auth id from a prayer JSON row (API field names vary).
  static String? extractAuthorUserId(Map<String, dynamic> map) {
    final direct = _cleanName(
      map['userId'] ??
          map['user_id'] ??
          map['identityUserId'] ??
          map['identity_user_id'] ??
          map['authorId'] ??
          map['author_id'] ??
          map['createdById'] ??
          map['created_by'] ??
          map['firebaseUid'] ??
          map['firebase_uid'] ??
          map['mongoUserId'] ??
          map['mongo_user_id'] ??
          map['posterId'] ??
          map['poster_id'] ??
          map['ownerId'] ??
          map['owner_id'],
    );
    if (direct != null) return direct;

    final userField = map['user'];
    if (userField is String) {
      final asString = _cleanName(userField);
      if (asString != null) return asString;
    }

    if (userField is Map) {
      final userMap = Map<String, dynamic>.from(userField);
      final fromUser = _cleanName(
        userMap['userId'] ??
            userMap['user_id'] ??
            userMap['_id'] ??
            userMap['id'] ??
            userMap['firebaseUid'] ??
            userMap['firebase_uid'],
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
            posterMap['id'] ??
            posterMap['firebaseUid'] ??
            posterMap['firebase_uid'],
      );
    }
    return null;
  }

  static String? _extractAuthorUserId(Map<String, dynamic> map) =>
      extractAuthorUserId(map);

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
    final email = _cleanName(map['email']);
    final identityUserId = _cleanName(
      map['identityUserId'] ?? map['identity_user_id'],
    );
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
      email: email,
      identityUserId: identityUserId,
      profileImage: profileImage,
      createdAt: created,
      expiresAt: expires,
      prayerDuration: duration,
    );
  }

  static List<PrayerWallItem> listFromResponseBody(String body) {
    final decoded = jsonDecode(body);
    List<dynamic>? raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      final nested = m['data'] ?? m['prayers'] ?? m['items'] ?? m['results'];
      if (nested is List) raw = nested;
    }
    if (raw == null) return [];
    final out = <PrayerWallItem>[];
    for (final e in raw) {
      final p = fromDynamic(e);
      if (p != null) out.add(p);
    }
    return out;
  }
}
