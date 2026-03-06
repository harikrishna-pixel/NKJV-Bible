import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/forget_password_bloc.dart';
import 'package:biblebookapp/view/screens/authenitcation/widgets/text_form_field.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as P;

class ForgetPasswordScreen extends HookConsumerWidget {
  ForgetPasswordScreen({super.key});
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forgetPasswordState = ref.watch(forgetPasswordBloc);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration:
              P.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                      AppCustomTheme.vintage
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(Images.bgImage(context)),
                          fit: BoxFit.fill))
                  : null,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SafeArea(
                  child: SizedBox(
                    height: 12,
                  ),
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
                          'Forgot Password!',
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: screenWidth > 450
                                  ? BibleInfo.fontSizeScale * 50
                                  : BibleInfo.fontSizeScale * 28,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please enter the email address we will send code to your registered email ID.',
                          style: TextStyle(
                              letterSpacing: BibleInfo.letterSpacing,
                              fontSize: screenWidth > 450
                                  ? BibleInfo.fontSizeScale * 23
                                  : BibleInfo.fontSizeScale * 14),
                        ),
                        const SizedBox(height: 50),
                        CustomTextFormField(
                          controller: forgetPasswordState.emailCon,
                          hintText: 'Email',
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Please enter your email address'),
                            FormBuilderValidators.email(
                                errorText: 'Email is not valid'),
                          ]),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: () async {
                            print("=== UI: Reset Password button tapped ===");
                            if (_formKey.currentState?.validate() ?? false) {
                              print("UI: Form validation passed");
                              FocusScope.of(context).unfocus();
                              try {
                                if (!forgetPasswordState.isLoading) {
                                  print("UI: Starting forgetPassword...");
                                  await forgetPasswordState
                                      .forgetPassword(context);
                                  print(
                                      "UI: forgetPassword completed successfully");
                                }
                              } catch (e) {
                                print("UI: Exception caught: $e");
                                print("UI: Exception type: ${e.runtimeType}");
                                Constants.showToast("Error: ${e.toString()}");
                              }
                            } else {
                              print("UI: Form validation failed");
                            }
                          },
                          child: Container(
                              width: 200,
                              height: screenWidth > 450 ? 70 : 40,
                              decoration: BoxDecoration(
                                color:
                                    CommanColor.whiteLightModePrimary(context),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 2)
                                ],
                              ),
                              child: Center(
                                  child: forgetPasswordState.isLoading
                                      ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: CommanColor
                                                .darkModePrimaryWhite(context),
                                            strokeWidth: 2.2,
                                          ))
                                      : Text(
                                          'Reset Password',
                                          style: TextStyle(
                                              letterSpacing:
                                                  BibleInfo.letterSpacing,
                                              fontSize: screenWidth > 450
                                                  ? BibleInfo.fontSizeScale * 20
                                                  : BibleInfo.fontSizeScale *
                                                      14,
                                              fontWeight: FontWeight.w500,
                                              color: CommanColor
                                                  .darkModePrimaryWhite(
                                                      context)),
                                        ))),
                        ),
                      ],
                    ),
                  ),
                ))
              ],
            ),
          ),
        ));
  }
}
