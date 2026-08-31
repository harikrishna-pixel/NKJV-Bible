class LiturgicalFasting {
  const LiturgicalFasting({
    required this.isFast,
    required this.rule,
    this.reason,
    this.detail,
  });

  final bool isFast;
  final String rule;
  final String? reason;
  final String? detail;

  factory LiturgicalFasting.fromJson(Map<String, dynamic> json) {
    return LiturgicalFasting(
      isFast: json['isFast'] == true,
      rule: json['rule']?.toString() ?? '',
      reason: json['reason']?.toString(),
      detail: json['detail']?.toString(),
    );
  }
}

/// Resolved liturgical details for one calendar day (API handoff §3).
class LiturgicalDayInfo {
  const LiturgicalDayInfo({
    required this.date,
    this.tradition,
    this.locale,
    this.feast,
    this.season = 'ordinary',
    this.fasting,
    this.saints = const [],
    this.nameDays = const [],
    this.easter,
    this.reading,
  });

  final String date;
  final String? tradition;
  final String? locale;
  final String? feast;
  final String season;
  final LiturgicalFasting? fasting;
  final List<String> saints;
  final List<String> nameDays;
  final String? easter;
  final String? reading;

  bool get showFastingUi =>
      tradition == 'orthodox' && fasting != null;

  bool get hasVisibleContent =>
      (feast != null && feast!.trim().isNotEmpty) ||
      season.trim().toLowerCase() != 'ordinary' ||
      saints.isNotEmpty ||
      nameDays.isNotEmpty ||
      showFastingUi ||
      (reading != null && reading!.trim().isNotEmpty);

  factory LiturgicalDayInfo.fromApi(Map<String, dynamic> json) {
    LiturgicalFasting? fasting;
    final fastingRaw = json['fasting'];
    if (fastingRaw is Map) {
      fasting = LiturgicalFasting.fromJson(
        Map<String, dynamic>.from(fastingRaw),
      );
    }

    return LiturgicalDayInfo(
      date: json['date']?.toString() ?? '',
      tradition: json['tradition']?.toString(),
      locale: json['locale']?.toString(),
      feast: json['feast']?.toString(),
      season: json['season']?.toString() ?? 'ordinary',
      fasting: fasting,
      saints: _stringList(json['saints']),
      nameDays: _stringList(json['nameDays']),
      easter: json['easter']?.toString(),
      reading: json['reading']?.toString(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
}
