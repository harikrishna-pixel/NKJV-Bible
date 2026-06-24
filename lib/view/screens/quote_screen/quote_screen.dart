import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/utils/network_error_message.dart';
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
    final emptyStateMessage = useState<String?>(null);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final themeProvider = p.Provider.of<ThemeProvider>(context);
    final isVintageTheme =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((callback) {
        ref.read(quotesCategoryBloc).getQuotesCategory();
        // Track Quotes event
        AnalyticsService.trackQuotes();
        // Reset toast flag when starting to load
        hasShownToast.value = false;
        hasCheckedNetwork.value = false;
        emptyStateMessage.value = null;
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
            Future.delayed(const Duration(seconds: 5), () async {
              if (!cancelled && quotesState.isLoading && !hasShownToast.value) {
                final hasInternet =
                    await InternetConnection().hasInternetAccess;
                if (!hasInternet) {
                  Constants.showToast('No internet connection');
                } else {
                  Constants.showToast(kCheckInternetConnectionMessage);
                }
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
        height: screenSize.height,
        width: screenSize.width,
        decoration: isVintageTheme
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.fill,
                ),
              )
            : BoxDecoration(color: themeProvider.backgroundColor),
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
                        color: CommanColor.contentTextColor(context),
                      ),
                    ),
                  ),
                  Text("Quotes", style: CommanStyle.themedAppBarStyle(context)),
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
                        emptyStateMessage.value = 'No internet connection';
                        Constants.showToast('No internet connection');
                        return;
                      }
                      
                      try {
                        final connectionSpeed = await InternetSpeedChecker.checkSpeed(
                          timeout: const Duration(seconds: 5),
                        );
                        
                        // If connection speed is null or very slow (>5000ms), treat as 2G/low network
                        final isSlowConnection = connectionSpeed == null || connectionSpeed > 5000;
                        
                        if (isSlowConnection) {
                          emptyStateMessage.value = kCheckInternetConnectionMessage;
                          Constants.showToast(kCheckInternetConnectionMessage);
                        }
                      } catch (e) {
                        // On error, assume slow connection
                        emptyStateMessage.value = kCheckInternetConnectionMessage;
                        Constants.showToast(kCheckInternetConnectionMessage);
                      }
                    });
                  }
                  
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        emptyStateMessage.value ??
                            kCheckInternetConnectionMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CommanColor.contentTextColor(context),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: data.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: screenWidth > 600 ? 1.75 : 1.4,
                      crossAxisCount: 2,
                    ),
                    itemBuilder: (context, index) => CategoryWidget(
                      category: data[index],
                      isWallpaper: false,
                    ),
                  );
                },
                error: (error, st) {
                  return Center(
                    child: Text(
                      userFacingNetworkMessage(error),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 44,
                        width: 44,
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Loading...",
                        style: TextStyle(
                          color: CommanColor.contentTextColor(context)
                              .withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // const Center(
              //     child: CircularProgressIndicator.adaptive())),
              )
            ],
          ),
        ),
      ),
    );
  }
}

