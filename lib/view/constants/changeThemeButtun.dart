import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangeThemeButtonWidget extends StatelessWidget {
  const ChangeThemeButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");
    SavePreference pre = SavePreference();
    if (themeProvider.isDarkMode) {
      return InkWell(
          onTap: () {
            final provider = Provider.of<ThemeProvider>(context, listen: false);
            provider.toggleTheme(false);
            pre.setTheme("light");
          },
          child: Image.asset(
            "assets/dark_modes/Dark mode.png",
            height: screenWidth > 450 ? 30 : 20,
            width: screenWidth > 450 ? 34 : 24,
          ));
    } else {
      return InkWell(
          onTap: () {
            final provider = Provider.of<ThemeProvider>(context, listen: false);
            provider.toggleTheme(true);
            pre.setTheme("dark");
          },
          child: Image.asset("assets/light_modes/Light mode.png",
              height: screenWidth > 450 ? 30 : 20,
              width: screenWidth > 450 ? 34 : 24));
    }
    // return Switch.adaptive(
    //   value: themeProvider.isDarkMode,
    //   onChanged: (value) {
    //     final provider = Provider.of<ThemeProvider>(context, listen: false);
    //     provider.toggleTheme(value);
    //   },
    //);
  }
}
