import 'dart:async';
import 'dart:convert';
import 'package:biblebookapp/Model/dailyVerseList.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/Model/product_details_model.dart';
import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/utils/custom_alert.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/widget/home_content_edit_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadProvider with ChangeNotifier {
  DownloadProvider() {
    _loadShownStatus();
    _loadData();
    DashBoardController().loadApi();
    debugPrint(" Api is called now ");
  }

  //! eshop

  static const _downloadsKey = 'downloaded_books';
  static const _planKey = 'subscription_plan';
  static const _usedFreeDownloadKey = 'used_free_download1';
  static const _usedLimitKey = 'used_download_count';

  String? _plan;
  int _usedLimit = 0;
  bool isbookLoading = false;
  String? get plan => _plan;
  int get usedLimit => _usedLimit;
  bool get isPlanActive => _isActive(_plan);

  static final _usedLimitController = StreamController<int>.broadcast();

//  static Stream<int> getUsedLimitStream() => _usedLimitController.stream;
  Stream<bool> isPlanActiveStream() async* {
    final plan = await getSubscriptionPlan();
    yield ['platinum', 'gold', 'silver'].contains(plan?.toLowerCase());
  }

  // Future<void> updateUsedLimit(int value) async {
  //   _usedLimitController.add(value);
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt(_usedLimitKey, value);
  // }

  Future<void> markFreeDownloadUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_usedFreeDownloadKey, true);
    notifyListeners();
  }

  checkbookloading() {
    notifyListeners();
    return isbookLoading;
  }

  setkbookloading(loading) {
    isbookLoading = loading;
    notifyListeners();
  }
  // static Future<void> loadUsedLimitFromPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _usedLimitController.add(prefs.getInt("usedLimit") ?? 0);
  // }

  Future<String?> getSubscriptionPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_planKey);
  }

  // Check if user has used free download
  Future<bool> hasUsedFreeDownload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_usedFreeDownloadKey) ?? false;
  }

  // // Check if user has used free download
  // Future<bool> usedFreeDownload() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.setBool(_usedFreeDownloadKey, false);
  // }

  static Stream<int> getUsedLimitStream() async* {
    // First yield the saved value from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    yield prefs.getInt(_usedLimitKey) ?? 0;

    // Then yield updates from the controller
    yield* _usedLimitController.stream;
  }

  getusedlimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usedLimitKey) ?? 0;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _plan = prefs.getString(_planKey);
    _usedLimit = prefs.getInt(_usedLimitKey) ?? 0;
    _usedLimitController.add(_usedLimit);
    notifyListeners();
  }

  // Set subscription plan
  Future<void> setSubscriptionPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan);
    _plan = plan;
    notifyListeners();
  }

  // // Set used limit directly
  // Future<void> setUsedLimit(int count) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt(_usedLimitKey, count);
  //   _usedLimit = count;
  //   notifyListeners();
  // }

  // Increment used limit
  Future<void> incrementUsedLimit() async {
    // _usedLimit++;

    // final usedFree = await hasUsedFreeDownload();
    // if (!usedFree) {
    //   await markFreeDownloadUsed();
    // }
    final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt(_usedLimitKey, _usedLimit);
    int current = prefs.getInt(_usedLimitKey) ?? 0;
    await prefs.setInt(_usedLimitKey, current + 1);
    _usedLimit = prefs.getInt(_usedLimitKey) ?? 0;
    _usedLimitController.add(_usedLimit);
    notifyListeners();
  }

  //   static Future<void> incrementUsedLimit() async {
//     final prefs = await SharedPreferences.getInstance();
//     int current = prefs.getInt(_usedLimitKey) ?? 0;
//     await prefs.setInt(_usedLimitKey, current + 1);
//   }

  // Reset used limit
  Future<void> resetUsedLimit() async {
    _usedLimit = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usedLimitKey, 0);
    await prefs.setString(_planKey, '');
    notifyListeners();
  }

  // Check if a user can download more books
  Future<bool> canDownloadMore() async {
    final prefs = await SharedPreferences.getInstance();
    // final usedFree = await hasUsedFreeDownload();
    final downloads = await getDownloadedBooks();
    final plan = await getSubscriptionPlan();
    int current = prefs.getInt(_usedLimitKey) ?? 0;
    debugPrint("check download $plan ${downloads.length}  $current");
    // Allow 1st download if free not used
    // if (usedFree == false) {
    //   return true;
    // } else
    if (plan != null && plan.isNotEmpty) {
      if (_plan == 'platinum') {
        return true;
      } else if (_plan == 'gold') {
        return current < 12;
      } else if (_plan == 'silver') {
        return current < 4;
      } else {
        return false;
      }
    }
    return false;
  }

  // Downloaded books storage

  Map<String, dynamic> createBook(String name, String imageUrl) {
    return {
      "name": name,
      "imageUrl": imageUrl,
    };
  }

  Future<List<String>> getDownloadedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_downloadsKey) ?? [];
  }

  Future<void> setDownloadedBooks(List<String> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_downloadsKey, books);
    notifyListeners();
  }

  //   /// Get downloaded books as a list of maps
  // Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final bookStrings = prefs.getStringList(_downloadsKey) ?? [];
  //   return bookStrings
  //       .map((str) => jsonDecode(str) as Map<String, dynamic>)
  //       .toList();
  // }

  // /// Save list of downloaded books
  // Future<void> setDownloadedBooks(List<Map<String, dynamic>> books) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final bookStrings = books.map((book) => jsonEncode(book)).toList();
  //   await prefs.setStringList(_downloadsKey, bookStrings);
  //   notifyListeners();
  // }

  // /// Add a single book (name + image)
  // Future<void> addDownloadedBook(String name, String imageUrl) async {
  //   final books = await getDownloadedBooks();
  //   books.add(createBook(name, imageUrl));
  //   await setDownloadedBooks(books);
  // }

  Future<bool> trackDownload(String bookId) async {
    final current = await getDownloadedBooks();
    if (current.contains(bookId)) return false;
//     if (current.contains(bookId)) return false;

    // // If first-time free, mark it
    // final usedFree = await hasUsedFreeDownload();
    // if (usedFree == false && current.isEmpty) {
    //   return true;
    // }
    final isfree = await hasUsedFreeDownload();

    if (isfree == true) {
      return true;
    }

//     // current.add(bookId);
//     // debugPrint("list of book d - $current");
//     // await setDownloadedBooks(current);
//     // await prefs.setStringList(_downloadsKey, current);
    // current.add(bookId);
    // await setDownloadedBooks(current);
    // await incrementUsedLimit();

    return true;
  }

  static bool _isActive(String? plan) {
    if (plan == null) return false;
    return ['platinum', 'gold', 'silver'].contains(plan.toLowerCase());
  }

