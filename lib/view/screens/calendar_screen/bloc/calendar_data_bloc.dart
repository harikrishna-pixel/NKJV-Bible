import 'dart:collection';
import 'dart:developer';

import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/table_calendar/src/shared/utils.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final calendarDataBloc =
    ChangeNotifierProvider<CalendarDataBloc>((ref) => CalendarDataBloc());

class CalendarDataBloc extends ChangeNotifier {
  List<CalendarModel> overAllCalendarData = [];
  late DateTime focusDate;
  late DateTime todayDate;
  late bool isTodaySelected;
  late TextEditingController fieldCon;
  late FocusNode fieldNode;
  late bool isTextEmpty;
  CalendarModel? editData;
  bool _isLoadingData = false; // Prevent multiple simultaneous calls
  bool _justDeleted = false; // Flag to prevent immediate reload after delete

  static int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  editCalendar(CalendarModel edit) {
    editData = edit;
    fieldCon.text = edit.title ?? '';
    fieldNode.requestFocus();
    notifyListeners();
  }

  void initState() {
    isTodaySelected = true;
    isTextEmpty = true;
    fieldNode = FocusNode();
    fieldCon = TextEditingController();
    fieldCon.addListener(() {
      textControllerListener();
    });
    todayDate = DateTime.now();
    focusDate = DateTime.now();
  }

  LinkedHashMap<DateTime, List<CalendarModel>> kEvents =
      LinkedHashMap<DateTime, List<CalendarModel>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  void cancelField() {
    fieldCon.clear();
  }

  textControllerListener() {
    if (isTextEmpty != fieldCon.text.isEmpty) {
      isTextEmpty = fieldCon.text.isEmpty;
      notifyListeners();
    }
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    isTodaySelected = isSameDay(focusedDay, todayDate);
    focusDate = focusedDay;
    notifyListeners();
  }

  void onPageChanged(DateTime focusedDay) {
    // Update focusDate when month changes via swiping
    if (!isSameDay(focusDate, focusedDay)) {
      focusDate = focusedDay;
      isTodaySelected = isSameDay(focusedDay, todayDate);
      notifyListeners();
    }
  }

