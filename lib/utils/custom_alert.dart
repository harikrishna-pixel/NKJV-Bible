import 'dart:ui';

import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/mark_as_read_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/signup_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BibleAlertBox extends StatelessWidget {
  const BibleAlertBox({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizes - reduced for smaller dialog
    final titleFontSize = screenWidth < 380
        ? 14.0
        : screenWidth > 450
            ? 20.0
            : 16.0;

    final subtitleFontSize = screenWidth < 380
        ? 11.0
        : screenWidth > 450
            ? 15.0
            : 13.0;

    final iconSize = screenWidth < 380
        ? 16.0
        : screenWidth > 450
            ? 20.0
            : 18.0;

    final progressSize = screenWidth < 380
        ? 80.0
        : screenWidth > 450
            ? 100.0
            : 90.0;

    final buttonHeight = screenWidth < 380
        ? 36.0
        : screenWidth > 450
            ? 44.0
            : 38.0;

    // Calculate dialog dimensions - card-style dialog similar to mock
    final dialogWidth = screenWidth < 380
        ? screenWidth * 0.95
        : screenWidth < 600
            ? screenWidth * 0.9
            : 620.0;
    
    // Calculate height to fit content with gentle scrolling on very small screens
    final dialogHeight = screenWidth < 380
        ? screenHeight * 0.72
        : screenWidth < 600
            ? screenHeight * 0.68
            : 720.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: screenWidth > 450 
          ? EdgeInsets.symmetric(horizontal: (screenWidth - dialogWidth) / 2)
          : EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8EFE4),
                  Color(0xFFE7D3BA),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            Get.back();
                          },
                          child: Icon(
                            Icons.close,
                            size: screenWidth < 380 ? 20 : 26,
                            color: const Color(0xFF5C4033),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign In to Save Your Spiritual Journey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4B3423),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Secure Your Progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: subtitleFontSize + 1,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A5A3A),
                      ),
                    ),
                    const SizedBox(height: 18),
                    BibleProgressCircle(
                      progressSize: progressSize,
                      fontSize: subtitleFontSize,
                    ),
                    SizedBox(height: screenWidth < 380 ? 14 : 18),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 450 ? 24 : 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconText(
                              Icons.check, 'Sync reading progress', iconSize, context),
                          const SizedBox(height: 8),
                          _buildIconText(
                              Icons.check, 'Access notes & highlights', iconSize, context),
                          const SizedBox(height: 8),
                          _buildIconText(Icons.check, 'Track your Bible completion',
                              iconSize, context),
                          const SizedBox(height: 8),
                          _buildIconText(Icons.check, 'Secure cloud backup', iconSize,
                              context),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth < 380 ? 10 : 14),
                    Text(
                      'Your data stays private',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth < 380
                            ? 11.0
                            : screenWidth > 450
                                ? 15
                                : 13.0,
                        color: const Color(0xFF4B3423),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenWidth < 380 ? 12 : 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 450 ? 60 : 20),
                      child: SizedBox(
                        height: buttonHeight,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B5842),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Get.to(() => SignupScreen());
                          },
                          child: Text(
                            'Sign In & Save Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 380 ? 13.0 : 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: screenWidth > 450
                            ? 10
                            : screenWidth < 380
                                ? 6
                                : 8),
                    Text(
                      'Your spiritual growth matters. Keep it safe',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: screenWidth > 450
                            ? subtitleFontSize - 1
                            : subtitleFontSize - 2,
                        color: const Color(0xFF6A4A33),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, double iconSize, context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      // crossAxisAlignment: CrossAxisAlignment.center,
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: Colors.brown),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: screenWidth < 380
                  ? 11.0
                  : screenWidth > 450
                      ? 15.0
                      : 13.0,
              color: CommanColor.black,
            ),
          ),
        ),
      ],
    );
  }
}

class BibleProgressCircle extends StatelessWidget {
  final double progressSize;
  final double fontSize;

