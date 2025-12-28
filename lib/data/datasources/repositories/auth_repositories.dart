import 'dart:convert';
import 'package:auto_service/core/utils/api_logger.dart';
import 'package:http/http.dart' as http;
import 'package:auto_service/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/models/user_profile_model.dart';

class AuthRepository {
  final LocalStorage _localStorage;

  AuthRepository(this._localStorage);

  Future<bool> login(String phone, String password) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/userx/login/');
    final body = {'phone': phone, 'password': password};
    final headers = {'Content-Type': 'application/json'};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('POST', uri, headers: headers, body: body);

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        final refresh = data['refresh'];

        if (access != null && refresh != null) {
          await _localStorage.saveAuthToken(access, refresh);
          await _localStorage.saveLoggedUser(phone);
          ApiLogger.logInfo('Login successful for $phone');
          return true;
        } else {
          ApiLogger.logWarning('Login response missing tokens');
        }
      } else {
        ApiLogger.logError('POST', uri, 'Login failed', response: response);
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
    }
    return false;
  }

  /// Проверяет, является ли пользователь сотрудником автосервиса
  Future<bool> isServiceEmployee(String phone) async {
    // For now, return false or check local flag if we set it manually
    return await _localStorage.isServiceEmployee(phone);
  }

  Future<bool> register(
    String phone,
    String password, {
    String? fullName,
    String? telegram,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/userx/register/');
    final body = {
      'phone': phone,
      'password': password,
      'full_name': fullName ?? 'New User',
      'telegram': telegram,
    };
    final headers = {'Content-Type': 'application/json'};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('POST', uri, headers: headers, body: body);

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 201) {
        ApiLogger.logInfo('Registration successful for $phone');
        return true;
      } else {
        ApiLogger.logError(
          'POST',
          uri,
          'Registration failed',
          response: response,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
    }
    return false;
  }

  Future<void> logout() async {
    final refreshToken = await _localStorage.getRefreshToken();

    if (refreshToken != null) {
      // Call backend logout endpoint to blacklist the refresh token
      final uri = Uri.parse('${ApiConfig.apiUrl}/userx/logout/');
      final body = {'refresh': refreshToken};
      final headers = {'Content-Type': 'application/json'};

      final stopwatch = Stopwatch()..start();
      ApiLogger.logRequest('POST', uri, headers: headers, body: body);

      try {
        final response = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(ApiConfig.connectionTimeout);

        stopwatch.stop();
        ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

        if (response.statusCode == 200) {
          ApiLogger.logInfo('Logout successful - token blacklisted');
        } else {
          ApiLogger.logWarning(
            'Logout endpoint returned ${response.statusCode}',
          );
        }
      } catch (e, stackTrace) {
        stopwatch.stop();
        ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
      }
    }

    // Clear local storage regardless of backend response
    await _localStorage.clearLoggedUser();
    await _localStorage.clearAuthToken();
    ApiLogger.logInfo('Local session cleared');
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await _localStorage.getRefreshToken();
    if (refreshToken == null) {
      ApiLogger.logError(
        'REFRESH',
        Uri.parse(''),
        'No refresh token available',
      );
      return null;
    }

    final uri = Uri.parse('${ApiConfig.apiUrl}/userx/token/refresh/');
    final body = {'refresh': refreshToken};
    final headers = {'Content-Type': 'application/json'};

    final stopwatch = Stopwatch()..start();
    ApiLogger.logRequest('POST', uri, headers: headers, body: body);

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectionTimeout);

      stopwatch.stop();
      ApiLogger.logResponse('POST', uri, response, stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        if (access != null) {
          // Обновляем только access токен, если refresh остался тем же
          final currentRefresh = refreshToken;
          await _localStorage.saveAuthToken(access, currentRefresh);
          ApiLogger.logInfo('Access token refreshed successfully');
          return access;
        }
      } else {
        ApiLogger.logError(
          'POST',
          uri,
          'Token refresh failed',
          response: response,
        );
        // Если refresh токен протух, разлогиниваем пользователя
        await logout();
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiLogger.logError('POST', uri, e, stackTrace: stackTrace);
    }
    return null;
  }

  Future<String?> getCurrentUser() async {
    return await _localStorage.getLoggedUser();
  }

  Future<String?> getAccessToken() async {
    return await _localStorage.getAccessToken();
  }

  // --- Profile Management ---

  Future<UserProfile?> getUserProfile() async {
    try {
      final token = await _localStorage.getAccessToken();
      if (token == null) return null;

      final uri = Uri.parse('${ApiConfig.apiUrl}/userx/profile/');
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
    }
    return null;
  }

  Future<bool> updateUserProfile(int id, Map<String, dynamic> data) async {
    try {
      final token = await _localStorage.getAccessToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.apiUrl}/userx/$id/');
      final response = await http
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  Future<bool> uploadUserImage(String imagePath) async {
    try {
      final token = await _localStorage.getAccessToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.apiUrl}/userx/upload-image/');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return false;
    }
  }
}
