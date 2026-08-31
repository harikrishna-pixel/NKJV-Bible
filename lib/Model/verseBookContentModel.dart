/// book_num : 0
/// chapter_num : 0
/// content : "And God said, Let the waters under the heavens be gathered together unto one place, and let the dry land appear: and it was so."
/// is_bookmarked : "no"
/// is_highlighted : "no"
/// is_noted : "no"
/// is_read : "no"
/// is_underlined : "no"
/// verse_num : 8
library;

class VerseBookContentModel {
  VerseBookContentModel({
    int? id,
    num? bookNum,
    num? chapterNum,
    dynamic content,
    String? isBookmarked,
    String? isHighlighted,
    String? isNoted,
    String? isRead,
    String? isUnderlined,
    num? verseNum,
  }) {
    _id = id;
    _bookNum = bookNum;
    _chapterNum = chapterNum;
    _content = content;
    _isBookmarked = isBookmarked;
    _isHighlighted = isHighlighted;
    _isNoted = isNoted;
    _isRead = isRead;
    _isUnderlined = isUnderlined;
    _verseNum = verseNum;
  }

  VerseBookContentModel.fromJson(dynamic json) {
    _id = json['id'];
    _bookNum = json['book_num'];
    _chapterNum = json['chapter_num'];
    _content = json['content'];
    _isBookmarked = json['is_bookmarked'];
    _isHighlighted = json['is_highlighted'];
    _isNoted = json['is_noted'];
    _isRead = json['is_read'];
    _isUnderlined = json['is_underlined'];
    _verseNum = json['verse_num'];
  }
  int? _id;
  num? _bookNum;
  num? _chapterNum;
  dynamic _content;
  String? _isBookmarked;
  String? _isHighlighted;
  String? _isNoted;
  String? _isRead;
  String? _isUnderlined;
  num? _verseNum;
  VerseBookContentModel copyWith({
    int? id,
    num? bookNum,
    num? chapterNum,
    dynamic content,
    String? isBookmarked,
    String? isHighlighted,
    String? isNoted,
    String? isRead,
    String? isUnderlined,
    num? verseNum,
  }) =>
      VerseBookContentModel(
        id: id ?? _id,
        bookNum: bookNum ?? _bookNum,
        chapterNum: chapterNum ?? _chapterNum,
        content: content ?? _content,
        isBookmarked: isBookmarked ?? _isBookmarked,
        isHighlighted: isHighlighted ?? _isHighlighted,
        isNoted: isNoted ?? _isNoted,
        isRead: isRead ?? _isRead,
        isUnderlined: isUnderlined ?? _isUnderlined,
        verseNum: verseNum ?? _verseNum,
      );
  int? get id => _id;
  num? get bookNum => _bookNum;
  num? get chapterNum => _chapterNum;
  dynamic get content => _content;
  String? get isBookmarked => _isBookmarked;
  String? get isHighlighted => _isHighlighted;
  String? get isNoted => _isNoted;
  String? get isRead => _isRead;
  String? get isUnderlined => _isUnderlined;
  num? get verseNum => _verseNum;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['book_num'] = _bookNum;
    map['chapter_num'] = _chapterNum;
    map['content'] = _content;
    map['is_bookmarked'] = _isBookmarked;
    map['is_highlighted'] = _isHighlighted;
    map['is_noted'] = _isNoted;
    map['is_read'] = _isRead;
    map['is_underlined'] = _isUnderlined;
    map['verse_num'] = _verseNum;
    return map;
  }
}

bool isSame(VerseBookContentModel item1, VerseBookContentModel item2) =>
    item1.bookNum == item2.bookNum &&
    item1.chapterNum == item2.chapterNum &&
    item1.verseNum == item2.verseNum;

List<VerseBookContentModel> filterContent(
    List<VerseBookContentModel> contents) {
  List<VerseBookContentModel> filteredContent = [];
  for (var content in contents) {
    final index = filteredContent.indexWhere((e) => isSame(content, e));
    if (index == -1) {
      filteredContent = [...filteredContent, content];
    }
  }
  filteredContent.sort((a, b) {
    final av = a.verseNum ?? 0;
    final bv = b.verseNum ?? 0;
    return av.compareTo(bv);
  });
  return filteredContent;
}

