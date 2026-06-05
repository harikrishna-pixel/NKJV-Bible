import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/more_apps/bloc/more_app_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart' as p;

class MoreAppsScreen extends HookConsumerWidget {
  const MoreAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(moreAppBloc);
    final hasShownToast = useRef(false);

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(moreAppBloc).getApps(reset: true);
        // Reset toast flag when starting to load
        hasShownToast.value = false;
      });
    });
    
    // Monitor loading state and show toast if loading takes too long
    useEffect(() {
      if (appState.isLoading && appState.apps.isEmpty && !hasShownToast.value) {
        bool cancelled = false;
        Future.delayed(const Duration(seconds: 3), () async {
          if (!cancelled && appState.isLoading && appState.apps.isEmpty && !hasShownToast.value) {
            final hasInternet = await InternetConnection().hasInternetAccess;
            if (!hasInternet) {
              Constants.showToast('No Internet Connection');
            } else {
              Constants.showToast('Check Your Internet Connection');
            }
            hasShownToast.value = true;
          }
        });
        return () {
          cancelled = true;
        };
      }
      return null;
    }, [appState.isLoading, appState.apps.isEmpty]);

    double screenWidth = MediaQuery.of(context).size.width;
    debugPrint("sz current width - $screenWidth ");

    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
              AppCustomTheme.vintage
          ? BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)), fit: BoxFit.fill))
          : null,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () async {
                    Get.back();
                    await SharPreferences.setString('OpenAd', '1');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: screenWidth > 450 ? 30 : 17,
                      color: CommanColor.whiteBlack(context),
                    ),
                  ),
                ),
                Text.rich(TextSpan(
                    text: 'More Apps',
                    style: screenWidth > 450
                        ? CommanStyle.appBarStyle(context)
                            .copyWith(fontSize: 29)
                        : CommanStyle.appBarStyle(context),
                    children: [
                      TextSpan(
                        text: '  Ads',
                        style: CommanStyle.appBarStyle(context).copyWith(
                          fontSize: BibleInfo.fontSizeScale * 12,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    ])),
                const SizedBox(width: 35)
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            appState.isLoading && appState.apps.isEmpty
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  )
                : Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: appState.apps.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: screenWidth > 450 ? 0.74 : 0.72,
                          crossAxisCount: screenWidth > 450 ? 3 : 2),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () async {
                          await SharPreferences.setString('OpenAd', '1');
                          if (await canLaunchUrlString(
                              appState.apps[index].appurl)) {
                            launchUrlString(appState.apps[index].appurl,
                                    mode: LaunchMode.externalApplication)
                                .then((v) async {
                              await SharPreferences.setString('OpenAd', '1');
                            });
                          }
                          await SharPreferences.setString('OpenAd', '1');
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                          decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    offset: Offset(3, 3),
                                    color: CommanColor.darkPrimaryColor)
                              ],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  width: 2,
                                  color: CommanColor.darkPrimaryColor),
                              color: Colors.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                    appState.apps[index].thumburl),
                              ),
                              screenWidth > 450 ? Spacer() : const SizedBox(),
                              Text(
                                appState.apps[index].appName,
                                maxLines: 1,
                                style: CommanStyle.appBarStyle(context)
                                    .copyWith(
                                        color: CommanColor.lightDarkPrimary(
                                            context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: BibleInfo.fontSizeScale *
                                                    screenWidth >
                                                450
                                            ? 14
                                            : 12),
                                textAlign: TextAlign.center,
                              ),
                              const Spacer(),
                              Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: CommanColor.whiteLightModePrimary(
                                        context),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5)),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26, blurRadius: 2)
                                    ],
                                  ),
                                  child: Center(
                                      child: Text(
                                    'Click Here',
                                    style: TextStyle(
                                        letterSpacing: BibleInfo.letterSpacing,
                                        fontSize: BibleInfo.fontSizeScale *
                                                    screenWidth >
                                                450
                                            ? 17
                                            : 12,
                                        fontWeight: FontWeight.w500,
                                        color: CommanColor.darkModePrimaryWhite(
                                            context)),
                                  ))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ));
  }
}