// end eshop

  static const String _key = 'appCount';
  int _appCount = 100;
  // final int _appCountper = 0;

  int get appCount => _appCount;

  bool _adEnabled = false;
  int _adCount = 0;

  int get adCount => _adCount;

  InterstitialAd? _interstitialAd;

  bool get adEnabled => _adEnabled;

// count for one time
  int _bookmarkCount = 0;
  bool _hasShown = false;

  bool get hasShown => _hasShown;

  // ad
  static const _pdkey = 'product_details_list';

  // Save list of ProductDetails
  Future<void> saveProductList(List<ProductDetails> products) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
        products.map((product) => jsonEncode(product.toJson())).toList();
    await prefs.setStringList(_pdkey, jsonList);
  }

  bool isLoading = false;

  Future<void> saveInBackground({
    required List<String> selectedCategories,
  }) async {
    isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dataIsChanged', true);
    debugPrint("dailyVersesnew is start");
    final dbClient = await DBHelper().db;
    if (dbClient == null) return;

    // 1. Save categories
    // final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'selected_categories', selectedCategories.toSet().toList());

    // 2. Load all data
    final rawData =
        await dbClient.rawQuery("SELECT * FROM dailyVersesMainList");

    // 3. Filter data in background isolate
    final categories = selectedCategories.toSet().toList();
    final filteredData = await compute(_filterVerses, {
      'data': rawData,
      'selectedCategories': categories,
    });

    final existingRows =
        await dbClient.rawQuery("SELECT * FROM dailyVersesnew");

    if (existingRows.isNotEmpty) {
      // Keep previously received verses; drop only deselected topics.
      if (categories.isEmpty) {
        await dbClient.execute("DELETE FROM dailyVersesnew");
      } else {
        final placeholders = List.filled(categories.length, '?').join(',');
        await dbClient.rawDelete(
          'DELETE FROM dailyVersesnew WHERE Category_Name NOT IN ($placeholders)',
          categories,
        );
      }

      final survivingRows =
          await dbClient.rawQuery("SELECT * FROM dailyVersesnew");
      final survivingCategories = survivingRows
          .map<String>((r) => r['Category_Name']?.toString() ?? '')
          .where((String name) => name.isNotEmpty)
          .toSet();
      final addedCategories = categories
          .where((String c) => !survivingCategories.contains(c))
          .toList();
      final missingFromRotation = _categoriesMissingFromPastSchedule(
        survivingRows,
        categories,
      );

      if (addedCategories.isNotEmpty || missingFromRotation) {
        await _rebalanceFutureDailyVerseSchedule(
          dbClient: dbClient,
          filteredData: filteredData,
          categories: categories,
          survivingRows: survivingRows,
        );
      }
    } else {
      // First-time setup: build the full schedule from scratch.
      await dbClient.execute("DELETE FROM dailyVersesnew");
      final interleaved =
          _interleaveDailyVersesByCategory(filteredData, categories);
      await _insertDailyVersesFromMainList(
        dbClient: dbClient,
        data: interleaved,
        startDate: DateTime.now(),
      );
    }

    debugPrint("dailyVersesnew is sucess");
    isLoading = false;
    notifyListeners();
    await loadDailyVerses();
  }

  Future<void> _insertDailyVersesFromMainList({
    required dynamic dbClient,
    required List<Map<String, dynamic>> data,
    required DateTime startDate,
  }) async {
    DateTime currentDate = startDate;
    // for (final data in filteredData) {
    //   final bookId = int.parse(data["Book_Id"].toString());
    //   final chapter = int.parse(data["Chapter"].toString());
    //   final verse = int.parse(
    //     data["Verse"].toString().contains("-")
    //         ? data["Verse"].toString().split("-").first
    //         : data["Verse"].toString(),
    //   );

    //   final verseResult = await dbClient.rawQuery(
    //     "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
    //     [bookId, chapter, verse],
    //   );

    //   if (verseResult.isNotEmpty) {
    //     final insertData = {
    //       "Category_Name": data["Category_Name"],
    //       "Category_Id": data["Category_Id"],
    //       "Book": data["Book"],
    //       "Book_Id": bookId,
    //       "Chapter": chapter,
    //       "Verse": verseResult[0]["content"],
    //       "Date": "$currentDate",
    //       "Verse_Num": verse,
    //     };

    //     await dbClient.transaction((txn) async {
    //       final batch = txn.batch();
    //       batch.insert('dailyVersesnew', insertData);
    //       await batch.commit(noResult: true);
    //     });

    //     currentDate = currentDate.add(const Duration(days: 1));
    //   }
    // }
    for (final row in data) {
      final bookId = int.tryParse(row["Book_Id"].toString());

      final chapterStr = row["Chapter"]?.toString().trim();
      final verseStr = row["Verse"]?.toString().trim();

      // ✅ Skip if Chapter or Verse is null/empty
      if (chapterStr == null ||
          chapterStr.isEmpty ||
          verseStr == null ||
          verseStr.isEmpty) {
        continue;
      }

      final chapter = int.tryParse(chapterStr);
      final verse = int.tryParse(
        verseStr.contains("-") ? verseStr.split("-").first : verseStr,
      );

      // ✅ Skip if parsing failed
      if (bookId == null || chapter == null || verse == null) {
        continue;
      }

      final lookup = _verseTableIndicesFromMainListRow(
        bookId: bookId,
        chapter: chapter,
        verseRaw: verseStr,
      );

      final verseResult = await dbClient.rawQuery(
        "SELECT * FROM verse WHERE book_num = ? AND chapter_num = ? AND verse_num = ?",
        [lookup.$1, lookup.$2, lookup.$3],
      );

      if (verseResult.isNotEmpty) {
        final insertData = {
          "Category_Name": row["Category_Name"],
          "Category_Id": row["Category_Id"],
          "Book": row["Book"],
          "Book_Id": bookId,
          "Chapter": chapter,
          "Verse": verseResult[0]["content"],
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

  String _dailyVerseScheduleKeyFromMain(Map<String, dynamic> row) {
    final verseRaw = row['Verse']?.toString() ?? '';
    final verseNum =
        verseRaw.contains('-') ? verseRaw.split('-').first : verseRaw;
    return '${row['Category_Name']}|${row['Book_Id']}|${row['Chapter']}|$verseNum';
  }

  String _dailyVerseScheduleKeyFromInserted(Map<String, dynamic> row) {
    return '${row['Category_Name']}|${row['Book_Id']}|${row['Chapter']}|${row['Verse_Num']}';
  }

  DateTime _dailyVerseDateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _categoriesMissingFromPastSchedule(
    List<Map<String, dynamic>> rows,
    List<String> categories,
  ) {
    final today = _dailyVerseDateOnly(DateTime.now());
    final represented = <String>{};
    for (final row in rows) {
      try {
        final day = _dailyVerseDateOnly(DateTime.parse(row['Date'].toString()));
        if (!day.isAfter(today)) {
          final cat = row['Category_Name']?.toString() ?? '';
          if (cat.isNotEmpty) represented.add(cat);
        }
      } catch (_) {}
    }
    return categories.any((c) => !represented.contains(c));
  }

  /// Rebuilds today-and-future rows so every selected topic (including newly added)
  /// shares the same round-robin rotation from today onward.
  Future<void> _rebalanceFutureDailyVerseSchedule({
    required dynamic dbClient,
    required List<Map<String, dynamic>> filteredData,
    required List<String> categories,
    required List<Map<String, dynamic>> survivingRows,
  }) async {
    final today = _dailyVerseDateOnly(DateTime.now());
    final idsToDelete = <int>[];
    final pastKeys = <String>{};

    for (final row in survivingRows) {
      try {
        final day = _dailyVerseDateOnly(DateTime.parse(row['Date'].toString()));
        if (day.isBefore(today)) {
          pastKeys.add(_dailyVerseScheduleKeyFromInserted(row));
        } else {
          final id = row['id'];
          if (id is int) idsToDelete.add(id);
        }
      } catch (_) {}
    }

    if (idsToDelete.isNotEmpty) {
      final placeholders = List.filled(idsToDelete.length, '?').join(',');
      await dbClient.rawDelete(
        'DELETE FROM dailyVersesnew WHERE id IN ($placeholders)',
        idsToDelete,
      );
    }

    final interleaved =
        _interleaveDailyVersesByCategory(filteredData, categories);
    final toSchedule = interleaved
        .where((row) => !pastKeys.contains(_dailyVerseScheduleKeyFromMain(row)))
        .toList();

    await _insertDailyVersesFromMainList(
      dbClient: dbClient,
      data: toSchedule,
      startDate: today,
    );
  }

// download limit
  int clickCount = 0;
  bool isAdReady = false;

  bool _isopenAdEnabled = true;

  bool get isopenAdEnabled => _isopenAdEnabled;

  void enableAd() {
    _isopenAdEnabled = true;
    notifyListeners();
  }

  void disableAd() {
    _isopenAdEnabled = false;
    Future.delayed(Duration.zero, () {
      notifyListeners(); // ✅ Safe
    });
  }

  void toggleAd() {
    _isopenAdEnabled = !_isopenAdEnabled;
    notifyListeners();
  }

  // Future<void> requestConsentInfo() async {
  //   final params = ConsentRequestParameters();
  //   final consentInfo = ConsentInformation.instance;

  //   consentInfo.requestConsentInfoUpdate(
  //     params,
  //     () async {
  //       // Consent info updated successfully.
  //       await loadAndShowConsentFormIfRequired();
  //     },
  //     (FormError error) {
  //       // Handle the error.
  //       debugPrint('Consent info update failed: ${error.message}');
  //     },
  //   );
  // }

  // Future<void> loadAndShowConsentFormIfRequired() async {
  //   await ConsentForm.loadAndShowConsentFormIfRequired(
  //     (FormError? formError) {
  //       if (formError != null) {
  //         // Handle the error.
  //         debugPrint('Consent form load/show failed: ${formError.message}');
  //       } else {
  //         // Consent form was shown successfully.
  //         debugPrint('Consent form displayed.');
  //       }
  //     },
  //   );
  // }

  void _loadShownStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShown = prefs.getBool('hasShownAlert') ?? false;
    notifyListeners();
  }

  Future<void> _trackVerseActionClickForFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(SharPreferences.mainFeedbackFromVerseActions) ?? false) {
      return;
    }

    final total =
        (prefs.getInt(SharPreferences.totalVerseActionClickCount) ?? 0) + 1;
    await prefs.setInt(SharPreferences.totalVerseActionClickCount, total);

    if (total >= 20) {
      await prefs.setBool(SharPreferences.mainFeedbackPending, true);
      await prefs.setBool(SharPreferences.mainFeedbackFromVerseActions, true);
    }
  }

  void incrementBookmarkCount(BuildContext context) async {
    CacheNotifier cacheNotifier = CacheNotifier();
    final data = await cacheNotifier.readCache(key: 'user');

    if (data == null) {
      await _trackVerseActionClickForFeedback();
    }

    if (_hasShown) return;

    if (data == null) {
      _bookmarkCount++;

      if (_bookmarkCount >= BibleInfo.appcount) {
        _bookmarkCount = 0;
        if (context.mounted) {
          // Show Alert
          showDialog(
            context: context,
            builder: (_) => const BibleAlertBox(),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasShownAlert', true);
          _hasShown = true;
          notifyListeners();
        }
      }
    }
  }

  // Future<void> checkConsentAndLoadAds() async {
  //   final consentInfo = ConsentInformation.instance;
  //   final canRequestAds = await consentInfo.canRequestAds();

  //   if (canRequestAds) {
  //     // Load and display ads.
  //   } else {
  //     // Do not load ads.
  //     print('Cannot request ads without user consent.');
  //   }
  // }

  Future handleDownloadClick(BuildContext context) async {
    // final data = await SharPreferences.getString(SharPreferences.offerenabled);
    final adEnable =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    final checkDownload = await SharPreferences.getBoolean("downloadreward");
    final adEnable2 = await SharPreferences.shouldLoadAd();
    final subEnable = await SharPreferences.getBoolean('isSubscriptionEnabled');

    debugPrint(
        "offer enabled 0 or - ad $adEnable - $adEnable2 & sub $subEnable  ");

    final clickcountcachefn =
        await SharPreferences.getInt('downloadrewardcount');

    // Initialize downloadreward to true if it's null (first time)
    if (checkDownload == null) {
      await SharPreferences.setBoolean("downloadreward", true);
    }

    // Initialize downloadrewardcount to 0 if it's null (first time)
    if (clickcountcachefn == null) {
      clickCount = 0;
      await SharPreferences.setInt("downloadrewardcount", clickCount);
    } else {
      clickCount = clickcountcachefn;
    }

    if (subEnable!) {
      if (adEnable2) {
        clickCount++;
        await SharPreferences.setInt("downloadrewardcount", clickCount);

        final clickcountcache =
            await SharPreferences.getInt('downloadrewardcount');
        debugPrint(
            "offer enabled 1 or - ad $adEnable - $adEnable2 & sub $subEnable  click count - $clickcountcache");
        // Show premium popup after 3 downloads (when count reaches 4, i.e., on 4th download attempt)
        if (clickcountcache == 4) {
          await setDownloadReward();
          // showLimitDialog(context);
          return true;
        } else if (checkDownload == false) {
          // If count is already 4 or more, show popup even if reward not watched
          if (clickCount >= 4) {
            await setDownloadReward();
            return true;
          }
          // Otherwise set to 3 to prepare for next download
          clickCount = 3;
          await SharPreferences.setInt("downloadrewardcount", clickCount);
          return false;
        }
      } else {
        clickCount = 3;
        await SharPreferences.setBoolean("downloadreward", true);
        await SharPreferences.setInt("downloadrewardcount", clickCount);
        return false;
      }
    } else {
      clickCount = 3;
      await SharPreferences.setBoolean("downloadreward", true);
      await SharPreferences.setInt("downloadrewardcount", clickCount);
      return false;
    }

    notifyListeners();
    return false;
  }

  Future<void> setDownloadReward() async {
    await SharPreferences.setBoolean("downloadreward", false);
    clickCount = 0;
    await SharPreferences.setInt("downloadrewardcount", clickCount);
    notifyListeners();
  }

  // Load list of ProductDetails
  Future<List<ProductDetails>> loadProductList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_pdkey);
    if (jsonList == null) return [];

    return jsonList
        .map((jsonStr) => ProductDetails.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>))
        .toList();
  }

  // Optional: clear stored products
  Future<void> clearProductList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pdkey);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _adEnabled = await shouldLoadAd();
    _adCount = int.tryParse(prefs.getString('showinterstitialo') ?? '0') ?? 0;
    notifyListeners();
  }

  Future<bool> shouldLoadAd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ad_enabled') ?? true;
  }

  Future<void> checkAndShowAd(BuildContext context, adEnabledfn) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsadcount =
        await SharPreferences.getString(SharPreferences.showinterstitialrow) ??
            "0";

    final data = prefs.getString('showinterstitialo') ?? '0';

    _adCount = int.tryParse(data ?? '0') ?? 0;

    _adEnabled = await shouldLoadAd();
    final adcount = int.tryParse(prefsadcount) ?? 0;
    debugPrint(" ad check $_adCount  & $adcount  ");
    if (_adCount % adcount == 0) {
      EasyLoading.showInfo('Please wait...');
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        _loadAndShowInterstitialAd(context);
      }
      EasyLoading.dismiss();
      // Reset counter after showing ad
      _adCount = 0;
    }
    notifyListeners();
  }

  Future<void> updateAdCount(int newCount) async {
    final prefs = await SharedPreferences.getInstance();
    _adCount = newCount;
    await prefs.setString('showinterstitialo', _adCount.toString());
  }

  void _loadAndShowInterstitialAd(BuildContext context) async {
    // final trackingAllowed = await isTrackingAllowed();
    // debugPrint('ad pop InterstitialAd -  ${!trackingAllowed}');
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.googleInterstitialAd);
    InterstitialAd.load(
      adUnitId: adUnitId.toString() ?? '',
      request: await AdConsentManager.getAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) async {
          _interstitialAd = ad;
          _interstitialAd?.show();
          DebugConsole.log(" interstitialAd is running ");
          await SharPreferences.setString('OpenAd', '1');
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async {
              await SharPreferences.setString('OpenAd', '1');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// download

  Future<void> _loadAppCount() async {
    final data = await SharPreferences.getInt(SharPreferences.offercount);
    //  await SharPreferences.setInt("offercountper", data ?? 0);
    //final data2 = await SharPreferences.getInt("offercountper");
    final prefs = await SharedPreferences.getInstance();
    //await prefs.setInt(_key, data ?? 10);
    _appCount = prefs.getInt(_key) ?? data ?? 10;
    debugPrint(" offer count is api $_appCount  $data");
    notifyListeners();
  }

  Future<void> _saveAppCount() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint(" offer count is $_appCount ");
    await prefs.setInt(_key, _appCount);
  }

  Future decrementCount(BuildContext context) async {
    await _loadAppCount();
    if (_appCount > 0) {
      _appCount--;
      _saveAppCount();
      notifyListeners();
      final data =
          await SharPreferences.getString(SharPreferences.offerenabled) ?? '';

      final premium = await SharPreferences.getString("premium") ?? 'no';
      final adenable =
          await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi) ??
              true;
      final subenable =
          await SharPreferences.getBoolean('isSubscriptionEnabled') ?? true;
      // await Future.delayed(Duration(seconds: 1));
      debugPrint("offer enabled or - $_appCount $data $adenable $subenable");
      if (subenable) {
        debugPrint("sub enabled or - $subenable");
        if (data == '1') {
          if (adenable) {
            if (_appCount == 0) {
              if (context.mounted && premium == 'no') {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PremiumAccessDialog(),
                );
              }
            }
          } else {
            resetCount();
          }
        } else {
          resetCount();
        }
      } else {
        resetCount();
      }
    } else {
      resetCount();
    }
  }

  Future<void> resetCount() async {
    final data = await SharPreferences.getInt(SharPreferences.offercount) ?? 20;
    _appCount = data;
    await _saveAppCount();
    notifyListeners();
  }

