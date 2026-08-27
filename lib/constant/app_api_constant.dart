import 'package:biblebookapp/view/constants/share_preferences.dart';

class AppApiConstant {
  static const appdata =
      "https://bibleoffice.com/BibleReplications/dev/v1/API/getAppInfo.php";

  static const baseurl = "https://bibleoffice.com/authhub/API/public/";

  static const gettemptokenapi = 'api/temp-token';
  static const registerapi = 'api/register';
  static const loginapi = 'api/login';
  /// AuthHub profile (PDF Steps 2/5): `POST /api/profile`.
  static const profileapi = 'api/profile';
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

  static String autoCloudBackupText =
      'If you don\'t export manually, your library is backed up automatically when you sign in. A daily cloud backup also runs after 2:00 AM when you open the app (signed-in users only).';

  /// API prefs sometimes store flags like "1" instead of a real product id.
  static String resolveSubscriptionProductId(String? stored, String fallback) {
    final value = stored?.trim() ?? '';
    if (value.contains('.') && value.startsWith('com.')) {
      return value;
    }
    return fallback;
  }

  /// App Store may use `adfree` or `adsfree` suffix — query both spellings.
  static Set<String> subscriptionProductIdQueryVariants(String planId) {
    final variants = <String>{planId.trim()};
    if (planId.contains('adsfree')) {
      variants.add(planId.replaceFirst('adsfree', 'adfree'));
    } else if (planId.contains('adfree')) {
      variants.add(planId.replaceFirst('adfree', 'adsfree'));
    }
    return variants;
  }

  static Set<String> paywallStoreQueryIds({
    required String sixMonthPlan,
    required String oneYearPlan,
    required String twoYearPlan,
    String? lifeTimePlan,
  }) {
    return {
      ...subscriptionProductIdQueryVariants(sixMonthPlan),
      ...subscriptionProductIdQueryVariants(oneYearPlan),
      ...subscriptionProductIdQueryVariants(twoYearPlan),
      if (lifeTimePlan != null && lifeTimePlan.trim().isNotEmpty)
        ...subscriptionProductIdQueryVariants(lifeTimePlan),
    };
  }

}

