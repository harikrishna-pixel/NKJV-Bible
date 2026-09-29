import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrayerAddedSuccessScreen extends StatelessWidget {
  const PrayerAddedSuccessScreen({
    super.key,
    required this.durationDays,
  });

  // Kept so the existing post call is unchanged. Not shown on this screen.
  final int durationDays;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final brown = const Color(0xFF5C4033);
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);

    return PopScope(
      canPop: false,
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
         )
            : BoxDecoration(color: cream),
        child: Scaffold(
          backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Image.asset(
                'assets/prayer_wall/prayer_shared_hands.png',
                height: 210,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                'Your Prayer Is Shared',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: isDark ? Colors.white : brown,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thank you for trusting our community with your prayer. Your prayer has been added to the Prayer Wall.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF6B5E52),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('mine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'View My Prayer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop('wall'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.transparent : const Color(0xFFF8F3EA),
                  foregroundColor: isDark ? Colors.white : brown,
                  side: BorderSide(color: brown, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Back to Prayer Wall',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '“Cast all your anxiety on Him because He cares for you.”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  height: 1.35,
                  color: isDark ? Colors.white70 : brown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1 Peter 5:7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : const Color(0xFF6B5E52),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
        ),
      ),
    ),
    );
  }
}
