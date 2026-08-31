import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/calendar_screen/bloc/calendar_data_bloc.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class CalendarEventItem extends HookConsumerWidget {
  final CalendarModel calendarModel;
  const CalendarEventItem({super.key, required this.calendarModel});

  String? _formattedDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brown = CommanColor.calendarSelectedColor(context);
    final isFeastDay = !calendarModel.canEdit;
    final dateLabel = _formattedDate(calendarModel.date);
    final subtitle = dateLabel == null
        ? (isFeastDay ? 'Feast Day' : 'Reminder')
        : '$dateLabel • ${isFeastDay ? 'Feast Day' : 'Reminder'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CommanColor.whiteAndDark(context).withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brown.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE5D3B3).withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFeastDay ? Icons.church_outlined : Icons.event_note_outlined,
                color: brown,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calendarModel.title ?? '',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      letterSpacing: BibleInfo.letterSpacing,
                      fontSize: BibleInfo.fontSizeScale * 17,
                      fontWeight: FontWeight.w700,
                      color: CommanColor.contentTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      letterSpacing: BibleInfo.letterSpacing,
                      fontSize: BibleInfo.fontSizeScale * 13,
                      fontWeight: FontWeight.w500,
                      color: CommanColor.contentTextColor(context).withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (calendarModel.canEdit) ...[
              GestureDetector(
                onTap: () {
                  ref.read(calendarDataBloc).editCalendar(calendarModel);
                },
                child: Icon(
                  Icons.edit_calendar_rounded,
                  color: brown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  ref.read(calendarDataBloc).deleteCalendarData(calendarModel);
                },
                child: Icon(
                  Icons.delete_outline,
                  color: brown,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
