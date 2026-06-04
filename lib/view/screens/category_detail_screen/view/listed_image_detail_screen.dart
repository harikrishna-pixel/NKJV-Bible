import 'dart:developer';
import 'dart:io';

import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as p;

deleteConfirmation(BuildContext context, Function() onTap) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
          backgroundColor: CommanColor.white,
          insetPadding: isTablet
              ? EdgeInsets.symmetric(
                  horizontal: 190,
                )
              : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure you want to delete?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: CommanColor.black, fontSize: isTablet ? 20 : null),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: CommanColor.lightGrey1,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2)
                              ],
                            ),
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: isTablet
                                      ? BibleInfo.fontSizeScale * 19
                                      : BibleInfo.fontSizeScale * 14,
                                  fontWeight: FontWeight.w400,
                                  color: CommanColor.black),
                            )),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: CommanColor.darkPrimaryColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2)
                              ],
                            ),
                            child: Text(
                              'Okay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  letterSpacing: BibleInfo.letterSpacing,
                                  fontSize: isTablet
                                      ? BibleInfo.fontSizeScale * 19
                                      : BibleInfo.fontSizeScale * 14,
                                  fontWeight: FontWeight.w500,
                                  color: CommanColor.white),
                            )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ));
    },
  );
}

class ListedImageDetailScreen extends HookConsumerWidget {
  const ListedImageDetailScreen(
      {super.key,
      required this.index,
      required this.photos,
      required this.isWallpaper});
  final int index;
  final List<ImageModel> photos;
  final bool isWallpaper;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(index);
    final bookmarkState = ref.watch(bookmarkSharedPrefBloc);
    final isDownloading = useState(false);
    final isShareImageLoading = useState(false);
    final controller = usePageController(initialPage: index);

    AdService adService = AdService();

    // Load ad initially
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) async {
          try {
            final shouldLoadAd = await SharPreferences.shouldLoadAd();

            if (!shouldLoadAd) return;

            debugPrint("Loading ads...");

            // Load other ads with single mounted check
            // _adService.loadRewardedInterstitialAds(() {});

            adService.loadBannerAd(() {});
          } catch (e) {
            debugPrint("Error loading ads: $e");
          }
      });
    });

    Future<void> bookmarkImage(ImageModel imageModel) async {
      ref
          .read(bookmarkSharedPrefBloc)
          .toggleBookMarkImage(imageModel, isWallpaper);
      log('Current Index: ${currentIndex.value}');
      log('Photos Length: ${photos.length}');
      if (!(currentIndex.value < photos.length)) {
        currentIndex.value--;
      }
      if (photos.isEmpty) {
        Get.back();
      }
    }

    void shareImage(ImageModel imageModel) async {
      isShareImageLoading.value = true;
      try {
        final http.Response response =
            await http.get(Uri.parse(imageModel.imageUrl ?? ''));

        final directory = await getApplicationDocumentsDirectory();
        final image = File(
            "${directory.path}/${imageModel.imageId}-${DateTime.now()}.png");
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

        final appPackageName =
            (await PackageInfo.fromPlatform()).packageName;
        String appid = BibleInfo.apple_AppId;
        String appLink = "";

        if (Platform.isAndroid) {
          appLink =
              " \n Read More at: https://play.google.com/store/apps/details?id=$appPackageName";
        } else if (Platform.isIOS) {
          appLink =
              " \n Read More at: https://itunes.apple.com/app/id$appid";
        }

        await Share.shareXFiles(
          [XFile(image.path, mimeType: 'image/png')],
          subject: 'Bible Book app',
          text: appLink,
          sharePositionOrigin: shareOrigin,
        );
      } catch (e) {
        isShareImageLoading.value = false;
        Constants.showToast("Unable to share at the moment");
      }
    }

    void downloadImage(String url) async {
      isDownloading.value = true;
      try {
        final http.Response response = await http.get(Uri.parse(url));
        await [Permission.storage].request();
        final time = DateTime.now()
            .toIso8601String()
            .replaceAll(".", "_")
            .replaceAll(":", "_");
        final name = "Bible_$time";
        await ImageGallerySaverPlus.saveImage(response.bodyBytes, name: name);
        Constants.showToast("Image downloaded successfully");
      } catch (e) {
        Constants.showToast("Failed to download Image");
      }
      isDownloading.value = false;
    }

    final showAd = useState(false);
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
              AppCustomTheme.vintage
          ? BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)), fit: BoxFit.fill))
          : null,
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
                Text(photos.first.imageTitle ?? "",
                    style: CommanStyle.appBarStyle(context)),
                const SizedBox(width: 20)
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: Stack(
                children: [
                  PhotoViewGallery.builder(
                    pageController: controller,
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (context, i) {
                      return PhotoViewGalleryPageOptions(
                          imageProvider: CachedNetworkImageProvider(
                              photos[i].imageUrl ?? ''),
                          initialScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained,
                          heroAttributes: PhotoViewHeroAttributes(tag: i));
                    },
                    itemCount: photos.length,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.transparent),
                    loadingBuilder: (context, event) => Center(
                      child: SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: (event?.cumulativeBytesLoaded ?? 1) /
                              (event?.expectedTotalBytes ?? 1),
                        ),
                      ),
                    ),
                    onPageChanged: (val) {
                      // Update index only if different to prevent unnecessary updates
                      if (val != currentIndex.value) {
                      currentIndex.value = val;
                      }
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 2,
                    right: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // GestureDetector(
                          //   onTap: () {
                          //     bookmarkImage(photos[currentIndex.value]);
                          //   },
                          //   child: Icon(
                          //     Icons.favorite,
                          //     color: bookmarkState.isIdBookMarked(
                          //             photos[currentIndex.value].imageId, isWallpaper)
                          //         ? Colors.red
                          //         : CommanColor.black,
                          //   ),
                          // ),
                          isShareImageLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator.adaptive())
                              : GestureDetector(
                                  onTap: () {
                                    shareImage(photos[currentIndex.value]);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: CommanColor.white,
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Icon(
                                        Icons.share,
                                        color: CommanColor.black,
                                      ),
                                    ),
                                  ),
                                ),
                          if (photos.isNotEmpty)
                            isDownloading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator.adaptive())
                                : GestureDetector(
                                    onTap: () {
                                      if (bookmarkState.isIdBookMarked(
                                          photos[currentIndex.value].imageId,
                                          isWallpaper)) {
                                        deleteConfirmation(
                                          context,
                                          () {
                                            Constants.showToast(
                                                'Successfully Deleted');
                                            Navigator.pop(context);
                                            bookmarkImage(
                                                photos[currentIndex.value]);
                                          },
                                        );
                                      } else {
                                        bookmarkImage(
                                            photos[currentIndex.value]);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: CommanColor.white,
                                          shape: BoxShape.circle),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          bookmarkState.isIdBookMarked(
                                                  photos[currentIndex.value]
                                                      .imageId,
                                                  isWallpaper)
                                              ? Icons.delete
                                              : Icons.cloud_download,
                                          color: bookmarkState.isIdBookMarked(
                                                  photos[currentIndex.value]
                                                      .imageId,
                                                  isWallpaper)
                                              ? Colors.brown
                                              : CommanColor.black,
                                        ),
                                      ),
                                    ),
                                  )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            (!showAd.value && adService.bannerAd != null)
                ? Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: SizedBox(
                      height: adService.bannerAd!.size.height.toDouble(),
                      width: adService.bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: adService.bannerAd!),
                    ),
                  )
                : const SizedBox(height: 12),
            // const SizedBox(height: 5)
          ],
        ),
      ),
    ));
  }
}
