/// book_num : 1
/// chapter_num : 2
/// content : "fgdfhfg fghf"
/// book_name : "fgdfhfg fghf"
/// color : "Color(0xffffff)"
/// timestamp : "2023-04-26 08:04:50"
/// verse_num : 5
library;

class HighLightContentModal {
  HighLightContentModal({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    String? plain_content,
    String? verseid,
    String? bookName,
    String? color,
    String? timestamp,
    num? verseNum,
  }) {
    _id = id;
    _bookNum = bookNum;
    _chapterNum = chapterNum;
    _content = content;
    _verseid = verseid;
    _bookName = bookName;
    _color = color;
    _timestamp = timestamp;
    _verseNum = verseNum;
    _plaincontent = plain_content;
  }

  HighLightContentModal.fromJson(dynamic json) {
    _id = json['id'];
    _bookNum = json['book_num'];
    _chapterNum = json['chapter_num'];
    _content = json['content'];
    _bookName = json['book_name'];
    _color = json['color'];
    _timestamp = json['timestamp'];
    _verseNum = json['verse_num'];
    _plaincontent = json['plain_content'];
    _verseid = json['verse_id'];
  }
  int? _id;
  num? _bookNum;
  num? _chapterNum;
  String? _content;
  String? _plaincontent;
  String? _verseid;
  String? _bookName;
  String? _color;
  String? _timestamp;
  num? _verseNum;
  HighLightContentModal With({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    String? plain_content,
    String? verseid,
    String? bookName,
    String? color,
    String? timestamp,
    num? verseNum,
  }) =>
      HighLightContentModal(
          id: id ?? _id,
          bookNum: bookNum ?? _bookNum,
          chapterNum: chapterNum ?? _chapterNum,
          content: content ?? _content,
          bookName: bookName ?? _bookName,
          color: color ?? _color,
          timestamp: timestamp ?? _timestamp,
          verseNum: verseNum ?? _verseNum,
          plain_content: plain_content ?? _plaincontent,
          verseid: verseid ?? _verseid);
  int? get id => _id;
  num? get bookNum => _bookNum;
  num? get chapterNum => _chapterNum;
  String? get content => _content;
  String? get plain_content => _plaincontent;
  String? get verseid => _verseid;
  String? get bookName => _bookName;
  String? get color => _color;
  String? get timestamp => _timestamp;
  num? get verseNum => _verseNum;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['book_num'] = _bookNum;
    map['id'] = _id;
    map['chapter_num'] = _chapterNum;
    map['content'] = _content;
    map['plain_content'] = _plaincontent;
    map['book_name'] = _bookName;
    map['color'] = _color;
    map['timestamp'] = _timestamp;
    map['verse_num'] = _verseNum;
    map['verse_id'] = _verseid;
    return map;
  }
}
