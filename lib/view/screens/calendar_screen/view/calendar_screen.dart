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
import 'dart:math' as math;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as p;

class CalendarScreen extends StatefulHookConsumerWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(calendarDataBloc).initState();
  }

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(calendarDataBloc).getLocalDBData();
      });
    });

    final calendarBloc = ref.watch(calendarDataBloc);
    Widget cellWidget(DateTime day, {bool isOutside = false}) {
      final bool isWeekend = day.weekday == 7;
      bool isSelected = isSameDay(day, calendarBloc.focusDate);
      return GestureDetector(
        onTap: () {
          calendarBloc.onDaySelected(day, day);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                      color: CommanColor.calendarSelectedColor(context)))
              : null,
          child: Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: CommanColor.calendarSelectedColor(context))
                : null,
            child: Text(
              day.day.toString(),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isOutside
                          ? CommanColor.progressUnFillColor(context)
                          : isWeekend
                              ? CommanColor.weekendColor(context)
                              : CommanColor.whiteBlack(context)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image:
                    p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                            AppCustomTheme.vintage
                        ? DecorationImage(
                            image: AssetImage(Images.bgImage(context)),
                            fit: BoxFit.cover)
                        : null),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SafeArea(
                    child: SizedBox(
                      height: 12,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: CommanColor.whiteBlack(context),
                          ),
                        ),
                      ),
                      Text("Calendar", style: CommanStyle.appBarStyle(context)),
                      const SizedBox(width: 20)
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        TableCalendar(
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: calendarBloc.focusDate,
                          eventLoader: (day) => calendarBloc.kEvents[day] ?? [],
                          headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              leftChevronIcon: Icon(
                                Icons.arrow_back_ios,
                                color: CommanColor.whiteBlack(context),
                              ),
                              rightChevronIcon: Transform.rotate(
                                angle: -math.pi,
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: CommanColor.whiteBlack(context),
                                ),
                              ),
                              titleTextStyle: const TextStyle(
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: BibleInfo.fontSizeScale * 16,
                                  fontWeight: FontWeight.w500),
                              headerPadding: const EdgeInsets.only(left: 16)),
                          weekendDays: const [DateTime.sunday],
                          daysOfWeekHeight: 32,
                          daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              weekendStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CommanColor.weekendColor(context))),
                          onDaySelected: calendarBloc.onDaySelected,
                          onPageChanged: calendarBloc.onPageChanged,
                          calendarBuilders: CalendarBuilders(
                            todayBuilder: (context, day, focusedDay) {
                              return cellWidget(day);
                            },
                            outsideBuilder: (context, day, focusedDay) {
                              return cellWidget(day, isOutside: true);
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              return cellWidget(day);
                            },
                            markerBuilder: (context, day, events) => Visibility(
                              visible: events.isNotEmpty &&
                                  !isSameDay(day, calendarBloc.focusDate),
                              child: Container(
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CommanColor.calendarSelectedColor(
                                        context)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            calendarBloc.isTodaySelected
                                ? 'Today'
                                : DateFormat('EEEE d')
                                    .format(calendarBloc.focusDate),
                            style: const TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFormField(
                            controller: calendarBloc.fieldCon,
                            focusNode: calendarBloc.fieldNode,
                            decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                hintText: 'Add an event or reminder',
                                hintStyle: const TextStyle(
                                    fontWeight: FontWeight.w300),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 1.5,
                                        color:
                                            CommanColor.calendarSelectedColor(
                                                context))),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                    borderSide: BorderSide(
                                        width: 1.5,
                                        color:
                                            CommanColor.calendarSelectedColor(
                                                    context)
                                                .withOpacity(0.5)))),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!calendarBloc.isTextEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        alignment: Alignment.center,
                                        backgroundColor:
                                            CommanColor.lightDarkPrimary200(
                                                context)),
                                    onPressed: () {
                                      calendarBloc.cancelField();
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: CommanStyle
                                              .inDarkPrimaryInLightWhite15500(
                                                  context)
                                          .copyWith(
                                              color: CommanStyle
                                                      .inDarkPrimaryInLightWhite15500(
                                                          context)
                                                  .color
                                                  ?.withOpacity(0.9)),
                                    )),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        alignment: Alignment.center,
                                        backgroundColor: CommanColor
                                            .inDarkWhiteAndInLightPrimary(
                                                context)),
                                    onPressed: () {
                                      calendarBloc.addCalendarData();
                                    },
                                    child: Text(
                                      "Save",
                                      style: CommanStyle
                                          .inDarkPrimaryInLightWhite15500(
                                              context),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
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
                        const SizedBox(height: 50)
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
