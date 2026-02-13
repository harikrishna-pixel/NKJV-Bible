import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';

class Images {
  static String bgImage(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/night_mode.png'
        : 'assets/lightMode/day_bg.png';
  }

  static String home(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/home.png'
        : 'assets/lightMode/icons/home.png';
  }

  static String reading(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/reading_book.png'
        : 'assets/lightMode/icons/reading_book.png';
  }

  static String daily(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/daily_verse.png'
        : 'assets/lightMode/icons/daily_verse.png';
  }

  static String wallpaper = 'assets/wallpaper.png';
  static String quote = 'assets/quote.png';

  static String myLibrary(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/mylibarary.png'
        : 'assets/lightMode/icons/my_library.png';
  }

  static String setting(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/settings_1.png'
        : 'assets/lightMode/icons/settings.png';
  }

  static String feedback(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/feedback.png'
        : 'assets/lightMode/icons/feedback.png';
  }

  static String share(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/share.png'
        : 'assets/lightMode/icons/share-1.png';
  }

  static String rateUs(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/ratesus.png'
        : 'assets/lightMode/icons/rates_us.png';
  }

  static String aboutUs(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/about.png'
        : 'assets/lightMode/icons/about_us.png';
  }

  static String search(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/search.png'
        : 'assets/lightMode/icons/search.png';
  }

  static String notificationBell(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/nightMode/icons/bell.png'
        : 'assets/lightMode/icons/bell.png';
  }

  static String appLogo(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/lightMode/icons/logo.png'
        : 'assets/lightMode/icons/logo.png';
  }

  static String adFree(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/icons/crown.png'
        : 'assets/icons/crown.png';
  }

  static String bookmarkPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/Path 45.png'
        : 'assets/dark_modes/Path 45.png';
  }

  static String wallpaperPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/dark_modes/Wallpaper.png'
        : 'assets/dark_modes/Wallpaper.png';
  }

  static String quotesPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/Quotes.png'
        : 'assets/dark_modes/Quotes.png';
  }


  static String highlightsPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/Highlights.png'
        : 'assets/dark_modes/Highlights.png';
  }

  static String notesPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/stickynote.png'
        : 'assets/dark_modes/stickynote.png';
  }

  static String underlinePlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/underline.png'
        : 'assets/dark_modes/underline.png';
  }

  static String imagesPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/dark_modes/image (2).png'
        : 'assets/dark_modes/image (2).png';
  }

  static String searchPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/light_modes/Union.png'
        : 'assets/dark_modes/new_search.png';
  }

  static String aboutPlaceHolder(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? 'assets/lightMode/images/about.png'
        : 'assets/nightMode/images/about.png';
  }
}
