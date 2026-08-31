/// book_num : 1
/// chapter_num : 2
/// content : "textdgjjb nmjkj"
/// notes : "God"
/// book_name : "Genesis"
/// timestamp : "2023-04-27 06:06:24"
/// verse_num : 3
library;

class SaveNotesModel {
  SaveNotesModel({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    String? notes,
    String? bookName,
    String? timestamp,
    String? plaincontent,
    num? verseNum,
  }) {
    _id = id;
    _bookNum = bookNum;
    _chapterNum = chapterNum;
    _content = content;
    _notes = notes;
    _bookName = bookName;
    _timestamp = timestamp;
    _verseNum = verseNum;
    _plaincontent = plaincontent;
  }

  SaveNotesModel.fromJson(dynamic json) {
    _id = json['id'];
    _bookNum = json['book_num'];
    _chapterNum = json['chapter_num'];
    _content = json['content'];
    _notes = json['notes'];
    _bookName = json['book_name'];
    _timestamp = json['timestamp'];
    _verseNum = json['verse_num'];
    _plaincontent = json['plaincontent'];
  }
  int? _id;
  num? _bookNum;
  num? _chapterNum;
  String? _content;
  String? _notes;
  String? _bookName;
  String? _timestamp;
  String? _plaincontent;
  num? _verseNum;
  SaveNotesModel copyWith({
    int? id,
    num? bookNum,
    num? chapterNum,
    String? content,
    String? notes,
    String? bookName,
    String? timestamp,
    String? plaincontent,
    num? verseNum,
  }) =>
      SaveNotesModel(
          id: id ?? _id,
          bookNum: bookNum ?? _bookNum,
          chapterNum: chapterNum ?? _chapterNum,
          content: content ?? _content,
          notes: notes ?? _notes,
          bookName: bookName ?? _bookName,
          timestamp: timestamp ?? _timestamp,
          verseNum: verseNum ?? _verseNum,
          plaincontent: plaincontent ?? _plaincontent);
  int? get id => _id;
  num? get bookNum => _bookNum;
  num? get chapterNum => _chapterNum;
  String? get content => _content;
  String? get notes => _notes;
  String? get bookName => _bookName;
  String? get timestamp => _timestamp;
  String? get plaincontent => _plaincontent;
  num? get verseNum => _verseNum;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['book_num'] = _bookNum;
    map['chapter_num'] = _chapterNum;
    map['content'] = _content;
    map['notes'] = _notes;
    map['book_name'] = _bookName;
    map['timestamp'] = _timestamp;
    map['plaincontent'] = _plaincontent;
    map['verse_num'] = _verseNum;

    return map;
  }
}
