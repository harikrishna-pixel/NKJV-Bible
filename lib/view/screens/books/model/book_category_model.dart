class BookCategoryModel {
  final String categoryId;
  final String categoryTitle;
  final String categoryRefId;

  const BookCategoryModel({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryRefId,
  });

  factory BookCategoryModel.fromJson(Map<String, dynamic> json) {
    return BookCategoryModel(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryTitle: json['categoryTitle']?.toString() ?? '',
      categoryRefId: json['categoryRefId']?.toString() ?? '',
    );
  }
}
