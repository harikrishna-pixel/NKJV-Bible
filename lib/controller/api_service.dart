import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/core/library_backup_upload_service.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/utils/referral_api_logger.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/more_apps/model/app_model.dart';
import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

import '../Model/get_audio_model.dart';
import '../core/api/auth/profile_update.api.dart';

class Api {
  static const moreAppList =
      'https://bibleoffice.com/BibleReplications/dev/v1/API/getMoreAppList.php';

  static const feedbackApi =
      "https://bibleoffice.com/m_feedback/API/feedback_form/index.php";
  static const getMusicApi =
      "https://bibleoffice.com/BibleReplications/dev/v1/API/getAppInfo.php";
  static const submitPurchaseApi =
      'https://bibleoffice.com/BibleReplications/dev/v1/API/v2/Subscription/insert';

  static const restorePurchase =
      'https://bibleoffice.com/BibleReplications/dev/v1/API/v2/Subscription/getReceipt_data';

  static const categoryListing =
      'https://savefbk.com/media_gallery/API/bible_app_v2/main_list/get_image_cat_list_by_app_id';

  static const imageListing =
      'https://savefbk.com/media_gallery/API/bible_app_v2/main_list/get_image_list_by_cat_id';

  static const String categoryListId =
      'https://saveigm.com/bookads/admin/api/book/book_cat_list_by_app';

  static const String bookListId =
      'https://saveigm.com/bookads/admin/api/book/book_list_by_cat';

  static String packageName = Platform.isAndroid
      ? BibleInfo.android_Package_Name
      : BibleInfo.ios_Bundle_Id;

  static String surveyForm =
      'https://bibleoffice.com/survey/webservice/survey_form/index.php?survey_id=';

  // static String surveyForm =
  //     'https://bibleoffice.com/survey/webservice/survey_form/index.php?survey_id=${BibleInfo.surveyAppId}&package_name=$packageName';

  // static String clientID = '9e03e5f1-621b-422c-8db9-30778e674386';

  // static String clientSecret = 'UWaoxT3h8N0gd6Olr3OIryt1BtEhFNGi9Q6S0mnx';
  static String tempToken =
      'https://bibleoffice.com/authhub/API/public/api/temp-token';
  static String register =
      'https://bibleoffice.com/authhub/API/public/api/register';
  static String login = 'https://bibleoffice.com/authhub/API/public/api/login';
}

HttpWithMiddleware http = HttpWithMiddleware.build(middlewares: [
  HttpLogger(logLevel: LogLevel.BODY),
]);
final CacheNotifier cacheNotifier = CacheNotifier();
// Future<GetAudioModel?>? getMusicDetails() async {
//   String androidPackageName;
//   androidPackageName = BibleInfo.android_Package_Name;
//   String appleAppId;
//   appleAppId = BibleInfo.apple_AppId;
//   String iosBundleId;
//   iosBundleId = BibleInfo.ios_Bundle_Id;

//   Map<String, dynamic> requestBody = {};

//   if (Platform.isAndroid) {
//     requestBody["android_package_name"] = androidPackageName;
//   } else if (Platform.isIOS) {
//     requestBody["ios_bundle_id"] = iosBundleId;
//     requestBody["ios_apple_id"] = appleAppId;
//   }

//   try {
//     final response = await http.post(
//       Uri.parse(Api.getMusicApi),
//       body: requestBody,
//     );
//     if (response.statusCode == 200) {
//       var data = json.decode(utf8.decode(response.bodyBytes));
//       return GetAudioModel.fromJson(data);
//     } else {
//       Constants.showToast("Failed to load music");
//       throw Exception('Failed to load Music');
//       //return null;
//     }
//   } catch (e) {
//     rethrow;
//     // return null;
//   }
// }
Future<GetAudioModel?> getMusicDetails() async {
  String androidPackageName = BibleInfo.android_Package_Name;
  String appleAppId = BibleInfo.apple_AppId;
  String iosBundleId = BibleInfo.ios_Bundle_Id;

  Map<String, dynamic> requestBody = {};

  if (Platform.isAndroid) {
    requestBody["android_package_name"] = androidPackageName;
  } else if (Platform.isIOS) {
    requestBody["ios_bundle_id"] = iosBundleId;
    requestBody["ios_apple_id"] = appleAppId;
  }

  try {
    // Create HTTP POST future
    final postFuture = http.post(
      Uri.parse(Api.getMusicApi),
      body: requestBody,
    );

    // Create timeout future
    final timeoutFuture =
        Future.delayed(const Duration(seconds: 7), () => null);

    // Whichever finishes first will be returned
    final response = await Future.any([postFuture, timeoutFuture]);

    if (response == null) {
      // Timeout hit before response
      return null;
    }

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      final model = GetAudioModel.fromJson(data);

      // Log wallpaper and image IDs from API response
      final wallpaperId = model.data?.wallpaperCatId ?? '';
      final imageId = model.data?.imageAppId ?? '';
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🌐 API getMusicDetails Response for Geneva Bible:');
      debugPrint('   wallpaper_cat_id: "$wallpaperId"');
      debugPrint('   image_app_id: "$imageId"');
      debugPrint('═══════════════════════════════════════════════════════');

      return model;
    } else {
      throw Exception('Failed to load Music');
    }
  } catch (e) {
    debugPrint("Error in getMusicDetails: $e");
    return null;
  }
}

