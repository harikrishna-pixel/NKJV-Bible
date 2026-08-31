class BookModel {
  final String bookId;
  final String bookName;
  final String storeTitle;
  final String bookUrl;
  final String bookPublishedBy;
  final String bookDescription;
  final String bookAge;
  final String bookThumbURL;

  BookModel({
    required this.bookId,
    required this.bookName,
    required this.storeTitle,
    required this.bookUrl,
    required this.bookPublishedBy,
    required this.bookDescription,
    required this.bookAge,
    required this.bookThumbURL,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      bookId: json['book_id'] as String,
      bookName: json['book_name'] as String,
      storeTitle: json['storeTitle'] as String,
      bookUrl: json['book_url'] as String,
      bookPublishedBy: json['book_published_by'] as String,
      bookDescription: json['book_description'] as String,
      bookAge: json['book_age'] as String,
      bookThumbURL: json['bookThumbURL'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_name': bookName,
      'storeTitle': storeTitle,
      'book_url': bookUrl,
      'book_published_by': bookPublishedBy,
      'book_description': bookDescription,
      'book_age': bookAge,
      'bookThumbURL': bookThumbURL,
    };
  }
}
