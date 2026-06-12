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

/// DB stores 0-based verse_num; UI shows 1-based verse numbers.
int displayVerseNumber(VerseBookContentModel verse, {int listIndex = 0}) {
  final stored = verse.verseNum;
  if (stored != null) return stored.toInt() + 1;
  return listIndex + 1;
}