Future<void> purchaseSubmit({receiptData}) async {
  var androidPackageName = BibleInfo.android_Package_Name;
  var iosBundleId = BibleInfo.ios_Bundle_Id;

  Map<String, dynamic> requestBody = {};

  requestBody["dev_app_id"] = Platform.isIOS ? iosBundleId : androidPackageName;
  requestBody["dev_type"] = Platform.isIOS ? '2' : '1';
  requestBody["receipt_data"] = receiptData;

  if (Platform.isIOS) {
    var iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
    requestBody["udid"] = iosDeviceInfo.identifierForVendor;
  }
  if (Platform.isAndroid) {
    var androidDeviceInfo = await AndroidId().getId();
    requestBody["udid"] = androidDeviceInfo;
  }
  try {
    final response = await http.post(
      Uri.parse(Api.submitPurchaseApi),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: requestBody,
    );
    final data = response.body;

    //  DebugConsole.log("purchase - $data");
    // debugPrint("${data}");
  } catch (e) {
    DebugConsole.log("purchase error - $e");
    log('$e');
  }
}

Future<dynamic> restorePurchase() async {
  var androidPackageName = BibleInfo.android_Package_Name;
  var iosBundleId = BibleInfo.ios_Bundle_Id;

  Map<String, dynamic> requestBody = {};

  requestBody["dev_app_id"] = Platform.isIOS ? iosBundleId : androidPackageName;
  requestBody["dev_type"] = Platform.isIOS ? '2' : '1';

  if (Platform.isIOS) {
    var iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
    requestBody["udid"] = iosDeviceInfo.identifierForVendor;
  }
  if (Platform.isAndroid) {
    var androidDeviceInfo = await AndroidId().getId();
    requestBody["udid"] = androidDeviceInfo;
  }
  try {
    final data = await http.post(Uri.parse(Api.restorePurchase),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody);

    DebugConsole.log("restore purchases api data - ${data.body}");
    // final data2 = json.decode(data.body);
    parseHtmlAndExtractJson(data.body);

    return parseHtmlAndExtractJson(data.body);
  } catch (e) {
    DebugConsole.log("restore purchases api error - $e");
    rethrow;
  }
}

parseHtmlAndExtractJson(String responseBody) {
  try {
    // Step 1: Find where the JSON starts
    int jsonStartIndex = responseBody.indexOf('{');
    if (jsonStartIndex == -1) {
      debugPrint("No JSON found in response");
      return;
    }

    // Step 2: Extract the JSON part from the string
    String jsonString = responseBody.substring(jsonStartIndex);

    // Step 3: Decode the JSON
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Step 4: Access "status"
    debugPrint("Status: ${jsonData['status']}");
    return jsonData;
  } catch (e) {
    debugPrint("Failed to parse response: $e");
  }
}

