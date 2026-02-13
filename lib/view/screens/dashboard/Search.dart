import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as html;
import 'package:html/parser.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Model/mainBookListModel.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/constant.dart';
import '../../constants/images.dart';

class SearchScreen extends StatefulWidget {
  dynamic controller;
  SearchScreen({
    super.key,
    this.controller,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static final MainBookListModel _allChapterItem =
      MainBookListModel(id: -1, title: "All Chapter", bookNum: -1);

  int selectedValueFilterIndex = 0;
  String selectedValueFilter = "ALL";
  MainBookListModel selectedBook = MainBookListModel(bookNum: -1);
  List<VerseBookContentModel> allVersesContent = [];
  List<VerseBookContentModel> filterSelectedVersesContent = [];
  List<MainBookListModel> bookList = [
    MainBookListModel(id: -1, title: "All Chapter", bookNum: -1)
  ];
  List<MainBookListModel> oTBookList = [];
  List<MainBookListModel> nTBookList = [
    // MainBookListModel(id: -1, title: "All Chapter", bookNum: -1)
  ];
  List<VerseBookContentModel> allOtVersesContent = [];
  List<VerseBookContentModel> allNtVersesContent = [];
  TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool _isBookNameSearchMode = false;

  double fontSize = Sizecf.scrnWidth! > 450 ? 25.0 : 15.0;
  var fontSizeS = "";
  var selectedFontFamily = "";
  Future<void> getFont() async {
    fontSizeS =
        await SharPreferences.getString(SharPreferences.selectedFontSize) ??
            "${Sizecf.scrnWidth! > 450 ? 25.0 : 15.0}";
    fontSize = double.parse(fontSizeS);
    final fontFamily =
        await SharPreferences.getString(SharPreferences.selectedFontFamily) ??
            "Arial";
    if (mounted) {
      setState(() {
        selectedFontFamily = fontFamily;
      });
    } else {
      selectedFontFamily = fontFamily;
    }
  }

  @override
  void initState() {
    super.initState();
    loadBookListsFromPrefs();
    getFont();
  }

  // loadLocal() async {
  //   _myProvider = Provider.of<DownloadProvider>(context, listen: false);
  //   _myProvider?.disableAd();
  //   await SharPreferences.setString('OpenAd', '1');
  //   await DBHelper().db.then((value) {
  //     value!.rawQuery("SELECT * From verse").then((selectedBookResponse) {
  //       setState(() {
  //         allVersesContent = selectedBookResponse
  //             .map<VerseBookContentModel>(
  //                 (e) => VerseBookContentModel.fromJson(e))
  //             .toList();
  //         for (var i = 0; i < allVersesContent.length; i++) {
  //           if (allVersesContent[i].bookNum!.clamp(0, 38) ==
  //               allVersesContent[i].bookNum) {
  //             setState(() {
  //               allOtVersesContent.add(allVersesContent[i]);
  //             });
  //           } else {
  //             setState(() {
  //               allNtVersesContent.add(allVersesContent[i]);
  //             });
  //           }
  //         }
  //       });
  //     });
  //   });
  //   await DBHelper().db.then((value) {
  //     value!.rawQuery("SELECT * From book").then((BookDAta) {
  //       setState(() {
  //         bookList = BookDAta.map<MainBookListModel>(
  //             (e) => MainBookListModel.fromJson(e)).toList();
  //       });

  //       for (var i = 0; i < 39; i++) {
  //         setState(() {
  //           oTBookList.add(bookList[i]);
  //         });
  //       }
  //       for (var i = 39; i < bookList.length; i++) {
  //         setState(() {
  //           nTBookList.add(bookList[i]);
  //         });
  //       }
  //     });
  //   });
  // }

  Future<void> loadBookListsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Get JSON strings from prefs
    final otBookJson = prefs.getString('otBookList');
    final ntBookJson = prefs.getString('ntBookList');
    final allBookJson = prefs.getString('bookList');

    if (allBookJson != null) {
      bookList = (await jsonDecode(allBookJson) as List)
          .map((e) => MainBookListModel.fromJson(e))
          .toList();
    }

    if (otBookJson != null) {
      oTBookList = (await jsonDecode(otBookJson) as List)
          .map((e) => MainBookListModel.fromJson(e))
          .toList();
    }
    //  debugPrint("check data -  $oTBookList ");
    if (ntBookJson != null) {
      nTBookList = (await jsonDecode(ntBookJson) as List)
          .map((e) => MainBookListModel.fromJson(e))
          .toList();
    }
    setState(() {});
    // debugPrint("check data -$bookList  ");
    // Decode and convert to model lists

    // if (allBookJson != null) {
    //   bookList = (jsonDecode(allBookJson) as List)
    //       .map((e) => MainBookListModel.fromJson(e))
    //       .toList();
    // }
  }

  Future loadLocal() async {
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    try {
      // downloadProvider.setIsLoading(true); // Start loading

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('OpenAd', '1');
      await SharPreferences.setString('OpenAd', '1');
      downloadProvider.disableAd();

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

      setState(() {
        oTBookList =
            oTBookList.isEmpty ? downloadProvider.otBookList : oTBookList;
        nTBookList =
            nTBookList.isEmpty ? downloadProvider.ntBookList : nTBookList;
        allVersesContent = downloadProvider.verseList;
        bookList = bookList.isEmpty ? downloadProvider.bookList : bookList;
      });

// ✅ Save to SharedPreferences
      await prefs.setString(
        'otBookList',
        jsonEncode(oTBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'ntBookList',
        jsonEncode(nTBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'bookList',
        jsonEncode(bookList.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error loading local data: $e');
    } finally {
      // downloadProvider.setIsLoading(false); // End loading
    }
  }

  String _normalizeBookKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  MainBookListModel? _findMatchingBook(
      String query, List<MainBookListModel> books) {
    final q = _normalizeBookKey(query.trim());
    if (q.isEmpty) return null;

    MainBookListModel? prefixMatch;
    for (final book in books) {
      if (book.bookNum == -1) continue; // "All Chapter"
      final title = (book.title ?? '').toString();
      final t = _normalizeBookKey(title);
      if (t.isEmpty) continue;

      // Prefer exact match (Genesis == genesis)
      if (t == q) return book;

      // Fallback: allow prefix match for partial typing (gen -> Genesis)
      if (prefixMatch == null && q.length >= 3 && t.startsWith(q)) {
        prefixMatch = book;
      }
    }
    return prefixMatch;
  }

  int _safeInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _searchFilter(value) async {
    // setState(() {
    //   if (selectedValueFilter == "ALL" && selectedBook.bookNum != -1) {
    //     filterSelectedVersesContent = allVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()) &&
    //             name.bookNum == selectedBook.bookNum)
    //         .toList();
    //   } else if (selectedValueFilter == "OT" && selectedBook.bookNum == -1) {
    //     filterSelectedVersesContent = allOtVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()))
    //         .toList();
    //   } else if (selectedValueFilter == "OT" && selectedBook.bookNum != -1) {
    //     filterSelectedVersesContent = allOtVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()) &&
    //             name.bookNum == selectedBook.bookNum)
    //         .toList();
    //   } else if (selectedValueFilter == "NT" && selectedBook.bookNum == -1) {
    //     filterSelectedVersesContent = allNtVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()))
    //         .toList();
    //   } else if (selectedValueFilter == "NT" && selectedBook.bookNum != -1) {
    //     filterSelectedVersesContent = allNtVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()) &&
    //             name.bookNum == selectedBook.bookNum)
    //         .toList();
    //   } else {
    //     filterSelectedVersesContent = allVersesContent
    //         .where((name) =>
    //             name.content!.toLowerCase().contains(value.toLowerCase()))
    //         .toList();
    //   }
    // });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('OpenAd', '1');
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    // If user typed a book name (Genesis/Exodus/etc), show the full book content
    // (all verses across all chapters) in this same results view.
    final queryText = (value ?? '').toString().trim();
    final booksSource = downloadProvider.bookList.isNotEmpty
        ? downloadProvider.bookList
        : bookList;
    final matchedBook = _findMatchingBook(queryText, booksSource);
    if (matchedBook != null) {
      List<VerseBookContentModel> bookVerses = [];
      if (selectedValueFilter == "OT") {
        bookVerses = downloadProvider.otVerseList
            .where((v) => v.bookNum == matchedBook.bookNum)
            .toList();
      } else if (selectedValueFilter == "NT") {
        bookVerses = downloadProvider.ntVerseList
            .where((v) => v.bookNum == matchedBook.bookNum)
            .toList();
      } else {
        bookVerses = downloadProvider.verseList
            .where((v) => v.bookNum == matchedBook.bookNum)
            .toList();
      }

      bookVerses.sort((a, b) {
        final c = _safeInt(a.chapterNum).compareTo(_safeInt(b.chapterNum));
        if (c != 0) return c;
        return _safeInt(a.verseNum).compareTo(_safeInt(b.verseNum));
      });

      setState(() {
        filterSelectedVersesContent = bookVerses;
        _isBookNameSearchMode = true;
      });
      return;
    }

    List<VerseBookContentModel> sourceList = [];
    downloadProvider.disableAd();
    if (selectedValueFilter == "ALL" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.verseList
          .where(
            (v) =>
                v.content?.toLowerCase().contains(value.toLowerCase()) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else if (selectedValueFilter == "OT" && selectedBook.bookNum == -1) {
      sourceList = downloadProvider.otVerseList
          .where(
            (v) => v.content?.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    } else if (selectedValueFilter == "OT" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.otVerseList
          .where(
            (v) =>
                v.content?.toLowerCase().contains(value.toLowerCase()) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else if (selectedValueFilter == "NT" && selectedBook.bookNum == -1) {
      sourceList = downloadProvider.ntVerseList
          .where(
            (v) => v.content?.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    } else if (selectedValueFilter == "NT" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.ntVerseList
          .where(
            (v) =>
                v.content?.toLowerCase().contains(value.toLowerCase()) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else {
      sourceList = downloadProvider.verseList
          .where(
            (v) => v.content?.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    }
    await SharPreferences.setString('OpenAd', '1');
    setState(() {
      filterSelectedVersesContent = sourceList;
      _isBookNameSearchMode = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");

    // final downloadProvider =
    //     Provider.of<DownloadProvider>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        Provider.of<DownloadProvider>(context, listen: false).enableAd();
        await SharPreferences.setString('OpenAd', '1');

        if (didPop) return;

        Get.back();

        // Get.offAll(
        //   () => HomeScreen(
        //     From: "splash",
        //     selectedVerseNumForRead: "",
        //     selectedBookForRead: "",
        //     selectedChapterForRead: "",
        //     selectedBookNameForRead: "",
        //     selectedVerseForRead: "",
        //   ),
        //   transition: Transition
        //       .rightToLeftWithFade, // You can also try slide, rightToLeft, etc.
        //   duration: const Duration(milliseconds: 1000),
        // );
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    Images.bgImage(context),
                  ),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Provider.of<ThemeProvider>(context)
                      .currentCustomTheme ==
                  AppCustomTheme.vintage
              ? Colors.transparent
              : Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                  ? CommanColor.darkPrimaryColor
                  : Provider.of<ThemeProvider>(context).backgroundColor,
          body:
              //downloadProvider.isLoadingsearch
              // oTBookList.isEmpty && nTBookList.isEmpty
              //     ? Column(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         //   crossAxisAlignment: CrossAxisAlignment.center,
              //         children: [
              //           Align(
              //             alignment: Alignment.center,
              //             child: Column(
              //               children: [
              //                 SizedBox(
              //                     height: 50,
              //                     width: 50,
              //                     child: CircularProgressIndicator.adaptive()),
              //                 Text("Loading...")
              //               ],
              //             ),
              //           ),
              //         ],
              //       )
              //     :
              SafeArea(
            child: GestureDetector(
              onTap: () async {
                // Dismiss keyboard when tapping outside the search field
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (currentFocus.hasPrimaryFocus ||
                    currentFocus.focusedChild != null) {
                  currentFocus.unfocus();
                }
                await SharPreferences.setString('OpenAd', '1');
                Provider.of<DownloadProvider>(context, listen: false)
                    .disableAd();
                await SharPreferences.setString('OpenAd', '1');
              },
              behavior:
                  HitTestBehavior.opaque, // Ensure entire area is tappable
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          // if (_myProvider != null) {
                          //   _myProvider?.enableAd();
                          // }
                          Provider.of<DownloadProvider>(context, listen: false)
                              .enableAd();
                          await SharPreferences.setString('OpenAd', '1');
                          Get.back();
                          // Get.offAll(
                          //   () => HomeScreen(
                          //     From: "splash",
                          //     selectedVerseNumForRead: "",
                          //     selectedBookForRead: "",
                          //     selectedChapterForRead: "",
                          //     selectedBookNameForRead: "",
                          //     selectedVerseForRead: "",
                          //   ),
                          //   transition: Transition
                          //       .rightToLeftWithFade, // You can also try slide, rightToLeft, etc.
                          //   duration: const Duration(milliseconds: 900),
                          // );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: screenWidth > 450 ? 30 : 20,
                            color: CommanColor.whiteBlack(context),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Text("Search",
                            style: screenWidth > 450
                                ? CommanStyle.appBarStyle(context).copyWith(
                                    fontSize: 29,
                                    color: CommanColor.whiteBlack(context))
                                : CommanStyle.appBarStyle(context).copyWith(
                                    color: CommanColor.whiteBlack(context))),
                      ),
                      SizedBox()
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: screenWidth > 450 ? 55 : 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: EdgeInsets.only(
                        bottom: 20.0,
                        left: 15,
                        right: 15,
                      ),
                      child: TextFormField(
                        style: CommanStyle.black16500.copyWith(
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 22
                                : BibleInfo.fontSizeScale * 16),
                        controller: searchController,
                        cursorColor: CommanColor.lightDarkPrimary(context),
                        onFieldSubmitted: (v) async {
                          setState(() {
                            isLoading = true;
                          });
                          Provider.of<DownloadProvider>(context, listen: false)
                              .disableAd();
                          FocusScopeNode currentFocus = FocusScope.of(context);
                          await SharPreferences.setString('OpenAd', '1');
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                          await loadLocal();
                          _searchFilter(searchController.text);

                          await SharPreferences.setString('OpenAd', '1');
                          setState(() {
                            isLoading = false;
                          });
                        },
                        // onSaved: (value) async {
                        //   // _searchFilter(value);
                        //   // Provider.of<DownloadProvider>(context,
                        //   //         listen: false)
                        //   //     .disableAd();
                        //   // await SharPreferences.setString(
                        //   //     'OpenAd', '1');
                        // },
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15.0, vertical: 8),
                            hintText: "Search",
                            suffixIcon: InkWell(
                              onTap: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                Provider.of<DownloadProvider>(context,
                                        listen: false)
                                    .disableAd();
                                FocusScopeNode currentFocus =
                                    FocusScope.of(context);
                                await SharPreferences.setString('OpenAd', '1');
                                if (!currentFocus.hasPrimaryFocus) {
                                  currentFocus.unfocus();
                                }
                                await loadLocal();
                                _searchFilter(searchController.text);

                                await SharPreferences.setString('OpenAd', '1');
                                setState(() {
                                  isLoading = false;
                                });
                              },
                              child: Container(
                                  width: screenWidth > 450 ? 55 : 45,
                                  height: screenWidth > 450 ? 55 : 45,
                                  padding: EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                      color:
                                          CommanColor.lightDarkPrimary(context),
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(7.5),
                                          bottomRight: Radius.circular(7.5))),
                                  child: Image.asset(
                                    "assets/search.png",
                                    height: screenWidth > 450 ? 20 : 12,
                                    width: 15,
                                    color: Colors.white,
                                  )),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            hintStyle: CommanStyle.grey13400,
                            fillColor: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: screenWidth > 450 ? 45 : 30,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () async {
                                  await SharPreferences.setString(
                                      'OpenAd', '1');
                                  FocusScopeNode currentFocus =
                                      FocusScope.of(context);

                                  if (!currentFocus.hasPrimaryFocus) {
                                    currentFocus.unfocus();
                                  }
                                  setState(() {
                                    selectedBook =
                                        MainBookListModel(bookNum: -1);
                                    index == 0
                                        ? selectedValueFilter = "ALL"
                                        : index == 1
                                            ? selectedValueFilter = "OT"
                                            : selectedValueFilter = "NT";
                                    selectedValueFilterIndex = index;
                                    filterSelectedVersesContent.clear();
                                    _searchFilter(searchController.text);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: screenWidth > 450 ? 65 : 50,
                                    height: 30,
                                    child: Card(
                                      elevation: 2,
                                      color: selectedValueFilterIndex == index
                                          ? CommanColor.lightDarkPrimary(
                                              context)
                                          : Colors.white,
                                      margin: EdgeInsets.only(right: 10),
                                      child: Center(
                                        child: index == 0
                                            ? Text(
                                                "ALL",
                                                style: selectedValueFilter ==
                                                        "ALL"
                                                    ? screenWidth > 450
                                                        ? CommanStyle.white14500
                                                            .copyWith(
                                                                fontSize: 19,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)
                                                        : CommanStyle.white14500
                                                    : screenWidth > 450
                                                        ? CommanStyle.black14500
                                                            .copyWith(
                                                                fontSize: 19,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)
                                                        : CommanStyle
                                                            .black15400,
                                              )
                                            : index == 1
                                                ? Text(
                                                    "OT",
                                                    style: selectedValueFilter ==
                                                            "OT"
                                                        ? screenWidth > 450
                                                            ? CommanStyle
                                                                .white14500
                                                                .copyWith(
                                                                    fontSize:
                                                                        19,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)
                                                            : CommanStyle
                                                                .white14500
                                                        : screenWidth > 450
                                                            ? CommanStyle
                                                                .black14500
                                                                .copyWith(
                                                                    fontSize:
                                                                        19,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)
                                                            : CommanStyle
                                                                .black15400,
                                                  )
                                                : Text(
                                                    "NT",
                                                    style: selectedValueFilter ==
                                                            "NT"
                                                        ? screenWidth > 450
                                                            ? CommanStyle
                                                                .white14500
                                                                .copyWith(
                                                                    fontSize:
                                                                        19,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)
                                                            : CommanStyle
                                                                .white14500
                                                        : screenWidth > 450
                                                            ? CommanStyle
                                                                .black14500
                                                                .copyWith(
                                                                    fontSize:
                                                                        19,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)
                                                            : CommanStyle
                                                                .black15400,
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!_isBookNameSearchMode)
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<MainBookListModel>(
                              isExpanded: true,
                              items: selectedValueFilterIndex == 0
                                  ? [
                                      DropdownMenuItem<MainBookListModel>(
                                        value: _allChapterItem,
                                        child: Text(
                                          _allChapterItem.title ??
                                              "All Chapter",
                                          style: TextStyle(
                                            letterSpacing:
                                                BibleInfo.letterSpacing,
                                            fontSize: BibleInfo.fontSizeScale *
                                                        screenWidth >
                                                    450
                                                ? 19
                                                : 15,
                                            fontWeight: FontWeight.w400,
                                            color: selectedBook.bookNum == -1
                                                ? CommanColor.lightDarkPrimary(
                                                    context)
                                                : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...bookList
                                          .where((b) => b.bookNum != -1)
                                          .map((item) => DropdownMenuItem<
                                                  MainBookListModel>(
                                                value: item,
                                                child: Text(
                                                  item.title.toString(),
                                                  style: TextStyle(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize:
                                                        BibleInfo.fontSizeScale *
                                                                    screenWidth >
                                                                450
                                                            ? 19
                                                            : 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: selectedBook.title ==
                                                            item.title
                                                        ? CommanColor
                                                            .lightDarkPrimary(
                                                                context)
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )),
                                    ]
                                  : selectedValueFilterIndex == 1
                                      ? oTBookList
                                          .map((item) => DropdownMenuItem<
                                                  MainBookListModel>(
                                                value: item,
                                                child: Text(
                                                  item.title.toString(),
                                                  style: TextStyle(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize:
                                                        BibleInfo.fontSizeScale *
                                                                    screenWidth >
                                                                450
                                                            ? 19
                                                            : 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: selectedBook.title ==
                                                            item.title
                                                        ? CommanColor
                                                            .lightDarkPrimary(
                                                                context)
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList()
                                      : nTBookList
                                          .map((item) => DropdownMenuItem<
                                                  MainBookListModel>(
                                                value: item,
                                                child: Text(
                                                  item.title.toString(),
                                                  style: TextStyle(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize:
                                                        BibleInfo.fontSizeScale *
                                                                    screenWidth >
                                                                450
                                                            ? 19
                                                            : 15,
                                                    fontWeight: FontWeight.w400,
                                                    color: selectedBook.title ==
                                                            item.title
                                                        ? CommanColor
                                                            .lightDarkPrimary(
                                                                context)
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                              value: selectedBook.bookNum == -1
                                  ? _allChapterItem
                                  : selectedBook,
                              onChanged: (newValue) async {
                                FocusScopeNode currentFocus =
                                    FocusScope.of(context);
                                await SharPreferences.setString('OpenAd', '1');
                                if (!currentFocus.hasPrimaryFocus) {
                                  currentFocus.unfocus();
                                }
                                setState(() {
                                  selectedBook = newValue!;
                                  filterSelectedVersesContent.clear();
                                });
                                _searchFilter(searchController.text);
                              },
                              hint: Text("All Chapter",
                                  style: screenWidth > 450
                                      ? CommanStyle.black15400.copyWith(
                                          fontSize: 19,
                                          fontFamily: selectedFontFamily)
                                      : CommanStyle.black15400.copyWith(
                                          fontFamily: selectedFontFamily)),
                              iconStyleData: IconStyleData(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_sharp,
                                ),
                                iconSize: screenWidth > 450 ? 30 : 20,
                                iconEnabledColor:
                                    CommanColor.lightDarkPrimary(context),
                                iconDisabledColor:
                                    CommanColor.lightDarkPrimary(context),
                              ),
                              buttonStyleData: ButtonStyleData(
                                  height: screenWidth > 450 ? 45 : 33,
                                  width:
                                      MediaQuery.of(context).size.width * 0.43,
                                  padding:
                                      const EdgeInsets.only(left: 8, right: 3),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.white),
                                  elevation: 1,
                                  overlayColor:
                                      WidgetStateProperty.all(Colors.white)),
                              menuItemStyleData: MenuItemStyleData(
                                height: 33,
                                padding:
                                    const EdgeInsets.only(left: 8, right: 3),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                width: MediaQuery.of(context).size.width * 0.43,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                elevation: 1,
                                scrollbarTheme: ScrollbarThemeData(
                                    radius: const Radius.circular(20),
                                    thickness: WidgetStateProperty.all(5.0),
                                    minThumbLength: 20),
                                offset: const Offset(0, -5),
                              ),
                              style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  searchController.text.isEmpty
                      ? Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.15),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  Images.searchPlaceHolder(context),
                                  height: 160,
                                  width: 160,
                                ),
                              
                                // Text(
                                //   'Search by Words',
                                //   style: TextStyle(
                                //     fontSize: 20,
                                //     fontWeight: FontWeight.bold,
                                //     color: CommanColor.whiteBlack(context),
                                //   ),
                                //   textAlign: TextAlign.center,
                                // ),
                              
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'Search by word or book name.\nExample: Love or Genesis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: CommanColor.whiteBlack(context)
                                          .withOpacity(0.7),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filterSelectedVersesContent.isEmpty
                          ? SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.13),
                                  Image.asset(
                                    Images.searchPlaceHolder(context),
                                    height: 150,
                                    width: 150,
                                    color: Colors.transparent.withOpacity(0.3),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    isLoading
                                        ? "Fetching data... Please wait"
                                        : "No results found",
                                    style: CommanStyle.black16500.copyWith(
                                        color: CommanColor.whiteBlack(context)),
                                  )
                                ],
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filterSelectedVersesContent.length,
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                physics: const ScrollPhysics(),
                                itemBuilder: (context, index) {
                                  print(filterSelectedVersesContent.length);
                                  var data = filterSelectedVersesContent[index];
                                  String? bookName;
                                  for (var name in bookList) {
                                    if (name.bookNum == data.bookNum) {
                                      bookName = name.title;
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: () async {
                                      await SharPreferences.setString(
                                          'OpenAd', '1');
                                      showModalBottomSheet(
                                        enableDrag: true,
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20))),
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(20),
                                                    topRight:
                                                        Radius.circular(20))),
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      height: 3,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(3),
                                                          color: CommanColor
                                                              .lightDarkPrimary(
                                                                  context)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                Text(
                                                  html
                                                          .parse(
                                                              "${data.content}")
                                                          .body
                                                          ?.text ??
                                                      '',
                                                  // "${data.content}",
                                                  style: CommanStyle.black15400
                                                      .copyWith(
                                                    fontFamily:
                                                        selectedFontFamily,
                                                  ),
                                                  maxLines: 7,
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                        "$bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                                                        style: CommanStyle
                                                            .black15400),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 35,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              await SharPreferences
                                                                  .setString(
                                                                      'OpenAd',
                                                                      '1');
                                                              await Clipboard.setData(
                                                                  ClipboardData(
                                                                      text:
                                                                          "${html.parse("${data.content}").body?.text ?? ''} \n$bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}"));
                                                              Constants
                                                                  .showToast(
                                                                      "Copied");
                                                            },
                                                            child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(6),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context),
                                                                    width: 1.4,
                                                                  ),
                                                                ),
                                                                child: Image.asset(
                                                                    "assets/Bookmark icons/Frame 3630.png",
                                                                    height: 28,
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context)))),
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Text(
                                                          "Copy",
                                                          style: CommanStyle
                                                              .bothPrimary14500(
                                                                  context),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: 30,
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        Provider.of<DownloadProvider>(
                                                                context,
                                                                listen: false)
                                                            .enableAd();
                                                        // if (_myProvider !=
                                                        //     null) {
                                                        //   _myProvider?.enableAd();
                                                        // }
                                                        await SharPreferences
                                                            .setString(
                                                                'OpenAd', '1');
                                                        await SharPreferences
                                                            .setString(
                                                                SharPreferences
                                                                    .selectedBook,
                                                                bookName
                                                                    .toString());
                                                        await SharPreferences.setString(
                                                            SharPreferences
                                                                .selectedChapter,
                                                            "${1 + int.parse(data.chapterNum.toString())}");
                                                        await SharPreferences.setString(
                                                            SharPreferences
                                                                .selectedBookNum,
                                                            "${int.parse(data.bookNum.toString())}");
                                                        await SharPreferences
                                                            .setString(
                                                                'OpenAd', '1');

                                                        // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                                                        Get.offAll(
                                                            () => HomeScreen(
                                                                From: "Read",
                                                                selectedBookForRead:
                                                                    int.parse(data
                                                                        .bookNum
                                                                        .toString()),
                                                                selectedChapterForRead:
                                                                    int.parse(data.chapterNum.toString()) +
                                                                        1,
                                                                selectedVerseNumForRead:
                                                                    int.parse(data.verseNum.toString()) +
                                                                        1,
                                                                selectedBookNameForRead:
                                                                    bookName
                                                                        .toString(),
                                                                selectedVerseForRead:
                                                                    parse(data.content)
                                                                        .body
                                                                        ?.text
                                                                        .toString()),
                                                            transition: Transition
                                                                .cupertinoDialog,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds: 300));
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              height: 40,
                                                              width: 40,
                                                              decoration: BoxDecoration(
                                                                  border: Border.all(
                                                                      color: CommanColor
                                                                          .lightDarkPrimary(
                                                                              context),
                                                                      width:
                                                                          1.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              3)),
                                                              child:
                                                                  Image.asset(
                                                                "assets/reading_book.png",
                                                                height: 25,
                                                                width: 15,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context),
                                                              )),
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Text("Read",
                                                              style: CommanStyle
                                                                  .bothPrimary14500(
                                                                      context)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 30,
                                                    ),
                                                    Column(
                                                      children: [
                                                        InkWell(
                                                            onTap: () async {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        ShareAlertBox(
                                                                  verseTitle:
                                                                      " $bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                                                                  onShareAsText:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    // Your logic here
                                                                    final appPackageName =
                                                                        (await PackageInfo.fromPlatform())
                                                                            .packageName;
                                                                    String
                                                                        message =
                                                                        ''; // Declare the message variable outside the if-else block
                                                                    String
                                                                        appid;
                                                                    appid = BibleInfo
                                                                        .apple_AppId;
                                                                    if (Platform
                                                                        .isAndroid) {
                                                                      message =
                                                                          "${html.parse("${data.content}").body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                                    } else if (Platform
                                                                        .isIOS) {
                                                                      message =
                                                                          '${html.parse("${data.content}").body?.text ?? ''}.\n You can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
                                                                    }

                                                                    if (message
                                                                        .isNotEmpty) {
                                                                      Share.share(
                                                                          message,
                                                                          sharePositionOrigin: Rect.fromPoints(
                                                                              const Offset(2, 2),
                                                                              const Offset(3, 3)));
                                                                    } else {
                                                                      print(
                                                                          'Message is empty or undefined');
                                                                    }
                                                                  },
                                                                  onShareAsImage:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    final controller =
                                                                        DashBoardController();
                                                                    await showModalBottomSheet(
                                                                      isScrollControlled:
                                                                          true,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) {
                                                                        return ImageBottomSheets(
                                                                          controller:
                                                                              controller,
                                                                          content:
                                                                              data.content,
                                                                          selectedBook:
                                                                              bookName.toString(),
                                                                          selectedChapter:
                                                                              '${int.parse(data.chapterNum.toString()) + 1}',
                                                                          selectedVerseView:
                                                                              '${int.parse(data.verseNum.toString()) + 1}',
                                                                        );
                                                                      },
                                                                    );

                                                                    // Your logic here
                                                                    // Navigator.pop(context);
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                            child: Image.asset(
                                                                "assets/share.png",
                                                                height: 40,
                                                                color: CommanColor
                                                                    .lightDarkPrimary(
                                                                        context))),
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Text("Share",
                                                            style: CommanStyle
                                                                .bothPrimary14500(
                                                                    context)),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: 30,
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        Navigator.of(context).pop();
                                                        Get.to(
                                                          () => ChatScreen(
                                                            verseContext: {
                                                              'verseText': parse(
                                                                      data.content)
                                                                  .body
                                                                  ?.text
                                                                  .toString() ??
                                                                  '',
                                                              'book':
                                                                  bookName.toString(),
                                                              'chapter':
                                                                  '${int.parse(data.chapterNum.toString()) + 1}',
                                                              'verse':
                                                                  '${int.parse(data.verseNum.toString()) + 1}',
                                                            },
                                                          ),
                                                          transition: Transition
                                                              .cupertinoDialog,
                                                          duration: const Duration(
                                                              milliseconds: 300),
                                                        );
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .all(8),
                                                            height: 40,
                                                            width: 40,
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: CommanColor
                                                                      .lightDarkPrimary(
                                                                          context),
                                                                  width: 1.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .question_answer_outlined,
                                                              size: 22,
                                                              color: CommanColor
                                                                  .lightDarkPrimary(
                                                                      context),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          Text(
                                                              "Ask",
                                                              style: CommanStyle
                                                                  .bothPrimary14500(
                                                                      context)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 2.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    Text.rich(
                                                      TextSpan(
                                                        children:
                                                            highlightOccurrences(
                                                                html
                                                                        .parse(
                                                                            "${data.content}")
                                                                        .body
                                                                        ?.text ??
                                                                    '',
                                                                searchController
                                                                    .text
                                                                    .toString(),
                                                                screenWidth,
                                                                fontSize),
                                                        style:
                                                            CommanStyle.bw14500(
                                                                    context)
                                                                .copyWith(
                                                          fontSize: fontSize,
                                                          fontFamily:
                                                              selectedFontFamily,
                                                          // fontSize: screenWidth > 450
                                                          //     ? BibleInfo
                                                          //             .fontSizeScale *
                                                          //         30
                                                          //     : BibleInfo.fontSizeScale *
                                                          //             widget
                                                          //                 .controller
                                                          //                 .fontSize
                                                          //                 .value ??
                                                          //         14,
                                                          // screenWidth >
                                                          //         450
                                                          //     ? BibleInfo
                                                          //             .fontSizeScale *
                                                          //         23
                                                          //     : BibleInfo
                                                          //             .fontSizeScale *
                                                          //         14
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 8,
                                                    ),
                                                    Text(
                                                        "$bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                                                        textAlign:
                                                            TextAlign.right,
                                                        style:
                                                            CommanStyle.bw14500(
                                                                    context)
                                                                .copyWith(
                                                          fontSize: fontSize,
                                                          fontFamily:
                                                              selectedFontFamily,
                                                          // screenWidth >
                                                          //         450
                                                          //     ? BibleInfo
                                                          //             .fontSizeScale *
                                                          //         23
                                                          //     : BibleInfo
                                                          //             .fontSizeScale *
                                                          //         14
                                                        )),
                                                    const SizedBox(height: 8),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                await SharPreferences.setString(
                                                    'OpenAd', '1');
                                                showModalBottomSheet(
                                                  enableDrag: true,
                                                  shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(20),
                                                              topRight: Radius
                                                                  .circular(
                                                                      20))),
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 30,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          20),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          20))),
                                                      child: ListView(
                                                        shrinkWrap: true,
                                                        children: [
                                                          SizedBox(
                                                            height: 10,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Container(
                                                                height: 3,
                                                                width: 40,
                                                                decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                3),
                                                                    color: CommanColor
                                                                        .lightDarkPrimary(
                                                                            context)),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Text(
                                                            html
                                                                    .parse(
                                                                        "${data.content}")
                                                                    .body
                                                                    ?.text ??
                                                                '',
                                                            // "${data.content}",
                                                            style: CommanStyle
                                                                .black15400
                                                                .copyWith(
                                                              fontFamily:
                                                                  selectedFontFamily,
                                                            ),
                                                            maxLines: 7,
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Text(
                                                                  "$bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                                                                  style: CommanStyle
                                                                      .black15400),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 35,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Column(
                                                                children: [
                                                                  InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        await SharPreferences.setString(
                                                                            'OpenAd',
                                                                            '1');
                                                                        await Clipboard.setData(ClipboardData(
                                                                            text:
                                                                                "${html.parse("${data.content}").body?.text ?? ''} \n$bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}"));
                                                                        Constants.showToast(
                                                                            "Copied");
                                                                      },
                                                                      child: Container(
                                                                          padding: const EdgeInsets.all(6),
                                                                          decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                            border:
                                                                                Border.all(
                                                                              color: CommanColor.lightDarkPrimary(context),
                                                                              width: 1.4,
                                                                            ),
                                                                          ),
                                                                          child: Image.asset("assets/Bookmark icons/Frame 3630.png", height: 25, width: 25, color: CommanColor.lightDarkPrimary(context)))),
                                                                  const SizedBox(
                                                                    height: 15,
                                                                  ),
                                                                  Text(
                                                                    "Copy",
                                                                    style: CommanStyle
                                                                        .bothPrimary14500(
                                                                            context),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                width: 30,
                                                              ),
                                                              InkWell(
                                                                onTap:
                                                                    () async {
                                                                  Provider.of<DownloadProvider>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .enableAd();
                                                                  // if (_myProvider !=
                                                                  //     null) {
                                                                  //   _myProvider?.enableAd();
                                                                  // }
                                                                  await SharPreferences
                                                                      .setString(
                                                                          'OpenAd',
                                                                          '1');
                                                                  await SharPreferences.setString(
                                                                      SharPreferences
                                                                          .selectedBook,
                                                                      bookName
                                                                          .toString());
                                                                  await SharPreferences.setString(
                                                                      SharPreferences
                                                                          .selectedChapter,
                                                                      "${1 + int.parse(data.chapterNum.toString())}");
                                                                  await SharPreferences.setString(
                                                                      SharPreferences
                                                                          .selectedBookNum,
                                                                      "${int.parse(data.bookNum.toString())}");
                                                                  await SharPreferences
                                                                      .setString(
                                                                          'OpenAd',
                                                                          '1');

                                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => );
                                                                  Get.offAll(
                                                                      () => HomeScreen(
                                                                          From:
                                                                              "Read",
                                                                          selectedBookForRead: int.parse(data
                                                                              .bookNum
                                                                              .toString()),
                                                                          selectedChapterForRead: int.parse(data.chapterNum.toString()) +
                                                                              1,
                                                                          selectedVerseNumForRead: int.parse(data.verseNum.toString()) +
                                                                              1,
                                                                          selectedBookNameForRead: bookName
                                                                              .toString(),
                                                                          selectedVerseForRead: parse(data.content)
                                                                              .body
                                                                              ?.text
                                                                              .toString()),
                                                                      transition:
                                                                          Transition
                                                                              .cupertinoDialog,
                                                                      duration:
                                                                          const Duration(
                                                                              milliseconds: 300));
                                                                },
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                        height:
                                                                            40,
                                                                        width:
                                                                            40,
                                                                        decoration: BoxDecoration(
                                                                            border:
                                                                                Border.all(color: CommanColor.lightDarkPrimary(context), width: 1.2),
                                                                            borderRadius: BorderRadius.circular(3)),
                                                                        child: Image.asset(
                                                                          "assets/reading_book.png",
                                                                          height:
                                                                              25,
                                                                          width:
                                                                              15,
                                                                          color:
                                                                              CommanColor.lightDarkPrimary(context),
                                                                        )),
                                                                    const SizedBox(
                                                                      height:
                                                                          15,
                                                                    ),
                                                                    Text("Read",
                                                                        style: CommanStyle.bothPrimary14500(
                                                                            context)),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 30,
                                                              ),
                                                              Column(
                                                                children: [
                                                                  InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder: (context) =>
                                                                              ShareAlertBox(
                                                                            verseTitle:
                                                                                " $bookName ${int.parse(data.chapterNum.toString()) + 1}:${int.parse(data.verseNum.toString()) + 1}",
                                                                            onShareAsText:
                                                                                () async {
                                                                              Navigator.of(context).pop();
                                                                              // Your logic here
                                                                              final appPackageName = (await PackageInfo.fromPlatform()).packageName;
                                                                              String message = ''; // Declare the message variable outside the if-else block
                                                                              String appid;
                                                                              appid = BibleInfo.apple_AppId;
                                                                              if (Platform.isAndroid) {
                                                                                message = "${html.parse("${data.content}").body?.text ?? ''}. \n   You can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName";
                                                                              } else if (Platform.isIOS) {
                                                                                message = '${html.parse("${data.content}").body?.text ?? ''}.\n You can read more at:\nhttps://itunes.apple.com/app/id$appid'; // Example iTunes URL
                                                                              }

                                                                              if (message.isNotEmpty) {
                                                                                Share.share(message, sharePositionOrigin: Rect.fromPoints(const Offset(2, 2), const Offset(3, 3)));
                                                                              } else {
                                                                                print('Message is empty or undefined');
                                                                              }
                                                                            },
                                                                            onShareAsImage:
                                                                                () async {
                                                                              Navigator.of(context).pop();
                                                                              final controller = DashBoardController();
                                                                              await showModalBottomSheet(
                                                                                isScrollControlled: true,
                                                                                backgroundColor: Colors.transparent,
                                                                                context: context,
                                                                                builder: (context) {
                                                                                  return ImageBottomSheets(
                                                                                    controller: controller,
                                                                                    content: data.content,
                                                                                    selectedBook: bookName.toString(),
                                                                                    selectedChapter: '${int.parse(data.chapterNum.toString()) + 1}',
                                                                                    selectedVerseView: '${int.parse(data.verseNum.toString()) + 1}',
                                                                                  );
                                                                                },
                                                                              );

                                                                              // Your logic here
                                                                              // Navigator.pop(context);
                                                                            },
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Image.asset(
                                                                          "assets/share.png",
                                                                          height:
                                                                              40,
                                                                          color:
                                                                              CommanColor.lightDarkPrimary(context))),
                                                                  const SizedBox(
                                                                    height: 15,
                                                                  ),
                                                                  Text("Share",
                                                                      style: CommanStyle
                                                                          .bothPrimary14500(
                                                                              context)),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  width: 30),
                                                              InkWell(
                                                                onTap: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  Get.to(
                                                                    () => ChatScreen(
                                                                      verseContext: {
                                                                        'verseText': parse(data.content)
                                                                            .body
                                                                            ?.text
                                                                            .toString() ??
                                                                            '',
                                                                        'book':
                                                                            bookName.toString(),
                                                                        'chapter':
                                                                            '${int.parse(data.chapterNum.toString()) + 1}',
                                                                        'verse':
                                                                            '${int.parse(data.verseNum.toString()) + 1}',
                                                                      },
                                                                    ),
                                                                    transition:
                                                                        Transition
                                                                            .cupertinoDialog,
                                                                    duration: const Duration(
                                                                        milliseconds: 300),
                                                                  );
                                                                },
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      padding: const EdgeInsets.all(8),
                                                                      height: 40,
                                                                      width: 40,
                                                                      decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                            color: CommanColor.lightDarkPrimary(context),
                                                                            width: 1.2),
                                                                        borderRadius: BorderRadius.circular(8),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons.question_answer_outlined,
                                                                        size: 22,
                                                                        color: CommanColor.lightDarkPrimary(context),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 15),
                                                                    Text("Ask",
                                                                        style: CommanStyle.bothPrimary14500(context)),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10.0),
                                                child: Icon(
                                                  Icons.more_vert,
                                                  color: CommanColor.whiteBlack(
                                                      context),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                            height: 2,
                                            child: Divider(
                                              thickness: 0.5,
                                              color: CommanColor.whiteBlack(
                                                  context),
                                            ))
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> highlightOccurrences(
      String source, String query, screenWidth, double fontSize) {
    if (query.isEmpty || !source.toLowerCase().contains(query.toLowerCase())) {
      return [
        TextSpan(
          text: source,
          style: TextStyle(fontFamily: selectedFontFamily),
        )
      ];
    }
    final matches = query.toLowerCase().allMatches(source.toLowerCase());

    int lastMatchEnd = 0;

    final List<TextSpan> children = [];
    for (var i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);

      if (match.start != lastMatchEnd) {
        children.add(TextSpan(
          text: source.substring(lastMatchEnd, match.start),
          style: TextStyle(fontFamily: selectedFontFamily),
        ));
      }
      children.add(TextSpan(
        text: " ${source.substring(match.start, match.end)} ",
        style: CommanStyle.searchTextStyle(context)
            .copyWith(fontFamily: selectedFontFamily, fontSize: fontSize),
      ));

      if (i == matches.length - 1 && match.end != source.length) {
        children.add(TextSpan(
          text: source.substring(match.end, source.length),
          style: TextStyle(fontFamily: selectedFontFamily),
        ));
      }

      lastMatchEnd = match.end;
    }
    return children;
  }
}
