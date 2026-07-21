import 'dart:developer';
import 'package:biblebookapp/Model/bookMarkModel.dart';
import 'package:biblebookapp/Model/highLightContentModal.dart';
import 'package:biblebookapp/Model/saveImagesModel.dart';
import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';

class OverallDbModel {
  final List<BookMarkModel>? bookmark;

  final List<HighLightContentModal>? highlight;
  final List<BookMarkModel>? underline;
  final List<SaveNotesModel>? notes;
  final List<SaveImageModel>? images;
  final List<CalendarModel>? calendar;
  final List<String>? wallpaper;
  final List<String>? quotes;
  final List<VerseBookContentModel>? versecontent;

  OverallDbModel(
      {this.bookmark,
      this.highlight,
      this.underline,
      this.images,
      this.wallpaper,
      this.quotes,
      this.calendar,
      this.notes,
      this.versecontent});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bookmark'] = bookmark?.map((e) => e.toJson()).toList();
    map['highlight'] = highlight?.map((e) => e.toJson()).toList();
    map['underline'] = underline?.map((e) => e.toJson()).toList();
    map['notes'] = notes?.map((e) => e.toJson()).toList();
    map['images'] = images?.map((e) => e.toJson()).toList();
    map['calendar'] = calendar?.map((e) => e.toJson()).toList();
    map['calendar'] = calendar?.map((e) => e.toJson()).toList();
    map['verse'] = versecontent?.map((e) => e.toJson()).toList();

    map['wallpaper'] = wallpaper;
    map['quotes'] = quotes;
    return map;
  }

  Future<void> updateLocalDB() async {
    // Use awaited for-loops (not forEach+async) so restore finishes before UI opens.
    for (final e in bookmark ?? const <BookMarkModel>[]) {
      await DBHelper().insertBookmark(e);
      await DBHelper().updateVersesDataByContent(
          e.content.toString(), 'is_bookmarked', 'yes');
//! plaincontent is versse id
      await DBHelper().updateVersesData(
          int.parse(e.plaincontent.toString()), 'is_bookmarked', 'yes');
    }
    for (final e in highlight ?? const <HighLightContentModal>[]) {
      await DBHelper().insertIntoHighLight(e);
      await DBHelper().updateVersesDataByContent(
          e.content.toString(), 'is_highlighted', '${e.color}');
      //! plaincontent is versse id
      await DBHelper().updateVersesData(
          int.parse(e.verseid ?? '0'), 'is_highlighted', '${e.color}');
    }
    for (final e in underline ?? const <BookMarkModel>[]) {
      await DBHelper().insertUnderLine(e);
      await DBHelper().updateVersesDataByContent(
          e.content.toString(), 'is_underlined', 'yes');
      //! plaincontent is versse id
      await DBHelper().updateVersesData(
          int.parse(e.plaincontent.toString()), 'is_underlined', 'yes');
    }
    for (final e in notes ?? const <SaveNotesModel>[]) {
      await DBHelper().insertNotes(e);
      await DBHelper().updateVersesDataByContent(
          e.content.toString(), 'is_noted', '${e.notes}');
//! plaincontent is versse id
      await DBHelper().updateVersesData(
          int.parse(e.plaincontent.toString()), 'is_noted', '${e.notes}');
    }
    for (final e in images ?? const <SaveImageModel>[]) {
      await DBHelper().saveImage(e);
    }
    for (final e in calendar ?? const <CalendarModel>[]) {
      await DBHelper().saveCalendarData(e);
    }

    // for (var e in versecontent!) {
    //   if (e.id != null) {
    //     Map<String, dynamic> updates = {};

    //     var jsonData = e.toJson();

    //     // Collect non-null values to update
    //     for (var key in [
    //       // 'is_bookmarked',
    //       // 'is_highlighted',
    //       // 'is_noted',
    //       'is_read',
    //       //'is_underlined'
    //     ]) {
    //       if (jsonData[key] != null) {
    //         updates[key] = jsonData[key];
    //       }
    //     }

    //     if (updates.isNotEmpty) {
    //       await DBHelper().updateVersesDataBatch(e.id!, updates);
    //     }

    //   }
    // }

    await SharPreferences.setListString(
        SharPreferences.wallpaperBookMark, wallpaper ?? []);
    await SharPreferences.setListString(
        SharPreferences.quotesBookMark, quotes ?? []);
  }

  Future<void> updateLocalDBsync() async {
    // Awaited for-loops so plain-text verse flag updates complete before Home opens.
    for (final e in bookmark ?? const <BookMarkModel>[]) {
      //  await DBHelper().insertBookmark(e);
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_bookmarked', 'yes');
    }
    for (final e in highlight ?? const <HighLightContentModal>[]) {
      // Prefer plain_content when present (highlight body is stored as plain text).
      final plain = (e.plain_content != null &&
              e.plain_content!.trim().isNotEmpty)
          ? e.plain_content!.toString()
          : e.content.toString();
      //  await DBHelper().insertIntoHighLight(e);
      await DBHelper().updateVersesDataByContentnew(
          plain, 'is_highlighted', '${e.color}');
    }
    for (final e in underline ?? const <BookMarkModel>[]) {
      //await DBHelper().insertUnderLine(e);
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_underlined', 'yes');
    }
    for (final e in notes ?? const <SaveNotesModel>[]) {
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_noted', '${e.notes}');
    }

    for (final e in calendar ?? const <CalendarModel>[]) {
      await DBHelper().saveCalendarData(e);
    }
  }

  factory OverallDbModel.fromJson(Map<String, dynamic> data) {
    try {
      final bookmark = (data['bookmark'] as List?)
          ?.map((e) => BookMarkModel.fromJson(e))
          .toList();
      final highlight = (data['highlight'] as List?)
          ?.map((e) => HighLightContentModal.fromJson(e))
          .toList();
      final underline = (data['underline'] as List?)
          ?.map((e) => BookMarkModel.fromJson(e))
          .toList();
      final notes = (data['notes'] as List?)
          ?.map((e) => SaveNotesModel.fromJson(e))
          .toList();
      final images = (data['images'] as List?)
          ?.map((e) => SaveImageModel.fromJson(e))
          .toList();
      final calender = (data['calendar'] as List?)
          ?.map((e) => CalendarModel.fromJson(e))
          .toList();
      final versecontent = (data['verse'] as List?)
          ?.map((e) => VerseBookContentModel.fromJson(e))
          .toList();
      final List<String> wallpaper =
          (data['wallpaper'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final List<String> quotes =
          (data['quotes'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return OverallDbModel(
          bookmark: bookmark,
          highlight: highlight,
          underline: underline,
          notes: notes,
          images: images,
          wallpaper: wallpaper,
          quotes: quotes,
          calendar: calender,
          versecontent: versecontent);
    } catch (e, st) {
      log('Error: $e ,$st');
      rethrow;
    }
  }
}
