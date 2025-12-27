import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized API logging utility for debugging HTTP requests and responses
class ApiLogger {
  static const bool _enableLogging = true; // Set to false to disable all logs

  /// Log levels
  static const String _debug = '🔍';
  static const String _info = '📡';
  static const String _success = '✅';
  static const String _warning = '⚠️';
  static const String _error = '❌';

  /// Log an HTTP request
  static void logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_enableLogging || !kDebugMode) return;

    debugPrint('\n$_info ========== HTTP REQUEST ==========');
    debugPrint('$_info Method: $method');
    debugPrint('$_info URL: $uri');

    if (headers != null && headers.isNotEmpty) {
      debugPrint('$_info Headers:');
      headers.forEach((key, value) {
        // Mask sensitive headers
        if (key.toLowerCase() == 'authorization') {
          debugPrint(
            '  $key: Bearer ***${value.substring(value.length > 10 ? value.length - 10 : 0)}',
          );
        } else {
          debugPrint('  $key: $value');
        }
      });
    }

    if (body != null) {
      debugPrint('$_info Body:');
      _logBody(body);
    }
    debugPrint('$_info ====================================\n');
  }

  /// Log an HTTP response
  static void logResponse(
    String method,
    Uri uri,
    http.Response response,
    Duration duration,
  ) {
    if (!_enableLogging || !kDebugMode) return;

    final statusCode = response.statusCode;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? _success : _error;

    debugPrint('\n$icon ========== HTTP RESPONSE ==========');
    debugPrint('$icon Method: $method');
    debugPrint('$icon URL: $uri');
    debugPrint('$icon Status: $statusCode ${_getStatusText(statusCode)}');
    debugPrint('$icon Duration: ${duration.inMilliseconds}ms');

    if (response.body.isNotEmpty) {
      debugPrint('$icon Response Body:');
      _logBody(response.body);
    }
    debugPrint('$icon ====================================\n');
  }

  /// Log an error
  static void logError(
    String method,
    Uri uri,
    dynamic error, {
    StackTrace? stackTrace,
    http.Response? response,
  }) {
    if (!_enableLogging || !kDebugMode) return;

    debugPrint('\n$_error ========== HTTP ERROR ==========');
    debugPrint('$_error Method: $method');
    debugPrint('$_error URL: $uri');
    debugPrint('$_error Error: $error');

    if (response != null) {
      debugPrint('$_error Status Code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('$_error Response Body:');
        _logBody(response.body);
      }
    }

    if (stackTrace != null) {
      debugPrint('$_error Stack Trace:');
      debugPrint(stackTrace.toString());
    }
    debugPrint('$_error ====================================\n');
  }

  /// Log a warning message
  static void logWarning(String message) {
    if (!_enableLogging || !kDebugMode) return;
    debugPrint('$_warning $message');
  }

  /// Log an info message
  static void logInfo(String message) {
    if (!_enableLogging || !kDebugMode) return;
    debugPrint('$_info $message');
  }

  /// Log a debug message
  static void logDebug(String message) {
    if (!_enableLogging || !kDebugMode) return;
    debugPrint('$_debug $message');
  }

  /// Log a success message
  static void logSuccess(String message) {
    if (!_enableLogging || !kDebugMode) return;
    debugPrint('$_success $message');
  }

  /// Log data validation issues
  static void logValidation(String field, dynamic expected, dynamic actual) {
    if (!_enableLogging || !kDebugMode) return;
    debugPrint(
      '$_warning Validation: Field "$field" - Expected: $expected, Got: $actual',
    );
  }

  /// Pretty print JSON body
  static void _logBody(dynamic body) {
    try {
      if (body is String) {
        // Skip logging HTML responses (likely Django error pages)
        if (body.contains('<html') || body.contains('<!DOCTYPE')) {
          // Try to extract error message from Django debug page
          try {
            if (body.contains('Exception Value:')) {
              final start = body.indexOf('Exception Value:') + 16;
              final end = body.indexOf('</td>', start);
              if (end > start) {
                final errorMsg = body.substring(start, end).trim();
                debugPrint('[Django Error] $errorMsg');
                return;
              }
            }
          } catch (_) {}
          
          debugPrint('[HTML Response - check Django server console for details]');
          return;
        }
        
        // Truncate very large responses
        if (body.length > 5000) {
          debugPrint('${body.substring(0, 5000)}...\n[Response truncated - total length: ${body.length} bytes]');
          return;
        }
        
        // Try to parse as JSON for pretty printing
        try {
          final decoded = jsonDecode(body);
          final prettyJson = const JsonEncoder.withIndent(
            '  ',
          ).convert(decoded);
          debugPrint(prettyJson);
        } catch (_) {
          // Not JSON, print as is
          debugPrint(body);
        }
      } else if (body is Map || body is List) {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(body);
        debugPrint(prettyJson);
      } else {
        debugPrint(body.toString());
      }
    } catch (e) {
      debugPrint('Failed to log body: $e');
    }
  }

  /// Get human-readable status text
  static String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      default:
        return '';
    }
  }

  /// Log token refresh event
  static void logTokenRefresh(bool success) {
    if (!_enableLogging || !kDebugMode) return;
    if (success) {
      debugPrint('$_success Token refreshed successfully');
    } else {
      debugPrint('$_error Token refresh failed');
    }
  }

  /// Log authentication event
  static void logAuth(String event, {bool success = true}) {
    if (!_enableLogging || !kDebugMode) return;
    final icon = success ? _success : _error;
    debugPrint('$icon Auth Event: $event');
  }
}
