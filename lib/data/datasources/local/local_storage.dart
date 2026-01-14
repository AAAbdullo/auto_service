import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart'
    show rootBundle; // 👈 для загрузки JSON из assets

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const String _keyLoggedPhone = 'loggedPhone';
  static const String _keyUserData = 'userData';
  static const String _keyFavorites = 'favorites';
  static const String _keyProducts = 'products';
  static const String _keyOrders = 'orders';
  static const String _keyReservedParts = 'reserved_parts';
  static const String _keyServiceEmployee = 'service_employee_';

  static const _secureStorage = FlutterSecureStorage();

  // Инициализация
  Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  // ====================== User ======================
  Future<void> saveLoggedUser(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoggedPhone, phone);
  }

  Future<String?> getLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoggedPhone);
  }

  Future<void> clearLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedPhone);
  }

  Future<void> saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  // WARN: Password storage removed for security.
  // We should rely on tokens for persistence.

  // ====================== Auth Tokens ======================
  static const String _keyAccessToken = 'accessToken';
  static const String _keyRefreshToken = 'refreshToken';

  Future<void> saveAuthToken(String access, String refresh) async {
    await _secureStorage.write(key: _keyAccessToken, value: access);
    await _secureStorage.write(key: _keyRefreshToken, value: refresh);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  // ====================== Favorites ======================
  Future<void> addFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_keyFavorites) ?? [];
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await prefs.setStringList(_keyFavorites, favorites);
    }
  }

  Future<void> removeFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_keyFavorites) ?? [];
    favorites.remove(productId);
    await prefs.setStringList(_keyFavorites, favorites);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  // ====================== Products ======================
  Future<List<ProductModel>?> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyProducts);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => ProductModel.fromJson(e)).toList();
    }
    return null;
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(products.map((e) => e.toJson()).toList());
    await prefs.setString(_keyProducts, data);
  }

  Future<void> clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
  }

  // ====================== Orders ======================

  /// Загружает JSON из языкового файла
  Future<Map<String, String>> _loadLangMap(String path) async {
    try {
      final data = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = json.decode(data);
      return jsonMap.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  /// Ищет ключ перевода по названию (в uz.json или ru.json)
  Future<String?> _findNameKey(String name) async {
    final uz = await _loadLangMap('assets/lang/uz.json');
    final ru = await _loadLangMap('assets/lang/ru.json');

    // normalize: lower case + trim
    String norm(String s) => s.toLowerCase().trim();

    final matchUz = uz.entries.firstWhere(
      (e) => norm(e.value) == norm(name),
      orElse: () => const MapEntry('', ''),
    );
    if (matchUz.key.isNotEmpty) return matchUz.key;

    final matchRu = ru.entries.firstWhere(
      (e) => norm(e.value) == norm(name),
      orElse: () => const MapEntry('', ''),
    );
    if (matchRu.key.isNotEmpty) return matchRu.key;

    return null;
  }

  Future<List<ProductModel>?> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyOrders);
    if (data == null) return null;

    final List<dynamic> jsonList = jsonDecode(data);
    final List<ProductModel> result = [];
    bool updated = false;

    for (final item in jsonList) {
      final map = Map<String, dynamic>.from(item);
      if ((map['nameKey'] == null || map['nameKey'].toString().isEmpty) &&
          map['name'] != null) {
        final key = await _findNameKey(map['name']);
        if (key != null) {
          map['nameKey'] = key;
          updated = true;
        }
      }
      result.add(ProductModel.fromJson(map));
    }

    // если добавились новые nameKey — обновим сохранённый JSON
    if (updated) {
      final newData = jsonEncode(result.map((e) => e.toJson()).toList());
      await prefs.setString(_keyOrders, newData);
    }

    return result;
  }

  Future<void> saveOrders(List<ProductModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(orders.map((e) => e.toJson()).toList());
    await prefs.setString(_keyOrders, data);
  }

  Future<void> addOrder(ProductModel product) async {
    final orders = await getOrders() ?? [];

    // Проверим, есть ли у продукта nameKey
    String? nameKey = product.nameKey;
    if (nameKey == null || nameKey.isEmpty) {
      final found = await _findNameKey(product.name);
      if (found != null) nameKey = found;
    }

    // создаем копию с заполненным nameKey, используя copyWith
    final updatedProduct = product.copyWith();

    orders.insert(0, updatedProduct); // Добавляем в начало списка
    await saveOrders(orders);
  }

  Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrders);
  }

  // ====================== Reserved Parts ======================
  Future<List<ProductModel>?> getReservedParts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyReservedParts);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => ProductModel.fromJson(e)).toList();
    }
    return null;
  }

  Future<void> saveReservedParts(List<ProductModel> parts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(parts.map((e) => e.toJson()).toList());
    await prefs.setString(_keyReservedParts, data);
  }

  Future<void> addReservedPart(ProductModel product) async {
    final parts = await getReservedParts() ?? [];
    parts.add(product);
    await saveReservedParts(parts);
  }

  Future<void> removeReservedPart(String id) async {
    final parts = await getReservedParts() ?? [];
    parts.removeWhere((item) => item.id.toString() == id);
    await saveReservedParts(parts);
  }

  Future<void> clearReservedParts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReservedParts);
  }

  // ====================== Service Employee ======================
  /// Сохраняет флаг сотрудника автосервиса для номера телефона
  Future<void> saveServiceEmployeeFlag(String phone, bool isEmployee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyServiceEmployee$phone', isEmployee);
  }

  /// Проверяет, является ли пользователь сотрудником автосервиса
  Future<bool> isServiceEmployee(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyServiceEmployee$phone') ?? false;
  }
}
