import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _kDarkModeKey = 'dark_mode';

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  /// 앱 시작 시 한 번 호출해서 저장된 설정값 로드
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDarkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = value;
    await prefs.setBool(_kDarkModeKey, value);
    notifyListeners();
  }
}