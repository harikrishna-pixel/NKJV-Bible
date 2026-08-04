import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';

/// Display-only labels matched to the active Bible version language.
/// Does not change selection, load, or switch logic.
class BibleUiLabels {
  static String _chapterWord = 'Chapter';

  static String get chapterWord => _chapterWord;

  static bool folderIsPortuguese(String? folder) {
    final f = (folder ?? '').toLowerCase();
    return f == 'catholic' ||
        f.contains('portug') ||
        f == 'pt' ||
        f.contains('almeida');
  }

  static String chapterWordForFolder(String? folder) =>
      folderIsPortuguese(folder) ? 'Capítulo' : 'Chapter';

  /// Sync hint from current book title (e.g. Gênesis / João after Catholic load).
  static bool bookTitleLooksPortuguese(String? title) {
    final t = (title ?? '').trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t.contains(RegExp(r'[áàâãéêíóôõúç]'))) return true;
    // Portuguese titles only (avoid English "Genesis" / "Daniel" false matches).
    const ptBooks = {
      'gênesis',
      'êxodo',
      'exodo',
      'levítico',
      'levitico',
      'números',
      'numeros',
      'deuteronômio',
      'deuteronomio',
      'josué',
      'josue',
      'juízes',
      'juizes',
      'mateus',
      'marcos',
      'lucas',
      'joão',
      'joao',
      'atos',
      'romanos',
      'coríntios',
      'corintios',
      'gálatas',
      'galatas',
      'efésios',
      'efesios',
      'filipenses',
      'colossenses',
      'tessalonicenses',
      'timóteo',
      'timoteo',
      'tito',
      'filemom',
      'hebreus',
      'tiago',
      'pedro',
      'judas',
      'apocalipse',
      'salmos',
      'provérbios',
      'proverbios',
      'eclesiastes',
      'cantares',
      'isaías',
      'isaias',
      'jeremias',
      'ezequiel',
    };
    final bare = t
        .replaceFirst(RegExp(r'^\d+\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return ptBooks.contains(bare) ||
        ptBooks.any((b) => bare == b || bare.endsWith(' $b'));
  }

  /// Prefer prefs folder; fall back to book-title language for immediate UI.
  static String chapterWordForDisplay({String? bookTitle}) {
    if (folderIsPortuguese(_cachedFolder)) return 'Capítulo';
    if (bookTitleLooksPortuguese(bookTitle)) return 'Capítulo';
    return _chapterWord;
  }

  static String? _cachedFolder;

  static String chapterBarLabel({
    required String chapterNum,
    String? bookTitle,
  }) =>
      '${chapterWordForDisplay(bookTitle: bookTitle)} - $chapterNum';

  /// Refresh cache from Version selection (`buttonStates`). Call from UI init.
  static Future<void> refreshFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('buttonStates') ?? [];
      String? folder;
      for (final entry in saved) {
        final parts = entry.split(':');
        if (parts.length == 2 &&
            parts[1].contains('DownloadButtonState.active')) {
          folder = parts[0];
          break;
        }
      }
      if (folder == null && BibleInfo.folders.length == 1) {
        folder = BibleInfo.folders.first;
      }
      _cachedFolder = folder;
      _chapterWord = chapterWordForFolder(folder);
    } catch (_) {}
  }
}
