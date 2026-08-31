import 'package:biblebookapp/constant/size_config.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'dart:core';
import '../../constants/colors.dart';
import '../../constants/images.dart';
import '../../constants/share_preferences.dart';

class FontType extends StatefulWidget {
  const FontType({super.key});

  @override
  State<FontType> createState() => _FontTypeState();
}

class _FontTypeState extends State<FontType> {
  List<String> itemlist = [
    "Arial",
    "Verdana",
    "Tahoma",
    "Trebuchet MS",
    "Times New Roman",
    "Georgia",
    "Garamond",
    "Courier New",
    "Brush Script MT",
    "Courier",
    "Alnile",
    "Avenir LT Std 65 Medium",
  ];
  int fonttap = 0;
  final double _value = 10;
  double fontSize = Sizecf.scrnWidth! > 450 ? 25.0 : 18.0;
  var fontSizeS;

  var selectedFontFamily;

  @override
  void initState() {
    super.initState();
    getSelectedFont();
  }

  getSelectedFont() async {
    Future.delayed(
      Duration.zero,
      () async {
        setState(() {
          fontSizeS =
              SharPreferences.getString(SharPreferences.selectedFontSize)
                  .then((value) {
            fontSize = Sizecf.scrnWidth! > 450
                ? double.parse(value ?? "25.0")
                : double.parse(value ?? "18");
          });
          SharPreferences.getString(SharPreferences.selectedFontFamily)
              .then((value) {
            selectedFontFamily = value ?? "Arial";
          });
        });
      },
    );
  }

  Future<void> _saveFontSettings({bool popAfterSave = true}) async {
    await SharPreferences.setString(
      SharPreferences.selectedFontSize,
      fontSize.toString(),
    );
    await SharPreferences.setString(
      SharPreferences.selectedFontFamily,
      (selectedFontFamily ?? "Arial").toString(),
    );
    Constants.showToast("Font settings saved");
    if (popAfterSave && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // debugPrint("sz current width - $screenWidth ");
    return Scaffold(
      body: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 15),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.fill))
            : null,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 2,
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Font Type",
                      textAlign: TextAlign.center,
                      style: CommanStyle.appBarStyle(context),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    "Please adjust to your preferred reading size below",
                    textAlign: TextAlign.center,
                    style: CommanStyle.bwWithChangeFont(
                        context, fontSize, selectedFontFamily),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Font Size",
                            textAlign: TextAlign.left,
                            style: CommanStyle.bw16500(context),
                          )),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("A-"),
                        Container(
                          padding: EdgeInsets.zero,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: SliderTheme(
                            data: SliderThemeData(
                                thumbColor:
                                    CommanColor.lightDarkPrimary(context),
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 6)),
                            child: Slider(
                              divisions: 100,
                              inactiveColor: Colors.black38,
                              activeColor:
                                  CommanColor.whiteLightModePrimary(context),
                              value: fontSize,
                              onChanged: (double s) {
                                SharPreferences.setString(
                                    SharPreferences.selectedFontSize,
                                    s.toString());
                                setState(() {
                                  print(s);
                                  if (s > 12) {
                                    fontSize = s;
                                  }
                                });
                              },
                              min: screenWidth > 450 ? 25.0 : 12.0,
                              max: screenWidth > 450 ? 40 : 34.0,
                            ),
                          ),
                        ),
                        const Text("A+"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                height: 30,
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      "Select Font",
                      style: CommanStyle.white14500,
                    )
                  ],
                ),
              ),
              Expanded(
                flex: screenWidth < 380
                    ? 6
                    : screenWidth > 450
                        ? 7
                        : 7,
                child: ListView.builder(
                  itemCount: itemlist.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedFontFamily = itemlist[index];
                          SharPreferences.setString(
                              SharPreferences.selectedFontFamily,
                              selectedFontFamily);
                          fonttap = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                itemlist[index],
                                style: CommanStyle.bw16500(context),
                              ),
                              selected: true,
                              horizontalTitleGap: 0,
                              contentPadding: const EdgeInsets.only(left: 10),
                              trailing: selectedFontFamily == itemlist[index]
                                  ? Icon(
                                      Icons.done_outline,
                                      color: CommanColor.whiteBlack(context),
                                      size: 25,
                                      weight: 24,
                                    )
                                  : const SizedBox(),
                            ),
                            SizedBox(
                                height: 2,
                                child: Divider(
                                  thickness: 0.5,
                                  color: CommanColor.whiteBlack(context),
                                ))
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  screenWidth < 380
                      ? 10
                      : screenWidth > 450
                          ? 28
                          : 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            fontSizeS = SharPreferences.setString(
                                    SharPreferences.selectedFontSize,
                                    Sizecf.scrnWidth! > 450 ? "25.0" : "18")
                                .then((value) {
                              fontSize = Sizecf.scrnWidth! > 450
                                  ? double.parse("25.0")
                                  : double.parse("18");
                            });
                            SharPreferences.setString(
                                    SharPreferences.selectedFontFamily, "Arial")
                                .then((value) {
                              selectedFontFamily = "Arial";
                            });
                          });
                          Constants.showToast("Reset Successful!");
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(9)),
                            border: Border.all(
                              color: CommanColor.whiteLightModePrimary(context),
                              width: 1.4,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Reset to default',
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: screenWidth < 380 ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: CommanColor.whiteLightModePrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _saveFontSettings(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: CommanColor.whiteLightModePrimary(context),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(9)),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 2)
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Save',
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CommanColor.darkModePrimaryWhite(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
