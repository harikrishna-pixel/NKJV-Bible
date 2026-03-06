import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/login_bloc.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/forget_password_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/mail_verification_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/signup_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/social_auth_widget.dart';
import 'package:biblebookapp/view/screens/authenitcation/widgets/text_form_field.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/preference_selection_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as P;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends HookConsumerWidget {
  LoginScreen({super.key, required this.hasSkip});
  final bool hasSkip;
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginBloc);
    double screenWidth = MediaQuery.of(context).size.width;

    // Check and clear fields if account was deleted
    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(loginBloc).checkAndClearIfNeeded();
      });
    });
    // debugPrint("sz current width - $screenWidth ");
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration:
              P.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                      AppCustomTheme.vintage
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(Images.bgImage(context)),
                          fit: BoxFit.cover))
                  : null,
          child: Column(
            children: [
              const SafeArea(
                child: SizedBox(
                  height: 12,
                ),
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
                  // if (hasSkip)
                  //   GestureDetector(
                  //     onTap: () async {
                  //       NotificationsServices().initialiseNotifications();

                  //       Get.offAll(() => HomeScreen(
                  //           From: "splash",
                  //           selectedVerseNumForRead: "",
                  //           selectedBookForRead: "",
                  //           selectedChapterForRead: "",
                  //           selectedBookNameForRead: "",
                  //           selectedVerseForRead: ""));
                  //     },
                  //     child: Text("Continue without Login",
                  //         style: screenWidth > 450
                  //             ? CommanStyle.bw22500(context).copyWith(
                  //                 decoration: TextDecoration.underline)
                  //             : CommanStyle.bw14400(context).copyWith(
                  //                 decoration: TextDecoration.underline)),
                  //   ),
                  const SizedBox(width: 20)
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                  child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Good to see you!',
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 50
                                : BibleInfo.fontSizeScale * 28,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your journey with God just got easier.',
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 23
                                : BibleInfo.fontSizeScale * 14),
                      ),
                      const SizedBox(height: 50),
                      CustomTextFormField(
                        controller: loginState.emailCon,
                        hintText: 'Email',
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: 'Please enter your email address'),
                          FormBuilderValidators.email(
                              errorText: 'Email is not valid'),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        controller: loginState.passCon,
                        isPassword: true,
                        hintText: 'Password',
                        validator: FormBuilderValidators.minLength(6,
                            errorText:
                                'Password should be at least 6 character length'),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            FocusScope.of(context).unfocus();
                            try {
                              if (!loginState.isLoading) {
                                final user = await loginState.login(context);
                                //  Constants.showToast(
                                //     "Hi $user, Welcome to Amplified Bible");

                                // Always route to HomeScreen after successful login
                                if (user != null) {
                                  Constants.showToast(
                                      "Hi ${user.displayName}, Welcome to ${BibleInfo.bible_shortName}");
                                  return Get.offAll(() => HomeScreen(
                                      From: "splash",
                                      selectedVerseNumForRead: "",
                                      selectedBookForRead: "",
                                      selectedChapterForRead: "",
                                      selectedBookNameForRead: "",
                                      selectedVerseForRead: ""));
                                }
                              }
                            } catch (e) {
                              if (e.toString() == 'verification') {
                                Get.offAll(
                                    () => const MailVerificationScreen());
                              } else {
                                Constants.showToast(e.toString());
                              }
                            }
                          }
                        },
                        child: Container(
                            width: 200,
                            height: screenWidth > 450 ? 70 : 40,
                            decoration: BoxDecoration(
                              color: CommanColor.whiteLightModePrimary(context),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2)
                              ],
                            ),
                            child: Center(
                                child: loginState.isLoading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color:
                                              CommanColor.darkModePrimaryWhite(
                                                  context),
                                          strokeWidth: 2.2,
                                        ))
                                    : Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                            letterSpacing:
                                                BibleInfo.letterSpacing,
                                            fontSize: screenWidth > 450
                                                ? BibleInfo.fontSizeScale * 20
                                                : BibleInfo.fontSizeScale * 14,
                                            fontWeight: FontWeight.w500,
                                            color: CommanColor
                                                .darkModePrimaryWhite(context)),
                                      ))),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                          onTap: () {
                            Get.to(() => ForgetPasswordScreen());
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Forgot Password?',
                                style: TextStyle(
                                    fontSize: screenWidth > 450 ? 22 : null,
                                    color: CommanColor.weekendColor(context)),
                              ),
                            ],
                          )),
                      const SizedBox(height: 20),
                      const SocialAuthWidget(),
                      RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              text: 'Don\'t have an account?',
                              style: TextStyle(
                                  fontSize: screenWidth > 450 ? 25 : null,
                                  color: CommanColor.whiteBlack(context)),
                              children: [
                                TextSpan(
                                    text: ' Sign Up',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: CommanColor.whiteBlack(context)),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.to(() => SignupScreen());
                                      })
                              ])),
                    ],
                  ),
                ),
              )),
              Padding(
                // Keep the same bottom spacing but align contents to the start
                // so the Note appears at the left on wide screens (iPad).
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 120.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(() => SignupScreen());
                      },
                      child: Text(
                        'Note:',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth > 450 ? 25 : null,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No login is needed to remove ads or restore purchases',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: CommanColor.whiteBlack(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