// daily verse
  bool isLoadingDailyVerse = false;
  List<DailyVerseList> dailyVerseList = [];

  Future<void> loadDailyVerses() async {
    final prefs = await SharedPreferences.getInstance();

    final bool dataIsChanged = prefs.getBool('dataIsChanged') ?? true;
    final String? cachedJson = prefs.getString('cachedDailyVerseList_v2');

    // Already in memory from splash/home/preference preload.
    if (!dataIsChanged && dailyVerseList.isNotEmpty) {
      isLoadingDailyVerse = false;
      notifyListeners();
      return;
    }

    // Instant path: prefs JSON cache (no DB round-trip before first paint).
    if (!dataIsChanged &&
        cachedJson != null &&
        cachedJson.isNotEmpty &&
        await _hydrateDailyVersesFromPrefsJson(cachedJson)) {
      isLoadingDailyVerse = false;
      notifyListeners();
      return;
    }

    isLoadingDailyVerse = true;
    notifyListeners();

    if (!dataIsChanged && cachedJson != null) {
      final selectedForCache =
          prefs.getStringList('selected_categories') ?? [];
      final List<dynamic> decodedCache = jsonDecode(cachedJson);
      final staleEmptyCache =
          selectedForCache.isNotEmpty && decodedCache.isEmpty;

      if (!staleEmptyCache) {
      if (selectedForCache.isNotEmpty) {
        final dbClient = await DBHelper().db;
        if (dbClient != null) {
          final rows = await dbClient.rawQuery(
            "SELECT Category_Name, Date FROM dailyVersesnew",
          );
          if (_categoriesMissingFromPastSchedule(rows, selectedForCache)) {
            await prefs.setBool('dataIsChanged', true);
          } else {
            dailyVerseList = decodedCache
                .map((e) => DailyVerseList.fromJson(e as Map<String, dynamic>))
                .toSet()
                .toList();
            debugPrint("dailyVerseList is ${dailyVerseList.length}");
            isLoadingDailyVerse = false;
            notifyListeners();
            return;
          }
        }
      } else {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        dailyVerseList = decoded
            .map((e) => DailyVerseList.fromJson(e as Map<String, dynamic>))
            .toSet()
            .toList();
        debugPrint("dailyVerseList is ${dailyVerseList.length}");
        isLoadingDailyVerse = false;
        notifyListeners();
        return;
      }
      }
    }

    // Continue loading from DB
    List<String> selectedCategories =
        prefs.getStringList('selected_categories') ?? ['faith-in-hard-times'];

    final dbClient = await DBHelper().db;
    if (dbClient == null) {
      isLoadingDailyVerse = false;
      notifyListeners();
      return;
    }

    final table = selectedCategories.isEmpty ? "dailyVerses" : "dailyVersesnew";
    var dailyVerses = await dbClient.rawQuery("SELECT * FROM $table");

    if (table == 'dailyVersesnew' &&
        selectedCategories.isNotEmpty &&
        _categoriesMissingFromPastSchedule(dailyVerses, selectedCategories)) {
      final rawData =
          await dbClient.rawQuery("SELECT * FROM dailyVersesMainList");
      final filteredData = await compute(_filterVerses, {
        'data': rawData,
        'selectedCategories': selectedCategories,
      });
      await _rebalanceFutureDailyVerseSchedule(
        dbClient: dbClient,
        filteredData: filteredData,
        categories: selectedCategories,
        survivingRows: dailyVerses,
      );
      dailyVerses = await dbClient.rawQuery("SELECT * FROM $table");
    }

    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    final result = await compute(_filterAndSortVerses, {
      'verses': dailyVerses,
      'today': todayString,
    });
    final verseRows =
        result.isNotEmpty ? result : List<Map<String, dynamic>>.from(dailyVerses);

    final List<DailyVerseList> enrichedList = [];

    for (var verse in verseRows) {
      // Keep original book name from server (don't translate to current Bible version)
      final storedBook = verse['Book']?.toString().trim() ?? '';
      final bookName = storedBook.isNotEmpty ? storedBook : 'Unknown';

      enrichedList.add(DailyVerseList(
        categoryName: verse['Category_Name'],
        categoryId: int.parse(verse['Category_Id'].toString()),
        book: bookName,
        bookId: int.parse(verse['Book_Id'].toString()),
        chapter: int.parse(verse['Chapter'].toString()),
        verse: verse['Verse'],
        date: verse['Date'],
        verseNum: int.parse(verse['Verse_Num'].toString()),
      ));
    }

    dailyVerseList = enrichedList;
    debugPrint("dailyVerseList new is ${dailyVerseList.length}");
    // Cache in SharedPreferences
    final String jsonList =
        jsonEncode(dailyVerseList.map((e) => e.toJson()).toSet().toList());
    await prefs.setString('cachedDailyVerseList_v2', jsonList);
    await prefs.setBool('dataIsChanged', false); // Reset the flag

    isLoadingDailyVerse = false;
    notifyListeners();

    // iOS Home Screen Widget: update Verse of the day (same format as Daily Verse screen)
    if (dailyVerseList.isNotEmpty) {
      final v = dailyVerseList.first;
      final ref = '${v.book ?? ''} ${(v.chapter ?? 0) + 1}:${(v.verseNum ?? 0) + 1}'.trim();
      updateVerseOfTheDayWidget(
        verseText: v.verse ?? '',
        reference: ref.isEmpty ? 'Daily Verse' : ref,
      );
    }
  }

  // Future<void> loadDailyVerses() async {
  //   isLoadingDailyVerse = true;
  //   notifyListeners();

  //   final prefs = await SharedPreferences.getInstance();
  //   List<String> selectedCategories =
  //       prefs.getStringList('selected_categories') ?? ['faith-in-hard-times'];

  //   final dbClient = await DBHelper().db;
  //   if (dbClient == null) return;

  //   final table = selectedCategories.isEmpty ? "dailyVerses" : "dailyVersesnew";
  //   final dailyVerses = await dbClient.rawQuery("SELECT * FROM $table");

  //   final today = DateTime.now();
  //   final todayString = DateFormat('yyyy-MM-dd').format(today);

  //   // Compute to process DB results off main thread
  //   final result = await compute(_filterAndSortVerses, {
  //     'verses': dailyVerses,
  //     'today': todayString,
  //   });

  //   // Fetch book names on main thread
  //   final List<DailyVerseList> enrichedList = [];

  //   for (var verse in result) {
  //     final bookData = await dbClient.rawQuery(
  //       "SELECT DISTINCT title FROM book WHERE book_num = ? LIMIT 1",
  //       [verse['Book_Id']],
  //     );
  //     final bookName =
  //         bookData.isNotEmpty ? bookData.first['title'] as String : 'Unknown';

  //     enrichedList.add(DailyVerseList(
  //       categoryName: verse['Category_Name'],
  //       categoryId: int.parse(verse['Category_Id'].toString()),
  //       book: bookName,
  //       bookId: int.parse(verse['Book_Id'].toString()),
  //       chapter: int.parse(verse['Chapter'].toString()),
  //       verse: verse['Verse'],
  //       date: verse['Date'],
  //       verseNum: int.parse(verse['Verse_Num'].toString()),
  //     ));
  //   }

  //   dailyVerseList = enrichedList;
  //   isLoadingDailyVerse = false;
  //   notifyListeners();
  // }

