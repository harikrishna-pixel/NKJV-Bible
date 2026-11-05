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

/// One slot row from `GET /api/prayer-queue` `items[]`.
class PrayerQueueSlotItem {
  PrayerQueueSlotItem({
    required this.position,
    required this.isCurrent,
    required this.prayer,
  });

  final int position;
  final bool isCurrent;
  final PrayerWallItem prayer;

  static PrayerQueueSlotItem? fromDynamic(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final prayer = PrayerWallItem.fromDynamic(map['prayer']);
    if (prayer == null) return null;
    final posRaw = map['position'];
    final position = posRaw is int
        ? posRaw
        : int.tryParse(posRaw?.toString() ?? '') ?? 0;
    final isCurrent = map['isCurrent'] == true;
    return PrayerQueueSlotItem(
      position: position,
      isCurrent: isCurrent,
      prayer: prayer,
    );
  }
}

/// Parsed `GET /api/prayer-queue` body.
class PrayerQueueListResult {
  PrayerQueueListResult({
    required this.slotSeconds,
    required this.queueCount,
    required this.currentPosition,
    required this.msRemaining,
    required this.loops,
    required this.items,
    this.slotStartedAt,
    this.slotEndsAt,
  });

  final int slotSeconds;
  final int queueCount;
  final int currentPosition;
  final int msRemaining;
  final bool loops;
  final List<PrayerQueueSlotItem> items;
  final DateTime? slotStartedAt;
  final DateTime? slotEndsAt;

  static PrayerQueueListResult? fromResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final rawItems = map['items'];
    final items = <PrayerQueueSlotItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        final slot = PrayerQueueSlotItem.fromDynamic(e);
        if (slot != null) items.add(slot);
      }
    }
    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    DateTime? asDate(dynamic v) => _prayerQueueUtc(v);

    return PrayerQueueListResult(
      slotSeconds: asInt(map['slotSeconds'], 420),
      queueCount: asInt(map['queueCount'], items.length),
      currentPosition: asInt(map['currentPosition'] ?? map['position']),
      msRemaining: asInt(map['msRemaining']),
      loops: map['loops'] == true,
      items: items,
      slotStartedAt: asDate(map['slotStartedAt']),
      slotEndsAt: asDate(map['slotEndsAt']),
    );
  }
}

/// Parsed `GET /api/prayer-queue/current` body.
class PrayerQueueCurrentResult {
  PrayerQueueCurrentResult({
    required this.slotSeconds,
    required this.queueCount,
    required this.position,
    required this.msRemaining,
    required this.loops,
    this.slotStartedAt,
    this.slotEndsAt,
    this.prayer,
    this.nextPrayerId,
  });

  final int slotSeconds;
  final int queueCount;
  final int position;
  final int msRemaining;
  final bool loops;
  final DateTime? slotStartedAt;
  final DateTime? slotEndsAt;
  final PrayerWallItem? prayer;
  final String? nextPrayerId;

  static PrayerQueueCurrentResult? fromResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    DateTime? asDate(dynamic v) => _prayerQueueUtc(v);

    final nextId = map['nextPrayerId']?.toString().trim();
    return PrayerQueueCurrentResult(
      slotSeconds: asInt(map['slotSeconds'], 420),
      queueCount: asInt(map['queueCount']),
      position: asInt(map['position'] ?? map['currentPosition']),
      msRemaining: asInt(map['msRemaining']),
      loops: map['loops'] == true,
      slotStartedAt: asDate(map['slotStartedAt']),
      slotEndsAt: asDate(map['slotEndsAt']),
      prayer: PrayerWallItem.fromDynamic(map['prayer']),
      nextPrayerId: (nextId == null || nextId.isEmpty) ? null : nextId,
    );
  }
}

/// Encodes original + AI prayer into one `prayer_description` for the wall.
class PrayerDualDescription {
  static const myWordsMarker = '<<<MY_WORDS>>>';
  static const aiMarker = '<<<AI_PRAYER>>>';

  static String encode({
    required String originalWords,
    required String englishPrayer,
  }) {
    return '$myWordsMarker\n${originalWords.trim()}\n$aiMarker\n${englishPrayer.trim()}';
  }

  static bool isDual(String description) {
    final s = description.trim();
    return s.contains(myWordsMarker) && s.contains(aiMarker);
  }

  static String? myWords(String description) {
    if (!isDual(description)) return null;
    final start = description.indexOf(myWordsMarker) + myWordsMarker.length;
    final end = description.indexOf(aiMarker);
    if (end <= start) return null;
    final v = description.substring(start, end).trim();
    return v.isEmpty ? null : v;
  }

  static String? aiPrayer(String description) {
    if (!isDual(description)) return null;
    final start = description.indexOf(aiMarker) + aiMarker.length;
    final v = description.substring(start).trim();
    return v.isEmpty ? null : v;
  }

  static String visibleBody(String description) {
    final ai = (aiPrayer(description) ?? '').trim();
    if (ai.isNotEmpty) return ai;
    final my = (myWords(description) ?? '').trim();
    if (my.isNotEmpty) return my;
    if (isDual(description)) return '';
    return description.trim();
  }

  /// True when `prayer_title` is the prayer text, or the start of it.
  static bool titleRepeatsPrayer(String title, String description) {
    final t = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final b = visibleBody(description).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty || b.isEmpty) return false;
    return t == b || b.startsWith(t);
  }
}

