/// Remote Prayer Wall API (MongoDB-backed).
/// Base host only — paths are appended without duplicating slashes.
class PrayerWallApiConstant {
  PrayerWallApiConstant._();

  static const String baseUrl = 'http://marberx-tech.duckdns.org';

  static String _path(String p) => '$baseUrl$p';

  static String get health => _path('/health');
  static String get prayers => _path('/api/prayers');
  static String get comments => _path('/api/comments');
  static String get likes => _path('/api/likes');

  /// Optional query helpers (no path params on server).
  static String commentsForPrayer(String prayerId) =>
      '$comments?prayerId=$prayerId';

  static String likesForPrayer(String prayerId) =>
      '$likes?prayerId=$prayerId';
}
