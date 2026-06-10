import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:biblebookapp/Model/dailyVersesMainListModel.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/main.dart';
import 'package:biblebookapp/utils/emoji_text_style.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Uint8List, PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:biblebookapp/view/widget/webview.dart';

class BibleVersionsScreen extends StatefulWidget {
  final String from;
  const BibleVersionsScreen({
    super.key,
    required this.from,
  });

  @override
  BibleVersionsScreenState createState() => BibleVersionsScreenState();
}

class BibleVersionsScreenState extends State<BibleVersionsScreen> {
  // final List<String> folders = [
  //   "Amplified Bible (AMP)",
  //   "Bengali Bible",
  // ];
  Map<String, DownloadButtonState> buttonStates = {};
  final Map<String, double> progressMap = {};
  List<DailyVersesMainListModel> dailyVerseDataList = [];

  List<MainBookListModel> bookList = [];
  List<VerseBookContentModel> versesContent = [];
  String? foldername;
  bool? isloading = false;
  bool? isbtnloading = false;
  double _progress = 0;

  final InAppReview _inAppReview = InAppReview.instance;
  Availability availability = Availability.loading;

  Set<String> _selectedCategories = {};
  late SharedPreferences _prefs;

  Future<void> _requestReview() async {
    final prefs = await SharedPreferences.getInstance();
    // final isAvailable = await _inAppReview.isAvailable();
    // debugPrint('rate Is Available: $isAvailable');
    // if (isAvailable) {
    //   try {
    //     await _inAppReview.requestReview();
    //     await prefs.setString('appreview1', '2');
    //   } catch (e, st) {
    //     debugPrint('rate Error: $e,$st');
    //   }
    // }
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult[0] == ConnectivityResult.none) {
      return Constants.showToast("Check your Internet connection");
    }

    final InAppReview inAppReview = InAppReview.instance;

    final isAvailable = await inAppReview.isAvailable();
    debugPrint('Is Available: $isAvailable');
    if (isAvailable) {
      try {
        await inAppReview.requestReview();
        await prefs.setString('appreview1', '2');
      } catch (e, st) {
        Constants.showToast("review request failed");
        debugPrint('Error: $e,$st');
      }
    } else {
      Constants.showToast("review request not available, try again later");
    }
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getStringList('selected_categories') ?? [];
    setState(() {
      _selectedCategories = saved.toSet();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDownloadedFolders();
    _loadButtonStates();
    _loadPreferences();
  }

  /// 🔹 Load saved states from SharedPreferences
  Future<void> _loadButtonStates() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStates = prefs.getStringList("buttonStates") ?? [];

    final Map<String, DownloadButtonState> loadedStates = {};
    for (var entry in savedStates) {
      final parts = entry.split(":");
      if (parts.length == 2) {
        final folder = parts[0];
        final stateStr = parts[1];
        loadedStates[folder] = DownloadButtonState.values.firstWhere(
          (e) => e.toString() == stateStr,
          orElse: () => DownloadButtonState.download,
        );
      }
    }

    setState(() {
      buttonStates = loadedStates;
    });
  }

  /// 🔹 Save states to SharedPreferences
  Future<void> _saveButtonStates() async {
    final prefs = await SharedPreferences.getInstance();
    final stateList =
        buttonStates.entries.map((e) => "${e.key}:${e.value}").toList();
    await prefs.setStringList("buttonStates", stateList);
  }

  /// ✅ Load saved downloaded folders from SharedPreferences
  Future<void> _loadDownloadedFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList("downloadedFolders") ?? [];

    for (var f in BibleInfo.folders) {
      if (downloaded.contains(f)) {
        buttonStates[f] = DownloadButtonState.open;
      } else {
        buttonStates[f] = DownloadButtonState.download;
      }
      progressMap[f] = 0.0;
    }

    //return showMainFeedbackDialog(context);

