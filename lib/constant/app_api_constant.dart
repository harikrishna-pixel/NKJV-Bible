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
  static const deleteacctapi =
      'https://bibleoffice.com/authhub/API/public/api/delete-account';
  static const bookofferapi =
      "https://saveigm.com/bookads/admin/api/book/book_list_by_cat";
  
  // Language code for chat responses (e.g., 'TN' for Tamil, 'EN' for English, null for default)
  static const String? chatLanguage = "EN"; // Set to 'TN' for Tamil, 'EN' for English, or null for default
}
