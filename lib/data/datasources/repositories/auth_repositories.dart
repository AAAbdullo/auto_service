import 'package:auto_service/data/datasources/local/local_storage.dart';

class AuthRepository {
  final LocalStorage _localStorage;

  // Демо-аккаунты сотрудников автосервисов
  static const Map<String, String> demoServiceEmployees = {
    '+998901234567': '1111', // Первый автосервис
    '+998903456789': '2222', // Второй автосервис
  };

  AuthRepository(this._localStorage);

  Future<bool> login(String phone, String password) async {
    // Проверяем демо-аккаунты сотрудников
    if (demoServiceEmployees.containsKey(phone) &&
        demoServiceEmployees[phone] == password) {
      await _localStorage.saveLoggedUser(phone);
      await _localStorage.saveServiceEmployeeFlag(phone, true);
      return true;
    }

    // Обычная проверка для других пользователей
    final savedPassword = await _localStorage.getPassword(phone);
    if (savedPassword != null && savedPassword == password) {
      await _localStorage.saveLoggedUser(phone);
      return true;
    }
    return false;
  }

  /// Проверяет, является ли пользователь сотрудником автосервиса
  Future<bool> isServiceEmployee(String phone) async {
    if (demoServiceEmployees.containsKey(phone)) {
      return true;
    }
    return await _localStorage.isServiceEmployee(phone);
  }

  Future<bool> register(String phone, String password) async {
    final existingPassword = await _localStorage.getPassword(phone);
    if (existingPassword != null) {
      return false; // Пользователь уже существует
    }
    await _localStorage.savePassword(phone, password);
    await _localStorage.saveLoggedUser(phone);
    return true;
  }

  Future<void> logout() async {
    await _localStorage.clearLoggedUser();
  }

  Future<String?> getCurrentUser() async {
    return await _localStorage.getLoggedUser();
  }
}
