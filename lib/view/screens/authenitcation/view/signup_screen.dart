import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/signup_bloc.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/widget/social_auth_widget.dart';
import 'package:biblebookapp/view/screens/authenitcation/widgets/text_form_field.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

class SignupScreen extends HookConsumerWidget {
  SignupScreen({super.key});
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agree = useState(false);
    final agree1 = useState(false);
    final signupState = ref.watch(signupBloc);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
          children: [
            Positioned.fill(
              child: p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                      AppCustomTheme.vintage
                  ? Image.asset(
                      Images.bgImage(context), // Path to your image
                      fit: BoxFit.cover,
                    )
                  : SizedBox(),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: 2,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome!',
                                style: TextStyle(
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: screenWidth > 450
                                        ? BibleInfo.fontSizeScale * 50
                                        : BibleInfo.fontSizeScale * 28,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign up to back up and restore your Bible journey anytime, even when switching devices.',
                                style: TextStyle(
                                    letterSpacing: BibleInfo.letterSpacing,
                                    fontSize: screenWidth > 450
                                        ? BibleInfo.fontSizeScale * 23
                                        : BibleInfo.fontSizeScale * 14),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: signupState.nameCon,
                                hintText: 'Name',
                                validator: FormBuilderValidators.required(
                                    errorText: 'Please enter your name'),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: signupState.emailCon,
                                hintText: 'Email',
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText:
                                          'Please enter your email address'),
                                  FormBuilderValidators.email(
                                      errorText: 'Email is not valid'),
                                ]),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: signupState.passCon,
                                isPassword: true,
                                hintText: 'Password',
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText: 'Please enter password'),
                                  FormBuilderValidators.minLength(8,
                                      errorText:
                                          'Password should be at least 8 character length'),
                                ]),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: signupState.confirmPassCon,
                                isPassword: true,
                                hintText: 'Confirm Password',
                                validator: (p0) {
                                  if (p0 == null || p0.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (p0 != signupState.passCon.text) {
                                    return 'Password is not matching';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenWidth > 450 ? 19 : 15),
                              Row(
                                children: [
                                  Checkbox(
                                      value: agree.value,
                                      onChanged: (value) {
                                        agree.value = !agree.value;
                                      }),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            'By creating an account, you agree to our ',
                                        style: CommanStyle.appBarStyle(context)
                                            .copyWith(
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize: screenWidth > 450
                                                    ? BibleInfo.fontSizeScale *
                                                        23
                                                    : BibleInfo.fontSizeScale *
                                                        14,
                                                fontWeight: FontWeight.w400),
                                        children: [
                                          TextSpan(
                                            text: 'Terms and Condition, ',
                                            style: CommanStyle.appBarStyle(
                                                    context)
                                                .copyWith(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize: screenWidth >
                                                            450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            23
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                await SharPreferences.setString(
                                                    'OpenAd', '1');
                                                launchUrlString(
                                                    BibleInfo
                                                        .termsandConditionURL,
                                                    mode: LaunchMode
                                                        .inAppBrowserView);
                                              },
                                          ),
                                          const TextSpan(
                                            text: 'and ',
                                          ),
                                          TextSpan(
                                            text: 'Privacy and Policy ',
                                            style: CommanStyle.appBarStyle(
                                                    context)
                                                .copyWith(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize: screenWidth >
                                                            450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            23
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            14,
                                                    fontWeight:
                                                        FontWeight.w700),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                await SharPreferences.setString(
                                                    'OpenAd', '1');
                                                launchUrlString(
                                                    BibleInfo.privacyPolicyURL,
                                                    mode: LaunchMode
                                                        .inAppBrowserView);
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: screenWidth > 450 ? 17 : 12),
                              Row(
                                children: [
                                  Checkbox(
                                      value: agree1.value,
                                      onChanged: (value) {
                                        agree1.value = !agree1.value;
                                      }),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            'Subscribe to receive daily Bible verses, special gifts, and updates. Unsubscribe any time. ',
                                        style: CommanStyle.appBarStyle(context)
                                            .copyWith(
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize: screenWidth > 450
                                                    ? BibleInfo.fontSizeScale *
                                                        23
                                                    : BibleInfo.fontSizeScale *
                                                        14,
                                                fontWeight: FontWeight.w400),
                                        children: [],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 30),
                              GestureDetector(
                                onTap: () async {
                                  if (agree.value) {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      FocusScope.of(context).unfocus();
                                      try {
                                        if (!signupState.isLoading) {
                                          await signupState.createAccount();

                                          //Get.offAll(() => const SplashScreen());
                                        }
                                      } catch (e) {
                                        Constants.showToast(e.toString());
                                      }
                                    }
                                  } else {
                                    Constants.showToast(
                                        'You have to agree our Terms and Condition, and Privacy and Policy.');
                                  }
                                },
                                child: Container(
                                    width: 200,
                                    height: screenWidth > 450 ? 70 : 40,
                                    decoration: BoxDecoration(
                                      color: CommanColor.whiteLightModePrimary(
                                          context),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(5)),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 2)
                                      ],
                                    ),
                                    child: Center(
                                        child: signupState.isLoading
                                            ? SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: CommanColor
                                                      .darkModePrimaryWhite(
                                                          context),
                                                  strokeWidth: 2.2,
                                                ))
                                            : Text(
                                                'SIGN UP',
                                                style: TextStyle(
                                                    letterSpacing:
                                                        BibleInfo.letterSpacing,
                                                    fontSize: screenWidth > 450
                                                        ? BibleInfo
                                                                .fontSizeScale *
                                                            20
                                                        : BibleInfo
                                                                .fontSizeScale *
                                                            14,
                                                    fontWeight: FontWeight.w500,
                                                    color: CommanColor
                                                        .darkModePrimaryWhite(
                                                            context)),
                                              ))),
                              ),
                              const SizedBox(height: 30),
                              const SocialAuthWidget(),
                              RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                      text: 'Already have an account?',
                                      style: TextStyle(
                                          fontSize:
                                              screenWidth > 450 ? 25 : null,
                                          color:
                                              CommanColor.whiteBlack(context)),
                                      children: [
                                        TextSpan(
                                            text: ' Sign In',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: CommanColor.whiteBlack(
                                                    context)),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Get.to(() => LoginScreen(
                                                      hasSkip: false,
                                                    ));
                                              })
                                      ])),
                              SizedBox(height: screenWidth > 450 ? 25 : 10),
                              // Divider with "or"
                              // Padding(
                              //   padding:
                              //       const EdgeInsets.symmetric(horizontal: 40),
                              //   child: Row(
                              //     children: [
                              //       const Expanded(
                              //         child: Divider(
                              //           thickness: 1.5,
                              //           color: Colors.brown,
                              //         ),
                              //       ),
                              //       Padding(
                              //         padding:
                              //             EdgeInsets.symmetric(horizontal: 10),
                              //         child: Text(
                              //           "or",
                              //           style: TextStyle(
                              //             color: Colors.grey,
                              //             fontSize: screenWidth > 450 ? 25 : 16,
                              //           ),
                              //         ),
                              //       ),
                              //       const Expanded(
                              //         child: Divider(
                              //           thickness: 1.5,
                              //           color: Colors.brown,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              // SizedBox(height: screenWidth > 450 ? 25 : 15),

                              // // Guest Login Button
                              // Padding(
                              //   padding: EdgeInsets.symmetric(
                              //       horizontal: screenWidth > 600 ? 200 : 75),
                              //   child: GestureDetector(
                              //     onTap: () async {
                              //       SharedPreferences prefs =
                              //           await SharedPreferences.getInstance();
                              //       final saved = prefs.getStringList(
                              //               'selected_categories') ??
                              //           [];

                              //       if (saved.isEmpty) {
                              //         Get.to(
                              //             () => const PreferenceSelectionScreen(
                              //                   isSetting: false,
                              //                 ));
                              //       } else {
                              //         Get.offAll(() => HomeScreen(
                              //             From: "splash",
                              //             selectedVerseNumForRead: "",
                              //             selectedBookForRead: "",
                              //             selectedChapterForRead: "",
                              //             selectedBookNameForRead: "",
                              //             selectedVerseForRead: ""));
                              //       }
                              //     },
                              //     // child:
                              //     // Container(
                              //     //   width: screenWidth > 600 ? 90 : 60,
                              //     //   height: screenWidth > 600 ? 70 : 40,
                              //     //   decoration: BoxDecoration(
                              //     //       color: const Color.fromARGB(
                              //     //           255, 135, 108, 87),
                              //     //       borderRadius: BorderRadius.circular(
                              //     //           9) // Brown color
                              //     //       ),
                              //     // onPressed: () {
                              //     //   // Add guest login logic here
                              //     // },
                              //     // style: ElevatedButton.styleFrom(
                              //     //   fixedSize: Size(60, 50),
                              //     //   backgroundColor: const Color.fromARGB(
                              //     //       255, 135, 108, 87), // Brown color
                              //     //   elevation: 6,
                              //     //   shadowColor:
                              //     //       const Color.fromARGB(255, 210, 180, 169),
                              //     //   padding: const EdgeInsets.symmetric(
                              //     //       horizontal: 20, vertical: 15),
                              //     //   shape: RoundedRectangleBorder(
                              //     //     borderRadius: BorderRadius.circular(12),
                              //     //   ),
                              //     // ),
                              //     child: Center(
                              //       child: Text(
                              //         'Guest Login',
                              //         style: TextStyle(
                              //           fontSize: screenWidth > 450 ? 20 : 16,
                              //           letterSpacing: 1,
                              //           color: Colors.black,
                              //           decoration: TextDecoration.underline,
                              //           fontWeight: FontWeight.w600,
                              //         ),
                              //       ),
                              //       // ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        )));
  }
}
