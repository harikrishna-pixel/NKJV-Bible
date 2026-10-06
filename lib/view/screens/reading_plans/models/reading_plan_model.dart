/// Reading Plan model — additive UI feature (independent of Study Plans).
class ReadingPlan {
  ReadingPlan({
    required this.id,
    required this.title,
    required this.topic,
    required this.description,
    required this.durationDays,
    required this.dayVerses,
    required this.backgroundAsset,
  });

  final String id;
  final String title;
  final String topic;
  final String description;
  final int durationDays;
  /// Each day has exactly 3 verse references (Day 1 = index 0).
  final List<List<String>> dayVerses;
  final String backgroundAsset;

  int get totalDays => durationDays;

  List<String> versesForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= dayVerses.length) return const [];
    return dayVerses[dayIndex];
  }
}
