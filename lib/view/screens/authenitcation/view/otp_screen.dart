import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../constant/size_config.dart';
import '../../../../core/notifiers/auth/auth.notifier.dart';
import '../../../constants/colors.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController1 = TextEditingController();
  final TextEditingController otpController2 = TextEditingController();
  final TextEditingController otpController3 = TextEditingController();
  final TextEditingController otpController4 = TextEditingController();
  final TextEditingController otpController5 = TextEditingController();
  final TextEditingController otpController6 = TextEditingController();

  late int timerSeconds;
  late String timerText;

  late String otptext;

  @override
  void initState() {
    super.initState();
    timerSeconds = 30;
    startTimer();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (timerSeconds > 0) {
        setState(() {
          timerSeconds--;
          timerText = timerSeconds.toString().padLeft(2, '0');
        });
        startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Sizecf().init(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      // appBar: AppBar(
      //   // backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   systemOverlayStyle: SystemUiOverlayStyle.dark,
      // ),
      //backgroundColor: CommanColor.white,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: Provider.of<ThemeProvider>(context).currentCustomTheme ==
                AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover))
            : null,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: screenWidth > 450 ? 30 : 20,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                Text(
                  'Enter OTP',
                  style: TextStyle(
                      fontSize: screenWidth > 450
                          ? Sizecf.blockSizeVertical! * 2.5
                          : Sizecf.blockSizeVertical! * 2.2,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: Sizecf.scrnHeight! * 0.02,
                ),
                Text(
                  'Enter 6 digit OTP',
                  style: TextStyle(
                    fontSize: screenWidth > 450
                        ? Sizecf.blockSizeVertical! * 2
                        : Sizecf.blockSizeVertical! * 1.5,
                    fontWeight: FontWeight.w300,
                    color:
                        CommanColor.whiteBlack(context).withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(
                  height: Sizecf.scrnHeight! * 0.03,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     otpTextField(otpController1),
                //     otpTextField(otpController2),
                //     otpTextField(otpController3),
                //     otpTextField(otpController4),
                //     otpTextField(otpController5),
                //     otpTextField(otpController6),
                //   ],
                // ),
                OtpTextField(
                  autoFocus: true,
                  textStyle: screenWidth > 450
                      ? TextStyle(fontSize: Sizecf.blockSizeVertical! * 1.7, fontWeight: FontWeight.bold)
                      : TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  numberOfFields: 6, // Set the OTP length
                  borderColor: CommanColor.lightDarkPrimary300(context),
                  enabledBorderColor: CommanColor.lightDarkPrimary300(context),
                  focusedBorderColor: CommanColor.lightDarkPrimary300(context),
                  showFieldAsBox: true, // Display the fields as boxes
                  onCodeChanged: (String code) {
                    // Handle changes
                    otptext = code;
                  },

                  fieldWidth: screenWidth > 450 ? 55 : 45,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  onSubmit: (String verificationCode) {
                    // Handle OTP submission
                    debugPrint("Entered OTP: $verificationCode");
                    otptext = verificationCode;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("OTP Entered: $otptext")),
                    );
                  },
                ),
                SizedBox(
                  height: Sizecf.scrnHeight! * 0.03,
                ),
                CustomButton(
                  text: "Verify",
                  txtsize: screenWidth > 450 ? 22 : 16,
                  onPressed: () async {
                    final authnotifier =
                        Provider.of<AuthNotifier>(context, listen: false);
                    await authnotifier
                        .forgotverifyotp(
                      otp: otptext,
                      context: context,
                    )
                        .then((status) {
                      if (status) {
                        if (context.mounted) {
                          /// (context).pushNamed(AppRouteConst.restpassRoute);
                        }
                      }
                    });
                  },
                ),
                SizedBox(
                  height: Sizecf.scrnHeight! * 0.02,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final cacheprovider =
                            Provider.of<CacheNotifier>(context, listen: false);

                        final data =
                            await cacheprovider.readCache(key: 'useremail');
                        final authnotifier =
                            Provider.of<AuthNotifier>(context, listen: false);

                        if (timerSeconds == 0) {
                          if (context.mounted) {
                            await authnotifier.forgotsendotp(
                              email: data,
                              context: context,
                            );
                          }
                        }
                      },
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: Sizecf.blockSizeVertical! * 1.7,
                          color: CommanColor.whiteBlack(context)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      '00:${timerSeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: Sizecf.blockSizeVertical! * 1.7,
                        color: CommanColor.whiteBlack(context)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: Sizecf.scrnHeight! * 0.06,
                ),
                Text(
                  '(If OTP is not received means kindly check your spam folder and Tap Looks safe.)',
                  style: TextStyle(
                    fontSize: Sizecf.blockSizeVertical! * 1.9,
                    fontWeight: FontWeight.bold,
                    color:
                        CommanColor.whiteBlack(context).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget otpTextField(TextEditingController controller) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          fillColor: CommanColor.lightDarkPrimary200(context).withOpacity(0.4),
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color txtcolor;
  final double txtsize;
  final double elevation;
  double? height;
  final double width;

  CustomButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.color = CommanColor.darkPrimaryColor,
      this.txtcolor = CommanColor.white,
      this.txtsize = 16,
      this.elevation = 1,
      this.height,
      this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: elevation,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
              fontSize: txtsize, fontWeight: FontWeight.w600, color: txtcolor),
        ),
      ),
    );
  }
}
