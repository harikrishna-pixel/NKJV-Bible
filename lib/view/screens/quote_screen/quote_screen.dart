import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/quote_screen/bloc/quotes_category_bloc.dart';
import 'package:biblebookapp/view/widget/category_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart' as p;

class QuoteScreen extends HookConsumerWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesState = ref.watch(quotesCategoryBloc).quotesCategoryState;
    final hasShownToast = useRef(false);
    final hasCheckedNetwork = useRef(false);
    
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) {
        ref.read(quotesCategoryBloc).getQuotesCategory();
        // Track Quotes event
        StatsigService.trackQuotes();
        // Reset toast flag when starting to load
        hasShownToast.value = false;
        hasCheckedNetwork.value = false;
      });
    });
    
    // Monitor loading state and show toast if loading takes too long
    // Increased delay for real devices where first network request can take longer
    useEffect(() {
      if (quotesState.isLoading && !hasShownToast.value) {
        bool cancelled = false;
        // Add initial delay to account for network initialization on real devices
        Future.delayed(const Duration(seconds: 1), () {
          if (!cancelled && quotesState.isLoading && !hasShownToast.value) {
            // Then wait additional 5 seconds before showing toast (total 6 seconds)
            Future.delayed(const Duration(seconds: 5), () {
              if (!cancelled && quotesState.isLoading && !hasShownToast.value) {
                Constants.showToast('Check Your Internet Connection');
                hasShownToast.value = true;
              }
            });
          }
        });
        return () {
          cancelled = true;
        };
      }
      return null;
    }, [quotesState.isLoading]);
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
                Text("Quotes", style: CommanStyle.appBarStyle(context)),
                const SizedBox(width: 20)
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Expanded(
              child: quotesState.when(
                data: (data) {
                  // Check network speed if data is empty and haven't checked yet
                  if (data.isEmpty && !hasCheckedNetwork.value) {
                    hasCheckedNetwork.value = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final hasInternet = await InternetConnection().hasInternetAccess;
                      if (!hasInternet) {
                        Constants.showToast('No Internet Connection');
                        return;
                      }
                      
                      try {
                        final connectionSpeed = await InternetSpeedChecker.checkSpeed(
                          timeout: const Duration(seconds: 5),
                        );
                        
                        // If connection speed is null or very slow (>5000ms), treat as 2G/low network
                        final isSlowConnection = connectionSpeed == null || connectionSpeed > 5000;
                        
                        if (isSlowConnection) {
                          Constants.showToast('Check Your Internet Connection');
                        }
                      } catch (e) {
                        // On error, assume slow connection
                        Constants.showToast('Check Your Internet Connection');
                      }
                    });
                  }
                  
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: data.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.4,
                            crossAxisCount: 2),
                    itemBuilder: (context, index) => CategoryWidget(
                      category: data[index],
                      isWallpaper: false,
                    ),
                  );
                },
                error: (error, st) {
                  return Center(child: Text('Check your Internet connection'));
                },
                loading: () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator.adaptive(),
                          ),
                          Text(
                            "Loading...",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // const Center(
              //     child: CircularProgressIndicator.adaptive())),
            )
          ],
        ),
      ),
    ));
  }
}

