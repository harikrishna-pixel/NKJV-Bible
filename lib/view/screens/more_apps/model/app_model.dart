class AppModel {
  final String appId;
  final String appName;
  final String appurl;
  final String developedBy;
  final String apptype;
  final String thumburl;
  final String? thumburl2;

  AppModel({
    required this.appId,
    required this.appName,
    required this.appurl,
    required this.developedBy,
    required this.apptype,
    required this.thumburl,
    this.thumburl2,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      appId: json['appId'] as String,
      appName: json['appName'] as String,
      appurl: json['appurl'] as String,
      developedBy: json['developed_by'] as String,
      apptype: json['apptype'] as String,
      thumburl: json['thumburl'] as String,
      thumburl2: json['thumburl_2'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'appName': appName,
      'appurl': appurl,
      'developed_by': developedBy,
      'apptype': apptype,
      'thumburl': thumburl,
      'thumburl_2': thumburl2,
    };
  }
}
