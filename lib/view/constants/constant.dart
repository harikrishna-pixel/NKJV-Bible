import 'package:biblebookapp/view/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      color: CommanColor.whiteBlack(context),
      animating: true,
      radius: 15,
    );
  }
}

class Constants {
  //show toast
  static showToast(String message, [sec = 1000]) {
    final duration = Duration(milliseconds: sec);
    final previousInteractions = EasyLoading.instance.userInteractions;
    // Toasts should not block scrolling/taps on the screen underneath.
    EasyLoading.instance.userInteractions = true;
    EasyLoading.showToast(
      message,
      toastPosition: EasyLoadingToastPosition.top,
      duration: duration,
      maskType: EasyLoadingMaskType.none,
      dismissOnTap: false,
    );
    Future.delayed(duration, () {
      EasyLoading.dismiss();
      EasyLoading.instance.userInteractions = previousInteractions;
    });
  }
}