/// Hybrid fair rotation computed on the client from the server queue.
///
/// Pure function of the server list (createdAt asc, `_id` asc) and the
/// server's epoch-aligned slot number, so every user gets the same schedule.
/// Per round each prayer is featured once (no repeats while others wait);
/// never-featured prayers go first; 3 of every 10 slots prefer prayers
/// posted within 48h; with no fresh prayers every slot is fair rotation.
class PrayerHybridRotation {
  static const freshWindow = Duration(hours: 48);
  static const _freshSlotsOfTen = {2, 5, 8};
  /// History replayed before "now" (~14 days of 7 min slots).
  static const _maxHistorySlots = 2880;
  /// Re-anchor step when history is capped (~1 day), avoids per-slot drift.
  static const _anchorAlignSlots = 200;

  static ({PrayerQueueCurrentResult current, PrayerQueueListResult list})?
      apply(PrayerQueueCurrentResult current, PrayerQueueListResult list) {
    final slotMs = list.slotSeconds * 1000;
    final startedAt = current.slotStartedAt ?? list.slotStartedAt;
    final prayers = [
      for (final slot in [...list.items]
        ..sort((a, b) => a.position.compareTo(b.position)))
        slot.prayer,
    ];
    if (slotMs <= 0 || startedAt == null || prayers.length < 2) return null;

    final nowSlot = startedAt.millisecondsSinceEpoch ~/ slotMs;
    final n = prayers.length;
    final createdMs = [
      for (final p in prayers) p.createdAt?.millisecondsSinceEpoch,
    ];
    final eligibleFrom = [
      for (final ms in createdMs) ms == null ? null : (ms + slotMs - 1) ~/ slotMs,
    ];

    int? oldest;
    for (final s in eligibleFrom) {
      if (s != null && (oldest == null || s < oldest)) oldest = s;
    }
    final cap =
        ((nowSlot - _maxHistorySlots) ~/ _anchorAlignSlots) * _anchorAlignSlots;
    var anchor = oldest ?? nowSlot;
    if (anchor < cap) anchor = cap;
    if (anchor > nowSlot) anchor = nowSlot;

    final lastShown = List<int?>.filled(n, null);
    final inRound = List<bool>.filled(n, false);
    final freshMs = freshWindow.inMilliseconds;

    int? pickAt(int t) {
      final eligible = <int>[
        for (var i = 0; i < n; i++)
          if ((eligibleFrom[i] ?? anchor) <= t) i,
      ];
      if (eligible.isEmpty) return null;
      var pool = eligible.where((i) => !inRound[i]).toList();
      if (pool.isEmpty) {
        for (final i in eligible) {
          inRound[i] = false;
        }
        pool = eligible;
      }
      if (_freshSlotsOfTen.contains(t % 10)) {
        final cut = t * slotMs - freshMs;
        final fresh = pool.where((i) {
          final ms = createdMs[i];
          return ms != null && ms >= cut;
        }).toList();
        if (fresh.isNotEmpty) pool = fresh;
      }
      var best = pool.first;
      for (final i in pool.skip(1)) {
        final a = lastShown[i];
        final b = lastShown[best];
        if (b == null) continue;
        if (a == null || a < b) best = i;
      }
      inRound[best] = true;
      lastShown[best] = t;
      return best;
    }

    for (var t = anchor; t < nowSlot; t++) {
      pickAt(t);
    }

    final firstOffset = <int, int>{};
    final horizon = n * 2 + 10;
    for (var j = 0; j <= horizon && firstOffset.length < n; j++) {
      final idx = pickAt(nowSlot + j);
      if (idx != null) firstOffset.putIfAbsent(idx, () => j);
    }
    final currentIdx = firstOffset.entries
        .firstWhere((e) => e.value == 0, orElse: () => firstOffset.entries.first)
        .key;
    final nextIdx = firstOffset.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<int, int>?>(
          null,
          (best, e) => best == null || e.value < best.value ? e : best,
        )
        ?.key;

    var tail = horizon + 2;
    final items = <PrayerQueueSlotItem>[
      for (var i = 0; i < n; i++)
        PrayerQueueSlotItem(
          position: (firstOffset[i] ?? tail++) + 1,
          isCurrent: i == currentIdx,
          prayer: prayers[i],
        ),
    ]..sort((a, b) => a.position.compareTo(b.position));

    return (
      current: PrayerQueueCurrentResult(
        slotSeconds: current.slotSeconds,
        queueCount: current.queueCount,
        position: 1,
        msRemaining: current.msRemaining,
        loops: current.loops,
        slotStartedAt: current.slotStartedAt,
        slotEndsAt: current.slotEndsAt,
        prayer: prayers[currentIdx],
        nextPrayerId: nextIdx == null ? null : prayers[nextIdx].id,
      ),
      list: PrayerQueueListResult(
        slotSeconds: list.slotSeconds,
        queueCount: list.queueCount,
        currentPosition: 1,
        msRemaining: list.msRemaining,
        loops: list.loops,
        items: items,
        slotStartedAt: list.slotStartedAt,
        slotEndsAt: list.slotEndsAt,
      ),
    );
  }
}

/// Queue times from the server are global (UTC).
DateTime? _prayerQueueUtc(dynamic v) {
  if (v == null) return null;
  final raw = v.toString().trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final hasZone = raw.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(raw);
  if (hasZone) return parsed.toUtc();
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
