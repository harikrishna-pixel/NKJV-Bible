import 'package:biblebookapp/Model/bookMarkModel.dart';
import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:flutter/widgets.dart';

class HomeContentEditProvider extends ChangeNotifier {
  bool _isBookmarked = false;
  bool get isBookmarked => _isBookmarked;

  bool _isNoted = false;
  bool get isNoted => _isNoted;

  set setIsBookmarked(bool val) {
    _isBookmarked = val;
    notifyListeners();
  }

  set setIsNoted(bool val) {
    _isNoted = val;
    notifyListeners();
  }

  Future<void> toggleBookmark({
    required VerseBookContentModel verseData,
    required Function(String) showDialog,
    required String content,
    required int verseId,
    required BookMarkModel bookmarkModel,
    required Function(VerseBookContentModel) updateVerseCallback,
  }) async {
    final isCurrentlyBookmarked = verseData.isBookmarked == "yes";

    final updated =
        verseData.copyWith(isBookmarked: isCurrentlyBookmarked ? "no" : "yes");
    updateVerseCallback(updated);

    if (isCurrentlyBookmarked) {
      await DBHelper().updateVersesData(verseId, "is_bookmarked", "no");
      await DBHelper().deleteBookmarkByContent(content);
      _isBookmarked = false;
      showDialog("Removed Successfully!");
    } else {
      await DBHelper().updateVersesData(verseId, "is_bookmarked", "yes");
      await DBHelper().insertBookmark(bookmarkModel);
      _isBookmarked = true;
      showDialog("Marked Successfully!");
    }

    notifyListeners();
  }

  Future<void> toggleUnderline({
    required VerseBookContentModel verseData,
    required Function(String) showDialog,
    required String content,
    required int verseId,
    required BookMarkModel underlineModel,
    required Function(VerseBookContentModel) updateVerseCallback,
  }) async {
    final isCurrentlyUnderlined = verseData.isUnderlined == "yes";

    final updated = verseData.copyWith(
      isUnderlined: isCurrentlyUnderlined ? "no" : "yes",
    );
    updateVerseCallback(updated);

    try {
      await DBHelper().updateVersesData(
        verseId,
        "is_underlined",
        isCurrentlyUnderlined ? "no" : "yes",
      );

      if (isCurrentlyUnderlined) {
        await DBHelper().deleteUnderlineByContent(content);
        showDialog("Removed Successfully!");
      } else {
        await DBHelper().insertUnderLine(underlineModel);
        showDialog("Underlined Successfully!");
      }

      notifyListeners();
    } catch (e) {
      DebugConsole.log("underline error - $e");
    }
  }

  Future<void> toggleNote({
    required VerseBookContentModel verseData,
    required String noteContent,
    required int verseId,
    required SaveNotesModel noteModel,
    required Function(VerseBookContentModel) updateVerseCallback,
    required BuildContext context,
    required Function() onSuccess,
    required Function() onDelete,
  }) async {
    final isCurrentlyNoted = verseData.isNoted != "no";

    if (isCurrentlyNoted) {
      // Update existing note
      if (noteContent.isNotEmpty) {
        final updated = verseData.copyWith(isNoted: noteContent);
        updateVerseCallback(updated);

        await Future.wait([
          DBHelper().updateVersesData(verseId, "is_noted", noteContent),
          DBHelper().updateNotesData(
            verseData.content,
            "notes",
            noteContent,
          ),
        ]);

        _isNoted = true;
        onSuccess();
      } else {
        // Delete note
        final updated = verseData.copyWith(isNoted: "no");
        updateVerseCallback(updated);

        await Future.wait([
          DBHelper().updateVersesData(verseId, "is_noted", "no"),
          DBHelper().deleteNotesByContent(verseData.content),
        ]);

        _isNoted = false;
        onDelete();
      }
    } else {
      // Add new note
      if (noteContent.isNotEmpty) {
        final updated = verseData.copyWith(isNoted: noteContent);
        updateVerseCallback(updated);

        await Future.wait([
          DBHelper().updateVersesData(verseId, "is_noted", noteContent),
          DBHelper().insertNotes(noteModel),
        ]);

        _isNoted = true;
        onSuccess();
      }
    }

    notifyListeners();
  }

  Future<void> deleteNote({
    required VerseBookContentModel verseData,
    required int verseId,
    required String content,
    required Function(VerseBookContentModel) updateVerseCallback,
    required Function() onSuccess,
  }) async {
    final updated = verseData.copyWith(isNoted: "no");
    updateVerseCallback(updated);

    await Future.wait([
      DBHelper().updateVersesData(verseId, "is_noted", "no"),
      DBHelper().deleteNotesByContent(content),
    ]);

    _isNoted = false;
    onSuccess();
    notifyListeners();
  }

  Future<void> resetVerseAttributes({
    required int verseId,
    required String content,
    required Function(VerseBookContentModel) updateVerseCallback,
  }) async {
    // Reset all attributes in the database
    await Future.wait([
      DBHelper().updateVersesData(verseId, "is_bookmarked", "no"),
      DBHelper().updateVersesData(verseId, "is_noted", "no"),
      DBHelper().updateVersesData(verseId, "is_highlighted", "no"),
      DBHelper().updateVersesData(verseId, "is_underlined", "no"),
      DBHelper().deleteBookmarkByContent(content),
      DBHelper().deleteHighlightByContent(content),
      DBHelper().deleteNotesByContent(content),
      DBHelper().deleteUnderlineByContent(content),
    ]);

    // Update provider state
    _isBookmarked = false;
    _isNoted = false;
    notifyListeners();
  }
}
