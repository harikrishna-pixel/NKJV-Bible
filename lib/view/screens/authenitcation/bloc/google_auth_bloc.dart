import 'dart:developer';

import 'package:biblebookapp/core/string_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final googleAuthBloc = ChangeNotifierProvider((ref) => GoogleAuthBloc());

class GoogleAuthBloc extends ChangeNotifier {
  bool isLoading = false;

  Future<User?> googleLogin() async {
    isLoading = true;
    notifyListeners();
    try {
      GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
      final googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      final user = await FirebaseAuth.instance.signInWithCredential(credential);
      log('User Name: ${user.user?.displayName}');
      isLoading = false;
      notifyListeners();
      return user.user;
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
