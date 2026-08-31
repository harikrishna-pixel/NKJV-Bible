import 'dart:developer' as devtools show log;

import 'package:biblebookapp/constant/app_api_constant.dart';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/utils/custom_http.dart';

class BookofferApi {
  Future getofferbook() async {
    final Uri uri = Uri.parse(AppApiConstant.bookofferapi);
    final value = await getMusicDetails();

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      // devtools.log("access token is ${data.data!.tempAccessToken}");
      var response = await CustomHttp().postwithout(
        uri,
        data: {
          "book_cat_id": value?.data?.bookAdsCatId.toString(),
        },
      );

      //  final statuscode = response.statusCode;
      final body = response.body;

      // devtools.log("getofferbook msg is $statuscode - ");

      return body;
    } catch (e) {
      devtools.log("getofferbook api error is $e");
      return null;
    }
  }

  Future getbooks() async {
    final Uri uri = Uri.parse(AppApiConstant.bookofferapi);
    //  final value = await getMusicDetails();

    // PhoneInfo phoneInfos = await Phoneinformations.getPhoneInformation();
    try {
      // devtools.log("access token is ${data.data!.tempAccessToken}");
      var response = await CustomHttp().postwithout(
        uri,
        data: {
          "book_cat_id": "18",
        },
      );

      //final statuscode = response.statusCode;
      final body = response.body;

      //   devtools.log("getbook msg is $statuscode - ");

      // devtools.log("getbook data is $body  ");

      return body;
    } catch (e) {
      devtools.log("getbook api error is $e");
      return null;
    }
  }
}
