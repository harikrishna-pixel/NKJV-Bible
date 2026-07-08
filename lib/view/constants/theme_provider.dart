import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class ThemeProvider extends ChangeNotifier {
//   SavePreference pre = SavePreference();

//   ThemeProvider() {
//     setInitialTheme();
//   }
// // new method
//   setInitialTheme() {
//     pre.getTheme().then((value) {
//       if (value != "null") {
//         themeMode = (value == "dark") ? ThemeMode.dark : ThemeMode.light;
//       } else {
//         final brightness = SchedulerBinding.instance.window.platformBrightness;
//         print(brightness);
//         themeMode =
//             (brightness == Brightness.light) ? ThemeMode.light : ThemeMode.dark;
//       }
//       notifyListeners();
//     });
//   }

//   ThemeMode themeMode = ThemeMode.system;
//   bool get isDarkMode {
//     if (themeMode == ThemeMode.system) {
//       final brightness = SchedulerBinding.instance.window.platformBrightness;
//       return brightness == Brightness.dark;
//     } else {
//       return themeMode == ThemeMode.dark;
//     }
//   }

//   void toggleTheme(bool isOn) {
//     themeMode = isOn ? ThemeMode.dark : ThemeMode.light;

//     notifyListeners();
//   }
// }

// class MyThemes {
//   static darkTheme(BuildContext context) => ThemeData(
//         scaffoldBackgroundColor: Colors.grey.shade900,
//         primaryColor: Colors.black,
//         colorScheme: ColorScheme.dark(),
//         bottomSheetTheme: BottomSheetThemeData(
//             constraints:
//                 BoxConstraints(minWidth: MediaQuery.sizeOf(context).width)),
//         iconTheme: IconThemeData(color: Colors.purple.shade200, opacity: 0.8),
//       );

//   static lightTheme(BuildContext context) => ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         primaryColor: Colors.white,
//         bottomSheetTheme: BottomSheetThemeData(
//             constraints:
//                 BoxConstraints(minWidth: MediaQuery.sizeOf(context).width)),
//         colorScheme: ColorScheme.light(),
//         iconTheme: IconThemeData(color: Colors.red, opacity: 0.8),
//       );
// }

class MyThemes {
  static ThemeData lightTheme(BuildContext context, Color backgroundColor) =>
      ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: Colors.white,
        bottomSheetTheme: BottomSheetThemeData(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width,
          ),
        ),
        colorScheme: const ColorScheme.light(),
        iconTheme: const IconThemeData(color: Colors.red, opacity: 0.8),
      );

  static ThemeData darkTheme(BuildContext context) => ThemeData(
        scaffoldBackgroundColor: CommanColor.darkPrimaryColor,
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.dark(),
        bottomSheetTheme: BottomSheetThemeData(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.purple.shade200, opacity: 0.8),
      );
}

enum AppCustomTheme {
  vintage,
  white,
  lightbrown,
}

class ThemeProvider extends ChangeNotifier {
  SavePreference pre = SavePreference();

  ThemeProvider() {
    setInitialTheme();
  }

  ThemeMode themeMode = ThemeMode.system;
  AppCustomTheme currentCustomTheme = AppCustomTheme.vintage;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  setInitialTheme() async {
    final savedTheme = await pre.getTheme();
    final savedCustom =
        await pre.getCustomTheme(); // "vintage", "light", "cream"

    if (savedTheme != "null") {
      themeMode = (savedTheme == "dark") ? ThemeMode.dark : ThemeMode.light;
    } else {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      themeMode =
          (brightness == Brightness.light) ? ThemeMode.light : ThemeMode.dark;
    }

    if (savedCustom != null) {
      currentCustomTheme = AppCustomTheme.values.firstWhere(
          (e) => e.toString().split('.').last == savedCustom,
          orElse: () => AppCustomTheme.vintage);
    }

    notifyListeners();
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    pre.setTheme(isOn ? "dark" : "light");
    notifyListeners();
  }

  void setCustomTheme(AppCustomTheme theme) {
    currentCustomTheme = theme;
    pre.setCustomTheme(theme.toString().split('.').last); // Save as string
    notifyListeners();
  }

  Color get backgroundColor {
    switch (currentCustomTheme) {
      case AppCustomTheme.vintage:
        // Match reader cream so route transitions do not flash yellow/brown.
        return const Color(0xFFF5F0E6);
      case AppCustomTheme.white:
        return Colors.white;
      case AppCustomTheme.lightbrown:
        return Color(0xFFFFF8E1);
    }
  }
}

class SavePreference {
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("theme_mode", theme);
  }

  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("theme_mode");
  }

  Future<void> setCustomTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("custom_theme", theme);
  }

  Future<String?> getCustomTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("custom_theme");
  }
}
