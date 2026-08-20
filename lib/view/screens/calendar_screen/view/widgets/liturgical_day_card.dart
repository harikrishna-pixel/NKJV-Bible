import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/liturgical_day_model.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';

/// Additive liturgical summary for the selected calendar day.
class LiturgicalDayCard extends StatelessWidget {
  const LiturgicalDayCard({super.key, required this.info});

  final LiturgicalDayInfo info;

  @override
  Widget build(BuildContext context) {
    if (!info.hasVisibleContent) return const SizedBox.shrink();

    final brown = CommanColor.calendarSelectedColor(context);
    final textColor = CommanColor.contentTextColor(context);
    final muted = textColor.withOpacity(0.72);
    final season = info.season.trim();
    final showSeason =
        season.isNotEmpty && season.toLowerCase() != 'ordinary';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: CommanColor.whiteAndDark(context).withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brown.withOpacity(0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.feast != null && info.feast!.trim().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.church_outlined, size: 18, color: brown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.feast!,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: BibleInfo.fontSizeScale * 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (showSeason) ...[
              if (info.feast != null && info.feast!.trim().isNotEmpty)
                const SizedBox(height: 8),
              Text(
                info.feast != null && info.feast!.trim().isNotEmpty
                    ? season
                    : _titleCaseSeason(season),
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: BibleInfo.fontSizeScale * 13.5,
                  fontWeight: FontWeight.w600,
                  color: brown,
                ),
              ),
            ],
            if (info.saints.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...info.saints.map(
                (saint) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, size: 16, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          saint,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: BibleInfo.fontSizeScale * 13,
                            color: muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (info.nameDays.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...info.nameDays.map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.celebration_outlined, size: 16, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: BibleInfo.fontSizeScale * 13,
                            color: muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (info.showFastingUi) ...[
              const SizedBox(height: 8),
              _FastingRow(fasting: info.fasting!, brown: brown, textColor: textColor),
            ],
            if (info.reading != null && info.reading!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.reading!,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: BibleInfo.fontSizeScale * 12.5,
                  color: muted,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _titleCaseSeason(String season) {
    if (season.isEmpty) return season;
    return season[0].toUpperCase() + season.substring(1);
  }
}

class _FastingRow extends StatelessWidget {
  const _FastingRow({
    required this.fasting,
    required this.brown,
    required this.textColor,
  });

  final LiturgicalFasting fasting;
  final Color brown;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isFast = fasting.isFast;
    final label = isFast ? 'Fast day' : 'No fast today';
    final detail = (fasting.detail ?? '').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isFast ? Icons.restaurant_outlined : Icons.check_circle_outline,
          size: 16,
          color: isFast ? brown : textColor.withOpacity(0.65),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: BibleInfo.fontSizeScale * 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: BibleInfo.fontSizeScale * 12,
                    color: textColor.withOpacity(0.65),
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
