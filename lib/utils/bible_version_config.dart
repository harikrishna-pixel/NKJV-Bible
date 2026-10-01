import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

class BibleVersionConfig {
  const BibleVersionConfig({
    required this.folder,
    required this.displayName,
    required this.chipLabel,
    required this.languageCode,
    required this.chapterWord,
    required this.ttsLanguage,
    required this.audioBasePath,
    this.otBookCount = 39,
    this.bookAliases = const {},
  });

  final String folder;
  final String displayName;
  final String chipLabel;
  final String languageCode;
  final String chapterWord;
  final String ttsLanguage;
  final String audioBasePath;
  final int otBookCount;
  final Map<String, List<String>> bookAliases;

  static const all = <BibleVersionConfig>[
    BibleVersionConfig(
      folder: 'NLT Bible',
      displayName: 'NLT Bible',
      chipLabel: 'NLT',
      languageCode: 'en',
      chapterWord: 'Chapter',
      ttsLanguage: 'en-US',
      audioBasePath:
          'https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English',
    ),
    BibleVersionConfig(
      folder: 'TAMIL_Bible',
      displayName: 'Tamil Bible',
      chipLabel: 'Tamil',
      languageCode: 'ta',
      chapterWord: 'அதிகாரம்',
      ttsLanguage: 'ta-IN',
      audioBasePath: '',
      bookAliases: {
        'genesis': ['ஆதியாகமம்'],
        'exodus': ['யாத்திராகமம்'],
        'matthew': ['மத்தேயு'],
        'john': ['யோவான்'],
        'psalms': ['சங்கீதம்'],
      },
    ),
  ];

  static BibleVersionConfig? forFolder(String? folder) {
    if (folder == null) return null;
    for (final c in all) {
      if (c.folder.toLowerCase() == folder.toLowerCase()) return c;
    }
    return null;
  }

  static Future<String?> activeFolder() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in prefs.getStringList('buttonStates') ?? const []) {
      final parts = entry.split(':');
      if (parts.length == 2 &&
          parts[1].contains('DownloadButtonState.active')) {
        return parts[0];
      }
    }
    return BibleInfo.folders.length == 1 ? BibleInfo.folders.first : null;
  }

  static Future<BibleVersionConfig?> active() async =>
      forFolder(await activeFolder());
}
