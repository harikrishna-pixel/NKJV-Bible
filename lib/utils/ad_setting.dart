import 'package:shared_preferences/shared_preferences.dart';

class ConsentManager {
  static const String _consentKey = 'user_consent'; // true or false

  static Future<void> saveConsent(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, allowed);
  }

  static Future<bool?> getConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey); // null if not set
  }

  static Future<bool> isTrackingAllowed() async {
    final consent = await getConsent();
    return consent ?? false;
  }
}
