import 'package:biblebookapp/controller/dpProvider.dart';

/// Resolves Daily Verse / JSON English book names to the active Bible's
/// `book_num`. Prefer name match (works across NKJV ↔ Catholic); fall back to
/// Protestant `Book_Id - 1` when unresolved.
class BibleBookResolve {
  static List<Map<String, dynamic>>? _bookRowsCache;

  static void clearCache() {
    _bookRowsCache = null;
  }

  /// ASCII-folded lowercase for accent-insensitive matching.
  static String fold(String input) {
    var s = input.toLowerCase().trim();
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// English Daily Verse book → match tokens against title / short_title / ntitle.
  static const Map<String, List<String>> _englishAliases = {
    'genesis': ['genesis'],
    'exodus': ['exodus', 'exodo'],
    'leviticus': ['leviticus', 'levitico'],
    'numbers': ['numbers', 'numeros'],
    'deuteronomy': ['deuteronomy', 'deuteronomio'],
    'joshua': ['joshua', 'josue'],
    'judges': ['judges', 'juizes'],
    'ruth': ['ruth', 'rute'],
    '1 samuel': ['1 samuel'],
    '2 samuel': ['2 samuel'],
    '1 kings': ['1 kings', '1 reis'],
    '2 kings': ['2 kings', '2 reis'],
    '1 chronicles': ['1 chronicles', '1 cronicas'],
    '2 chronicles': ['2 chronicles', '2 cronicas'],
    'ezra': ['ezra', 'esdras'],
    'nehemiah': ['nehemiah', 'neemias'],
    'esther': ['esther', 'ester'],
    'job': ['job', 'jo'],
    'psalm': ['psalm', 'psalms', 'salmos'],
    'psalms': ['psalm', 'psalms', 'salmos'],
    'proverbs': ['proverbs', 'proverbios'],
    'ecclesiastes': ['ecclesiastes', 'eclesiastes'],
    'song of solomon': ['song of solomon', 'song of songs', 'canticos', 'canticles'],
    'isaiah': ['isaiah', 'isaias'],
    'jeremiah': ['jeremiah', 'jeremias'],
    'lamentations': ['lamentations', 'lamentacoes'],
    'ezekiel': ['ezekiel', 'ezequiel'],
    'daniel': ['daniel'],
    'hosea': ['hosea', 'oseias'],
    'joel': ['joel'],
    'amos': ['amos'],
    'obadiah': ['obadiah', 'abdias'],
    'jonah': ['jonah', 'jonas'],
    'micah': ['micah', 'miqueias'],
    'nahum': ['nahum', 'naum'],
    'habakkuk': ['habakkuk', 'habacuc'],
    'zephaniah': ['zephaniah', 'sofonias'],
    'haggai': ['haggai', 'ageu'],
    'zechariah': ['zechariah', 'zacarias'],
    'malachi': ['malachi', 'malaquias'],
    'matthew': ['matthew', 'mateus'],
    'mark': ['mark', 'marcos'],
    'luke': ['luke', 'lucas'],
    'john': ['john', 'joao'],
    'acts': ['acts', 'atos', 'atos dos apostolos'],
    'romans': ['romans', 'romanos'],
    '1 corinthians': ['1 corinthians', '1 corintios'],
    '2 corinthians': ['2 corinthians', '2 corintios'],
    'galatians': ['galatians', 'galatas'],
    'ephesians': ['ephesians', 'efesios'],
    'philippians': ['philippians', 'filipenses'],
    'colossians': ['colossians', 'colossenses'],
    '1 thessalonians': ['1 thessalonians', '1 tessalonicenses'],
    '2 thessalonians': ['2 thessalonians', '2 tessalonicenses'],
    '1 timothy': ['1 timothy', '1 timoteo'],
    '2 timothy': ['2 timothy', '2 timoteo'],
    'titus': ['titus', 'tito'],
    'philemon': ['philemon', 'filemon'],
    'hebrews': ['hebrews', 'hebreus'],
    'james': ['james', 'tiago'],
    '1 peter': ['1 peter', '1 pedro'],
    '2 peter': ['2 peter', '2 pedro'],
    '1 john': ['1 john', '1 joao'],
    '2 john': ['2 john', '2 joao'],
    '3 john': ['3 john', '3 joao'],
    'jude': ['jude', 'judas'],
    'revelation': ['revelation', 'apocalipse', 'apocalypse'],
  };

  static Future<List<Map<String, dynamic>>> _bookRows(dynamic db) async {
    if (_bookRowsCache != null) return _bookRowsCache!;
    final client = db ?? await DBHelper().db;
    if (client == null) return const [];
    final rows = await client.rawQuery('SELECT * FROM book');
    _bookRowsCache = rows;
    return rows;
  }

  /// Match English Daily Verse [Book] to active Bible `book_num`, or null.
  static Future<int?> bookNumForEnglishBookName(
    String? bookName, {
    dynamic db,
  }) async {
    final name = (bookName ?? '').trim();
    if (name.isEmpty) return null;
    final rows = await _bookRows(db);
    if (rows.isEmpty) return null;

    final foldedName = fold(name);
    final aliases = <String>{
      foldedName,
      ...?_englishAliases[foldedName],
    };

    for (final row in rows) {
      final title = fold(row['title']?.toString() ?? '');
      final shortTitle = fold(row['short_title']?.toString() ?? '');
      final ntitle = fold(row['ntitle']?.toString() ?? '');
      final fields = <String>{title, shortTitle, ntitle};
      for (final a in aliases) {
        if (a.isEmpty) continue;
        if (fields.contains(a)) {
          return int.tryParse(row['book_num'].toString());
        }
        // "Atos dos Apostolos" contains atos — only for multi-word aliases.
        if (a.contains(' ') && title == a) {
          return int.tryParse(row['book_num'].toString());
        }
      }
      // Acts special: title may be longer Portuguese form.
      if (aliases.contains('acts') || aliases.contains('atos')) {
        if (title.startsWith('atos')) {
          return int.tryParse(row['book_num'].toString());
        }
      }
    }

    // Second pass: alias equals any field token / starts with.
    for (final row in rows) {
      final title = fold(row['title']?.toString() ?? '');
      final ntitle = fold(row['ntitle']?.toString() ?? '');
      for (final a in aliases) {
        if (a.isEmpty || a.length < 3) continue;
        if (title == a || ntitle == a) {
          return int.tryParse(row['book_num'].toString());
        }
      }
    }
    return null;
  }

  /// Protestant 1-based Daily Verse [Book_Id] → English book name (stable across Bibles).
  static const Map<int, String> protestantBookIdToEnglish = {
    1: 'Genesis',
    2: 'Exodus',
    3: 'Leviticus',
    4: 'Numbers',
    5: 'Deuteronomy',
    6: 'Joshua',
    7: 'Judges',
    8: 'Ruth',
    9: '1 Samuel',
    10: '2 Samuel',
    11: '1 Kings',
    12: '2 Kings',
    13: '1 Chronicles',
    14: '2 Chronicles',
    15: 'Ezra',
    16: 'Nehemiah',
    17: 'Esther',
    18: 'Job',
    19: 'Psalm',
    20: 'Proverbs',
    21: 'Ecclesiastes',
    22: 'Song of Solomon',
    23: 'Isaiah',
    24: 'Jeremiah',
    25: 'Lamentations',
    26: 'Ezekiel',
    27: 'Daniel',
    28: 'Hosea',
    29: 'Joel',
    30: 'Amos',
    31: 'Obadiah',
    32: 'Jonah',
    33: 'Micah',
    34: 'Nahum',
    35: 'Habakkuk',
    36: 'Zephaniah',
    37: 'Haggai',
    38: 'Zechariah',
    39: 'Malachi',
    40: 'Matthew',
    41: 'Mark',
    42: 'Luke',
    43: 'John',
    44: 'Acts',
    45: 'Romans',
    46: '1 Corinthians',
    47: '2 Corinthians',
    48: 'Galatians',
    49: 'Ephesians',
    50: 'Philippians',
    51: 'Colossians',
    52: '1 Thessalonians',
    53: '2 Thessalonians',
    54: '1 Timothy',
    55: '2 Timothy',
    56: 'Titus',
    57: 'Philemon',
    58: 'Hebrews',
    59: 'James',
    60: '1 Peter',
    61: '2 Peter',
    62: '1 John',
    63: '2 John',
    64: '3 John',
    65: 'Jude',
    66: 'Revelation',
  };

  /// Prefer English name from [Book_Id]; fall back to stored [Book] label.
  static String? englishNameForDailyVerse({
    String? storedBook,
    num? bookId,
  }) {
    final id = bookId?.toInt();
    if (id != null && protestantBookIdToEnglish.containsKey(id)) {
      return protestantBookIdToEnglish[id];
    }
    final s = storedBook?.trim();
    if (s != null && s.isNotEmpty) return s;
    return null;
  }

  /// Safe Daily Verse book_num: name first, then Protestant `Book_Id - 1`.
  static Future<int> bookNumForDailyVerse({
    required String? bookName,
    required num? bookId,
    dynamic db,
  }) async {
    final english = englishNameForDailyVerse(
          storedBook: bookName,
          bookId: bookId,
        ) ??
        bookName;
    final byName = await bookNumForEnglishBookName(english, db: db);
    if (byName != null) return byName;
    final id = (bookId ?? 0).toInt();
    return id > 0 ? id - 1 : 0;
  }

  static Future<String?> titleForBookNum(int bookNum, {dynamic db}) async {
    final rows = await _bookRows(db);
    for (final row in rows) {
      if (int.tryParse(row['book_num'].toString()) == bookNum) {
        final t = row['title']?.toString().trim();
        if (t != null && t.isNotEmpty) return t;
      }
    }
    return null;
  }

  /// 0-based verse-table indices used by existing Daily Verse inserts.
  static (int chapterNum, int verseNum) dailyVerseDbChapterVerse({
    required int chapter1Based,
    required String verseRaw,
  }) {
    final verseNum = verseRaw.length == 2
        ? int.parse(verseRaw) - 1
        : int.parse(verseRaw.split('-').first) - 1;
    final chapterNum = chapter1Based > 0 ? chapter1Based - 1 : 0;
    return (chapterNum, verseNum);
  }

  /// Look up verse row for a Daily Verse main-list entry (name-based book_num).
  static Future<List<Map<String, dynamic>>> lookupVerseRowsForDailyMain({
    required dynamic db,
    required String? bookName,
    required int bookId,
    required int chapter1Based,
    required String verseRaw,
  }) async {
    final bookNum = await bookNumForDailyVerse(
      bookName: bookName,
      bookId: bookId,
      db: db,
    );
    final indices = dailyVerseDbChapterVerse(
      chapter1Based: chapter1Based,
      verseRaw: verseRaw,
    );
    final rows = await db.rawQuery(
      'SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?',
      [bookNum, indices.$1, indices.$2],
    );
    return List<Map<String, dynamic>>.from(rows);
  }
}
