import 'package:auto_service/data/datasources/repositories/auth_repositories.dart';
import 'package:flutter/foundation.dart';

import 'package:auto_service/data/models/user_profile_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  String? _currentUserPhone;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isServiceEmployee = false;

  AuthProvider(this._authRepository);

  String? get currentUserPhone => _currentUserPhone;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUserPhone != null;
  bool get isServiceEmployee => _isServiceEmployee;

  Future<void> init() async {
    _currentUserPhone = await _authRepository.getCurrentUser();
    if (_currentUserPhone != null) {
      // 🔄 Proactively refresh access token on app startup
      // This prevents 401 errors when access token expires after 24 hours
      try {
        final refreshToken = await _authRepository.getRefreshToken();
        if (refreshToken != null) {
          debugPrint('🔑 Proactively refreshing access token on startup...');
          final newAccessToken = await _authRepository.refreshAccessToken();

          if (newAccessToken == null) {
            // Refresh token expired - logout gracefully
            debugPrint('⚠️ Refresh token expired, logging out...');
            await logout();
            return;
          }
          debugPrint('✅ Access token refreshed successfully');
        }
      } catch (e) {
        debugPrint('❌ Error refreshing token on startup: $e');
        // If refresh fails, try to continue - getUserProfile will handle 401
      }

      // Fetch full profile locally or from API if token exists
      await refreshProfile();

      // If profile fetch failed (user was logged out), don't proceed
      if (_currentUserPhone == null) return;

      // Keep legacy check for compatibility if needed, or rely on profile
      _isServiceEmployee = await _authRepository.isServiceEmployee(
        _currentUserPhone!,
      );
    }
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _userProfile = await _authRepository.getUserProfile();
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authRepository.login(phone, password);
    if (success) {
      _currentUserPhone = phone;
      await refreshProfile();
      _isServiceEmployee = await _authRepository.isServiceEmployee(phone);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(
    String phone,
    String password,
    String fullName,
    String email,
  ) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authRepository.register(
      phone,
      password,
      fullName: fullName,
      email: email,
    );
    if (success) {
      // If auto-login logic exists in register, set phone.
      // Current repo register returns bool but doesn't auto-login usually.
      // But if we want to be safe:
      // _currentUserPhone = phone;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUserPhone = null;
    _userProfile = null;
    _isServiceEmployee = false;
    notifyListeners();
  }

  Future<String?> getAccessToken() => _authRepository.getAccessToken();

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_userProfile == null) return false;
    final success = await _authRepository.updateUserProfile(
      _userProfile!.id,
      data,
    );
    if (success) {
      await refreshProfile();
    }
    return success;
  }

  Future<bool> uploadProfileImage(String path) async {
    final success = await _authRepository.uploadUserImage(path);
    if (success) {
      await refreshProfile();
    }
    return success;
  }
}
