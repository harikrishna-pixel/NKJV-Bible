class CalendarModel {
  final int? id;
  final String? title;
  final String? date;
  final bool canEdit;
  CalendarModel({this.date, this.id, this.title, this.canEdit = true});

  factory CalendarModel.fromJson(dynamic json) {
    return CalendarModel(
        id: json['id'],
        title: json['title'],
        date: json['date'],
        canEdit: json['canEdit'] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'date': date};
  }

  CalendarModel copyWith({String? newTitle, bool? updateCanEdit}) {
    return CalendarModel(
        id: id,
        title: newTitle ?? title,
        date: date,
        canEdit: updateCanEdit ?? canEdit);
  }
}
