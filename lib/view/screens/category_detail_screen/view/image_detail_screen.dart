import 'dart:developer';
import 'dart:io';
import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/fetched_images_bloc.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/widget/adhelper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as p;

class AdService {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  NativeAd? _fullScreenAd;
  bool _isFullScreenAdLoaded = false;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;

  void loadRewardedInterstitialAds(VoidCallback onAdLoaded) async {
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.rewardedInterstitialAd);
    RewardedInterstitialAd.loadWithAdManagerAdRequest(
      adUnitId: adUnitId.toString(),
      adManagerRequest: const AdManagerAdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) async {
              await SharPreferences.setString('OpenAd', '1');
            },
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) async {
              await SharPreferences.setString('OpenAd', '1');
              ad.dispose();
            },
            onAdClicked: (ad) {},
          );
          _rewardedInterstitialAd = ad;
          onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('RewardedInterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd() async {
    await Future.delayed(Duration(milliseconds: 600));
    if (_interstitialAd != null) {
      EasyLoading.dismiss();
      _interstitialAd!.show();
      DebugConsole.log(" interstitialAd 3 is running ");
      _interstitialAd = null; // Dispose after showing
      _isInterstitialAdLoaded = false;
      loadInterstitialAd(() {}); // Reload for the next time
    } else {
      EasyLoading.dismiss();
      log('InterstitialAd is not ready yet');
    }
  }

  void loadInterstitialAd(VoidCallback onAdLoaded) async {
    final trackingAllowed = await isTrackingAllowed();

    String? adUnitId =
        await SharPreferences.getString(SharPreferences.googleInterstitialAd);

    debugPrint('ad pop loadInterstitialAd -  ${!trackingAllowed} - $adUnitId');
    InterstitialAd.load(
      adUnitId: adUnitId.toString(),
      request: await AdConsentManager.getAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) async {
              await SharPreferences.setString('OpenAd', '1');
            },
            onAdDismissedFullScreenContent: (ad) async {
              await SharPreferences.setString('OpenAd', '1');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) async {
          await SharPreferences.setString('OpenAd', '1');
          log('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void loadBannerAd(VoidCallback onAdLoaded) async {
    final trackingAllowed = await isTrackingAllowed();
    debugPrint('ad pop loadBannerAd -  ${!trackingAllowed}');
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.googleBannerId);
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId.toString(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          log('Failed to load banner ad: $error');
        },
      ),
      request: await AdConsentManager.getAdRequest(),
    )..load();
  }

  void loadFullScreenAd(VoidCallback onAdLoaded) async {
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.nativeAdId);
    _fullScreenAd = NativeAd(
      adUnitId: adUnitId.toString(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isFullScreenAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdManagerAdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: CommanColor.darkPrimaryColor,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
      ),
    )..load();
  }

  InterstitialAd? get interstitialAd =>
      _isInterstitialAdLoaded ? _interstitialAd : null;
  RewardedInterstitialAd? get rewardedInterstitialAd => _rewardedInterstitialAd;
  BannerAd? get bannerAd => _isBannerAdLoaded ? _bannerAd : null;
  NativeAd? get fullScreenAd => _isFullScreenAdLoaded ? _fullScreenAd : null;
}

class ImageDetailScreen extends StatefulHookConsumerWidget {
  final int index;
  final CategoryModel category;
  final bool isWallpaper;
  const ImageDetailScreen(
      {super.key,
      required this.category,
      required this.index,
      required this.isWallpaper});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      ImageDetailScreenState();
}

class ImageDetailScreenState extends ConsumerState<ImageDetailScreen> {
  late PageController controller;
  late int currentIndex;
  late bool isWallpaper;
  late int adcountview;
  final AdService _adService = AdService();
  late ValueNotifier<bool> isDownloading;
  late ValueNotifier<bool> isShareImageLoading;

  //! ad

  // loadAds() async {
  //   final shouldLoadAd = await SharPreferences.shouldLoadAd();
  //   final data =
  //       await SharPreferences.getString(SharPreferences.showinterstitialrow);

  //   setState(() {
  //     adcountview = int.parse(data.toString());
  //   });

  //   debugPrint("adcount is $adcountview");

  //   if (shouldLoadAd) {
  //     //
  //     //

