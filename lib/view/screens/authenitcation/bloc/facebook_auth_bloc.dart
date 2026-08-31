import 'dart:developer';

import 'package:biblebookapp/core/string_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final facebookAuthBloc = ChangeNotifierProvider((ref) => FacebookAuthBloc());

class FacebookAuthBloc extends ChangeNotifier {
  bool isLoading = false;

  Future<User?> facebookLogin() async {
    isLoading = true;
    notifyListeners();
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.accessToken != null) {
        final credential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final user =
            await FirebaseAuth.instance.signInWithCredential(credential);
        log('User Name: ${user.user?.displayName}');
        isLoading = false;
        notifyListeners();
        return user.user;
      } else {
        isLoading = false;
        notifyListeners();
        throw 'Unable to fetch the access token';
      }
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      throw e.code.replaceAll('-', ' ').toTitleCase;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
