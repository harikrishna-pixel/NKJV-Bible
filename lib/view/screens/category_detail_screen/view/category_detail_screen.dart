import 'dart:async';
import 'dart:developer';

import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/utils/network_error_message.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/bookmark_shared_pref_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/bloc/fetched_images_bloc.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/widget/image_card_widget.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as p;

class CategoryDetailScreen extends StatefulHookConsumerWidget {
  final CategoryModel category;
  final bool isWallpaper;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.isWallpaper,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late ScrollController controller;
  late List<NativeAd> nativeAds;
  bool isAdLoading = false;
  bool isFetchingAds = false;

  Future<void> loadNativeAds() async {
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.nativeAdId);

    // Create a Completer to handle asynchronous ad loading
    Completer<void> adLoadedCompleter = Completer<void>();

    NativeAd nativeAd = NativeAd(
      adUnitId: adUnitId.toString(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          adLoadedCompleter
              .complete(); // Complete the completer once the ad is loaded
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          adLoadedCompleter.completeError(
              error); // Complete the completer with an error if loading fails
        },
      ),
      request: await AdConsentManager.getAdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: CommanColor.darkPrimaryColor,
            style: NativeTemplateFontStyle.monospace,
            size: 16.0),
      ),
    );

    nativeAd.load();

    try {
      // Wait for the ad to be loaded
      await adLoadedCompleter.future;

      // Add the ad to the list
      nativeAds.add(nativeAd);
      log('Ad Loaded');
      // Update the UI if mounted
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      // Handle ad load failure if needed
      log('Failed to load ad: $error');
    }
  }

  Future<void> loadAds() async {
    final shouldLoadAd = await SharPreferences.shouldLoadAd();
    if (shouldLoadAd) {
      if (!isAdLoading && !isFetchingAds) {
        isFetchingAds = true;
        // Ensure ads are fetched in chunks
        const adCount = 5;
        for (int i = 0; i < adCount; i++) {
          await loadNativeAds();
        }
        isFetchingAds = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    nativeAds = [];
    controller = ScrollController();
    loadAds();
    controller.addListener(pageListener);
  }

  void pageListener() {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      ref.read(fetchedPhotosBloc(widget.category)).getPhotos();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(fetchedPhotosBloc(widget.category));
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) {
        ref.read(bookmarkSharedPrefBloc).getBookmarks();
        ref.read(fetchedPhotosBloc(widget.category)).getPhotos(reset: true);
      });
    });

    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: CommanColor.isDarkTheme(context)
            ? BoxDecoration(color: CommanColor.darkPrimaryColor)
            : (p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                    AppCustomTheme.vintage
                ? BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Images.bgImage(context)),
                      fit: BoxFit.fill,
                    ),
                  )
                : null),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 12),
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
                  Text(widget.category.name ?? "",
                      style: CommanStyle.appBarStyle(context)),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 20),
              imageState.isLoading && imageState.photos.isEmpty
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : imageState.photos.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text(
                              kCheckInternetConnectionMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: StaggeredGrid.count(
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          crossAxisCount: screenWidth > 450 ? 3 : 2,
                          children: List.generate(
                            imageState.photos.length +
                                ((imageState.photos.length ~/ 6) * 1),
                            (index) {
                              int adIndex = index ~/ 7;

                              if ((index + 1) % 7 == 0 && index != 0) {
                                if (nativeAds.length > adIndex) {
                                  return StaggeredGridTile.count(
                                    crossAxisCellCount:
                                        screenWidth > 450 ? 3 : 2,
                                    mainAxisCellCount: 1.9,
                                    child: AdWidget(ad: nativeAds[adIndex]),
                                  );
                                } else {
                                  loadAds(); // Load more ads if needed
                                  return StaggeredGridTile.extent(
                                      crossAxisCellCount:
                                          screenWidth > 450 ? 3 : 2,
                                      mainAxisExtent: 0.1,
                                      child: SizedBox.shrink());
                                }
                              }

                              return StaggeredGridTile.count(
                                crossAxisCellCount: screenWidth > 450 ? 1 : 1,
                                mainAxisCellCount: 1.6,
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => ImageDetailScreen(
                                        index: index - adIndex,
                                        category: widget.category,
                                        isWallpaper: widget.isWallpaper,
                                      ),
                                      transition: Transition.cupertinoDialog,
                                      duration:
                                          const Duration(milliseconds: 300),
                                    );
                                  },
                                  child: ImageCardWidget(
                                    url: imageState
                                            .photos[index - adIndex].imageUrl ??
                                        '',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
              if (imageState.isLoading && imageState.photos.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator.adaptive(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