    setState(() {});
  }

  /// ✅ Save downloaded folder into SharedPreferences
  Future<void> _saveDownloadedFolder(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList("downloadedFolders") ?? [];

    if (!downloaded.contains(folderName)) {
      downloaded.add(folderName);
      await prefs.setStringList("downloadedFolders", downloaded);
    }
  }

  Future<void> extractFromFolder(
      {String? from,
      required String folderName,
      required String password}) async {
    if (from.toString() != "home") {
      setState(() {
        buttonStates[folderName] = DownloadButtonState.downloading;
        progressMap[folderName] = 0.0;
      });
    }

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
        setState(() {
          progressMap[folderName] = processed / filesInFolder.length;
        });
        await Future.delayed(const Duration(seconds: 1));
      }
      if (from.toString() != "home") {
        setState(() {
          buttonStates[folderName] = DownloadButtonState.open;
        });
      }

      /// ✅ Save state persistently
      await _saveDownloadedFolder(folderName);
    } catch (e) {
      debugPrint("❌ Error extracting from $folderName: $e");
      setState(() {
        buttonStates[folderName] = DownloadButtonState.download;
      });
    }
  }

  loadingstop() {
    setState(() {
      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
      },
      child: Scaffold(
        // appBar: AppBar(title: Text("Bible versions")),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                  AppCustomTheme.vintage
              ? BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(Images.bgImage(context)),
                      fit: BoxFit.fill))
              : null,
          child: BibleInfo.folders.isEmpty
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      widget.from.toString() == "home"
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 15.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      Get.back();
                                    },
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      size: 20,
                                      color: CommanColor.whiteBlack(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Text("Bible versions",
                                      style: CommanStyle.appBarStyle(context)),
                                ),
                                SizedBox(),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: Text("Bible versions",
                                  style: CommanStyle.appBarStyle(context)),
                            ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: BibleInfo.folders.length,
                          itemBuilder: (context, index) {
                            final folder = BibleInfo.folders[index];
                            final state = buttonStates[folder] ??
                                DownloadButtonState.download;
                            final progress = progressMap[folder] ?? 0.0;

                            return ListTile(
                              title: Text(folder),
                              trailing: SizedBox(
                                width: 100,
                                height: 27,
                                child: DownloadButton(
                                  state: state,
                                  progress: progress,
                                  onDownload: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final data =
                                        prefs.getString("appreview1") ?? "1";
                                    if (data == '1') {
                                      // await _requestReview();
                                      // await prefs.setString('appreview1', '2');
                                    }
                                    extractFromFolder(
                                      folderName: folder,
                                      password: dotenv
                                          .env[AssetsConstants.holybibleKey]
                                          .toString(),
                                    );
                                  },
                                  onOpen: () async {
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   SnackBar(
                                    //       content: Text("Opening $folder...")),
                                    // );
                                    // if (widget.from == 'onboard') {
                                    //   Get.to(() => PreferenceSelectionScreen(
                                    //         isSetting: false,
                                    //         selectedbible: folder,
                                    //       ));
                                    // } else {
                                    //   await loadBookContent(folder);
                                    //   await loadBookList(folder);
                                    //   await deleteFiles(folder);
                                    //   return Get.back();
                                    // }
                                    // setState(() {
                                    //   foldername = folder;
                                    //   buttonStates[folder] =
                                    //       DownloadButtonState.active;
                                    // });
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final data =
                                        prefs.getString("appreview1") ?? "1";
                                    if (data == '1') {
                                      await _requestReview();
                                    }
                                    setState(() {
                                      // Step 1: Reset all active folders to "open"
                                      buttonStates.updateAll((key, value) {
                                        if (value ==
                                            DownloadButtonState.active) {
                                          return DownloadButtonState.open;
                                        }
                                        return value;
                                      });

                                      // Step 2: Mark only the tapped folder as "active"
                                      foldername = folder;
                                      buttonStates[folder] =
                                          DownloadButtonState.active;
                                    });
                                  },
                                  onactive: () {},
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 65),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Provider.of<ThemeProvider>(
                                              context,
                                              listen: false)
                                          .themeMode ==
                                      ThemeMode.dark
                                  ? CommanColor.white
                                  : const Color(0xFF7B5C3D),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 20 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                isloading = true;
                              });
                              // await showClearDatabaseDialog(context);
                              if (foldername != null &&
                                  foldername!.isNotEmpty) {
                                // 🔹 Save state after change

                                // Navigate next
                                if (widget.from == 'onboard') {
                                  setState(() {
                                    isloading = false;
                                  });
                                  await _saveButtonStates();
                                  CustomAlertBox.show(context, () {
                                    Get.to(() => PreferenceSelectionScreen(
                                          isSetting: false,
                                          selectedbible: foldername.toString(),
                                        ));
                                  });
                                } else {
                                  await showClearDatabaseDialog(context);
                                  // await extractFromFolder(
                                  //     folderName: foldername.toString(),
                                  //     password: "Mtech2023",
                                  //     from: "home");
                                  // await loadBookContent(foldername);
                                  // await loadBookList(foldername);
                                  // await loadDailyVerseData();
                                  // await loadLocal();
                                  // await deleteFiles(foldername);
                                  // // return Get.back();
                                  // setState(() {
                                  //   isloading = false;
                                  // });
                                  // return Get.offAll(() => HomeScreen(
                                  //       From: "splash",
                                  //       selectedVerseNumForRead: "",
                                  //       selectedBookForRead: "",
                                  //       selectedChapterForRead: "",
                                  //       selectedBookNameForRead: "",
                                  //       selectedVerseForRead: "",
                                  //     ));
                                }
                              } else {
                                setState(() {
                                  isloading = false;
                                });
                                Constants.showToast("Click Set as Default");
                              }
                            },
                            child: Text(
                              isloading == false ? "Continue" : "loading...",
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 16,
                                fontWeight: FontWeight.w600,
                                color: Provider.of<ThemeProvider>(context,
                                                listen: false)
                                            .themeMode ==
                                        ThemeMode.dark
                                    ? CommanColor.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void showMainFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;

        return Dialog(
          backgroundColor: CommanColor.white,
          insetPadding: isTablet ? EdgeInsets.symmetric(horizontal: 100) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                          )),
                    ],
                  ),
                ),
                Container(
                  height: 79,
                  width: 79,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: AssetImage("assets/Icon-1024.png"))),
                ),
                // const Icon(Icons.menu_book, size: 48, color: Colors.brown),
                const SizedBox(height: 10),
                Text(
                  'How are you enjoying ${BibleInfo.bible_shortName} so far?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                textWithTrailingEmoji(
                  prefix:
                      'Your feedback helps us improve the app and serve you better. ',
                  emoji: '💛',
                  emojiFontSize: isTablet ? 15 : 14,
                  prefixStyle: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _buildEmojiOption(
                  context,
                  emoji: '😍',
                  text: 'Love It',
                  color: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2D6A4F),
                  onTap: () => _showRateAppDialog(context),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: '😊',
                  text: 'It\'s Good',
                  color: const Color(0xFFFFEDD5),
                  textColor: const Color(0xFF9A3412),
                  onTap: () => _showFeedbackDialog(context, '😊'),
                ),
                const SizedBox(height: 10),
                _buildEmojiOption(
                  context,
                  emoji: '😔',
                  text: 'Needs Improvement',
                  color: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFFB91C1C),
                  onTap: () => _showFeedbackDialog(context, '😔'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiOption(BuildContext context,
      {required String emoji,
      required String text,
      required Color color,
      required Color textColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: emojiTextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: textColor.withOpacity(0.8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    Navigator.of(context).pop(); // close previous dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;
        double screenWidth = MediaQuery.of(context).size.width;
        return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                          )),
                    ],
                  ),
                ),
                emojiText('😍', fontSize: 40),
                const SizedBox(height: 15),
                textWithTrailingEmoji(
                  prefix: 'Thanks for the love! ',
                  emoji: '💛',
                  emojiFontSize: isTablet ? 19 : 16,
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 19 : 16,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Leave us a quick rating to help others\nexperience God's Word too!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet
                        ? 19
                        : screenWidth < 380
                            ? 12.5
                            : 14,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Add your rate app logic here
                    await SharPreferences.setString('OpenAd', '1');
                    _requestReview();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  child: Text(
                    "Rate the app",
                    style: TextStyle(
                      color: CommanColor.white,
                      fontSize: isTablet ? 17 : null,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Later",
                    style: TextStyle(
                      color: CommanColor.black,
                      fontSize: isTablet ? 17 : null,
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

  // Future<void> _requestReview() async {
  //   final InAppReview inAppReview = InAppReview.instance;

  //   ///Availability availability = Availability.loading;
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   if (connectivityResult[0] == ConnectivityResult.mobile ||
  //       connectivityResult[0] == ConnectivityResult.wifi) {
  //     final isAvailable = await inAppReview.isAvailable();
  //     debugPrint('Is Available: $isAvailable');
  //     if (isAvailable) {
  //       try {
  //         await inAppReview.requestReview();
  //       } catch (e, st) {
  //         debugPrint('Error: $e,$st');
  //       }
  //     }
  //   } else {
  //     Constants.showToast('No Internet Connection');
  //   }
  // }

  Future loadLocal() async {
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    try {
      // downloadProvider.setIsLoading(true); // Start loading

      final prefs = await SharedPreferences.getInstance();

      final db = await DBHelper().db;

      // Load and parse verses
      final verseRaw = await db!.rawQuery("SELECT * FROM verse");
      final parsedVerses = await compute(parseVerses, verseRaw);
      final splitVersesMap = await compute(splitVerses, parsedVerses);

      // Load and parse books
      final bookRaw = await db.rawQuery("SELECT * FROM book");
      final parsedBooks = await compute(parseBooks, bookRaw);
      final splitBooksMap = await compute(splitBooks, parsedBooks);

      // Set provider data
      downloadProvider.setData(
        allVerses: parsedVerses,
        otVerses: splitVersesMap['ot']!,
        ntVerses: splitVersesMap['nt']!,
        allBooks: parsedBooks,
        otBooks: splitBooksMap['ot']!,
        ntBooks: splitBooksMap['nt']!,
      );

      // setState(() {
      //   oTBookList = downloadProvider.otBookList;
      //   nTBookList = downloadProvider.ntBookList;
      //   allVersesContent = downloadProvider.verseList;
      //   bookList = downloadProvider.bookList;
      // });

// ✅ Save to SharedPreferences
      await prefs.setString(
        'otBookList',
        jsonEncode(downloadProvider.otBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'ntBookList',
        jsonEncode(downloadProvider.ntBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'bookList',
        jsonEncode(downloadProvider.bookList.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  Future<void> clearAllData() async {
    final db = await DBHelper().db; // your db instance getter
    await db?.delete("bookmark");
    await db?.delete("highlight");
    await db?.delete("underline");
    await db?.delete("save_notes");
    await db?.delete("save_images");
    // await db.delete("images"); // if you have images table
    debugPrint("✅ All database data cleared");
  }

  Future<void> showClearDatabaseDialog(BuildContext context) async {
    //final dbHelper = DBHelper();

    return showDialog<void>(
      context: context,

      barrierDismissible: false, // user must tap button
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            // backgroundColor: Colors.white,
            title: const Text("Are you sure?"),
            content: const Text(
              "All my library data will be deleted. Do you want to continue?",
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              isbtnloading == true
                  ? SizedBox.fromSize()
                  : TextButton(
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            color:
                                Provider.of<ThemeProvider>(context).themeMode ==
                                        ThemeMode.dark
                                    ? Colors.white
                                    : CommanColor.black),
                      ),
                      onPressed: () {
                        setState(() {
                          isbtnloading = false;
                          isloading = false;
                        });
                        loadingstop();
                        Navigator.of(context).pop(); // just close dialog
                      },
                    ),
              isbtnloading == true
                  ? SizedBox.fromSize()
                  : SizedBox(
                      width: 15,
                    ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isbtnloading == true ? Colors.grey : Colors.red,
                ),
                child: Text(
                  isbtnloading == true
                      ? "${_progress.toStringAsFixed(0)}% Loading..."
                      : "Okay",
                  style: TextStyle(
                      color: isbtnloading == true
                          ? Colors.black
                          : CommanColor.white),
                ),
                onPressed: () async {
                  setState(() {
                    isbtnloading = true;
                  });
                  if (foldername != null && foldername!.isNotEmpty) {
                    // 🔹 Save state after change
                    await _saveButtonStates();
                    // Navigate next
                    if (widget.from == 'onboard') {
                      setState(() {
                        isloading = false;
                        isbtnloading = false;
                      });

                      CustomAlertBox.show(context, () {
                        Get.to(() => PreferenceSelectionScreen(
                              isSetting: false,
                              selectedbible: foldername.toString(),
                            ));
                      });
                    } else {
                      setState(() {
                        _progress = 5;
                      });
                      await extractFromFolder(
                          folderName: foldername.toString(),
                          password: dotenv.env[AssetsConstants.holybibleKey]
                              .toString(),
                          from: "home");

                      setState(() {
                        _progress = 15;
                      });
                      await loadBookContent(foldername);

                      setState(() {
                        _progress = 27;
                      });
                      await loadBookList(foldername);

                      setState(() {
                        _progress = 43;
                      });
                      //  await loadDailyVerseData();
                      _savePreferences();
                      //  await loadBookList(foldername);

                      setState(() {
                        _progress = 54;
                      });
                      await loadLocal();

                      setState(() {
                        _progress = 67;
                      });
                      await DBHelper().db.then((db) async {
                        if (db != null) {
                          final result = await db.rawQuery(
                            "SELECT * FROM book WHERE book_num = ?",
                            [int.parse("0")],
                          );

                          if (result.isNotEmpty && result[0]["title"] != null) {
                            final title = result[0]["title"].toString();
                            // final data = await SharPreferences.getString(
                            //       SharPreferences.selectedBook,
                            //     ) ??
                            //     "";
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
                          debugPrint("testapp Database instance is null");
                        }
                      });

                      setState(() {
                        _progress = 73;
                      });
                      await deleteFiles(foldername);
                      // return Get.back();

                      setState(() {
                        _progress = 89;
                      });
                      await clearAllData(); // clear DB

                      setState(() {
                        _progress = 97;
                      });
                      // close dialog
                      Constants.showToast("Updated Successfully");
                      setState(() {
                        isloading = false;
                        isbtnloading = false;
                      });

                      return Get.offAll(() => HomeScreen(
                            From: "splash",
                            selectedVerseNumForRead: "",
                            selectedBookForRead: "",
                            selectedChapterForRead: "",
                            selectedBookNameForRead: "",
                            selectedVerseForRead: "",
                          ));
                    }
                  } else {
                    setState(() {
                      isloading = false;
                      isbtnloading = false;
                    });
                    loadingstop();
                    Constants.showToast("Click Set as Default");
                  }

                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text("Library data deleted")),
                  // );
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _showFeedbackDialog(BuildContext context, String emoji) {
    Navigator.of(context).pop(); // close previous dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;

        return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                          )),
                    ],
                  ),
                ),
                emojiText(emoji, fontSize: 40),
                const SizedBox(height: 15),
                const Text(
                  "Thanks! We'd love to hear your thoughts..",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Got a suggestion to help us improve?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Preserve existing preference side-effect then open chat screen
                    await SharPreferences.setString('OpenAd', '1');
                    Get.to(() => const FeedbackWebView());
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  child: Text(
                    "Share Feedback",
                    style: TextStyle(
                      color: CommanColor.white,
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

// Helper methods extracted from the initState
  Future<void> _initializeRatingDialog(GetXState state) async {
    await Future.delayed(Duration.zero, () async {
      final saveRating =
          await SharPreferences.getInt(SharPreferences.saveRating) ?? 0;
      final lastViewRatingDateTime =
          await SharPreferences.getString(SharPreferences.lastViewTime) ?? "";
      final lastRatingDateTime =
          await SharPreferences.getString(SharPreferences.ratingDateTime) ?? "";

      if (lastRatingDateTime.isNotEmpty) {
        final startTime =
            DateFormat('dd-MM-yyyy HH:mm').parse(lastViewRatingDateTime);
        final currentTime = DateTime.now();
        final diffDays = currentTime.difference(startTime).inDays;

        if (saveRating <= 4 && diffDays > 3) {
          Future.delayed(Duration(minutes: 2),
              () => _showRatingDialog(state, currentTime));
        }
      }
    });
  }

  void _showRatingDialog(GetXState state, DateTime currentTime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 15),
          content: _buildRatingDialogContent(state, currentTime),
        );
      },
    );
  }

  void _setRating(int rating) {
    _rating.value = rating;
    _showFeedbackButton.value = rating >= 4;
  }

  final ValueNotifier<int> _rating = ValueNotifier<int>(0);
  final ValueNotifier<bool> _showFeedbackButton = ValueNotifier<bool>(false);
  Widget _buildRatingDialogContent(GetXState state, DateTime currentTime) {
    return ValueListenableBuilder<int>(
      valueListenable: _rating,
      builder: (context, int value, Widget? child) {
        final (feedbackText, feedbackText1, style, style1, colour) =
            _getFeedbackContent(value);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/feedbacklogo.png",
              height: 140,
              width: 140,
              color: Colors.brown,
            ),
            Text(feedbackText, style: style1),
            const SizedBox(height: 16),
            Text(feedbackText1, style: style),
            const SizedBox(height: 10),
            _buildStarRating(state, value),
            const SizedBox(height: 16),
            _buildRatingButtons(state, value, currentTime, colour),
          ],
        );
      },
    );
  }

  (String, String, TextStyle, TextStyle, Color?) _getFeedbackContent(
      int value) {
    if (value == 0) {
      return (
        'Leave Your Experience,',
        'Let it Shine Bright',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.grey[500],
      );
    } else if (value <= 3) {
      return (
        'Please help us',
        'with your valuable feedback',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.brown[500],
      );
    } else {
      return (
        'Great!',
        'Give your rating on store',
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 13,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        const TextStyle(
          letterSpacing: BibleInfo.letterSpacing,
          fontSize: BibleInfo.fontSizeScale * 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        Colors.brown[500],
      );
    }
  }

  Widget _buildStarRating(GetXState state, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          5,
          (i) => GestureDetector(
                onTap: () {
                  _setRating(i + 1);
                  //  state.controller!.rating.value = i + 1;
                },
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: value >= i + 1 ? Colors.brown : Colors.grey,
                ),
              )),
    );
  }

  Widget _buildRatingButtons(
      GetXState state, int value, DateTime currentTime, Color? colour) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[500]),
          child: const Text('Not Now', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pop();
            SharPreferences.setString(
                SharPreferences.lastViewTime, "$currentTime");
          },
        ),
        const SizedBox(width: 50),
        ValueListenableBuilder<bool>(
          valueListenable: _showFeedbackButton,
          builder: (context, bool showButton, Widget? child) {
            return SizedBox(
              height: 40,
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colour),
                child: Text(
                  showButton ? 'Rate Us' : 'Feedback',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () =>
                    _handleRatingButtonPress(state, showButton, currentTime),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleRatingButtonPress(
      GetXState state, bool showButton, DateTime currentTime) async {
    Get.back();
    // SharPreferences.setInt(
    //     SharPreferences.saveRating, state.controller!.rating.value);
    SharPreferences.setString(SharPreferences.ratingDateTime, "$currentTime");

    if (showButton) {
      await _launchStoreRating();
    } else {
      await _launchFeedbackForm();
    }
  }

  Future<void> _launchStoreRating() async {
    if (Platform.isAndroid) {
      final appPackageName = (await PackageInfo.fromPlatform()).packageName;
      try {
        await launchUrl(Uri.parse("market://details?id=$appPackageName"));
      } on PlatformException {
        await launchUrl(Uri.parse(
            "https://play.google.com/store/apps/details?id=$appPackageName"));
      }
    } else if (Platform.isIOS) {
      await launchUrl(
          Uri.parse("https://itunes.apple.com/app/id${BibleInfo.apple_AppId}"));
    }
  }

  Future<void> _launchFeedbackForm() async {
    const url =
        'https://bibleoffice.com/m_feedback/API/feedback_form/index.php';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

  Future<void> _savePreferences() async {
    final saveProvider = Provider.of<DownloadProvider>(context, listen: false);
    await saveProvider.saveInBackground(
        selectedCategories: _selectedCategories.toList());
  }

  Future<void> loadDailyVerseData() async {
    final db = await DBHelper().db;

    // Clear both tables before inserting new data
    await db?.delete("dailyVersesMainList");
    await db?.delete("dailyVerses");
    await db?.delete("dailyVersesnew");

    // Load json and parse
    final String dailyVerseResponse =
        await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
    final List<DailyVersesMainListModel> dataList =
        await compute(parseDailyVerseJsond, dailyVerseResponse);

    setState(() {
      dailyVerseDataList = dataList;
    });

    // Insert fresh main list
    await db?.transaction((txn) async {
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
    final newMainList = await db?.rawQuery("SELECT * FROM dailyVersesMainList");

    for (var i = 0; i < 20 && i < newMainList!.length; i++) {
      final m = newMainList[i];

      final int verseNum = m["Verse"].toString().length == 2
          ? int.parse(m["Verse"].toString()) - 1
          : int.parse(m["Verse"].toString().split("-").first) - 1;

      final selectedVerse = await db?.rawQuery(
        "SELECT * FROM verse WHERE book_num ='${int.parse(m["Book_Id"].toString()) - 1}' "
        "AND chapter_num ='${int.parse(m["Chapter"].toString()) - 1}' "
        "AND verse_num ='$verseNum'",
      );

      if (selectedVerse!.isNotEmpty) {
        await db?.transaction((txn) async {
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

/// --------------------
/// Custom Download Button
/// --------------------
enum DownloadButtonState { download, downloading, open, active }

class DownloadButton extends StatelessWidget {
  final DownloadButtonState state;
  final double progress;

  final VoidCallback? onDownload;
  final VoidCallback? onOpen;
  final VoidCallback? onactive;

  const DownloadButton({
    super.key,
    required this.state,
    this.onDownload,
    this.onOpen,
    this.onactive,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DownloadButtonState.download:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(),
            side: BorderSide(
                color: Provider.of<ThemeProvider>(context, listen: false)
                            .themeMode ==
                        ThemeMode.dark
                    ? CommanColor.white
                    : Color(0xFF8B5E3C)),
            foregroundColor:
                Provider.of<ThemeProvider>(context, listen: false).themeMode ==
                        ThemeMode.dark
                    ? CommanColor.white
                    : const Color(0xFF8B5E3C),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          ),
          onPressed: onDownload,
          child: const Text(
            "Download",
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        );

      case DownloadButtonState.downloading:
        return Stack(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                //borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFF8B5E3C)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0.1),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(const Color(0xFF8B5E3C)),
                  minHeight: 40,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  "Downloading...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );

      case DownloadButtonState.open:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(),
            backgroundColor: const Color(0xFF8B5E3C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          ),
          onPressed: onOpen,
          child: Text(
            "Set as Default",
            style: TextStyle(
              fontSize: 10.1,
            ),
          ),
        );
      case DownloadButtonState.active:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(),
            backgroundColor: const ui.Color.fromARGB(255, 48, 134, 2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          ),
          onPressed: onOpen,
          child: Text(
            "Active",
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        );
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

class CustomAlertBox {
  static void show(BuildContext context, onPressed) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600; // iPad vs iPhone
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: false, // must tap Next
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? size.width * 0.2 : 24,
            vertical: isTablet ? size.height * 0.2 : 24,
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 32 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bible Image/Icon
                Image.asset(
                  "assets/Icon-1024.png", // replace with your Bible icon
                  height: isTablet ? 100 : 70,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "A Beautiful Step Forward!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: isTablet ? 24 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  "You've chosen a version that speaks\n to your heart!\n\n"
                  "Let's take the next step together and\n find words meant just for you..",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth < 380
                        ? 14
                        : isTablet
                            ? 18
                            : 16,
                    height: 1.5,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),

                // Next Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5C3D),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onPressed
                      // () {
                      //   Navigator.of(context).pop();
                      //    // close alert
                      //   // Navigate to next screen if needed
                      // }
                      ,
                      child: Text(
                        "Next",
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// enum DownloadButtonState { download, downloading, open }

// class DownloadButton extends StatefulWidget {
//   final DownloadButtonState state;
//   final VoidCallback? onDownload;
//   final VoidCallback? onOpen;
//   final double progress; // 0.0 to 1.0

//   const DownloadButton({
//     Key? key,
//     required this.state,
//     this.onDownload,
//     this.onOpen,
//     this.progress = 0.0,
//   }) : super(key: key);

//   @override
//   State<DownloadButton> createState() => _DownloadButtonState();
// }

// class _DownloadButtonState extends State<DownloadButton> {
//   @override
//   Widget build(BuildContext context) {
//     switch (widget.state) {
//       case DownloadButtonState.download:
//         return OutlinedButton(
//           style: OutlinedButton.styleFrom(
//             side: const BorderSide(color: Color(0xFF8B5E3C)), // brown border
//             foregroundColor: const Color(0xFF8B5E3C),
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           ),
//           onPressed: widget.onDownload,
//           child: const Text("Download"),
//         );

//       case DownloadButtonState.downloading:
//         return Stack(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(color: const Color(0xFF8B5E3C)),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(6),
//                 child: LinearProgressIndicator(
//                   value: widget.progress,
//                   backgroundColor: Colors.transparent,
//                   valueColor:
//                       AlwaysStoppedAnimation<Color>(const Color(0xFF8B5E3C)),
//                   minHeight: 40,
//                 ),
//               ),
//             ),
//             Positioned.fill(
//               child: Center(
//                 child: Text(
//                   "Downloading",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );

//       case DownloadButtonState.open:
//         return ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF8B5E3C), // brown filled
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           ),
//           onPressed: widget.onOpen,
//           child: const Text("Open"),
//         );
//     }
//   }
// }
