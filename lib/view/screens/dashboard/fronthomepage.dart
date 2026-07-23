import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/Search.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/dailyverse.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/myLibrary.dart';
import 'package:biblebookapp/view/screens/dashboard/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeFrontPage extends StatefulWidget {
  const HomeFrontPage({super.key});

  @override
  State<HomeFrontPage> createState() => _HomeFrontPageState();
}

class _HomeFrontPageState extends State<HomeFrontPage> {
  @override
  Widget build(BuildContext context) {
    var bibleName = BibleInfo.bible_shortName;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 250,
              color: const Color.fromARGB(255, 2, 64, 114),
              child: Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/Logo.png',
                        height: 110,
                        width: 110,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        bibleName,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 25,
                            color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 152, 31, 71),
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Bible',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/Bible.png'),
                            iconSize: 45,
                            onPressed: () {
                              Get.offAll(() => HomeScreen(
                                  From: "splash",
                                  selectedVerseNumForRead: "",
                                  selectedBookForRead: "",
                                  selectedChapterForRead: "",
                                  selectedBookNameForRead: "",
                                  selectedVerseForRead: ""));
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Daily Verse',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/verse.png'),
                            iconSize: 45,
                            onPressed: () {
                              Get.to(() => const DailyVerse(),
                                  transition: Transition.cupertinoDialog,
                                  duration: const Duration(milliseconds: 300));
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Search',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/search.png'),
                            iconSize: 45,
                            onPressed: () {
                              Get.to(() => SearchScreen(),
                                  transition: Transition.cupertinoDialog,
                                  duration: const Duration(milliseconds: 300));
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                          color: Colors.brown,
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Quotes',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/quotes.png'),
                            iconSize: 45,
                            onPressed: () {},
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 81, 160, 83),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Videos',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/video.png'),
                            iconSize: 45,
                            onPressed: () {},
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Wallpaper',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/Wallpaper.png'),
                            iconSize: 45,
                            onPressed: () {},
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'My Library',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/My Library.png'),
                            iconSize: 45,
                            onPressed: () {
                              Get.to(() => LibraryScreen(),
                                      transition: Transition.cupertinoDialog,
                                      duration:
                                          const Duration(milliseconds: 300))!
                                  .then((value) {});
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Settings',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/Settings.png'),
                            iconSize: 45,
                            onPressed: () {
                              SharPreferences.getBoolean(
                                      SharPreferences.isNotificationOn)
                                  .then((value) {
                                // Default OFF when unset so denied permission
                                // never opens Settings toggles as ON.
                                final natificationValue = value ?? false;
                                Get.to(() => SettingScreen(
                                      notificationValue: natificationValue,
                                    ));
                              });
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Container(
                      height: 120,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 237, 104, 22),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'Feedback',
                            style: TextStyle(
                                letterSpacing: BibleInfo.letterSpacing,
                                fontSize: BibleInfo.fontSizeScale * 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconButton(
                            icon: Image.asset('assets/homeicon/Feedback.png'),
                            iconSize: 45,
                            onPressed: () async {
                              const url =
                                  'https://bibleoffice.com/m_feedback/API/feedback_form/index.php';
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else {
                                throw 'Could not launch $url';
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
