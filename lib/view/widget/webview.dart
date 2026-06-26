import 'dart:io';

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
import 'package:package_info_plus/package_info_plus.dart';
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
      iframeAllowFullscreen: true,
      forceDark: ForceDark.OFF,
      algorithmicDarkeningAllowed: false);

  static const String _feedbackInputStyleJs = '''
(function() {
  var style = document.createElement('style');
  style.id = 'feedback-form-input-fix';
  style.textContent =
    'input, textarea, select {' +
    'color: #1a1a1a !important;' +
    '-webkit-text-fill-color: #1a1a1a !important;' +
    'caret-color: #1a1a1a !important;' +
    '}';
  if (!document.getElementById('feedback-form-input-fix')) {
    document.head.appendChild(style);
  }
  document.querySelectorAll('input, textarea').forEach(function(el) {
    if (el.dataset.feedbackLogAttached === '1') return;
    el.dataset.feedbackLogAttached = '1';
    el.addEventListener('input', function() {
      var label = el.name || el.id || el.type || 'field';
      console.log('feedback_input|' + label + '|' + (el.value || ''));
    });
  });
})();
''';

  static const String _feedbackFieldsDumpJs = '''
(function() {
  var fields = document.querySelectorAll('input, textarea, select');
  var out = [];
  for (var i = 0; i < fields.length; i++) {
    var f = fields[i];
    out.push({
      name: f.name || f.id || ('field_' + i),
      type: f.type || f.tagName.toLowerCase(),
      value: f.value || ''
    });
  }
  return JSON.stringify(out);
})();
''';

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

  void _handleFeedbackSuccess(Uri uri) {
    debugPrint('=== Feedback Submit Success ===');
    for (final entry in uri.queryParameters.entries) {
      debugPrint('  ${entry.key}: ${entry.value}');
    }
    debugPrint('  full_url: $uri');
    debugPrint('===============================');
    Get.back();
    Constants.showToast(
      _feedbackSuccessMessage(uri) ?? 'Thank you for the valuable feedback!',
    );
  }

  bool _isInterruptedSuccessLoad(WebResourceError error) {
    return error.type == WebResourceErrorType.CANCELLED ||
        error.description.contains('Frame load interrupted') ||
        error.description.contains('code=102');
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

  /// Build feedback URL with Uri.https so every value is encoded correctly.
  Future<Uri> _buildFeedbackFormUri() async {
    final pkg = await PackageInfo.fromPlatform();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceInfo = DeviceInfoPlugin();

    const groupId = '1';
    const appType = 'lite';

    final params = <String, String>{
      'group_id': groupId,
      'app_version': pkg.version,
      'package_name': pkg.packageName,
      'app_name':
          pkg.appName.isNotEmpty ? pkg.appName : BibleInfo.bible_shortName,
      'app_type': appType,
      'language': locale.languageCode,
      'country_code': locale.countryCode ?? '',
    };

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      params.addAll({
        'device_type': 'ios',
        'device_id': ios.identifierForVendor ?? '',
        'device_name': ios.name,
        'device_model': ios.utsname.machine,
        'os_version': ios.systemVersion,
        'ios_apple_id': BibleInfo.apple_AppId,
      });
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      params.addAll({
        'device_type': 'android',
        'device_id': android.id,
        'device_name': android.device,
        'device_model': android.model,
        'os_version': android.version.release,
      });
    } else {
      params['device_type'] = 'unknown';
      params['device_id'] = '';
      params['device_name'] = '';
      params['device_model'] = '';
      params['os_version'] = '';
    }

    final uri = Uri.https(
      'bibleoffice.com',
      '/m_feedback/API/feedback_form/index.php',
      params,
    );

    debugPrint('=== Feedback Form URL (verify before load) ===');
    debugPrint(uri.toString());
    for (final entry in params.entries) {
      final marker =
          entry.value.trim().isEmpty ? ' *** EMPTY — check source ***' : '';
      debugPrint('  ${entry.key}: ${entry.value}$marker');
    }
    debugPrint('==============================================');

    return uri;
  }

  /// Load feedback form URL (bibleoffice.com) with device params.
  Future<void> _loadFeedbackFormUrl() async {
    await SharPreferences.setString('OpenAd', '1');
    try {
      final feedbackUri = await _buildFeedbackFormUri();
      if (mounted) {
        setState(() {
          url = feedbackUri.toString();
        });
      }
    } catch (e, st) {
      debugPrint('FeedbackWebView: failed to build feedback URL: $e');
      debugPrint('$st');
    }
  }

  Future<void> _logFeedbackFormFields(String source) async {
    final controller = webViewController;
    if (controller == null) return;
    try {
      final result = await controller.evaluateJavascript(
        source: _feedbackFieldsDumpJs,
      );
      debugPrint('Feedback form fields ($source): $result');
    } catch (e) {
      debugPrint('Feedback form field dump failed ($source): $e');
    }
  }

  Future<void> _ensureFeedbackInputVisible() async {
    final controller = webViewController;
    if (controller == null) return;
    try {
      await controller.evaluateJavascript(source: _feedbackInputStyleJs);
    } catch (e) {
      debugPrint('Feedback input style injection failed: $e');
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
                          _handleFeedbackSuccess(uri);
                          return;
                        }
                        if (uri != null &&
                            uri.toString().contains('m_feedback/Save_feedback')) {
                          debugPrint('=== Feedback Submitting (POST) ===');
                          debugPrint('  submit_url: $uri');
                          _logFeedbackFormFields('onLoadStart_submit');
                        }
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (_isFeedbackSuccessUrl(Uri.parse(uri.toString()))) {
                          _handleFeedbackSuccess(Uri.parse(uri.toString()));
                          return NavigationActionPolicy.CANCEL;
                        }

                        if (uri.toString().contains('m_feedback/Save_feedback')) {
                          debugPrint('=== Feedback Submitting ===');
                          debugPrint('  submit_url: ${uri.toString()}');
                          debugPrint(
                              '  method: ${navigationAction.request.method}');
                          await _logFeedbackFormFields('before_submit');
                          debugPrint('============================');
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
                        await _ensureFeedbackInputVisible();
                        await _logFeedbackFormFields('onLoadStop');
                        setState(() {
                          this.url = url.toString();
                          isLoading = false;
                        });
                      },
                      onReceivedError: (controller, request, error) async {
                        pullToRefreshController?.endRefreshing();
                        if (_isInterruptedSuccessLoad(error)) {
                          debugPrint(
                              'FeedbackWebView: ignored interrupted load after success');
                          return;
                        }
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
                      onConsoleMessage: (controller, consoleMessage) {
                        final message = consoleMessage.message;
                        if (message.startsWith('feedback_input|')) {
                          final parts = message.split('|');
                          if (parts.length >= 3) {
                            debugPrint(
                                'Feedback typed [${parts[1]}]: ${parts.sublist(2).join('|')}');
                          }
                        } else {
                          debugPrint(
                              'FeedbackWebView console [${consoleMessage.messageLevel}]: $message');
                        }
                      },
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