Future<dynamic> feedbackSubmit({device_id}) async {
  try {
    final response = await http.post(
      Uri.parse(
          "${Api.feedbackApi}?device_type=ios&group_id=1&package_name=com.whitebibles.amplifiedbible&app_name=testapp&device_id=$device_id"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print(response.body);
      print(response.body);
      print(response.body);
      return responseBody;

    }
  } on TimeoutException catch (e) {
    Constants.showToast(e.message.toString());
    return;
  } on SocketException catch (e) {
    Constants.showToast(e.message.toString());
    return;
  }
}

Future<List<CategoryModel>> getCategoryListing({required bool isQuotes}) async {
  var androidPackageName = BibleInfo.android_Package_Name;
  var iosBundleId = BibleInfo.ios_Bundle_Id;
  var appVersion = BibleInfo.current_Version;
  try {
    // Get ID from SharedPreferences, fallback to constants if not available
    final idFromPrefs = await SharPreferences.getString(
        isQuotes ? SharPreferences.imageAppID : SharPreferences.wallpaperCatID);

    // Use constants as fallback when API data is not available
    final id = idFromPrefs?.isNotEmpty == true
        ? idFromPrefs!
        : (isQuotes ? BibleInfo.imageAppId : BibleInfo.wallpaperCatId);

    // If ID is still empty, return empty list instead of making API call
    if (id.isEmpty) {
      debugPrint(
          '${isQuotes ? "Quotes" : "Wallpaper"} ID not available, returning empty list from constants');
      return [];
    }

    final resp = await http
        .post(Uri.parse(Api.categoryListing), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'app_id': id,
      'device_type': Platform.isIOS ? 'ios' : 'android',
      'package_name': Platform.isIOS ? iosBundleId : androidPackageName,
      'app_version': appVersion
    });
    final data = jsonDecode(resp.body)['data'];
    return (data['category_list'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  } catch (e) {
    DebugConsole.log("wallpaper/quotes err - $e");
    // If API fails and we have constants, return empty list instead of throwing error
    // This allows the UI to show empty state instead of error message
    if (e.toString().contains('host lookup') ||
        e.toString().contains('SocketException')) {
      debugPrint(
          '${isQuotes ? "Quotes" : "Wallpaper"} API failed - no internet, returning empty list from constants fallback');
      return []; // Return empty list instead of throwing error
    }
    // For other errors, also return empty list to prevent "Check your Internet connection" message
    debugPrint(
        '${isQuotes ? "Quotes" : "Wallpaper"} API error: $e, returning empty list from constants fallback');
    return [];
  }
}

Future<List<ImageModel>> getImageListing(
    {required String id, required int page}) async {
  var androidPackageName = BibleInfo.android_Package_Name;
  var iosBundleId = BibleInfo.ios_Bundle_Id;
  var appVersion = BibleInfo.current_Version;
  try {
    final resp =
        await http.post(Uri.parse(Api.imageListing), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'category_id': id,
      'device_type': Platform.isIOS ? 'ios' : 'android',
      'package_name': Platform.isIOS ? iosBundleId : androidPackageName,
      'app_version': appVersion,
      'page_limit': '21',
      'next_page_no': '$page'
    });
    final data = jsonDecode(resp.body)['data'];
    return (data['img_list'] as List)
        .map((e) => ImageModel.fromJson(e))
        .toList();
  } catch (e) {
    if (e.toString().contains('host lookup')) {
      throw 'No Internet Connection';
    }
    rethrow;
  }
}

Future<List<CalendarModel>> downloadAndParseCsv() async {
  try {
// Download the CSV file
    final response = await http.get(
        Uri.parse('http://bibleoffice.com/bibleCalendar/bibleCalendar.csv'));

    if (response.statusCode == 200) {
      // Parse CSV
      final csvString = response.body.trim();

      List<String> lines = csvString.split('\n');

      // Map each line to a model, skipping the first (header) row
      List<CalendarModel> events = lines.skip(1).map((line) {
        List<String> fields = line.split(',');
        // Define the format according to the input (dd-MM-yyyy)
        DateFormat dateFormat = DateFormat('dd-MM-yyyy');

        // Parse the string to DateTime
        DateTime parsedDate = dateFormat.parse(fields[1].trim());

        // Ensure each field is trimmed and properly mapped
        return CalendarModel(
          date: parsedDate.toString(), // Date column (2nd column)
          title: fields[2].trim(), // Content column (3rd column)
          canEdit: false,
        );
      }).toList();
      final json = events.map((e) => jsonEncode(e.toJson())).toList();
      await SharPreferences.setListString(SharPreferences.calendarLocal, json);
      return events;
    } else {
      throw Exception('Failed to download CSV');
    }
  } catch (e) {
    final localData =
        await SharPreferences.getStringList(SharPreferences.calendarLocal);
    if (localData == null || localData.isEmpty) {
      return [];
    } else {
      return localData
          .map((e) => CalendarModel.fromJson(jsonDecode(e)))
          .toList();
    }
  }
}

Future<List<AppModel>> getMoreApps() async {
  var androidPackageName = BibleInfo.android_Package_Name;
  var iosBundleId = BibleInfo.apple_AppId; // for amplifed
  // var iosBundleId = BibleInfo.ios_Bundle_Id; // for telugu

  try {
    final resp =
        await http.post(Uri.parse(Api.moreAppList), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'package_name': Platform.isAndroid ? androidPackageName : iosBundleId,
    });
    final data = jsonDecode(resp.body)['data'];
    return (data as List).map((e) => AppModel.fromJson(e)).toList();
  } catch (e) {
    DebugConsole.log("more apps err - $e");
    // If API fails, use fallback data from constants
    if (e.toString().contains('host lookup') ||
        e.toString().contains('SocketException') ||
        e.toString().contains('TimeoutException') ||
        e.toString().contains('Failed host lookup')) {
      debugPrint('More Apps API failed - using fallback data from constants');
      try {
        // Get fallback app data from constants
        final fallbackData = BibleInfo.getMoreAppsFallbackData();
        return fallbackData.map((e) => AppModel.fromJson(e)).toList();
      } catch (fallbackError) {
        debugPrint('Error creating fallback apps: $fallbackError');
        return []; // Return empty list if fallback also fails
      }
    }
    // For other errors, also try fallback
    debugPrint('More Apps API error: $e - using fallback data from constants');
    try {
      final fallbackData = BibleInfo.getMoreAppsFallbackData();
      return fallbackData.map((e) => AppModel.fromJson(e)).toList();
    } catch (fallbackError) {
      debugPrint('Error creating fallback apps: $fallbackError');
      return []; // Return empty list if fallback also fails
    }
  }
}

