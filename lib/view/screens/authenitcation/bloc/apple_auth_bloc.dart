import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:biblebookapp/core/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final appleAuthBloc = ChangeNotifierProvider((ref) => AppleAuthBloc());

class AppleAuthBloc extends ChangeNotifier {
  bool isLoading = false;

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> appleLogin() async {
    isLoading = true;
    notifyListeners();
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ], nonce: Platform.isIOS ? nonce : null);

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        rawNonce: Platform.isIOS ? rawNonce : null,
        accessToken: Platform.isIOS ? null : credential.authorizationCode,
      );
      log("Apple Family Name : ${credential.familyName}");
      log("Apple Given Name : ${credential.givenName}");
      final user =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      isLoading = false;
      notifyListeners();
      return user.user;
    } on FirebaseAuthException catch (e, st) {
      log('Firebase Exception: $e, $st');
      isLoading = false;
      notifyListeners();
      throw e.code.replaceAll('-', ' ').toTitleCase;
    } catch (e, st) {
      log('Catch Error: $e, $st');
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
