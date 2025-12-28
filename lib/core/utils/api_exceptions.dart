import 'package:auto_service/core/constants/http_status_codes.dart';

/// Base API Exception
class ApiException implements Exception {
  final String message;
  final ApiErrorCode errorCode;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final int? statusCode;

  ApiException({
    required this.message,
    this.errorCode = ApiErrorCode.unknownError,
    this.originalError,
    this.stackTrace,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException: $message (Code: ${errorCode.code})';
}

/// Network timeout exception
class TimeoutException extends ApiException {
  TimeoutException({
    super.message = 'Request timed out',
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.timeout,
  );
}

/// Network error exception
class NetworkException extends ApiException {
  NetworkException({
    super.message = 'Network error',
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.networkError,
  );
}

/// Authentication error exception
class AuthenticationException extends ApiException {
  AuthenticationException({
    super.message = 'Authentication failed',
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.authenticationFailed,
    statusCode: 401,
  );
}

/// Authorization error exception
class AuthorizationException extends ApiException {
  AuthorizationException({
    super.message = 'Authorization failed',
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.authorizationFailed,
    statusCode: 403,
  );
}

/// Not found exception
class NotFoundException extends ApiException {
  NotFoundException({
    super.message = 'Resource not found',
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.notFound,
    statusCode: 404,
  );
}

/// Validation error exception
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({
    super.message = 'Validation error',
    this.errors,
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.validationError,
    statusCode: 422,
  );
}

/// Server error exception
class ServerException extends ApiException {
  ServerException({
    super.message = 'Server error',
    super.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(
    errorCode: ApiErrorCode.serverError,
  );
}

/// Create appropriate exception based on status code
ApiException createException({
  required int statusCode,
  required String message,
  dynamic originalError,
  StackTrace? stackTrace,
  Map<String, dynamic>? errors,
}) {
  switch (statusCode) {
    case 401:
      return AuthenticationException(
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    case 403:
      return AuthorizationException(
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    case 404:
      return NotFoundException(
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    case 422:
      return ValidationException(
        message: message,
        errors: errors,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    case >= 500:
      return ServerException(
        message: message,
        statusCode: statusCode,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    default:
      return ApiException(
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
        statusCode: statusCode,
      );
  }
}
