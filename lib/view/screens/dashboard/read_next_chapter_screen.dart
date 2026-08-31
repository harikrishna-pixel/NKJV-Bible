import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class ReadNextChapterScreen extends StatelessWidget {
  const ReadNextChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                  AppCustomTheme.vintage
              ? BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(Images.bgImage(context)),
                      fit: BoxFit.fill))
              : null,
          child: Column(children: [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: const Image(
                  image: AssetImage("assets/2.jpg"),
                  fit: BoxFit.cover,
                )),
            const SizedBox(
              height: 40,
            ),
            Center(
                child: Text(
              "You're Great",
              style: TextStyle(
                  letterSpacing: BibleInfo.letterSpacing,
                  fontSize: BibleInfo.fontSizeScale * 25,
                  color: CommanColor.whiteLightModePrimary(context),
                  fontWeight: FontWeight.w500),
            )),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: <Widget>[
                  LinearPercentIndicator(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      width: MediaQuery.of(context).size.width * 0.8,
                      lineHeight: 10.0,
                      barRadius: const Radius.circular(10),
                      percent: 0.8,
                      trailing: Text(
                        "80%",
                        style: TextStyle(
                            color: CommanColor.whiteBlack(context),
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: BibleInfo.fontSizeScale * 14),
                      ),
                      progressColor:
                          CommanColor.whiteLightModePrimary(context)),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                      child: Text(
                    "Genesis : Chapter 9 ",
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 15,
                        color: CommanColor.whiteBlack(context),
                        fontWeight: FontWeight.w500),
                  )),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                      child: Text(
                    "Completed !!!",
                    style: TextStyle(
                        letterSpacing: BibleInfo.letterSpacing,
                        fontSize: BibleInfo.fontSizeScale * 15,
                        color: CommanColor.whiteBlack(context),
                        fontWeight: FontWeight.w500),
                  )),
                  const SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    onTap: () {
                      //Get.to(()=>const MarkAsReadScreen());
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 35, vertical: 12),
                        // height:  MediaQuery.of(context).size.height*0.05,
                        // width:  MediaQuery.of(context).size.width*0.5,
                        decoration: BoxDecoration(
                            color: CommanColor.whiteLightModePrimary(context),
                            borderRadius: BorderRadius.circular(40)),
                        child: Text(
                          "Read the next Chapter",
                          style: CommanStyle.pw14500(context),
                        )),
                  ),
                ],
              ),
            ),
          ])),
    );
  }
}
