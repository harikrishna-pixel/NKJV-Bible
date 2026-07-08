import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:biblebookapp/core/api/auth/temp_token.api.dart';
import 'package:biblebookapp/utils/referral_api_logger.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';

import '../../../Model/auth/temp_token_model.dart';
import '../../../constant/app_api_constant.dart';
import '../../../utils/custom_http.dart';
import '../../notifiers/cache.notifier.dart';

class ProfileUpdateApi {
  Temptokenapi temptokenapi = Temptokenapi();

  final CacheNotifier cacheNotifier = CacheNotifier();

  Future updateprofile(
      {required email,
      required name,
      appversion,
      deviceversion,
      devicemodel,
      devicelocale,
      devicetimezone}) async {
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
      var response = await CustomHttp().postwithtoken(
        path: uri,
        //token: data.data!.tempAccessToken.toString(),
        token: authtoken,
        data: {
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
        },
      );

      final statuscode = response!.statusCode;
      final body = response.body;

      devtools.log("profile update api msg is $statuscode - $body");

      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          logAuthApiReferralFields('PROFILE UPDATE API', parsed);
        } catch (_) {}
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

  Future<String?> updateReferralRewardClaimed({required int value}) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.updateprofleapi);
    final userid = await cacheNotifier.readCache(key: 'userid');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    final email = await cacheNotifier.readCache(key: 'user');
    final name = await cacheNotifier.readCache(key: 'name');

    try {
      final emailStr =
          email != null ? email.toString().trim() : '';
      final nameStr = name != null ? name.toString().trim() : '';
      final userId = userid.toString();

      if (emailStr.isNotEmpty && nameStr.isNotEmpty) {
        await _postProfileUpdate(
          uri: uri,
          authtoken: authtoken,
          logLabel: 'referral_reward_claimed prime',
          payload: {
            'action': '1',
            'email': emailStr,
            'name': nameStr,
            'user_id': userId,
            'app_id': BibleInfo.appID,
          },
        );
      }

      final body = await _postProfileUpdate(
        uri: uri,
        authtoken: authtoken,
        logLabel: 'referral_reward_claimed',
        payload: {
          'action': '1',
          'key': 'referral_reward_claimed',
          'value': value.toString(),
          'user_id': userId,
          'app_id': BibleInfo.appID,
          if (nameStr.isNotEmpty) 'name': nameStr,
        },
      );
      if (body != null && body.isNotEmpty) {
        return body;
      }
      return null;
    } catch (e) {
      devtools.log('profile update referral_reward_claimed error: $e');
      return null;
    }
  }

  bool _profileResponseSucceeded(String? body) {
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
        try {
          final parsed = jsonDecode(body);
          logAuthApiReferralFields('PROFILE UPDATE API ($logLabel)', parsed);
        } catch (_) {}
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
      try {
        final parsed = jsonDecode(body);
        logAuthApiReferralFields('PROFILE UPDATE API ($logLabel)', parsed);
      } catch (_) {}
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
      final cachedName = await cacheNotifier.readCache(key: 'name');
      final cachedEmail = await cacheNotifier.readCache(key: 'user');
      final resolvedName = (name?.trim().isNotEmpty == true
              ? name!.trim()
              : cachedName?.toString().trim()) ??
          '';
      final resolvedEmail = (email?.trim().isNotEmpty == true
              ? email!.trim()
              : cachedEmail?.toString().trim()) ??
          '';
      final resolvedPassword = password?.trim() ?? '';
      final code = referralCode.trim();
      final userId = userid.toString();
      final appId = BibleInfo.appID.toString();

      String? lastBody;

      // Backend profile-update requires name+email for action 1 (see 422 logs).
      // Action 2 requires password + old_password when provided.
      final profileAttempts = <Map<String, String>>[
        if (resolvedName.isNotEmpty && resolvedEmail.isNotEmpty)
          {
            'action': '1',
            'key': 'referred_by',
            'value': code,
            'user_id': userId,
            'app_id': appId,
            'name': resolvedName,
            'email': resolvedEmail,
          },
        if (resolvedEmail.isNotEmpty)
          {
            'action': '1',
            'key': 'referred_by',
            'value': code,
            'user_id': userId,
            'app_id': appId,
            'email': resolvedEmail,
            if (resolvedName.isNotEmpty) 'name': resolvedName,
          },
        if (resolvedPassword.isNotEmpty &&
            resolvedName.isNotEmpty &&
            resolvedEmail.isNotEmpty)
          {
            'action': '2',
            'key': 'referred_by',
            'value': code,
            'user_id': userId,
            'app_id': appId,
            'name': resolvedName,
            'email': resolvedEmail,
            'password': resolvedPassword,
            'old_password': resolvedPassword,
          },
        // Also try sending the invite code as referral_code (same action 1 shape).
        if (resolvedName.isNotEmpty && resolvedEmail.isNotEmpty)
          {
            'action': '1',
            'key': 'referral_code',
            'value': code,
            'user_id': userId,
            'app_id': appId,
            'name': resolvedName,
            'email': resolvedEmail,
            'referred_by': code,
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

      Uri applyQueryUri(String baseUrl, String referralCode, String uid) {
        return Uri.parse('${baseUrl}api/apply-referral-code').replace(
          queryParameters: {
            'referral_code': referralCode,
            'user_id': uid,
            'app_id': appId,
          },
        );
      }

      Uri applyPathUri(String baseUrl, String referralCode, String uid) {
        return Uri.parse('${baseUrl}api/apply-referral-code/$referralCode')
            .replace(queryParameters: {
          'user_id': uid,
          'app_id': appId,
        });
      }

      final tempToken = await _resolveTempAccessToken();
      final applyGetAttempts = <({String suffix, String? token, Uri Function(String, String, String) buildUri})>[
        (suffix: ' query auth', token: authtoken, buildUri: applyQueryUri),
        (suffix: ' path auth', token: authtoken, buildUri: applyPathUri),
        if (tempToken != null && tempToken.isNotEmpty)
          (suffix: ' query temp', token: tempToken, buildUri: applyQueryUri),
      ];

      for (final attempt in applyGetAttempts) {
        final body = await _tryApplyReferralCodeGet(
          code: code,
          userId: userId,
          authtoken: attempt.token,
          logSuffix: attempt.suffix,
          buildUri: attempt.buildUri,
        );
        lastBody = body;
        if (_profileResponseSucceeded(body)) {
          return body;
        }
      }

      return lastBody;
    } catch (e) {
      devtools.log('profile update referred_by error: $e');
      return null;
    }
  }
}
