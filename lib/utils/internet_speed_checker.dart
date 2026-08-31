import 'package:http/http.dart' as http;

class InternetSpeedChecker {
  /// Returns internet response time in milliseconds
  /// Returns `null` if internet is unreachable or request times out
  static Future<int?> checkSpeed({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com/search?q=bible')) // lighter
          .timeout(timeout);

      stopwatch.stop();
      if (response.statusCode == 204 || response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      // Handle specific errors if needed (SocketException, TimeoutException, etc.)
      return null;
    }
    return null; // No internet or very slow
  }
}
