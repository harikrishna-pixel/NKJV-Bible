import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Additive liturgical HTTP helpers (tradition JSON + per-day API).
/// Kept separate so calendar feast-list / CSV logic stays unchanged.

String _calendarBundleId() {
  return Platform.isIOS
      ? BibleInfo.ios_Bundle_Id
      : BibleInfo.android_Package_Name;
}

Future<String?> _resolveCalendarTradition() async {
  final cached =
      await SharPreferences.getString(SharPreferences.calendarTradition);
  if (cached != null && cached.trim().isNotEmpty) return cached.trim();

  final bundle = _calendarBundleId();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final uri = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/calendar_api.php'
    '?bundle=${Uri.encodeQueryComponent(bundle)}'
    '&date=$today',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) return null;
  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return null;
  final tradition = decoded['tradition']?.toString().trim();
  if (tradition == null || tradition.isEmpty) return null;
  await SharPreferences.setString(SharPreferences.calendarTradition, tradition);
  return tradition;
}

Future<Map<String, dynamic>?> _loadCachedLiturgicalJson() async {
  final raw = await SharPreferences.getString(SharPreferences.calendarDataJson);
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

Future<Map<String, dynamic>?> _fetchLiturgicalDataFile(String tradition) async {
  final url = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/data/$tradition.json',
  );
  final etag =
      await SharPreferences.getString(SharPreferences.calendarDataEtag) ?? '';
  final headers = <String, String>{};
  if (etag.isNotEmpty) {
    headers['If-None-Match'] = etag;
  }
  final response = await http.get(url, headers: headers);
  if (response.statusCode == 304) {
    return _loadCachedLiturgicalJson();
  }
  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return _loadCachedLiturgicalJson();
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return _loadCachedLiturgicalJson();
  final map = Map<String, dynamic>.from(decoded);
  await SharPreferences.setString(
    SharPreferences.calendarDataJson,
    response.body,
  );
  final newEtag = response.headers['etag'] ?? '';
  if (newEtag.isNotEmpty) {
    await SharPreferences.setString(SharPreferences.calendarDataEtag, newEtag);
  }
  return map;
}

/// Ensures tradition JSON is cached (additive; feast-list path unchanged).
Future<Map<String, dynamic>?> ensureLiturgicalDataCached() async {
  final tradition = await _resolveCalendarTradition();
  if (tradition == null) return _loadCachedLiturgicalJson();
  try {
    return await _fetchLiturgicalDataFile(tradition);
  } catch (_) {
    return _loadCachedLiturgicalJson();
  }
}

/// Per-day liturgical API (method A) — used with a 6 h client cache.
Future<Map<String, dynamic>?> fetchLiturgicalDayFromApi(DateTime date) async {
  final bundle = _calendarBundleId();
  final iso = DateFormat('yyyy-MM-dd').format(
    DateTime(date.year, date.month, date.day),
  );
  final uri = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/calendar_api.php'
    '?bundle=${Uri.encodeQueryComponent(bundle)}'
    '&date=$iso',
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
}
