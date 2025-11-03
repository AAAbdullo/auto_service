import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageProvider extends ChangeNotifier {
  String? _profileImagePath;
  static const String _profileImageKey = 'profile_image_path';

  String? get profileImagePath => _profileImagePath;

  ProfileImageProvider() {
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileImagePath = prefs.getString(_profileImageKey);
      notifyListeners();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> setProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, imagePath);
      _profileImagePath = imagePath;
      notifyListeners();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> removeProfileImage() async {
    try {
      // Сохраняем путь к файлу перед очисткой
      final imagePathToDelete = _profileImagePath;

      // Очищаем SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageKey);

      // Очищаем переменную
      _profileImagePath = null;
      notifyListeners();

      // Удаляем файл с диска (если он существует)
      if (imagePathToDelete != null && imagePathToDelete.isNotEmpty) {
        try {
          final file = File(imagePathToDelete);
          if (await file.exists()) {
            await file.delete();
          }
          // ignore: empty_catches
        } catch (fileError) {}
      }
    } catch (e) {
      // В случае ошибки все равно очищаем переменную
      _profileImagePath = null;
      notifyListeners();
    }
  }

  bool get hasProfileImage => _profileImagePath != null;
}
