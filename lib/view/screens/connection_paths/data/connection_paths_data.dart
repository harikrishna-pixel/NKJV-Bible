import 'dart:convert';

import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:flutter/services.dart';

/// Loads Connection Paths from `assets/connection_paths_en.json`.
/// Separate from onboarding — do not share progress keys with onboarding.
class ConnectionPathsData {
  ConnectionPathsData._();

  static const assetPath = 'assets/connection_paths_en.json';

  static List<ConnectionPath>? _cache;

  /// Category chips shown on home / all-paths (mockup order).
  static const categoryChips = <({String id, String label})>[
    (id: 'all', label: 'All'),
    (id: 'prayer', label: 'Prayer'),
    (id: 'faith', label: 'Faith'),
    (id: 'peace', label: 'Peace'),
    (id: 'spiritual-growth', label: 'Spiritual Growth'),
    (id: 'gratitude', label: 'Gratitude'),
    (id: 'difficult-times', label: 'Difficult Times'),
  ];

  /// Jesus scenes from study_plan_images (covers + screen backgrounds).
  static const Map<String, String> coverAssets = {
    'growing_in_gratitude': 'assets/study_plan_images/Joy Scene.png',
    'closer_to_god': 'assets/study_plan_images/Hope and Love Scene.png',
    'build_a_prayer_habit': 'assets/study_plan_images/Healing Scene.png',
    'trust_god_more': 'assets/study_plan_images/Courage Scene.png',
    'morning_with_god': 'assets/study_plan_images/Faith Scene.png',
    'a_month_with_god': 'assets/study_plan_images/Peace and Wisdom Scene.png',
    'walk_with_god_daily':
        'assets/study_plan_images/Peace Symbol Integration.png',
    'the_lords_prayer':
        'assets/study_plan_images/Gemini_Generated_Image_5weyjf5weyjf5wey.png',
    'the_shepherds_psalm':
        'assets/study_plan_images/Gemini_Generated_Image_uwge7ruwge7ruwge.png',
    'abide_in_him': 'assets/study_plan_images/Hope and Love Scene.png',
    'rest_for_the_weary': 'assets/study_plan_images/Healing Scene.png',
    'peace_in_the_storm': 'assets/study_plan_images/Courage Scene.png',
    'faith_over_fear': 'assets/study_plan_images/Faith Scene.png',
    'fruit_of_the_spirit': 'assets/study_plan_images/Joy Scene.png',
    'who_god_says_you_are':
        'assets/study_plan_images/Peace Symbol Integration.png',
  };

  /// Mockup scenes: sunrise valley + river, and open Bible on a rock.
  static const valleyBgAsset =
      'assets/study_plan_images/connection_verse_bg.jpg';
  static const bibleSunriseBgAsset =
      'assets/study_plan_images/connection_check_bg.jpg';
  static const sproutGlowAsset =
      'assets/study_plan_images/connection_sprout_glow.png';
  static const sproutAsset = 'assets/study_plan_images/connection_sprout.png';

  static const heroAsset = valleyBgAsset;
  static const verseBgAsset = bibleSunriseBgAsset;
  static const devotionBgAsset = valleyBgAsset;
  static const reflectionBgAsset = valleyBgAsset;
  static const prayerBgAsset = valleyBgAsset;
  static const pageBgAsset = 'assets/peace-bg.png';
  static const checkBgAsset = valleyBgAsset;
  static const completeBgAsset = valleyBgAsset;
  static const detailsHeroFallback =
      'assets/study_plan_images/Hope and Love Scene.png';
  static const jesusCutout = 'assets/offer/jesus.png';

  static String coverFor(ConnectionPath path) =>
      coverAssets[path.coverAssetId] ?? coverAssets.values.first;

  static Future<List<ConnectionPath>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final text = await rootBundle.loadString(assetPath);
    final raw = jsonDecode(text) as Map<String, dynamic>;
    final plans = ((raw['plans'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => ConnectionPath.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    _cache = plans;
    return plans;
  }

  static List<ConnectionPath> get all => _cache ?? const [];

  static ConnectionPath? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<ConnectionPath> get featured {
    final list = all;
    if (list.isEmpty) return const [];
    // First three in JSON order (matches mockup featured feel).
    return list.take(3).toList();
  }

  static List<int> get durations {
    final set = <int>{};
    for (final p in all) {
      set.add(p.durationDays);
    }
    final list = set.toList()..sort();
    return list;
  }

  static List<ConnectionPath> forDuration(int? days) {
    if (days == null) return all;
    return all.where((p) => p.durationDays == days).toList();
  }

  static List<ConnectionPath> forCategory(String categoryId) {
    if (categoryId == 'all' || categoryId.isEmpty) return all;
    return all.where((p) => p.categoryId == categoryId).toList();
  }

  static String categoryLabel(String id) {
    for (final c in categoryChips) {
      if (c.id == id) return c.label;
    }
    return id;
  }
}
