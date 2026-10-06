import 'package:biblebookapp/utils/bible_version_config.dart';

/// Display-only labels matched to the active Bible version language.
/// Does not change selection, load, or switch logic.
class BibleUiLabels {
  static String _chapterWord = 'Chapter';

  static String get chapterWord => _chapterWord;

  static String chapterWordForFolder(String? folder) =>
      BibleVersionConfig.forFolder(folder)?.chapterWord ?? 'Chapter';

  /// Sync hint from the current book title when prefs are not loaded yet
  /// (e.g. Tamil script title right after a switch).
  static String? _chapterWordForTitle(String? title) {
    final t = (title ?? '').trim();
    if (t.isEmpty) return null;
    for (final c in BibleVersionConfig.installed) {
      final pattern = c.scriptPattern;
      if (pattern != null && pattern.hasMatch(t)) return c.chapterWord;
    }
    return null;
  }

  /// Prefer prefs folder; fall back to book-title script for immediate UI.
  static String chapterWordForDisplay({String? bookTitle}) {
    final fromFolder =
        BibleVersionConfig.forFolder(BibleVersionConfig.cachedActiveFolder);
    if (fromFolder != null) return fromFolder.chapterWord;
    return _chapterWordForTitle(bookTitle) ?? _chapterWord;
  }

  static String chapterBarLabel({
    required String chapterNum,
    String? bookTitle,
  }) =>
      '${chapterWordForDisplay(bookTitle: bookTitle)} - $chapterNum';

  /// Refresh cache from Version selection (`buttonStates`). Call from UI init.
  static Future<void> refreshFromPrefs() async {
    try {
      final folder = await BibleVersionConfig.activeFolder();
      _chapterWord = chapterWordForFolder(folder);
    } catch (_) {}
  }
}
