import 'package:biblebookapp/table_calendar/table_calendar_main.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/calendar_screen/bloc/calendar_data_bloc.dart';
import 'package:biblebookapp/view/screens/calendar_screen/view/widgets/calendar_event_item.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as p;

class CalendarScreen extends StatefulHookConsumerWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const Color _tanCircle = Color(0xFFD4A96A);

  @override
  void initState() {
    super.initState();
    ref.read(calendarDataBloc).initState();
  }

  Widget _legendItem({
    required Widget icon,
    required String label,
    required Color textColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: BibleInfo.fontSizeScale * 11,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.75),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDivider(Color color) {
    return Container(
      width: 1,
      height: 36,
      color: color.withOpacity(0.2),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final brown = CommanColor.calendarSelectedColor(context);
    final textColor = CommanColor.whiteBlack(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: CommanColor.whiteAndDark(context).withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brown.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _legendItem(
            icon: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: _tanCircle,
                shape: BoxShape.circle,
              ),
            ),
            label: 'Sunday /\nSpecial Day',
            textColor: textColor,
          ),
          _legendDivider(brown),
          _legendItem(
            icon: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: brown, width: 1.5),
              ),
            ),
            label: 'Selected\nDate',
            textColor: textColor,
          ),
          _legendDivider(brown),
          _legendItem(
            icon: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: brown,
                shape: BoxShape.circle,
              ),
            ),
            label: 'Event /\nReminder',
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(calendarDataBloc).getLocalDBData();
      });
    });

    final calendarBloc = ref.watch(calendarDataBloc);
    final themeProvider = p.Provider.of<ThemeProvider>(context);
    final isVintageTheme =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final brown = CommanColor.calendarSelectedColor(context);
    final textColor = CommanColor.contentTextColor(context);

    Widget cellWidget(DateTime day, {bool isOutside = false}) {
      final bool isSunday = day.weekday == DateTime.sunday;
      final bool isSelected = isSameDay(day, calendarBloc.selectedDay);
      final events = calendarBloc.kEvents[day] ?? [];
      final bool hasEvents = events.isNotEmpty;
      final bool isSpecialDay =
          hasEvents && events.any((event) => !event.canEdit);

      final bool showTanCircle =
          !isOutside && !isSelected && (isSunday || isSpecialDay);

      return GestureDetector(
        onTap: () {
          calendarBloc.onDaySelected(day, day);
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: showTanCircle ? _tanCircle : null,
                  borderRadius: BorderRadius.circular(isSelected ? 8 : 17),
                  border: isSelected
                      ? Border.all(color: brown, width: 1.5)
                      : showTanCircle
                          ? Border.all(
                              color: brown.withOpacity(0.45), width: 1.2)
                          : null,
                ),
                child: Text(
                  day.day.toString(),
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: BibleInfo.fontSizeScale * 14,
                    color: isOutside
                        ? CommanColor.progressUnFillColor(context)
                            .withOpacity(0.55)
                        : textColor,
                  ),
                ),
              ),
              if (hasEvents)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    height: 5,
                    width: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brown,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: p.Provider.of<ThemeProvider>(context).backgroundColor,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: isVintageTheme ? null : themeProvider.backgroundColor,
            decoration: isVintageTheme
                ? BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Images.bgImage(context)),
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SafeArea(
                    child: SizedBox(
                      height: 8,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.back();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Calendar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: BibleInfo.fontSizeScale * 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 24,
                            color: brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: 8,
                        ),
                        TableCalendar(
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: calendarBloc.focusDate,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, calendarBloc.selectedDay),
                          eventLoader: (day) => calendarBloc.kEvents[day] ?? [],
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            markersMaxCount: 0,
                            defaultTextStyle: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            weekendTextStyle: TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            outsideTextStyle: TextStyle(
                              fontFamily: 'Georgia',
                              color: CommanColor.progressUnFillColor(context)
                                  .withOpacity(0.55),
                            ),
                            cellMargin: const EdgeInsets.all(4),
                          ),
                          headerStyle: HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                              leftChevronIcon: Icon(
                                Icons.chevron_left_rounded,
                                color: textColor,
                                size: 28,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right_rounded,
                                color: textColor,
                                size: 28,
                              ),
                              titleTextFormatter: (date, locale) =>
                                  DateFormat('MMMM, yyyy').format(date),
                              titleTextStyle: TextStyle(
                                  fontFamily: 'Georgia',
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: BibleInfo.fontSizeScale * 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor),
                              headerPadding:
                                  const EdgeInsets.symmetric(vertical: 8)),
                          weekendDays: const [DateTime.sunday],
                          daysOfWeekHeight: 36,
                          daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontWeight: FontWeight.w700,
                                  fontSize: BibleInfo.fontSizeScale * 13,
                                  color: textColor),
                              weekendStyle: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontWeight: FontWeight.w700,
                                  fontSize: BibleInfo.fontSizeScale * 13,
                                  color: CommanColor.weekendColor(context))),
                          onDaySelected: calendarBloc.onDaySelected,
                          onPageChanged: calendarBloc.onPageChanged,
                          calendarBuilders: CalendarBuilders(
                            todayBuilder: (context, day, focusedDay) {
                              return cellWidget(day);
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return cellWidget(day);
                            },
                            outsideBuilder: (context, day, focusedDay) {
                              return cellWidget(day, isOutside: true);
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              return cellWidget(day);
                            },
                            markerBuilder: (context, day, events) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Text(
                            calendarBloc.isTodaySelected
                                ? 'Today'
                                : DateFormat('EEEE, MMMM d')
                                    .format(calendarBloc.focusDate),
                            style: TextStyle(
                                fontFamily: 'Georgia',
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 16,
                                fontWeight: FontWeight.w600,
                                color: textColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: TextFormField(
                            controller: calendarBloc.fieldCon,
                            focusNode: calendarBloc.fieldNode,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: CommanColor.whiteAndDark(context)
                                    .withOpacity(0.55),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                hintText: 'Add an event or reminder',
                                hintStyle: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.45)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        width: 1.5, color: brown)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        width: 1.5,
                                        color: brown.withOpacity(0.35))),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        width: 1.5,
                                        color: brown.withOpacity(0.35)))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!calendarBloc.isTextEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: brown.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10)),
                                    onPressed: () {
                                      calendarBloc.cancelField();
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: brown,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10)),
                                    onPressed: () {
                                      calendarBloc.addCalendarData();
                                    },
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) => CalendarEventItem(
                                calendarModel: calendarBloc
                                    .kEvents[calendarBloc.focusDate]![index]),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemCount: calendarBloc
                                    .kEvents[calendarBloc.focusDate]?.length ??
                                0),
                        _buildLegend(context),
                      ],
                    )),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
