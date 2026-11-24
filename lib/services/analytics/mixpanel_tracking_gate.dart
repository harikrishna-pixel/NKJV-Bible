/// Pure gate logic for Mixpanel (unit-testable, no SDK).
class MixpanelRemoteConfig {
  const MixpanelRemoteConfig({
    required this.enabled,
    required this.samplePct,
    required this.dailyEventCap,
  });

  final bool enabled;
  final int samplePct;
  final int dailyEventCap;

  factory MixpanelRemoteConfig.fromJson(Map<String, dynamic> json) {
    final sample = (json['sample_pct'] is num)
        ? (json['sample_pct'] as num).toInt()
        : int.tryParse('${json['sample_pct']}') ?? 0;
    final cap = (json['daily_event_cap'] is num)
        ? (json['daily_event_cap'] as num).toInt()
        : int.tryParse('${json['daily_event_cap']}') ?? 40;
    final enabledRaw = json['enabled'];
    final enabled = enabledRaw == true ||
        enabledRaw == 1 ||
        '${enabledRaw}'.toLowerCase() == 'true';
    return MixpanelRemoteConfig(
      enabled: enabled,
      samplePct: sample.clamp(0, 100),
      dailyEventCap: cap < 0 ? 0 : cap,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'sample_pct': samplePct,
        'daily_event_cap': dailyEventCap,
      };
}

class MixpanelTrackingGate {
  MixpanelTrackingGate._();

  /// FNV-1a style hash — stable across runs for the same string.
  static int stableHash(String input) {
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  /// Sample by user (not by event). Cached decision should use this once.
  static bool isSampledIn({
    required String anonymousId,
    required int samplePct,
  }) {
    if (samplePct <= 0) return false;
    if (samplePct >= 100) return true;
    if (anonymousId.isEmpty) return false;
    return stableHash(anonymousId) % 100 < samplePct;
  }

  /// Fail-closed: no config → never track.
  static bool canSendEvent({
    required MixpanelRemoteConfig? config,
    required bool? sampledInCached,
    required String anonymousId,
    required int eventsSentToday,
  }) {
    if (config == null) return false;
    if (!config.enabled) return false;
    if (config.dailyEventCap <= 0) return false;
    if (eventsSentToday >= config.dailyEventCap) return false;

    final sampled = sampledInCached ??
        isSampledIn(anonymousId: anonymousId, samplePct: config.samplePct);
    return sampled;
  }

  /// Once-per-calendar-day guard for [app_open_daily].
  static bool shouldSendAppOpenDaily({
    required String? lastSentDateYmd,
    required DateTime now,
  }) {
    final today = _ymd(now);
    if (lastSentDateYmd == null || lastSentDateYmd.isEmpty) return true;
    return lastSentDateYmd != today;
  }

  static String dateYmd(DateTime dt) => _ymd(dt);

  static String _ymd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Streak: consecutive calendar days with an open. Returns updated streak.
  static int nextStreakDay({
    required String? lastOpenDateYmd,
    required int previousStreak,
    required DateTime now,
  }) {
    final today = _ymd(now);
    if (lastOpenDateYmd == null || lastOpenDateYmd.isEmpty) return 1;
    if (lastOpenDateYmd == today) {
      return previousStreak <= 0 ? 1 : previousStreak;
    }
    final last = DateTime.tryParse(lastOpenDateYmd);
    if (last == null) return 1;
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final lastDay = DateTime(last.year, last.month, last.day);
    if (lastDay == yesterday) {
      return (previousStreak <= 0 ? 1 : previousStreak) + 1;
    }
    return 1;
  }

  static int daysSinceInstall({
    required String? firstOpenDateYmd,
    required DateTime now,
  }) {
    if (firstOpenDateYmd == null || firstOpenDateYmd.isEmpty) return 0;
    final first = DateTime.tryParse(firstOpenDateYmd);
    if (first == null) return 0;
    final a = DateTime(first.year, first.month, first.day);
    final b = DateTime(now.year, now.month, now.day);
    return b.difference(a).inDays;
  }
}
