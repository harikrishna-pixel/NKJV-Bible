import 'dart:developer';
import 'dart:io';

import 'package:biblebookapp/view/screens/profile/bloc/user_bloc.dart';
import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final editProfileBloc =
    ChangeNotifierProvider((ref) => EditProfileBloc(ref: ref));

class EditProfileBloc extends ChangeNotifier {
  final Ref ref;
  EditProfileBloc({required this.ref});

  XFile? pickedImage;
  TextEditingController nameCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  TextEditingController addressCon = TextEditingController();
  bool isLoading = false;

  updateCountry(Country country) {
    log('Country: $country');
    addressCon.text = '${country.flagEmoji} ${country.name}';
  }

  initateUserValue(UserModel? user) {
    nameCon.text = user?.displayName ?? '';
    phoneCon.text = user?.phoneNumber ?? '';
    pickedImage = null;
    addressCon.text = user?.address ?? '';

    notifyListeners();
  }

  Future<String?> uploadImage(User? user) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult[0] == ConnectivityResult.mobile ||
          connectivityResult[0] == ConnectivityResult.wifi) {
        if (user != null && pickedImage != null) {
          log('Uploading Image');
          final reference = FirebaseStorage.instance
              .ref('user_profile/${user.uid}-${DateTime.now()}.jpg');
          await reference.putFile(File(pickedImage!.path),
              SettableMetadata(contentType: 'image/jpeg'));
          final imageUrl = await reference.getDownloadURL();
          await user.updatePhotoURL(imageUrl);
          log('Image Upload Successfull');
          return imageUrl;
        } else {
          return null;
        }
      } else {
        throw 'No Internet Connection';
      }
    } catch (e, st) {
      log("Error Uploading Image: $e,$st");
      rethrow;
    }
  }

  Future<void> updateProfile() async {
    isLoading = true;
    notifyListeners();
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      final imageUrl = await uploadImage(currentUser);
      await currentUser?.updateDisplayName(nameCon.text);
      ref.read(userBloc).updateUser(UserModel(
          uid: currentUser!.uid,
          displayName: nameCon.text,
          photoURL: imageUrl ?? currentUser.photoURL,
          address: addressCon.text,
          phoneNumber: phoneCon.text));
    } catch (e, st) {
      isLoading = false;
      notifyListeners();
      log("Error: $e,$st");
      rethrow;
    }
    isLoading = false;
    notifyListeners();
  }

  updateImage(XFile? image) {
    pickedImage = image;
    notifyListeners();
  }
}
