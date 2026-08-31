class CountryLocal {
  final isoLangs = {
    "GB": {"name": "United Kingdom"},
    "US": {"name": "United States"},
    "AU": {"name": "Australia"},
    "NG": {"name": "New Zealand"},
    "IN": {"name": "India"},

  };

  getDisplayCountry(key) {
    if (isoLangs.containsKey(key)) {
      return isoLangs[key];
    } else {
      throw Exception("Country key incorrect");
    }
  }
}