Future<List<BookModel>> getBookListing(int id) async {
  try {
    final resp =
        await http.post(Uri.parse(Api.bookListId), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'book_cat_id': "$id",
    });
    final data = jsonDecode(resp.body)['data'];
    return (data as List).map((e) => BookModel.fromJson(e)).toList();
  } catch (e) {
    DebugConsole.log("book list err - $e");
    if (e.toString().contains('host lookup')) {
      throw 'No Internet Connection';
    }
    rethrow;
  }
}

Future<List<BookModel>> getBookCategories(int id) async {
  try {
    final resp = await http
        .post(Uri.parse(Api.categoryListId), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'book_app_id': "$id",
    });
    final data = jsonDecode(resp.body)['data'];
    if ((data as List).isNotEmpty) {
      return await getBookListing(int.tryParse(data.first['categoryId']) ?? 13);
    } else {
      return [];
    }
  } catch (e) {
    if (e.toString().contains('host lookup')) {
      throw 'No Internet Connection';
    }
    rethrow;
  }
}

Future<String> getTempToken() async {
  try {
    final resp =
        await http.post(Uri.parse(Api.tempToken), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'client_id': dotenv.env[AssetsConstants.clientid] ?? '',
      'client_secret': dotenv.env[AssetsConstants.clientSecret] ?? "",
      'app_id': BibleInfo.appID,
    });
    final data = jsonDecode(resp.body)?['data']?['temp_access_token'];
    if (data != null) {
      return data.toString();
    } else {
      throw 'Failed to get temp token';
    }
  } catch (e) {
    // If the code explicitly threw a user-facing string (e.g. data['message']), rethrow it unchanged
    if (e is String) {
      throw e;
    }
    final err = e.toString().toLowerCase();
    // Map common network errors/timeouts to a user-friendly offline message
    if (e is SocketException ||
        e is TimeoutException ||
        err.contains('socketexception') ||
        err.contains('host lookup') ||
        err.contains('failed host lookup') ||
        err.contains('timed out') ||
        err.contains('timeout')) {
      throw 'No Internet Connection';
    }
    // Check for certificate/SSL/handshake errors and show user-friendly message
    if (err.contains('certificate_verify_failed') ||
        err.contains('handshake') ||
        err.contains('certificate') ||
        err.contains('ssl')) {
      debugPrint('getTempToken: Certificate/SSL error: $e');
      throw 'Something went wrong. Please check your internet connection and try again.';
    }
    debugPrint('getTempToken: Error: $e');
    throw 'Something went wrong. Please try again.';
  }
}

Future<bool> updateReferralRewardClaimed({required int value}) async {
  final result =
      await ProfileUpdateApi().updateReferralRewardClaimed(value: value);
  if (result == null || result.isEmpty) return false;
  try {
    final parsed = jsonDecode(result) as Map<String, dynamic>;
    return parsed['status'] == true;
  } catch (_) {
    return false;
  }
}

