import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../controller/api_service.dart';

final signupBloc = ChangeNotifierProvider((ref) => SignupBloc(ref: ref));

class SignupBloc extends ChangeNotifier {
  final Ref ref;
  SignupBloc({required this.ref});
  TextEditingController emailCon = TextEditingController();
  TextEditingController nameCon = TextEditingController();
  TextEditingController passCon = TextEditingController();
  TextEditingController confirmPassCon = TextEditingController();
  bool isLoading = false;
  UserModel? user;
  Future<String?> createAccount() async {
    isLoading = true;
    notifyListeners();
    try {
      final referralCode = await registerUser(
          email: emailCon.text, name: nameCon.text, password: passCon.text);
      isLoading = false;
      notifyListeners();
      return referralCode;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
