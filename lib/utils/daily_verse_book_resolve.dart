import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';

/// Additive helpers so Daily Verse book refs match the *active* Bible's
/// `book` / `verse` tables (Catholic numbering differs from NKJV).
/// Does not change Daily Verse scheduling / topic selection logic.

String _normBookKey(String input) {
  var s = input.trim().toLowerCase();
  const mapped = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ý': 'y',
    'ÿ': 'y',
    'ĝ': 'g',
  };
  final buf = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    buf.write(mapped[ch] ?? ch);
  }
  return buf.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Shared canonical key for EN/PT/FR book title aliases.
String? dailyVerseCanonicalBookKey(String title) {
  final n = _normBookKey(title);
  if (n.isEmpty) return null;
  const aliases = <String, String>{
    'genesis': 'genesis',
    'genes': 'genesis',
    'exodus': 'exodus',
    'exodo': 'exodus',
    'exode': 'exodus',
    'leviticus': 'leviticus',
    'levitico': 'leviticus',
    'levitique': 'leviticus',
    'numbers': 'numbers',
    'numeros': 'numbers',
    'nombres': 'numbers',
    'deuteronomy': 'deuteronomy',
    'deuteronomio': 'deuteronomy',
    'deuteronome': 'deuteronomy',
    'joshua': 'joshua',
    'josue': 'joshua',
    'judges': 'judges',
    'juizes': 'judges',
    'juges': 'judges',
    'ruth': 'ruth',
    'rute': 'ruth',
    '1samuel': '1samuel',
    'isamuel': '1samuel',
    '1sm': '1samuel',
    '2samuel': '2samuel',
    'iisamuel': '2samuel',
    '2sm': '2samuel',
    '1kings': '1kings',
    '1reis': '1kings',
    '1rois': '1kings',
    '2kings': '2kings',
    '2reis': '2kings',
    '2rois': '2kings',
    '1chronicles': '1chronicles',
    '1cronicas': '1chronicles',
    '1chroniques': '1chronicles',
    '2chronicles': '2chronicles',
    '2cronicas': '2chronicles',
    '2chroniques': '2chronicles',
    'ezra': 'ezra',
    'esdras': 'ezra',
    'nehemiah': 'nehemiah',
    'neemias': 'nehemiah',
    'nehemie': 'nehemiah',
    'esther': 'esther',
    'ester': 'esther',
    'job': 'job',
    'jo': 'job',
    'psalms': 'psalms',
    'psalm': 'psalms',
    'salmos': 'psalms',
    'psaumes': 'psalms',
    'proverbs': 'proverbs',
    'proverbios': 'proverbs',
    'proverbes': 'proverbs',
    'ecclesiastes': 'ecclesiastes',
    'eclesiastes': 'ecclesiastes',
    'ecclesiaste': 'ecclesiastes',
    'songofsolomon': 'songofsolomon',
    'songofsongs': 'songofsolomon',
    'cantares': 'songofsolomon',
    'cantique': 'songofsolomon',
    'cantiquedescantiques': 'songofsolomon',
    'isaiah': 'isaiah',
    'isaias': 'isaiah',
    'esaie': 'isaiah',
    'jeremiah': 'jeremiah',
    'jeremias': 'jeremiah',
    'jeremie': 'jeremiah',
    'lamentations': 'lamentations',
    'lamentacoes': 'lamentations',
    'ezekiel': 'ezekiel',
    'ezequiel': 'ezekiel',
    'ezechiel': 'ezekiel',
    'daniel': 'daniel',
    'hosea': 'hosea',
    'oseias': 'hosea',
    'osee': 'hosea',
    'joel': 'joel',
    'amos': 'amos',
    'obadiah': 'obadiah',
    'obadias': 'obadiah',
    'abdias': 'obadiah',
    'jonah': 'jonah',
    'jonas': 'jonah',
    'micah': 'micah',
    'miqueias': 'micah',
    'michee': 'micah',
    'nahum': 'nahum',
    'naum': 'nahum',
    'habakkuk': 'habakkuk',
    'habacuque': 'habakkuk',
    'habacuc': 'habakkuk',
    'zephaniah': 'zephaniah',
    'sofonias': 'zephaniah',
    'sophonie': 'zephaniah',
    'haggai': 'haggai',
    'ageu': 'haggai',
    'aggee': 'haggai',
    'zechariah': 'zechariah',
    'zacarias': 'zechariah',
    'zacharie': 'zechariah',
    'malachi': 'malachi',
    'malaquias': 'malachi',
    'malachie': 'malachi',
    'matthew': 'matthew',
    'mateus': 'matthew',
    'matthieu': 'matthew',
    'mark': 'mark',
    'marcos': 'mark',
    'marc': 'mark',
    'luke': 'luke',
    'lucas': 'luke',
    'luc': 'luke',
    'john': 'john',
    'joao': 'john',
    'jean': 'john',
    'acts': 'acts',
    'actsoftheapostles': 'acts',
    'atos': 'acts',
    'atosdosapostolos': 'acts',
    'actes': 'acts',
    'romans': 'romans',
    'romanos': 'romans',
    'romains': 'romans',
    '1corinthians': '1corinthians',
    '1corintios': '1corinthians',
    '1corinthiens': '1corinthians',
    '2corinthians': '2corinthians',
    '2corintios': '2corinthians',
    '2corinthiens': '2corinthians',
    'galatians': 'galatians',
    'galatas': 'galatians',
    'galates': 'galatians',
    'ephesians': 'ephesians',
    'efesios': 'ephesians',
    'ephesiens': 'ephesians',
    'philippians': 'philippians',
    'filipenses': 'philippians',
    'philippiens': 'philippians',
    'colossians': 'colossians',
    'colossenses': 'colossians',
    'colossiens': 'colossians',
    '1thessalonians': '1thessalonians',
    '1tessalonicenses': '1thessalonians',
    '1thessaloniciens': '1thessalonians',
    '2thessalonians': '2thessalonians',
    '2tessalonicenses': '2thessalonians',
    '2thessaloniciens': '2thessalonians',
    '1timothy': '1timothy',
    '1timoteo': '1timothy',
    '1timothee': '1timothy',
    '2timothy': '2timothy',
    '2timoteo': '2timothy',
    '2timothee': '2timothy',
    'titus': 'titus',
    'tito': 'titus',
    'tite': 'titus',
    'philemon': 'philemon',
    'filemom': 'philemon',
    'hebrews': 'hebrews',
    'hebreus': 'hebrews',
    'hebreux': 'hebrews',
    'james': 'james',
    'tiago': 'james',
    'jacques': 'james',
    '1peter': '1peter',
    '1pedro': '1peter',
    '1pierre': '1peter',
    '2peter': '2peter',
    '2pedro': '2peter',
    '2pierre': '2peter',
    '1john': '1john',
    '1joao': '1john',
    '1jean': '1john',
    '2john': '2john',
    '2joao': '2john',
    '2jean': '2john',
    '3john': '3john',
    '3joao': '3john',
    '3jean': '3john',
    'jude': 'jude',
    'judas': 'jude',
    'revelation': 'revelation',
    'apocalypse': 'revelation',
    'apocalipse': 'revelation',
  };
  return aliases[n] ?? n;
}

