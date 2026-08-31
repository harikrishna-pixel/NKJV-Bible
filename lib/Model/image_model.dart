class ImageModel {
  final String? imageId;
  final String? imageTitle;
  final String? imageUrl;

  ImageModel({this.imageId, this.imageTitle, this.imageUrl});

  // Factory constructor to create an ImageModel from a JSON object
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      imageId: json['image_id'] as String?,
      imageTitle: json['image_title'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  // Method to convert an ImageModel to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'image_title': imageTitle,
      'image_url': imageUrl,
    };
  }

  @override
  String toString() => 'ImageModel(id:$imageId, imageUrl:$imageUrl)';
}
