import 'dart:io';

import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class FeedbackWebView extends StatefulWidget {
  const FeedbackWebView({super.key});

  @override
  State<FeedbackWebView> createState() => _FeedbackWebViewState();
}

class _FeedbackWebViewState extends State<FeedbackWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      cacheEnabled: false,
      cacheMode: CacheMode.LOAD_NO_CACHE,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;
  String? url;
  bool isLoading = true;
  double progress = 0;

  bool _isFeedbackSuccessUrl(Uri uri) {
    if (!uri.toString().contains('m_feedback/API/feedback_form/index.php')) {
      return false;
    }
    // Server returns response screen params like:
    // ?repsonse_screen=1&r_res=suc&r_msg=Thank%20you...
    final responseScreen = uri.queryParameters['repsonse_screen'];
    final result = uri.queryParameters['r_res'];
    return responseScreen == '1' && result == 'suc';
  }

  String? _feedbackSuccessMessage(Uri uri) {
    final msg = uri.queryParameters['r_msg'];
    if (msg == null || msg.trim().isEmpty) return null;
    return msg;
  }

  @override
  void initState() {
    super.initState();
    checknetwork();
    _loadFeedbackFormUrl();

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  Future<void> checknetwork() async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        Constants.showToast("No internet connection");
      }
    } catch (_) {
      // Do not block feedback when connectivity check fails.
    }
  }

  /// Load feedback form URL (bibleoffice.com) with device params.
  Future<void> _loadFeedbackFormUrl() async {
    await SharPreferences.setString('OpenAd', '1');
    String deviceType = 'ios';
    String packageName = Api.packageName;
    String appName = BibleInfo.bible_shortName;
    String deviceId = '';
    String deviceModel = '';
    const String groupId = '1';
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceType = 'Android';
      deviceId = androidInfo.id;
      deviceModel = androidInfo.model;
      packageName = BibleInfo.android_Package_Name;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceType = 'iOS';
      packageName = BibleInfo.ios_Bundle_Id;
      deviceId = iosInfo.identifierForVendor ?? '';
      deviceModel = iosInfo.utsname.machine;
    }
    final String feedbackUrl =
        '${Api.feedbackApi}?device_type=$deviceType&group_id=$groupId&package_name=$packageName&app_name=$appName&device_id=$deviceId&device_model=$deviceModel';
    if (mounted) {
      setState(() {
        url = feedbackUrl;
      });
    }
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 218, 211),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover))
            : null,
        child: SafeArea(
          child: Stack(
            children: [
              // isLoading
              //     ? Align(
              //         alignment: Alignment.center,
              //         child: CircularProgressIndicator.adaptive(),
              //       )
              //     : Stack(),
              (url != null)
                  ? InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(url: WebUri(url!)),
                      initialSettings: settings,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) async {
                        webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                          isLoading = true;
                        });
                        final uri = Uri.tryParse(url.toString());
                        if (uri != null && _isFeedbackSuccessUrl(uri)) {
                          Get.back();
                          Constants.showToast(
                              _feedbackSuccessMessage(uri) ??
                                  'Thank you for the valuable feedback!');
                          return;
                        }
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (_isFeedbackSuccessUrl(Uri.parse(uri.toString()))) {
                          Get.back();
                          Constants.showToast(
                              _feedbackSuccessMessage(Uri.parse(uri.toString())) ??
                                  'Thank you for the valuable feedback!');
                          return NavigationActionPolicy.CANCEL;
                        }

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController?.endRefreshing();
                        await SharPreferences.setString('OpenAd', '1');
                        setState(() {
                          this.url = url.toString();
                          isLoading = false;
                        });
                      },
                      onReceivedError: (controller, request, error) async {
                        pullToRefreshController?.endRefreshing();
                        if (error.description ==
                            "The Internet connection appears to be offline.") {
                          try {
                            final hasInternet =
                                await InternetConnection().hasInternetAccess;
                            if (!hasInternet) {
                              Constants.showToast(
                                  "No internet connection", 4000);
                            }
                          } catch (_) {
                            // Skip toast when connectivity cannot be verified.
                          }
                        }
                        setState(() {
                          isLoading = false; // Hide loader on error
                        });
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController?.endRefreshing();
                          setState(() {
                            isLoading = false;
                          });
                        }
                        setState(() {
                          this.progress = progress / 100;
                        });
                      },
                      onUpdateVisitedHistory: (controller, url, isReload) {
                        setState(() {
                          this.url = url.toString();
                          isLoading = false;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {},
                    )
                  : isLoading
                      ? Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator.adaptive(),
                        )
                      : Column(),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: CommanColor.darkPrimaryColor,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white)),
                ),
              ),
              isLoading
                  ? Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : url == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                'Unable to load feedback form',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          ],
                        )
                      : Column(),
            ],
          ),
        ),
      ),
    );
  }
}
