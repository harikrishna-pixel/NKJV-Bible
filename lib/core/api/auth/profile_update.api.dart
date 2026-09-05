import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'dart:io';

import 'package:biblebookapp/core/api/auth/temp_token.api.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../Model/auth/temp_token_model.dart';
import '../../../constant/app_api_constant.dart';
import '../../../utils/custom_http.dart';
import '../../notifiers/cache.notifier.dart';

String? _profileImageFromBody(String? body) {
  if (body == null || body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    String? pick(Map<String, dynamic> m) {
      for (final key in [
        'profile_image',
        'profileImage',
        'profile_image_url',
        'image_url',
        'photoURL',
        'photo_url',
      ]) {
        final v = m[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final top = pick(map);
    if (top != null) return top;
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final fromData = pick(dataMap);
      if (fromData != null) return fromData;
      final user = dataMap['user'];
      if (user is Map) {
        return pick(Map<String, dynamic>.from(user));
      }
    }
    final user = map['user'];
    if (user is Map) return pick(Map<String, dynamic>.from(user));
  } catch (_) {}
  return null;
}

/// Merge profile_image URL into action=1 JSON so existing callers can cache it.
String _mergeProfileImageUrl(String body, String imageUrl) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return body;
    final map = Map<String, dynamic>.from(decoded);
    map['profile_image'] = imageUrl;
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      dataMap['profile_image'] = imageUrl;
      final user = dataMap['user'];
      if (user is Map) {
        final userMap = Map<String, dynamic>.from(user);
        userMap['profile_image'] = imageUrl;
        dataMap['user'] = userMap;
      }
      map['data'] = dataMap;
    }
    return jsonEncode(map);
  } catch (_) {
    return body;
  }
}

class ProfileUpdateApi {
  Temptokenapi temptokenapi = Temptokenapi();

  final CacheNotifier cacheNotifier = CacheNotifier();

  /// Resolves cached display name / email for profile-update validation
  /// (API requires both when action=1). Does not change call-site logic.
  Future<({String name, String email})> _cachedNameAndEmail({
    String? name,
    String? email,
  }) async {
    var resolvedName = (name ?? '').trim();
    var resolvedEmail = (email ?? '').trim();

    if (resolvedName.isEmpty) {
      final cachedName = await cacheNotifier.readCache(key: 'name');
      resolvedName = cachedName?.toString().trim() ?? '';
    }
    if (resolvedEmail.isEmpty) {
      final cachedEmail = await cacheNotifier.readCache(key: 'useremail') ??
          await cacheNotifier.readCache(key: 'user');
      resolvedEmail = cachedEmail?.toString().trim() ?? '';
    }

    return (name: resolvedName, email: resolvedEmail);
  }

  Future updateprofile(
      {required email,
      required name,
      appversion,
      deviceversion,
      devicemodel,
      devicelocale,
      devicetimezone,
      File? profileImage}) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      // var tokendata = await temptokenapi.gettokenaccess();
      // final data = Temptoken.fromJson(jsonDecode(tokendata));
      // if (data.statusCode == 200) {
      //   if (data.data!.tempAccessToken != null) {
      //  devtools.log("access token is ${data.data!.tempAccessToken}");
      final payload = {
        "email": email,
        "name": name,
        "action": "1",
        "user_id": userid.toString(),
        // "app_version": appversion ?? "1.0.0",
        // "device_type": "Android",
        // //"device_type": Platform.isAndroid ? "Android" : "ios",
        // "device_version": deviceversion ?? "15.2",
        // "device_model": devicemodel ?? "iPhone 16",
        // "device_locale": devicelocale ?? "en-US",
        // "device_timezone": devicetimezone ?? "America/New_York",
        "app_id": BibleInfo.appID,
      };

      print('========== profile-update Data ==========');
      print('URL: $uri');
      print('fields: $payload');
      print(
          'profile_image: ${profileImage == null ? "none" : profileImage.path}');
      if (profileImage != null) {
        print('profile_image size: ${await profileImage.length()} bytes');
      }
      print('========== End profile-update Data ==========');

      // Existing action=1 name/email update — unchanged.
      final plain = await CustomHttp().postwithtoken(
        path: uri,
        //token: data.data!.tempAccessToken.toString(),
        token: authtoken,
        data: payload,
      );
      if (plain == null) {
        devtools.log("lprofile update api  is not found");
        return null;
      }
      var body = plain.body;
      final statuscode = plain.statusCode;

