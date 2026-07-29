import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:biblebookapp/Model/category_model.dart';
import 'package:biblebookapp/Model/image_model.dart';
import 'package:biblebookapp/core/api/auth/profile_update.api.dart';
import 'package:biblebookapp/core/library_backup_upload_service.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/utils/debugprint.dart';
import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/calendar_screen/model/calendar_model.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/more_apps/model/app_model.dart';
import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/own_referral_code_dialog.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

import '../Model/get_audio_model.dart';

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

List<CalendarModel> _parseCalendarCsvString(String csvString) {
  final lines = csvString.trim().split('\n');
  final dateFormat = DateFormat('dd-MM-yyyy');
  final events = <CalendarModel>[];

  for (final line in lines.skip(1)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final fields = trimmed.split(',');
    if (fields.length < 3) continue;
    try {
      final parsedDate = dateFormat.parse(fields[1].trim());
      events.add(
        CalendarModel(
          date: parsedDate.toString(),
          title: fields[2].trim(),
          canEdit: false,
        ),
      );
    } catch (_) {
      continue;
    }
  }
  return events;
}

Future<List<CalendarModel>> _loadBundledCalendarCsv() async {
  final csvString = await rootBundle.loadString('assets/bibleCalendar.csv');
  return _parseCalendarCsvString(csvString);
}

