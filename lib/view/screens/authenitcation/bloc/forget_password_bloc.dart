import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/notifiers/auth/auth.notifier.dart';

final forgetPasswordBloc =
    ChangeNotifierProvider((ref) => ForgetPasswordBloc());

class ForgetPasswordBloc extends ChangeNotifier {
  TextEditingController emailCon = TextEditingController();
  AuthNotifier authNotifier = AuthNotifier();
  bool isLoading = false;

  Future<bool> userExists() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailCon.text,
        password: 'TemporaryPassword123!', // Use a temporary password
      );

      // If the account creation is successful, delete the account and return false
      await userCredential.user!.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If account creation fails because the email is already in use,
        // return true
        return true;
      } else {
        // If account creation fails for any other reason, return false
        return false;
      }
    }
  }

  Future<void> forgetPassword(context) async {
    print("=== BLOC: forgetPassword called ===");
    print("BLOC: Email = ${emailCon.text}");

    isLoading = true;
    notifyListeners();
    // if (await userExists()) {
    try {
      print("BLOC: Calling authNotifier.forgotsendotp...");
      await authNotifier.forgotsendotp(email: emailCon.text, context: context);
      print("BLOC: forgotsendotp completed");
      isLoading = false;
      // await FirebaseAuth.instance
      //     .sendPasswordResetEmail(email: emailCon.text);
    } catch (e) {
      print("BLOC: Exception caught: $e");
      print("BLOC: Exception type: ${e.runtimeType}");
      isLoading = false;
      notifyListeners();
      // Rethrow so the UI can handle it
      rethrow;
      // throw e.code.replaceAll('-', ' ').toTitleCase;
    }
    // } else {
    //   isLoading = false;
    //   notifyListeners();
    //   throw 'User does not exists';
    // }
    isLoading = false;
    notifyListeners();
    print("=== BLOC: forgetPassword finished ===");
  }
}
