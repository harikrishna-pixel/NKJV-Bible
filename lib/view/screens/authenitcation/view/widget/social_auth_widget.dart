import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/apple_auth_bloc.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/facebook_auth_bloc.dart';
import 'package:biblebookapp/view/screens/authenitcation/bloc/google_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SocialAuthWidget extends HookConsumerWidget {
  const SocialAuthWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleAuthState = ref.watch(googleAuthBloc);
    final facebookAuthState = ref.watch(facebookAuthBloc);
    final appleAuthState = ref.watch(appleAuthBloc);
    return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: CommanColor.whiteLightModePrimary(context),
              ),
            ),
            const Text('OR'),
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: CommanColor.whiteLightModePrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          'Social Media Login',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                try {
                  if (!googleAuthState.isLoading) {
                    final user = await googleAuthState.googleLogin();
                    Constants.showToast(
                        "Hi ${user?.displayName}, Welcome to Amplified Bible");
                  }
                } catch (e) {
                  Constants.showToast(e.toString());
                }
              },
              child: Center(
                  child: googleAuthState.isLoading
                      ? Container(
                          height: 22,
                          width: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CommanColor.whiteLightModePrimary(context),
                          ),
                          child: CircularProgressIndicator(
                            color: CommanColor.darkModePrimaryWhite(context),
                            strokeWidth: 2.2,
                          ))
                      : Image.asset(
                          'assets/google.png',
                          height: 28,
                          width: 28,
                        )),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () async {
                try {
                  if (!facebookAuthState.isLoading) {
                    final user = await facebookAuthState.facebookLogin();
                    Constants.showToast(
                        "Hi ${user?.displayName}, Welcome to Amplified Bible");
                  }
                } catch (e) {
                  Constants.showToast(e.toString());
                }
              },
              child: Center(
                  child: facebookAuthState.isLoading
                      ? Container(
                          height: 22,
                          width: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CommanColor.whiteLightModePrimary(context),
                          ),
                          child: CircularProgressIndicator(
                            color: CommanColor.darkModePrimaryWhite(context),
                            strokeWidth: 2.2,
                          ))
                      : Image.asset(
                          'assets/facebook.png',
                          height: 28,
                          width: 28,
                        )),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  try {
                    if (!appleAuthState.isLoading) {
                      final user = await appleAuthState.appleLogin();
                      Constants.showToast(
                          "Hi ${user?.displayName}, Welcome to Amplified Bible");
                    }
                  } catch (e) {
                    Constants.showToast(e.toString());
                  }
                },
                child: Center(
                    child: appleAuthState.isLoading
                        ? Container(
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CommanColor.whiteLightModePrimary(context),
                            ),
                            child: CircularProgressIndicator(
                              color: CommanColor.darkModePrimaryWhite(context),
                              strokeWidth: 2.2,
                            ))
                        : Image.asset(
                            'assets/apple.png',
                            height: 28,
                            width: 28,
                          )),
              ),
            ]
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
