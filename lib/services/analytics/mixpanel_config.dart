/// Mixpanel project tokens and environment switch for Old Paper apps.
///
/// [useProdToken]: `0` = Test project, `1` = Prod project.
/// Keep at `0` until App Store builds should send to production.
class MixpanelConfig {
  MixpanelConfig._();

  /// 0 = test token / environment "test"; 1 = prod token / environment "prod".
  static const int useProdToken = 1;

  static const String prodToken = 'e8b931282c40c9d4d512c73043efa1d2';
  static const String testToken = 'eca394a6c41accbf64fcbed8bdf900ca';

  static const String configUrlBase =
      'https://bibleoffice.com/app-config/mixpanel.php';

  static bool get isProd => useProdToken == 1;

  static String get token => isProd ? prodToken : testToken;

  static String get environment => isProd ? 'prod' : 'test';
}
