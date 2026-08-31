/// id : 1
/// Category_Name : "God's Promises"
/// Category_Id : 14
/// Book : "John"
/// Book_Id : 43
/// Chapter : 3
/// Verse : "ggdfgd"
/// Date : ""
library;

class DailyVerseList {
  DailyVerseList({
    int? id,
    String? categoryName,
    num? categoryId,
    String? book,
    num? bookId,
    num? chapter,
    String? verse,
    String? date,
    int? verseNum,
  }) {
    _id = id;
    _categoryName = categoryName;
    _categoryId = categoryId;
    _book = book;
    _bookId = bookId;
    _chapter = chapter;
    _verse = verse;
    _date = date;
    _verseNum = verseNum;
  }

  DailyVerseList.fromJson(dynamic json) {
    _id = json['id'];
    _categoryName = json['Category_Name'];
    _categoryId = json['Category_Id'];
    _book = json['Book'];
    _bookId = json['Book_Id'];
    _chapter = json['Chapter'];
    _verse = json['Verse'];
    _date = json['Date'];
    _verseNum = json['Verse_Num'];
  }
  int? _id;
  String? _categoryName;
  num? _categoryId;
  String? _book;
  num? _bookId;
  num? _chapter;
  String? _verse;
  String? _date;
  int? _verseNum;
  DailyVerseList copyWith({
    int? id,
    String? categoryName,
    num? categoryId,
    String? book,
    num? bookId,
    num? chapter,
    String? verse,
    String? date,
    int? verseNum,
  }) =>
      DailyVerseList(
        id: id ?? _id,
        categoryName: categoryName ?? _categoryName,
        categoryId: categoryId ?? _categoryId,
        book: book ?? _book,
        bookId: bookId ?? _bookId,
        chapter: chapter ?? _chapter,
        verse: verse ?? _verse,
        date: date ?? _date,
        verseNum: verseNum ?? _verseNum,
      );
  int? get id => _id;
  String? get categoryName => _categoryName;
  num? get categoryId => _categoryId;
  String? get book => _book;
  num? get bookId => _bookId;
  num? get chapter => _chapter;
  String? get verse => _verse;
  String? get date => _date;
  int? get verseNum => _verseNum;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['Category_Name'] = _categoryName;
    map['Category_Id'] = _categoryId;
    map['Book'] = _book;
    map['Book_Id'] = _bookId;
    map['Chapter'] = _chapter;
    map['Verse'] = _verse;
    map['Date'] = _date;
    map['Verse_Num'] = _verseNum;
    return map;
  }
}
