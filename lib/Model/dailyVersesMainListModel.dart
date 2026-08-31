/// id : 1
/// Category_Name : "faith-in-hard-times"
/// Category_Id : 5
/// Book : "1 Thessalonians"
/// Book_Id : 52
/// Chapter : 5
/// Verse : "11"
// library;

// class DailyVersesMainListModel {
//   DailyVersesMainListModel({
//     int? id,
//     String? categoryName,
//     num? categoryId,
//     String? book,
//     num? bookId,
//     num? chapter,
//     String? verse,
//   }) {
//     _id = id;
//     _categoryName = categoryName;
//     _categoryId = categoryId;
//     _book = book;
//     _bookId = bookId;
//     _chapter = chapter;
//     _verse = verse;
//   }

//   DailyVersesMainListModel.fromJson(dynamic json) {
//     _id = json['id'];
//     _categoryName = json['Category_Name'];
//     _categoryId = json['Category_Id'];
//     _book = json['Book'];
//     _bookId = json['Book_Id'];
//     _chapter = json['Chapter'];
//     _verse = json['Verse'];
//   }
//   int? _id;
//   String? _categoryName;
//   num? _categoryId;
//   String? _book;
//   num? _bookId;
//   num? _chapter;
//   String? _verse;
//   DailyVersesMainListModel copyWith({
//     int? id,
//     String? categoryName,
//     num? categoryId,
//     String? book,
//     num? bookId,
//     num? chapter,
//     String? verse,
//   }) =>
//       DailyVersesMainListModel(
//         id: id ?? _id,
//         categoryName: categoryName ?? _categoryName,
//         categoryId: categoryId ?? _categoryId,
//         book: book ?? _book,
//         bookId: bookId ?? _bookId,
//         chapter: chapter ?? _chapter,
//         verse: verse ?? _verse,
//       );
//   int? get id => _id;
//   String? get categoryName => _categoryName;
//   num? get categoryId => _categoryId;
//   String? get book => _book;
//   num? get bookId => _bookId;
//   num? get chapter => _chapter;
//   String? get verse => _verse;

//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['id'] = _id;
//     map['Category_Name'] = _categoryName;
//     map['Category_Id'] = _categoryId;
//     map['Book'] = _book;
//     map['Book_Id'] = _bookId;
//     map['Chapter'] = _chapter;
//     map['Verse'] = _verse;
//     return map;
//   }
// }

library;

class DailyVersesMainListModel {
  DailyVersesMainListModel({
    int? id,
    String? categoryName,
    String? mainCategory,
    num? categoryId,
    String? book,
    num? bookId,
    num? chapter,
    int? verse,
    String? verseDetails,
  }) {
    _id = id;
    _categoryName = categoryName;
    _mainCategory = mainCategory;
    _categoryId = categoryId;
    _book = book;
    _bookId = bookId;
    _chapter = chapter;
    _verse = verse;
    _verseDetails = verseDetails;
  }

  DailyVersesMainListModel.fromJson(dynamic json) {
    _id = json['id'];
    _categoryName = json['Category_Name'];
    _mainCategory = json['Main_Category'];
    _categoryId = json['Category_Id'];
    _book = json['Book'];
    _bookId = json['Book_Id'];
    _chapter = json['Chapter'];

    final verseString = json['Verse']?.toString();
    if (verseString != null && verseString.contains('-')) {
      _verse = int.tryParse(verseString.split('-').first);
    } else {
      _verse = int.tryParse(verseString ?? '');
    }

    _verseDetails = json['Verse_Details'];
  }

  int? _id;
  String? _categoryName;
  String? _mainCategory;
  num? _categoryId;
  String? _book;
  num? _bookId;
  num? _chapter;
  int? _verse;
  String? _verseDetails;

  DailyVersesMainListModel copyWith({
    int? id,
    String? categoryName,
    String? mainCategory,
    num? categoryId,
    String? book,
    num? bookId,
    num? chapter,
    int? verse,
    String? verseDetails,
  }) =>
      DailyVersesMainListModel(
        id: id ?? _id,
        categoryName: categoryName ?? _categoryName,
        mainCategory: mainCategory ?? _mainCategory,
        categoryId: categoryId ?? _categoryId,
        book: book ?? _book,
        bookId: bookId ?? _bookId,
        chapter: chapter ?? _chapter,
        verse: verse ?? _verse,
        verseDetails: verseDetails ?? _verseDetails,
      );

  int? get id => _id;
  String? get categoryName => _categoryName;
  String? get mainCategory => _mainCategory;
  num? get categoryId => _categoryId;
  String? get book => _book;
  num? get bookId => _bookId;
  num? get chapter => _chapter;
  int? get verse => _verse;
  String? get verseDetails => _verseDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['Category_Name'] = _categoryName;
    map['Main_Category'] = _mainCategory;
    map['Category_Id'] = _categoryId;
    map['Book'] = _book;
    map['Book_Id'] = _bookId;
    map['Chapter'] = _chapter;
    map['Verse'] = _verse?.toString();
    map['Verse_Details'] = _verseDetails;
    return map;
  }
}
