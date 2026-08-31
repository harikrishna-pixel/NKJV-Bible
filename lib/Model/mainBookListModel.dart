/// id : 1
/// book_num : 0
/// chapter_count : 50
/// read_per : "0"
/// short_title : ""
/// title : "Genesis"
library;

class MainBookListModel {
  MainBookListModel({
    int? id,
    num? bookNum,
    num? chapterCount,
    String? readPer,
    String? shortTitle,
    String? title,
  }) {
    _id = id;
    _bookNum = bookNum;
    _chapterCount = chapterCount;
    _readPer = readPer;
    _shortTitle = shortTitle;
    _title = title;
  }

  MainBookListModel.fromJson(dynamic json) {
    _id = json['id'];
    _bookNum = json['book_num'];
    _chapterCount = json['chapter_count'];
    _readPer = json['read_per']?.toString();
    _shortTitle = json['short_title'];
    _title = json['title'];
  }
  int? _id;
  num? _bookNum;
  num? _chapterCount;
  String? _readPer;
  String? _shortTitle;
  String? _title;
  MainBookListModel copyWith({
    int? id,
    num? bookNum,
    num? chapterCount,
    String? readPer,
    String? shortTitle,
    String? title,
  }) =>
      MainBookListModel(
        id: id ?? _id,
        bookNum: bookNum ?? _bookNum,
        chapterCount: chapterCount ?? _chapterCount,
        readPer: readPer ?? _readPer,
        shortTitle: shortTitle ?? _shortTitle,
        title: title ?? _title,
      );
  int? get id => _id;
  num? get bookNum => _bookNum;
  num? get chapterCount => _chapterCount;
  String? get readPer => _readPer;
  String? get shortTitle => _shortTitle;
  String? get title => _title;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['book_num'] = _bookNum;
    map['chapter_count'] = _chapterCount;
    map['read_per'] = _readPer;
    map['short_title'] = _shortTitle;
    map['title'] = _title;
    return map;
  }
}
