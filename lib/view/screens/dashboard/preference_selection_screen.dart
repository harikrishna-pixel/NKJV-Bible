import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:biblebookapp/Model/dailyVersesMainListModel.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/onboard_faith_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';

class PreferenceSelectionScreen extends StatefulWidget {
  final bool isSetting;
  bool? from;
  String? selectedbible;
  PreferenceSelectionScreen({
    super.key,
    this.selectedbible,
    this.from,
    required this.isSetting,
  });

  @override
  PreferenceSelectionScreenState createState() =>
      PreferenceSelectionScreenState();
}

class PreferenceSelectionScreenState extends State<PreferenceSelectionScreen> {
  bool isLoading = false;
  List<MainBookListModel> bookList = [];
  List<VerseBookContentModel> versesContent = [];
  List<DailyVersesMainListModel> dailyVerseDataList = [];
  Map<String, String> _iconNames = {
    // // "Anxiety": "headache",
    // "Hope": "protest",
    // //"Depression": "sad",
    // "God's Promises": "encouragement",
    // "faith-in-hard-times": "pray1",
    // "Courage": "family",
    // "Forgiveness": "love",
    // "Friendship": "people",
    // "Healing": "healing",
    // "Motivational": "dancing",
    // // "Loneliness": "alone",
    // "Love": "engagement-ring",
    // "Comforting": "compassion",
    // "Peace": "dove",
    // "Protection": "shield",
    // "Prayers": "pray",
    // "Salvation": "salvation",
    // "Thankful": "thank-you",
    // "Trust": "trust",
    // // "Women of Strength": "feminism",
  };

  int saveDay = 9;
  Set<String> _selectedCategories = {};
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    loadIconNames();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getStringList('selected_categories') ?? [];
    setState(() {
      _selectedCategories = saved.toSet();
    });
  }

  Future<void> loadIconNames() async {
    final dbClient = await DBHelper().db;
    final dailyVersesMainData =
        await dbClient?.rawQuery("SELECT * FROM dailyVersesMainList");

    // Build the map from Category_Name
    final Map<String, String> categoryIcons = {};
    debugPrint("daily verse -${dailyVersesMainData?.length} ");
    for (var item in dailyVersesMainData!) {
      final categoryName = item['Category_Name']?.toString();
      if (categoryName != null && categoryName.isNotEmpty) {
        categoryIcons[categoryName] = categoryName;
      }
    }

    _iconNames = categoryIcons;
    await _loadPreferences();
  }

  // Future<void> _savePreferences() async {
  //   await _prefs.setStringList(
  //       'selected_categories', _selectedCategories.toList());

  //   DBHelper().db.then((dailyVersesMainList) {
  //     dailyVersesMainList!
  //         .rawQuery("SELECT * From dailyVersesMainList")
  //         .then((dailyVersesMainData) async {
  //       for (var i = 0; i < dailyVersesMainData.length; i++) {
  //         var selectedVersesMainData = DailyVersesMainListModel(
  //           verse: dailyVersesMainData[i]["Verse"].toString().length == 2
  //               ? "${int.parse(dailyVersesMainData[i]["Verse"].toString()) - 1}"
  //               : "${int.parse(dailyVersesMainData[i]["Verse"].toString().split("-").first) - 1}",
  //           book: "${dailyVersesMainData[i]["Book"]}",
  //           bookId: int.parse(dailyVersesMainData[i]["Book_Id"].toString()) - 1,
  //           categoryId:
  //               int.parse(dailyVersesMainData[i]["Category_Id"].toString()),
  //           categoryName: "${dailyVersesMainData[i]["Category_Name"]}",
  //           chapter:
  //               int.parse(dailyVersesMainData[i]["Chapter"].toString()) - 1,
  //         );
  //         await dailyVersesMainList.execute('DELETE FROM dailyVersesnew');
  //         await dailyVersesMainList
  //             .rawQuery(
  //                 "SELECT * From verse WHERE book_num ='${int.parse(selectedVersesMainData.bookId.toString())}' AND chapter_num ='${int.parse(selectedVersesMainData.chapter.toString())}' AND verse_num ='${int.parse(selectedVersesMainData.verse.toString())}'")
  //             .then((selectedDailyVersesResponse) async {
  //           //    late SharedPreferences _prefs;
  //           // print("selectedDailyVersesResponse");
  //           // print(selectedDailyVersesResponse);
  //           SharedPreferences prefs = await SharedPreferences.getInstance();
  //           List<String> selectedCategories =
  //               prefs.getStringList('selected_categories') ?? [];

  //           for (int i = 0; i < dailyVersesMainData.length; i++) {
  //             dynamic categoryName = dailyVersesMainData[i]["Category_Name"];

  //             if (selectedCategories.contains(categoryName)) {
  //               final bookId =
  //                   int.parse(dailyVersesMainData[i]["Book_Id"].toString());
  //               final chapter =
  //                   int.parse(dailyVersesMainData[i]["Chapter"].toString());
  //               final verse = int.parse(
  //                 dailyVersesMainData[i]["Verse"].toString().contains("-")
  //                     ? dailyVersesMainData[i]["Verse"]
  //                         .toString()
  //                         .split("-")
  //                         .first
  //                     : dailyVersesMainData[i]["Verse"].toString(),
  //               );

  //               List<Map<String, dynamic>> selectedDailyVersesResponse =
  //                   await dailyVersesMainList.rawQuery(
  //                 "SELECT * FROM verse WHERE book_num = '$bookId' AND chapter_num = '$chapter' AND verse_num = '$verse'",
  //               );

  //               if (selectedDailyVersesResponse.isNotEmpty) {
  //                 await dailyVersesMainList.transaction((txn) async {
  //                   var batch = txn.batch();
  //                   var date = DateTime.now().subtract(Duration(days: saveDay));

  //                   var insertData = {
  //                     "Category_Name": categoryName,
  //                     "Category_Id": dailyVersesMainData[i]["Category_Id"],
  //                     "Book": dailyVersesMainData[i]["Book"],
  //                     "Book_Id": bookId,
  //                     "Chapter": chapter,
  //                     "Verse": selectedDailyVersesResponse[0]["content"],
  //                     "Date": "$date",
  //                     "Verse_Num": verse,
  //                   };

  //                   saveDay = saveDay - 1;

  //                   batch.insert('dailyVersesnew', insertData);
  //                   await batch.commit();
  //                 });
  //               }
  //             }
  //           }
  //         });
  //       }
  //     });
  //   });
