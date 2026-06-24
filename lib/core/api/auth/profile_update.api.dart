import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:biblebookapp/core/api/auth/temp_token.api.dart';
import 'package:biblebookapp/utils/referral_api_logger.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

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

    try {
      final payload = {
        'action': '1',
        'key': 'referral_reward_claimed',
        'value': value.toString(),
        'user_id': userid.toString(),
        'app_id': BibleInfo.appID,
      };
      devtools.log('profile update referral_reward_claimed request: $payload');

      final response = await CustomHttp().postwithtoken(
        path: uri,
        token: authtoken,
        data: payload,
      );

      final statuscode = response?.statusCode;
      final body = response?.body ?? '';
      devtools.log(
          'profile update referral_reward_claimed response: $statuscode - $body');

      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          logAuthApiReferralFields(
              'PROFILE UPDATE API (referral_reward_claimed)', parsed);
        } catch (_) {}
        return body;
      }
      return null;
    } catch (e) {
      devtools.log('profile update referral_reward_claimed error: $e');
      return null;
    }
  }
}
