class BookModel {
  final String bookId;
  final String bookName;
  final String storeTitle;
  final String bookUrl;
  final String bookPublishedBy;
  final String bookDescription;
  final String bookAge;
  final String bookThumbURL;
  final String bookPromoImg;
  final String categoryId;
  final String categoryTitle;

  BookModel({
    required this.bookId,
    required this.bookName,
    required this.storeTitle,
    required this.bookUrl,
    required this.bookPublishedBy,
    required this.bookDescription,
    required this.bookAge,
    required this.bookThumbURL,
    this.bookPromoImg = '',
    this.categoryId = '',
    this.categoryTitle = '',
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      bookId: json['book_id']?.toString() ?? '',
      bookName: json['book_name']?.toString() ?? '',
      storeTitle: json['storeTitle']?.toString() ?? '',
      bookUrl: json['book_url']?.toString() ?? '',
      bookPublishedBy: json['book_published_by']?.toString() ?? '',
      bookDescription: json['book_description']?.toString() ?? '',
      bookAge: json['book_age']?.toString() ?? '',
      bookThumbURL: json['bookThumbURL']?.toString() ?? '',
      bookPromoImg: json['book_promo_img']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryTitle: json['categoryTitle']?.toString() ?? '',
    );
  }

  BookModel copyWith({
    String? categoryId,
    String? categoryTitle,
  }) {
    return BookModel(
      bookId: bookId,
      bookName: bookName,
      storeTitle: storeTitle,
      bookUrl: bookUrl,
      bookPublishedBy: bookPublishedBy,
      bookDescription: bookDescription,
      bookAge: bookAge,
      bookThumbURL: bookThumbURL,
      bookPromoImg: bookPromoImg,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
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
      'book_promo_img': bookPromoImg,
      'categoryId': categoryId,
      'categoryTitle': categoryTitle,
    };
  }
}