  //     RewardedAdService.loadAd(onAdLoaded: () {
  //       setState(() => isAdReady = true);
  //     });
  //     _adService.loadRewardedInterstitialAds(() {
  //       if (context.mounted) {
  //         setState(() {});
  //       }
  //     });
  //     _adService.loadInterstitialAd(() {
  //       if (context.mounted) {
  //         setState(() {});
  //       }
  //     });
  //     debugPrint("ad is called");
  //     _adService.loadBannerAd(() {
  //       if (context.mounted) {
  //         setState(() {});
  //       }
  //     });
  //     _adService.loadFullScreenAd(() {
  //       if (context.mounted) {
  //         setState(() {});
  //       }
  //     });
  //   }
  // }

  int clickCount = 0;
  bool isAdReady = false;

  void _handledownloadClick() async {
    final data = await SharPreferences.getString(SharPreferences.offerenabled);
    // await Future.delayed(Duration(seconds: 1));
    debugPrint("offer enabled or - $data");
    // final data = await SharPreferences.getString(SharPreferences.offerenabled);
    final adenable =
        await SharPreferences.getBoolean(SharPreferences.isAdsEnabledApi);

    final checkdownload = await SharPreferences.getBoolean("downloadreward");

    final adenable2 = await SharPreferences.shouldLoadAd();

    final subenable = await SharPreferences.getBoolean('isSubscriptionEnabled');

    debugPrint(
        "offer enabled 2 or - ad $adenable - $adenable2 & sub $subenable");
    if (subenable!) {
      // if (data == '1') {
      if (adenable2) {
        setState(() {
          clickCount++;
          if (clickCount == 4) {
            setdownloadreward();
            showLimitDialog();
          } else if (!checkdownload!) {
            setState(() {
              clickCount = 3;
            });
          }
        });
      } else {
        setState(() {
          clickCount = 3;
        });
        await SharPreferences.setBoolean("downloadreward", true);
      }
      // } else {
      //   setState(() {
      //     clickCount = 0;
      //   });
      //   await SharPreferences.setBoolean("downloadreward", true);
      // }
    } else {
      setState(() {
        clickCount = 3;
      });
      await SharPreferences.setBoolean("downloadreward", true);
    }
  }

  setdownloadreward() async {
    await SharPreferences.setBoolean("downloadreward", false);
    setState(() {
      clickCount = 0;
    });
  }

  void _handleReward() async {
    await SharPreferences.setBoolean("downloadreward", true);
    Constants.showToast(
        "Reward unlocked! Download 3 more images for free", 6000);
  }

  Future<void> _handleAdDismissed() async {}

