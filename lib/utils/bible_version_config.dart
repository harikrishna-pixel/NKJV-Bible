import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';

/// Per-Bible display settings for multi-Bible builds ([BibleInfo.folders]).
/// Display only — does not change extract / load / switch logic.
class BibleVersionConfig {
  const BibleVersionConfig({
    required this.folder,
    required this.displayName,
    required this.chipLabel,
    required this.languageCode,
    required this.chapterWord,
    this.ttsLanguage,
    this.audioBasePath,
    this.scriptPattern,
    this.bookAliases = const {},
  });

  /// Must match the [BibleInfo.folders] entry exactly.
  final String folder;

  /// Bible Version screen title.
  final String displayName;

  /// My Library card chip.
  final String chipLabel;

  final String languageCode;

  /// "Chapter" word in the reader bar and chapter list.
  final String chapterWord;

  /// Text-to-speech language; null keeps the API / [BibleInfo] default.
  final String? ttsLanguage;

  /// MP3 base ('<base>/<bookNum>/<chapterNum>.mp3'); null keeps the API default.
  final String? audioBasePath;

  /// Non-Latin script detector used to label Library items saved from this Bible.
  final RegExp? scriptPattern;

  /// English book name (lowercase) -> extra local names (lowercase).
  final Map<String, List<String>> bookAliases;

  static final List<BibleVersionConfig> all = [
    const BibleVersionConfig(
      folder: 'NLT Bible',
      displayName: 'NLT Bible',
      chipLabel: 'NLT',
      languageCode: 'en',
      chapterWord: 'Chapter',
    ),
    BibleVersionConfig(
      folder: 'TAMIL_Bible',
      displayName: 'Tamil Bible',
      chipLabel: 'Tamil',
      languageCode: 'ta',
      chapterWord: 'அதிகாரம்',
      ttsLanguage: 'ta-IN',
      scriptPattern: RegExp(r'[\u0B80-\u0BFF]'),
    ),
    const BibleVersionConfig(
      folder: 'NKJV',
      displayName: 'NKJV Bible',
      chipLabel: 'NKJV',
      languageCode: 'en',
      chapterWord: 'Chapter',
      audioBasePath:
          'https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English',
    ),
    const BibleVersionConfig(
      folder: 'catholic',
      displayName: 'Catholic Bible',
      chipLabel: 'Catholic',
      languageCode: 'pt',
      chapterWord: 'Capítulo',
      ttsLanguage: 'pt-BR',
      audioBasePath:
          'https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/Portuguese',
    ),
  ];

  static BibleVersionConfig? forFolder(String? folder) {
    if (folder == null) return null;
    final f = folder.trim().toLowerCase();
    for (final c in all) {
      if (c.folder.toLowerCase() == f) return c;
    }
    return null;
  }

  static String displayNameFor(String folder) =>
      forFolder(folder)?.displayName ?? folder;

  /// Configs for the folders shipped in this build, in [BibleInfo.folders] order.
  static List<BibleVersionConfig> get installed => [
        for (final f in BibleInfo.folders)
          if (forFolder(f) != null) forFolder(f)!,
      ];

  static String? _cachedActiveFolder;

  /// Last folder read by [activeFolder] (sync access for display code).
  static String? get cachedActiveFolder => _cachedActiveFolder;

  /// Active folder from Bible Version selection (`buttonStates` pref).
  static Future<String?> activeFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in prefs.getStringList('buttonStates') ?? const []) {
        final i = entry.lastIndexOf(':');
        if (i <= 0) continue;
        if (entry.substring(i + 1).contains('DownloadButtonState.active')) {
          _cachedActiveFolder = entry.substring(0, i);
          return _cachedActiveFolder;
        }
      }
    } catch (_) {}
    if (BibleInfo.folders.length == 1) {
      _cachedActiveFolder = BibleInfo.folders.first;
    }
    return _cachedActiveFolder;
  }

  static Future<BibleVersionConfig?> active() async =>
      forFolder(await activeFolder());
}
