import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeMode _appThemeMode = AppThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeMode get appThemeMode => _appThemeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Переключение темы между светлой и тёмной
  void toggleTheme() {
    if (_appThemeMode == AppThemeMode.dark) {
      setTheme(AppThemeMode.light);
    } else {
      setTheme(AppThemeMode.dark);
    }
  }

  void setTheme(AppThemeMode mode) async {
    _appThemeMode = mode;
    switch (mode) {
      case AppThemeMode.system:
        _themeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        break;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', mode.index);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('themeMode') ?? 0;
    setTheme(AppThemeMode.values[index]);
  }
}
