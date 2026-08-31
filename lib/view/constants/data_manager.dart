

class DataManager {
  var themeMode;

  static final DataManager ourInstance = DataManager();

  static DataManager getInstance() { return ourInstance;}

  String getThemeMode() {
    return themeMode;
  }
  setThemeMode(value) {
    themeMode = value;
  }

}