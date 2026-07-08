import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topics_data.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topics_screen.dart';
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

  static const String _recentSearchesKey = 'search_recent_queries';
  static const int _maxRecentSearches = 10;
  List<String> _bookSuggestions = [];
  List<String> _recentSearches = [];
  int _faithCredits = 0;

  bool isLoading = false;
  bool _isBookNameSearchMode = false;
  bool _hasPerformedSearch = false;
  bool _searchGuideSubtextShown = false;

  bool get _hasSearchResults =>
      _hasPerformedSearch && filterSelectedVersesContent.isNotEmpty;

  bool get _showSearchGuideSubtext =>
      !_searchGuideSubtextShown && !_hasSearchResults;

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
    getFont();
    _loadRecentSearches();
    _loadFaithCredits();
    _loadSearchGuideSubtextPref();
    searchController.addListener(() {
      if (mounted) {
        setState(() {
          if (searchController.text.trim().isEmpty) {
            _hasPerformedSearch = false;
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSearchData();
    });
  }

  void _syncListsFromProvider(DownloadProvider downloadProvider) {
    allVersesContent = downloadProvider.verseList;
    allOtVersesContent = downloadProvider.otVerseList;
    allNtVersesContent = downloadProvider.ntVerseList;
    if (bookList.length <= 1) {
      bookList = downloadProvider.bookList;
    }
    if (oTBookList.isEmpty) {
      oTBookList = downloadProvider.otBookList;
    }
    if (nTBookList.isEmpty) {
      nTBookList = downloadProvider.ntBookList;
    }
  }

  Future<void> _initializeSearchData() async {
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    // Show suggestions immediately when splash/home already cached Bible data.
    if (downloadProvider.verseList.isNotEmpty) {
      _syncListsFromProvider(downloadProvider);
      if (mounted) {
        setState(() => _refreshVerseSuggestions());
      }
    }

    final bookListsFuture = loadBookListsFromPrefs();

    if (allVersesContent.isEmpty) {
      final loaded =
          await downloadProvider.preloadBibleDataFromDatabaseIfNeeded();
      if (loaded && mounted) {
        _syncListsFromProvider(downloadProvider);
        setState(() => _refreshVerseSuggestions());
      }
    }

    await bookListsFuture;
    if (!mounted) return;
    setState(() {});

    // Keep full local hydrate + prefs sync in background (no UI wait).
    unawaited(loadLocal());

    // Preload Explore Topics category list so the grid opens instantly.
    VerseTopicsData.preloadCategories();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) {
      setState(() => _recentSearches = list);
    }
  }

  Future<void> _loadSearchGuideSubtextPref() async {
    final shown = await SharPreferences.getBoolean(
            SharPreferences.searchGuideSubtextShown) ??
        false;
    if (mounted) {
      setState(() => _searchGuideSubtextShown = shown);
    } else {
      _searchGuideSubtextShown = shown;
    }
  }

  Future<void> _markSearchGuideSubtextSeen() async {
    if (_searchGuideSubtextShown) return;
    _searchGuideSubtextShown = true;
    await SharPreferences.setBoolean(
        SharPreferences.searchGuideSubtextShown, true);
  }

  Future<void> _saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final updated = [
      q,
      ..._recentSearches.where((e) => e.toLowerCase() != q.toLowerCase()),
    ];
    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _removeRecentSearch(String query) async {
    final updated =
        _recentSearches.where((e) => e.toLowerCase() != query.toLowerCase()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  Future<void> _loadFaithCredits() async {
    final credits = await WalletService.getCredits();
    if (mounted) setState(() => _faithCredits = credits);
  }

  void _applySearchQuery(String query) {
    searchController.text = query;
    _performSearch();
  }

  void _refreshVerseSuggestions() {
    List<VerseBookContentModel> verses = allVersesContent;
    if (verses.isEmpty) {
      verses =
          Provider.of<DownloadProvider>(context, listen: false).verseList;
    }
    if (verses.isEmpty) return;

    final random = math.Random();
    final suggestions = <String>[];
    final picked = <int>{};
    final total = verses.length;
    var attempts = 0;
    final maxAttempts = math.min(total * 3, 120);

    while (suggestions.length < 4 && attempts < maxAttempts) {
      attempts++;
      final index = random.nextInt(total);
      if (!picked.add(index)) continue;

      final snippet = _verseSuggestionSnippet(verses[index]);
      if (snippet.isEmpty) continue;
      final isDuplicate = suggestions.any(
        (existing) => existing.toLowerCase() == snippet.toLowerCase(),
      );
      if (!isDuplicate) suggestions.add(snippet);
    }

    _bookSuggestions = suggestions;
  }

  void _openPreferenceSelection() {
    Get.to(
      () => const VerseTopicsScreen(),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 350),
    );
  }

  /// Opens the reader at [verseIndex] (0-based) without rebuilding the stack.
  Future<void> _openVerseInReader({
    required String bookName,
    required int bookNum,
    required int chapter,
    required int verseIndex,
    required String verseText,
  }) async {
    await SharPreferences.setString('OpenAd', '1');
    await SharPreferences.setString(SharPreferences.selectedBook, bookName);
    await SharPreferences.setString(
        SharPreferences.selectedChapter, '$chapter');
    await SharPreferences.setString(
        SharPreferences.selectedBookNum, '$bookNum');
    try {
      final controller = Get.find<DashBoardController>();
      controller.selectedBook.value = bookName;
      controller.selectedBookNum.value = '$bookNum';
      controller.selectedChapter.value = '$chapter';
      controller.selectChapterChange.value = chapter;
      controller.selectedBookNameForRead.value = bookName;
      controller.selectedBookNumForRead.value = '$bookNum';
      controller.selectedChapterForRead.value = '$chapter';
      controller.selectedVerseForRead.value = '$verseIndex';
      await controller.getSelectedChapterAndBook();
      controller.readHighlight.value = true;
      controller.selectedIndex.value = verseIndex;
      if (Navigator.of(context).canPop()) {
        Get.until((route) => route.isFirst);
      } else {
        Get.offAll(
          () => HomeScreen(
            From: 'Read',
            selectedBookForRead: bookNum,
            selectedChapterForRead: chapter,
            selectedVerseNumForRead: verseIndex,
            selectedBookNameForRead: bookName,
            selectedVerseForRead: verseText,
            fromSearch: true,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 280),
          opaque: true,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 80), () async {
          try {
            await controller.scrollToIndex(verseIndex);
          } catch (_) {}
          Future.delayed(const Duration(seconds: 6), () {
            controller.readHighlight.value = false;
            controller.selectedIndex.value = -1;
          });
        });
      });
    } catch (_) {
      Get.offAll(
        () => HomeScreen(
          From: 'Read',
          selectedBookForRead: bookNum,
          selectedChapterForRead: chapter,
          selectedVerseNumForRead: verseIndex,
          selectedBookNameForRead: bookName,
          selectedVerseForRead: verseText,
          fromSearch: true,
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 280),
        opaque: true,
      );
    }
  }

  Widget _buildExploreTopicsBanner(double screenWidth) {
    final primary = CommanColor.lightDarkPrimary(context);
    final lightText = _searchUsesLightText(context);
    final textColor = _searchTextColor(context);
    final mutedColor = _searchMutedTextColor(context, 0.75);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
      child: Container(
        padding: EdgeInsets.all(screenWidth > 450 ? 16 : 12),
        decoration: BoxDecoration(
          color: lightText
              ? Colors.white.withOpacity(0.12)
              : const Color(0xFFF8F4EB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _searchCardBorderColor(context, primary)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            lightText
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.22),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      Images.searchPlaceHolder(context),
                      width: screenWidth > 450 ? 72 : 58,
                      height: screenWidth > 450 ? 72 : 58,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    Images.searchPlaceHolder(context),
                    width: screenWidth > 450 ? 72 : 58,
                    height: screenWidth > 450 ? 72 : 58,
                    fit: BoxFit.contain,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Can't find what you're looking for?",
                    style: TextStyle(
                      fontSize: screenWidth > 450 ? 15 : 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore popular topics and curated verses to inspire your journey.',
                    style: TextStyle(
                      fontSize: screenWidth > 450 ? 12 : 11,
                      color: mutedColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _openPreferenceSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 450 ? 14 : 10,
                  vertical: screenWidth > 450 ? 12 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Explore Topics',
                style: TextStyle(
                  fontSize: screenWidth > 450 ? 13 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _searchUsesLightText(BuildContext context) {
    return CommanColor.isDarkTheme(context);
  }

  Color _searchTextColor(BuildContext context) {
    return _searchUsesLightText(context) ? Colors.white : Colors.black;
  }

  Color _searchMutedTextColor(BuildContext context, [double opacity = 0.78]) {
    return _searchUsesLightText(context)
        ? Colors.white.withOpacity(opacity)
        : Colors.black.withOpacity(opacity * 0.85);
  }

  Color _searchCardColor(BuildContext context) {
    return _searchUsesLightText(context)
        ? Colors.white.withOpacity(0.14)
        : Colors.white;
  }

  Color _searchCardBorderColor(BuildContext context, Color primary) {
    return _searchUsesLightText(context)
        ? Colors.white.withOpacity(0.28)
        : primary.withOpacity(0.22);
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
    if (mounted) {
      setState(() {});
    }
    // Decode and convert to model lists

    // if (allBookJson != null) {
    //   bookList = (jsonDecode(allBookJson) as List)
    //       .map((e) => MainBookListModel.fromJson(e))
    //       .toList();
    // }
  }

  Future<void> _performSearch() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    Provider.of<DownloadProvider>(context, listen: false).disableAd();
    final currentFocus = FocusScope.of(context);
    await SharPreferences.setString('OpenAd', '1');
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    await loadLocal();
    await _searchFilter(searchController.text);
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      await _saveRecentSearch(query);
    }
    await SharPreferences.setString('OpenAd', '1');
    if (!mounted) return;
    setState(() {
      isLoading = false;
      _hasPerformedSearch = query.isNotEmpty;
    });
    if (query.isNotEmpty && filterSelectedVersesContent.isNotEmpty) {
      await _markSearchGuideSubtextSeen();
    }
  }

  bool _showExploreTopicsBanner() {
    return _hasPerformedSearch && searchController.text.trim().isNotEmpty;
  }

  Future<void> _onFilterSelected(int index) async {
    await SharPreferences.setString('OpenAd', '1');
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    if (mounted) {
      setState(() {
        selectedBook = MainBookListModel(bookNum: -1);
        selectedValueFilter =
            index == 0 ? "ALL" : index == 1 ? "OT" : "NT";
        selectedValueFilterIndex = index;
        filterSelectedVersesContent.clear();
      });
    }
    await _searchFilter(searchController.text);
  }

  /// Resolves a [DropdownButton2] value that exists in the current items list.
  /// Avoids assertion failures when OT/NT lists omit [_allChapterItem].
  MainBookListModel? _resolveDropdownValue() {
    if (selectedValueFilterIndex == 0) {
      if (selectedBook.bookNum == -1) return _allChapterItem;
      for (final book in bookList) {
        if (book.bookNum == selectedBook.bookNum) return book;
      }
      return _allChapterItem;
    }

    final list = selectedValueFilterIndex == 1 ? oTBookList : nTBookList;
    if (selectedBook.bookNum == -1) return null;
    for (final book in list) {
      if (book.bookNum == selectedBook.bookNum) return book;
    }
    return null;
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    required double screenWidth,
  }) {
    final isSelected = selectedValueFilterIndex == index;
    final primary = CommanColor.lightDarkPrimary(context);
    final lightText = _searchUsesLightText(context);
    return GestureDetector(
      onTap: () => _onFilterSelected(index),
      child: Padding(
        padding: EdgeInsets.only(right: screenWidth > 450 ? 10 : 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 450 ? 18 : 14,
            vertical: screenWidth > 450 ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (lightText ? Colors.white : primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: lightText
                  ? Colors.white
                  : (isSelected ? primary : primary.withOpacity(0.45)),
              width: lightText ? 1.4 : 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth > 450 ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (lightText ? primary : Colors.white)
                  : (lightText ? Colors.white : primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(double screenWidth) {
    if (_bookSuggestions.isEmpty) return const SizedBox.shrink();
    final primary = CommanColor.lightDarkPrimary(context);
    final textColor = _searchTextColor(context);
    final lightText = _searchUsesLightText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions',
            style: TextStyle(
              fontSize: screenWidth > 450 ? 20 : 17,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _searchCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _searchCardBorderColor(context, primary)),
            ),
            child: Column(
              children: List.generate(_bookSuggestions.length, (index) {
                final suggestion = _bookSuggestions[index];
                return Column(
                  children: [
                    InkWell(
                      onTap: () => _applySearchQuery(suggestion),
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(16) : Radius.zero,
                        bottom: index == _bookSuggestions.length - 1
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: lightText
                                    ? Colors.white.withOpacity(0.18)
                                    : primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search,
                                size: 18,
                                color: lightText ? Colors.white : primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: screenWidth > 450 ? 16 : 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: _searchMutedTextColor(context, 0.85),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < _bookSuggestions.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: lightText
                            ? Colors.white.withOpacity(0.18)
                            : primary.withOpacity(0.12),
                        indent: 14,
                        endIndent: 14,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection(double screenWidth) {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();
    final primary = CommanColor.lightDarkPrimary(context);
    final textColor = _searchTextColor(context);
    final lightText = _searchUsesLightText(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 22, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: screenWidth > 450 ? 20 : 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                style: TextButton.styleFrom(
                  foregroundColor:
                      lightText ? Colors.white.withOpacity(0.92) : primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: screenWidth > 450 ? 15 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentSearches.map((query) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _searchCardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _searchCardBorderColor(context, primary)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: lightText ? Colors.white : primary,
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _applySearchQuery(query),
                      child: Text(
                        query,
                        style: TextStyle(
                          fontSize: screenWidth > 450 ? 15 : 13,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _removeRecentSearch(query),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _searchMutedTextColor(context, 0.85),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(double screenWidth) {
    final textColor = _searchTextColor(context);
    final primary = CommanColor.lightDarkPrimary(context);
    final lightText = _searchUsesLightText(context);
    final query = searchController.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: lightText
                      ? Colors.white.withOpacity(0.28)
                      : primary.withOpacity(0.25),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '◆',
                  style: TextStyle(
                    color: lightText
                        ? Colors.white.withOpacity(0.75)
                        : primary.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: lightText
                      ? Colors.white.withOpacity(0.28)
                      : primary.withOpacity(0.25),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Image.asset(
            Images.searchPlaceHolder(context),
            height: screenWidth > 450 ? 150 : 120,
            width: screenWidth > 450 ? 150 : 120,
          ),
          const SizedBox(height: 18),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: screenWidth > 450 ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Georgia',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: screenWidth > 450 ? 16 : 14,
                height: 1.45,
                color: _searchMutedTextColor(context, 0.82),
              ),
              children: [
                const TextSpan(text: "We couldn't find anything for "),
                TextSpan(
                  text: "'$query'",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text:
                      '. Try another keyword or explore our suggestions.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBrowseScrollContent(double screenWidth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // When there are no matching results, show the empty state first (primary focus),
          // and keep optional sections below it.
          if (_showExploreTopicsBanner()) ...[
            _buildNoResultsState(screenWidth),
            const SizedBox(height: 12),
            _buildRecentSearchesSection(screenWidth),
            _buildSuggestionsSection(screenWidth),
          ] else ...[
            _buildSuggestionsSection(screenWidth),
            _buildRecentSearchesSection(screenWidth),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
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

      dynamic db;
      for (var attempt = 0; attempt < 5; attempt++) {
        db = await DBHelper().db;
        if (db != null) break;
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
      if (db == null) {
        debugPrint('Search loadLocal: DB null after retries');
        return;
      }

      // Load and parse verses
      final verseRaw = await db.rawQuery("SELECT * FROM verse");
      final parsedVerses = await compute(parseVerses, verseRaw);
      final splitVersesMap = await compute(splitVerses, parsedVerses);

      // Load and parse books
      final bookRaw = await db.rawQuery("SELECT * FROM book");
      final parsedBooks = await compute(parseBooks, bookRaw);
      final splitBooksMap = await compute(splitBooks, parsedBooks);

      if (parsedVerses.isEmpty) {
        debugPrint('Search loadLocal: no verses in database');
        return;
      }

      // Set provider data
      downloadProvider.setData(
        allVerses: parsedVerses,
        otVerses: splitVersesMap['ot']!,
        ntVerses: splitVersesMap['nt']!,
        allBooks: parsedBooks,
        otBooks: splitBooksMap['ot']!,
        ntBooks: splitBooksMap['nt']!,
      );

      if (mounted) {
        setState(() {
          oTBookList =
              oTBookList.isEmpty ? downloadProvider.otBookList : oTBookList;
          nTBookList =
              nTBookList.isEmpty ? downloadProvider.ntBookList : nTBookList;
          allVersesContent = downloadProvider.verseList;
          bookList = bookList.isEmpty ? downloadProvider.bookList : bookList;
          _refreshVerseSuggestions();
        });
      }

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

  String _plainVerseText(dynamic content) {
    final raw = content?.toString() ?? '';
    if (raw.isEmpty) return '';
    return html.parse(raw).body?.text ?? raw;
  }

  String _verseSuggestionSnippet(VerseBookContentModel verse) {
    final plain =
        _plainVerseText(verse.content).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain.isEmpty) return '';

    final words =
        plain.split(' ').where((word) => word.trim().isNotEmpty).toList();
    if (words.isEmpty) return '';

    final wordCount = words.length >= 3 ? 3 : words.length;
    return words.take(wordCount).join(' ');
  }

  bool _verseMatchesQuery(VerseBookContentModel v, dynamic value) {
    final query = (value ?? '').toString().trim().toLowerCase();
    if (query.isEmpty) return false;
    return _plainVerseText(v.content).toLowerCase().contains(query);
  }

  Future<void> _ensureSearchVersesLoaded(DownloadProvider downloadProvider) async {
    if (downloadProvider.verseList.isNotEmpty) return;
    final loaded =
        await downloadProvider.preloadBibleDataFromDatabaseIfNeeded();
    if (!loaded && mounted) {
      await loadLocal();
    }
  }

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
    await _ensureSearchVersesLoaded(downloadProvider);

    // If user typed a book name (Genesis/Exodus/etc), show the full book content
    // (all verses across all chapters) in this same results view.
    final queryText = (value ?? '').toString().trim();
    final booksSource = downloadProvider.bookList.isNotEmpty
        ? downloadProvider.bookList
        : bookList;
    final matchedBook = _findMatchingBook(queryText, booksSource);
    if (matchedBook != null && queryText.length >= 3) {
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

      if (mounted) {
        setState(() {
          filterSelectedVersesContent = bookVerses;
          _isBookNameSearchMode = true;
        });
      }
      return;
    }

    List<VerseBookContentModel> sourceList = [];
    downloadProvider.disableAd();
    if (selectedValueFilter == "ALL" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.verseList
          .where(
            (v) =>
                _verseMatchesQuery(v, value) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else if (selectedValueFilter == "OT" && selectedBook.bookNum == -1) {
      sourceList = downloadProvider.otVerseList
          .where(
            (v) => _verseMatchesQuery(v, value),
          )
          .toList();
    } else if (selectedValueFilter == "OT" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.otVerseList
          .where(
            (v) =>
                _verseMatchesQuery(v, value) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else if (selectedValueFilter == "NT" && selectedBook.bookNum == -1) {
      sourceList = downloadProvider.ntVerseList
          .where(
            (v) => _verseMatchesQuery(v, value),
          )
          .toList();
    } else if (selectedValueFilter == "NT" && selectedBook.bookNum != -1) {
      sourceList = downloadProvider.ntVerseList
          .where(
            (v) =>
                _verseMatchesQuery(v, value) &&
                v.bookNum == selectedBook.bookNum,
          )
          .toList();
    } else {
      sourceList = downloadProvider.verseList
          .where(
            (v) => _verseMatchesQuery(v, value),
          )
          .toList();
    }
    await SharPreferences.setString('OpenAd', '1');
    if (mounted) {
      setState(() {
        filterSelectedVersesContent = sourceList;
        _isBookNameSearchMode = false;
      });
    }
  }

  @override
  void dispose() {
    if (_showSearchGuideSubtext) {
      _markSearchGuideSubtextSeen();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final lightText = _searchUsesLightText(context);
    final primaryText = _searchTextColor(context);
    final mutedText = _searchMutedTextColor(context);
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () async {
                            Provider.of<DownloadProvider>(context, listen: false)
                                .enableAd();
                            await SharPreferences.setString('OpenAd', '1');
                            Get.back();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: screenWidth > 450 ? 30 : 20,
                              color: primaryText,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Search",
                        style: screenWidth > 450
                            ? CommanStyle.appBarStyle(context).copyWith(
                                fontSize: 32,
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w700,
                                color: primaryText)
                            : CommanStyle.appBarStyle(context).copyWith(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w700,
                                color: primaryText),
                      ),

                    ],
                  ),
                  if (_showSearchGuideSubtext) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: lightText
                                  ? Colors.white.withOpacity(0.35)
                                  : CommanColor.lightDarkPrimary(context)
                                      .withOpacity(0.35),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '◆',
                              style: TextStyle(
                                color: lightText
                                    ? Colors.white.withOpacity(0.75)
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.7),
                                fontSize: screenWidth > 450 ? 14 : 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: lightText
                                  ? Colors.white.withOpacity(0.35)
                                  : CommanColor.lightDarkPrimary(context)
                                      .withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Search for prayers, topics, verses or guidance to grow your faith.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth > 450 ? 16 : 14,
                          height: 1.4,
                          color: mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      height: screenWidth > 450 ? 56 : 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4EB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CommanColor.lightDarkPrimary(context)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                                    style: CommanStyle.black16500.copyWith(
                                      fontSize: screenWidth > 450
                                          ? BibleInfo.fontSizeScale * 20
                                          : BibleInfo.fontSizeScale * 16,
                                      color: Colors.black87,
                                    ),
                              controller: searchController,
                              cursorColor:
                                  CommanColor.lightDarkPrimary(context),
                              onFieldSubmitted: (_) => _performSearch(),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.fromLTRB(
                                  screenWidth > 450 ? 16 : 14,
                                  screenWidth > 450 ? 14 : 12,
                                  8,
                                  screenWidth > 450 ? 14 : 12,
                                ),
                                hintText:
                                    'Type a verse, topic, or prayer...',
                                hintStyle: CommanStyle.grey13400,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _performSearch,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(14),
                            ),
                            child: Container(
                              width: screenWidth > 450 ? 56 : 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: CommanColor.lightDarkPrimary(context),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(14),
                                ),
                              ),
                              child: Icon(
                                Icons.search,
                                color: Colors.white,
                                size: screenWidth > 450 ? 26 : 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFilterChip(
                              index: 0,
                              label: 'All',
                              screenWidth: screenWidth,
                            ),
                            _buildFilterChip(
                              index: 1,
                              label: 'OT',
                              screenWidth: screenWidth,
                            ),
                            _buildFilterChip(
                              index: 2,
                              label: 'NT',
                              screenWidth: screenWidth,
                            ),
                            if (!_isBookNameSearchMode) ...[
                              Container(
                                width: 1,
                                height: 28,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                color: lightText
                                    ? Colors.white.withOpacity(0.28)
                                    : CommanColor.lightDarkPrimary(context)
                                        .withOpacity(0.25),
                              ),
                              SizedBox(
                                width: screenWidth > 450 ? 140 : 110,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton2<MainBookListModel>(
                                    isExpanded: true,
                                    items: selectedValueFilterIndex == 0
                                        ? [
                                            DropdownMenuItem<
                                                MainBookListModel>(
                                              value: _allChapterItem,
                                              child: Text(
                                                _allChapterItem.title ??
                                                    'All Chapter',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize:
                                                      screenWidth > 450
                                                          ? 14
                                                          : 12,
                                                  color: primaryText,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            ...bookList
                                                .where((b) => b.bookNum != -1)
                                                .map(
                                                  (item) => DropdownMenuItem<
                                                      MainBookListModel>(
                                                    value: item,
                                                    child: Text(
                                                      item.title.toString(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth > 450
                                                                ? 14
                                                                : 12,
                                                        color: primaryText,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ]
                                        : selectedValueFilterIndex == 1
                                            ? oTBookList
                                                .map(
                                                  (item) => DropdownMenuItem<
                                                      MainBookListModel>(
                                                    value: item,
                                                    child: Text(
                                                      item.title.toString(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth > 450
                                                                ? 14
                                                                : 12,
                                                        color: primaryText,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList()
                                            : nTBookList
                                                .map(
                                                  (item) => DropdownMenuItem<
                                                      MainBookListModel>(
                                                    value: item,
                                                    child: Text(
                                                      item.title.toString(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth > 450
                                                                ? 14
                                                                : 12,
                                                        color: primaryText,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                    value: _resolveDropdownValue(),
                                    hint: Text(
                                      'All Chapters',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: screenWidth > 450 ? 14 : 12,
                                        color: primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onChanged: (newValue) async {
                                      final currentFocus =
                                          FocusScope.of(context);
                                      await SharPreferences.setString(
                                          'OpenAd', '1');
                                      if (!currentFocus.hasPrimaryFocus) {
                                        currentFocus.unfocus();
                                      }
                                      setState(() {
                                        selectedBook = newValue!;
                                        filterSelectedVersesContent.clear();
                                      });
                                      _searchFilter(searchController.text);
                                    },
                                    iconStyleData: IconStyleData(
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_sharp,
                                      ),
                                      iconSize: screenWidth > 450 ? 22 : 18,
                                      iconEnabledColor: primaryText,
                                    ),
                                    buttonStyleData: ButtonStyleData(
                                      height: screenWidth > 450 ? 40 : 34,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      overlayColor: WidgetStateProperty.all(
                                          Colors.transparent),
                                    ),
                                    menuItemStyleData:
                                        const MenuItemStyleData(height: 36),
                                    dropdownStyleData: DropdownStyleData(
                                      maxHeight: 220,
                                      width: screenWidth > 450 ? 220 : 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color:
                                            CommanColor.whiteAndDark(context),
                                        border: Border.all(
                                          color: CommanColor
                                              .lightDarkPrimary(context)
                                              .withOpacity(0.35),
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: screenWidth > 450 ? 14 : 12,
                                      color: primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filterSelectedVersesContent.isNotEmpty
                        ? ListView.builder(
                                itemCount: filterSelectedVersesContent.length,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                physics: const BouncingScrollPhysics(),
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
                                                        await _openVerseInReader(
                                                          bookName:
                                                              bookName.toString(),
                                                          bookNum: int.parse(data
                                                              .bookNum
                                                              .toString()),
                                                          chapter: int.parse(data
                                                                  .chapterNum
                                                                  .toString()) +
                                                              1,
                                                          verseIndex: int.parse(
                                                              data.verseNum
                                                                  .toString()),
                                                          verseText: parse(data
                                                                      .content)
                                                                  .body
                                                                  ?.text
                                                                  .toString() ??
                                                              '',
                                                        );
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
                                                        Navigator.of(context)
                                                            .pop();
                                                        Get.to(
                                                          () => ChatScreen(
                                                            verseContext: {
                                                              'verseText': parse(
                                                                          data.content)
                                                                      .body
                                                                      ?.text
                                                                      .toString() ??
                                                                  '',
                                                              'book': bookName
                                                                  .toString(),
                                                              'chapter':
                                                                  '${int.parse(data.chapterNum.toString()) + 1}',
                                                              'verse':
                                                                  '${int.parse(data.verseNum.toString()) + 1}',
                                                            },
                                                          ),
                                                          transition: Transition
                                                              .cupertinoDialog,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                        );
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            height: 40,
                                                            width: 40,
                                                            decoration:
                                                                BoxDecoration(
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
                                                            child: Image.asset(
                                                              'assets/Chat icon.png',
                                                              height: 22,
                                                              width: 22,
                                                              fit: BoxFit.contain,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 15),
                                                          Text("Ask",
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
                                                                  await _openVerseInReader(
                                                                    bookName:
                                                                        bookName
                                                                            .toString(),
                                                                    bookNum: int
                                                                        .parse(data
                                                                            .bookNum
                                                                            .toString()),
                                                                    chapter: int.parse(data
                                                                            .chapterNum
                                                                            .toString()) +
                                                                        1,
                                                                    verseIndex:
                                                                        int.parse(data
                                                                            .verseNum
                                                                            .toString()),
                                                                    verseText: parse(data
                                                                                .content)
                                                                            .body
                                                                            ?.text
                                                                            .toString() ??
                                                                        '',
                                                                  );
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
                                                                    () =>
                                                                        ChatScreen(
                                                                      verseContext: {
                                                                        'verseText':
                                                                            parse(data.content).body?.text.toString() ??
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
                                                                        milliseconds:
                                                                            300),
                                                                  );
                                                                },
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              8),
                                                                      height:
                                                                          40,
                                                                      width: 40,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border: Border.all(
                                                                            color:
                                                                                CommanColor.lightDarkPrimary(context),
                                                                            width: 1.2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                      ),
                                                                      child: Image.asset(
                                                                        'assets/Chat icon.png',
                                                                        height: 22,
                                                                        width: 22,
                                                                        fit: BoxFit.contain,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            15),
                                                                    Text("Ask",
                                                                        style: CommanStyle.bothPrimary14500(
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
                              )
                        : isLoading
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Text(
                                    'Fetching data... Please wait',
                                    style: CommanStyle.black16500.copyWith(
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: _buildSearchBrowseScrollContent(
                                        screenWidth),
                                  ),
                                  _buildExploreTopicsBanner(screenWidth),
                                ],
                              ),
                  ),
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
