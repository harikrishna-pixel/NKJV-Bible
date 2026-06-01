import 'package:biblebookapp/view/constants/share_preferences.dart';

class AppApiConstant {
  static const appdata =
      "https://bibleoffice.com/BibleReplications/dev/v1/API/getAppInfo.php";

  static const baseurl = "https://bibleoffice.com/authhub/API/public/";

  static const gettemptokenapi = 'api/temp-token';
  static const registerapi = 'api/register';
  static const loginapi = 'api/login';
  static const forgotsendotp = 'api/forgot-pwd/send-otp';
  static const forgotverifyotp = 'api/forgot-pwd/verify-otp';
  static const forgotrestpwd = 'api/forgot-pwd/reset-pwd';
  static const updateprofleapi = 'api/profile-update';
  static const userBackupUploadApi = 'api/user-backup/upload';
  static String get userBackupUploadUrl => '$baseurl$userBackupUploadApi';
  static const userBackupDownloadApi = 'api/user-backup/download';
  static String get userBackupDownloadUrl => '$baseurl$userBackupDownloadApi';
  static const deleteacctapi =
      'https://bibleoffice.com/authhub/API/public/api/delete-account';
  static const bookofferapi =
      "https://saveigm.com/bookads/admin/api/book/book_list_by_cat";

  // Language code for chat/Prayer (EN, HI, TN, PT). Loaded from SharedPreferences so app language reflects here.
  static String chatLanguage = "EN";

  static Future<void> loadChatLanguage() async {
    try {
      final lang =
          await SharPreferences.getString(SharPreferences.chatLanguage);
      if (lang != null && lang.isNotEmpty) {
        chatLanguage = lang;
      }
    } catch (_) {}
  }
}