  const BibleProgressCircle({
    super.key,
    required this.progressSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const ringBrown = Color(0xFF7B5842);
    const ringGold = Color(0xFFC9A227);
    const labelBrown = Color(0xFF4B3423);

    return SizedBox(
      width: progressSize,
      height: progressSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: progressSize,
            height: progressSize,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: progressSize * 0.09,
              backgroundColor: ringBrown.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(ringGold),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bible Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: labelBrown,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.check,
                size: fontSize + 4,
                color: ringGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomAlertBox extends StatelessWidget {
  final String title;
  final String message;
  final List<AlertButton> buttons;

  const CustomAlertBox({
    super.key,
    required this.title,
    required this.message,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CommanColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      Get.back();
                    },
                    child: Icon(
                      Icons.close,
                      size: 25,
                      color: CommanColor.black,
                    ),
                  ),
                ],
              ),
            ),
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: CommanColor.black,
                )),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CommanColor.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttons.map((btn) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5C39), // brown
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: btn.onPressed,
                    child: Text(
                      btn.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertButton {
  final String text;
  final VoidCallback onPressed;

  AlertButton({required this.text, required this.onPressed});
}

// backup,import,export
class BackupDialog extends StatelessWidget {
  final String type; // 'export', 'complete', 'import'
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  const BackupDialog({
    super.key,
    required this.type,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double padding = isTablet ? 32 : 20;
    final double dialogWidth = isTablet ? 400 : double.infinity;

    final content = _buildDialogContent(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: padding),
      backgroundColor: CommanColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: content,
        ),
      ),
    );
  }

  List<Widget> _buildDialogContent(context) {
    switch (type) {
      case 'export':
        return _buildExport(context);
      case 'complete':
        return _buildComplete(context);
      case 'import':
        return _buildImport(context);
      default:
        return [const Text("Unknown Dialog Type")];
    }
  }

  List<Widget> _buildExport(context) {
    return [
      const SizedBox(height: 9),
      _buildImage("assets/folder_e.png"),
      const SizedBox(height: 17),
      const Text(
        "Export Info",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: CommanColor.black,
        ),
      ),
      const SizedBox(height: 17),
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: "Your ",
                style: TextStyle(
                  color: CommanColor.black,
                )),
            TextSpan(
              text: "Bookmarks, Highlights, Underline and Notes",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: CommanColor.black,
              ),
            ),
            TextSpan(
                text: " will be saved to:",
                style: TextStyle(
                  color: CommanColor.black,
                )),
          ],
        ),
        textAlign: TextAlign.left,
      ),
      const SizedBox(height: 12),
      _fileBox(
          "${BibleInfo.bible_shortName}/${BibleInfo.bible_shortName}_Backup.enc"),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              "• Verse images not included",
              style: TextStyle(
                color: CommanColor.black,
              ),
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              "• Save the file to cloud or PC to avoid data loss",
              style: TextStyle(
                color: CommanColor.black,
              ),
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "• ${BibleInfo.autoCloudBackupText}",
              style: const TextStyle(
                color: CommanColor.black,
              ),
            )),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSecondaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.lightGrey1,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "Cancel",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 14,
                        fontWeight: FontWeight.w400,
                        color: CommanColor.black),
                  )),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: onPrimaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.darkPrimaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "Okay, Export",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 14,
                        fontWeight: FontWeight.w500,
                        color: CommanColor.white),
                  )),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildComplete(context) {
    return [
      const SizedBox(height: 12),
      _buildImage("assets/folder_s.png"),
      const SizedBox(height: 17),
      const Text(
        "Backup Complete",
        style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: CommanColor.black),
      ),
      const SizedBox(height: 17),
      Align(
        alignment: Alignment.centerLeft,
        child: const Text(
          "File saved to:",
          textAlign: TextAlign.left,
          style: TextStyle(
            color: CommanColor.black,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _fileBox(
          "${BibleInfo.bible_shortName}/${BibleInfo.bible_shortName}_Backup.enc"),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: const Text(
          "• Verse images not included",
          style: TextStyle(
            color: CommanColor.black,
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: const Text(
          "• Please copy this file to Google Drive, iCloud, or PC for safety",
          style: TextStyle(
            color: CommanColor.black,
          ),
          // textAlign: TextAlign.left,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: const Text(
          "• Also saved to your account when signed in",
          style: TextStyle(
            color: CommanColor.black,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSecondaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.lightGrey1,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "Okay",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 13,
                        fontWeight: FontWeight.w400,
                        color: CommanColor.black),
                  )),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: onPrimaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.darkPrimaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "View Backup",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 13,
                        fontWeight: FontWeight.w500,
                        color: CommanColor.white),
                  )),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
    ];
  }

  List<Widget> _buildImport(context) {
    return [
      const SizedBox(height: 9),
      _buildImage("assets/folder_i.png"),
      const SizedBox(height: 17),
      const Text(
        "Import Info",
        style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: CommanColor.black),
      ),
      const SizedBox(height: 17),
      Text(
        "Select a backup file (${BibleInfo.bible_shortName}_Backup.enc) to restore:",
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: CommanColor.black),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Bookmarks, Highlights, Underline and Notes",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: CommanColor.black),
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              "• Verse images not restored",
              style: TextStyle(
                color: CommanColor.black,
              ),
            )),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSecondaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.lightGrey1,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "Cancel",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 14,
                        fontWeight: FontWeight.w400,
                        color: CommanColor.black),
                  )),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: onPrimaryPressed,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: CommanColor.darkPrimaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                  child: Text(
                    "Select File",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 14,
                        fontWeight: FontWeight.w500,
                        color: CommanColor.white),
                  )),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _fileBox(String path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        path,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: CommanColor.black),
      ),
    );
  }

  Widget _buildImage(String assetPath) {
    return Image.asset(
      assetPath,
      height: 48,
      width: 48,
      fit: BoxFit.contain,
    );
  }
}

