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
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
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
  /// PDF AuthHub profile: `POST /api/profile` (app_id + user_id).
  static String profile =
      'https://bibleoffice.com/authhub/API/public/api/profile';
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

String _calendarBundleId() {
  return Platform.isIOS
      ? BibleInfo.ios_Bundle_Id
      : BibleInfo.android_Package_Name;
}

Future<String?> _resolveCalendarTradition() async {
  final cached =
      await SharPreferences.getString(SharPreferences.calendarTradition);
  if (cached != null && cached.trim().isNotEmpty) return cached.trim();

  final bundle = _calendarBundleId();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final uri = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/calendar_api.php'
    '?bundle=${Uri.encodeQueryComponent(bundle)}'
    '&date=$today',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) return null;
  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return null;
  final tradition = decoded['tradition']?.toString().trim();
  if (tradition == null || tradition.isEmpty) return null;
  await SharPreferences.setString(SharPreferences.calendarTradition, tradition);
  return tradition;
}

Future<Map<String, dynamic>?> _loadCachedLiturgicalJson() async {
  final raw = await SharPreferences.getString(SharPreferences.calendarDataJson);
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

Future<Map<String, dynamic>?> _fetchLiturgicalDataFile(String tradition) async {
  final url = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/data/$tradition.json',
  );
  final etag =
      await SharPreferences.getString(SharPreferences.calendarDataEtag) ?? '';
  final headers = <String, String>{};
  if (etag.isNotEmpty) {
    headers['If-None-Match'] = etag;
  }
  final response = await http.get(url, headers: headers);
  if (response.statusCode == 304) {
    return _loadCachedLiturgicalJson();
  }
  if (response.statusCode != 200 || response.body.trim().isEmpty) {
    return _loadCachedLiturgicalJson();
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return _loadCachedLiturgicalJson();
  final map = Map<String, dynamic>.from(decoded);
  await SharPreferences.setString(
    SharPreferences.calendarDataJson,
    response.body,
  );
  final newEtag = response.headers['etag'] ?? '';
  if (newEtag.isNotEmpty) {
    await SharPreferences.setString(SharPreferences.calendarDataEtag, newEtag);
  }
  return map;
}

/// Ensures tradition JSON is cached (additive; feast-list path unchanged).
Future<Map<String, dynamic>?> ensureLiturgicalDataCached() async {
  final tradition = await _resolveCalendarTradition();
  if (tradition == null) return _loadCachedLiturgicalJson();
  try {
    return await _fetchLiturgicalDataFile(tradition);
  } catch (_) {
    return _loadCachedLiturgicalJson();
  }
}

/// Per-day liturgical API (method A) — used with a 6 h client cache.
Future<Map<String, dynamic>?> fetchLiturgicalDayFromApi(DateTime date) async {
  final bundle = _calendarBundleId();
  final iso = DateFormat('yyyy-MM-dd').format(
    DateTime(date.year, date.month, date.day),
  );
  final uri = Uri.parse(
    'https://bibleoffice.com/bibleCalendar/calendar_api.php'
    '?bundle=${Uri.encodeQueryComponent(bundle)}'
    '&date=$iso',
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
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

/// Additive: check referrer [referral_count] (logged-in session).
/// Credits are claimed via Home popup — no silent credit here.
Future<void> syncReferrerCreditsFromSession() async {
  try {
    final pending = await fetchPendingReferrerReward();
    if (pending == null || pending.pendingCount <= 0) return;
    debugPrint(
        'syncReferrerCreditsFromSession: pending ${pending.pendingCount} '
        'referral(s) → ${pending.credits} credits (claim on Home)');
  } catch (e) {
    debugPrint('syncReferrerCreditsFromSession: $e');
  }
}

/// Pending referrer reward from backend [referral_count] vs local claim watermark.
class PendingReferrerReward {
  const PendingReferrerReward({
    required this.userId,
    required this.referralCount,
    required this.alreadyCredited,
  });

  final String userId;
  final int referralCount;
  final int alreadyCredited;

  static const rewardPerReferral = 100;

  int get pendingCount =>
      referralCount > alreadyCredited ? referralCount - alreadyCredited : 0;

  int get credits => pendingCount * rewardPerReferral;

  String get _prefsKey => 'local_referral_count_credited_$userId';
}

int? _parseReferralInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

/// Persist referral fields from login / auth (profile snapshot often omits them).
Future<void> cacheReferralFieldsFromUser(UserModel user) async {
  if (user.referralCount != null) {
    await cacheNotifier.writeCache(
        key: 'referral_count', value: '${user.referralCount}');
  }
  if (user.referralRewardClaimed != null) {
    await cacheNotifier.writeCache(
        key: 'referral_reward_claimed',
        value: '${user.referralRewardClaimed}');
  }
  if (user.referredBy != null && user.referredBy!.trim().isNotEmpty) {
    await cacheNotifier.writeCache(
        key: 'referred_by', value: user.referredBy!.trim());
  }
  // Additive PDF fields (cache only — claim logic unchanged).
  if (user.referralRewardCredits != null) {
    await cacheNotifier.writeCache(
        key: 'referral_reward_credits',
        value: '${user.referralRewardCredits}');
  }
  if (user.totalReferredCount != null) {
    await cacheNotifier.writeCache(
        key: 'total_referred_count', value: '${user.totalReferredCount}');
  }
  if (user.totalClaimedCount != null) {
    await cacheNotifier.writeCache(
        key: 'total_claimed_count', value: '${user.totalClaimedCount}');
  }
  if (user.walletBalance != null) {
    await cacheNotifier.writeCache(
        key: 'wallet_balance', value: '${user.walletBalance}');
  }
}

/// Additive: PDF `POST /api/profile` (app_id + user_id from login/register).
/// Does not replace profile-update snapshot.
Future<Map<String, dynamic>?> fetchAuthHubProfile() async {
  try {
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    if (authtoken == null || authtoken.toString().trim().isEmpty) {
      return null;
    }
    final tempToken = await getTempToken();
    // PDF form: user_id = token from login/register; also try cached user_id.
    final candidates = <String>[
      authtoken.toString().trim(),
      if (userid != null && userid.toString().trim().isNotEmpty)
        userid.toString().trim(),
    ];
    for (final profileUserId in candidates.toSet()) {
      final resp = await http.post(
        Uri.parse(Api.profile),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $tempToken',
        },
        body: <String, String>{
          'app_id': BibleInfo.appID.toString(),
          'user_id': profileUserId,
        },
      );
      debugPrint(
          'fetchAuthHubProfile status=${resp.statusCode} body=${resp.body}');
      if (resp.statusCode < 200 || resp.statusCode >= 300) continue;
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) continue;
      final userMap = _userFromAuthResponse(decoded);
      if (userMap != null) return decoded;
      if (decoded['data'] is Map) return decoded;
    }
  } catch (e) {
    debugPrint('fetchAuthHubProfile: $e');
  }
  return null;
}

/// Additive: merge referral fields from `/api/profile` into cache.
Future<void> syncReferralFieldsFromAuthHubProfile() async {
  final profile = await fetchAuthHubProfile();
  if (profile == null) return;
  final userMap = _userFromAuthResponse(profile);
  if (userMap == null) return;
  final token = (await cacheNotifier.readCache(key: 'authtoken'))?.toString() ??
      '';
  try {
    if (userMap['user_id'] == null) return;
    final user = UserModel.fromJson(userMap, token);
    await cacheReferralFieldsFromUser(user);
    debugPrint(
        'syncReferralFieldsFromAuthHubProfile: referral_count=${user.referralCount} '
        'credits=${user.referralRewardCredits}');
  } catch (e) {
    debugPrint('syncReferralFieldsFromAuthHubProfile parse: $e');
    // Fallback: write raw ints if UserModel cast fails on shape.
    final count = _parseReferralInt(userMap['referral_count']);
    final claimed = _parseReferralInt(userMap['referral_reward_claimed']);
    if (count != null) {
      await cacheNotifier.writeCache(
          key: 'referral_count', value: count.toString());
    }
    if (claimed != null) {
      await cacheNotifier.writeCache(
          key: 'referral_reward_claimed', value: claimed.toString());
    }
  }
}

Future<PendingReferrerReward?> fetchPendingReferrerReward() async {
  try {
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    final userid = await cacheNotifier.readCache(key: 'userid');
    if (authtoken == null ||
        authtoken.toString().trim().isEmpty ||
        userid == null) {
      debugPrint('fetchPendingReferrerReward: not logged in');
      return null;
    }

    final stableUserId = userid.toString();

    // Existing snapshot (name+email required by API). Response may omit
    // referral fields — Login cache is the fallback.
    final body =
        await ProfileUpdateApi().fetchLoggedInUserProfileSnapshot();

    int? apiCount;
    int? apiClaimed;
    if (body != null && body.isNotEmpty) {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final userMap = _userFromAuthResponse(parsed);
        apiCount = _parseReferralInt(userMap?['referral_count']);
        apiClaimed = _parseReferralInt(userMap?['referral_reward_claimed']);
        debugPrint('fetchPendingReferrerReward API user keys → '
            '${userMap?.keys.toList()}');
        debugPrint('fetchPendingReferrerReward API referral_count → $apiCount');
        debugPrint(
            'fetchPendingReferrerReward API referral_reward_claimed → $apiClaimed');
        if (apiCount != null) {
          await cacheNotifier.writeCache(
              key: 'referral_count', value: apiCount.toString());
        }
        if (apiClaimed != null) {
          await cacheNotifier.writeCache(
              key: 'referral_reward_claimed', value: apiClaimed.toString());
        }
      }
    } else {
      debugPrint('fetchPendingReferrerReward: empty snapshot body');
    }

    // Additive: PDF `/api/profile` may return referral_count when snapshot omits it.
    try {
      final hub = await fetchAuthHubProfile();
      final hubUser = hub != null ? _userFromAuthResponse(hub) : null;
      final hubCount = _parseReferralInt(hubUser?['referral_count']);
      final hubClaimed =
          _parseReferralInt(hubUser?['referral_reward_claimed']);
      debugPrint(
          'fetchPendingReferrerReward /api/profile referral_count → $hubCount');
      if (hubCount != null) {
        apiCount = hubCount;
        await cacheNotifier.writeCache(
            key: 'referral_count', value: hubCount.toString());
      }
      if (hubClaimed != null) {
        apiClaimed = hubClaimed;
        await cacheNotifier.writeCache(
            key: 'referral_reward_claimed', value: hubClaimed.toString());
      }
      if (hubUser != null) {
        final credits = _parseReferralInt(hubUser['referral_reward_credits']);
        final totalRef = _parseReferralInt(hubUser['total_referred_count']);
        final totalClaimed = _parseReferralInt(hubUser['total_claimed_count']);
        final wallet = _parseReferralInt(hubUser['wallet_balance']);
        if (credits != null) {
          await cacheNotifier.writeCache(
              key: 'referral_reward_credits', value: credits.toString());
        }
        if (totalRef != null) {
          await cacheNotifier.writeCache(
              key: 'total_referred_count', value: totalRef.toString());
        }
        if (totalClaimed != null) {
          await cacheNotifier.writeCache(
              key: 'total_claimed_count', value: totalClaimed.toString());
        }
        if (wallet != null) {
          await cacheNotifier.writeCache(
              key: 'wallet_balance', value: wallet.toString());
        }
      }
    } catch (e) {
      debugPrint('fetchPendingReferrerReward /api/profile: $e');
    }

    final cachedCount = _parseReferralInt(
        await cacheNotifier.readCache(key: 'referral_count'));
    final cachedClaimed = _parseReferralInt(
        await cacheNotifier.readCache(key: 'referral_reward_claimed'));

    debugPrint(
        'fetchPendingReferrerReward CACHE referral_count → $cachedCount');
    debugPrint(
        'fetchPendingReferrerReward CACHE referral_reward_claimed → $cachedClaimed');

    var count = apiCount ?? cachedCount ?? 0;
    // If only referral_reward_claimed looks like a small referral count, use it.
    if (count <= 0) {
      final claimedHint = apiClaimed ?? cachedClaimed ?? 0;
      if (claimedHint > 0 && claimedHint < 100) {
        count = claimedHint;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final watermarkKey = 'local_referral_count_credited_$stableUserId';
    final alreadyCredited = prefs.getInt(watermarkKey) ?? 0;

    debugPrint(
        'fetchPendingReferrerReward RESULT count=$count '
        'alreadyCredited=$alreadyCredited '
        'pending=${count > alreadyCredited ? count - alreadyCredited : 0}');

    if (count <= 0 || count <= alreadyCredited) return null;

    return PendingReferrerReward(
      userId: stableUserId,
      referralCount: count,
      alreadyCredited: alreadyCredited,
    );
  } catch (e) {
    debugPrint('fetchPendingReferrerReward: $e');
    return null;
  }
}

Future<PendingReferrerReward?> pendingReferrerRewardFromProfile(
  UserModel user,
) async {
  await cacheReferralFieldsFromUser(user);

  final count = user.referralCount ?? 0;
  if (count <= 0) return null;

  final userid = await cacheNotifier.readCache(key: 'userid');
  final stableUserId = (userid ?? user.uid).toString();

  final prefs = await SharedPreferences.getInstance();
  final key = 'local_referral_count_credited_$stableUserId';
  final alreadyCredited = prefs.getInt(key) ?? 0;
  if (count <= alreadyCredited) return null;

  return PendingReferrerReward(
    userId: stableUserId,
    referralCount: count,
    alreadyCredited: alreadyCredited,
  );
}

/// Grant local wallet credits for unclaimed [referral_count] growth (100 each).
Future<bool> claimPendingReferrerReward(PendingReferrerReward pending) async {
  if (pending.pendingCount <= 0) return false;

  final prefs = await SharedPreferences.getInstance();
  final key = pending._prefsKey;
  final alreadyCredited = prefs.getInt(key) ?? 0;
  if (pending.referralCount <= alreadyCredited) return false;

  final delta = pending.referralCount - alreadyCredited;
  final credits = delta * PendingReferrerReward.rewardPerReferral;
  await WalletService.addCredits(credits);
  await prefs.setInt(key, pending.referralCount);
  debugPrint(
      'claimPendingReferrerReward: claimed $credits for $delta referral(s) '
      '(count=${pending.referralCount})');
  return true;
}

/// Note pending referrer credits for Home claim popup (no silent credit).
Future<void> syncReferrerCreditsFromProfile(UserModel user) async {
  await cacheReferralFieldsFromUser(user);
  final pending = await pendingReferrerRewardFromProfile(user);
  if (pending == null || pending.pendingCount <= 0) return;
  debugPrint(
      'syncReferrerCreditsFromProfile: pending ${pending.pendingCount} '
      'referral(s) → ${pending.credits} credits (claim on Home)');
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
  // PDF /api/profile sometimes nests fields under data (no user wrapper).
  if (data is Map &&
      (data.containsKey('referral_count') ||
          data.containsKey('referral_code') ||
          data.containsKey('user_id') ||
          data.containsKey('email'))) {
    return Map<String, dynamic>.from(data);
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
    final statusTrue =
        status == true || status == 1 || status == '1' || status == 'true';
    // Require an explicit success status — status_code 200 alone is not enough
    // (invalid referral responses often still return 200).
    if (!statusTrue) return false;
    if (_hasReferralErrorInResponse(parsed)) return false;
    final message = parsed['message']?.toString().toLowerCase() ?? '';
    if (message.contains('invalid') &&
        (message.contains('referral') || message.contains('referred'))) {
      return false;
    }
    return true;
  } catch (_) {
    return false;
  }
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
  final signUpFallback = 'Enter this referral code on the Sign Up screen';
  final invalidFallback = 'Invalid Referral code';
  final genericFallback =
      forLoggedInSession ? invalidFallback : signUpFallback;

  if (profileError == null || profileError.isEmpty) {
    return genericFallback;
  }
  final lower = profileError.toLowerCase();
  if (lower.contains('already applied') ||
      lower.contains('already used')) {
    return 'Referral code already applied';
  }
  if (lower.contains('own referral') ||
      (lower.contains('own') && lower.contains('referral'))) {
    return 'You cannot use your own referral code';
  }
  if (lower.contains('invalid') ||
      lower.contains('not found') ||
      lower.contains('does not exist') ||
      lower.contains('referred') ||
      lower.contains('referral')) {
    return invalidFallback;
  }
  if (lower.contains('email already exists') ||
      lower.contains('validation failed') ||
      lower.contains('page not found') ||
      lower.contains('password') ||
      lower.contains('the email field') ||
      lower.contains('the name field')) {
    return genericFallback;
  }
  return forLoggedInSession ? invalidFallback : profileError;
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
  // Keep referred_by (existing). Also send referral_code (PDF register/login).
  return {
    'email': email,
    'password': password,
    'app_id': BibleInfo.appID.toString(),
    'device_type': Platform.isIOS ? 'iOS' : 'Android',
    'referred_by': code,
    'referral_code': code,
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
    final code = referralCode.trim();
    // PDF uses referral_code; keep referred_by for existing apply path.
    body['referral_code'] = code;
    body['referred_by'] = code;
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
    // Backend accepts invite at register. Keep referred_by; also send
    // referral_code (PDF Postman field for friend's invite code).
    if (inviteCode.isNotEmpty) {
      body['referred_by'] = inviteCode;
      body['referral_code'] = inviteCode;
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
      // Additive: pull PDF /api/profile fields after register.
      await syncReferralFieldsFromAuthHubProfile();
      await PrayerWallLocalStore.clearAccountScopedData();
      await PrayerWallService.resolveIdentityUser(
        email: '${data['data']['user']['email']}',
      );
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
      // Keep referred_by (existing). Also send referral_code (PDF).
      final code = referralCode.trim();
      body['referred_by'] = code;
      body['referral_code'] = code;
    }
    debugPrint('========== SIGN IN REQUEST ==========');
    debugPrint('POST ${Api.login}');
    for (final entry in body.entries) {
      if (entry.key == 'password') {
        debugPrint('  ${entry.key} → *** (${entry.value.length} chars)');
      } else {
        debugPrint('  ${entry.key} → ${entry.value}');
      }
    }
    debugPrint('  Authorization → Bearer {temp_token}');
    debugPrint('=====================================');
    final resp =
        await http.post(Uri.parse(Api.login), headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $token'
    }, body: body);
    final data = jsonDecode(resp.body);
    debugPrint('========== SIGN IN RESPONSE ==========');
    debugPrint('  status_code → ${resp.statusCode}');
    debugPrint('  status      → ${data['status']}');
    debugPrint('  message     → ${data['message']}');
    if (data['status'] == true && data['data'] != null) {
      final userData = data['data']['user'];
      final authToken = data['data']['token']?.toString() ?? '';
      debugPrint('  email       → ${userData?['email']}');
      debugPrint('  name        → ${userData?['name']}');
      debugPrint('  user_id     → ${userData?['user_id']}');
      debugPrint(
          '  token       → ${authToken.length > 20 ? '${authToken.substring(0, 20)}...' : authToken}');
      if (userData?['referred_by'] != null) {
        debugPrint('  referred_by → ${userData['referred_by']}');
      }
      if (userData?['referral_code'] != null) {
        debugPrint('  referral_code → ${userData['referral_code']}');
      }
    }
    debugPrint('======================================');
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

      // Account switch: drop previous user's Prayer Wall ownership, then resolve.
      await PrayerWallLocalStore.clearAccountScopedData();
      await PrayerWallService.resolveIdentityUser(
        email: '${data['data']['user']['email']}',
      );

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
      await cacheReferralFieldsFromUser(user);
      // Additive: sync PDF /api/profile fields (does not change claim rules).
      await syncReferralFieldsFromAuthHubProfile();
      // Pending credits claimed via Home popup (no silent credit).
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
    throw 'Please enter a referral code';
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

  final profileResult = await ProfileUpdateApi().updateReferredBy(
    referralCode: code,
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
    throw 'Please enter a referral code';
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
    );
    if (_profileUpdateSucceeded(profileResult)) {
      debugPrint('applyReferralViaLogin: referral accepted by profile API');
    } else {
      debugPrint(
          'applyReferralViaLogin: profile apply failed '
          '(${_profileUpdateErrorMessage(profileResult) ?? 'unknown'})');
      // Post-login / Account sheet — never redirect users to Sign Up.
      throw _referralApplyFailureMessage(
        profileResult,
        forLoggedInSession: true,
      );
    }

    await cacheNotifier.writeCache(key: 'referred_by', value: code);

    final user = UserModel.fromJson(
        userMap, responseData['token']!.toString());
    debugPrint('applyReferralViaLogin parsed referral fields:');
    debugPrint('  referred_by              → ${user.referredBy ?? code}');
    debugPrint('  referral_count           → ${user.referralCount}');
    debugPrint(
        '  referral_reward_claimed  → ${user.referralRewardClaimed}');
    await cacheReferralFieldsFromUser(user);
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
