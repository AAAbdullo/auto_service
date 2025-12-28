class ApiConfig {
  // Base URLs
  static const String baseUrl = 'https://avtomakon.airi.uz';
  static const String apiUrl = '$baseUrl/api';

  // API Version
  static const String apiVersion = '1.0.0';

  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Debug settings
  static const bool enableApiLogging = true; // Set to false in production
}
