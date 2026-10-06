/// Additive Achievements / Milestones models (presentation only).
enum MilestoneCategory { connection, prayer, community }

class MilestoneDef {
  const MilestoneDef({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.about,
    required this.reward,
    required this.icon,
  });

  final String id;
  final MilestoneCategory category;
  final String title;
  final String subtitle;
  final int target;
  final String about;
  final String reward;
  /// Material icon code point name used in UI.
  final IconKind icon;
}

enum IconKind {
  lantern,
  sprout,
  prayer,
  community,
  wreath,
}

class MilestoneProgress {
  const MilestoneProgress({
    required this.def,
    required this.current,
  });

  final MilestoneDef def;
  final int current;

  bool get isComplete => current >= def.target;
  double get fraction =>
      def.target <= 0 ? 0 : (current / def.target).clamp(0.0, 1.0);
  String get progressLabel =>
      isComplete ? 'Done' : '$current/${def.target}';
}

class ConnectionHubStats {
  const ConnectionHubStats({
    required this.totalConnectedDays,
    required this.currentStreak,
    required this.pathsCompleted,
    required this.prayersJoined,
    required this.answersReceived,
    required this.activePathTitle,
    this.activePathId,
    required this.activePathDay,
    required this.activePathTotal,
  });

  /// Set when the active path is a Connection Path (opens its overview).
  final String? activePathId;

  final int totalConnectedDays;
  final int currentStreak;
  final int pathsCompleted;
  final int prayersJoined;
  final int answersReceived;
  final String? activePathTitle;
  final int activePathDay;
  final int activePathTotal;
}
