import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel = 'Continue Reading',
    this.onButtonPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;

  void _continueReading() {
    Get.offAll(
      () => HomeScreen(
        From: "Go to Read",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ),
      transition: Transition.cupertinoDialog,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = CommanColor.lightDarkPrimary(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = CommanColor.isDarkTheme(context);
    final titleColor = isDark ? Colors.white : primary;
    final subtitleColor =
        isDark ? Colors.white.withOpacity(0.88) : primary.withOpacity(0.85);
    final iconColor = isDark ? Colors.white : primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: screenWidth > 450 ? 72 : 64,
                  color: iconColor,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale *
                        (screenWidth > 450 ? 26 : 22),
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _OrnamentDivider(color: iconColor),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    letterSpacing: BibleInfo.letterSpacing,
                    fontSize: BibleInfo.fontSizeScale *
                        (screenWidth > 450 ? 16 : 14),
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onButtonPressed ?? _continueReading,
                icon: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  buttonLabel,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: BibleInfo.fontSizeScale * 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: color.withOpacity(0.35), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.diamond, size: 8, color: color.withOpacity(0.5)),
        ),
        Expanded(
          child: Divider(color: color.withOpacity(0.35), thickness: 1),
        ),
      ],
    );
  }
}
