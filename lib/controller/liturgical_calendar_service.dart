import 'dart:convert';

import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/liturgical_day_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves per-day liturgical data from cached tradition JSON (offline-first)
/// with a per-day API fallback (6 h cache). Does not change feast-list logic.
class LiturgicalCalendarService {
  LiturgicalCalendarService._();

  static const _cacheHours = 6;

  static String _isoDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return DateFormat('yyyy-MM-dd').format(d);
  }

  static String _mmdd(DateTime date) {
    return DateFormat('MM-dd').format(DateTime(date.year, date.month, date.day));
  }

  static bool _inRange(String iso, String? start, String? end) {
    if (start == null || end == null) return false;
    return iso.compareTo(start) >= 0 && iso.compareTo(end) <= 0;
  }

  static Map<String, dynamic>? _yearBlock(
    Map<String, dynamic> data,
    int year,
  ) {
    final years = data['years'];
    if (years is Map) {
      final raw = years['$year'];
      if (raw is Map) return Map<String, dynamic>.from(raw);
    }
    if (data['year']?.toString() == '$year') {
      return data;
    }
    return null;
  }

  static String _prettyFeastName(String key) {
    const labels = {
      'ashWednesday': 'Ash Wednesday',
      'palmSunday': 'Palm Sunday',
      'maundyThursday': 'Maundy Thursday',
      'goodFriday': 'Good Friday',
      'holySaturday': 'Holy Saturday',
      'easterSunday': 'Easter Sunday',
      'pascha': 'Pascha',
      'ascension': 'Ascension Day',
      'pentecost': 'Pentecost',
      'trinitySunday': 'Trinity Sunday',
      'firstSundayOfAdvent': 'Advent (First Sunday)',
      'christmas': 'Christmas Day',
      'christmasEve': 'Christmas Eve',
      'corpusChristi': 'Corpus Christi',
    };
    if (labels.containsKey(key)) return labels[key]!;
    if (key.contains(' ') || key.contains("'")) return key;
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String? _lookupFeast(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final iso = _isoDate(date);
    final mmdd = _mmdd(date);
    final yearBlock = _yearBlock(data, date.year);

    for (final mapKey in ['movableFeasts', 'majorFeasts']) {
      final map = yearBlock?[mapKey] ?? data[mapKey];
      if (map is Map) {
        for (final entry in map.entries) {
          if (entry.value?.toString() == iso) {
            return _prettyFeastName(entry.key.toString());
          }
        }
      }
    }

    for (final mapKey in ['fixedFeasts', 'greatFeastsFixed']) {
      final map = yearBlock?[mapKey] ?? data[mapKey];
      if (map is Map && map[mmdd] != null) {
        //
        return map[mmdd].toString();
      }
    }
    return null;
  }

  static List<String> _lookupNamedList(
    Map<String, dynamic> data,
    DateTime date,
    String mapKey,
  ) {
    final mmdd = _mmdd(date);
    final yearBlock = _yearBlock(data, date.year);
    final map = yearBlock?[mapKey] ?? data[mapKey];
    if (map is Map && map[mmdd] != null) {
      return [map[mmdd].toString()];
    }
    return const [];
  }

  static Map<String, dynamic>? _fastingBlock(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final yearBlock = _yearBlock(data, date.year);
    final raw = yearBlock?['fasting'] ?? data['fasting'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static LiturgicalFasting? _resolveOrthodoxFast(
    DateTime date,
    Map<String, dynamic>? fastingBlock,
  ) {
    if (fastingBlock == null) return null;
    final iso = _isoDate(date);

    final fastFreeWeeks = fastingBlock['fastFreeWeeks'];
    if (fastFreeWeeks is List) {
      for (final week in fastFreeWeeks) {
        if (week is! Map) continue;
        if (_inRange(iso, week['start']?.toString(), week['end']?.toString())) {
          return LiturgicalFasting(
            isFast: false,
            rule: 'harti (fast-free)',
            reason: week['name']?.toString() ?? 'Fast-free week',
          );
        }
      }
    }

    final seasons = fastingBlock['seasons'];
    if (seasons is List) {
      for (final season in seasons) {
        if (season is! Map) continue;
        if (_inRange(
          iso,
          season['start']?.toString(),
          season['end']?.toString(),
        )) {
          return LiturgicalFasting(
            isFast: true,
            rule: 'post',
            reason: season['name']?.toString() ?? 'Fasting season',
            detail: season['rule']?.toString(),
          );
        }
      }
    }

    if (date.weekday == DateTime.wednesday ||
        date.weekday == DateTime.friday) {
      return LiturgicalFasting(
        isFast: true,
        rule: 'post',
        reason: date.weekday == DateTime.wednesday ? 'Wednesday' : 'Friday',
      );
    }

    return const LiturgicalFasting(
      isFast: false,
      rule: 'fara post',
    );
  }

  static String _resolveSeason(
    Map<String, dynamic> data,
    DateTime date,
    String? feast,
    LiturgicalFasting? fasting,
  ) {
    final iso = _isoDate(date);
    final fastingBlock = _fastingBlock(data, date);
    final seasons = fastingBlock?['seasons'];
    if (seasons is List) {
      for (final season in seasons) {
        if (season is! Map) continue;
        if (_inRange(
          iso,
          season['start']?.toString(),
          season['end']?.toString(),
        )) {
          return season['name']?.toString() ?? 'ordinary';
        }
      }
    }

    final feastLower = feast?.toLowerCase() ?? '';
    if (feastLower.contains('easter') || feastLower.contains('pascha')) {
      return 'Easter';
    }
    if (feastLower.contains('lent')) return 'Lent';
    if (feastLower.contains('advent')) return 'Advent';
    if (fasting?.isFast == true &&
        (fasting?.reason ?? '').trim().isNotEmpty) {
      return fasting!.reason!;
    }
    return 'ordinary';
  }

  static LiturgicalDayInfo? _resolveFromCachedJson(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final tradition = data['tradition']?.toString();
    final feast = _lookupFeast(data, date);
    final saints = _lookupNamedList(data, date, 'majorSaints');
    final yearBlock = _yearBlock(data, date.year);

    LiturgicalFasting? fasting;
    if (tradition == 'orthodox') {
      fasting = _resolveOrthodoxFast(date, _fastingBlock(data, date));
    }

    final season = _resolveSeason(data, date, feast, fasting);

    return LiturgicalDayInfo(
      date: _isoDate(date),
      tradition: tradition,
      locale: data['locale']?.toString(),
      feast: feast,
      season: season,
      fasting: fasting,
      saints: saints,
      nameDays: const [],
      easter: yearBlock?['easter']?.toString() ?? data['easter']?.toString(),
    );
  }

  static Future<Map<String, dynamic>?> _cachedDayApi(DateTime date) async {
    final iso = _isoDate(date);
    final prefs = await SharedPreferences.getInstance();
    final tsKey = '${SharPreferences.calendarDayApiTs}_$iso';
    final dataKey = '${SharPreferences.calendarDayApiJson}_$iso';
    final ts = prefs.getInt(tsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - ts < _cacheHours * 3600000) {
      final raw = prefs.getString(dataKey);
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    final api = await fetchLiturgicalDayFromApi(date);
    if (api != null) {
      await prefs.setString(dataKey, jsonEncode(api));
      await prefs.setInt(tsKey, now);
    }
    return api;
  }

  static bool _shouldUseApiFallback(
    Map<String, dynamic>? data,
    DateTime date,
  ) {
    if (data == null) return true;
    if (date.year >= 2026 && date.year <= 2030) {
      return _yearBlock(data, date.year) == null;
    }
    return false;
  }

  /// Device-local date resolution: cached JSON first, API fallback (6 h cache).
  static Future<LiturgicalDayInfo?> resolveDay(DateTime date) async {
    final localDate = DateTime(date.year, date.month, date.day);
    final data = await ensureLiturgicalDataCached();

    LiturgicalDayInfo? local;
    if (data != null) {
      local = _resolveFromCachedJson(data, localDate);
    }

    if (_shouldUseApiFallback(data, localDate)) {
      final api = await _cachedDayApi(localDate);
      if (api != null) return LiturgicalDayInfo.fromApi(api);
    }

    return local;
  }
}
