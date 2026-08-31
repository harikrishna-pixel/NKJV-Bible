import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UnsplashService {
  static const String _accessKeyKey = 'unsplash_access_key';
  static const String _baseUrl = 'https://api.unsplash.com';
  // Default access key - you can override this by calling setAccessKey()
  static const String _defaultAccessKey =
      'hYjjb0Q9x9sUu5B1BpIkgd1B8fvP00QmDMARhXLGprE';

  // Specific keywords for each study plan to get better matching images
  static const Map<String, String> _planKeywords = {
    'gospels': 'Jesus Christ cross sunrise holy light divine',
    'psalms': 'peaceful nature calm sunset tranquil serene mountain',
    'proverbs': 'wisdom ancient books scroll knowledge library study',
    'genesis': 'creation universe stars sky nature cosmos beginning',
    'love': 'love heart hands together family unity compassion',
    'faith': 'faith journey path light hope sunrise pathway',
    'wisdom': 'wisdom light understanding enlightenment dawn morning',
    'peace': 'calm peaceful meditation serenity ocean waves quiet',
    'hope': 'hope sunrise dawn light bright future optimism',
    'joy': 'joy happiness celebration cheerful laughter smiling',
    'courage': 'courage strength mountain climbing overcoming victory',
    'forgiveness': 'forgiveness mercy grace peaceful hands',
    'healing': 'healing restoration renewal nature growth',
    'protection': 'protection shield safety secure guardian',
    'trust': 'trust faith confidence reliable support',
    'gratitude': 'gratitude thankful blessing appreciation',
  };

  // Fallback keywords by category
  static const Map<String, String> _categoryKeywords = {
    'Devotional Growth': 'spiritual meditation prayer worship',
    'Life Challenges': 'peaceful nature calm hopeful',
    'Biblical Themes': 'bible book reading scripture',
  };

  // Cache for images
  static final Map<String, String> _imageCache = {};

  // Set Unsplash access key
  Future<void> setAccessKey(String accessKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKeyKey, accessKey);
  }

  // Get Unsplash access key
  Future<String?> getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_accessKeyKey);
    // Return saved key or default if none saved
    return savedKey ?? _defaultAccessKey;
  }

  // Get image URL for a study plan based on plan ID, category, or title
  Future<String> getImageUrl(
      String planId, String category, String title) async {
    // Check cache first
    final cacheKey = '$planId-$category-$title';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    final accessKey = await getAccessKey();
    if (accessKey == null || accessKey.isEmpty) {
      // Return placeholder if no access key
      return '';
    }

    try {
      // Use plan-specific keywords first, then category, then title
      String keyword = _planKeywords[planId.toLowerCase()] ??
          _categoryKeywords[category] ??
          title.toLowerCase();

      final url = Uri.parse(
          '$_baseUrl/photos/random?query=$keyword&orientation=landscape&client_id=$accessKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['urls']['regular'] as String;

        // Cache the result
        _imageCache[cacheKey] = imageUrl;
        return imageUrl;
      } else {
        // Fallback to a default image or empty
        return '';
      }
    } catch (e) {
      print('Error fetching Unsplash image: $e');
      return '';
    }
  }

  // Clear cache
  void clearCache() {
    _imageCache.clear();
  }
}
