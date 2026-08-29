import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/core/notifiers/auth/auth.notifier.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final loginBloc = ChangeNotifierProvider((ref) => LoginBloc(ref: ref));

class LoginBloc extends ChangeNotifier {
  final Ref ref;
  LoginBloc({required this.ref});

  TextEditingController emailCon = TextEditingController();
  TextEditingController passCon = TextEditingController();

  bool isLoading = false;

  AuthNotifier authNotifier = AuthNotifier();

  // Clear email and password controllers
  void clearFields() {
    emailCon.clear();
    passCon.clear();
    notifyListeners();
  }

  // Check if user cache is empty and clear fields if needed
  Future<void> checkAndClearIfNeeded() async {
    final cacheNotifier = CacheNotifier();
    final user = await cacheNotifier.readCache(key: 'user');
    final userid = await cacheNotifier.readCache(key: 'userid');
    final name = await cacheNotifier.readCache(key: 'name');
    final authtoken = await cacheNotifier.readCache(key: 'authtoken');
    
    // If all cache keys are empty (account deleted), clear the fields
    if (user == null && userid == null && name == null && authtoken == null) {
      clearFields();
    }
  }

  Future login(context) async {
    isLoading = true;
    notifyListeners();
    try {
      // return await authNotifier.login(
      //     email: emailCon.text, password: passCon.text, context: context);
      return await loginUser(email: emailCon.text, password: passCon.text);
    } catch (_) {
      rethrow;
    } finally {
      // Keep isLoading true for the whole login request so Login cannot
      // fire twice and stack the referral bottom sheet.
      isLoading = false;
      notifyListeners();
    }
  }
}
