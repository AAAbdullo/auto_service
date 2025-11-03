import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  String? _currentUserPhone;
  bool _isLoading = false;
  bool _isServiceEmployee = false;

  AuthProvider(this._authRepository);

  String? get currentUserPhone => _currentUserPhone;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUserPhone != null;
  bool get isServiceEmployee => _isServiceEmployee;

  Future<void> init() async {
    _currentUserPhone = await _authRepository.getCurrentUser();
    if (_currentUserPhone != null) {
      _isServiceEmployee = await _authRepository.isServiceEmployee(
        _currentUserPhone!,
      );
    }
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authRepository.login(phone, password);
    if (success) {
      _currentUserPhone = phone;
      _isServiceEmployee = await _authRepository.isServiceEmployee(phone);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authRepository.register(phone, password);
    if (success) {
      _currentUserPhone = phone;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUserPhone = null;
    _isServiceEmployee = false;
    notifyListeners();
  }
}
