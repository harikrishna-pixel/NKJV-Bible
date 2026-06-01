import 'dart:io';

import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/utils/rating_dialog_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:biblebookapp/view/widget/home_content_edit_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class ShareAlertBox extends StatelessWidget {
  final String verseTitle;
  final VoidCallback onShareAsText;
  final VoidCallback onShareAsImage;

  const ShareAlertBox({
    super.key,
    required this.verseTitle,
    required this.onShareAsText,
    required this.onShareAsImage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth > 600;

        return Dialog(
          backgroundColor: CommanColor.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            color: Colors.transparent, // Ensure container is transparent
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            width: isTablet ? 400 : double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 50,
                          ),
                          Text(
                            verseTitle,
                            style: TextStyle(
                              fontSize: isTablet ? 19 : 18,
                              fontWeight: FontWeight.w600,
                              color: CommanColor.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Text(
                //   verseTitle,
                //   style: TextStyle(
                //     fontSize: isTablet ? 20 : 16,
                //     fontWeight: FontWeight.w600,
                //     color: CommanColor.black,
                //   ),
                // ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildButton(
                      context,
                      isTablet,
                      label: 'Share as Text',
                      onTap: onShareAsText,
                    ),
                    buildButton(
                      context,
                      isTablet,
                      label: 'Share as Image',
                      onTap: onShareAsImage,
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

  Widget buildButton(BuildContext context, bool isTablet,
      {required String label, required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 16 : 12,
            ),
            backgroundColor: CommanColor.darkPrimaryColor,
            foregroundColor: Colors.black87,
            textStyle: TextStyle(fontSize: isTablet ? 16 : 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: CommanColor.white,fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class ImageBottomSheets extends StatelessWidget {
  final DashBoardController controller;
  final String content;
  final String selectedBook;
  final String selectedChapter;
  final String selectedVerseView;
  const ImageBottomSheets(
      {super.key,
      required this.controller,
      required this.content,
      required this.selectedBook,
      required this.selectedChapter,
      required this.selectedVerseView});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        controller.isImageBannerAdLoaded.value &&
                controller.imageBannerAd != null &&
                controller.adFree.value == false
            ? IgnorePointer(
                child: SizedBox(
                  height: controller.imageBannerAd?.size.height.toDouble(),
                  width: controller.imageBannerAd?.size.width.toDouble(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: AdWidget(ad: controller.imageBannerAd!),
                  ),
                ),
              )
            : SizedBox(height: screenWidth < 380 ? 2 : 100),
        Flexible(
          child: FractionallySizedBox(
            heightFactor: screenWidth < 380
                ? 0.85
                : screenWidth > 450
                    ? 0.82
                    : 0.81,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Screenshot(
                        controller: controller.screenshotController.value,
                        child: GestureDetector(
                          onTap: () {},
                          child: Stack(
                            children: [
                              SizedBox(
                                height: screenWidth < 380
                                    ? MediaQuery.of(context).size.height * 0.735
                                    : screenWidth > 450
                                        ? MediaQuery.of(context).size.height *
                                            0.69
                                        : MediaQuery.of(context).size.height *
                                            0.62,
                                width: MediaQuery.sizeOf(context).width,
                                child: Obx(
                                  () => Image(
                                    image: AssetImage(controller.bgImagesList[
                                        controller.selectedBgImage.value]),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 50,
                                top: 0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: AutoSizeHtmlWidget(
                                        html: content,
                                        maxLines: 16,
                                        maxFontSize: screenWidth < 380
                                            ? BibleInfo.fontSizeScale * 14.5
                                            : screenWidth > 450
                                                ? BibleInfo.fontSizeScale * 31
                                                : controller.fontSize.value -
                                                    0.9,
                                        minFontSize:
                                            screenWidth < 380 ? 11.5 : 10.9,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "$selectedBook ${int.parse(selectedChapter.toString())}:${int.parse(selectedVerseView.toString())}",
                                          style: TextStyle(
                                            color: Colors.black,
                                            letterSpacing:
                                                BibleInfo.letterSpacing,
                                            fontSize: screenWidth > 450
                                                ? BibleInfo.fontSizeScale * 28
                                                : BibleInfo.fontSizeScale * 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.2,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  color: Colors.transparent,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "assets/Icon-1024.png",
                                        height: 28,
                                        width: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        BibleInfo.bible_shortName,
                                        style: TextStyle(
                                          color: const Color(0xFF3E2723),
                                          letterSpacing: BibleInfo.letterSpacing,
                                          fontSize: BibleInfo.fontSizeScale * 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 25,
                        child: InkWell(
                          onTap: () async {
                            await SharPreferences.setString('OpenAd', '1');
                            controller.selectedBgImage.value == 9
                                ? controller.selectedBgImage.value = 0
                                : controller.selectedBgImage.value += 1;
                          },
                          child: Container(
                            height: screenWidth > 450 ? 45 : 25,
                            width: screenWidth > 450 ? 45 : 25,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/next.png",
                                color: Colors.white,
                                height: 15,
                                width: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 25,
                        child: InkWell(
                          onTap: () async {
                            try {
                              await SharPreferences.setString('OpenAd', '1');
                              controller.selectedBgImage.value == 9
                                  ? controller.selectedBgImage.value = 0
                                  : controller.selectedBgImage.value += 1;
                            } catch (e) {
                              // DebugConsole.log("image priv error - $e");
                            }
                          },
                          child: Container(
                            height: screenWidth > 450 ? 45 : 25,
                            width: screenWidth > 450 ? 45 : 25,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/priv.png",
                                color: Colors.white,
                                height: 15,
                                width: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareImageButton(context, "Share"),
                      _buildShareImageButton(context, "Save"),
                      _buildShareImageButton(context, "Close"),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareImageButton(BuildContext context, String label) {
    return SizedBox(
      width: 100,
      height: MediaQuery.of(context).size.width > 450 ? 60 : null,
      child: ElevatedButton(
        onPressed: () async {
          await SharPreferences.setString('OpenAd', '1');
          await SharPreferences.setString('bottom', '1');
          if (controller.adFree.value == false) {
            final countprovider =
                Provider.of<DownloadProvider>(context, listen: false);
            await countprovider.decrementCount(context);
          }
          final image = await controller.screenshotController.value.capture(
            delay: const Duration(milliseconds: 400),
            pixelRatio: MediaQuery.of(context).devicePixelRatio * 2,
          );

          if (image == null) {
            await SharPreferences.setString('bottom', '0');
            return;
          }

          if (label == "Share") {
            // Check and show rating dialog on first share
            final ratingShown =
            await RatingDialogHelper.showRatingDialogOnFirstShare(context);
            if (ratingShown) {
              // Give the rating flow a moment before opening the share sheet
              await Future.delayed(const Duration(milliseconds: 400));
            }
            
            // Image-only share (same as home Verse of the Day); branding is on the image.
            saveAndShare(image, "bible", "", context: context);
            // Track Share event
            AnalyticsService.trackShare();
          } else if (label == "Save") {
            await saveImageIntoLocal(image, context);
          } else {
            await SharPreferences.setString('bottom', '0');
            Navigator.of(context).pop();
          }

          await SharPreferences.setString('bottom', '0');
        },
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            CommanColor.lightDarkPrimary(context),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              letterSpacing: BibleInfo.letterSpacing,
              fontSize: MediaQuery.of(context).size.width > 450
                  ? BibleInfo.fontSizeScale * 17
                  : BibleInfo.fontSizeScale * 14,
            ),
          ),
        ),
      ),
    );
  }
}
