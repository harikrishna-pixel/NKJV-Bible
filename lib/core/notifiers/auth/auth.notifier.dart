import 'dart:convert';
import 'dart:io';
import 'package:biblebookapp/Model/bookoffer_model.dart';
import 'package:biblebookapp/core/api/bookoffer_api.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/login_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/otp_screen.dart';
import 'package:biblebookapp/view/screens/authenitcation/view/rest_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../../Model/auth/register_model.dart';
import '../../../constant/size_config.dart';
import '../../../view/constants/colors.dart';
import '../../../view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/core/library_backup_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../api/auth/profile_update.api.dart';
import '../../api/auth/register.api.dart';

import 'dart:developer' as devtools show log;

import '../cache.notifier.dart';

/// Pull profile image URL from profile-update / auth JSON shapes.
String? _profileImageUrlFromResponse(dynamic decoded) {
  if (decoded is! Map) return null;
  final map = Map<String, dynamic>.from(decoded);

  String? fromMap(Map<String, dynamic> m) {
    for (final key in [
      'profile_image',
      'profileImage',
      'profile_image_url',
      'image_url',
      'photoURL',
      'photo_url',
      'avatar',
      'avatar_url',
    ]) {
      final v = m[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  final top = fromMap(map);
  if (top != null) return top;

  final data = map['data'];
  if (data is Map) {
    final dataMap = Map<String, dynamic>.from(data);
    final fromData = fromMap(dataMap);
    if (fromData != null) return fromData;
    final user = dataMap['user'];
    if (user is Map) {
      final fromUser = fromMap(Map<String, dynamic>.from(user));
      if (fromUser != null) return fromUser;
    }
  }

  final user = map['user'];
  if (user is Map) {
    return fromMap(Map<String, dynamic>.from(user));
  }
  return null;
}

class AuthNotifier extends ChangeNotifier {
  final RegisterApi registerApi = RegisterApi();
  final ProfileUpdateApi profileUpdateApi = ProfileUpdateApi();
  final BookofferApi bookofferApi = BookofferApi();
  final CacheNotifier cacheNotifier = CacheNotifier();
  Future register(
      {required name,
      required email,
      required password,
      required passwordconfirmation,
      context}) async {
    try {
      var appdata = await registerApi.register(
          name: name,
          email: email,
          password: password,
          passwordconfirmation: passwordconfirmation);

      final data = Register.fromJson(jsonDecode(appdata));

      final datafn = jsonDecode(appdata);

      final msg = datafn['message'];

      //  debugPrint("APP data: ${datafn['data']['app_name']}");
      if (data.data != null) {
        if (data.statusCode == 200 && data.status == true) {
          await cacheNotifier.writeCache(
              key: "user", value: data.data!.user!.email.toString());

          await cacheNotifier.writeCache(
              key: "userid", value: data.data!.user!.userId.toString());

          await cacheNotifier.writeCache(
              key: "name", value: data.data!.user!.name.toString());

          await cacheNotifier.writeCache(
              key: "authtoken", value: data.data!.token.toString());

          LibraryBackupUploadService.runAfterLogin();

          await cacheNotifier.writeCache(key: "skip", value: "false");
          return showDialog(
              context: context,
              builder: (BuildContext context) {
                return Center(
                  child: StatusDialog(
                    title: data.status == true
                        ? 'Successfully Registered'
                        : 'Registered Failed',
                    buttonText: data.status == true ? 'Continue' : 'Retry',
                    onButtonPressed: () {
                      // Add navigation or retry logic here
                      // (context).goNamed(AppRouteConst.navhomeRoute,
                      //     pathParameters: {'index': '0'});
                    },
                    isSuccess: data.status == true ? true : false,
                  ),
                );
              });
        }
      } else {
        print("register data is null");

        final datafn = jsonDecode(appdata);

        return showDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: StatusDialog(
                  title: datafn['status'] == true
                      ? 'Successfully Registered'
                      : 'Registered Failed ${datafn['errors']['password'] ?? msg}',
                  buttonText: datafn['status'] == true ? 'Continue' : 'Retry',
                  onButtonPressed: () {
                    // Add navigation or retry logic here
                    Navigator.of(context).pop();
                  },
                  isSuccess: datafn['status'] == true ? true : false,
                ),
              );
            });
      }
    } catch (e) {
      print("register notifier error is $e");
      return null;
    }
  }

  Future<List?> getofferbook() async {
    try {
      var appdata = await bookofferApi.getofferbook();

      final data = GetBookOffer.fromJson(jsonDecode(appdata));

      final datafn = jsonDecode(appdata);

      final msg = datafn['message'];

      //  debugPrint("APP data: ${datafn['data']['app_name']}");
      if (data.data != null && data.data!.isNotEmpty) {
        return data.data;
      } else {
        print("getofferbook data is null");
        return [];
      }
    } catch (e) {
      print("getofferbook notifier error is $e");
      return [];
    }
  }

  getbook() async {
    try {
      var appdata = await bookofferApi.getbooks();

      final data = GetBookOffer.fromJson(jsonDecode(appdata));

      final datafn = jsonDecode(appdata);

      final msg = datafn['message'];

      // debugPrint("APP data: $datafn");
      if (data.data != null && data.data!.isNotEmpty) {
        return data;
      } else {
        print("getbooks data is null");
        return [];
      }
    } catch (e) {
      print("getbooks notifier error is $e");
      return [];
    }
  }

  deleteyouraccount(context) async {
    try {
      final email = await cacheNotifier.readCache(key: 'userid');
      final authtoken = await cacheNotifier.readCache(key: 'authtoken');
      var appdata =
          await registerApi.deleteyouraccount(context, email, authtoken);

      // final data = GetBookOffer.fromJson(jsonDecode(appdata));

      final datafn = jsonDecode(appdata);

      final msg = datafn['message'];

      debugPrint("delete account: $msg");
      if (datafn != null) {
        if (datafn['status'] == true) {
          await cacheNotifier.removeCache(key: 'userid');
          await cacheNotifier.removeCache(key: 'user');
          await cacheNotifier.removeCache(key: 'name');
          await cacheNotifier.removeCache(key: 'authtoken');
          //   FirebaseAuth.instance.signOut();
          Constants.showToast("$msg");
          Get.offAll(() => const SplashScreen());
        }

        //return data.data;
      } else {
        print("delete account data is null");
        Get.back();
        return null;
      }
    } catch (e) {
      Constants.showToast('Please connect to the internet');
      print("delete account notifier error is $e");
      Get.back();
      return null;
    }
  }

  Future login(
      {required email,
      required password,
      required BuildContext context}) async {
    try {
      var appdata = await registerApi.login(email: email, password: password);

      final datafn = jsonDecode(appdata);

      // final statuscode = datafn['status_code'];

      final status = datafn['status'];

      final msg = datafn['message'];

      //  debugPrint("APP data: $datafn");

      if (datafn != null) {
        if (datafn['status'] == true) {
          debugPrint("login data: ${datafn['data']['user']['email']}");
          await cacheNotifier.writeCache(
              key: "user", value: '${datafn['data']['user']['email']}');

          await cacheNotifier.writeCache(
              key: "userid", value: '${datafn['data']['user']['user_id']}');

          await cacheNotifier.writeCache(
              key: "name", value: '${datafn['data']['user']['name']}');
          await cacheNotifier.writeCache(
              key: "authtoken", value: '${datafn['data']['token']}');
          await cacheNotifier.writeCache(key: "skip", value: "false");

          LibraryBackupUploadService.runAfterLogin();

          if (context.mounted) {
            // context.pushReplacementNamed(AppRouteConst.navhomeRoute,
            //     pathParameters: {'index': '0'});
            Get.offAll(() => HomeScreen(
                From: "splash",
                selectedVerseNumForRead: "",
                selectedBookForRead: "",
                selectedChapterForRead: "",
                selectedBookNameForRead: "",
                selectedVerseForRead: ""));
          }
          return '${datafn['data']['user']['name']}';
        }
        return showDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: StatusDialog(
                  title: status == true
                      ? 'Successfully Logged In'
                      : msg.toString(),
                  buttonText: status == true ? 'Continue' : 'Retry',
                  onButtonPressed: () {
                    Navigator.of(context).pop();
                  },
                  isSuccess: status == true ? true : false,
                ),
              );
            });
      } else {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Something Went Wrong !',
          backgroundColor: Colors.redAccent,
        );
        return null;
      }
    } catch (e) {
      print("login notifier error is $e");
      return null;
    }
  }

  Future forgotsendotp({
    required email,
    context,
  }) async {
    print("AUTH NOTIFIER: Starting forgotsendotp for email: $email");

    // Check internet connectivity before making API call
    try {
      print("AUTH NOTIFIER: Checking internet connectivity...");
      final hasInternet = await InternetConnection()
          .hasInternetAccess
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print("AUTH NOTIFIER: Internet check timed out - assuming connected");
        return true; // Assume connected if check times out
      });

      print("AUTH NOTIFIER: Internet check result: $hasInternet");

      if (!hasInternet) {
        print("AUTH NOTIFIER: No internet connection detected");
        SnackbarUtil.showSnackbar(
          context: context,
          message:
              'No internet connection. Please check your network and try again.',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }
    } catch (connectivityError) {
      print("AUTH NOTIFIER: Internet check failed: $connectivityError");
      // Continue anyway - the check itself might have failed
    }

    try {
      print("AUTH NOTIFIER: Making API call...");
      var appdata = await registerApi.forgotsendotp(
        email: email.toString().trim(),
      );

      print(
          "AUTH NOTIFIER: Received response, appdata is ${appdata == null ? 'NULL' : 'NOT NULL'}");

      // Check if API returned null (error occurred)
      if (appdata == null) {
        devtools
            .log("AUTH NOTIFIER: API returned null - showing error to user");
        SnackbarUtil.showSnackbar(
          context: context,
          message:
              'Cannot reach server. Please check:\n1. Your internet connection\n2. Server might be down\nPlease try again later.',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }

      print("AUTH NOTIFIER: Attempting to decode JSON response");
      final datafn = jsonDecode(appdata);

      final statuscode = datafn['status_code'];
      final status = datafn['status'];
      final msg = datafn['message'];

      print(
          "AUTH NOTIFIER: Response decoded - Status: $status, StatusCode: $statuscode, Message: $msg");

      await cacheNotifier.writeCache(key: "useremail", value: email.toString());

      if (datafn != null) {
        if (status == true) {
          print(
              "AUTH NOTIFIER: SUCCESS - Showing success message and navigating to OTP screen");
          SnackbarUtil.showSnackbar(
            context: context,
            message: msg,
            backgroundColor: const Color.fromARGB(255, 89, 148, 22),
          );
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => OtpScreen()));
          return true;
        } else {
          print(
              "AUTH NOTIFIER: ERROR - Server returned error: $msg (Status Code: $statuscode)");

          // Show the API message when available; only use "no account" for real not-found cases.
          final raw = msg?.toString().trim() ?? '';
          final lower = raw.toLowerCase();
          final code = int.tryParse(statuscode?.toString() ?? '') ?? 0;
          final String errorMessage;
          if (code == 404 ||
              lower.contains('not found') ||
              lower.contains('no account') ||
              lower.contains('does not exist') ||
              lower.contains('not registered')) {
            errorMessage = raw.isNotEmpty
                ? raw
                : 'No account found with this email. Please check and try again.';
          } else if (raw.isNotEmpty) {
            errorMessage = raw;
          } else if (code >= 500) {
            errorMessage =
                'Unable to process your request. Please try again later.';
          } else {
            errorMessage =
                'Unable to reset password. Please check your email and try again.';
          }

          print("AUTH NOTIFIER: Showing error snackbar to user");
          SnackbarUtil.showSnackbar(
            context: context,
            message: errorMessage,
            backgroundColor: Colors.redAccent,
          );
          return false;
        }
      } else {
        print("AUTH NOTIFIER: ERROR - datafn is null");
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Something Went Wrong !',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }
    } catch (e) {
      // Check if it's a network error (offline) vs other error
      try {
        // Add timeout to internet check to prevent hanging
        final hasInternet = await InternetConnection()
            .hasInternetAccess
            .timeout(const Duration(seconds: 5), onTimeout: () => true);

        if (!hasInternet) {
          SnackbarUtil.showSnackbar(
            context: context,
            message: 'No Internet Connection',
            backgroundColor: Colors.redAccent,
          );
        } else {
          SnackbarUtil.showSnackbar(
            context: context,
            message: 'Unable to connect to server. Please try again.',
            backgroundColor: Colors.redAccent,
          );
        }
      } catch (_) {
        // If internet check fails, show generic error instead of assuming no connection
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Unable to connect to server. Please try again.',
          backgroundColor: Colors.redAccent,
        );
      }
      print("AUTH NOTIFIER: Exception in forgotsendotp: $e");
      print("AUTH NOTIFIER: Exception type: ${e.runtimeType}");
      return false;
    }
  }

  Future forgotverifyotp({
    required otp,
    context,
  }) async {
    final email = await cacheNotifier.readCache(key: 'useremail');
    try {
      var appdata = await registerApi.forgotverifyotp(
        email: email,
        otp: otp,
      );

      // Check if API returned null (error occurred)
      if (appdata == null) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Unable to connect to server. Please try again.',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }

      final datafn = jsonDecode(appdata);

      // final statuscode = datafn['status_code'];

      final status = datafn['status'];

      final msg = datafn['message'];
      final otptoken = '${datafn['data']['token']}';

      debugPrint("otp token data: $otptoken");
      await cacheNotifier.writeCache(key: "otp", value: otp.toString());
      await cacheNotifier.writeCache(
          key: "otptoken", value: otptoken.toString());
      if (datafn != null) {
        if (status == true) {
          SnackbarUtil.showSnackbar(
            context: context,
            message: msg,
            backgroundColor: const Color.fromARGB(255, 89, 148, 22),
          );
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => RestPasswordScreen()));
          return true;
        } else {
          SnackbarUtil.showSnackbar(
            context: context,
            message: msg,
            backgroundColor: Colors.redAccent,
          );
          return false;
        }
      } else {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Something Went Wrong !',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }
    } catch (e) {
      SnackbarUtil.showSnackbar(
        context: context,
        message: 'Something Went Wrong !',
        backgroundColor: Colors.redAccent,
      );
      print("forgot otp verify notifier error is $e");
      return false;
    }
  }

  Future forgotrestpwd(
      {required passwordconfirmation, required password, context}) async {
    final email = await cacheNotifier.readCache(key: 'useremail');
    final otp = await cacheNotifier.readCache(key: 'otp');
    final token = await cacheNotifier.readCache(key: 'otptoken');
    try {
      var appdata = await registerApi.forgotrestpwd(
        email: email,
        otp: otp,
        token: token,
        passwordconfirmation: passwordconfirmation,
        password: password,
      );

      // Check if API returned null (error occurred)
      if (appdata == null) {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Unable to connect to server. Please try again.',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }

      final datafn = jsonDecode(appdata);

      // final statuscode = datafn['status_code'];

      final status = datafn['status'];

      final msg = datafn['message'];

      //  debugPrint("APP data: $datafn");

      if (datafn != null) {
        if (status == true) {
          SnackbarUtil.showSnackbar(
            context: context,
            message: msg,
            backgroundColor: const Color.fromARGB(255, 89, 148, 22),
          );

          Get.offAll(() => LoginScreen(
                hasSkip: false,
              ));
          // Get.offAll(() => HomeScreen(
          //     From: "splash",
          //     selectedVerseNumForRead: "",
          //     selectedBookForRead: "",
          //     selectedChapterForRead: "",
          //     selectedBookNameForRead: "",
          //     selectedVerseForRead: ""));

          return true;
        } else {
          SnackbarUtil.showSnackbar(
            context: context,
            message: msg,
            backgroundColor: Colors.redAccent,
          );
          return false;
        }
      } else {
        SnackbarUtil.showSnackbar(
          context: context,
          message: 'Something Went Wrong !',
          backgroundColor: Colors.redAccent,
        );
        return false;
      }
    } catch (e) {
      print("login notifier error is $e");
      return false;
    }
  }

  Future updateprofle(
      {required email,
      required name,
      required BuildContext context,
      File? profileImage}) async {
    //final email = await cacheNotifier.readCache(key: 'useremail');
    // final otp = await cacheNotifier.readCache(key: 'otp');
    // final token = await cacheNotifier.readCache(key: 'otptoken');
    try {
      print(
          'updateprofle Data → email=$email name=$name profile_image=${profileImage?.path}');
      var appdata = await profileUpdateApi.updateprofile(
        email: email,
        name: name,
        profileImage: profileImage,
      );

      final datafn = jsonDecode(appdata);

      // final statuscode = datafn['status_code'];

      final status = datafn['status'];

      final msg = datafn['message'];

      //  debugPrint("APP data: $datafn");

      if (datafn != null) {
        if (status == true) {
          await cacheNotifier.writeCache(key: "user", value: email.toString());
          await cacheNotifier.writeCache(key: "name", value: name.toString());
          // Additive: cache profile image URL from API (for Prayer Wall post).
          final imageUrl = _profileImageUrlFromResponse(datafn);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            await cacheNotifier.writeCache(
                key: 'profile_image', value: imageUrl);
            print('Cached profile_image URL → $imageUrl');
          } else {
            final firebaseUrl =
                FirebaseAuth.instance.currentUser?.photoURL?.trim();
            if (firebaseUrl != null && firebaseUrl.isNotEmpty) {
              await cacheNotifier.writeCache(
                  key: 'profile_image', value: firebaseUrl);
              print('Cached profile_image from Firebase → $firebaseUrl');
            }
          }
          if (context.mounted) {
            SnackbarUtil.showSnackbar(
              context: context,
              message: msg,
              backgroundColor: const Color.fromARGB(255, 89, 148, 22),
            );
          }
          if (context.mounted) {
            Get.offAll(() => HomeScreen(
                From: "splash",
                selectedVerseNumForRead: "",
                selectedBookForRead: "",
                selectedChapterForRead: "",
                selectedBookNameForRead: "",
                selectedVerseForRead: ""));
            // context.goNamed(AppRouteConst.navhomeRoute,
            //     pathParameters: {'index': '0'});
          }
          return true;
        } else {
          if (context.mounted) {
            SnackbarUtil.showSnackbar(
              context: context,
              message: msg,
              backgroundColor: Colors.redAccent,
            );
          }
          return false;
        }
      } else {
        if (context.mounted) {
          SnackbarUtil.showSnackbar(
            context: context,
            message: 'Something Went Wrong !',
            backgroundColor: Colors.redAccent,
          );
        }
        return false;
      }
    } catch (e) {
      Constants.showToast('Check your Internet connection');
      print("login notifier error is $e");
      return false;
    }
  }
}

class StatusDialog extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool isSuccess;

  const StatusDialog({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onButtonPressed,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    Sizecf().init(context);
    return Container(
      width: Sizecf.scrnWidth! * 0.75,
      height: Sizecf.scrnHeight! * 0.31,
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Sizecf.scrnHeight! * 0.01,
            ),
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 64,
            ),
            SizedBox(
              height: Sizecf.scrnHeight! * 0.03,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              height: Sizecf.scrnHeight! * 0.03,
            ),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSuccess ? CommanColor.darkPrimaryColor : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnackbarUtil {
  // Private constructor to prevent instantiation
  SnackbarUtil._();

  static void showSnackbar({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Remove any existing Snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