String? _referralCodeFromAuthResponse(dynamic response) {
  if (response is! Map) return null;
  final map = Map<String, dynamic>.from(response);
  Map<String, dynamic>? user;
  final data = map['data'];
  if (data is Map && data['user'] is Map) {
    user = Map<String, dynamic>.from(data['user'] as Map);
  } else if (map['user'] is Map) {
    user = Map<String, dynamic>.from(map['user'] as Map);
  }
  if (user == null) return null;
  for (final key in ['referral_code', 'referralCode']) {
    final value = user[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  if (data is Map) {
    for (final key in ['referral_code', 'referralCode']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
  }
  return null;
}

Future<String?> registerUser(
    {required String email,
    required String name,
    required String password}) async {
  // final CacheNotifier cacheNotifier = CacheNotifier();
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedCategories =
        prefs.getStringList('selected_categories') ?? [];
    final token = await getTempToken();
    final resp =
        await http.post(Uri.parse(Api.register), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: {
      'name': name,
      'email': email,
      'password': password,
      "device_type": Platform.isIOS ? "iOS" : "Android",
      'password_confirmation': password,
      'app_id': BibleInfo.appID,
      'interested_vc_tags': selectedCategories.toString()
    });
    final data = jsonDecode(resp.body);

    logAuthApiReferralFields('REGISTER API', data);
    debugPrint("sign up - $data ");

    if (data['status']) {
      // await cacheNotifier.writeCache(
      //     key: "user", value: '${data['data']['user']['email']}');

      // await cacheNotifier.writeCache(
      //     key: "userid", value: '${data['data']['user']['user_id']}');

      // await cacheNotifier.writeCache(
      //     key: "name", value: '${data['data']['user']['name']}');
      await cacheNotifier.writeCache(
          key: "authtoken", value: '${data['data']['token']}');
      Constants.showToast("Account Created Successfully");
      return _referralCodeFromAuthResponse(data);
    } else {
      throw data['message'] ?? 'Failed to register';
    }
  } catch (e) {
    // If the code explicitly threw a user-facing string (e.g. data['message']), rethrow it unchanged
    if (e is String) {
      throw e;
    }
    final err = e.toString().toLowerCase();
    if (e is SocketException ||
        e is TimeoutException ||
        err.contains('socketexception') ||
        err.contains('host lookup') ||
        err.contains('failed host lookup') ||
        err.contains('timed out') ||
        err.contains('timeout')) {
      throw 'No Internet Connection';
    }
    // Check for certificate/SSL/handshake errors and show user-friendly message
    if (err.contains('certificate_verify_failed') ||
        err.contains('handshake') ||
        err.contains('certificate') ||
        err.contains('ssl') ||
        err.contains('failed to get temp token')) {
      debugPrint('registerUser: Certificate/SSL error or temp token error: $e');
      throw 'Something went wrong. Please check your internet connection and try again.';
    }
    // If error message is already user-friendly (from getTempToken), use it
    if (err.contains('something went wrong')) {
      throw e.toString();
    }
    debugPrint('registerUser: Error: $e');
    throw 'Something went wrong. Please try again.';
  }
}

Future<UserModel> loginUser(
    {required String email,
    required String password,
    String? referralCode}) async {
  try {
    final token = await getTempToken();
    final body = <String, String>{
      'email': email,
      'password': password,
      'app_id': BibleInfo.appID.toString(),
      "device_type": Platform.isIOS ? "iOS" : "Android",
    };
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      body['referral_code'] = referralCode.trim();
    }
    final resp =
        await http.post(Uri.parse(Api.login), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: body);
    final data = jsonDecode(resp.body);

    logAuthApiReferralFields('LOGIN API', data);
    debugPrint("user login - $data");
    if (data['status']) {
      await cacheNotifier.writeCache(
          key: "user", value: '${data['data']['user']['email']}');

      await cacheNotifier.writeCache(
          key: "userid", value: '${data['data']['user']['user_id']}');

      await cacheNotifier.writeCache(
          key: "name", value: '${data['data']['user']['name']}');
      await cacheNotifier.writeCache(
          key: "authtoken", value: '${data['data']['token']}');

      LibraryBackupUploadService.runAfterLogin();

      // Constants.showToast(
      //     "Hi ${data['data']['user']['name']}, Welcome to ${BibleInfo.bible_shortName}");
      // Get.offAll(() => HomeScreen(
      //     From: "splash",
      //     selectedVerseNumForRead: "",
      //     selectedBookForRead: "",
      //     selectedChapterForRead: "",
      //     selectedBookNameForRead: "",
      //     selectedVerseForRead: ""));
      final user =
          UserModel.fromJson(data['data']['user'], data['data']['token']);
      debugPrint('LOGIN parsed referral fields:');
      debugPrint('  referred_by              → ${user.referredBy ?? ''}');
      debugPrint('  referral_count           → ${user.referralCount}');
      debugPrint(
          '  referral_reward_claimed  → ${user.referralRewardClaimed}');
      return user;
    } else {
      throw data['message'] ?? 'Failed to login';
    }
  } catch (e) {
    // If the code explicitly threw a user-facing string (e.g. data['message']), rethrow it unchanged
    if (e is String) {
      throw e;
    }
    final err = e.toString().toLowerCase();
    if (e is SocketException ||
        e is TimeoutException ||
        err.contains('socketexception') ||
        err.contains('host lookup') ||
        err.contains('failed host lookup') ||
        err.contains('timed out') ||
        err.contains('timeout')) {
      throw 'No Internet Connection';
    }
    // Check for certificate/SSL/handshake errors and show user-friendly message
    if (err.contains('certificate_verify_failed') ||
        err.contains('handshake') ||
        err.contains('certificate') ||
        err.contains('ssl') ||
        err.contains('failed to get temp token')) {
      debugPrint('loginUser: Certificate/SSL error or temp token error: $e');
      throw 'Something went wrong. Please check your internet connection and try again.';
    }
    // If error message is already user-friendly (from getTempToken), use it
    if (err.contains('something went wrong')) {
      throw e.toString();
    }
    debugPrint('loginUser: Error: $e');
    throw 'Something went wrong. Please try again.';
  }
}

Future<void> applyReferralViaLogin({
  required String email,
  required String password,
  required String referralCode,
  String? ownReferralCode,
  String? initialReferredBy,
}) async {
  final code = referralCode.trim();
  if (code.isEmpty) {
    throw 'Please enter a referral ID';
  }
  if (ownReferralCode != null &&
      ownReferralCode.trim().isNotEmpty &&
      code.toUpperCase() == ownReferralCode.trim().toUpperCase()) {
    throw 'You cannot use your own referral code';
  }
  if (initialReferredBy != null && initialReferredBy.trim().isNotEmpty) {
    throw 'Referral code already applied';
  }

  try {
    final token = await getTempToken();
    final resp =
        await http.post(Uri.parse(Api.login), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: {
      'email': email,
      'password': password,
      'app_id': BibleInfo.appID.toString(),
      'device_type': Platform.isIOS ? 'iOS' : 'Android',
      'referral_code': code,
    });
    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    logAuthApiReferralFields('LOGIN API (referral apply)', data);
    debugPrint('applyReferralViaLogin - $data');
    if (data['status'] != true) {
      final apiMessage = data['message']?.toString().trim();
      throw (apiMessage != null && apiMessage.isNotEmpty)
          ? apiMessage
          : 'Invalid referral code';
    }

    await cacheNotifier.writeCache(
        key: 'user', value: '${data['data']['user']['email']}');
    await cacheNotifier.writeCache(
        key: 'userid', value: '${data['data']['user']['user_id']}');
    await cacheNotifier.writeCache(
        key: 'name', value: '${data['data']['user']['name']}');
    await cacheNotifier.writeCache(
        key: 'authtoken', value: '${data['data']['token']}');
  } catch (e) {
    if (e is String) {
      throw e;
    }
    final err = e.toString().toLowerCase();
    if (e is SocketException ||
        e is TimeoutException ||
        err.contains('socketexception') ||
        err.contains('host lookup') ||
        err.contains('failed host lookup') ||
        err.contains('timed out') ||
        err.contains('timeout')) {
      throw 'No Internet Connection';
    }
    if (err.contains('certificate_verify_failed') ||
        err.contains('handshake') ||
        err.contains('certificate') ||
        err.contains('ssl') ||
        err.contains('failed to get temp token')) {
      throw 'Something went wrong. Please check your internet connection and try again.';
    }
    if (err.contains('something went wrong')) {
      throw e.toString();
    }
    debugPrint('applyReferralViaLogin: Error: $e');
    throw 'Something went wrong. Please try again.';
  }
}
