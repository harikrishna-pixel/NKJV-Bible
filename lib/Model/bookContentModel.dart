/// book_num : 0
/// chapter_num : 0
/// content : "In the beginning God created the heavens and the earth."
/// verse_num : 0
library;

class BookContentModel {
  BookContentModel({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    num? verseNum,
  }) {
    _id = id;
    _bookNum = bookNum;
    _chapterNum = chapterNum;
    _content = content;
    _verseNum = verseNum;
  }

  BookContentModel.fromJson(dynamic json) {
    _id = json["id"];
    _bookNum = json['book_num'];
    _chapterNum = json['chapter_num'];
    _content = json['content'];
    _verseNum = json['verse_num'];
  }
  int? _id;
  num? _bookNum;
  num? _chapterNum;
  String? _content;
  num? _verseNum;
  BookContentModel copyWith({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    num? verseNum,
  }) =>
      BookContentModel(
        id: id ?? _id,
        bookNum: bookNum ?? _bookNum,
        chapterNum: chapterNum ?? _chapterNum,
        content: content ?? _content,
        verseNum: verseNum ?? _verseNum,
      );
  int? get id => _id;
  num? get bookNum => _bookNum;
  num? get chapterNum => _chapterNum;
  String? get content => _content;
  num? get verseNum => _verseNum;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['book_num'] = _bookNum;
    map['chapter_num'] = _chapterNum;
    map['content'] = _content;
    map['verse_num'] = _verseNum;
    return map;
  }
}