class FullScreenAd extends StatelessWidget {
  final String networkimage;
  final String title;
  final String description;
  final String iteamurl;
  final String rededBookName;
  final String readedChapter;
  final String selectedBookChapterCount;

  const FullScreenAd(
      {super.key,
      required this.networkimage,
      required this.title,
      required this.description,
      required this.iteamurl,
      required this.rededBookName,
      required this.readedChapter,
      required this.selectedBookChapterCount});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      // backgroundColor: Colors.black.withValues(alpha: .2),
      body: Stack(
        children: [
          // Glass Blur Background with Image
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  networkimage, // <-- background image
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: screenWidth > 450 ? 22 : 12,
                      sigmaY: screenWidth > 450 ? 22 : 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: .55),
                  ),
                ),
              ],
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Close + Ads tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.off(() => MarkAsReadScreen(
                                ReadedChapter: readedChapter,
                                RededBookName: rededBookName,
                                SelectedBookChapterCount:
                                    selectedBookChapterCount,
                              ));
                        },
                        child: Container(
                          width: screenWidth > 450 ? 30.0 : 22,
                          height: screenWidth > 450 ? 30.0 : 22,
                          decoration: BoxDecoration(
                            color: Colors.white, // background color
                            shape: BoxShape.circle, // makes it round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Ads",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth > 450 ? 20 : 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  screenWidth > 450
                      ? Spacer()
                      : SizedBox(height: screenWidth > 450 ? 45 : 12),

                  // Title & Subtitle
                  Text(
                    title ?? "Bible Word Search",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth > 450 ? 30 : 22,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: screenWidth > 450 ? 19 : 8),
                  Text(
                    description ??
                        "Relax, reflect, and rediscover God’s Word\nin every puzzle.",
                    textAlign: TextAlign.center,
                    maxLines: 2, // limit to 2 lines
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth > 450 ? 26.0 : 14,
                        overflow: TextOverflow.clip),
                  ),

                  const Spacer(),

                  // Main Ad Card with Image
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 12),
                  //   decoration: BoxDecoration(
                  //     color: Colors.black.withOpacity(0.7),
                  //     borderRadius: BorderRadius.circular(16),
                  //     boxShadow: [
                  //       BoxShadow(
                  //           color: Colors.black.withOpacity(0.4),
                  //           blurRadius: 10,
                  //           offset: const Offset(0, 4))
                  //     ],
                  //   ),
                  //   child:
                  // Column(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      networkimage, // <-- main ad image
                      fit: BoxFit.fill,
                      // centerSlice:
                      //     Rect.fromCircle(center: Offset(1, 1), radius: 12),
                      height: screenWidth > 450 ? 430 : 330,
                      width: screenWidth > 450 ? 400 : 300,
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(16),
                  //   child: Column(
                  //     children: const [
                  //       Text(
                  //         "Marberx Publication",
                  //         style: TextStyle(
                  //             color: Colors.white70, fontSize: 12),
                  //       ),
                  //       SizedBox(height: 4),
                  //       Text(
                  //         "BIBLE WORD SEARCH",
                  //         style: TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 20,
                  //             fontWeight: FontWeight.bold),
                  //       ),
                  //       SizedBox(height: 4),
                  //       Text(
                  //         "Large Puzzles Print Book",
                  //         style: TextStyle(
                  //             color: Colors.white70, fontSize: 14),
                  //       ),
                  //     ],
                  //   ),
                  // )
                  //   ],
                  // ),
                  //  ),

                  const Spacer(),

                  // CTA Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 16),
                    ),
                    onPressed: () async {
                      // Get.to(() => MarkAsReadScreen(
                      //       ReadedChapter: readedChapter,
                      //       RededBookName: rededBookName,
                      //       SelectedBookChapterCount: selectedBookChapterCount,
                      //     ));
                      await SharPreferences.setString('OpenAd', '1');
                      if (await canLaunchUrlString(iteamurl)) {
                        launchUrlString(iteamurl,
                                mode: LaunchMode.externalApplication)
                            .then((v) async {
                          await SharPreferences.setString('OpenAd', '1');
                          Get.off(() => MarkAsReadScreen(
                                ReadedChapter: readedChapter,
                                RededBookName: rededBookName,
                                SelectedBookChapterCount:
                                    selectedBookChapterCount,
                              ));
                        });
                      }
                      await SharPreferences.setString('OpenAd', '1');
                    },
                    child: const Text(
                      "Explore Now",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