/// Normalizes verse HTML/plain text for content comparison.
String normalizeVersePlainText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final withoutTags = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return withoutTags
      .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
      .replaceAll(RegExp(r'&quot;'), '"')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'&lt;'), '<')
      .replaceAll(RegExp(r'&gt;'), '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}

/// DB stores 0-based verse_num; UI shows 1-based verse numbers.
int displayVerseNumber(VerseBookContentModel verse, {int listIndex = 0}) {
  final stored = verse.verseNum;
  if (stored != null) return stored.toInt() + 1;
  return listIndex + 1;
}

/// Reader `book_num` from daily [Book_Id] (same as splash daily-verse DB lookup).
int dailyVerseBookNum(num? bookId) {
  final id = (bookId ?? 0).toInt();
  return id > 0 ? id - 1 : 0;
}

/// Reader UI chapter from daily stored [Chapter] (1-based bible chapter).
int dailyVerseUiChapter(num? chapter) {
  final ch = (chapter ?? 0).toInt();
  return ch > 0 ? ch : 1;
}

/// Reader UI verse from daily stored [Verse_Num] (1-based bible verse).
int dailyVerseUiVerse(num? verseNum) {
  final v = (verseNum ?? 0).toInt();
  return v > 0 ? v : 1;
}

/// Reader DB `verse_num` from daily [Verse_Num] (stored 1-based in dailyVerses).
int dailyVerseDbVerseNum(num? verseNum) {
  final v = (verseNum ?? 0).toInt();
  return v > 0 ? v - 1 : 0;
}

/// Maps daily [Verse_Num] to reader list index.
/// Book/chapter are loaded separately; this finds the matching verse row.
int resolveDailyVerseListIndex(
  int dailyVerseNum,
  List<VerseBookContentModel> chapterContent, {
  String? versePlainText,
}) {
  if (chapterContent.isEmpty) {
    return dailyVerseNum < 0 ? 0 : dailyVerseNum;
  }

  final normalizedHint = normalizeVersePlainText(versePlainText);
  if (normalizedHint.length >= 8) {
    for (var i = 0; i < chapterContent.length; i++) {
      final row =
          normalizeVersePlainText(chapterContent[i].content?.toString());
      if (row.isNotEmpty && row == normalizedHint) {
        return i;
      }
    }
    final hintPrefix =
        normalizedHint.length > 40 ? normalizedHint.substring(0, 40) : normalizedHint;
    for (var i = 0; i < chapterContent.length; i++) {
      final row =
          normalizeVersePlainText(chapterContent[i].content?.toString());
      if (row.isEmpty) continue;
      final rowPrefix = row.length > 40 ? row.substring(0, 40) : row;
      if (row.startsWith(hintPrefix) || hintPrefix.startsWith(rowPrefix)) {
        return i;
      }
    }
  }

  // Verse_Num stored 0-based (matches DB verse_num) — try before subtracting 1.
  for (var i = 0; i < chapterContent.length; i++) {
    if (chapterContent[i].verseNum?.toInt() == dailyVerseNum) return i;
  }

  // Verse_Num stored 1-based (splash insert) -> DB verse_num is Verse_Num - 1.
  final dbVerse = dailyVerseDbVerseNum(dailyVerseNum);
  for (var i = 0; i < chapterContent.length; i++) {
    if (chapterContent[i].verseNum?.toInt() == dbVerse) return i;
  }

  final dailyDisplayVerse = dailyVerseNum + 1;
  for (var i = 0; i < chapterContent.length; i++) {
    if (displayVerseNumber(chapterContent[i], listIndex: i) ==
        dailyDisplayVerse) {
      return i;
    }
  }

  return dailyVerseNum.clamp(0, chapterContent.length - 1);
}
