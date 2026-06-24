import 'package:biblebookapp/view/screens/dashboard/constants.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';

class CommanColor {
  static const darkPrimaryColor = Color(0xFF745248);
  static const darkPrimaryColor200 = Color(0xFFA2786C);
  static const lightGrey = Color(0xFFB6B5B5);
  static const lightGrey1 = Color.fromARGB(255, 213, 213, 213);
  static const white = Color(0xFFFFFFFF);
  static const black = Colors.black;
  static const lightModePrimary = Color(0xFF805531);
  static const lightModePrimary200 = Color(0xFFab8d6f);
  static const backgrondcolor = Color(0xffFFF6E8);

  static bool isDarkTheme(BuildContext context) =>
      Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

  static Color lightDarkPrimary(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? darkPrimaryColor
        : lightModePrimary;
  }

  static Color lightDarkPrimary200(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? darkPrimaryColor200
        : lightModePrimary200;
  }

  static Color lightDarkPrimary300(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? white
        : lightModePrimary200;
  }

  static Color calendarSelectedColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0xFF3A2923)
        : lightModePrimary;
  }

  static Color whiteBlack45(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? Colors.white
        : Colors.black45;
  }

  static Color Blackwhite(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? Colors.black
        : Colors.white;
  }

  static Color Blackwhite100(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? Colors.white12
        : Colors.grey.shade300;
  }

  static Color whiteBlack(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark
        ? Colors.white
        : Colors.black;
  }

  /// Text on solid custom backgrounds (yellow/white themes) stays dark even in dark mode.
  static Color contentTextColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider.currentCustomTheme != AppCustomTheme.vintage) {
      return Colors.black;
    }
    return whiteBlack(context);
  }

  static Color container(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color.fromARGB(255, 121, 90, 43)
        : const Color.fromARGB(255, 52, 130, 90);
  }

  static Color chapter(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? Colors.black
        : Colors.white;
  }

  static Color backgr(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color.fromARGB(255, 79, 74, 74)
        : const Color.fromARGB(255, 184, 46, 147);
  }

  static Color weekendColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0XFFD5B900)
        : const Color.fromARGB(255, 189, 13, 13);
  }

  static Color whiteAndDark(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0xFF4A342B)
        : Colors.white;
  }

  static Color progressFillColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0xFFE5DF0D)
        : const Color(0xFF805531);
  }

  static Color progressUnFillColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0xFF3A2923)
        : const Color(0xFF787167);
  }

  static Color whiteLightModePrimary(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? CommanColor.white
        : CommanColor.lightModePrimary;
  }

  static Color darkModePrimaryWhite(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? CommanColor.darkPrimaryColor
        : CommanColor.white;
  }

  static Color primaryShadow(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0x66745248)
        : const Color(0x66805531);
  }

  static Color inDarkWhiteAndInLightPrimary(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? Colors.white
        : CommanColor.lightModePrimary;
  }

  static Color yellowAndLightPrimary(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const Color(0xFFE5DF0D)
        : CommanColor.lightModePrimary;
  }
  // static Color lightPrimaryAndBlack(BuildContext context) {
  //   return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark ?  Colors.black:  CommanColor.lightModePrimary ;
  // }
}

