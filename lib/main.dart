import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/core/notifiers/auth/auth.notifier.dart';
import 'package:biblebookapp/core/notifiers/bottom.notifier.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/background_api_service.dart';
import 'package:biblebookapp/services/statsig/statsig_service.dart';

import 'package:biblebookapp/view/widget/adhelper.dart';
import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as hooks;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/constants/theme_provider.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;

// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp(
//   //   options: DefaultFirebaseOptions.currentPlatform,
//   // );
//   configLoading();
//   await dotenv.load(fileName: ".env");

//   await GetStorage.init();

//   /// SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
//   tz.initializeTimeZones();

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//   await SharPreferences.getString(SharPreferences.theme) ?? "notSave";

//   // final appOpenAdManager = AppOpenAdManager();
//   // final appLifecycleReactor =
//   //     AppLifecycleReactor(appOpenAdManager: appOpenAdManager);

//   await MobileAds.instance.initialize();
//   RewardedAdService();
//   // appOpenAdManager.loadAd(); // Load ad in advance
//   // appLifecycleReactor.listenToAppStateChanges();

//   runApp(
//     hooks.ProviderScope(
//       child: MultiProvider(
//         providers: [
//           ChangeNotifierProvider(create: (context) => ThemeProvider()),
//           ChangeNotifierProvider(create: (context) => AuthNotifier()),
//           ChangeNotifierProvider(create: (context) => CacheNotifier()),
//           ChangeNotifierProvider(create: (context) => DownloadProvider()),
//           ChangeNotifierProvider(
//               create: (context) => HomeContentEditProvider()),
//           // Add other providers here
//         ],
//         child: MyApp(),
//       ),
//     ),
//   );
// }

// configLoading() {
//   EasyLoading.instance
//     ..displayDuration = const Duration(milliseconds: 2000)
//     ..indicatorType = EasyLoadingIndicatorType.fadingCircle
//     ..loadingStyle = EasyLoadingStyle.custom
//     ..indicatorSize = 45.0
//     ..radius = 5.0
//     ..backgroundColor = const Color.fromARGB(255, 130, 88, 88)
//     ..textColor = Colors.white
//     ..maskColor = Colors.white
//     ..indicatorColor = Colors.white
//     ..userInteractions = false
//     ..dismissOnTap = true;
// }

// // var mode;
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   log('Remote Message: ${message.data}');
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
// }

bool _isAppInBackground = false;
bool _isAppInActive = false;

// make this available app-wide
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configLoading();

  // Keep startup resilient on real devices:
  // run core app even if any optional service init fails/hangs.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("main: dotenv load failed: $e");
  }

  try {
    await GetStorage.init();
  } catch (e) {
    debugPrint("main: GetStorage init failed: $e");
  }

  try {
    tz.initializeTimeZones();
  } catch (e) {
    debugPrint("main: timezone init failed: $e");
  }

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint("main: orientation lock failed: $e");
  }

  try {
    await SharPreferences.getString(SharPreferences.theme);
  } catch (e) {
    debugPrint("main: theme preload failed: $e");
  }

  runApp(
    hooks.ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => AuthNotifier()),
          ChangeNotifierProvider(create: (context) => CacheNotifier()),
          ChangeNotifierProvider(create: (context) => DownloadProvider()),
          ChangeNotifierProvider(
              create: (context) => HomeContentEditProvider()),
        ],
        child: const LifecycleWrapper(), // Wrap MyApp inside lifecycle handler
      ),
    ),
  );

  // Non-critical startup tasks in background so debugger/service attach
  // is not blocked by network/plugin initialization.
  unawaited(_bootstrapBackgroundStartup());
}

