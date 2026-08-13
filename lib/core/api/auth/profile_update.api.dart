import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'dart:io';

import 'package:biblebookapp/core/api/auth/temp_token.api.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../Model/auth/temp_token_model.dart';
import '../../../constant/app_api_constant.dart';
import '../../../utils/custom_http.dart';
import '../../notifiers/cache.notifier.dart';

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

      late final http.Response response;
      if (profileImage != null && await profileImage.exists()) {
        // Additive: same fields + multipart profile_image (gallery/avatar).
        final request = http.MultipartRequest('POST', uri);
        if (authtoken != null && authtoken.toString().isNotEmpty) {
          request.headers['Authorization'] = 'Bearer ${authtoken.toString()}';
        }
        payload.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        final fileName = profileImage.uri.pathSegments.isNotEmpty
            ? profileImage.uri.pathSegments.last
            : 'profile_image.jpg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImage.path,
            filename: fileName,
          ),
        );
        print('Sending multipart profile-update with profile_image...');
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
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
        response = plain;
      }

      final statuscode = response.statusCode;
      final body = response.body;

      print('profile-update response: $statuscode - $body');
      devtools.log("profile update api msg is $statuscode - $body");

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
      final userId = userid.toString();
      final appId = BibleInfo.appID.toString();
      final identity = await _cachedNameAndEmail(name: name, email: email);

      String? lastBody;

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

      // Do NOT send email / do NOT write key=referral_code (that is the user's
      // own code). Only set referred_by to the invite code entered.
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
      ];

      for (var i = 0; i < profileAttempts.length; i++) {
        final body = await _postProfileUpdate(
          uri: uri,
          authtoken: authtoken,
          logLabel: 'referred_by profile attempt ${i + 1}',
          payload: profileAttempts[i],
        );
        lastBody = body;
        if (_profileResponseSucceeded(body)) {
          return body;
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
}
