import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutUpdateScreen extends StatelessWidget {
  const AboutUpdateScreen({super.key});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width * 0.9,
                child: const Image(
                  image: AssetImage("assets/Artboard2.png"),
                  fit: BoxFit.fill,
                )),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.06,
                      width: MediaQuery.of(context).size.width * 0.12,
                      child: Image(
                        image: AssetImage("assets/Artboard1.png"),
                        fit: BoxFit.fill,
                      )),
                  Text(
                    "About Update",
                    style: CommanStyle.bw17500(context),
                  ),
                  Text(
                    "v 1.2.6 ",
                    style: CommanStyle.bw16500(context),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "1.Fix some bugs",
              style: CommanStyle.bw15400(context),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "2.New navigation interaction",
              style: CommanStyle.bw15400(context),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "3.Improve loading experience ",
              style: CommanStyle.bw15400(context),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.05,
              decoration: BoxDecoration(
                color: CommanColor.lightDarkPrimary(context),
                border: Border.all(color: Colors.transparent, width: 1.5),
                borderRadius: BorderRadiusDirectional.circular(50),
              ),
              child: Center(
                  child: Text(
                "Update",
                style: CommanStyle.white18400,
              )),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.05,
              decoration: BoxDecoration(
                color: CommanColor.Blackwhite100(context),
                border: Border.all(color: Colors.transparent, width: 1.5),
                borderRadius: BorderRadiusDirectional.circular(50),
              ),
              child: Center(
                  child: Text(
                "Try Later",
                style: CommanStyle.black18400,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
