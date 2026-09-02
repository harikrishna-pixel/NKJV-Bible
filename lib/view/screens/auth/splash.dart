import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/view/screens/onboard_faith_screen.dart';
import 'package:biblebookapp/view/screens/welcome_screen.dart';
import 'package:biblebookapp/view/screens/notification_info_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:biblebookapp/view/widget/bible_upgrade_alert.dart';
import 'package:upgrader/upgrader.dart';

import 'package:biblebookapp/Model/bookMarkModel.dart';
import 'package:biblebookapp/Model/highLightContentModal.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/Model/saveNotesModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/extract_zip_json.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/initialization_helper.dart';
import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/widget/notification_service.dart';

import '../../../Model/dailyVersesMainListModel.dart';
import '../../../Model/verseBookContentModel.dart';
import '../../../controller/dpProvider.dart';
import '../../constants/share_preferences.dart';
import 'package:biblebookapp/streak_flow/streak_flow_screens.dart' hide SharPreferences;
import '../dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/bible_select_screen.dart';

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  late String selecteDailyVerses;
  int appLaunchCount = 0;
  int appLaunchCountoffer = 0;
  AppOpenAd? _appOpenAd;

  double _progress = 0;
  final bool _isLoading = true;
  String _loaderMessage = "Loading God's Word...";
  late final AnimationController _splashProgressController;
  bool _initComplete = false;
  bool _hasNavigated = false;
  /// Additive: force-leave if init hangs after an update (does not alter init steps).
  Timer? _splashSafetyTimer;
  static const Duration _splashSafetyTimeout = Duration(seconds: 60);
  static const Duration _splashHeavyStepTimeout = Duration(seconds: 30);

  // Platform messages are asynchronous, so we initialize in an async method.

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  get developer => null;

  @override
  void initState() {
    super.initState();
    _splashProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    final splashProgressAnim = CurvedAnimation(
      parent: _splashProgressController,
      curve: Curves.easeOutCubic,
    );
    splashProgressAnim.addListener(() {
      if (!mounted) return;
      setState(() {
        _progress = splashProgressAnim.value;
      });
    });
    _splashProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryLeaveSplash();
      }
    });
    _splashProgressController.forward();
    _initialize();
  }

  Future<void> _leaveSplash() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    // UI: hold at 98% → open ad on splash → then 100% → Home.
    setState(() {
      _progress = 0.98;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _maybeShowColdStartOpenAdOnSplash();
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await handleNavigation();
  }

  /// Same destination check as [handleNavigation] Home path — no ad on Welcome/restore.
  Future<bool> _willNavigateToHomeAfterSplash() async {
    final isOnboardingCompleted =
        await SharPreferences.getBoolean(SharPreferences.onboarding);
    if (isOnboardingCompleted == null || !isOnboardingCompleted) return false;
    try {
      final counts = await _readCoreBibleCountsWithRetry();
      if (counts == null) return false;
      if (counts.verseCount == 0 || counts.bookCount == 0) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markSplashOpenAdFlowComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('showopenad', 'false');
    await prefs.setBool(SharPreferences.openAdFlowComplete, true);
  }

  /// Mirrors Home [UpgradeCheckWrapper] open-ad rules; blocks navigation until dismiss/fail.
  Future<void> _maybeShowColdStartOpenAdOnSplash() async {
    if (!await _willNavigateToHomeAfterSplash()) return;

    final upgrader = Upgrader(
      debugLogging: true,
      durationUntilAlertAgain: const Duration(days: 1),
    );
    final updateAvailable = upgrader.isUpdateAvailable();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('showopenad');
    final pendingStreakRating = await SharPreferences.getInt(
            SharPreferences.pendingStreakCompleteCelebration) ??
        0;

    if (pendingStreakRating >= 1) {
      await prefs.setString('showopenad', 'false');
      await SharPreferences.setString('OpenAd', '1');
      await _markSplashOpenAdFlowComplete();
      return;
    }

    if (updateAvailable || data != 'true') {
      await _markSplashOpenAdFlowComplete();
      return;
    }

    await _loadAndAwaitSplashOpenAd();
    await _markSplashOpenAdFlowComplete();
  }

  Future<void> _loadAndAwaitSplashOpenAd() async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    bool? isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    if (!(isAdEnabledFromApi ?? true)) {
      finish();
      return;
    }

    final testFlag = await SharPreferences.getString('test');
    if (testFlag == null) {
      await SharPreferences.setString('test', 'test');
      finish();
      return;
    }

    var adsEnabled =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabled) ?? true;
    final rewardTime =
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime);
    if (rewardTime != null) {
      final diff =
          DateTime.now().difference(DateTime.parse(rewardTime)).inDays;
      if (!diff.isNegative) {
        await SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
        adsEnabled =
            await SharPreferences.getBoolean(SharPreferences.isAdsEnabled) ??
                true;
      } else {
        await SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
        adsEnabled = false;
      }
    }

    if (!adsEnabled) {
      finish();
      return;
    }

    final openAdUnitId =
        await SharPreferences.getString(SharPreferences.openAppId);
    AppOpenAd.load(
      adUnitId: openAdUnitId ?? '',
      request: await AdConsentManager.getAdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              finish();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _appOpenAd = null;
              finish();
            },
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) {
              finish();
              return;
            }
            try {
              ad.show();
            } catch (_) {
              finish();
            }
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Splash AppOpenAd failed to load: $error');
          SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
          finish();
        },
      ),
    );

    try {
      await completer.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      debugPrint('Splash open ad timed out — continuing navigation');
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }
  }

  void _tryLeaveSplash() {
    if (_hasNavigated || !_initComplete || !mounted) return;
    if (!_splashProgressController.isCompleted) return;
    _leaveSplash();
  }

  Future<void> _markInitCompleteAndTryLeave() async {
    _initComplete = true;
    _tryLeaveSplash();
  }

  @override
  void dispose() {
    _splashSafetyTimer?.cancel();
    _splashProgressController.dispose();
    super.dispose();
  }

  void _schedulePostSplashAtt() {
    // Wait for splash navigation + home to mount before ATT pre-dialog.
    Future.delayed(const Duration(seconds: 3), () {
      AdConsentManager.showAttFlowIfNeeded();
    });
  }

  loadOpenAd() async {
    final trackingAllowed = await isTrackingAllowed();
    debugPrint('ad pop loadOpenAd -  ${!trackingAllowed}');
    bool? isAdEnabledFromApi =
    await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    if (isAdEnabledFromApi ?? true) {
      String? openAdUnitId =
      await SharPreferences.getString(SharPreferences.openAppId);
      AppOpenAd.load(
        adUnitId: openAdUnitId ?? '',
        request: await AdConsentManager.getAdRequest(),
        //orientation: 1,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;

            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _appOpenAd = null;
              },
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              final adToShow = _appOpenAd;
              if (adToShow == null) return;
              adToShow.show();
            });
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: $error');
            SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
          },
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> initAppOpen() async {
    await SharPreferences.getString('test').then((value) async {
      if (value != null) {
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime)
            .then((re) async {
          if (re != null) {
            DateTime CurrentDateTime = DateTime.now();
            DateTime SaveTime = DateTime.parse(re.toString());
            var diff = CurrentDateTime.difference(SaveTime).inDays;
            log('Diff: $diff');
            if (!diff.isNegative) {
              SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
              // bool dta = Provider.of<DownloadProvider>(context, listen: false)
              //     .isopenAdEnabled;
              // final checkad = await SharPreferences.getString('OpenAd') ?? "1";
              // final data2 = await SharPreferences.getString('bottom') ?? '0';

              final data = await SharPreferences.getBoolean(
                  SharPreferences.isAdsEnabled) ??
                  true;
              // debugPrint("Open ad tigger and $checkad and && $dta");
              if (data) {
                loadOpenAd();
              }
              setState(() {});
            } else {
              SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
            }
          } else {
            // bool dta = Provider.of<DownloadProvider>(context, listen: false)
            //     .isopenAdEnabled;
            // final checkad = await SharPreferences.getString('OpenAd') ?? "1";
            // final data2 = await SharPreferences.getString('bottom') ?? '0';

            final data = await SharPreferences.getBoolean(
                SharPreferences.isAdsEnabled) ??
                true;
            // debugPrint("Open ad tigger and $checkad and && $dta");
            if (data) {
              loadOpenAd();
            }
            setState(() {});
          }
        });
      } else {
        await SharPreferences.setString('test', 'test');
      }
    });
  }

  int saveDay = 320;

  Future<void> _initialize() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final password = dotenv.env[AssetsConstants.dbPasswordKey]!;
      // Additive safety net only: same init sequence, but never hang forever.
      _splashSafetyTimer?.cancel();
      _splashSafetyTimer = Timer(_splashSafetyTimeout, () {
        if (_initComplete || _hasNavigated || !mounted) return;
        debugPrint(
            'SPLASH safety timeout (${_splashSafetyTimeout.inSeconds}s) — leaving');
        _markInitCompleteAndTryLeave();
      });
      try {
        // Only do essential initialization that's required before navigation
        // APIs are already loading in background via BackgroundApiService

        // Drop any stale DB handle (hot restart / odd overwrite cases); always
        // align with current file on disk before migration + seed.
        await DBHelper.resetStaticDatabaseConnection();

        // Essential: Database migration
        print('SPLASH before migrateToEncryptedDatabase');
        // Also log to system console (visible in Mac Console.app)
        debugPrint('SPLASH before migrateToEncryptedDatabase');
        try {
          await Future.wait<void>([
            DBMigrationHelper.migrateToEncryptedDatabase(password),
            WalletService.initializeWallet(),
          ]).timeout(_splashHeavyStepTimeout);
          // Additive: restore wallet from profile when session already exists.
          unawaited(syncReferralFieldsFromAuthHubProfile());
        } on TimeoutException {
          debugPrint('SPLASH migration/wallet timed out — continuing');
        }
        print('SPLASH after migrateToEncryptedDatabase');
        debugPrint('SPLASH after migrateToEncryptedDatabase');

        if (kDebugMode) {
          await DBHelper.debugPrintDatabaseFiles();
        }

        // Essential: Reset purchase flags
        await SharPreferences.setBoolean('restorepurches', false);
        await SharPreferences.setBoolean('startpurches', false);

        // Preload Paywall Screen data in background (non-blocking)
        PaywallPreloadService.preloadPaywallData();

        // Essential: Check app count (launch counters / open-ad flag only).
        await checkappcount();

        // Essential: Load local data (books, verses from DB)
        await Future.wait<void>([
          loadBookList(),
          loadBookContent(),
        ]);
        // Prefs can survive reinstall/restore while DB is empty → clear "loaded"
        // flags and JSON caches so daily verse + home never trust stale state.
        await reconcilePersistedBibleStateWithDatabase();
        await loadDailyVerseData();
        // Load Verse for You only after daily-verse tables are seeded (first install).
        if (mounted) {
          await Provider.of<DownloadProvider>(context, listen: false)
              .loadDailyVerses();
        }
        try {
          await loadLocal().timeout(_splashHeavyStepTimeout);
        } on TimeoutException {
          debugPrint('SPLASH loadLocal timed out — continuing');
        }

        // Essential: Set default book if not set + preserve legacy user data
        await Future.wait<void>([
          DBHelper().db.then((db) async {
            if (db != null) {
              final result = await db.rawQuery(
                "SELECT * FROM book WHERE book_num = ?",
                [int.parse("0")],
              );

              if (result.isNotEmpty && result[0]["title"] != null) {
                final title = result[0]["title"].toString();
                final data = await SharPreferences.getString(
                  SharPreferences.selectedBook,
                ) ??
                    "";
                if (data.isEmpty) {
                  await SharPreferences.setString(
                    SharPreferences.selectedBook,
                    title,
                  );
                }
              } else {
                debugPrint("testapp No book found with book_num = 0");
              }
            } else {
              debugPrint("testapp Database instance is null");
            }
          }),
          DBMigrationHelper.copyUserDataFromLegacyIfNeeded(password),
        ]);

        // Essential: Update local DB (sync verse flags with bookmarks/highlights)
        try {
          await Future.wait<void>([
            updateLocalDB(),
            deleteFiles(),
          ]).timeout(_splashHeavyStepTimeout);
        } on TimeoutException {
          debugPrint('SPLASH updateLocalDB/deleteFiles timed out — continuing');
        }
        print('SPLASH after copyUserDataFromLegacyIfNeeded');
        if (kDebugMode) {
          await DBHelper.debugPrintLibraryTableCounts();
        }
        print('SPLASH before navigation');

        await _markInitCompleteAndTryLeave();
      } catch (e) {
        print('SPLASH init error - $e');
        // Even if there's an error, try to navigate
        await _markInitCompleteAndTryLeave();
      } finally {
        _splashSafetyTimer?.cancel();
        _splashSafetyTimer = null;
      }
    });
  }

  /// When the DB has no verse/book rows but SharedPreferences still claim
  /// content was loaded (reinstall with iCloud prefs, `adb install -r`, etc.),
  /// clear cached JSON + flags so [loadDailyVerseData] and Home never trust
  /// stale "loaded" state over an empty database.
  Future<void> reconcilePersistedBibleStateWithDatabase() async {
    try {
      final db = await DBHelper().db;
      if (db == null) return;

      final verseCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) AS c FROM verse'),
      ) ??
          0;
      final bookCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) AS c FROM book'),
      ) ??
          0;

      if (verseCount > 0 && bookCount > 0) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bookList');
      await prefs.remove('otBookList');
      await prefs.remove('ntBookList');
      await SharPreferences.setBoolean(SharPreferences.isLoadBookContent, false);
      await SharPreferences.setBoolean(SharPreferences.isLoadBookList, false);

      if (!mounted) return;
      Provider.of<DownloadProvider>(context, listen: false).setData(
        allVerses: <VerseBookContentModel>[],
        otVerses: <VerseBookContentModel>[],
        ntVerses: <VerseBookContentModel>[],
        allBooks: <MainBookListModel>[],
        otBooks: <MainBookListModel>[],
        ntBooks: <MainBookListModel>[],
      );

      debugPrint(
          'reconcilePersistedBibleStateWithDatabase: cleared stale prefs (verse=$verseCount book=$bookCount)');
    } catch (e) {
      debugPrint('reconcilePersistedBibleStateWithDatabase error: $e');
    }
  }

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
      await SharPreferences.setBoolean('restorepurches', false);
      await SharPreferences.setBoolean('startpurches', false);
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

  // @override
  // void initState() {
  //   super.initState();
  //   _initialize();
  //   // Request app tracking permission after splash screen is visible for 1-2 seconds
  //   _requestTrackingPermission();
  // }

  Future<void> _requestTrackingPermission() async {
    // Wait a few seconds after splash screen appears before showing ATT
    await Future.delayed(const Duration(seconds: 4));

    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('App Tracking Permission Status: $status');
      } on PlatformException catch (e) {
        debugPrint('App Tracking Permission Error: ${e.message}');
      }
    }
  }

  void _updateProgress(double progress, String message) {
    setState(() {
      _progress = progress;
      _loaderMessage = "Please wait...";
    });
  }

  checkappcount() async {
    // Daily verses load after loadDailyVerseData() on splash — not here —
    // so first install does not cache an empty Verse for You list.

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      appLaunchCount = prefs.getInt('launchCount') ?? 0;
      appLaunchCountoffer = prefs.getInt('launchCountoffer') ?? 0;

      appLaunchCount++;
      appLaunchCountoffer++;
      await prefs.setString("showopenad", "true");
      await prefs.setInt('launchCount', appLaunchCount);
      await prefs.setInt('launchCountoffer', appLaunchCountoffer);
    } catch (e) {
      debugPrint("launchCount error - $e");
    }
  }

  /// Additive: decide Welcome Old→New logos vs single new logo.
  /// New install → false. In-place upgrade from older build → true.
  /// Does not change navigation or onboarding completion.
  Future<void> _updateWelcomeLogoComparisonFlag() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version.trim();
      final last =
      (await SharPreferences.getString(SharPreferences.lastKnownAppVersion))
          ?.trim();

      var showComparison = false;
      if (last != null && last.isNotEmpty) {
        showComparison = _isAppVersionOlder(last, current);
      } else {
        // First time we track version: treat as upgrader if this install
        // already had prior use (update from a build before this flag existed).
        final prefs = await SharedPreferences.getInstance();
        final launchCount = prefs.getInt('launchCount') ?? 0;
        final selectedBook =
        await SharPreferences.getString(SharPreferences.selectedBook);
        final loadedList = await SharPreferences.getBoolean(
            SharPreferences.isLoadBookList) ??
            false;
        showComparison = launchCount > 1 ||
            (selectedBook != null && selectedBook.isNotEmpty) ||
            loadedList;
      }

      await SharPreferences.setBoolean(
          SharPreferences.showWelcomeLogoComparison, showComparison);
      if (current.isNotEmpty) {
        await SharPreferences.setString(
            SharPreferences.lastKnownAppVersion, current);
      }
      debugPrint(
        'Welcome logo comparison=$showComparison '
            '(last=$last current=$current)',
      );
    } catch (e) {
      debugPrint('_updateWelcomeLogoComparisonFlag error: $e');
      // Safe default for Welcome: new-user single logo.
      await SharPreferences.setBoolean(
          SharPreferences.showWelcomeLogoComparison, false);
    }
  }

  /// Returns true when [a] is strictly older than [b] (e.g. 1.0.101 < 1.0.115).
  bool _isAppVersionOlder(String a, String b) {
    List<int> parts(String v) => v
        .split(RegExp(r'[^0-9]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai < bi) return true;
      if (ai > bi) return false;
    }
    return false;
  }

  Future<({int verseCount, int bookCount})?> _readCoreBibleCountsWithRetry() async {
    Future<({int verseCount, int bookCount})?> readCounts() async {
      final db = await DBHelper().db;
      if (db == null) return null;
      final verseCountRows = await db.rawQuery("SELECT COUNT(*) as c FROM verse");
      final bookCountRows = await db.rawQuery("SELECT COUNT(*) as c FROM book");
      final verseCount =
          verseCountRows.isNotEmpty ? (verseCountRows.first["c"] as int?) ?? 0 : 0;
      final bookCount =
          bookCountRows.isNotEmpty ? (bookCountRows.first["c"] as int?) ?? 0 : 0;
      return (verseCount: verseCount, bookCount: bookCount);
    }

    try {
      return await readCounts();
    } catch (e) {
      final err = e.toString().toLowerCase();
      final isClosed = e is DatabaseException && err.contains('database_closed');
      if (!isClosed) rethrow;

      debugPrint('Core bible count read hit closed DB, retrying once...');
      await DBHelper.resetStaticDatabaseConnection();
      return readCounts();
    }
  }

  handleNavigation() async {
    await NotificationsServices.storeLaunchPayloadIfFromNotification();
    await _updateWelcomeLogoComparisonFlag();

    final isOnboardingCompleted =
    await SharPreferences.getBoolean(SharPreferences.onboarding);

    // First launch: show welcome -> onboarding questions
    if (isOnboardingCompleted == null || !isOnboardingCompleted) {
      _schedulePostSplashAtt();
      Get.offAll(() => const WelcomeScreen());
      return;
    }

    // Hard safety: if core bible data missing, route user to restore/select Bible.
    // If DB cannot be opened, do NOT fall through to Home (infinite loader / empty content).
    try {
      final counts = await _readCoreBibleCountsWithRetry();
      if (counts == null) {
        debugPrint('testapp Core bible check: DB null → Bible restore flow');
        if (BibleInfo.folders.length <= 1) {
          _schedulePostSplashAtt();
          Get.offAll(() => PreferenceSelectionScreen(
            isSetting: false,
            selectedbible: BibleInfo.folders.isNotEmpty
                ? BibleInfo.folders.first
                : '',
          ));
        } else {
          _schedulePostSplashAtt();
          Get.offAll(() => const BibleVersionsScreen(from: 'onboard'));
        }
        return;
      }
      final verseCount = counts.verseCount;
      final bookCount = counts.bookCount;
      if (verseCount == 0 || bookCount == 0) {
        if (BibleInfo.folders.length <= 1) {
          _schedulePostSplashAtt();
          Get.offAll(() => PreferenceSelectionScreen(
            isSetting: false,
            selectedbible: BibleInfo.folders.isNotEmpty
                ? BibleInfo.folders.first
                : '',
          ));
        } else {
          _schedulePostSplashAtt();
          Get.offAll(() => const BibleVersionsScreen(from: 'onboard'));
        }
        return;
      }
    } catch (e) {
      debugPrint('testapp Core bible data check failed: $e → Bible restore flow');
      try {
        if (BibleInfo.folders.length <= 1) {
          _schedulePostSplashAtt();
          Get.offAll(() => PreferenceSelectionScreen(
            isSetting: false,
            selectedbible: BibleInfo.folders.isNotEmpty
                ? BibleInfo.folders.first
                : '',
          ));
        } else {
          _schedulePostSplashAtt();
          Get.offAll(() => const BibleVersionsScreen(from: 'onboard'));
        }
      } catch (_) {}
      return;
    }

    _schedulePostSplashAtt();
    await SharPreferences.setBoolean(SharPreferences.isLoadBookContent, true);
    // UI-only: finish warm before route swap so splash→Home does not flash empty.
    try {
      final provider =
          Provider.of<DownloadProvider>(context, listen: false);
      await provider.warmDataBeforeHomeScreen().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint(
              'warmDataBeforeHomeScreen timed out — continuing to Home');
        },
      );
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    if (!mounted) return;
    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }

  loadBookContent() async {
    final db = await DBHelper().db;
    if (db == null) {
      debugPrint("testapp: Database is null.");
      return;
    }

    final result = await db.rawQuery("SELECT COUNT(*) as count FROM verse");
    final count = Sqflite.firstIntValue(result) ?? 0;

    if (count == 0) {
      try {
        // Use same password as Bible version flow (Geneva Bible zips use HOLY_BIBLE_ZIP).
        final String response = await ExtractZipJson.extractFile(
          AssetsConstants.verseJSONPath,
          AssetsConstants.holybibleKey,
        );

        final tempList = await compute(_parseVerseContent, response);
        versesContent = tempList;

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

        await SharPreferences.setBoolean(SharPreferences.isLoadBookContent, true);
      } catch (e, st) {
        debugPrint("testapp: Error loading verse content → $e\n$st");
      }
    }
  }

  Future<void> deleteFiles() async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Safety for upgrade users: only delete legacy DBs when current DB has
      // both core data (verse/book) AND library data (bookmark/highlight), so we
      // never delete the only copy of My Library data.
      bool canDeleteLegacyDbs = false;
      try {
        final db = await DBHelper().db;
        if (db != null) {
          final verseCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM verse");
          final bookCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM book");
          final bookmarkCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM bookmark");
          final highlightCountRows =
          await db.rawQuery("SELECT COUNT(*) as c FROM highlight");
          final verseCount =
              (verseCountRows.isNotEmpty ? (verseCountRows.first["c"] as int?) : 0) ?? 0;
          final bookCount =
              (bookCountRows.isNotEmpty ? (bookCountRows.first["c"] as int?) : 0) ?? 0;
          final bookmarkCount =
              (bookmarkCountRows.isNotEmpty ? (bookmarkCountRows.first["c"] as int?) : 0) ?? 0;
          final highlightCount =
              (highlightCountRows.isNotEmpty ? (highlightCountRows.first["c"] as int?) : 0) ?? 0;
          final hasLibraryData = bookmarkCount > 0 || highlightCount > 0;
          canDeleteLegacyDbs = verseCount > 0 && bookCount > 0 && hasLibraryData;
          print(
              'SPLASH deleteFiles check verseCount=$verseCount bookCount=$bookCount bookmarkCount=$bookmarkCount highlightCount=$highlightCount hasLibraryData=$hasLibraryData canDeleteLegacyDbs=$canDeleteLegacyDbs');
          if (verseCount > 0 && bookCount > 0 && !hasLibraryData) {
            print(
                'testapp Keeping legacy DBs (current DB has no library data yet).');
          }
        }
      } catch (e) {
        print('SPLASH deleteFiles error verifying encrypted DB data: $e');
        canDeleteLegacyDbs = false;
      }

      // Define file paths
      final file1 = File('${directory.path}/book.json');
      final file2 = File('${directory.path}/verse_json.json');

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

      try {
        if (!canDeleteLegacyDbs) {
          print(
              'testapp Skipping legacy DB deletion (target DB missing core data).');
          return;
        }

        final dir = await getApplicationDocumentsDirectory();
        final oldDbFile = File(p.join(dir.path, 'bible.db'));
        if (await oldDbFile.exists()) {
          await oldDbFile.delete();
          debugPrint('Deleted old unencrypted DB: bible.db');
        }

        final dotDbFile = File(p.join(dir.path, '.bible.db'));
        if (await dotDbFile.exists()) {
          await dotDbFile.delete();
          debugPrint('Deleted old encrypted DB: .bible.db');
        }
        final dotDbFile2 = File(p.join(dir.path, 'bible2.db'));
        if (await dotDbFile2.exists()) {
          await dotDbFile2.delete();
          debugPrint('Deleted old encrypted DB: bible2.db');
        }
      } catch (e) {
        debugPrint('Error deleting old DB files: $e');
      }
    } catch (e) {
      debugPrint('Error deleting files: $e');
    }
  }

  loadBookList() async {
    final db = await DBHelper().db;
    if (db == null) {
      debugPrint("testapp: Database is null.");
      return;
    }

    final result = await db.rawQuery("SELECT COUNT(*) as count FROM book");
    final count = Sqflite.firstIntValue(result) ?? 0;

    if (count == 0) {
      try {
        // Use same password as Bible version flow (Geneva Bible zips use HOLY_BIBLE_ZIP).
        final String response = await ExtractZipJson.extractFile(
          AssetsConstants.booksJSONPath,
          AssetsConstants.holybibleKey,
        );

        final tempBookList = await compute(_parseAndPrepareBooks, response);
        bookList = tempBookList;

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

        await SharPreferences.setBoolean(SharPreferences.isLoadBookList, true);
      } catch (e, st) {
        debugPrint("testapp: Error loading book list: $e\n$st");
      }
    } else {
      // Book table is not empty, just log one item
      final bookRows = await db.rawQuery("SELECT * FROM book LIMIT 1");
      if (bookRows.isEmpty) {
        debugPrint("testapp: Book table has count but no rows returned.");
      }
    }
  }

  // loadDailyVerseData() async {
  //   await DBHelper().db.then((db) async {
  //     final dailyVersesMainList =
  //         await db!.rawQuery("SELECT * From dailyVersesMainList");

  //     if (dailyVersesMainList.isEmpty) {
  //       final String dailyVerseResponse =
  //           await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
  //       final dailyVerseData = await json.decode(dailyVerseResponse);

  //       setState(() {
  //         dailyVerseDataList = List.from(dailyVerseData)
  //             .map<DailyVersesMainListModel>(
  //                 (item) => DailyVersesMainListModel.fromJson(item))
  //             .toList();

  //         DBHelper().db.then((value) {
  //           value!.transaction((txn) async {
  //             var batch = txn.batch();
  //             for (int i = 0; i < dailyVerseDataList.length; i++) {
  //               var insertData = {
  //                 "Category_Name": dailyVerseDataList[i].mainCategory,
  //                 "Category_Id": dailyVerseDataList[i].categoryId,
  //                 "Book": dailyVerseDataList[i].book,
  //                 "Book_Id": dailyVerseDataList[i].bookId,
  //                 "Chapter": dailyVerseDataList[i].chapter,
  //                 "Verse": dailyVerseDataList[i].verse,
  //               };
  //               batch.insert('dailyVersesMainList', insertData);
  //             }
  //             List<Object?> isUpload = await batch.commit();
  //             if (isUpload.isEmpty) {
  //             } else {
  //               debugPrint("testapp 1e");
  //             }
  //           });
  //         }).whenComplete(() {
  //           Future.delayed(
  //             Duration(milliseconds: 500),
  //             () {
  //               DBHelper().db.then((dailyVersesMainList) {
  //                 dailyVersesMainList!
  //                     .rawQuery("SELECT * From dailyVersesMainList")
  //                     .then((dailyVersesMainData) async {
  //                   for (var i = 0; i < 20; i++) {
  //                     var selectedVersesMainData = DailyVersesMainListModel(
  //                       verse: dailyVersesMainData[i]["Verse"]
  //                                   .toString()
  //                                   .length ==
  //                               2
  //                           ? int.parse(dailyVersesMainData[i]["Verse"]
  //                                   .toString()) -
  //                               1
  //                           : int.parse(dailyVersesMainData[i]["Verse"]
  //                                   .toString()
  //                                   .split("-")
  //                                   .first) -
  //                               1,
  //                       book: "${dailyVersesMainData[i]["Book"]}",
  //                       bookId: int.parse(
  //                               dailyVersesMainData[i]["Book_Id"].toString()) -
  //                           1,
  //                       categoryId: int.parse(
  //                           dailyVersesMainData[i]["Category_Id"].toString()),
  //                       categoryName:
  //                           "${dailyVersesMainData[i]["Category_Name"]}",
  //                       chapter: int.parse(
  //                               dailyVersesMainData[i]["Chapter"].toString()) -
  //                           1,
  //                     );

  //                     dailyVersesMainList
  //                         .rawQuery(
  //                             "SELECT * From verse WHERE book_num ='${int.parse(selectedVersesMainData.bookId.toString())}' AND chapter_num ='${int.parse(selectedVersesMainData.chapter.toString())}' AND verse_num ='${int.parse(selectedVersesMainData.verse.toString())}'")
  //                         .then((selectedDailyVersesResponse) async {
  //                       if (selectedDailyVersesResponse.isNotEmpty) {
  //                         dailyVersesMainList.transaction((txn) async {
  //                           var batch = txn.batch();
  //                           var Date = DateTime.now()
  //                               .subtract(Duration(days: saveDay));
  //                           var insertData = {
  //                             "Category_Name": dailyVersesMainData[i]
  //                                 ["Category_Name"],
  //                             "Category_Id": dailyVersesMainData[i]
  //                                 ["Category_Id"],
  //                             "Book": dailyVersesMainData[i]["Book"],
  //                             "Book_Id": dailyVersesMainData[i]["Book_Id"],
  //                             "Chapter": dailyVersesMainData[i]["Chapter"],
  //                             "Verse": selectedDailyVersesResponse[0]
  //                                 ["content"],
  //                             "Date": "$Date",
  //                             "Verse_Num": dailyVersesMainData[i]["Verse"]
  //                                         .toString()
  //                                         .length ==
  //                                     2
  //                                 ? int.parse(dailyVersesMainData[i]["Verse"]
  //                                     .toString())
  //                                 : int.parse(dailyVersesMainData[i]["Verse"]
  //                                     .toString()
  //                                     .split("-")
  //                                     .first),
  //                           };
  //                           saveDay = saveDay - 1;
  //                           batch.insert('dailyVerses', insertData);
  //                           List<Object?> isUpload = await batch.commit();
  //                           if (isUpload.isEmpty) {
  //                           } else {
  //                             debugPrint("testapp 2e");
  //                           }
  //                         });
  //                       }
  //                     });
  //                   }
  //                 });
  //               }).then((value) {
  //                 SharPreferences.setString(
  //                     SharPreferences.selectedDailyVerse, "11");
  //                 var currentDate = DateTime.now();
  //                 SharPreferences.setString(
  //                     SharPreferences.dailyVerseUpdateTime,
  //                     currentDate.toString());
  //               });
  //             },
  //           );
  //         });
  //       });
  //     } else {
  //       await SharPreferences.getString(SharPreferences.dailyVerseUpdateTime)
  //           .then((saveTime) async {
  //         final saveDateTime = DateTime.parse(saveTime.toString());
  //         final currentDateTime = DateTime.now();
  //         final difference = daysBetween(saveDateTime, currentDateTime);
  //         if (difference >= 1) {
  //           await SharPreferences.getBoolean(SharPreferences.isLoadBookContent)
  //               .then((value) async {
  //             if (value != null || value != false) {
  //               DBHelper().db.then((dailyVersesMainList) {
  //                 dailyVersesMainList!
  //                     .rawQuery("SELECT * From dailyVersesMainList")
  //                     .then((dailyVersesMainData) async {
  //                   selecteDailyVerses = await SharPreferences.getString(
  //                           SharPreferences.selectedDailyVerse) ??
  //                       "11";
  //                   var selectedVersesMainData = DailyVersesMainListModel(
  //                     verse: dailyVersesMainData[int.parse(selecteDailyVerses.toString())]
  //                                     ["Verse"]
  //                                 .toString()
  //                                 .length ==
  //                             2
  //                         ? int.parse(dailyVersesMainData[int.parse(
  //                                     selecteDailyVerses.toString())]["Verse"]
  //                                 .toString()) -
  //                             1
  //                         : int.parse(dailyVersesMainData[
  //                                         int.parse(selecteDailyVerses.toString())]
  //                                     ["Verse"]
  //                                 .toString()
  //                                 .split("-")
  //                                 .first) -
  //                             1,
  //                     book:
  //                         "${dailyVersesMainData[int.parse(selecteDailyVerses.toString())]["Book"]}",
  //                     bookId: int.parse(dailyVersesMainData[
  //                                     int.parse(selecteDailyVerses.toString())]
  //                                 ["Book_Id"]
  //                             .toString()) -
  //                         1,
  //                     categoryId: int.parse(dailyVersesMainData[
  //                                 int.parse(selecteDailyVerses.toString())]
  //                             ["Category_Id"]
  //                         .toString()),
  //                     categoryName:
  //                         "${dailyVersesMainData[int.parse(selecteDailyVerses.toString())]["Category_Name"]}",
  //                     chapter: int.parse(dailyVersesMainData[
  //                                     int.parse(selecteDailyVerses.toString())]
  //                                 ["Chapter"]
  //                             .toString()) -
  //                         1,
  //                   );
  //                   dailyVersesMainList
  //                       .rawQuery(
  //                           "SELECT * From verse WHERE book_num ='${int.parse(selectedVersesMainData.bookId.toString())}' AND chapter_num ='${int.parse(selectedVersesMainData.chapter.toString())}' AND verse_num ='${int.parse(selectedVersesMainData.verse.toString())}'")
  //                       .then((selectedDailyVersesResponse) {
  //                     if (selectedDailyVersesResponse.isNotEmpty) {
  //                       dailyVersesMainList.transaction((txn) async {
  //                         var batch = txn.batch();
  //                         var Date = DateTime.now();
  //                         var insertData = {
  //                           "Category_Name": dailyVersesMainData[
  //                                   int.parse(selecteDailyVerses.toString())]
  //                               ["Category_Name"],
  //                           "Category_Id": dailyVersesMainData[
  //                                   int.parse(selecteDailyVerses.toString())]
  //                               ["Category_Id"],
  //                           "Book": dailyVersesMainData[
  //                                   int.parse(selecteDailyVerses.toString())]
  //                               ["Book"],
  //                           "Book_Id": dailyVersesMainData[
  //                                   int.parse(selecteDailyVerses.toString())]
  //                               ["Book_Id"],
  //                           "Chapter": dailyVersesMainData[
  //                                   int.parse(selecteDailyVerses.toString())]
  //                               ["Chapter"],
  //                           "Verse": selectedDailyVersesResponse[0]["content"],
  //                           "Date": "$Date",
  //                           "Verse_Num": dailyVersesMainData[
  //                                               int.parse(selecteDailyVerses.toString())]
  //                                           ["Verse"]
  //                                       .toString()
  //                                       .length ==
  //                                   2
  //                               ? int.parse(dailyVersesMainData[
  //                                           int.parse(selecteDailyVerses.toString())]
  //                                       ["Verse"]
  //                                   .toString())
  //                               : int.parse(dailyVersesMainData[
  //                                           int.parse(selecteDailyVerses.toString())]
  //                                       ["Verse"]
  //                                   .toString()
  //                                   .split("-")
  //                                   .first),
  //                         };
  //                         batch.insert('dailyVerses', insertData);
  //                         List<Object?> isUpload = await batch.commit();
  //                         if (isUpload.isEmpty) {
  //                         } else {
  //                           debugPrint("testapp 3e");
  //                         }
  //                       });
  //                     }
  //                   });
  //                 });
  //               }).then((value) {
  //                 Future.delayed(
  //                   Duration(seconds: 1),
  //                   () {
  //                     if (kDebugMode) {
  //                       print(selecteDailyVerses.toString());
  //                     }
  //                     SharPreferences.setString(
  //                         SharPreferences.selectedDailyVerse,
  //                         "${int.parse(selecteDailyVerses.toString()) + 1}");
  //                     SharPreferences.setString(
  //                         SharPreferences.dailyVerseUpdateTime,
  //                         currentDateTime.toString());
  //                   },
  //                 );
  //               });
  //             }
  //           });
  //         }
  //       });
  //     }
  //   });
  // }

  Future<void> loadDailyVerseData() async {
    final db = await DBHelper().db;

    final List<Map<String, dynamic>> dailyVersesMainList =
    await db!.rawQuery("SELECT * FROM dailyVersesMainList");

    if (dailyVersesMainList.isEmpty) {
      final String dailyVerseResponse =
      await rootBundle.loadString('assets/jsonFile/dailyVerse.json');
      // Use compute for parsing
      final List<DailyVersesMainListModel> dataList =
      await compute(parseDailyVerseJsond, dailyVerseResponse);

      // Update your state only here
      setState(() {
        dailyVerseDataList = dataList;
      });

      // Insert data into DB using transaction and batch
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final item in dataList) {
          batch.insert('dailyVersesMainList', {
            "Category_Name": item.mainCategory,
            "Category_Id": item.categoryId,
            "Book": item.book,
            "Book_Id": item.bookId,
            "Chapter": item.chapter,
            "Verse": item.verse,
          });
        }
        await batch.commit();
      });

      // Insert daily verses for the first 20 items
      int saveDay = 0; // Make sure to manage this appropriately
      final newMainList =
      await db.rawQuery("SELECT * FROM dailyVersesMainList");
      for (var i = 0; i < 20 && i < newMainList.length; i++) {
        final m = newMainList[i];

        final int verseNum = m["Verse"].toString().length == 2
            ? int.parse(m["Verse"].toString()) - 1
            : int.parse(m["Verse"].toString().split("-").first) - 1;

        final selectedVerse = await db.rawQuery(
          "SELECT * FROM verse WHERE book_num ='${int.parse(m["Book_Id"].toString()) - 1}' AND "
              "chapter_num ='${int.parse(m["Chapter"].toString()) - 1}' "
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
              "Verse": selectedVerse[0]["content"],
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
    } else {
      // Already populated, check if new daily verse needs to be added
      final saveTime =
      await SharPreferences.getString(SharPreferences.dailyVerseUpdateTime);
      final saveDateTime =
      DateTime.parse(saveTime ?? DateTime.now().toString());
      final currentDateTime = DateTime.now();
      final difference = daysBetween(saveDateTime, currentDateTime);

      if (difference >= 1) {
        final isLoadBookContent =
        await SharPreferences.getBoolean(SharPreferences.isLoadBookContent);

        if (isLoadBookContent != null && isLoadBookContent == true) {
          final mainList =
          await db.rawQuery("SELECT * FROM dailyVersesMainList");
          String selecteDailyVerses = await SharPreferences.getString(
              SharPreferences.selectedDailyVerse) ??
              "11";
          int idx = int.parse(selecteDailyVerses);

          final m = mainList[idx];

          final int verseNum = m["Verse"].toString().length == 2
              ? int.parse(m["Verse"].toString()) - 1
              : int.parse(m["Verse"].toString().split("-").first) - 1;

          final selectedVerse = await db.rawQuery(
            "SELECT * FROM verse WHERE book_num ='${int.parse(m["Book_Id"].toString()) - 1}' AND "
                "chapter_num ='${int.parse(m["Chapter"].toString()) - 1}' "
                "AND verse_num ='$verseNum'",
          );

          if (selectedVerse.isNotEmpty) {
            await db.transaction((txn) async {
              final batch = txn.batch();
              final date = DateTime.now();
              batch.insert('dailyVerses', {
                "Category_Name": m["Category_Name"],
                "Category_Id": m["Category_Id"],
                "Book": m["Book"],
                "Book_Id": m["Book_Id"],
                "Chapter": m["Chapter"],
                "Verse": selectedVerse[0]["content"],
                "Date": "$date",
                "Verse_Num": m["Verse"].toString().length == 2
                    ? int.parse(m["Verse"].toString())
                    : int.parse(m["Verse"].toString().split("-").first),
              });
              await batch.commit();
            });
          }

          // Update preference after delay
          Future.delayed(const Duration(seconds: 1), () async {
            if (kDebugMode) print(selecteDailyVerses);
            await SharPreferences.setString(
                SharPreferences.selectedDailyVerse, "${idx + 1}");
            await SharPreferences.setString(
                SharPreferences.dailyVerseUpdateTime,
                currentDateTime.toString());
          });
        }
      }
    }
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  List<MainBookListModel> bookList = [];
  List<DailyVersesMainListModel> dailyVerseDataList = [];
  List<VerseBookContentModel> versesContent = [];

  Future<void> updateLocalDB() async {
    final dbHelper = DBHelper();

    // 1. Load all data from local database
    final List<BookMarkModel> bookmarks = await dbHelper.getBookMark();
    final List<HighLightContentModal> highlights =
    await dbHelper.getHighlight();
    final List<BookMarkModel> underlines = await dbHelper.getUnderLine();
    final List<SaveNotesModel> notesList = await dbHelper.getNotes();
    //final List<ImageModel> imageList = await dbHelper.getSavedImages();
    final List<CalendarModel> calendarList = await dbHelper.getCalendarData();

    // 2. Process Bookmarks
    for (var e in bookmarks) {
      // // await dbHelper.insertBookmark(e);
      // await dbHelper.updateVersesDataByContent(
      //     e.content.toString(), 'is_bookmarked', 'yes');
      // await dbHelper.updateVersesData(
      //     int.parse(e.plaincontent.toString()), 'is_bookmarked', 'yes');
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_bookmarked', 'yes');
    }

    // 3. Process Highlights
    for (var e in highlights) {
      //  await dbHelper.insertIntoHighLight(e);
      await DBHelper().updateVersesDataByContentnewcheck(
          e.content.toString(), 'is_highlighted', '${e.color}');
    }

    // 4. Process Underlines
    for (var e in underlines) {
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_underlined', 'yes');
    }

    // 5. Process Notes
    for (var e in notesList) {
      //  await dbHelper.insertNotes(e);
      await DBHelper().updateVersesDataByContentnew(
          e.content.toString(), 'is_noted', '${e.notes}');
    }

    // 6. Process Saved Images
    // for (var e in imageList) {
    //   await dbHelper.saveImage(e);
    // }

    // 7. Process Calendar
    for (var e in calendarList) {
      await dbHelper.saveCalendarData(e);
    }
    debugPrint("db updated");
  }

  static const Color _splashInk = Color(0xFF4A3728);
  static const Color _splashGold = Color(0xFFC59434);

  Widget _splashOrnamentDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 52),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: _splashGold.withValues(alpha: 0.75),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.diamond_outlined,
              size: 11,
              color: _splashGold.withValues(alpha: 0.9),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _splashGold.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _splashLoadingBookIcon() {
    return SizedBox(
      width: 52,
      height: 52,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          _splashGold.withValues(alpha: 0.95),
          BlendMode.srcIn,
        ),
        child: Image.asset(
          'assets/paywall_icons/read_scripture.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.auto_stories_rounded,
            size: 38,
            color: _splashGold.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }

  Widget _splashProgressBar(bool isCompact) {
    // UI-only: loading caps at 98%; after ad phase _progress becomes 1.0 → 100%.
    final percent = _hasNavigated
        ? (_progress * 100).clamp(0, 100).round()
        : ((_progress * 100).clamp(0, 98).round());
    final fillFactor = _hasNavigated
        ? _progress.clamp(0.0, 1.0)
        : (_progress.clamp(0.0, 1.0) * 0.98);
    final barHeight = isCompact ? 24.0 : 26.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 10% narrower than the available content width.
        final barWidth = constraints.maxWidth * 0.9;
        return Align(
          alignment: Alignment.center,
          child: Container(
            height: barHeight,
            width: barWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barHeight / 2),
              color: const Color(0xFFE8D9C4).withValues(alpha: 0.88),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fillFactor,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barHeight / 2),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFD4A04A),
                            Color(0xFFC59434),
                            Color(0xFF9A6B2F),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _splashLoadingSection(bool isCompact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(36, 0, 36, isCompact ? 22 : 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _splashLoadingBookIcon(),
          SizedBox(height: isCompact ? 12 : 14),
          Text(
            _loaderMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isCompact ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: _splashInk.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 16),
          _splashProgressBar(isCompact),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;
    final iconSize = isCompact ? 168.0 : 200.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2E6D4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash-bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.45),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/Icon-1024.png',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 22 : 28),
                Text(
                  BibleInfo.bible_shortName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: isCompact ? 30 : 34,
                    fontWeight: FontWeight.w700,
                    color: _splashInk,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: isCompact ? 14 : 18),
                _splashOrnamentDivider(),
                SizedBox(height: isCompact ? 14 : 18),
                Text(
                  'Trusted Scripture.\nModern Experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w500,
                    color: _splashInk.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
                const Spacer(flex: 2),
                _splashLoadingSection(isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportDialogContent extends StatelessWidget {
  const SupportDialogContent({super.key});

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;

    if (width < 380) {
      // Small phones
      return 14.2;
    } else if (width < 480) {
      // Medium phones
      return baseSize;
    } else {
      // Large phones and tablets
      return baseSize * 1.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              BibleInfo.thankyoutitle,
              style: TextStyle(
                fontSize: getResponsiveFontSize(context, 22),
                color: CommanColor.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              " 📲 To keep this Bible app free, we show a few ads. \n\n ✅ Allowing tracking helps us show ads that match your faith and interests, like Christian books & family tools. \n\n ❌ If you don’t allow, ads will still appear but may be less relevant. \n\n  🔐 We respect your privacy and never share personal data. \n",
              style: TextStyle(
                fontSize: getResponsiveFontSize(context, 16),
                color: CommanColor.black,
              ),
              textAlign: TextAlign.left,
            ),
            Text(
              " “Let your light shine before others...” \n          – Matthew 5:16 ",
              style: TextStyle(
                fontSize: getResponsiveFontSize(context, 16),
                color: CommanColor.black,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // await AdConsentManager.initAppFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CommanColor.darkPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 50, vertical: 9),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 15),
                  color: CommanColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdConsentManager {
  static bool _canRequestAds = false;
  static bool _privacyOptionsRequired = false;
  static bool _attFlowCompleted = false;
  static const String _prefsDontTrack = "user_dont_track_ads";
  static final _initializationHelper = InitializationHelper();

  /// Requests the system ATT prompt once after splash (no custom pre-dialog).
  static Future<void> showAttFlowIfNeeded() async {
    if (_attFlowCompleted) return;
    _attFlowCompleted = true;

    final prefs = await SharedPreferences.getInstance();

    if (Platform.isIOS) {
      var status =
      await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        try {
          status =
          await AppTrackingTransparency.requestTrackingAuthorization();
          debugPrint('ATT Status: $status');
        } on PlatformException catch (e) {
          debugPrint('ATT Error: ${e.message}');
        }
      }

      if (status == TrackingStatus.denied) {
        await prefs.setBool(_prefsDontTrack, true);
        debugPrint("ATT denied — storing 'Don't track' and skipping");
      } else if (status == TrackingStatus.authorized) {
        await prefs.setBool(_prefsDontTrack, false);
      }
    }

    await initAppFlow();
  }

  /// Main initialization flow
  static Future<bool> initAppFlow() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint("ATT denied 2 — storing 'Don't track' and skipping");
    //  Early exit if "Don't track" flag already set
    if (prefs.getBool(_prefsDontTrack) ?? true) {
      debugPrint("User opted out — skipping consent flow");
      _canRequestAds = false;
      debugPrint("ATT denied 3 — storing 'Don't track' and skipping");
      return false;
    } else {
      try {
        debugPrint("ATT denied 4 — storing 'Don't track' and skipping");
        //  await _handleConsentFlow();
        await _initializationHelper.initialize();
        return _canRequestAds;
      } catch (e) {
        debugPrint('Ad init failed: $e');
        return false;
      }
    }
  }

  /// Handles UMP consent and iOS ATT
  static Future<void> _handleConsentFlow() async {
    final prefs = await SharedPreferences.getInstance();

    // If user previously opted out, skip everything
    if (prefs.getBool(_prefsDontTrack) ?? false) {
      debugPrint(
          "Skipping consent flow — user previously selected 'Don't track'");
      _canRequestAds = false;
      return;
    }

    late TrackingStatus status;
    final consentStatus = await ConsentInformation.instance.getConsentStatus();
    if (consentStatus != ConsentStatus.obtained) {
      _canRequestAds = false;
    }

    // iOS ATT request
    if (Platform.isIOS) {
      try {
        debugPrint("ATT denied 5 — storing 'Don't track' and skipping");
        status = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('ATT Status: $status');
      } on PlatformException catch (e) {
        debugPrint('ATT Error: ${e.message}');
      }

      if (status == TrackingStatus.denied) {
        // User refused — store flag and exit
        await prefs.setBool(_prefsDontTrack, true);
        debugPrint("ATT denied — storing 'Don't track' and skipping");
        return;
      }
    }

    // Request UMP consent info
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () async {
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        _privacyOptionsRequired = await _isPrivacyOptionsRequired();
        await Future.delayed(const Duration(seconds: 2));

        if (!_canRequestAds) {
          final formShown = await _loadAndShowConsentForm();
          _canRequestAds = await ConsentInformation.instance.canRequestAds();

          if (!_canRequestAds) {
            await prefs.setBool(_prefsDontTrack, true);
            debugPrint("User denied in Consent Form — storing 'Don't track'");
          }
        }

        await _initializeAdNetworks();
      },
          (FormError error) => throw Exception("Consent error: ${error.message}"),
    );
  }

  /// Loads & shows consent form if needed
  static Future<bool> _loadAndShowConsentForm() async {
    final prefs = await SharedPreferences.getInstance();

    // Extra safeguard: Skip if opted out
    if (prefs.getBool(_prefsDontTrack) ?? false) {
      debugPrint("Skipping form load — user opted out");
      return false;
    }

    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) throw Exception("Form error: ${error.message}");
      });
      return true;
    } catch (e) {
      debugPrint('Consent form failed: $e');
      return false;
    }
  }

  /// Checks if privacy options required
  static Future<bool> _isPrivacyOptionsRequired() async {
    return await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  /// Shows privacy options form (manual user request)
  static Future<void> showPrivacyOptionsForm() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          throw Exception("Privacy form error: ${error.message}");
        }
      });
    } catch (e) {
      debugPrint('Privacy form failed: $e');
    }
  }

  /// Initialize ad networks
  static Future<void> _initializeAdNetworks() async {
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
  }

  /// Returns appropriate AdRequest
  static Future<AdRequest> getAdRequest() async {
    final prefs = await SharedPreferences.getInstance();

    // Always non-personalized if opted out
    if (prefs.getBool(_prefsDontTrack) ?? false) {
      debugPrint("User opted out. Using fallback (NPA) ads.");
      _canRequestAds = false;
      return _createNonPersonalizedRequest();
    }

    final hasConsent = await _checkBasicConsent();
    if (!hasConsent) {
      debugPrint('No valid consent - using fallback NPA');
      _canRequestAds = false;
      return _createNonPersonalizedRequest();
    }

    final trackingAllowed = _canRequestAds &&
        (Platform.isAndroid ||
            await AppTrackingTransparency.trackingAuthorizationStatus ==
                TrackingStatus.authorized);

    return trackingAllowed
        ? AdRequest() // Personalized
        : _createNonPersonalizedRequest();
  }

  /// Checks if we have minimum consent
  static Future<bool> _checkBasicConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsDontTrack) ?? false) return false;

    final status =
    await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.denied) return false;

    final consentStatus = await ConsentInformation.instance.getConsentStatus();
    return consentStatus == ConsentStatus.obtained;
  }

  /// Create NPA (non-personalized ad request)
  static AdRequest _createNonPersonalizedRequest() {
    return AdRequest(
      nonPersonalizedAds: true,
      keywords: _getNonPersonalizedKeywords(),
    );
  }

  static List<String> _getNonPersonalizedKeywords() => [
    'bible',
    'christian',
    'faith',
    'prayer',
    'church',
    'devotional',
    'scripture'
  ];
}

