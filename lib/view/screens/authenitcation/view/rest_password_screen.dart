import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/otp_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../constant/size_config.dart';
import '../../../../core/notifiers/auth/auth.notifier.dart';

class RestPasswordScreen extends StatefulWidget {
  const RestPasswordScreen({super.key});

  @override
  State<RestPasswordScreen> createState() => _RestPasswordScreenState();
}

class _RestPasswordScreenState extends State<RestPasswordScreen> {
  late TextEditingController passwordtext;
  late TextEditingController confrimpasswordtext;

  @override
  void initState() {
    super.initState();
    passwordtext = TextEditingController();
    confrimpasswordtext = TextEditingController();
  }

  @override
  void dispose() {
    passwordtext.dispose();
    confrimpasswordtext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Sizecf().init(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        Get.offAll(() => HomeScreen(
            From: "splash",
            selectedVerseNumForRead: "",
            selectedBookForRead: "",
            selectedChapterForRead: "",
            selectedBookNameForRead: "",
            selectedVerseForRead: ""));
      },
      child: Scaffold(
        // backgroundColor: CommanColor.white,
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.03,
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Get.offAll(() => HomeScreen(
                              From: "splash",
                              selectedVerseNumForRead: "",
                              selectedBookForRead: "",
                              selectedChapterForRead: "",
                              selectedBookNameForRead: "",
                              selectedVerseForRead: ""));
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
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.04,
                  ),
                  Text(
                    "Reset Password",
                    style: TextStyle(
                        fontSize: screenWidth < 380
                            ? 19
                            : screenWidth > 450
                                ? 22
                                : 20,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.02,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45),
                    child: Text(
                      'Please enter your New Password and Confirm Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth < 380
                            ? 14
                            : screenWidth > 450
                                ? 18
                                : 16,
                        fontWeight: FontWeight.w300,
                        color: CommanColor.black.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.03,
                  ),
                  CustomTextField1(
                    labelText: "Password",
                    hintText: "Password",
                    isPassword: true,
                    controller: passwordtext,
                  ),
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.02,
                  ),
                  CustomTextField1(
                    labelText: "Confirm Password",
                    hintText: "Confirm Password",
                    isPassword: true,
                    controller: confrimpasswordtext,
                  ),
                  SizedBox(
                    height: Sizecf.scrnHeight! * 0.045,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CustomButton(
                      text: "Continue",
                      txtsize: screenWidth > 450 ? 22 : 16,
                      onPressed: () async {
                        if (passwordtext.text.isNotEmpty &&
                            confrimpasswordtext.text.isNotEmpty) {
                          if (passwordtext.text == confrimpasswordtext.text) {
                            final authnotifier = Provider.of<AuthNotifier>(
                                context,
                                listen: false);
                            await authnotifier
                                .forgotrestpwd(
                                    passwordconfirmation: passwordtext.text,
                                    password: confrimpasswordtext.text,
                                    context: context)
                                .then((status) {
                              if (status) {
                                if (context.mounted) {}
                              }
                            });
                          } else {
                            SnackbarUtil.showSnackbar(
                              context: context,
                              message: 'Password does not matched !',
                              backgroundColor: Colors.redAccent,
                            );
                          }
                        } else {
                          SnackbarUtil.showSnackbar(
                            context: context,
                            message: 'Fill the value Correctly !',
                            backgroundColor: Colors.redAccent,
                          );
                        }
                        // Handle Login
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField1 extends StatefulWidget {
  final String labelText;
  final String hintText;
  final bool isPassword;
  final bool isSearch;
  final TextEditingController? controller;
  bool isobscure;
  CustomTextField1({
    super.key,
    required this.labelText,
    required this.hintText,
    this.isPassword = false,
    this.isSearch = false,
    this.controller,
    this.isobscure = true,
  });

  @override
  State<CustomTextField1> createState() => _CustomTextField1State();
}

class _CustomTextField1State extends State<CustomTextField1> {
  @override
  Widget build(BuildContext context) {
    Sizecf().init(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isSearch != true
            ? Text(
                widget.labelText,
                style: TextStyle(
                    fontSize: screenWidth < 380
                        ? 14
                        : screenWidth > 450
                            ? 18
                            : 16,
                    fontWeight: FontWeight.w500),
              )
            : Center(),
        const SizedBox(height: 8),
        TextField(
          style: screenWidth > 450 ? TextStyle(fontSize: 25) : TextStyle(),
          controller: widget.controller,
          obscureText: widget.isPassword ? widget.isobscure : false,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
                fontSize: screenWidth < 380
                    ? 14
                    : screenWidth > 450
                        ? 18
                        : 16,
                color: CommanColor.black.withValues(alpha: 0.4)),
            filled: true,
            fillColor: CommanColor.lightDarkPrimary200(context)
                .withOpacity(0.4), // Light grey background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
              borderSide: BorderSide.none, // No border
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16, vertical: screenWidth > 450 ? 20 : 14),
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.isobscure = !widget.isobscure;
                      });
                    },
                    child: const Icon(Icons.visibility_off, color: Colors.grey))
                : null,
          ),
        ),
      ],
    );
  }
}
