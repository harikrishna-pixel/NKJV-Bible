import 'package:shared_preferences/shared_preferences.dart';

/// Service to track Study Plan progress and completion status
class StudyPlanProgressService {
  static const String _progressPrefix = 'study_plan_progress_';
  static const String _completedPrefix = 'study_plan_completed_';
  static const String _verseCompletedPrefix = 'study_plan_verse_completed_';
  static const String _startedPrefix = 'study_plan_started_';

  /// Get progress for a study plan (0.0 to 1.0)
  static Future<double> getProgress(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${_progressPrefix}$planId') ?? 0.0;
  }

  /// Set progress for a study plan (0.0 to 1.0)
  static Future<void> setProgress(String planId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_progressPrefix}$planId', progress);

    // Auto-mark as completed if progress reaches 100%
    if (progress >= 1.0) {
      await markAsCompleted(planId);
    }
  }

  /// Check if study plan is completed
  static Future<bool> isCompleted(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_completedPrefix}$planId') ?? false;
  }

  /// Mark study plan as completed
  static Future<void> markAsCompleted(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_completedPrefix}$planId', true);
    await prefs.setDouble('${_progressPrefix}$planId', 1.0);
    await prefs.setString(
        '${_completedPrefix}${planId}_date', DateTime.now().toIso8601String());
  }

  /// Check if study plan is started
  static Future<bool> isStarted(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_startedPrefix}$planId') ?? false;
  }

  /// Mark study plan as started
  static Future<void> markAsStarted(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_startedPrefix}$planId', true);
    await prefs.setString(
        '${_startedPrefix}${planId}_date', DateTime.now().toIso8601String());

    // Set initial progress if not already set
    final currentProgress = await getProgress(planId);
    if (currentProgress == 0.0) {
      await setProgress(planId, 0.1); // 10% progress when started
    }
  }

  /// Get completion date
  static Future<DateTime?> getCompletionDate(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('${_completedPrefix}${planId}_date');
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Get started date
  static Future<DateTime?> getStartedDate(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('${_startedPrefix}${planId}_date');
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Reset progress for a study plan
  static Future<void> resetProgress(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_progressPrefix}$planId');
    await prefs.remove('${_completedPrefix}$planId');
    await prefs.remove('${_startedPrefix}$planId');
    await prefs.remove('${_completedPrefix}${planId}_date');
    await prefs.remove('${_startedPrefix}${planId}_date');
    // Remove any per-verse completion flags for this plan
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('$_verseCompletedPrefix$planId')) {
        await prefs.remove(key);
      }
    }
  }

  /// Get all completed study plans
  static Future<List<String>> getCompletedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final completedPlans = <String>[];

    for (final key in keys) {
      if (key.startsWith(_completedPrefix) && !key.contains('_date')) {
        final planId = key.substring(_completedPrefix.length);
        if (prefs.getBool(key) == true) {
          completedPlans.add(planId);
        }
      }
    }

    return completedPlans;
  }

  /// Get progress status text
  static String getProgressStatusText(
      double progress, bool isCompleted, bool isStarted) {
    if (isCompleted) return 'Completed';
    if (isStarted && progress > 0) return 'In Progress';
    return 'Not Started';
  }

  /// Get progress percentage as integer
  static int getProgressPercentage(double progress) {
    return (progress * 100).round();
  }

  /// Mark/unmark an individual verse within a study plan as completed
  static Future<void> setVerseCompleted(
      String planId, String verseRef, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '$_verseCompletedPrefix${planId}_${Uri.encodeComponent(verseRef)}';
    if (completed) {
      await prefs.setBool(key, true);
      await prefs.setString(
          '${_verseCompletedPrefix}${planId}_${Uri.encodeComponent(verseRef)}_date',
          DateTime.now().toIso8601String());
    } else {
      await prefs.remove(key);
      await prefs.remove(
          '${_verseCompletedPrefix}${planId}_${Uri.encodeComponent(verseRef)}_date');
    }
  }

  /// Check if an individual verse is marked completed
  static Future<bool> isVerseCompleted(String planId, String verseRef) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        '$_verseCompletedPrefix${planId}_${Uri.encodeComponent(verseRef)}';
    return prefs.getBool(key) ?? false;
  }

  /// Get all completed verse refs for a plan
  static Future<List<String>> getCompletedVerses(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final completed = <String>[];
    for (final key in keys) {
      if (key.startsWith('$_verseCompletedPrefix$planId')) {
        // key format: prefix + planId + _ + encodedVerseRef
        final parts = key.split('_');
        if (parts.length >= 3) {
          // Reconstruct encoded part (may contain underscores)
          final encoded =
              key.substring('$_verseCompletedPrefix$planId'.length + 1);
          try {
            final verseRef = Uri.decodeComponent(encoded);
            completed.add(verseRef);
          } catch (e) {
            // fallback: ignore
          }
        }
      }
    }
    return completed;
  }
}
