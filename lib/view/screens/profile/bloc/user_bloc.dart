import 'dart:developer';
import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userBloc = ChangeNotifierProvider((ref) => UserBloc());

class UserBloc extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  // final firestoredb = FirebaseFirestore.instance;
  Future<void> createUser(String name, String email, String password) async {
    try {
      final newUser =
          registerUser(email: email, name: name, password: password);
      // user = await newUser;
      notifyListeners();
    } catch (e, st) {
      log('Error Creating User: $e,$st');
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {}
}