// }
  // Future<void> _savePreferences() async {
  //   await _prefs.setStringList(
  //       'selected_categories', _selectedCategories.toList());

  //   final dbClient = await DBHelper().db;
  //   if (dbClient == null) return;

  //   final dailyVersesMainData =
  //       await dbClient.rawQuery("SELECT * FROM dailyVersesMainList");

  //   // Clear the table before inserting new values
  //   await dbClient.execute("DELETE FROM dailyVersesnew");

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> selectedCategories =
  //       prefs.getStringList('selected_categories') ?? [];

  //   int totalEntries = dailyVersesMainData.length;

  //   for (int i = 0; i < totalEntries; i++) {
  //     final data = dailyVersesMainData[i];
  //     final categoryName = data["Category_Name"];

  //     if (selectedCategories.contains(categoryName)) {
  //       final bookId = int.parse(data["Book_Id"].toString());
  //       final chapter = int.parse(data["Chapter"].toString());
  //       final verse = int.parse(
  //         data["Verse"].toString().contains("-")
  //             ? data["Verse"].toString().split("-").first
  //             : data["Verse"].toString(),
  //       );

  //       final selectedVerseResponse = await dbClient.rawQuery(
  //         "SELECT * FROM verse WHERE book_num = '$bookId' AND chapter_num = '$chapter' AND verse_num = '$verse'",
  //       );

  //       if (selectedVerseResponse.isNotEmpty) {
  //         final date = DateTime.now().add(Duration(days: i)); // forward
  //         // Use subtract(Duration(days: totalEntries - i - 1)) if you want to go backward

  //         final insertData = {
  //           "Category_Name": categoryName,
  //           "Category_Id": data["Category_Id"],
  //           "Book": data["Book"],
  //           "Book_Id": bookId,
  //           "Chapter": chapter,
  //           "Verse": selectedVerseResponse[0]["content"],
  //           "Date": "$date",
  //           "Verse_Num": verse,
  //         };

  //         await dbClient.transaction((txn) async {
  //           final batch = txn.batch();
  //           batch.insert('dailyVersesnew', insertData);
  //           await batch.commit(noResult: true);
  //         });
  //       }
  //     }
  //   }
  // }

  Future<void> _savePreferences() async {
    final saveProvider = Provider.of<DownloadProvider>(context, listen: false);
    await saveProvider.saveInBackground(
        selectedCategories: _selectedCategories.toList());

    // if (widget.isSetting) {
    //   Constants.showToast("Saved successfully");
    //   Get.back();
    // } else {
    //   if (widget.selectedbible != null && widget.selectedbible!.isNotEmpty) {
    //     FaithJourneyDialog.showLoadingDialog(context);
    //     await loadBookContent(widget.selectedbible);
    //     await loadBookList(widget.selectedbible);
    //     await deleteFiles(widget.selectedbible);
    //     Navigator.pop(context); // Close loading
    //     FaithJourneyDialog.showSuccessDialog(context);

    //     // Get.offAll(() => HomeScreen(
    //     //       From: "splash",
    //     //       selectedVerseNumForRead: "",
    //     //       selectedBookForRead: "",
    //     //       selectedChapterForRead: "",
    //     //       selectedBookNameForRead: "",
    //     //       selectedVerseForRead: "",
    //     //     ));
    //   }
    // }
  }

  void _toggleSelection(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> loadBookContent(foldername) async {
    final db = await DBHelper().db;
    if (db == null) {
      debugPrint("testapp: Database is null.");
      return;
    }

    try {
      // Step 1: Clear existing data
      await db.delete('verse');
      debugPrint("testapp: Verse table cleared.");
      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDocDir.path}/$foldername-extracted/verse_json.json';
      // Step 2: Extract JSON from zip
      final String response = await File(filePath).readAsString();

      // Step 3: Parse JSON in background isolate
      final tempList = await compute(_parseVerseContent, response);

      // Step 4: Store in memory
      versesContent = tempList;

      // Step 5: Insert into DB using batch
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final verse in tempList) {
          batch.insert('verse', {
            "book_num": verse.bookNum,
            "chapter_num": verse.chapterNum,
            "verse_num": verse.verseNum,
            "content": verse.content,
            "is_bookmarked": verse.isBookmarked,
            "is_highlighted": verse.isHighlighted,
            "is_noted": verse.isNoted,
            "is_read": verse.isRead,
            "is_underlined": verse.isUnderlined,
          });
        }
        final isUpload = await batch.commit();
        if (isUpload.isNotEmpty) {
          debugPrint("testapp: Verse content inserted into DB.");
        }
      });

      // Step 6: Save flag in SharedPreferences
      await SharPreferences.setBoolean(SharPreferences.isLoadBookContent, true);
    } catch (e, st) {
      debugPrint("testapp: Error loading verse content → $e\n$st");
    }
  }

  Future<void> loadBookList(foldername) async {
    final db = await DBHelper().db;
    if (db == null) {
      debugPrint("testapp: Database is null.");
      return;
    }

    try {
      // Step 1: Clear existing data
      await db.delete('book');
      debugPrint("testapp: Book table cleared.");

      final appDocDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDocDir.path}/$foldername-extracted/book.json';
      // Step 2: Extract JSON from zip
      final String response = await File(filePath).readAsString();

      // Step 3: Parse JSON in background isolate
      final tempBookList = await compute(_parseAndPrepareBooks, response);

      // Step 4: Store in memory
      bookList = tempBookList;

      // Step 5: Insert into DB using batch
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final book in tempBookList) {
          batch.insert('book', {
            "book_num": book.bookNum,
            "chapter_count": book.chapterCount,
            "title": book.title,
            "short_title": book.shortTitle,
            "read_per": book.readPer,
          });
        }
        final isUpload = await batch.commit();
        if (isUpload.isNotEmpty) {
          debugPrint("testapp: Books inserted into DB.");
        }
      });

      // Step 6: Save flag in SharedPreferences
      await SharPreferences.setBoolean(SharPreferences.isLoadBookList, true);
    } catch (e, st) {
      debugPrint("testapp: Error loading book list: $e\n$st");
    }
  }

  Future<void> deleteFiles(foldername) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Define file paths
      final file1 = File('${directory.path}/$foldername-extracted/book.json');
      final file2 =
          File('${directory.path}/$foldername-extracted/verse_json.json');

      // Check and delete file1
      if (await file1.exists()) {
        await file1.delete();
        debugPrint('file1.txt deleted successfully');
      } else {
        debugPrint('file1.txt does not exist');
      }

      // Check and delete file2
      if (await file2.exists()) {
        await file2.delete();
        debugPrint('file2.txt deleted successfully');
      } else {
        debugPrint('file2.txt does not exist');
      }
    } catch (e) {
      debugPrint('Error deleting files: $e');
    }
  }

  bool _isSelected(String category) => _selectedCategories.contains(category);

  // String _getIconPath(String name, bool selected) {
  //   final baseName = _iconNames[name] ?? 'default';
  //   return 'assets/icons/$baseName${!selected ? "_b" : ""}.png';
  // }

  String _getIconPath(String name, bool selected) {
    final baseName = _iconNames[name] ?? 'default';
    final folder = !selected ? 'lightMode' : 'nightMode';
    return 'assets/$folder/icons/$baseName.png';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor =
        isDark ? CommanColor.darkPrimaryColor : themeProvider.backgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? null
            : backgroundColor,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                color: backgroundColor,
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.fill))
            : null,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                height: 10,
              ),
              widget.isSetting == true
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            // checknotification();
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: screenWidth > 600 ? 29 : 20,
                            color: CommanColor.whiteBlack(context),
                          ),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.only(right: 15.0),
                        //   child: Text("Change Preferences",
                        //       style: CommanStyle.appBarStyle(context).copyWith(
                        //           fontSize: screenWidth > 600
                        //               ? BibleInfo.fontSizeScale * 21
                        //               : BibleInfo.fontSizeScale * 18)),
                        // ),
                        const SizedBox(),
                        const SizedBox()
                      ],
                    )
                  : InkWell(
                      onTap: () {
                        // checknotification();
                        // If coming from onboarding, navigate to Theme Selection Screen
                        // Otherwise, just pop back
                        if (widget.isSetting == false) {
                          Get.off(() => OnboardingThemeSelectionScreen(
                                onThemeSelected: () {
                                  // Navigate back to PreferenceSelectionScreen after theme selection
                                  Get.off(() => PreferenceSelectionScreen(
                                        isSetting: false,
                                        selectedbible: widget.selectedbible,
                                      ));
                                },
                              ));
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: screenWidth > 600 ? 29 : 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Jesus Will Guide You!",
                style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 600 ? 25 : 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose your preferred verse topics",
                style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 600 ? 22 : 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: screenWidth > 600 ? 20 : 10,
                    runSpacing: screenWidth > 600 ? 16 : 12,
                    children: _iconNames.entries.map((category) {
                      final selected = _isSelected(category.key);

                      return InkWell(
                        onTap: () => _toggleSelection(category.key),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            // Selected option: background color 805531 with 20% opacity
                            color: selected
                                ? const Color(0xFF805531).withOpacity(0.2)
                                : Colors.transparent,
                            // Border with increased thickness when selected
                            border: Border.all(
                              // Border stroke color: yellow when selected in dark mode, otherwise use default colors
                              color: selected && isDark
                                  ? Colors.yellow // Yellow border for selected topics in dark mode
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF805531)),
                              width: selected
                                  ? 2.0
                                  : 1.0, // Increase thickness when selected
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  // White/Black for normal (unselected) based on theme
                                  // Theme color (805531) when selected in light mode, white when selected in dark mode
                                  selected
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF805531))
                                      : (isDark
                                          ? CommanColor.whiteBlack(context)
                                          : const Color(0xFF805531)),
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  _getIconPath(
                                      category.key,
                                      Provider.of<ThemeProvider>(context,
                                                      listen: false)
                                                  .themeMode ==
                                              ThemeMode.dark
                                          ? !selected
                                          : selected),
                                  width: screenWidth > 600 ? 40 : 20,
                                  height: screenWidth > 600 ? 40 : 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category.key,
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 19 : null,
                                  // White/Black for normal (unselected) based on theme
                                  // Theme color (805531) when selected in light mode, white when selected in dark mode
                                  color: selected
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF805531))
                                      : (isDark
                                          ? CommanColor.whiteBlack(context)
                                          : const Color(0xFF805531)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : _selectedCategories.isNotEmpty
                        ? () async {
                            debugPrint("dailyVersesnew 1");
                            if (widget.isSetting == true) {
                              debugPrint("dailyVersesnew 2");
                              setState(() {
                                isLoading = true;
                              });
                              _savePreferences();
                              await Future.delayed(Duration(seconds: 1));
                              Constants.showToast("Saved successfully");
                              setState(() {
                                isLoading = false;
                              });
                              if (widget.from == true) {
                                Get.offAll(() => HomeScreen(
                                      From: "home",
                                      selectedVerseNumForRead: "",
                                      selectedBookForRead: "",
                                      selectedChapterForRead: "",
                                      selectedBookNameForRead: "",
                                      selectedVerseForRead: "",
                                    ));
                              } else {
                                Get.back();
                              }
                            } else {
                              if (widget.selectedbible != null &&
                                  widget.selectedbible!.isNotEmpty) {
                                setState(() {
                                  isLoading = true;
                                });
                                FaithJourneyDialog.showLoadingDialog(
                                  context,
                                  onContinue: () {
                                    // Show success dialog when user taps Continue
                                    FaithJourneyDialog.showSuccessDialog(context,
                                        isFromOnboarding: !widget.isSetting);
                                  },
                                );
                                debugPrint(
                                    "folders leng - ${BibleInfo.folders.length}");
                                if (BibleInfo.folders.length == 1) {
                                  await extractFromFolder(
                                    folderName: BibleInfo.folders.first,
                                    password: dotenv
                                        .env[AssetsConstants.holybibleKey]
                                        .toString(),
                                  );

                                  await loadBookContent(
                                      BibleInfo.folders.first);
                                  await loadBookList(BibleInfo.folders.first);
                                  // await loadDailyVerseData();
                                  await _savePreferences();
                                  await DBHelper().db.then((db) async {
                                    if (db != null) {
                                      final result = await db.rawQuery(
                                        "SELECT * FROM book WHERE book_num = ?",
                                        [int.parse("0")],
                                      );

                                      if (result.isNotEmpty &&
                                          result[0]["title"] != null) {
                                        final title =
                                            result[0]["title"].toString();
                                        // final data =
                                        //     await SharPreferences.getString(
                                        //           SharPreferences.selectedBook,
                                        //         ) ??
                                        //         "";
                                        // if (data.isEmpty) {
                                        await SharPreferences.setString(
                                          SharPreferences.selectedBook,
                                          title,
                                        );
                                        // }
                                      } else {
                                        debugPrint(
                                            "testapp No book found with book_num = 0");
                                      }
                                    } else {
                                      debugPrint(
                                          "testapp Database instance is null");
                                    }
                                  });
                                  await deleteFiles(BibleInfo.folders.first);
                                  await Future.delayed(Duration(seconds: 2));
                                  setState(() {
                                    isLoading = false;
                                  });
                                  // Don't auto-dismiss - let user tap Continue button
                                  // Navigator.pop(context); // Close loading
                                  // Show success dialog after user dismisses loading dialog
                                  // This will be handled when user taps Continue button
                                } else {
                                  await loadBookContent(widget.selectedbible);
                                  await loadBookList(widget.selectedbible);
                                  // await loadDailyVerseData();
                                  await _savePreferences();
                                  await DBHelper().db.then((db) async {
                                    if (db != null) {
                                      final result = await db.rawQuery(
                                        "SELECT * FROM book WHERE book_num = ?",
                                        [int.parse("0")],
                                      );

                                      if (result.isNotEmpty &&
                                          result[0]["title"] != null) {
                                        final title =
                                            result[0]["title"].toString();
                                        // final data =
                                        //     await SharPreferences.getString(
                                        //           SharPreferences.selectedBook,
                                        //         ) ??
                                        //         "";
                                        // if (data.isEmpty) {
                                        await SharPreferences.setString(
                                          SharPreferences.selectedBook,
                                          title,
                                        );
                                        // }
                                      } else {
                                        debugPrint(
                                            "testapp No book found with book_num = 0");
                                      }
                                    } else {
                                      debugPrint(
                                          "testapp Database instance is null");
                                    }
                                  });
                                  await deleteFiles(widget.selectedbible);
                                  await Future.delayed(Duration(seconds: 2));
                                  setState(() {
                                    isLoading = false;
                                  });
                                  // Don't auto-dismiss - let user tap Continue button
                                  // Navigator.pop(context); // Close loading
                                  // Success dialog will be shown when user taps Continue
                                }
                                // Get.offAll(() => HomeScreen(
                                //       From: "splash",
                                //       selectedVerseNumForRead: "",
                                //       selectedBookForRead: "",
                                //       selectedChapterForRead: "",
                                //       selectedBookNameForRead: "",
                                //       selectedVerseForRead: "",
                                //     ));
                              }
                            }
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     backgroundColor: CommanColor.darkPrimaryColor,
                            //     content: Text(
                            //       'Preferences saved!',
                            //       style: TextStyle(color: CommanColor.white),
                            //     ),
                            //   ),
                            // );
                          }
                        : null,
                child: Center(
                  child: Container(
                    width: screenWidth > 600 ? 160 : 130,
                    height: screenWidth > 600 ? 65 : 40,
                    decoration: BoxDecoration(
                        gradient: _selectedCategories.isNotEmpty
                            ? (Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .themeMode ==
                                    ThemeMode.dark
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF763201),
                                      Color(0xFFD5821F),
                                      Color(0xFF763201),
                                    ],
                                  ))
                            : null,
                        color: _selectedCategories.isNotEmpty
                            ? (Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .themeMode ==
                                    ThemeMode.dark
                                ? CommanColor.backgrondcolor
                                : null)
                            : Color(0XFFC9B7A5),
                        borderRadius: BorderRadius.circular(9) // Brown color
                        ),
                    // onPressed: _selectedCategories.length == 4
                    //     ? () {
                    //         _savePreferences();
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           const SnackBar(
                    //             content: Text('Preferences saved!'),
                    //           ),
                    //         );
                    //       }
                    //     : null,
                    // style: ElevatedButton.styleFrom(
                    //   backgroundColor: const Color(0xFF8B5E3C),
                    //   padding: const EdgeInsets.symmetric(
                    //       horizontal: 40, vertical: 12),
                    // ),
                    child: Center(
                      child: Text(
                          isLoading
                              ? "Loading..."
                              : widget.isSetting == true
                                  ? "Save"
                                  : "Continue",
                          style: TextStyle(
                              fontSize: screenWidth > 600 ? 20 : 17,
                              color: _selectedCategories.isNotEmpty
                                  ? Provider.of<ThemeProvider>(context,
                                                  listen: false)
                                              .themeMode ==
                                          ThemeMode.dark
                                      ? CommanColor.darkPrimaryColor
                                      : CommanColor.white
                                  : null)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              widget.isSetting != true
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You can change these anytime in Settings.",
                          style: TextStyle(
                              color: CommanColor.whiteBlack(context),
                              fontSize: screenWidth > 600 ? 21 : 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    )
                  : SizedBox(),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> extractFromFolder(
      {String? from,
      required String folderName,
      required String password}) async {
    // if (from.toString() != "home") {
    //   setState(() {
    //     buttonStates[folderName] = DownloadButtonState.downloading;
    //     progressMap[folderName] = 0.0;
    //   });
    // }

    try {
      final filesInFolder = [
        "assets/zipped/$folderName/book.json.zip",
        "assets/zipped/$folderName/verse_json.zip",
      ];

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory("${dir.path}/$folderName-extracted");
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      int processed = 0;
      for (final zipPath in filesInFolder) {
        final byteData = await rootBundle.load(zipPath);
        final bytes = byteData.buffer.asUint8List();

        final archive = ZipDecoder().decodeBytes(
          List<int>.from(bytes),
          verify: true,
          password: password,
        );

        final file = archive.files.first;

        if (!file.isFile) {
          throw Exception('The extracted item is not a file.');
        }

        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/$folderName-extracted/${file.name}';

        List<int> rawData = file.content is Uint8List
            ? List<int>.from(file.content)
            : file.content as List<int>;

        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(rawData);

        debugPrint("✅ Extracted: $filePath");

        processed++;
        // setState(() {
        //   progressMap[folderName] = processed / filesInFolder.length;
        // });
        await Future.delayed(const Duration(seconds: 1));
      }
      // if (from.toString() != "home") {
      //   setState(() {
      //     buttonStates[folderName] = DownloadButtonState.open;
      //   });
      // }

      /// ✅ Save state persistently
      //  await _saveDownloadedFolder(folderName);
    } catch (e) {
      debugPrint("❌ Error extracting from $folderName: $e");
      // setState(() {
      //   buttonStates[folderName] = DownloadButtonState.download;
      // });
    }
  }

  Future<void> loadDailyVerseData() async {
    final db = await DBHelper().db;

    // Clear both tables before inserting new data
    await db!.delete("dailyVersesMainList");
    await db.delete("dailyVerses");

    // Load json and parse
    final String dailyVerseResponse =
        await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
    final List<DailyVersesMainListModel> dataList =
        await compute(parseDailyVerseJsond, dailyVerseResponse);

    setState(() {
      dailyVerseDataList = dataList;
    });

    // Insert fresh main list
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in dataList) {
        batch.insert('dailyVersesMainList', {
          "Category_Name": item.mainCategory,
          "Category_Id": item.categoryId,
          "Book": item.book,
          "Book_Id": item.bookId,
          "Chapter": item.chapter,
          "Verse": item.verse, // Keep raw verse number here
        });
      }
      await batch.commit();
    });

    // Insert first 20 daily verses with actual verse content
    int saveDay = 0;
    final newMainList = await db.rawQuery("SELECT * FROM dailyVersesMainList");

    for (var i = 0; i < 20 && i < newMainList.length; i++) {
      final m = newMainList[i];

      final int verseNum = m["Verse"].toString().length == 2
          ? int.parse(m["Verse"].toString()) - 1
          : int.parse(m["Verse"].toString().split("-").first) - 1;

      final selectedVerse = await db.rawQuery(
        "SELECT * FROM verse WHERE book_num ='${int.parse(m["Book_Id"].toString()) - 1}' "
        "AND chapter_num ='${int.parse(m["Chapter"].toString()) - 1}' "
        "AND verse_num ='$verseNum'",
      );

      if (selectedVerse.isNotEmpty) {
        await db.transaction((txn) async {
          final batch = txn.batch();
          final date = DateTime.now().subtract(Duration(days: saveDay));
          batch.insert('dailyVerses', {
            "Category_Name": m["Category_Name"],
            "Category_Id": m["Category_Id"],
            "Book": m["Book"],
            "Book_Id": m["Book_Id"],
            "Chapter": m["Chapter"],
            "Verse": selectedVerse[0]
                ["content"], // ✅ Only Verse content inserted
            "Date": "$date",
            "Verse_Num": m["Verse"].toString().length == 2
                ? int.parse(m["Verse"].toString())
                : int.parse(m["Verse"].toString().split("-").first),
          });
          saveDay = saveDay - 1;
          await batch.commit();
        });
      }
    }

    await SharPreferences.setString(SharPreferences.selectedDailyVerse, "11");
    await SharPreferences.setString(
        SharPreferences.dailyVerseUpdateTime, DateTime.now().toString());
  }
}

