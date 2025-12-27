import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Singleton HTTP client to reuse connections across the app
class HttpClientManager {
  static final HttpClientManager _instance = HttpClientManager._internal();
  static late http.Client _client;

  factory HttpClientManager() {
    return _instance;
  }

  HttpClientManager._internal() {
    _client = _createHttpClient();
  }

  /// Create HTTP client with SSL certificate handling
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    
    // Игнорируем самоподписанные сертификаты (для development/testing)
    // В production нужно правильно настроить сертификаты
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      debugPrint('⚠️ SSL Certificate verification skipped for: $host:$port');
      // Возвращаем true чтобы принять самоподписанный сертификат
      // ВАЖНО: В production это нужно изменить!
      return true;
    };
    
    return IOClient(httpClient);
  }

  /// Get the singleton HTTP client
  static http.Client get client => _client;

  /// Close the client (useful for cleanup)
  static void closeClient() {
    _client.close();
    _client = _createHttpClient();
  }
}
