import 'dart:developer' as devtools show log;

import 'package:biblebookapp/view/constants/assets_constants.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../constant/app_api_constant.dart';
import '../../../utils/custom_http.dart';

class Temptokenapi {
  Future gettokenaccess() async {
    final Uri uri =
        Uri.parse(AppApiConstant.baseurl + AppApiConstant.gettemptokenapi);
    try {
      var response = await CustomHttp().post(
        uri,
        data: {
          "client_id": dotenv.env[AssetsConstants.clientid] ?? '',
          "client_secret": dotenv.env[AssetsConstants.clientSecret] ?? '',
          "app_id": BibleInfo.appID
        },
      );

      final statuscode = response.statusCode;
      final body = response.body;

      if (statuscode == 200) {
        return body;
      } else {
        devtools.log("temptoken  is not found");
        return null;
      }
    } catch (e) {
      devtools.log("temptoken error is $e");
      return null;
    }
  }
}
