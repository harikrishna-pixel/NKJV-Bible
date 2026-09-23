import 'package:biblebookapp/services/connection_checkin_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// New check-in calendar. Does not replace or change the existing Calendar screen.
class ConnectionCheckinCalendarScreen extends StatefulWidget {
  const ConnectionCheckinCalendarScreen({super.key, required this.byDay});

  final Map<String, int> byDay;

  @override
  State<ConnectionCheckinCalendarScreen> createState() =>
      _ConnectionCheckinCalendarScreenState();
}

class _ConnectionCheckinCalendarScreenState
    extends State<ConnectionCheckinCalendarScreen> {
  static const _ink = Color(0xFF2F241C);
  static const _muted = Color(0xFF8B7D70);
  static const _page = Color(0xFFE8E0D4);
  static const _card = Color(0xFFFFFCF8);
  static const _quoteBg = Color(0xFFF6EFE0);
  static const _gold = Color(0xFFB8893A);
  static const _levelColors = [
    Color(0xFFE07A6A),
    Color(0xFFF0A56A),
    Color(0xFFF2CF5A),
    Color(0xFF7DC47A),
    Color(0xFF3E9A55),
  ];
  static const _quotes = [
    'Come as you are. God is near.',
    'Keep seeking Him.',
    'Keep seeking, keep growing.',
    'Stay close. Keep walking in faith.',
    'Abide in Him.',
  ];

  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  int? _levelFor(DateTime day) {
    return widget.byDay[ConnectionCheckinStore.dayKey(day)];
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final rows = ((lead + daysInMonth + 6) ~/ 7);
    final selectedLevel = _levelFor(_selected);

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _ink),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Connection History',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _month = DateTime(_month.year, _month.month - 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_left, size: 26, color: _ink),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _month = DateTime(_month.year, _month.month + 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_right, size: 26, color: _ink),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                        (d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                ...List.generate(rows, (r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: List.generate(7, (c) {
                        final index = r * 7 + c;
                        final dayNum = index - lead + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const Expanded(child: SizedBox(height: 42));
                        }
                        final date =
                            DateTime(_month.year, _month.month, dayNum);
                        final level = _levelFor(date);
                        final isSelected = date.year == _selected.year &&
                            date.month == _selected.month &&
                            date.day == _selected.day;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = date),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: level == null
                                        ? Colors.transparent
                                        : _levelColors[level].withOpacity(0.88),
                                    border: isSelected
                                        ? Border.all(color: _gold, width: 2)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: level == null
                                          ? _ink
                                          : const Color(0xFF2A241C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: _quoteBg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 22,
                    color: _gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(_selected),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedLevel == null
                            ? 'No Check-in'
                            : ConnectionCheckinStore.labels[selectedLevel],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedLevel == null
                            ? 'No connection check-in on this day.'
                            : '“${_quotes[selectedLevel]}”',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
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
                Row(
                  children: [
                    Expanded(child: _legendDot(_levelColors[0], 'Very Far')),
                    Expanded(child: _legendDot(_levelColors[1], 'Far')),
                    Expanded(child: _legendDot(_levelColors[2], 'Growing')),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _legendDot(_levelColors[3], 'Close')),
                    Expanded(child: _legendDot(_levelColors[4], 'Very Close')),
                    Expanded(
                      child: _legendDot(
                          const Color(0xFFB8B0A6), 'No Check-in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ),
      ],
    );
  }
}