  Future<void> showLimitDialog() async {
    Sizecf().init(context);

    await SharPreferences.setBoolean("downloadreward", false);

    // Check if user has premium subscription
    final downloadProvider =
        p.Provider.of<DownloadProvider>(context, listen: false);
    final subscriptionPlan = await downloadProvider.getSubscriptionPlan();
    final hasPremium = subscriptionPlan != null &&
        subscriptionPlan.isNotEmpty &&
        ['platinum', 'gold', 'silver'].contains(subscriptionPlan.toLowerCase());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      clickCount = 3;
                    });
                    await SharPreferences.setInt("downloadrewardcount", 3);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          " X ",
                          style: TextStyle(
                              fontSize: Sizecf.blockSizeVertical! * 1.7,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Get Unlimited Downloads!',
                  style: CommanStyle.bw20500(context).copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You’ve reached your daily limit of 3 image downloads.',
                  textAlign: TextAlign.left,
                  style: CommanStyle.bw16500(context).copyWith(
                      fontWeight: FontWeight.w400, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text('To continue downloading:',
                    style: CommanStyle.bw15500(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 20),

                // Buy Premium Row - Only show if user doesn't have premium
                hasPremium
                    ? SizedBox.shrink()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Icon(Icons.diamond, color: Colors.brown),
                          Image.asset(
                            'assets/Asset1.png',
                            height: 25,
                            width: 25,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buy Premium',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  'Unlock unlimited downloads and remove all limits',
                                  style: CommanStyle.bw15500wU(context)
                                      .copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 15),
                isAdReady == false
                    ? SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '(or)',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                        ],
                      ),
                isAdReady == false
                    ? SizedBox.shrink()
                    : const SizedBox(height: 15),
                // Watch Ad Row
                isAdReady == false
                    ? SizedBox.shrink()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon(Icons.ondemand_video, color: Colors.brown),
                          Image.asset(
                            'assets/Asset5.png',
                            height: 25,
                            width: 25,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Watch an Ad',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  'Instantly download this image by watching a short ad',
                                  style: CommanStyle.bw15500wU(context)
                                      .copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: (isAdReady == false || hasPremium)
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    // Buy Premium button - Only show if user doesn't have premium
                    hasPremium
                        ? SizedBox.shrink()
                        : ElevatedButton(
                            onPressed: () async {
                              await SharPreferences.setString('OpenAd', '1');
                              // Use constants as fallback when SharedPreferences are empty (first time loading)
                              final sixMonthPlan =
                                  await SharPreferences.getString(
                                          'sixMonthPlan') ??
                                      BibleInfo.sixMonthPlanid;
                              final oneYearPlan =
                                  await SharPreferences.getString(
                                          'oneYearPlan') ??
                                      BibleInfo.oneYearPlanid;
                              final lifeTimePlan =
                                  await SharPreferences.getString(
                                          'lifeTimePlan') ??
                                      BibleInfo.lifeTimePlanid;
                              setState(() {
                                clickCount = 0;
                              });
                              await SharPreferences.setInt(
                                  "downloadrewardcount", 0);
                              if (context.mounted) {
                                Navigator.pop(context);
                                // Handle buy premium - Navigate to SubscriptionScreen
                                SubscriptionScreen.openPaywallStacked(
                                  sixMonthPlan: sixMonthPlan,
                                  oneYearPlan: oneYearPlan,
                                  lifeTimePlan: lifeTimePlan,
                                  checkad: 'image',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              backgroundColor: CommanColor.lightModePrimary200,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Buy Premium',
                              textAlign: TextAlign.center,
                              style: CommanStyle.white14500.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                    SizedBox(
                      width: 5,
                    ),
                    isAdReady == false
                        ? SizedBox.shrink()
                        : ElevatedButton(
                            onPressed: () async {
                              await SharPreferences.setString('OpenAd', '1');
                              Navigator.pop(context);
                              // Handle watch ad
                              var connectivityResult =
                                  await Connectivity().checkConnectivity();
                              if (connectivityResult.first ==
                                      ConnectivityResult.other ||
                                  connectivityResult.first ==
                                      ConnectivityResult.wifi ||
                                  connectivityResult.first ==
                                      ConnectivityResult.mobile) {
                                RewardedAdService.loadAd(
                                    onAdLoaded: () {
                                      if (context.mounted) {
                                        setState(() => isAdReady = true);
                                      }
                                    },
                                    onAdFailed: () async {
                                      setState(
                                        () {
                                          clickCount = 3;
                                        },
                                      );
                                      Constants.showToast(
                                          "Ad not available image1", 6000);
                                      await SharPreferences.setInt(
                                          "downloadrewardcount", 3);
                                    },
                                    data: "imaged");
                                if (isAdReady) {
                                  await SharPreferences.setString(
                                      'OpenAd', '1');
                                  RewardedAdService.showAd(
                                      onRewardEarned: _handleReward,
                                      onAdDismissed: () async {
                                        // setState(() => isAdReady = false);
                                        await SharPreferences.setBoolean(
                                            "downloadreward", true);
                                        Constants.showToast(
                                            "Reward unlocked! Download 3 more images for free",
                                            6000);
                                        RewardedAdService.loadAd(
                                            onAdLoaded: () {
                                              setState(() => isAdReady = true);
                                            },
                                            onAdFailed: () {
                                              Constants.showToast(
                                                  "Ad not available. image 2",
                                                  6000);
                                            },
                                            data: "imaged");
                                      },
                                      data: "image d");
                                }
                              } else {
                                Constants.showToast(
                                    'No Internet Connection', 6000);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CommanColor.lightModePrimary200,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Watch Ad',
                              style: CommanStyle.white14500.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          )),
    );
  }

  @override
  void initState() {
    super.initState();
    isWallpaper = widget.isWallpaper;
    currentIndex = widget.index;
    controller = PageController(initialPage: widget.index);

    isDownloading = ValueNotifier(false);
    isShareImageLoading = ValueNotifier(false);
    loadAds();
  }

  Future<void> loadAds() async {
    try {
      final shouldLoadAd = await SharPreferences.shouldLoadAd();
      final data =
          await SharPreferences.getString(SharPreferences.showinterstitialrow);

      int count = int.tryParse(data ?? '0') ?? 0;

      setState(() {
        adcountview = count;
      });

      debugPrint("Ad count is $adcountview");

      if (!shouldLoadAd) return;

      debugPrint("Loading ads...");

      //  Load Rewarded Ad
      RewardedAdService.loadAd(
          onAdLoaded: () {
            if (context.mounted) {
              setState(() => isAdReady = true);
            }
          },
          onAdFailed: () {
            setState(() => isAdReady = false);
          },
          data: "imaged");
      // Load other ads with single mounted check
      // _adService.loadRewardedInterstitialAds(() {});
      _adService.loadInterstitialAd(() {});
      _adService.loadBannerAd(() {});
      _adService.loadFullScreenAd(() {});

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading ads: $e");
    }
  }

  void bookmarkImage(ImageModel imageModel) {
    ref
        .read(bookmarkSharedPrefBloc)
        .toggleBookMarkImage(imageModel, isWallpaper);
  }

  Future<void> shareImage(ImageModel imageModel) async {
    isShareImageLoading.value = true;
    try {
      final response = await http.get(Uri.parse(imageModel.imageUrl ?? ''));
      final directory = await getApplicationDocumentsDirectory();
      final image =
          File("${directory.path}/${imageModel.imageId}-${DateTime.now()}.png");
      await image.writeAsBytes(response.bodyBytes);
      isShareImageLoading.value = false;

      final shareOrigin =
          Rect.fromPoints(const Offset(2, 2), const Offset(3, 3));

      if (isWallpaper) {
        await Share.shareXFiles(
          [
            XFile(
              image.path,
              mimeType: 'image/png',
              name: 'Jesus Wallpaper.png',
            ),
          ],
          sharePositionOrigin: shareOrigin,
        );
        return;
      }

      await Share.shareXFiles(
        [
          XFile(
            image.path,
            mimeType: 'image/png',
            name: 'Bible Quote.png',
          ),
        ],
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      isShareImageLoading.value = false;
      Constants.showToast("Unable to share at the moment");
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      // final androidVersion = int.parse(androidInfo.version.release.split('.')[0]);
      // if (androidVersion >= 13) {
      //   var status = await Permission.photos.request();
      //   if (status.isGranted) return true;
      // } else {
      //   var status = await Permission.storage.request();
      //   if (status.isGranted) return true;
      // }
      // Constants.showToast("Storage permission is required to save images.");
      // return false;

      if (await Permission.storage.isGranted) return true;

      var status = await Permission.storage.request();

      if (status.isGranted) return true;

      Constants.showToast("Storage permission is required to save images.");
      return false;
    } else if (Platform.isIOS) {
      // var status = await Permission.photos.request();
      // if (status.isGranted) return true;

      // if (status.isPermanentlyDenied) {
      //   Constants.showToast("Enable photo access from Settings to save images.");
      //   //openAppSettings(); // Optional
      // } else {
      //   Constants.showToast("Photo access is needed to save images.");
      // }

      // return false;
      final status = await Permission.photos.status;
      print("Current iOS permission status: $status");
      if (status.isGranted) return true;

      final newStatus = await Permission.photos.request();
      print("New iOS permission status: $newStatus");

      if (newStatus.isGranted) return true;

      if (newStatus.isPermanentlyDenied || newStatus.isLimited) {
        Constants.showToast("Photo access permanently denied. Go to Settings.");
        //openAppSettings();
        showPermissionSettingsDialog(context);
      } else {
        Constants.showToast("Photo access is required.");
      }

      return false;
    }
    return false;
  }

  void showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text("Permission Required"),
        content: Text(
          "Please enable photo permissions in settings to use this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // Opens settings
              Navigator.pop(context);
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> downloadImage(ImageModel imageModel,
      {required bool isDownloadImage}) async {
    bool? isCheckcount = await SharPreferences.getBoolean("downloadreward");

    if (isCheckcount!) {
      final isAlreadyBookMarked = ref
          .read(bookmarkSharedPrefBloc)
          .isIdBookMarked(imageModel.imageId, isWallpaper);
      if (!(isAlreadyBookMarked && isDownloadImage)) {
        bookmarkImage(imageModel);
      }
      isDownloading.value = true;
      try {
        bool hasPermission = await _requestPermission();
        if (!hasPermission) {
          isDownloading.value = false;
          return;
        }

        final response = await http.get(Uri.parse(imageModel.imageUrl ?? ''));
        await [Permission.storage].request();
        final time = DateTime.now()
            .toIso8601String()
            .replaceAll(".", "_")
            .replaceAll(":", "_");
        final name = "Bible_$time";
        await ImageGallerySaverPlus.saveImage(response.bodyBytes, name: name);
        isDownloading.value = false;
        Constants.showToast(isDownloadImage
            ? "Image downloaded successfully"
            : "Favourite added successfully");
      } catch (e) {
        Constants.showToast("Failed to download Image");
      }
      isDownloading.value = false;
    }
    isDownloading.value = false;
  }

  void openAd(ImageModel imageModel, bool isDownloadImage) async {
    final shouldLoadAd = await SharPreferences.shouldLoadAd();
    if (shouldLoadAd) {
      if (_adService.rewardedInterstitialAd != null) {
        _adService.rewardedInterstitialAd?.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          downloadImage(imageModel, isDownloadImage: isDownloadImage);
          _adService.loadRewardedInterstitialAds(() {});
          SharPreferences.setString(
              SharPreferences.lastInterstitialRewardedAdPlayedTime,
              DateTime.now().toString());
        });
      } else {
        downloadImage(imageModel, isDownloadImage: isDownloadImage);
      }
    } else {
      downloadImage(imageModel, isDownloadImage: isDownloadImage);
    }
  }

  Future<void> playAd(ImageModel imageModel, bool isDownloadImage) async {
    bool? isCheckcount = await SharPreferences.getBoolean("downloadreward");
    // await Future.delayed(Duration(seconds: 1));
    if (isCheckcount!) {
      if (_adService.rewardedInterstitialAd != null) {
        String? lastPlayed = await SharPreferences.getString(
            SharPreferences.lastInterstitialRewardedAdPlayedTime);
        String? adsDiff =
            await SharPreferences.getString(SharPreferences.adPauseDiff);
        final lastPlayedDateTime = DateTime.tryParse(lastPlayed.toString());
        if (lastPlayedDateTime != null) {
          final diff = DateTime.now().difference(lastPlayedDateTime).inMinutes;
          int diffValidValue = int.tryParse(adsDiff ?? '') ?? 5;
          if (diff < diffValidValue) {
            downloadImage(imageModel, isDownloadImage: isDownloadImage);
          } else {
            //  openAd(imageModel, isDownloadImage);
            downloadImage(imageModel, isDownloadImage: isDownloadImage);
          }
        } else {
          //  openAd(imageModel, isDownloadImage);
          downloadImage(imageModel, isDownloadImage: isDownloadImage);
        }
      } else {
        downloadImage(imageModel, isDownloadImage: isDownloadImage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoState = ref.watch(fetchedPhotosBloc(widget.category));
    final photos = photoState.photos;
    final showAd = useState(false);
    Sizecf().init(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: CommanColor.isDarkTheme(context)
            ? BoxDecoration(color: CommanColor.darkPrimaryColor)
            : (p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                    AppCustomTheme.vintage
                ? BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(Images.bgImage(context)),
                        fit: BoxFit.fill))
                : null),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
                  ),
                  Text(showAd.value ? 'Ads' : (widget.category.name ?? ""),
                      style: CommanStyle.appBarStyle(context)),
                  const SizedBox(width: 20)
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                // height: Sizecf.scrnHeight! * 0.66,
                child: photoState.isLoading && photos.isEmpty
                    ? Center(
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : Stack(
                  children: [
                    PhotoViewGallery.builder(
                      pageController: controller,
                      scrollPhysics: const BouncingScrollPhysics(),
                      builder: (context, i) {
                        // Future.delayed(Duration.zero, () {
                        //   showAd.value = (i > 0 &&
                        //       i % 5 == 0 &&
                        //       _adService._interstitialAd != null);
                        // });

                        return PhotoViewGalleryPageOptions.customChild(
                          child:
                              // showAd.value
                              //     ? Center(
                              //         child: ConstrainedBox(
                              //           constraints: const BoxConstraints(
                              //             minWidth: 320,
                              //             minHeight: 320,
                              //             maxWidth: 400,
                              //             maxHeight: 400,
                              //           ),
                              //           child: _adService.fullScreenAd == null
                              //               ? const SizedBox.shrink()
                              //               : AdWidget(ad: _adService.fullScreenAd!),
                              //         ),
                              //       )
                              //     :
                              CachedNetworkImage(
                            imageUrl: photos[i].imageUrl ?? '',
                            fit: BoxFit.fill,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator.adaptive(
                                value: downloadProgress.progress,
                              ),
                            ),
                          ),
                          initialScale: PhotoViewComputedScale.contained,
                          // maxScale: PhotoViewComputedScale.contained * 3.7,
                          minScale: PhotoViewComputedScale.contained,
                          heroAttributes: PhotoViewHeroAttributes(tag: i),
                        );
                      },
                      itemCount: photos.length,
                      backgroundDecoration:
                          const BoxDecoration(color: Colors.transparent),
                      loadingBuilder: (context, event) => Center(
                        child: CircularProgressIndicator.adaptive(
                          value: event == null
                              ? null
                              : (event.cumulativeBytesLoaded) /
                                  (event.expectedTotalBytes ?? 1),
                        ),
                      ),
                      onPageChanged: (val) async {
                        if (val > (photos.length - 5)) {
                          ref
                              .read(fetchedPhotosBloc(widget.category))
                              .getPhotos();
                        }

                        final shouldLoadAd =
                            await SharPreferences.shouldLoadAd();
                        if (val % 3 == 0 && shouldLoadAd) {
                          _adService.loadBannerAd(() {
                            if (context.mounted) {
                              setState(() {});
                            }
                          });
                        }
                        if (val > 0 &&
                            val % adcountview == 0 &&
                            _adService._interstitialAd != null) {
                          if (_adService._isInterstitialAdLoaded) {
                            EasyLoading.showInfo('Please wait...');
                            await SharPreferences.setString('OpenAd', '1');
                            _adService.showInterstitialAd();

                            // Future.delayed(Duration.zero, () {
                            //   showAd.value = false;
                            // });
                          }
                        }
                        if (context.mounted) {
                          setState(() {
                            // showAd.value = (val > 0 &&
                            //     val % 5 == 0 &&
                            //     _adService._fullScreenAd != null);
                            if ((val > 0 &&
                                val % adcountview == 0 &&
                                _adService._fullScreenAd != null)) {
                              currentIndex = val - (val ~/ 5);
                            } else {
                              currentIndex = val;
                            }
                          });
                          // int newIndex;
                          // if ((val > 0 &&
                          //     val % 5 == 0 &&
                          //     _adService._fullScreenAd != null)) {
                          //   newIndex = val - (val ~/ 5);
                          // } else {
                          //   newIndex = val;
                          // }

                          // if (currentIndex != newIndex) {
                          //   currentIndex = newIndex;
                          //   shouldUpdate = true;
                          // }
                        }
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      left: 2,
                      right: 2,
                      child: !showAd.value
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // GestureDetector(
                                  //   onTap: () {
                                  //     playAd(photos[currentIndex], false);
                                  //   },
                                  //   child: Icon(
                                  //     Icons.favorite,
                                  //     color: bookmarkState.isIdBookMarked(
                                  //             photos[currentIndex].imageId, isWallpaper)
                                  //         ? Colors.red
                                  //         : CommanColor.black,
                                  //   ),
                                  // ),
                                  isShareImageLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator
                                              .adaptive())
                                      : GestureDetector(
                                          onTap: () async {
                                            await SharPreferences.setString(
                                                'OpenAd', '1');
                                            shareImage(photos[currentIndex]);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: CommanColor.white,
                                                shape: BoxShape.circle),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: const Icon(
                                                Icons.share,
                                                color: CommanColor.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ValueListenableBuilder(
                                    valueListenable: isDownloading,
                                    builder: (context, value, child) {
                                      return value
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator
                                                  .adaptive())
                                          : GestureDetector(
                                              onTap: () async {
                                                await SharPreferences.setString(
                                                    'OpenAd', '1');
                                                final providerdailoglimit =
                                                    context.read<
                                                        DownloadProvider>();
                                                // _handledownloadClick();

                                                final data =
                                                    await providerdailoglimit
                                                        .handleDownloadClick(
                                                            context);

                                                if (data) {
                                                  showLimitDialog();
                                                }

                                                bool? isCheckcount =
                                                    await SharPreferences
                                                        .getBoolean(
                                                            "downloadreward");

                                                if (isCheckcount! &&
                                                    providerdailoglimit
                                                            .clickCount !=
                                                        4) {
                                                  playAd(photos[currentIndex],
                                                      true);
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: CommanColor.white,
                                                    shape: BoxShape.circle),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: const Icon(
                                                    Icons.cloud_download,
                                                    color: CommanColor.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                    },
                                  )
                                ],
                              ),
                            )
                          : SizedBox(),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              (!showAd.value && _adService.bannerAd != null)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: SizedBox(
                        height: _adService.bannerAd!.size.height.toDouble(),
                        width: _adService.bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _adService.bannerAd!),
                      ),
                    )
                  : const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