Future<void> _bootstrapBackgroundStartup() async {
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
    RewardedAdService();
  } catch (e) {
    debugPrint("main: MobileAds init failed: $e");
  }

  try {
    await StatsigService.initialize().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint("main: Statsig init failed: $e");
  }

  try {
    BackgroundApiService().startBackgroundLoading();
  } catch (e) {
    debugPrint("main: background API bootstrap failed: $e");
  }

  try {
    await AppApiConstant.loadChatLanguage().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint("main: chat language load failed: $e");
  }

  try {
    await initBibleHomeWidget().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint("main: home widget init failed: $e");
  }
}

configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 5.0
    ..backgroundColor = const Color.fromARGB(255, 130, 88, 88)
    ..textColor = Colors.white
    ..maskColor = Colors.white
    ..indicatorColor = Colors.white
    ..userInteractions = false
    ..dismissOnTap = true;
}

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   log('Remote Message: ${message.data}');
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
// }

// Lifecycle Wrapper
class LifecycleWrapper extends StatefulWidget {
  const LifecycleWrapper({super.key});
  @override
  State<LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<LifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        _isAppInActive = false;
        break;
      case AppLifecycleState.inactive:
        if (_isAppInBackground) {
          _isAppInActive = true;
        }
        break;
      case AppLifecycleState.resumed:
        final checkad = await SharPreferences.getString('OpenAd') ?? "1";
        final closead = await SharPreferences.getBoolean('closead') ?? true;
        debugPrint(
            "App resumed: $state, OpenAd: $checkad, isActive: $_isAppInActive, $closead");

        if (_isAppInBackground && checkad != '1' && _isAppInActive && closead) {
          _isAppInBackground = false;
          _isAppInActive = false;
          await SharPreferences.setString('OpenAd', '0');
          await initAppOpen();
        } else {
          // Keep the existing OpenAd flag value so flows that explicitly
          // disable app-open ads (set OpenAd='1') are not overridden here.
        }
        break;

      default:
        break;
    }
  }

  Future<void> loadOpenAd() async {
    bool? isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    if (isAdEnabledFromApi ?? true) {
      String? openAdUnitId =
          await SharPreferences.getString(SharPreferences.openAppId);
      AppOpenAd.load(
        adUnitId: openAdUnitId ?? '',
        request: await AdConsentManager.getAdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            ad.show();
          },
          onAdFailedToLoad: (error) {
            SharPreferences.setBoolean(SharPreferences.isAdsEnabled, false);
          },
        ),
      );
    }
  }

  Future<void> initAppOpen() async {
    await SharPreferences.getString('test').then((value) async {
      if (value != null) {
        final isAdsEnabled =
            await SharPreferences.getBoolean(SharPreferences.isAdsEnabled) ??
                true;
        if (isAdsEnabled) {
          await loadOpenAd();
        }
      } else {
        await SharPreferences.setString('test', 'test');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        Sizecf().init(context);
        return GetMaterialApp(
          title: "Bible",
          navigatorObservers: [routeObserver],
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: MyThemes.lightTheme(context, themeProvider.backgroundColor),
          darkTheme: MyThemes.darkTheme(context),
          home: SplashScreen(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}

enum Availability { loading, available, unavailable }

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  void loadAd() async {
    bool? isAdEnabledFromApi =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);
    if (isAdEnabledFromApi ?? true) {
      String? openAdUnitId =
          await SharPreferences.getString(SharPreferences.openAppId);
      AppOpenAd.load(
        adUnitId: openAdUnitId ?? '',
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
          },
          onAdFailedToLoad: (error) {
            _appOpenAd = null;
          },
        ),
        //orientation: AppOpenAd.orientationPortrait,
      );
    }
  }

  void showAdIfAvailable() {
    if (!isAdAvailable || _isShowingAd) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
      },
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
    );

    _appOpenAd!.show();
  }

  bool get isAdAvailable => _appOpenAd != null;
}

class AppLifecycleReactor {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream
        .forEach((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) async {
    if (appState == AppState.foreground) {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('hasShownOpenAd') ?? false;

      if (!isFirstTime) {
        appOpenAdManager.showAdIfAvailable();
        await prefs.setBool('hasShownOpenAd', true);
      }
    }
  }
}
