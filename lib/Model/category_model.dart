class CategoryModel {
  final String? id;
  final String? name;
  final String? thumbnail;
  CategoryModel({this.id, this.name, this.thumbnail});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id'] as String?,
      name: json['category_name'] as String?,
      thumbnail: json['cat_thumb_img_url'] as String?,
    );
  }
}