//search
  bool isLoadingsearch = false;

  List<VerseBookContentModel> verseList = [];
  List<VerseBookContentModel> otVerseList = [];
  List<VerseBookContentModel> ntVerseList = [];

  List<MainBookListModel> bookList = [];
  List<MainBookListModel> otBookList = [];
  List<MainBookListModel> ntBookList = [];

  void setIsLoading(bool value) {
    isLoadingsearch = value;
    notifyListeners();
  }

  void setData({
    required List<VerseBookContentModel> allVerses,
    required List<VerseBookContentModel> otVerses,
    required List<VerseBookContentModel> ntVerses,
    required List<MainBookListModel> allBooks,
    required List<MainBookListModel> otBooks,
    required List<MainBookListModel> ntBooks,
  }) {
    verseList = allVerses;
    otVerseList = otVerses;
    ntVerseList = ntVerses;

    bookList = allBooks;
    otBookList = otBooks;
    ntBookList = ntBooks;

    notifyListeners();
  }

  /// Loads verse/book rows from SQLite into memory when cache is empty.
  Future<bool> preloadBibleDataFromDatabaseIfNeeded() async {
    if (verseList.isNotEmpty) return true;
    try {
      dynamic db;
      for (var attempt = 0; attempt < 6; attempt++) {
        db = await DBHelper().db;
        if (db != null) {
          final count =
              await db.rawQuery('SELECT COUNT(*) as c FROM verse LIMIT 1');
          final verseCount = int.tryParse('${count.first['c']}') ?? 0;
          if (verseCount > 0) break;
        }
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
      if (db == null) {
        debugPrint('preloadBibleDataFromDatabaseIfNeeded: DB null');
        return false;
      }

      final verseRaw = await db.rawQuery('SELECT * FROM verse');
      if (verseRaw.isEmpty) {
        debugPrint('preloadBibleDataFromDatabaseIfNeeded: verse table empty');
        return false;
      }

      final parsedVerses = await compute(parseVerses, verseRaw);
      final splitVersesMap = await compute(splitVerses, parsedVerses);
      final bookRaw = await db.rawQuery('SELECT * FROM book');
      final parsedBooks = await compute(parseBooks, bookRaw);
      final splitBooksMap = await compute(splitBooks, parsedBooks);

      setData(
        allVerses: parsedVerses,
        otVerses: splitVersesMap['ot']!,
        ntVerses: splitVersesMap['nt']!,
        allBooks: parsedBooks,
        otBooks: splitBooksMap['ot']!,
        ntBooks: splitBooksMap['nt']!,
      );
      return verseList.isNotEmpty;
    } catch (e) {
      debugPrint('preloadBibleDataFromDatabaseIfNeeded error: $e');
      return false;
    }
  }

  /// Mirrors splash [loadLocal]: memory cache + book list prefs for Home/Search.
  Future<bool> preloadAndCacheBibleDataFromDatabase() async {
    final loaded = await preloadBibleDataFromDatabaseIfNeeded();
    if (!loaded && verseList.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'otBookList',
        jsonEncode(otBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'ntBookList',
        jsonEncode(ntBookList.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'bookList',
        jsonEncode(bookList.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('preloadAndCacheBibleDataFromDatabase prefs error: $e');
    }
    return verseList.isNotEmpty;
  }

  /// Reads [cachedDailyVerseList_v2] prefs only — for instant Daily Verse UI.
  Future<bool> tryHydrateDailyVersesFromLocalCache() async {
    if (dailyVerseList.isNotEmpty) return true;

    final prefs = await SharedPreferences.getInstance();
    final dataIsChanged = prefs.getBool('dataIsChanged') ?? true;
    if (dataIsChanged) return false;

    final cachedJson = prefs.getString('cachedDailyVerseList_v2');
    if (cachedJson == null || cachedJson.isEmpty) return false;

    return _hydrateDailyVersesFromPrefsJson(cachedJson);
  }

  Future<bool> _hydrateDailyVersesFromPrefsJson(String cachedJson) async {
    try {
      final decoded = jsonDecode(cachedJson);
      if (decoded is! List || decoded.isEmpty) return false;

      dailyVerseList = decoded
          .map((e) => DailyVerseList.fromJson(e as Map<String, dynamic>))
          .toSet()
          .toList();
      return dailyVerseList.isNotEmpty;
    } catch (e) {
      debugPrint('hydrateDailyVersesFromPrefsJson error: $e');
      return false;
    }
  }

  /// Warm bible + daily verse caches before opening Home (no UI change).
  Future<void> warmDataBeforeHomeScreen() async {
    await preloadAndCacheBibleDataFromDatabase();
    if (dailyVerseList.isEmpty) {
      await loadDailyVerses();
    }
  }
}

/// One verse per selected topic per day (round-robin), not all from one category.
List<Map<String, dynamic>> _interleaveDailyVersesByCategory(
  List<Map<String, dynamic>> data,
  List<String> categoryOrder,
) {
  final byCategory = <String, List<Map<String, dynamic>>>{};
  for (final row in data) {
    final cat = row['Category_Name']?.toString() ?? '';
    if (cat.isEmpty) continue;
    byCategory.putIfAbsent(cat, () => []).add(row);
  }

  final orderedCats = <String>[];
  for (final cat in categoryOrder) {
    if (byCategory.containsKey(cat)) orderedCats.add(cat);
  }
  for (final cat in byCategory.keys) {
    if (!orderedCats.contains(cat)) orderedCats.add(cat);
  }

  final result = <Map<String, dynamic>>[];
  var round = 0;
  var hasMore = true;
  while (hasMore) {
    hasMore = false;
    for (final cat in orderedCats) {
      final list = byCategory[cat]!;
      if (round < list.length) {
        result.add(list[round]);
        hasMore = true;
      }
    }
    round++;
  }
  return result;
}

/// Maps dailyVersesMainList 1-based ids to 0-based verse table columns
/// (same convention as splash [loadDailyVerseData]).
(int, int, int) _verseTableIndicesFromMainListRow({
  required int bookId,
  required int chapter,
  required String verseRaw,
}) {
  final verseNum = verseRaw.length == 2
      ? int.parse(verseRaw) - 1
      : int.parse(verseRaw.split('-').first) - 1;
  return (bookId - 1, chapter - 1, verseNum);
}

// Background selectedCategories
List<Map<String, dynamic>> _filterVerses(Map<String, dynamic> args) {
  List<Map<String, dynamic>> data =
      List<Map<String, dynamic>>.from(args['data']);
  List<String> selectedCategories =
      List<String>.from(args['selectedCategories']);

  return data
      .where((e) => selectedCategories.contains(e["Category_Name"]))
      .toSet()
      .toList();
}

/// Background dailyverse list
List<Map<String, dynamic>> _filterAndSortVerses(Map<String, dynamic> args) {
  // final verses = List<Map<String, dynamic>>.from(args['verses']);
  // final todayStr = args['today'];

  // final today = DateTime.parse(todayStr);
  // final todayOnly = DateFormat('yyyy-MM-dd').format(today);

  // List<Map<String, dynamic>> filtered = [];

  // for (var i in verses) {
  //   try {
  //     final verseDate = DateTime.parse(i['Date']);
  //     final verseDateOnly = DateFormat('yyyy-MM-dd').format(verseDate);
  //     if (verseDateOnly.compareTo(todayOnly) > 0) continue;

  //     filtered.add(i);
  //   } catch (e) {
  //     continue;
  //   }
  // }

  // filtered.sort((a, b) {
  //   final dateA = DateTime.parse(a['Date']);
  //   final dateB = DateTime.parse(b['Date']);

  //   final isTodayA = DateFormat('yyyy-MM-dd').format(dateA) == todayOnly;
  //   final isTodayB = DateFormat('yyyy-MM-dd').format(dateB) == todayOnly;

  //   if (isTodayA && !isTodayB) return -1;
  //   if (!isTodayA && isTodayB) return 1;

  //   return dateB.compareTo(dateA);
  // });

  // return filtered;

  final verses = List<Map<String, dynamic>>.from(args['verses']);

  List<Map<String, dynamic>> filtered = [];

  for (var i in verses) {
    try {
      DateTime.parse(i['Date']); // Ensure valid date
      filtered.add(i);
    } catch (e) {
      continue;
    }
  }

  filtered.sort((a, b) {
    final dateA = DateTime.parse(a['Date']);
    final dateB = DateTime.parse(b['Date']);
    return dateB.compareTo(dateA); // Sort descending
  });

  return filtered;
}

//search background
// `compute` requires the callback to accept `dynamic` (not a typed list).
// These helpers are used from multiple screens to parse DB rows in an isolate.
List<VerseBookContentModel> parseVerses(dynamic data) {
  if (data == null) return <VerseBookContentModel>[];
  final list = (data as List).toList();
  return list.map((e) => VerseBookContentModel.fromJson(e)).toList();
}

Map<String, List<VerseBookContentModel>> splitVerses(
    List<VerseBookContentModel> all) {
  List<VerseBookContentModel> ot = [];
  List<VerseBookContentModel> nt = [];
  final otCount = BibleInfo.old_testament_count;

  for (var v in all) {
    if ((v.bookNum ?? 0) < otCount) {
      ot.add(v);
    } else {
      nt.add(v);
    }
  }

  return {'ot': ot, 'nt': nt};
}

List<MainBookListModel> parseBooks(dynamic data) {
  if (data == null) return <MainBookListModel>[];
  final list = (data as List).toList();
  return list.map((e) => MainBookListModel.fromJson(e)).toList();
}

Map<String, List<MainBookListModel>> splitBooks(List<MainBookListModel> books) {
  final otCount = BibleInfo.old_testament_count;
  List<MainBookListModel> ot = [];
  List<MainBookListModel> nt = [];

  for (final book in books) {
    if ((book.bookNum ?? 0) < otCount) {
      ot.add(book);
    } else {
      nt.add(book);
    }
  }

  return {'ot': ot, 'nt': nt};
}

String? _resolveDailyVerseBookTitle(
    Map<int, String> bookTitleByNum, int bookKey) {
  final direct = bookTitleByNum[bookKey];
  if (direct != null && direct.isNotEmpty) return direct;
  if (bookKey > 0) {
    final legacy = bookTitleByNum[bookKey - 1];
    if (legacy != null && legacy.isNotEmpty) return legacy;
  }
  final next = bookTitleByNum[bookKey + 1];
  if (next != null && next.isNotEmpty) return next;
  return null;
}
