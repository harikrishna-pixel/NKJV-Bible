import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

import '../../../Model/auth/temp_token_model.dart';
import '../../../constant/app_api_constant.dart';
import '../../../utils/custom_http.dart';
import 'temp_token.api.dart';

class RegisterApi {
  Temptokenapi temptokenapi = Temptokenapi();

  Future register(
      {required name,
      required email,
      required password,
      required passwordconfirmation,
      appversion,
      deviceversion,
      devicemodel,
      devicelocale,
      devicetimezone}) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.registerapi);

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      var tokendata = await temptokenapi.gettokenaccess();
      final data = Temptoken.fromJson(jsonDecode(tokendata));
      if (data.statusCode == 200) {
        if (data.data!.tempAccessToken != null) {
          // print("access token is ${data.data!.tempAccessToken}");
          var response = await CustomHttp().postwithtoken(
            path: uri,
            token: data.data!.tempAccessToken.toString(),
            data: {
              "name": name,
              "email": email,
              "password": password,
              "password_confirmation": passwordconfirmation,
              "app_version": appversion ?? "1.0.0",
              "email_verify": BibleInfo.emailVerify,
              "device_type": "Android",
              //"device_type": Platform.isAndroid ? "Android" : "ios",
              "device_version": deviceversion ?? "15.2",
              "device_model": devicemodel ?? "iPhone 16",
              "device_locale": devicelocale ?? "en-US",
              "device_timezone": devicetimezone ?? "America/New_York",
              // "app_id": AppApiConstant.appid
              "app_id": BibleInfo.appID
            },
          );

          final statuscode = response!.statusCode;
          final body = response.body;

          print("register msg is ${response.statusCode} - ");

          if (statuscode == 200) {
            return body;
          } else {
            print("register is failed");
            return body;
          }
        } else {
          print("access token is null");
          return null;
        }
      } else {
        print("access token is not found");
        return null;
      }
    } catch (e) {
      print("register error is $e");
      return null;
    }
  }

  Future login(
      {required email,
      required password,
      appversion,
      deviceversion,
      devicemodel,
      devicelocale,
      devicetimezone}) async {
    final Uri uri = Uri.parse(AppApiConstant.baseurl + AppApiConstant.loginapi);

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      var tokendata = await temptokenapi.gettokenaccess();
      final data = Temptoken.fromJson(jsonDecode(tokendata));
      if (data.statusCode == 200) {
        if (data.data!.tempAccessToken != null) {
          // print("access token is ${data.data!.tempAccessToken}");
          var response = await CustomHttp().postwithtoken(
            path: uri,
            token: data.data!.tempAccessToken.toString(),
            data: {
              "email": email,
              "password": password,
              "app_version": appversion ?? "1.0.0",
              "device_type": "Android",
              //"device_type": Platform.isAndroid ? "Android" : "ios",
              "device_version": deviceversion ?? "15.2",
              "device_model": devicemodel ?? "iPhone 16",
              "device_locale": devicelocale ?? "en-US",
              "device_timezone": devicetimezone ?? "America/New_York",
              // "app_id": AppApiConstant.appid
              "app_id": BibleInfo.appID
            },
          );

          final statuscode = response!.statusCode;
          final body = response.body;

          print("login msg is $statuscode - $body");

          if (body.isNotEmpty) {
            return body;
          } else {
            print("login api  is not found");
            return null;
          }
        } else {
          print("access token is null");
          return null;
        }
      } else {
        print("access token is not found");
        return null;
      }
    } catch (e) {
      print("login api error is $e");
      return null;
    }
  }

  Future deleteyouraccount(context, email, token) async {
    final Uri uri = Uri.parse(AppApiConstant.deleteacctapi);

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      // var tokendata = await temptokenapi.gettokenaccess();
      // final data = Temptoken.fromJson(jsonDecode(tokendata));
      // if (data.statusCode == 200) {
      //   if (data.data!.tempAccessToken != null) {
      // print("access token is ${data.data!.tempAccessToken}");
      var response = await CustomHttp().postwithtoken(
        path: uri,
        token: token,
        data: {
          "user_id": email,
          // "app_id": AppApiConstant.appid
          "app_id": BibleInfo.appID
        },
      );

      final statuscode = response!.statusCode;
      final body = response.body;

      print("deleteyouraccount api msg is $statuscode - $body");

      if (body.isNotEmpty) {
        return body;
      } else {
        print("deleteyouraccount api  is not found");
        return null;
      }
      //   } else {
      //     print("access token is null");
      //     return null;
      //   }
      // } else {
      //   print("access token is not found");
      //   return null;
      // }
    } catch (e) {
      Constants.showToast('Check your Internet connection');
      print("deleteyouraccount api error is $e");
      return null;
    }
  }

  Future forgotsendotp({
    required email,
  }) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.forgotsendotp);
    final trimmedEmail = email.toString().trim();

    print("========== FORGOT PASSWORD DEBUG ==========");
    print("forgotsendotp - Request URL: $uri");
    print("forgotsendotp - Email: $trimmedEmail");
    print("forgotsendotp - AppID: ${BibleInfo.appID}");
    print(
        "forgotsendotp - Full URL: ${AppApiConstant.baseurl}${AppApiConstant.forgotsendotp}");

    try {
      print("forgotsendotp - Getting temp token...");
      var tokendata = await temptokenapi.gettokenaccess();
      if (tokendata == null) {
        print("forgotsendotp - temp token response is null");
        return null;
      }

      final tokenModel = Temptoken.fromJson(jsonDecode(tokendata));
      if (tokenModel.statusCode != 200 ||
          tokenModel.data?.tempAccessToken == null) {
        print("forgotsendotp - temp token unavailable");
        return null;
      }

      print("forgotsendotp - Starting HTTP request...");

      final response = await CustomHttp().postwithtoken(
        path: uri,
        token: tokenModel.data!.tempAccessToken.toString(),
        data: {
          "email": trimmedEmail,
          "app_id": BibleInfo.appID,
        },
      );

      if (response == null) {
        print("forgotsendotp - HTTP response is null");
        return null;
      }

      final statuscode = response.statusCode;
      final body = response.body;

      print("forgotsendotp response: statusCode=$statuscode");
      print("forgotsendotp response body: $body");

      // Check if response is successful
      if (statuscode >= 200 && statuscode < 300) {
        print("forgotsendotp - SUCCESS: Returning response body");
        return body;
      } else {
        devtools
            .log("forgotsendotp - ERROR: Failed with status code: $statuscode");
        print("forgotsendotp - ERROR: Response body: $body");
        // Return the error response body so it can be parsed
        return body;
      }
    } on Exception catch (e) {
      print("forgotsendotp - EXCEPTION: $e");
      print("forgotsendotp - Exception type: ${e.runtimeType}");

      // Check if it's a timeout exception
      if (e.toString().contains('timed out') ||
          e.toString().contains('TimeoutException')) {
        devtools
            .log("forgotsendotp - TIMEOUT: Request timed out after 30 seconds");
        print(
            "forgotsendotp - TIMEOUT: Server at ${AppApiConstant.baseurl} not responding");
      } else if (e.toString().contains('SocketException')) {
        print("forgotsendotp - SOCKET ERROR: Cannot connect to server");
        print(
            "forgotsendotp - Possible causes: DNS failure, server down, firewall blocking");
      } else if (e.toString().contains('HandshakeException') ||
          e.toString().contains('CERTIFICATE')) {
        devtools
            .log("forgotsendotp - SSL ERROR: Certificate validation failed");
      }

      return null;
    } catch (e) {
      print("forgotsendotp - UNEXPECTED ERROR: $e");
      print("forgotsendotp - Error type: ${e.runtimeType}");
      return null;
    } finally {
      print("========== END FORGOT PASSWORD DEBUG ==========");
    }
  }

  Future forgotverifyotp({
    required email,
    required otp,
  }) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.forgotverifyotp);

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      // print("access token is ${data.data!.tempAccessToken}");
      var response = await CustomHttp().postwithout(
        uri,
        data: {
          "email": email,
          // "app_id": AppApiConstant.appid,
          "app_id": BibleInfo.appID,
          "otp": otp,
        },
      );

      final statuscode = response.statusCode;
      final body = response.body;

      print("forgotverifyotp msg is $statuscode - ");

      return body;
    } catch (e) {
      print("forgotverifyotp api error is $e");
      return null;
    }
  }

  Future forgotrestpwd(
      {required email,
      required otp,
      required passwordconfirmation,
      required token,
      required password}) async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.forgotrestpwd);

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      var tokendata = await temptokenapi.gettokenaccess();
      final data = Temptoken.fromJson(jsonDecode(tokendata));
      if (data.statusCode == 200) {
        if (data.data!.tempAccessToken != null) {
          // print("access token is ${data.data!.tempAccessToken}");
          var response = await CustomHttp().postwithout(
            uri,
            data: {
              "email": email,
              "app_id": BibleInfo.appID,
              //"app_id": AppApiConstant.appid,
              "token": token,
              "password": password,
              "password_confirmation": passwordconfirmation
            },
          );

          final statuscode = response.statusCode;
          final body = response.body;

          print("forgotrestpwd msg is $statuscode - ");

          return body;
        } else {
          print("access token is null");
          return null;
        }
      } else {
        print("access token is not found");
        return null;
      }
    } catch (e) {
      print("forgotrestpwd api error is $e");
      return null;
    }
  }
}
