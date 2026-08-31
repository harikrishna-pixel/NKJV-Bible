/// Remote Prayer Wall API (MongoDB-backed).
/// Base host only — paths are appended without duplicating slashes.
class PrayerWallApiConstant {
  PrayerWallApiConstant._();

  static const String baseUrl = 'https://api.biblehi.com';

  static String _path(String p) => '$baseUrl$p';

  static String get health => _path('/health');
  static String get prayers => _path('/api/prayers');
  static String get comments => _path('/api/comments');
  static String get likes => _path('/api/likes');
  static String get prayerReports => _path('/api/prayer-reports');
  static String get blockedUsers => _path('/api/blocked-users');
  static String get usersResolve => _path('/api/users/resolve');
  static String get prayerHistory => _path('/api/prayer-history');

  /// Additive: expired / past prayers — `GET /api/prayer-history?user_id=`.
  /// Does not change GET /api/prayers (wall) or identity GET (active My Prayers).
  static String prayerHistoryForUser(String userId) =>
      '$prayerHistory?user_id=${Uri.encodeQueryComponent(userId)}';

  /// Additive: restore blocks after login — `GET /api/blocked-users?user_id=`.
  static String blockedUsersForUser(String userId) =>
      '$blockedUsers?user_id=${Uri.encodeQueryComponent(userId)}';

  /// Optional query helpers (no path params on server).
  static String commentsForPrayer(String prayerId) =>
      '$comments?prayerId=$prayerId';

  static String likesForPrayer(String prayerId) =>
      '$likes?prayerId=$prayerId';

  /// One prayer by id (history): `GET /api/prayers?prayerId={id}`.
  static String prayersForPrayerId(String prayerId) =>
      '$prayers?prayerId=${Uri.encodeQueryComponent(prayerId)}';

  /// Additive: wall fetch with identity — `GET /api/prayers?identityUserId=`.
  static String prayersForIdentityUserId(String identityUserId) =>
      '$prayers?identityUserId=${Uri.encodeQueryComponent(identityUserId)}';

  /// Additive: wall omitting this viewer's blocked prayers.
  /// `GET /api/prayers?excludeBlockedForUserId=`.
  static String prayersExcludingBlockedForUser(String userId) =>
      '$prayers?excludeBlockedForUserId=${Uri.encodeQueryComponent(userId)}';
}
