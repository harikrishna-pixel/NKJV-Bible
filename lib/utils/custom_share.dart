import 'dart:async';

import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/utils/rating_dialog_helper.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/widget/home_content_edit_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        verseTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 19 : 18,
                          fontWeight: FontWeight.w600,
                          color: CommanColor.black,
                        ),
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

  Widget buildButton(
    BuildContext context,
    bool isTablet, {
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final button = ElevatedButton(
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
        style: const TextStyle(
          color: CommanColor.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: button,
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
  final String shareFooterMessage;
  final bool showNavButtons;
  final double verseTextNudgeDown;
  final bool useFixedVerseBackground;
  const ImageBottomSheets(
      {super.key,
      required this.controller,
      required this.content,
      required this.selectedBook,
      required this.selectedChapter,
      required this.selectedVerseView,
      this.shareFooterMessage = '',
      this.showNavButtons = true,
      this.verseTextNudgeDown = 0,
      this.useFixedVerseBackground = false});

  /// Daily Verses share preview: single verse_image_bg, no background cycling.
  factory ImageBottomSheets.dailyVerse({
    required DashBoardController controller,
    required String content,
    required String selectedBook,
    required String selectedChapter,
    required String selectedVerseView,
    String shareFooterMessage = '',
  }) {
    return ImageBottomSheets(
      controller: controller,
      content: content,
      selectedBook: selectedBook,
      selectedChapter: selectedChapter,
      selectedVerseView: selectedVerseView,
      shareFooterMessage: shareFooterMessage,
      showNavButtons: false,
      verseTextNudgeDown: 0,
      useFixedVerseBackground: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final bottomInset = media.padding.bottom;
    const actionBarHeight = 52.0;
    final actionBarTotalHeight = actionBarHeight + bottomInset + 16;
    final topGap = media.padding.top + kToolbarHeight;
    final availableBelowAppBar = media.size.height - topGap;
    final sheetHeight = screenWidth < 380
        ? availableBelowAppBar * 0.84
        : screenWidth > 450
            ? availableBelowAppBar * 0.80
            : availableBelowAppBar * 0.82;

    Widget buildShareCard() {
      final bgPath = useFixedVerseBackground
          ? 'assets/verse_image_bg.png'
          : controller.bgImagesList[controller.selectedBgImage.value];
      final bgIndex =
          useFixedVerseBackground ? 0 : controller.selectedBgImage.value;

      return VerseShareImageCard(
        backgroundImagePath: bgPath,
        backgroundIndex: bgIndex,
        verseHtml: content,
        verseReference:
            "$selectedBook ${int.parse(selectedChapter.toString())}:${int.parse(selectedVerseView.toString())}",
        screenWidth: screenWidth,
        maxVerseFontSize: screenWidth < 380
            ? BibleInfo.fontSizeScale * 18
            : screenWidth > 450
                ? BibleInfo.fontSizeScale * 30
                : BibleInfo.fontSizeScale * 24,
        minVerseFontSize: screenWidth < 380 ? 14 : 16,
        actionBarReserve: actionBarTotalHeight,
        verseTextNudgeDown: verseTextNudgeDown,
        useSimpleVerseLayout: useFixedVerseBackground,
        centerVerseContent: true,
      );
    }

    Widget buildScreenshotChild() {
      if (useFixedVerseBackground) {
        return buildShareCard();
      }

      return GestureDetector(
        onTap: () async {
          try {
            await SharPreferences.setString('OpenAd', '1');
            controller.selectedBgImage.value == 9
                ? controller.selectedBgImage.value = 0
                : controller.selectedBgImage.value += 1;
          } catch (_) {}
        },
        child: Obx(buildShareCard),
      );
    }

    return SizedBox(
      height: media.size.height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: sheetHeight,
          child: Column(
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
              : const SizedBox(height: 4),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Screenshot(
                  controller: controller.screenshotController.value,
                  child: buildScreenshotChild(),
                ),
                if (showNavButtons) ...[
                  Positioned(
                    left: 12,
                    bottom: actionBarTotalHeight + 8,
                    child: _verseNavButton(
                      screenWidth: screenWidth,
                      icon: Icons.chevron_left,
                      onTap: () async {
                        try {
                          await SharPreferences.setString('OpenAd', '1');
                          controller.selectedBgImage.value == 9
                              ? controller.selectedBgImage.value = 0
                              : controller.selectedBgImage.value += 1;
                        } catch (_) {}
                      },
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: actionBarTotalHeight + 8,
                    child: _verseNavButton(
                      screenWidth: screenWidth,
                      icon: Icons.chevron_right,
                      onTap: () async {
                        await SharPreferences.setString('OpenAd', '1');
                        controller.selectedBgImage.value == 9
                            ? controller.selectedBgImage.value = 0
                            : controller.selectedBgImage.value += 1;
                      },
                    ),
                  ),
                ],
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: actionBarTotalHeight,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.03),
                            Colors.black.withOpacity(0.08),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      14,
                      12,
                      bottomInset + 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildShareImageButton(context, "Share"),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildShareImageButton(context, "Save"),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildShareImageButton(context, "Close"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _verseNavButton({
    required double screenWidth,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final size = screenWidth > 450 ? 45.0 : 36.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.22),
          border: Border.all(
            color: Colors.white.withOpacity(0.85),
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.95),
          size: screenWidth > 450 ? 22 : 18,
        ),
      ),
    );
  }

  Widget _buildShareImageButton(BuildContext context, String label) {
    final icon = switch (label) {
      'Share' => Icons.share_outlined,
      'Save' => Icons.bookmark_border,
      _ => Icons.close,
    };

    void onClose() {
      Navigator.of(context).pop();
      SharPreferences.setString('OpenAd', '1');
      SharPreferences.setString('bottom', '0');
    }

    Future<void> onShareOrSave() async {
      HapticFeedback.lightImpact();
      final showShareLoader = useFixedVerseBackground && label == 'Share';
      if (showShareLoader) {
        EasyLoading.show(
          status: 'Preparing...',
          maskType: EasyLoadingMaskType.clear,
        );
      }

      // Capture first so Share/Save feel instant (avoid blocking on ads/prefs/rating).
      unawaited(SharPreferences.setString('OpenAd', '1'));
      unawaited(SharPreferences.setString('bottom', '1'));

      try {
        // Match reading-screen capture: default pixel ratio (devicePixelRatio * 2 is very slow).
        final image = await controller.screenshotController.value.capture(
          delay: Duration.zero,
        );

        if (showShareLoader) {
          await EasyLoading.dismiss();
        }

        if (image == null) {
          unawaited(SharPreferences.setString('bottom', '0'));
          return;
        }

        if (label == "Share") {
          final imageShareName =
              '${selectedBook}_${selectedChapter}_$selectedVerseView'
                  .replaceAll(RegExp(r'[^\w\-. ]+'), '_')
                  .trim();
          // Await share sheet open so it appears promptly after capture.
          await saveAndShare(
            image,
            imageShareName.isNotEmpty ? imageShareName : 'bible_verse',
            '',
          );
          AnalyticsService.trackShare();
          // Show the "Thanks for the love" popup only after the share sheet closes.
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 400));
            if (context.mounted) {
              await RatingDialogHelper.showRatingDialogOnFirstShare(context);
            }
          }
        } else if (label == "Save") {
          await saveImageIntoLocal(image, context);
        }

        if (controller.adFree.value == false && context.mounted) {
          final countprovider =
              Provider.of<DownloadProvider>(context, listen: false);
          unawaited(countprovider.decrementCount(context));
        }
        unawaited(SharPreferences.setString('bottom', '0'));
      } catch (_) {
        if (showShareLoader) {
          await EasyLoading.dismiss();
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.width > 450 ? 48 : 44,
      child: ElevatedButton(
        onPressed: label == "Close" ? onClose : () => onShareOrSave(),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            const Color(0xFF5C4033).withOpacity(0.72),
          ),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 450 ? 14 : 10,
              vertical: 10,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: MediaQuery.of(context).size.width > 450 ? 18 : 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: MediaQuery.of(context).size.width > 450
                      ? BibleInfo.fontSizeScale * 15
                      : BibleInfo.fontSizeScale * 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
