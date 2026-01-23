import 'package:biblebookapp/services/statsig/statsig_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/books/bloc/book_bloc.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart' as p;

class BooksScreen extends HookConsumerWidget {
  final int bookAdId;
  const BooksScreen({super.key, required this.bookAdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookBloc);
    final hasShownToast = useRef(false);
    
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookBloc).getBooks(bookAdId);
        // Track Books event
        StatsigService.trackBooks();
        // Reset toast flag when starting to load
        hasShownToast.value = false;
      });
    });
    
    // Monitor loading state and show toast if loading takes too long
    useEffect(() {
      if (bookState.isLoading && bookState.books.isEmpty && !hasShownToast.value) {
        bool cancelled = false;
        Future.delayed(const Duration(seconds: 3), () async {
          if (!cancelled && bookState.isLoading && bookState.books.isEmpty && !hasShownToast.value) {
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
    }, [bookState.isLoading, bookState.books.isEmpty]);
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
                  onTap: () {
                    Get.back();
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
                    text: 'Books',
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
            bookState.isLoading && bookState.books.isEmpty
                ? const CircularProgressIndicator.adaptive()
                : Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: bookState.books.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: screenWidth > 450 ? 0.65 : 0.61,
                          crossAxisCount: screenWidth > 450 ? 3 : 2),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () async {
                          await SharPreferences.setString('OpenAd', '1');
                          if (await canLaunchUrlString(
                              bookState.books[index].bookUrl)) {
                            launchUrlString(bookState.books[index].bookUrl,
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
                                padding: const EdgeInsets.all(4.0),
                                child: Image.network(
                                    bookState.books[index].bookThumbURL),
                              ),
                              // const Spacer(),
                              // Flexible(
                              //   child: Text(
                              //     bookState.books[index].bookName,
                              //     style: CommanStyle.appBarStyle(context)
                              //         .copyWith(
                              //             color: CommanColor.lightDarkPrimary(
                              //                 context),
                              //             fontWeight: FontWeight.bold,
                              //             fontSize: BibleInfo.fontSizeScale *
                              //                         screenWidth >
                              //                     450
                              //                 ? 14
                              //                 : 12),
                              //     textAlign: TextAlign.center,
                              //   ),
                              // ),
                              screenWidth > 450
                                  ? SizedBox(
                                      height: 6,
                                    )
                                  : const Spacer(),
                              Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
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
                                    'View',
                                    style: TextStyle(
                                        letterSpacing: BibleInfo.letterSpacing,
                                        fontSize: BibleInfo.fontSizeScale *
                                                    screenWidth >
                                                450
                                            ? 17
                                            : 15,
                                        fontWeight: FontWeight.w500,
                                        color: CommanColor.darkModePrimaryWhite(
                                            context)),
                                  ))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
          ],
        ),
      ),
    ));
  }
}