class DailyVerseBookRef {
  const DailyVerseBookRef({
    required this.bookNum,
    required this.title,
    required this.bookId,
  });

  final int bookNum;
  final String title;
  /// 1-based id stored in dailyVerses* tables (reader uses bookId - 1).
  final int bookId;
}

/// Build title-key → current Bible book lookup once per insert batch.
Future<Map<String, DailyVerseBookRef>> buildDailyVerseBookLookup(
  dynamic dbClient,
) async {
  final map = <String, DailyVerseBookRef>{};
  final rows = await dbClient.rawQuery(
    'SELECT book_num, title FROM book ORDER BY book_num ASC',
  );
  for (final row in rows) {
    final title = row['title']?.toString().trim() ?? '';
    final bookNum = (row['book_num'] as num?)?.toInt();
    if (title.isEmpty || bookNum == null) continue;
    final key = dailyVerseCanonicalBookKey(title);
    if (key == null || key.isEmpty) continue;
    map.putIfAbsent(
      key,
      () => DailyVerseBookRef(
        bookNum: bookNum,
        title: title,
        bookId: bookNum + 1,
      ),
    );
  }
  return map;
}

/// Prefer title match against the active `book` table; fall back to Book_Id.
DailyVerseBookRef? resolveDailyVerseBookRef({
  required Map<String, DailyVerseBookRef> lookup,
  required String? bookTitle,
  required int? bookId,
}) {
  final key = dailyVerseCanonicalBookKey(bookTitle ?? '');
  if (key != null && lookup.containsKey(key)) {
    return lookup[key];
  }
  if (bookId == null) return null;
  final fallbackNum = dailyVerseBookNum(bookId);
  for (final ref in lookup.values) {
    if (ref.bookNum == fallbackNum) return ref;
  }
  return DailyVerseBookRef(
    bookNum: fallbackNum,
    title: (bookTitle ?? '').trim().isNotEmpty ? bookTitle!.trim() : 'Unknown',
    bookId: bookId > 0 ? bookId : fallbackNum + 1,
  );
}

/// Async open-path resolve: map stored Daily Verse book → reader book_num.
Future<int> resolveDailyVerseReaderBookNum({
  required num? bookId,
  required String? bookTitle,
}) async {
  final fallback = dailyVerseBookNum(bookId);
  try {
    final db = await DBHelper().db;
    if (db == null) return fallback;
    final lookup = await buildDailyVerseBookLookup(db);
    final resolved = resolveDailyVerseBookRef(
      lookup: lookup,
      bookTitle: bookTitle,
      bookId: bookId?.toInt(),
    );
    return resolved?.bookNum ?? fallback;
  } catch (_) {
    return fallback;
  }
}

/// Localized book title for the active Bible (for newly generated rows).
Future<String> resolveDailyVerseReaderBookTitle({
  required String? bookTitle,
  required num? bookId,
}) async {
  final fallback = (bookTitle ?? '').trim();
  try {
    final db = await DBHelper().db;
    if (db == null) return fallback;
    final lookup = await buildDailyVerseBookLookup(db);
    final resolved = resolveDailyVerseBookRef(
      lookup: lookup,
      bookTitle: bookTitle,
      bookId: bookId?.toInt(),
    );
    return resolved?.title ?? fallback;
  } catch (_) {
    return fallback;
  }
}
