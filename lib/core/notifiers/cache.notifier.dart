import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheNotifier extends ChangeNotifier {
  static const String _lastCallDateKey = 'lastCallDate';

  Future readCache({required String key}) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    var cacheData = sharedPreferences.getString(key);
    return cacheData;
  }

  Future writeCache({required String key, required String value}) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    await sharedPreferences.setString(key, value);
  }

  Future removeCache({required String key}) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    await sharedPreferences.remove(key);
  }

  /// If not, it will execute the provided function and update the last call date.
  static Future<void> callOncePerDay(Function functionToCall) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the last called date from SharedPreferences
    final String? lastCallDate = prefs.getString(_lastCallDateKey);

    // Get today's date in 'yyyy-MM-dd' format
    final String today = DateTime.now().toIso8601String().split('T').first;

    if (lastCallDate != today) {
      // Call the function
      functionToCall();

      // Update the last call date in SharedPreferences
      await prefs.setString(_lastCallDateKey, today);
    }
  }
}
