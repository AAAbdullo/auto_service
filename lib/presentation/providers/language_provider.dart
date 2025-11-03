import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('uz');
  bool _isLoaded = false;

  Locale get locale => _locale;

  LanguageProvider();

  Future<void> setLanguage(BuildContext context, String code) async {
    final newLocale = Locale(code);
    if (_locale != newLocale) {
      _locale = newLocale;
      await context.setLocale(newLocale); // Синхронизация с easy_localization
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', code);
      notifyListeners();
    }
  }

  Future<void> loadLanguage(BuildContext? context) async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('language_code')) {
      final code = prefs.getString('language_code') ?? 'uz';
      _locale = Locale(code);
      if (context != null) {
        await context.setLocale(_locale);
      }
    } else {
      // Нет сохранённого значения — синхронизируемся с текущим языком приложения
      if (context != null) {
        _locale = context.locale;
      } else {
        _locale = const Locale('uz');
      }
    }

    _isLoaded = true;
    notifyListeners();
  }
}
