class StudyPlan {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> verses;
  final int durationDays;

  StudyPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.verses,
    required this.durationDays,
  });
}