  Future<void> getLocalDBData({bool force = false}) async {
    // Prevent reload immediately after delete to avoid reappearing events
    if (_justDeleted && !force) {
      _justDeleted = false; // Reset flag after skipping one call
      return;
    }
    // Prevent multiple simultaneous calls unless forced
    if (_isLoadingData && !force) return;
    _isLoadingData = true;
    
    try {
    final dbDatas = await DBHelper().getCalendarData();
    final onlineDBData = (await downloadAndParseCsv())
        .map((e) => e.copyWith(updateCanEdit: false));
    
      // Get list of deleted events from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final deletedEvents = prefs.getStringList('deleted_calendar_events') ?? [];
      final deletedEventsSet = deletedEvents.toSet();
      log('Loaded ${deletedEvents.length} deleted event identifiers');
    
    // Deduplicate events: prioritize DB events over online events if same ID
    Map<int?, CalendarModel> uniqueEventsById = {};
    List<CalendarModel> eventsWithoutId = [];
    
    // First, add all events with IDs (prioritize DB events)
    for (var event in dbDatas) {
      if (event.id != null) {
        uniqueEventsById[event.id] = event;
      } else {
        eventsWithoutId.add(event);
      }
    }
    
    // Helper function to create event identifier
    String createEventIdentifier(CalendarModel event) {
      if (event.title == null || event.date == null) {
        return event.id != null ? 'id_${event.id}' : '';
      }
      try {
        final eventDate = DateTime.parse(event.date!);
        final normalizedDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        return '${event.title}_${normalizedDate.toString()}';
      } catch (e) {
        return '${event.title}_${event.date}';
      }
    }
    
    // Add online events only if not already in DB and not deleted by user
    for (var event in onlineDBData) {
      final eventIdentifier = createEventIdentifier(event);
      
      // Skip if this event was deleted by the user
      if (eventIdentifier.isNotEmpty && deletedEventsSet.contains(eventIdentifier)) {
        log('Skipping deleted online event: $eventIdentifier');
        continue;
      }
      
      if (event.id != null && !uniqueEventsById.containsKey(event.id)) {
        uniqueEventsById[event.id] = event;
      } else if (event.id == null) {
        eventsWithoutId.add(event);
      }
    }
    
    // Deduplicate events without ID based on title+date
    List<CalendarModel> uniqueEventsWithoutId = [];
    Set<String> seenTitleDate = {};
    for (var event in eventsWithoutId) {
      final key = '${event.title}_${event.date}';
      if (!seenTitleDate.contains(key)) {
        seenTitleDate.add(key);
        uniqueEventsWithoutId.add(event);
      }
    }
    
    overAllCalendarData = [...uniqueEventsById.values, ...uniqueEventsWithoutId];
    
    // Group events by date and deduplicate within each date
    Map<DateTime, List<CalendarModel>> kEventSource = {};
    
    // First, group all events by date
    for (var event in overAllCalendarData) {
      final parseDate = DateTime.parse(event.date ?? DateTime.now().toString());
      final dateInFormat =
          DateTime(parseDate.year, parseDate.month, parseDate.day);
      
      if (!kEventSource.containsKey(dateInFormat)) {
        kEventSource[dateInFormat] = [];
      }
      kEventSource[dateInFormat]!.add(event);
    }
    
    // Now deduplicate events within each date
    // Use both ID and title+date combination to catch all duplicates
    for (var date in kEventSource.keys) {
      List<CalendarModel> deduplicatedEvents = [];
      Set<String> seenEventKeys = {};
      Set<String> seenTitleDate = {}; // Track title+date to catch duplicates even with different IDs
      
      for (var e in kEventSource[date]!) {
        String eventKey;
        String titleDateKey = '${e.title}_${e.date}';
        
        if (e.id != null) {
          eventKey = 'id_${e.id}';
        } else {
          eventKey = 'title_${e.title}_date_${e.date}';
        }
        
        // Check both ID key and title+date key to prevent duplicates
        // This handles cases where same event has different IDs (duplicates in DB)
        if (!seenEventKeys.contains(eventKey) && !seenTitleDate.contains(titleDateKey)) {
          seenEventKeys.add(eventKey);
          seenTitleDate.add(titleDateKey);
          deduplicatedEvents.add(e);
        }
      }
      
      kEventSource[date] = deduplicatedEvents;
    }
    
    // Clear existing events before adding to prevent duplicates
    kEvents.clear();
    kEvents.addAll(kEventSource);

    notifyListeners();
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> addCalendarData() async {
    log('${editData == null}');
    if (editData == null) {
      final newData =
          CalendarModel(title: fieldCon.text, date: focusDate.toString());
      try {
        // Check if an event with the same title and date already exists
        final existingEvents = await DBHelper().getCalendarData();
        final dateString = focusDate.toString();
        // Normalize dates for comparison (compare only date part, not time)
        final focusDateNormalized = DateTime(focusDate.year, focusDate.month, focusDate.day);
        final duplicateExists = existingEvents.any((event) {
          if (event.title != newData.title) return false;
          if (event.date == null) return false;
          try {
            final eventDate = DateTime.parse(event.date!);
            final eventDateNormalized = DateTime(eventDate.year, eventDate.month, eventDate.day);
            return eventDateNormalized == focusDateNormalized;
          } catch (e) {
            // If date parsing fails, compare strings
            return event.date == dateString;
          }
        });
        
        if (duplicateExists) {
          Constants.showToast('This event already exists for this date');
          cancelField();
          return;
        }
        
        await DBHelper().saveCalendarData(newData);
        // Reload from DB to get the event with proper ID and prevent duplicates
        await getLocalDBData();
        cancelField();
        Constants.showToast('Saved Data Successfully');
      } catch (e) {
        log('Error Adding Calendar Data: $e');
      }
    } else {
      final updatedData =
          editData?.copyWith(newTitle: fieldCon.text) ?? CalendarModel();
      try {
        await DBHelper().updateCalendarData(updatedData);
        // Reload from DB to ensure data consistency and prevent duplicates
        await getLocalDBData();
        editData = null;
        cancelField();
        Constants.showToast('Updated Data Successfully');
      } catch (e) {
        log('Error Updating Calendar Data: $e');
      }
    }
  }

  Future<void> deleteCalendarData(CalendarModel data) async {
    log('Delete Calendar ID: ${data.id}, Title: ${data.title}, Date: ${data.date}');
    try {
      if (data.id != null && data.id! > 0) {
        final deleteResult = await DBHelper().deleteCalendarData(data.id!);
        log('Delete result: $deleteResult rows deleted');
        if (deleteResult > 0) {
          // Immediately remove from local data structures
          final beforeCount = overAllCalendarData.length;
          overAllCalendarData.removeWhere((element) => element.id == data.id);
          final afterCount = overAllCalendarData.length;
          log('Removed from overAllCalendarData: ${beforeCount > afterCount}');
          
          // Remove from all dates in kEvents, not just focusDate
          int removedFromEvents = 0;
          for (var date in kEvents.keys.toList()) {
            final beforeCount = kEvents[date]?.length ?? 0;
            kEvents[date]?.removeWhere((element) => element.id == data.id);
            final afterCount = kEvents[date]?.length ?? 0;
            if (beforeCount > afterCount) {
              removedFromEvents++;
            }
            // Remove the date key if no events remain
            if (kEvents[date]!.isEmpty) {
              kEvents.remove(date);
            }
          }
          log('Removed from $removedFromEvents date(s) in kEvents');
          
          _justDeleted = true; // Set flag to prevent immediate reload
          notifyListeners();
      Constants.showToast('Deleted Data Successfully');
          
          // Verify deletion by checking database
          final verifyDelete = await DBHelper().getCalendarData();
          final stillExists = verifyDelete.any((e) => e.id == data.id);
          if (stillExists) {
            log('WARNING: Event still exists in database after delete!');
          } else {
            log('Delete verified: Event no longer in database');
          
          // Store deleted event identifier in SharedPreferences to prevent it from reappearing
          if (data.title != null && data.date != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final deletedEvents = prefs.getStringList('deleted_calendar_events') ?? [];
              final eventDate = DateTime.parse(data.date!);
              final normalizedDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
              final eventIdentifier = '${data.title}_${normalizedDate.toString()}';
              if (!deletedEvents.contains(eventIdentifier)) {
                deletedEvents.add(eventIdentifier);
                await prefs.setStringList('deleted_calendar_events', deletedEvents);
                log('Stored deleted event identifier: $eventIdentifier');
              }
            } catch (e) {
              log('Error storing deleted event identifier: $e');
            }
          }
          }
        } else {
          log('Delete failed: No rows deleted');
          Constants.showToast('Failed to delete event');
        }
      } else {
        // For events without ID, remove by title and date
        overAllCalendarData.removeWhere((element) => 
            element.title == data.title && element.date == data.date);
        // Remove from all dates in kEvents, not just focusDate
        for (var date in kEvents.keys.toList()) {
          kEvents[date]?.removeWhere((element) => 
              element.title == data.title && element.date == data.date);
          // Remove the date key if no events remain
          if (kEvents[date]!.isEmpty) {
            kEvents.remove(date);
          }
        }
        _justDeleted = true; // Set flag to prevent immediate reload
      notifyListeners();
        Constants.showToast('Deleted Data Successfully');
      }
    } catch (e) {
      log('Error Deleting Calendar Data: $e');
      Constants.showToast('Error deleting event');
    }
  }

  @override
  void dispose() {
    super.dispose();
    fieldCon.dispose();
  }
}
