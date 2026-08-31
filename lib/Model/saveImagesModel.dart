/// id : 1
/// image_path : "hjgfhj"
library;

class SaveImageModel {
  SaveImageModel({
    int? id,
    String? imagePath,
  }) {
    _id = id;
    _imagePath = imagePath;
  }

  SaveImageModel.fromJson(dynamic json) {
    _id = json['id'];
    _imagePath = json['image_path'];
  }
  int? _id;
  String? _imagePath;

  get bookName => null;

  get chapterNum => null;

  get content => null;

  get verseNum => null;
  SaveImageModel copyWith({
    int? id,
    String? imagePath,
  }) =>
      SaveImageModel(
        id: id ?? _id,
        imagePath: imagePath ?? imagePath,
      );
  int? get id => _id;
  String? get imagePath => _imagePath;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['image_path'] = _imagePath;
    return map;
  }
}
