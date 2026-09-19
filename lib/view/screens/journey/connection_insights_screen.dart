import 'package:biblebookapp/services/connection_checkin_store.dart';
import 'package:biblebookapp/view/screens/journey/connection_checkin_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConnectionInsightsScreen extends StatefulWidget {
  const ConnectionInsightsScreen({super.key});

  @override
  State<ConnectionInsightsScreen> createState() =>
      _ConnectionInsightsScreenState();
}

class _ConnectionInsightsScreenState extends State<ConnectionInsightsScreen> {
  static const _ink = Color(0xFF2F241C);
  static const _muted = Color(0xFF8B7D70);
  static const _page = Color(0xFFE8E0D4);
  static const _card = Color(0xFFFFFCF8);
  static const _barTrack = Color(0xFFE4DBD0);
  static const _pillTrack = Color(0xFFF0E9DF);
  static const _pillSelected = Color(0xFF4A3728);
  static const _barColors = [
    Color(0xFFE8D7C0),
    Color(0xFFF0A56A),
    Color(0xFFF2CF5A),
    Color(0xFF7DC47A),
    Color(0xFF3E9A55),
  ];

  int _rangeDays = 30;
  Map<String, int> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await ConnectionCheckinStore.hydrateFromExistingStreakItems();
    if (!mounted) return;
    setState(() => _byDay = map);
  }

  List<MapEntry<String, int>> get _inRange {
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays - 1));
    final start = DateTime(cutoff.year, cutoff.month, cutoff.day);
    final entries = <MapEntry<String, int>>[];
    _byDay.forEach((key, level) {
      final date = ConnectionCheckinStore.parseDay(key) ??
          DateTime.tryParse(key.length >= 10 ? key.substring(0, 10) : key);
      if (date == null) return;
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isBefore(start)) entries.add(MapEntry(key, level));
    });
    entries.sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  List<double> get _percents {
    final list = _inRange;
    if (list.isEmpty) return List<double>.filled(5, 0);
    final counts = List<int>.filled(5, 0);
    for (final e in list) {
      counts[e.value.clamp(0, 4)]++;
    }
    return counts.map((c) => (c * 100.0) / list.length).toList();
  }

  int get _dominantIndex {
    final p = _percents;
    var maxI = 2;
    var maxV = -1.0;
    for (var i = 0; i < p.length; i++) {
      if (p[i] >= maxV) {
        maxV = p[i];
        maxI = i;
      }
    }
    return maxI;
  }

  Color get _heartColor {
    if (_inRange.isEmpty) return _barColors[3];
    return _barColors[_dominantIndex];
  }

  IconData _dominantIcon(int dominant) {
    switch (dominant) {
      case 0:
      case 1:
        return Icons.spa_outlined;
      case 2:
        return Icons.park_rounded;
      case 3:
        return Icons.eco_rounded;
      default:
        return Icons.favorite;
    }
  }

  String _headerCopy(int dominant) {
    if (_rangeDays == 7) {
      switch (dominant) {
        case 0:
          return 'This week has felt distant. God is still near — take one small step.';
        case 1:
          return 'This week has felt far. Keep reaching for Him.';
        case 2:
          return 'You\'re building a stronger connection. Keep going!';
        case 3:
          return 'Most of your check-ins this week have felt close. Keep seeking God\'s presence!';
        default:
          return 'You\'ve stayed close to God this week. Keep it up!';
      }
    }
    if (_rangeDays == 90) {
      switch (dominant) {
        case 0:
          return 'The last 90 days have felt distant. His love has not left you.';
        case 1:
          return 'The last 90 days have felt far. Keep seeking God\'s presence!';
        case 2:
          return 'You\'ve been growing with God over the last 90 days. Keep going!';
        case 3:
          return 'Most of your check-ins have felt close over the last 90 days. Keep seeking God\'s presence!';
        default:
          return 'You\'ve been consistently connected with God over the last 90 days. Keep it up!';
      }
    }
    switch (dominant) {
      case 0:
        return 'The last 30 days have felt distant. Come as you are — He is near.';
      case 1:
        return 'The last 30 days have felt far. Keep seeking God\'s presence!';
      case 2:
        return 'You\'re growing closer over the last 30 days. Keep going!';
      case 3:
        return 'Most of your check-ins have felt close. Keep seeking God\'s presence!';
      default:
        return 'You\'ve stayed close to God over the last 30 days. Keep it up!';
    }
  }

  ({String title, String body, Color tint, Color accent}) _motive(int dominant) {
    if (_rangeDays == 7) {
      if (dominant <= 1) {
        return (
          title: 'Keep Seeking',
          body:
              'Every step toward God this week is a step worth taking. Keep moving forward in faith.',
          tint: const Color(0xFFF8EFE4),
          accent: const Color(0xFFC47A4A),
        );
      }
      return (
        title: 'Keep Going',
        body:
            'You\'re making progress this week. Small steps bring you closer to God!',
        tint: const Color(0xFFFFF6E8),
        accent: const Color(0xFFD0894A),
      );
    }
    if (_rangeDays == 90) {
      if (dominant >= 3) {
        return (
          title: 'Consistently Connected',
          body:
              'You\'ve maintained a strong connection over the past 90 days. Keep seeking His presence!',
          tint: const Color(0xFFEEF4FF),
          accent: const Color(0xFF3D6FD9),
        );
      }
      if (dominant == 2) {
        return (
          title: 'Keep Growing',
          body:
              'You\'ve been growing over the past 90 days. Keep seeking His presence!',
          tint: const Color(0xFFFBF3D8),
          accent: const Color(0xFFD2A83A),
        );
      }
      return (
        title: 'Keep Seeking',
        body:
            'The last 90 days have had hard days. His love never leaves you. Take one step toward Him today.',
        tint: const Color(0xFFF8EFE4),
        accent: const Color(0xFFC47A4A),
      );
    }
    if (dominant >= 3) {
      return (
        title: 'You\'re Closer',
        body:
            'You\'ve chosen Close or Very Close more often in the last 30 days. That\'s wonderful!',
        tint: const Color(0xFFE8F4E4),
        accent: const Color(0xFF4FA05A),
      );
    }
    if (dominant == 2) {
      return (
        title: 'Keep Growing',
        body:
            'You\'re growing closer over the last 30 days. Stay rooted in His Word.',
        tint: const Color(0xFFFBF3D8),
        accent: const Color(0xFFD2A83A),
      );
    }
    return (
      title: 'Keep Seeking',
      body:
          'Every step toward God in the last 30 days is a step worth taking. Keep moving forward in faith.',
      tint: const Color(0xFFF8EFE4),
      accent: const Color(0xFFC47A4A),
    );
  }

  String _checkinWhen(String key) {
    final date = ConnectionCheckinStore.parseDay(key);
    if (date == null) return key;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final percents = _percents;
    final dominant = _inRange.isEmpty ? -1 : _dominantIndex;
    final heart = _heartColor;
    final top = MediaQuery.of(context).padding.top;
    final motive = dominant < 0 ? null : _motive(dominant);

    return Scaffold(
      backgroundColor: _page,
      body: Column(
        children: [
          SizedBox(height: top + 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink),
                ),
                const Expanded(
                  child: Text(
                    'Connection Insights',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Get.to(
                      () => ConnectionCheckinCalendarScreen(byDay: _byDay),
                      transition: Transition.cupertino,
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 22, color: _ink),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _rangeDays == 7
                            ? 'Your Connection Last 7 Days'
                            : _rangeDays == 90
                                ? 'Your Connection Last 90 Days'
                                : 'Your Connection Last 30 Days',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: heart.withOpacity(0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              dominant < 0
                                  ? Icons.favorite
                                  : _dominantIcon(dominant),
                              size: 38,
                              color: heart,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dominant < 0
                                      ? 'Start checking in'
                                      : ConnectionCheckinStore.labels[dominant],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    height: 1.05,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dominant < 0
                                      ? 'Complete today\'s Faith Journey check-in to see insights.'
                                      : _headerCopy(dominant),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.35,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 122,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(5, (i) {
                            final hasFill = percents[i] > 0;
                            final h = hasFill
                                ? (8.0 + (percents[i] / 100) * 114)
                                    .clamp(8.0, 122.0)
                                : 0.0;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 122,
                                    alignment: Alignment.bottomCenter,
                                    decoration: BoxDecoration(
                                      color: _barTrack,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: hasFill
                                        ? Container(
                                            height: h,
                                            decoration: BoxDecoration(
                                              color: _barColors[i],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (i) {
                          return Expanded(
                            child: Column(
                              children: [
                                Text(
                                  ConnectionCheckinStore.labels[i],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${percents[i].round()}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: percents[i] <= 0
                                        ? _muted
                                        : _barColors[i],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _pillTrack,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [7, 30, 90].map((days) {
                            final selected = _rangeDays == days;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _rangeDays = days),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _pillSelected
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$days Days',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : _muted,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (motive != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          decoration: BoxDecoration(
                            color: motive.tint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 22, color: motive.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      motive.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: motive.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      motive.body,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Check-ins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (_inRange.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => _CheckinListScreen(items: _inRange),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 280),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC4A574),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_inRange.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No check-ins in this period yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: _inRange.take(3).toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return Column(
                          children: [
                            if (i > 0)
                              const Divider(height: 1, color: Color(0xFFF0EAE3)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _barColors[e.value.clamp(0, 4)],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _checkinWhen(e.key),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckinListScreen extends StatelessWidget {
  const _CheckinListScreen({required this.items});

  final List<MapEntry<String, int>> items;

  static const _ink = Color(0xFF2F241C);
  static const _page = Color(0xFFE8E0D4);
  static const _barColors = [
    Color(0xFFE8D7C0),
    Color(0xFFF0A56A),
    Color(0xFFF2CF5A),
    Color(0xFF7DC47A),
    Color(0xFF3E9A55),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Recent Check-ins',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final e = items[index];
          final date = ConnectionCheckinStore.parseDay(e.key);
          final label = date == null
              ? e.key
              : DateFormat('MMM d, yyyy').format(date);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _barColors[e.value.clamp(0, 4)],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
                Text(
                  ConnectionCheckinStore.labels[e.value.clamp(0, 4)],
                  style: TextStyle(
                    color: _barColors[e.value.clamp(0, 4)],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
