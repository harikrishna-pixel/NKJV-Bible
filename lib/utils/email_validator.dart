/// Stricter email validation than [FormBuilderValidators.email]:
/// blocks common typo TLDs (e.g. .con) and uncommon/invalid extensions.
class AppEmailValidator {
  AppEmailValidator._();

  static const _blockedTlds = <String>{
    'con',
    'cmo',
    'comm',
    'coom',
    'nett',
    'orgg',
    'orgn',
    'xyz',
  };

  static const _commonTlds = <String>{
    'com',
    'net',
    'org',
    'edu',
    'gov',
    'mil',
    'int',
    'info',
    'biz',
    'name',
    'pro',
    'co',
    'io',
    'me',
    'app',
    'dev',
    'ai',
    'tv',
    'cc',
    'us',
    'uk',
    'ca',
    'au',
    'in',
    'de',
    'fr',
    'es',
    'it',
    'nl',
    'br',
    'mx',
    'jp',
    'kr',
    'cn',
    'ru',
    'za',
    'ng',
    'ke',
    'ph',
    'pk',
    'bd',
    'id',
    'my',
    'sg',
    'hk',
    'tw',
    'nz',
    'ie',
    'pl',
    'se',
    'no',
    'fi',
    'dk',
    'at',
    'ch',
    'be',
    'pt',
    'gr',
    'cz',
    'ro',
    'hu',
    'il',
    'ae',
    'sa',
    'eg',
    'tr',
    'ua',
    'ar',
    'cl',
    'pe',
    've',
    'online',
    'site',
    'store',
    'shop',
    'blog',
    'cloud',
    'live',
  };

  static const _typoDomainLabels = <String>{
    'gnail',
    'gmial',
    'gmal',
    'gamil',
    'gmai',
    'hotmial',
    'hotmal',
    'outlok',
    'outllok',
    'yaho',
    'yahooo',
  };

  static final RegExp _structure = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,24}$',
  );

  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final email = value.trim().toLowerCase();
    if (email.contains('.@') ||
        email.contains('@.') ||
        email.contains('..')) {
      return 'Email is not valid';
    }

    if (!_structure.hasMatch(email)) {
      return 'Email is not valid';
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Email is not valid';
    }

    final local = parts[0];
    if (local.isEmpty ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return 'Email is not valid';
    }

    final domain = parts[1];
    if (domain.startsWith('.') ||
        domain.endsWith('.') ||
        domain.contains('..')) {
      return 'Email is not valid';
    }

    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'Email is not valid';
    }

    for (final label in domainParts) {
      if (label.isEmpty || _typoDomainLabels.contains(label)) {
        return 'Email is not valid';
      }
    }

    final tld = domainParts.last;
    if (tld.length < 2 || _blockedTlds.contains(tld)) {
      return 'Email is not valid';
    }

    final isTwoLetterCountry =
        tld.length == 2 && RegExp(r'^[a-z]{2}$').hasMatch(tld);
    if (!_commonTlds.contains(tld) && !isTwoLetterCountry) {
      return 'Email is not valid';
    }

    return null;
  }
}