Future<List<CalendarModel>> downloadAndParseCsv() async {
  try {
    final response = await http.get(
      Uri.parse('https://bibleoffice.com/bibleCalendar/bibleCalendar.csv'),
    );

    final body = response.body.trim();
    if (response.statusCode == 200 && body.startsWith('Day,Date,Content')) {
      final events = _parseCalendarCsvString(body);
      if (events.isNotEmpty) {
        final json = events.map((e) => jsonEncode(e.toJson())).toList();
        await SharPreferences.setListString(SharPreferences.calendarLocal, json);
      }
      return events;
    }
    throw Exception('Failed to download CSV');
  } catch (e) {
    final localData =
        await SharPreferences.getStringList(SharPreferences.calendarLocal);
    if (localData != null && localData.isNotEmpty) {
      return localData
          .map((item) => CalendarModel.fromJson(jsonDecode(item)))
          .toList();
    }
    try {
      final bundled = await _loadBundledCalendarCsv();
      if (bundled.isNotEmpty) {
        final json = bundled.map((e) => jsonEncode(e.toJson())).toList();
        await SharPreferences.setListString(SharPreferences.calendarLocal, json);
      }
      return bundled;
    } catch (_) {
      return [];
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

Future<bool> updateReferralRewardClaimed({
  required int value,
  String? referredBy,
}) async {
  final resolvedReferredBy = referredBy?.trim().isNotEmpty == true
      ? referredBy!.trim()
      : (await cacheNotifier.readCache(key: 'referred_by'))?.toString().trim();
  final result = await ProfileUpdateApi().updateReferralRewardClaimed(
    value: value,
    referredBy: resolvedReferredBy,
  );
  if (result == null || result.isEmpty) return false;
  try {
    final parsed = jsonDecode(result) as Map<String, dynamic>;
    return parsed['status'] == true;
  } catch (_) {
    return false;
  }
}

UserModel? _userModelFromApiPayload(
  Map<String, dynamic> parsed,
  String token,
) {
  final userMap = _userFromAuthResponse(parsed);
  if (userMap != null && userMap['user_id'] != null) {
    return UserModel.fromJson(userMap, token);
  }
  final data = parsed['data'];
  if (data is Map<String, dynamic> && data['user_id'] != null) {
    return UserModel.fromJson(data, token);
  }
  if (data is Map<String, dynamic> &&
      data['user'] is Map<String, dynamic>) {
    return UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
      token,
    );
  }
  return null;
}

/// Additive: sync referrer wallet when [referral_count] grew (logged-in session).
Future<void> syncReferrerCreditsFromSession() async {
  try {
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    final userid = await cacheNotifier.readCache(key: 'userid');
    if (authtoken == null ||
        authtoken.toString().trim().isEmpty ||
        userid == null) {
      return;
    }

    final body =
        await ProfileUpdateApi().fetchLoggedInUserProfileSnapshot();
    if (body == null || body.isEmpty) return;

    final parsed = jsonDecode(body);
    if (parsed is! Map<String, dynamic>) return;

    final user = _userModelFromApiPayload(
      parsed,
      authtoken.toString(),
    );
    if (user == null) return;

    debugPrint('syncReferrerCreditsFromSession referral_count → '
        '${user.referralCount}');
    await syncReferrerCreditsFromProfile(user);
  } catch (e) {
    debugPrint('syncReferrerCreditsFromSession: $e');
  }
}

/// Grant local wallet credits to the referrer when API [referral_count] increases.
/// Wallet credits are device-local; without this, User 1 never sees referral rewards.
Future<void> syncReferrerCreditsFromProfile(UserModel user) async {
  final count = user.referralCount ?? 0;
  if (count <= 0) return;

  const rewardPerReferral = 100;
  final prefs = await SharedPreferences.getInstance();
  final key = 'local_referral_count_credited_${user.uid}';
  final alreadyCredited = prefs.getInt(key) ?? 0;
  if (count <= alreadyCredited) return;

  final delta = count - alreadyCredited;
  await WalletService.addCredits(delta * rewardPerReferral);
  await prefs.setInt(key, count);
  debugPrint(
      'syncReferrerCreditsFromProfile: credited ${delta * rewardPerReferral} '
      'for $delta new referral(s) (count=$count)');
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

Map<String, dynamic>? _userFromAuthResponse(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map && data['user'] is Map) {
    return Map<String, dynamic>.from(data['user'] as Map);
  }
  if (response['user'] is Map) {
    return Map<String, dynamic>.from(response['user'] as Map);
  }
  return null;
}

String? _readStringField(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

bool _profileUpdateSucceeded(String? body) {
  if (body == null || body.isEmpty) return false;
  try {
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    final status = parsed['status'];
    if (status == true || status == 1 || status == '1' || status == 'true') {
      return true;
    }
    final statusCode = parsed['status_code'];
    if (statusCode == 200 && status != false && status != 'false') {
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}

bool _isMisleadingLoginSuccessMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final lower = message.toLowerCase();
  return lower.contains('logged in successfully') ||
      lower.contains('login successful');
}

String _referralApplyFailureMessage(
  String? profileResult, {
  bool forLoggedInSession = false,
}) {
  final profileError = _profileUpdateErrorMessage(profileResult);
  final signUpFallback = 'Enter this referral ID on the Sign Up screen';
  final loggedInFallback =
      'Unable to apply referral code. Please check the code and try again.';
  final genericFallback =
      forLoggedInSession ? loggedInFallback : signUpFallback;

  if (profileError == null || profileError.isEmpty) {
    return genericFallback;
  }
  final lower = profileError.toLowerCase();
  if (lower.contains('referral') ||
      lower.contains('already applied') ||
      lower.contains('already used') ||
      lower.contains('does not exist') ||
      lower.contains('expired')) {
    return profileError;
  }
  if (lower.contains('email already exists') ||
      lower.contains('validation failed') ||
      lower.contains('page not found') ||
      lower.contains('password') ||
      lower.contains('the email field') ||
      lower.contains('the name field')) {
    return genericFallback;
  }
  return profileError;
}

String? _profileUpdateErrorMessage(String? body) {
  if (body == null || body.isEmpty) return null;
  try {
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    if (parsed['status'] == true) return null;

    final errors = parsed['errors'];
    if (errors is Map) {
      for (final key in [
        'referral_code',
        'referred_by',
        'referral',
        'value',
      ]) {
        final fieldErrors = errors[key];
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          return fieldErrors.first.toString();
        }
      }
      for (final entry in errors.entries) {
        final fieldErrors = entry.value;
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          return fieldErrors.first.toString();
        }
      }
    }

    final message = parsed['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'validation failed') {
      return message;
    }
  } catch (_) {}
  return null;
}

bool _hasReferralErrorInResponse(Map<String, dynamic> response) {
  final errors = response['errors'];
  if (errors is Map) {
    for (final key in ['referral_code', 'referred_by', 'referral']) {
      final fieldErrors = errors[key];
      if (fieldErrors is List && fieldErrors.isNotEmpty) return true;
      if (fieldErrors is String && fieldErrors.trim().isNotEmpty) return true;
    }
  }
  final message = response['message']?.toString().toLowerCase() ?? '';
  return message.contains('invalid referral') ||
      (message.contains('invalid') && message.contains('referral'));
}

Map<String, String> _referralApplyLoginBody({
  required String email,
  required String password,
  required String referralCode,
}) {
  final code = referralCode.trim();
  // Only referred_by — referral_code is the user's OWN invite code field.
  // Sending the friend's code as referral_code confuses apply / is ignored.
  return {
    'email': email,
    'password': password,
    'app_id': BibleInfo.appID.toString(),
    'device_type': Platform.isIOS ? 'iOS' : 'Android',
    'referred_by': code,
  };
}

Future<Map<String, dynamic>?> _fetchLoginProfile({
  required String email,
  required String password,
  String? referralCode,
}) async {
  final token = await getTempToken();
  final body = <String, String>{
    'email': email,
    'password': password,
    'app_id': BibleInfo.appID.toString(),
    'device_type': Platform.isIOS ? 'iOS' : 'Android',
  };
  if (referralCode != null && referralCode.trim().isNotEmpty) {
    body['referral_code'] = referralCode.trim();
  }
  final resp =
      await http.post(Uri.parse(Api.login), headers: <String, String>{
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $token'
  }, body: body);
  final decoded = jsonDecode(resp.body);
  if (decoded is! Map<String, dynamic>) return null;
  return decoded;
}

bool _referralWasAcceptedByApi(
  Map<String, dynamic> response, {
  required String enteredCode,
  String? initialReferredBy,
}) {
  final code = enteredCode.trim();
  final user = _userFromAuthResponse(response);
  final data = response['data'];
  final dataMap = data is Map<String, dynamic> ? data : null;

  final referredBy = _readStringField(user, [
        'referred_by',
        'referredBy',
        'you_referred_by',
        'refered_by',
        'referrer_code',
      ]) ??
      _readStringField(dataMap, [
        'referred_by',
        'referredBy',
        'you_referred_by',
        'refered_by',
        'referrer_code',
      ]);

  final hadReferrer =
      initialReferredBy != null && initialReferredBy.trim().isNotEmpty;
  final hasReferrerNow =
      referredBy != null && referredBy.trim().isNotEmpty;

  if (!hadReferrer && hasReferrerNow) {
    return true;
  }

  if (hasReferrerNow &&
      referredBy.toUpperCase() == code.toUpperCase()) {
    return true;
  }

  for (final container in [user, dataMap, response]) {
    if (container == null) continue;
    for (final key in [
      'used_referral_code',
      'applied_referral_code',
      'referral_code_used',
    ]) {
      final value = container[key]?.toString().trim();
      if (value != null &&
          value.isNotEmpty &&
          value.toUpperCase() == code.toUpperCase()) {
        return true;
      }
    }
  }

  for (final container in [user, dataMap, response]) {
    if (container == null) continue;
    final applied = container['referral_applied'];
    if (applied == true ||
        applied == 1 ||
        applied == '1' ||
        applied == 'true') {
      return true;
    }
  }

  final message = response['message']?.toString().toLowerCase() ?? '';
  if (message.contains('referral') &&
      (message.contains('applied') ||
          message.contains('success') ||
          message.contains('accepted'))) {
    return true;
  }

  return false;
}

Future<String?> registerUser(
    {required String email,
    required String name,
    required String password,
    String? referredBy}) async {
  // final CacheNotifier cacheNotifier = CacheNotifier();
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedCategories =
        prefs.getStringList('selected_categories') ?? [];
    final token = await getTempToken();
    final inviteCode = referredBy?.trim() ?? '';
    final body = <String, String>{
      'name': name,
      'email': email,
      'password': password,
      "device_type": Platform.isIOS ? "iOS" : "Android",
      'password_confirmation': password,
      'app_id': BibleInfo.appID,
      'interested_vc_tags': selectedCategories.toString()
    };
    // Backend accepts invite only at register (profile-update cannot set it).
    if (inviteCode.isNotEmpty) {
      body['referred_by'] = inviteCode;
    }
    final resp =
        await http.post(Uri.parse(Api.register), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: body);
    final data = jsonDecode(resp.body);
    debugPrint("sign up - $data ");

    if (data['status']) {
      await cacheNotifier.writeCache(
          key: "user", value: '${data['data']['user']['email']}');

      await cacheNotifier.writeCache(
          key: "userid", value: '${data['data']['user']['user_id']}');

      await cacheNotifier.writeCache(
          key: "name", value: '${data['data']['user']['name']}');
      await cacheNotifier.writeCache(
          key: "authtoken", value: '${data['data']['token']}');
      final registeredReferralCode = _referralCodeFromAuthResponse(data);
      if (registeredReferralCode != null &&
          registeredReferralCode.trim().isNotEmpty) {
        await cacheNotifier.writeCache(
            key: OwnReferralCodeDialog.referralCacheKey,
            value: registeredReferralCode.trim());
      }
      if (inviteCode.isNotEmpty) {
        final userMap = data['data'] is Map
            ? data['data']['user']
            : null;
        final fromApi = userMap is Map
            ? (userMap['referred_by'] ?? userMap['referredBy'] ?? '')
                .toString()
                .trim()
            : '';
        final stored =
            fromApi.isNotEmpty ? fromApi : inviteCode;
        await cacheNotifier.writeCache(key: 'referred_by', value: stored);
      }
      Constants.showToast("Account Created Successfully");
      return registeredReferralCode;
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
      // Apply invite via referred_by only (referral_code is own invite id).
      body['referred_by'] = referralCode.trim();
    }
    final resp =
        await http.post(Uri.parse(Api.login), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: body);
    final data = jsonDecode(resp.body);
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
      final referralCode = _referralCodeFromAuthResponse(data);
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        await cacheNotifier.writeCache(
            key: OwnReferralCodeDialog.referralCacheKey,
            value: referralCode.trim());
      }

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
      if (user.referralCode != null && user.referralCode!.trim().isNotEmpty) {
        await cacheNotifier.writeCache(
            key: OwnReferralCodeDialog.referralCacheKey,
            value: user.referralCode!.trim());
      }
      debugPrint('LOGIN parsed referral fields:');
      debugPrint('  referred_by              → ${user.referredBy ?? ''}');
      debugPrint('  referral_count           → ${user.referralCount}');
      debugPrint(
          '  referral_reward_claimed  → ${user.referralRewardClaimed}');
      // Additive: credit referrer locally when backend referral_count grew.
      await syncReferrerCreditsFromProfile(user);
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

/// Apply a friend's referral code while the user is already signed in
/// (Account → Enter Referral Code). Uses the existing profile `referred_by`
/// update path — does not alter login/signup apply flows.
Future<void> applyReferralWhileLoggedIn({
  required String referralCode,
  String? ownReferralCode,
  String? initialReferredBy,
  int? initialReferralRewardClaimed,
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

  final alreadyApplied =
      (initialReferredBy != null && initialReferredBy.trim().isNotEmpty) ||
          ((initialReferralRewardClaimed ?? 0) > 0);
  if (alreadyApplied) {
    throw 'Referral code already applied';
  }

  final cachedReferredBy =
      await cacheNotifier.readCache(key: 'referred_by');
  if (cachedReferredBy != null &&
      cachedReferredBy.toString().trim().isNotEmpty) {
    throw 'Referral code already applied';
  }

  final email =
      (await cacheNotifier.readCache(key: 'user'))?.toString().trim() ?? '';
  final name =
      (await cacheNotifier.readCache(key: 'name'))?.toString().trim() ?? '';
  if (email.isEmpty || name.isEmpty) {
    throw 'Unable to apply referral code. Please sign out and sign in again, then try once more.';
  }
  final profileResult = await ProfileUpdateApi().updateReferredBy(
    referralCode: code,
    email: email,
    name: name,
  );
  if (!_profileUpdateSucceeded(profileResult)) {
    throw _referralApplyFailureMessage(
      profileResult,
      forLoggedInSession: true,
    );
  }
  await cacheNotifier.writeCache(key: 'referred_by', value: code);
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

  // Only block when THIS logged-in account already has a referrer from Login API.
  // Local cache can be leftover from another attempt/user on the same device.
  final apiAlreadyApplied =
      initialReferredBy != null && initialReferredBy.trim().isNotEmpty;
  if (apiAlreadyApplied) {
    throw 'Referral code already applied';
  }

  final cachedReferredBy =
      await cacheNotifier.readCache(key: 'referred_by');
  if (cachedReferredBy != null &&
      cachedReferredBy.toString().trim().isNotEmpty) {
    // Login for this email has empty referred_by → cache is stale; clear and continue.
    debugPrint(
        'applyReferralViaLogin: clearing stale referred_by cache '
        '("${cachedReferredBy.toString()}") — Login referred_by is empty for this email');
    await cacheNotifier.writeCache(key: 'referred_by', value: '');
  }

  try {
    final token = await getTempToken();
    final loginBody = _referralApplyLoginBody(
      email: email,
      password: password,
      referralCode: code,
    );
    debugPrint('applyReferralViaLogin REQUEST body: $loginBody');
    final resp =
        await http.post(Uri.parse(Api.login), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: loginBody);
    debugPrint(
        'applyReferralViaLogin HTTP status: ${resp.statusCode}, raw body: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    debugPrint('applyReferralViaLogin parsed response: $data');

    // Login always authenticates with status true/200 even when referral is
    // ignored. Empty referred_by means the code was NOT applied (see logs).
    final status = data['status'];
    final statusTrue =
        status == true || status == 1 || status == '1' || status == 'true';
    final statusFalse =
        status == false || status == 0 || status == '0' || status == 'false';
    final message = data['message']?.toString().toLowerCase() ?? '';
    final messageSaysInvalid = message.contains('invalid referral') ||
        (message.contains('invalid') && message.contains('referral')) ||
        message.contains('referral code not found') ||
        message.contains('referral not found');

    // Only hard-fail when login itself fails or the API explicitly says the
    // code is invalid. Soft referral errors in a successful login payload must
    // not block the existing profile / apply-referral fallback below.
    if (resp.statusCode != 200 || statusFalse || !statusTrue) {
      throw 'Invalid Referral code';
    }
    if (messageSaysInvalid) {
      throw 'Invalid Referral code';
    }

    final responseData = data['data'];
    if (responseData is! Map<String, dynamic> ||
        responseData['user'] is! Map<String, dynamic> ||
        responseData['token'] == null) {
      throw 'Invalid Referral code';
    }

    final userMap = responseData['user'] as Map<String, dynamic>;
    final referredByFromApi =
        (userMap['referred_by'] ?? userMap['referredBy'] ?? '')
            .toString()
            .trim();
    final rewardClaimedRaw =
        userMap['referral_reward_claimed'] ?? userMap['referralRewardClaimed'];
    final rewardClaimed = rewardClaimedRaw is int
        ? rewardClaimedRaw
        : int.tryParse(rewardClaimedRaw?.toString() ?? '');

    await cacheNotifier.writeCache(
        key: 'user', value: '${userMap['email']}');
    await cacheNotifier.writeCache(
        key: 'userid', value: '${userMap['user_id']}');
    await cacheNotifier.writeCache(
        key: 'name', value: '${userMap['name']}');
    await cacheNotifier.writeCache(
        key: 'authtoken', value: '${responseData['token']}');

    // Account-level guards (survive reinstall): if this user already entered a
    // referral code or already claimed joining credit, do not apply again.
    if (rewardClaimed != null && rewardClaimed > 0) {
      if (referredByFromApi.isNotEmpty) {
        await cacheNotifier.writeCache(
            key: 'referred_by', value: referredByFromApi);
      }
      throw 'Referral code already applied';
    }
    if (referredByFromApi.isNotEmpty) {
      await cacheNotifier.writeCache(
          key: 'referred_by', value: referredByFromApi);
      throw 'Referral code already applied';
    }

    // Login often returns 200/true with empty referred_by even for a valid
    // code (it only authenticates). Confirm apply via profile / apply-referral.
    debugPrint(
        'applyReferralViaLogin: Login left referred_by empty; '
        'confirming via profile apply-referral');
    final profileResult = await ProfileUpdateApi().updateReferredBy(
      referralCode: code,
      email: email,
      name: userMap['name']?.toString(),
      password: password,
    );
    if (_profileUpdateSucceeded(profileResult)) {
      debugPrint('applyReferralViaLogin: referral accepted by profile API');
    } else {
      debugPrint(
          'applyReferralViaLogin: profile apply failed '
          '(${_profileUpdateErrorMessage(profileResult) ?? 'unknown'})');
      throw _referralApplyFailureMessage(profileResult);
    }

    await cacheNotifier.writeCache(key: 'referred_by', value: code);

    final user = UserModel.fromJson(
        userMap, responseData['token']!.toString());
    debugPrint('applyReferralViaLogin parsed referral fields:');
    debugPrint('  referred_by              → ${user.referredBy ?? code}');
    debugPrint('  referral_count           → ${user.referralCount}');
    debugPrint(
        '  referral_reward_claimed  → ${user.referralRewardClaimed}');
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