      print('profile-update (action 1) response: $statuscode - $body');
      devtools.log("profile update api msg is $statuscode - $body");

      // Additive: Profile Image requires action=3 + multipart file field
      // profile_image (jpg/jpeg/png/webp, max 15MB). Returns full URL.
      if (profileImage != null && await profileImage.exists()) {
        final imageUrl = await _uploadProfileImageAction3(
          uri: uri,
          authtoken: authtoken,
          userId: userid.toString(),
          profileImage: profileImage,
        );
        print('profile-update (action 3) profile_image URL → ${imageUrl ?? "empty"}');
        if (imageUrl != null && imageUrl.isNotEmpty && body.isNotEmpty) {
          body = _mergeProfileImageUrl(body, imageUrl);
        }
      }

      if (body.isNotEmpty) {
        return body;
      } else {
        devtools.log("lprofile update api  is not found");
        return null;
      }
      // } else {
      //   devtools.log("access token is null");
      //   return null;
      // }
      // } else {
      //   devtools.log("access token is not found");
      //   return null;
      // }
    } catch (e) {
      Constants.showToast('Check your Internet connection');
      devtools.log("profile update api error is $e");
      return null;
    }
  }

  /// API action 3: multipart upload field `profile_image`.
  Future<String?> _uploadProfileImageAction3({
    required Uri uri,
    required dynamic authtoken,
    required String userId,
    required File profileImage,
  }) async {
    try {
      final lower = profileImage.path.toLowerCase();
      String filename = 'profile.jpg';
      MediaType contentType = MediaType('image', 'jpeg');
      if (lower.endsWith('.png')) {
        filename = 'profile.png';
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.webp')) {
        filename = 'profile.webp';
        contentType = MediaType('image', 'webp');
      } else if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) {
        filename = 'profile.jpg';
        contentType = MediaType('image', 'jpeg');
      }

      final request = http.MultipartRequest('POST', uri);
      if (authtoken != null && authtoken.toString().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${authtoken.toString()}';
      }
      request.fields['action'] = '3';
      request.fields['user_id'] = userId;
      request.fields['app_id'] = BibleInfo.appID.toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          profileImage.path,
          filename: filename,
          contentType: contentType,
        ),
      );

      print(
          'Sending profile-update action=3 multipart profile_image '
          'file=$filename type=${contentType.mimeType} '
          'size=${await profileImage.length()}');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      print(
          'profile-update (action 3) response: ${response.statusCode} - ${response.body}');
      return _profileImageFromBody(response.body);
    } catch (e) {
      print('profile-update action 3 error: $e');
      return null;
    }
  }

  Future<String?> updateReferralRewardClaimed({
    required int value,
    String? referredBy,
    String? email,
    String? name,
  }) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');

    try {
      final userId = userid.toString();
      final referredByCode = referredBy?.trim() ?? '';
      final identity = await _cachedNameAndEmail(name: name, email: email);

      // Prime with name+email only (satisfies validation). Do NOT send email
      // on the key update — that returns 400 "Email already exists".
      if (identity.email.isNotEmpty && identity.name.isNotEmpty) {
        await _postProfileUpdate(
          uri: uri,
          authtoken: authtoken,
          logLabel: 'referral_reward_claimed prime',
          payload: {
            'action': '1',
            'email': identity.email,
            'name': identity.name,
            'user_id': userId,
            'app_id': BibleInfo.appID,
          },
        );
      }

      final claimAttempts = <Map<String, String>>[
        {
          'action': '1',
          'key': 'referral_reward_claimed',
          'value': value.toString(),
          'user_id': userId,
          'app_id': BibleInfo.appID,
          if (identity.name.isNotEmpty) 'name': identity.name,
          if (referredByCode.isNotEmpty) 'referred_by': referredByCode,
        },
        {
          'action': '1',
          'key': 'referral_reward_claimed',
          'value': value.toString(),
          'user_id': userId,
          'app_id': BibleInfo.appID,
          if (referredByCode.isNotEmpty) 'referred_by': referredByCode,
        },
      ];

      String? lastBody;
      for (var i = 0; i < claimAttempts.length; i++) {
        final body = await _postProfileUpdate(
          uri: uri,
          authtoken: authtoken,
          logLabel: 'referral_reward_claimed attempt ${i + 1}',
          payload: claimAttempts[i],
        );
        lastBody = body;
        if (_profileResponseSucceeded(body)) {
          return body;
        }
      }

      if (lastBody != null && lastBody.isNotEmpty) {
        return lastBody;
      }
      return null;
    } catch (e) {
      devtools.log('profile update referral_reward_claimed error: $e');
      return null;
    }
  }

  /// Read-only profile snapshot for logged-in users (referral_count sync).
  Future<String?> fetchLoggedInUserProfileSnapshot() async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');

    if (userid == null || authtoken == null) return null;

    final identity = await _cachedNameAndEmail();
    if (identity.email.isEmpty || identity.name.isEmpty) return null;

    return _postProfileUpdate(
      uri: uri,
      authtoken: authtoken,
      logLabel: 'profile snapshot referral',
      payload: {
        'action': '1',
        'email': identity.email,
        'name': identity.name,
        'user_id': userid.toString(),
        'app_id': BibleInfo.appID,
      },
    );
  }

  /// Additive: cached URL first; if missing, snapshot API then cache.
  Future<String?> loadAndCacheProfileImageUrl() async {
    final cached = await cacheNotifier.readCache(key: 'profile_image');
    final cachedUrl = cached?.toString().trim() ?? '';
    if (cachedUrl.isNotEmpty) return cachedUrl;

    try {
      final body = await fetchLoggedInUserProfileSnapshot();
      final url = _profileImageFromBody(body);
      if (url != null && url.isNotEmpty) {
        await cacheNotifier.writeCache(key: 'profile_image', value: url);
        return url;
      }
    } catch (e) {
      debugPrint('loadAndCacheProfileImageUrl: $e');
    }
    return null;
  }

  bool _profileResponseSucceeded(String? body) {
    if (body == null || body.isEmpty) return false;
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final status = parsed['status'];
      final statusTrue =
          status == true || status == 1 || status == '1' || status == 'true';
      // Require explicit success — status_code 200 alone can appear on invalid referral.
      if (!statusTrue) return false;
      final message = parsed['message']?.toString().toLowerCase() ?? '';
      if (message.contains('invalid') &&
          (message.contains('referral') || message.contains('referred'))) {
        return false;
      }
      final errors = parsed['errors'];
      if (errors is Map) {
        for (final key in ['referral_code', 'referred_by', 'referral']) {
          final fieldErrors = errors[key];
          if (fieldErrors is List && fieldErrors.isNotEmpty) return false;
          if (fieldErrors is String && fieldErrors.trim().isNotEmpty) {
            return false;
          }
        }
      }
      return true;
    } catch (_) {}
    return false;
  }

  Future<String?> _getProfileUpdate({
    required Uri uri,
    required String? authtoken,
    required String logLabel,
  }) async {
    devtools.log('profile update $logLabel GET request: $uri');
    debugPrint('profile update $logLabel GET REQUEST: $uri');

    try {
      final headers = <String, String>{};
      if (authtoken != null && authtoken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${authtoken.trim()}';
      }
      final response = await CustomHttp().client.get(uri, headers: headers);

      final statuscode = response.statusCode;
      final body = response.body;
      devtools.log('profile update $logLabel response: $statuscode - $body');
      debugPrint(
          'profile update $logLabel RESPONSE: status=$statuscode body=$body');

      if (body.isNotEmpty) {
        return body;
      }
      return null;
    } catch (e) {
      devtools.log('profile update $logLabel GET error: $e');
      return null;
    }
  }

  Future<String?> _postProfileUpdate({
    required Uri uri,
    required String? authtoken,
    required Map<String, String> payload,
    required String logLabel,
  }) async {
    devtools.log('profile update $logLabel request: $payload');
    debugPrint('profile update $logLabel REQUEST: $payload');

    final response = await CustomHttp().postwithtoken(
      path: uri,
      token: authtoken,
      data: payload,
    );

    final statuscode = response?.statusCode;
    final body = response?.body ?? '';
    devtools.log('profile update $logLabel response: $statuscode - $body');
    debugPrint(
        'profile update $logLabel RESPONSE: status=$statuscode body=$body');

    if (body.isNotEmpty) {
      return body;
    }
    return null;
  }

  Future<String?> _resolveTempAccessToken() async {
    try {
      final raw = await temptokenapi.gettokenaccess();
      if (raw == null) return null;
      final parsed = Temptoken.fromJson(jsonDecode(raw.toString()));
      if (parsed.statusCode != 200) return null;
      return parsed.data?.tempAccessToken?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryApplyReferralCodeGet({
    required String code,
    required String userId,
    required String? authtoken,
    required String logSuffix,
    required Uri Function(String baseUrl, String code, String userId) buildUri,
  }) async {
    final uri = buildUri(AppApiConstant.baseurl, code, userId);
    return _getProfileUpdate(
      uri: uri,
      authtoken: authtoken,
      logLabel: 'apply-referral-code$logSuffix',
    );
  }

  /// Additive: POST dedicated apply (Account). Does not change profile-update
  /// action 1/3/4. Returns body when endpoint exists; null on 404/network miss.
  Future<String?> tryPostApplyReferralCode({
    required String referralCode,
  }) async {
    final code = referralCode.trim();
    if (code.isEmpty) return null;
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    if (authtoken == null || authtoken.toString().trim().isEmpty) return null;

    final appId = BibleInfo.appID.toString();
    final userIdCandidates = <String>[
      authtoken.toString().trim(),
      if (userid != null && userid.toString().trim().isNotEmpty)
        userid.toString().trim(),
    ].toSet().toList();

    final paths = <String>[
      AppApiConstant.applyReferralCodeApi,
      'api/referral/apply',
      'api/referrals/redeem',
    ];

    String? lastBody;
    for (final path in paths) {
      final uri = Uri.parse(AppApiConstant.baseurl + path);
      for (final userId in userIdCandidates) {
        try {
          final payloads = <Map<String, String>>[
            {
              'referral_code': code,
              'app_id': appId,
              'user_id': userId,
            },
            {
              'referred_by': code,
              'referral_code': code,
              'app_id': appId,
              'user_id': userId,
            },
          ];
          for (var i = 0; i < payloads.length; i++) {
            final body = await _postProfileUpdate(
              uri: uri,
              authtoken: authtoken,
              logLabel: 'dedicated-apply $path attempt ${i + 1}',
              payload: payloads[i],
            );
            lastBody = body;
            if (body == null || body.isEmpty) continue;
            // Skip hard 404 HTML/JSON miss — try next path.
            final lower = body.toLowerCase();
            if (lower.contains('page not found') ||
                lower.contains('"status_code":404') ||
                lower.contains('"status_code": 404')) {
              continue;
            }
            if (_profileResponseSucceeded(body) ||
                _referredByUpdateLooksSuccessful(body)) {
              return body;
            }
            // Explicit invalid code from dedicated API — stop early.
            if (lower.contains('invalid referral') ||
                (lower.contains('invalid') && lower.contains('code'))) {
              return body;
            }
          }
        } catch (e) {
          debugPrint('tryPostApplyReferralCode $path: $e');
        }
      }
    }
    return lastBody;
  }

  Future<String?> updateReferredBy({
    required String referralCode,
    String? email,
    String? name,
    String? password,
  }) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');

    try {
      final code = referralCode.trim();
      final appId = BibleInfo.appID.toString();
      final identity = await _cachedNameAndEmail(name: name, email: email);

      // Same as action 4: AuthHub often needs login token as user_id.
      // Cached userid alone can return Decryption Error → false "Invalid".
      final userIdCandidates = <String>[
        if (authtoken != null && authtoken.toString().trim().isNotEmpty)
          authtoken.toString().trim(),
        if (userid != null && userid.toString().trim().isNotEmpty)
          userid.toString().trim(),
      ].toSet().toList();
      if (userIdCandidates.isEmpty) return null;

      String? lastBody;

      for (final userId in userIdCandidates) {
        // Same pattern as referral_reward_claimed: prime with email+name, then
        // set referred_by WITHOUT email. Sending email on that update returns
        // 400 "Email already exists" (seen when applying after Login).
        if (identity.email.isNotEmpty && identity.name.isNotEmpty) {
          await _postProfileUpdate(
            uri: uri,
            authtoken: authtoken,
            logLabel: 'referred_by prime',
            payload: {
              'action': '1',
              'email': identity.email,
              'name': identity.name,
              'user_id': userId,
              'app_id': appId,
            },
          );
        }

        // Do NOT send email. Prefer referred_by (existing); also try referral_code
        // (PDF invite field) as an extra attempt only.
        final profileAttempts = <Map<String, String>>[
          {
            'action': '1',
            'key': 'referred_by',
            'value': code,
            'user_id': userId,
            'app_id': appId,
            if (identity.name.isNotEmpty) 'name': identity.name,
          },
          {
            'action': '1',
            'user_id': userId,
            'app_id': appId,
            'referred_by': code,
            if (identity.name.isNotEmpty) 'name': identity.name,
          },
          // Additive PDF-aligned attempt (does not remove prior attempts).
          {
            'action': '1',
            'user_id': userId,
            'app_id': appId,
            'referred_by': code,
            'referral_code': code,
            if (identity.name.isNotEmpty) 'name': identity.name,
          },
        ];

        for (var i = 0; i < profileAttempts.length; i++) {
          final body = await _postProfileUpdate(
            uri: uri,
            authtoken: authtoken,
            logLabel: 'referred_by profile attempt ${i + 1}',
            payload: profileAttempts[i],
          );
          lastBody = body;
          if (_profileResponseSucceeded(body) ||
              _referredByUpdateLooksSuccessful(body)) {
            return body;
          }
        }
      }

      // apply-referral-code is not deployed on this backend (always 404) —
      // do not call it; it only overwrote the real profile-update error.
      return lastBody;
    } catch (e) {
      devtools.log('profile update referred_by error: $e');
      return null;
    }
  }

  /// Additive: AuthHub often returns status true + "Account Updated Successfully"
  /// when referred_by was set — treat as success for Account apply.
  bool _referredByUpdateLooksSuccessful(String? body) {
    if (body == null || body.isEmpty) return false;
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final status = parsed['status'];
      final statusTrue =
          status == true || status == 1 || status == '1' || status == 'true';
      final code = parsed['status_code'] ?? parsed['statusCode'];
      final codeOk = code == 200 || code == '200' || code == null;
      final message = parsed['message']?.toString().toLowerCase() ?? '';
      if (message.contains('invalid') &&
          (message.contains('referral') || message.contains('referred'))) {
        return false;
      }
      if (!statusTrue && !codeOk) return false;
      return message.contains('updated') ||
          message.contains('success') ||
          statusTrue;
    } catch (_) {
      return false;
    }
  }

  /// Additive: profile-update action=4 — backup [walletBalance] to AuthHub.
  /// Does not change action 1/3 or referral flows.
  Future<bool> updateWalletBalanceAction4(int walletBalance) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    if (authtoken == null || authtoken.toString().trim().isEmpty) {
      print('profile-update (action 4) skipped: not logged in');
      return false;
    }
    // Postman / AuthHub: user_id is login token; also try cached user_id.
    final candidates = <String>[
      authtoken.toString().trim(),
      if (userid != null && userid.toString().trim().isNotEmpty)
        userid.toString().trim(),
    ];
    final balance = walletBalance < 0 ? 0 : walletBalance;

    for (final userId in candidates.toSet()) {
      final payload = <String, String>{
        'action': '4',
        'user_id': userId,
        'app_id': BibleInfo.appID.toString(),
        'wallet_balance': balance.toString(),
      };
      print('========== profile-update Data (action 4) ==========');
      print('URL: $uri');
      print('fields: $payload');
      print('========== End profile-update Data ==========');
      try {
        final plain = await CustomHttp().postwithtoken(
          path: uri,
          token: authtoken,
          data: payload,
        );
        if (plain == null) continue;
        print(
          'profile-update (action 4) response: '
          '${plain.statusCode} - ${plain.body}',
        );
        if (plain.statusCode >= 200 &&
            plain.statusCode < 300 &&
            _profileResponseSucceeded(plain.body)) {
          return true;
        }
        // Some AuthHub responses are 200 with status_code in JSON only.
        if (plain.statusCode >= 200 && plain.statusCode < 300) {
          try {
            final decoded = jsonDecode(plain.body);
            if (decoded is Map) {
              final code = decoded['status_code'] ?? decoded['statusCode'];
              if (code == 200 || code == '200') return true;
              final msg = decoded['message']?.toString().toLowerCase() ?? '';
              if (msg.contains('success') || msg.contains('updated')) {
                return true;
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        print('profile-update (action 4) error: $e');
      }
    }
    return false;
  }
}