class UpgradeCheckWrapper extends StatefulWidget {
  final Widget child;
  final String? check;
  /// When true, wraps [child] with [BibleUpgradeAlert]. Home uses open-ad only.
  final bool showUpgradeAlert;

  const UpgradeCheckWrapper({
    super.key,
    required this.child,
    this.check,
    this.showUpgradeAlert = false,
  });

  @override
  State<UpgradeCheckWrapper> createState() => _UpgradeCheckWrapperState();
}

class _UpgradeCheckWrapperState extends State<UpgradeCheckWrapper> {
  bool shouldShowAd = false;
  AppOpenAd? _appOpenAd;
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      debugLogging: true,
      durationUntilAlertAgain: const Duration(days: 1),
    );

    if (widget.showUpgradeAlert) {
      unawaited(
          SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false));
    }

    if (widget.check != 'home') return;

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('showopenad');
      // Splash already showed cold-start open ad (showopenad cleared).
      if (data != 'true') {
        return;
      }

      final updateAvailable = _upgrader.isUpdateAvailable();
      final pendingStreakRating = await SharPreferences.getInt(
          SharPreferences.pendingStreakCompleteCelebration) ??
          0;
      // Suppress open ad only while post-streak flow is still pending (Day 1 or Day 2+).
      // deferUpgradeAlert is for upgrade/rating UI only — not a permanent open-ad block.
      if (pendingStreakRating >= 1) {
        await prefs.setString("showopenad", "false");
        await SharPreferences.setString('OpenAd', '1');
        await _markOpenAdFlowComplete();
        return;
      }
      // debugPrint(
      //     'upgrader is  ${upgrader.versionInfo} ${upgrader.releaseNotes} $data');
      if (!updateAvailable && data == "true") {
        setState(() => shouldShowAd = true);
        // OpenAdService.showAd(); // ✅ Show open ad only if no update available
        //  if (widget.check == "show") {
        await initAppOpen();
        await prefs.setString("showopenad", "false");
        // }
      } else {
        await _markOpenAdFlowComplete();
        debugPrint('Update is available. Skipping open ad.');
      }
    });
  }

  Future<void> _markOpenAdFlowComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharPreferences.openAdFlowComplete, true);
  }

  loadOpenAd() async {
    final trackingAllowed = await isTrackingAllowed();
    debugPrint('ad pop loadOpenAd -  ${!trackingAllowed}');
    bool? isAdEnabledFromApi =
    await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    if (!(isAdEnabledFromApi ?? true)) {
      await _markOpenAdFlowComplete();
      return;
    }
    if (isAdEnabledFromApi ?? true) {
      String? openAdUnitId =
      await SharPreferences.getString(SharPreferences.openAppId);
      AppOpenAd.load(
        adUnitId: openAdUnitId ?? '',
        request: await AdConsentManager.getAdRequest(),
        //orientation: 1,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;

            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
                _markOpenAdFlowComplete();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _appOpenAd = null;
                _markOpenAdFlowComplete();
              },
            );

            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              final adToShow = _appOpenAd;
              if (adToShow == null) return;
              adToShow.show();
            });
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: $error');
            SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
            _markOpenAdFlowComplete();
          },
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 1));
    if (_appOpenAd == null) {
      await _markOpenAdFlowComplete();
    }
  }

  Future<void> initAppOpen() async {
    await SharPreferences.getString('test').then((value) async {
      if (value != null) {
        await SharPreferences.getString(SharPreferences.isRewardAdViewTime)
            .then((re) async {
          if (re != null) {
            DateTime CurrentDateTime = DateTime.now();
            DateTime SaveTime = DateTime.parse(re.toString());
            var diff = CurrentDateTime.difference(SaveTime).inDays;
            log('Diff: $diff');
            if (!diff.isNegative) {
              SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
              // bool dta = Provider.of<DownloadProvider>(context, listen: false)
              //     .isopenAdEnabled;
              // final checkad = await SharPreferences.getString('OpenAd') ?? "1";
              // final data2 = await SharPreferences.getString('bottom') ?? '0';

              final data = await SharPreferences.getBoolean(
                  SharPreferences.isAdsEnabled) ??
                  true;
              // debugPrint("Open ad tigger and $checkad and && $dta");
              if (data) {
                await loadOpenAd();
              } else {
                await _markOpenAdFlowComplete();
              }
              setState(() {});
            } else {
              SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
              await _markOpenAdFlowComplete();
            }
          } else {
            // bool dta = Provider.of<DownloadProvider>(context, listen: false)
            //     .isopenAdEnabled;
            // final checkad = await SharPreferences.getString('OpenAd') ?? "1";
            // final data2 = await SharPreferences.getString('bottom') ?? '0';

            final data = await SharPreferences.getBoolean(
                SharPreferences.isAdsEnabled) ??
                true;
            // debugPrint("Open ad tigger and $checkad and && $dta");
            if (data) {
              await loadOpenAd();
            } else {
              await _markOpenAdFlowComplete();
            }
            setState(() {});
          }
        });
      } else {
        await SharPreferences.setString('test', 'test');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showUpgradeAlert) {
      return widget.child;
    }
    return BibleUpgradeAlert(
      upgrader: _upgrader,
      child: widget.child,
    );
  }
}

// Helper function for background isolate JSON parsing:
List<DailyVersesMainListModel> parseDailyVerseJsond(String jsonString) {
  final List<dynamic> decoded = json.decode(jsonString);
  return decoded
      .map((item) => DailyVersesMainListModel.fromJson(item))
      .toList();
}