import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;

/// Display-only bible version label for My Library cards.
/// Infers NKJV vs Catholic from saved book name / verse text (no DB changes).
String libraryBibleVersionLabel({
  String? bookName,
  String? content,
}) {
  final book = (bookName ?? '').trim().toLowerCase();
  final plain = _plain(content).toLowerCase();
  final haystack = '$book $plain';

  if (_looksPortugueseCatholic(haystack, book)) {
    return 'Catholic';
  }
  return 'NKJV';
}

String _plain(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  try {
    return parse(raw).body?.text ?? raw;
  } catch (_) {
    return raw;
  }
}

bool _looksPortugueseCatholic(String haystack, String book) {
  // Accented Portuguese characters common in Catholic PT text.
  if (RegExp(r'[ãáàâäéêíóôõúçñ]', caseSensitive: false).hasMatch(haystack)) {
    return true;
  }

  const ptBooks = <String>{
    'gênesis',
    'genesis', // ambiguous — check with content below
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
    'rute',
    '1 samuel',
    '2 samuel',
    '1 reis',
    '2 reis',
    '1 crônicas',
    '2 crônicas',
    '1 cronicas',
    '2 cronicas',
    'esdras',
    'neemias',
    'tobias',
    'judite',
    'ester',
    'jó',
    'salmos',
    'provérbios',
    'proverbios',
    'eclesiastes',
    'cântico',
    'cantico',
    'sabedoria',
    'eclesiástico',
    'eclesiastico',
    'isaías',
    'isaias',
    'jeremias',
    'lamentações',
    'lamentacoes',
    'baruque',
    'ezequiel',
    'daniel',
    'oséias',
    'oseias',
    'joel',
    'amós',
    'amos',
    'obadias',
    'jonas',
    'miquéias',
    'miqueias',
    'naum',
    'habacuque',
    'habacuc',
    'sofonias',
    'ageu',
    'zacarias',
    'malaquias',
    'mateus',
    'marcos',
    'lucas',
    'joão',
    'joao',
    'atos',
    'romanos',
    '1 coríntios',
    '2 coríntios',
    '1 corintios',
    '2 corintios',
    'gálatas',
    'galatas',
    'efésios',
    'efesios',
    'filipenses',
    'colossenses',
    '1 tessalonicenses',
    '2 tessalonicenses',
    '1 timóteo',
    '2 timóteo',
    '1 timoteo',
    '2 timoteo',
    'tito',
    'filemom',
    'hebreus',
    'tiago',
    '1 pedro',
    '2 pedro',
    '1 joão',
    '2 joão',
    '3 joão',
    '1 joao',
    '2 joao',
    '3 joao',
    'judas',
    'apocalipse',
  };

  if (ptBooks.contains(book)) {
    // Shared spellings (e.g. Daniel, Joel) — confirm with Portuguese cues.
    const shared = {
      'daniel',
      'joel',
      'amos',
      'amós',
      'ester',
      'jonas',
      'naum',
      'ageu',
      'tito',
      'lucas',
      'marcos',
      'atos',
      'romanos',
    };
    if (shared.contains(book)) {
      return _hasPortugueseCue(haystack);
    }
    // Distinct PT titles (Zacarias, Sofonias, Josué, Mateus, etc.).
    if (book.contains('gên') ||
        book.contains('êx') ||
        book.contains('crôn') ||
        book.contains('cron') ||
        book.contains('josué') ||
        book.contains('josue') ||
        book.contains('zacarias') ||
        book.contains('sofonias') ||
        book.contains('mateus') ||
        book.contains('joão') ||
        book.contains('joao') ||
        book.contains('apocalipse') ||
        book.contains('miquéias') ||
        book.contains('miqueias') ||
        book.contains('habacu') ||
        book.contains('malaquias') ||
        book.contains('provér') ||
        book.contains('proverb') ||
        book.contains('salmos') ||
        book.contains('hebreus') ||
        book.contains('tiago') ||
        book.contains('filipenses') ||
        book.contains('colossenses') ||
        book.contains('gálatas') ||
        book.contains('galatas') ||
        book.contains('efésios') ||
        book.contains('efesios') ||
        book.contains('corínt') ||
        book.contains('corint') ||
        book.contains('tessalonic') ||
        book.contains('timót') ||
        book.contains('timot') ||
        book.contains('filemom') ||
        book.contains('juízes') ||
        book.contains('juizes') ||
        book.contains('reis') ||
        book.contains('neemias') ||
        book.contains('esdras') ||
        book.contains('tobias') ||
        book.contains('judite') ||
        book.contains('sabedoria') ||
        book.contains('eclesi') ||
        book.contains('baruque') ||
        book.contains('lamenta') ||
        book.contains('obadias') ||
        book.contains('oséia') ||
        book.contains('oseia') ||
        book.contains('isaía') ||
        book.contains('isaia') ||
        book.contains('jeremias') ||
        book.contains('ezequiel') ||
        book.contains('números') ||
        book.contains('numeros') ||
        book.contains('deuteron') ||
        book.contains('levít') ||
        book.contains('levit') ||
        book.contains('rute') ||
        book.contains('cântico') ||
        book.contains('cantico') ||
        book.contains('pedro') ||
        book.contains('judas') ||
        book.contains('1 samuel') ||
        book.contains('2 samuel')) {
      return true;
    }
    return _hasPortugueseCue(haystack);
  }

  return _hasPortugueseCue(haystack);
}

bool _hasPortugueseCue(String haystack) {
  const cues = <String>[
    'deus ',
    'senhor',
    'princípio',
    'principio',
    'criou',
    'filhos',
    'disse',
    'porque',
    'também',
    'tambem',
    'não ',
    'nao ',
    'vosso',
    'vossa',
    'espírito',
    'espirito',
    'coração',
    'coracao',
    'palavra',
    'terra',
    'céus',
    'ceus',
    'homens',
    'mulher',
    'jerusalém',
    'jerusalem',
  ];
  for (final cue in cues) {
    if (haystack.contains(cue)) return true;
  }
  return false;
}

/// Small corner chip for My Library list cards.
class LibraryBibleVersionChip extends StatelessWidget {
  const LibraryBibleVersionChip({
    super.key,
    this.bookName,
    this.content,
  });

  final String? bookName;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final label = libraryBibleVersionLabel(
      bookName: bookName,
      content: content,
    );
    final isCatholic = label == 'Catholic';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCatholic
            ? const Color(0xFFE8F0E6)
            : const Color(0xFFF3EADF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CommanColor.lightDarkPrimary(context).withOpacity(0.35),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CommanColor.lightDarkPrimary(context),
          height: 1.1,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
