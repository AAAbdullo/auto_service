import 'package:auto_service/core/utils/api_logger.dart';

/// Retry configuration
class RetryConfig {
  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay between retries in milliseconds
  final Duration initialDelay;

  /// Maximum delay between retries in milliseconds
  final Duration maxDelay;

  /// Multiplier for exponential backoff (default: 2)
  final double backoffMultiplier;

  /// List of HTTP status codes that should trigger a retry
  final List<int> retryableStatusCodes;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });
}

/// Helper class for retrying operations with exponential backoff
class RetryHelper {
  static final RetryConfig _defaultConfig = const RetryConfig();

  /// Retry a function with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(Exception)? retryIf,
    void Function(int, Duration)? onRetry,
  }) async {
    config ??= _defaultConfig;
    var retryCount = 0;
    var delay = config.initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        // Check if we should retry
        final shouldRetry = retryCount < config.maxAttempts &&
            (retryIf == null || (e is Exception && retryIf(e)));

        if (!shouldRetry) {
          rethrow;
        }

        // Log retry attempt
        ApiLogger.logWarning(
          'Retry attempt $retryCount/${ config.maxAttempts} after ${delay.inMilliseconds}ms',
        );

        onRetry?.call(retryCount, delay);

        // Wait before retrying
        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).toInt(),
        );

        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }
      }
    }
  }

  /// Check if a status code is retryable
  static bool isRetryableStatusCode(int statusCode, [RetryConfig? config]) {
    config ??= _defaultConfig;
    return config.retryableStatusCodes.contains(statusCode);
  }
}