// Top-level function for compute
Future<void> processAndInsertVerses(Map<String, dynamic> args) async {
  final List<Map<String, dynamic>> allData = args['allData'];
  final List<String> selectedCategories = args['selectedCategories'];

  final dbClient = await DBHelper().db;
  if (dbClient == null) return;

  await dbClient.execute("DELETE FROM dailyVersesnew");

  List<Map<String, dynamic>> filteredData = allData
      .where((data) => selectedCategories.contains(data["Category_Name"]))
      .toList();

  // Shuffle verses from all selected categories to mix them together
  filteredData.shuffle();

  DateTime currentDate = DateTime.now();

  for (final data in filteredData) {
    final bookId = int.parse(data["Book_Id"].toString());
    final chapter = int.parse(data["Chapter"].toString());
    final verse = int.parse(
      data["Verse"].toString().contains("-")
          ? data["Verse"].toString().split("-").first
          : data["Verse"].toString(),
    );

    final selectedVerseResponse = await dbClient.rawQuery(
      "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
      [bookId, chapter, verse],
    );

    if (selectedVerseResponse.isNotEmpty) {
      final insertData = {
        "Category_Name": data["Category_Name"],
        "Category_Id": data["Category_Id"],
        "Book": data["Book"],
        "Book_Id": bookId,
        "Chapter": chapter,
        "Verse": selectedVerseResponse[0]["content"],
        "Date": "$currentDate",
        "Verse_Num": verse,
      };

      await dbClient.transaction((txn) async {
        final batch = txn.batch();
        batch.insert('dailyVersesnew', insertData);
        await batch.commit(noResult: true);
      });

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
}

Future<List<MainBookListModel>> _parseAndPrepareBooks(String jsonString) async {
  final data = json.decode(jsonString);
  return List.from(data)
      .map<MainBookListModel>((item) => MainBookListModel.fromJson(item))
      .toList();
}

Future<List<VerseBookContentModel>> _parseVerseContent(
    String jsonString) async {
  final data = json.decode(jsonString);
  return List.from(data)
      .map<VerseBookContentModel>(
        (item) => VerseBookContentModel.fromJson(item),
      )
      .toList();
}

class FaithJourneyDialog {
  /// Show Loading Dialog
  static Future<void> showLoadingDialog(BuildContext context, {VoidCallback? onContinue}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _AnimatedJourneyDialog(
          onContinue: onContinue,
        );
      },
    );
  }

  /// Follow-up dialog when user taps Continue
  static Future<void> showNextStepDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final isTablet = mq.width > 600;
        return Center(
          child: Container(
            width: isTablet ? mq.width * 0.45 : mq.width * 0.85,
            padding: EdgeInsets.all(isTablet ? 24 : 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6EBDD), Color(0xFFEBDDC9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD2C1A8), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your journey is ready",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7B5536),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Start now or continue exploring.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 15,
                    color: const Color(0xFF7B5536),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFB16A1E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 14 : 12,
                          ),
                        ),
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: const Color(0xFF7B5536),
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 14 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFFB16A1E),
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        child: Text(
                          "Start Now",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show Success Dialog
  static Future<void> showSuccessDialog(BuildContext context,
      {bool isFromOnboarding = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final isTablet = mq.width > 600;
        final screenWidth = MediaQuery.of(context).size.width;
        return Center(
          child: Container(
            width: isTablet ? mq.width * 0.4 : mq.width * 0.8,
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color.fromARGB(255, 26, 161, 30),
                  size: isTablet ? 95 : 80,
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  "Your Bible Experience Is Ready!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: CommanColor.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "We've personalized your experience\n with verses that reflect your\n spiritual journey.\n\nLet's begin this beautiful walk together in God's Word.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth < 380
                        ? 12.5
                        : isTablet
                            ? 16
                            : 14.7,
                    color: CommanColor.black,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // Close dialog
                    if (isFromOnboarding) {
                      final sixMonthPlan =
                          await SharPreferences.getString('sixMonthPlan') ??
                              BibleInfo.sixMonthPlanid;
                      final oneYearPlan =
                          await SharPreferences.getString('oneYearPlan') ??
                              BibleInfo.oneYearPlanid;
                      final lifeTimePlan =
                          await SharPreferences.getString('lifeTimePlan') ??
                              BibleInfo.lifeTimePlanid;
                      Get.offAll(() => SubscriptionScreen(
                            sixMonthPlan: sixMonthPlan,
                            oneYearPlan: oneYearPlan,
                            lifeTimePlan: lifeTimePlan,
                            checkad: 'onboard',
                          ));
                    } else {
                      Get.offAll(() => HomeScreen(
                            From: "splash",
                            selectedVerseNumForRead: "",
                            selectedBookForRead: "",
                            selectedChapterForRead: "",
                            selectedBookNameForRead: "",
                            selectedVerseForRead: "",
                          ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero, // REQUIRED
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF763201),
                          Color(0xFFD5821F),
                          Color(0xFF763201),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40 : 24,
                        vertical: isTablet ? 16 : 12,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Start now",
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const CustomLoadingIndicator({
    super.key,
    this.size = 50,
    this.color = Colors.brown,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedJourneyDialog extends StatefulWidget {
  final VoidCallback? onContinue;

  const _AnimatedJourneyDialog({this.onContinue});

  @override
  State<_AnimatedJourneyDialog> createState() => _AnimatedJourneyDialogState();
}

class _AnimatedJourneyDialogState extends State<_AnimatedJourneyDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _buttonController;
  late List<AnimationController> _stepControllers;
  late Animation<double> _progressAnimation;
  late Animation<double> _buttonAnimation;

  final List<String> _steps = [
    "Understanding Your Goals",
    "Selecting Verse Topics",
    "Preparing Prayer Guidance",
    "Getting Your Daily Verse Ready",
  ];

  int _completedSteps = 0;
  bool _allStepsCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize step controllers
    _stepControllers = List.generate(
      _steps.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations sequentially
    _startAnimations();
  }

  void _startAnimations() {
    // Complete steps one by one
    for (int i = 0; i < _steps.length; i++) {
      Future.delayed(Duration(milliseconds: 600 * (i + 1)), () {
        if (mounted) {
          setState(() {
            _completedSteps = i + 1;
          });
          _stepControllers[i].forward();
          
          // Start progress animation after first step
          if (i == 0) {
            _progressController.forward();
          }
          
          // Complete progress and show button after last step
          if (i == _steps.length - 1) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _allStepsCompleted = true;
                });
                _buttonController.forward();
              }
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _buttonController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildStep(String text, int index) {
    final isCompleted = index < _completedSteps;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.width > 600 ? 10 : 8,
        horizontal: MediaQuery.of(context).size.width > 600 ? 6 : 4,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _stepControllers[index],
            builder: (context, child) {
              return Transform.scale(
                scale: isCompleted
                    ? 0.8 + (_stepControllers[index].value * 0.2)
                    : 1.0,
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.hourglass_bottom_rounded,
                  color: isCompleted
                      ? const Color(0xFF7AA36D)
                      : const Color(0xFFB3854A),
                  size: MediaQuery.of(context).size.width > 600 ? 26 : 22,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                color: const Color(0xFF7B5536),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isTablet = mq.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: isTablet ? mq.width * 0.5 : mq.width * 0.9,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 20,
          vertical: isTablet ? 26 : 20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF6EBDD), Color(0xFFEBDDC9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD2C1A8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Preparing Your Journey",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 26 : 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7B5536),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're aligning scripture with your\nheart and daily needs.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth < 380
                    ? 14
                    : isTablet
                        ? 18
                        : 16,
                color: const Color(0xFF7B5536),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 18 : 14,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F1E4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8C8AF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(_steps.length, (index) => _buildStep(_steps[index], index)),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: const Color(0xFFE8D8C4),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFD69A32),
                        ),
                        minHeight: 6,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Designed to help you grow daily in God's Word.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 17 : 15,
                color: const Color(0xFF7B5536),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _buttonAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _buttonAnimation.value,
                  child: Transform.scale(
                    scale: 0.9 + (_buttonAnimation.value * 0.1),
                    child: GestureDetector(
                      onTap: _allStepsCompleted
                          ? () {
                              Navigator.of(context).pop();
                              if (widget.onContinue != null) {
                                widget.onContinue!();
                              }
                            }
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: isTablet ? 58 : 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF763201),
                              Color(0xFFD5821F),
                              Color(0xFF763201),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;

    final radius = size.width / 2;
    const segmentCount = 12;
    final angle = (2 * math.pi) / segmentCount;

    for (int i = 0; i < segmentCount; i++) {
      final double opacity =
          ((i / segmentCount + (1.0 - progress)) % 1.0).clamp(0.2, 1.0);
      paint.color = color.withValues(alpha: opacity);

      final x1 = radius + radius * 0.6 * math.cos(angle * i);
      final y1 = radius + radius * 0.6 * math.sin(angle * i);
      final x2 = radius + radius * 0.9 * math.cos(angle * i);
      final y2 = radius + radius * 0.9 * math.sin(angle * i);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