class CommanStyle {
  static TextStyle appBarStyle(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            overflow: TextOverflow.ellipsis,
            fontSize: BibleInfo.fontSizeScale * 18,
            fontWeight: FontWeight.w600)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 18,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w600);
  }

  static TextStyle themedAppBarStyle(BuildContext context) {
    return TextStyle(
      color: CommanColor.contentTextColor(context),
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 18,
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle bw14400(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w400)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w400);
  }

  static TextStyle bw14500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500);
  }

  // static TextStyle bw14500WithUnderline(BuildContext context) {
  //   return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark ? TextStyle(color: Colors.white,letterSpacing: BibleInfo.letterSpacing ,  fontSize: BibleInfo.fontSizeScale * 14,fontWeight: FontWeight.w500,decoration: TextDecoration.underline) :TextStyle(color: Colors.black,letterSpacing: BibleInfo.letterSpacing ,  fontSize: BibleInfo.fontSizeScale * 14,fontWeight: FontWeight.w500,decoration: TextDecoration.underline);
  // }
  static TextStyle bw16500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w500);
  }

  static TextStyle bw17500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 17,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 17,
            fontWeight: FontWeight.w500);
  }

  static TextStyle bw15400(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w400)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w400);
  }

  static TextStyle bw18400(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 18,
            fontWeight: FontWeight.w400)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 20,
            fontWeight: FontWeight.w400);
  }

  static TextStyle bw22500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 22,
            fontWeight: FontWeight.w400,
          )
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 22,
            fontWeight: FontWeight.w400);
  }

  static TextStyle bw20500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 20,
            fontWeight: FontWeight.w500,
          )
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 20,
            fontWeight: FontWeight.w500);
  }

  static TextStyle bw15500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline);
  }

  static TextStyle bw15500wU(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500,
          )
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500,
          );
  }

  static TextStyle bw12400(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 12,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 12,
            fontWeight: FontWeight.w500);
  }

  static TextStyle bw14500WithBgColor(BuildContext context, Color? bgColor) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500,
            backgroundColor: bgColor,
            height: 1.5)
        : TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500,
            backgroundColor: bgColor,
            height: 1.5,
          );
  }

  static TextStyle pw14500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.lightModePrimary,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: CommanColor.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500);
  }

  static TextStyle bothPrimary16600(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.darkPrimaryColor,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w600)
        : const TextStyle(
            color: CommanColor.lightModePrimary,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w600);
  }

  static TextStyle bothPrimary14500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.darkPrimaryColor,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: CommanColor.lightModePrimary,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500);
  }

  static TextStyle inDarkPrimaryInLightWhite12400(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.darkPrimaryColor,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 12,
            fontWeight: FontWeight.w400)
        : const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 12,
            fontWeight: FontWeight.w400);
  }

  static TextStyle inDarkPrimaryInLightWhite15500(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.darkPrimaryColor,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500)
        : const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 15,
            fontWeight: FontWeight.w500);
  }

  static const darkPrimary14500 = TextStyle(
      color: CommanColor.darkPrimaryColor,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 14,
      fontWeight: FontWeight.w500);
  static const darkPrimary16600 = TextStyle(
      color: CommanColor.darkPrimaryColor,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 16,
      fontWeight: FontWeight.w600);
  static const grey16600 = TextStyle(
      color: CommanColor.lightGrey,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 16,
      fontWeight: FontWeight.w600);
  static const grey13400 = TextStyle(
      color: CommanColor.lightGrey,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 13,
      fontWeight: FontWeight.w400);
  static const white16600 = TextStyle(
      color: CommanColor.white,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 16,
      fontWeight: FontWeight.w600);
  static const white18400 = TextStyle(
      color: CommanColor.white,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 18,
      fontWeight: FontWeight.w400);
  static const white14500 = TextStyle(
      color: CommanColor.white,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 14,
      fontWeight: FontWeight.w500);
  static const white12400 = TextStyle(
      color: CommanColor.white,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 12,
      fontWeight: FontWeight.w400);
  static const black16500 = TextStyle(
      color: CommanColor.black,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 16,
      fontWeight: FontWeight.w500);
  static const black14500 = TextStyle(
      color: CommanColor.black,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 14,
      fontWeight: FontWeight.w500);
  static const black15400 = TextStyle(
      color: CommanColor.black,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 15,
      fontWeight: FontWeight.w400);
  static const black18500 = TextStyle(
      color: CommanColor.black,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 18,
      fontWeight: FontWeight.w500);
  static const black18400 = TextStyle(
      color: CommanColor.black,
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: BibleInfo.fontSizeScale * 18,
      fontWeight: FontWeight.w400);

  static TextStyle bw14500withBgColor(BuildContext context, int index,
      selectedIndex, double? fontSize, String? fontFamily) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor:
                index == selectedIndex ? Colors.black54 : Colors.transparent,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily)
        : TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: index == selectedIndex
                ? const Color(0x80605749)
                : Colors.transparent,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily);
  }

  static TextStyle bw14500withBgColorAndUnderLine(BuildContext context,
      int index, selectedIndex, double? fontSize, String? fontFamily) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor:
                index == selectedIndex ? Colors.black54 : Colors.transparent,
            decoration: TextDecoration.underline)
        : TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: index == selectedIndex
                ? const Color(0x80605749)
                : Colors.transparent,
            decoration: TextDecoration.underline);
  }

  static TextStyle bw14500withColor(
      BuildContext context, int? color, double? fontSize, String? fontFamily) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: color != null ? Color(color) : null)
        : TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: color != null ? Color(color) : null,
          );
  }

  static TextStyle bw14500withColorWithUnderLine(
      BuildContext context, int color, double? fontSize, String? fontFamily) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: Color(color),
            decoration: TextDecoration.underline)
        : TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            height: 1.2,
            backgroundColor: Color(color),
            decoration: TextDecoration.underline);
  }

  static TextStyle searchTextStyle(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: CommanColor.darkPrimaryColor,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500,
            backgroundColor: Colors.white)
        : const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 14,
            fontWeight: FontWeight.w500,
            backgroundColor: CommanColor.lightModePrimary
            // background: Paint()..color =  CommanColor.lightModePrimary
            //   ..strokeJoin = StrokeJoin.round
            //   ..strokeCap = StrokeCap.round
            //   ..style = PaintingStyle.stroke
            //   ..strokeWidth = 10.0,
            );
  }

  static TextStyle HighLightWordStyle(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
            backgroundColor: CommanColor.darkPrimaryColor)
        : const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
            backgroundColor: CommanColor.lightModePrimary);
  }

  static TextStyle bwWithChangeFont(
      BuildContext context, double? fontSize, String? fontFamily) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily)
        : TextStyle(
            color: Colors.black,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * (fontSize ?? 14),
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily);
  }

  static TextStyle placeholderText(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? const TextStyle(
            color: Colors.white,
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w400,
          )
        : const TextStyle(
            color: Color(0xFF51493D),
            letterSpacing: BibleInfo.letterSpacing,
            fontSize: BibleInfo.fontSizeScale * 16,
            fontWeight: FontWeight.w400,
          );
  }
}
