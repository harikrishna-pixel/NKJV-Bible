import 'package:shared_preferences/shared_preferences.dart';

/// Local-only flags for which milestone unlock popups were already shown.
/// Does not touch streak / prayer / reading-plan data.
class MilestoneCelebrationStore {
  MilestoneCelebrationStore._();

  static const _celebratedKey = 'milestone_celebrated_ids_v1';
  static const _seededKey = 'milestone_celebrated_seeded_v1';

  static Future<Set<String>> loadCelebratedIds() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_celebratedKey) ?? const <String>[];
    return list.toSet();
  }

  static Future<void> saveCelebratedIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_celebratedKey, ids.toList()..sort());
  }

  static Future<void> markCelebrated(String id) async {
    final s = await loadCelebratedIds();
    if (s.add(id)) await saveCelebratedIds(s);
  }

  static Future<bool> isSeeded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_seededKey) ?? false;
  }

  static Future<void> markSeeded() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seededKey, true);
  }
}
