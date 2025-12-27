/// HTTP Status Codes enum
enum HttpStatusCode {
  // 2xx Success
  ok(200),
  created(201),
  accepted(202),
  noContent(204),

  // 3xx Redirection
  movedPermanently(301),
  found(302),
  notModified(304),

  // 4xx Client Error
  badRequest(400),
  unauthorized(401),
  forbidden(403),
  notFound(404),
  methodNotAllowed(405),
  conflict(409),
  unprocessableEntity(422),

  // 5xx Server Error
  internalServerError(500),
  badGateway(502),
  serviceUnavailable(503),
  gatewayTimeout(504);

  final int code;

  const HttpStatusCode(this.code);

  /// Check if response was successful (2xx)
  bool get isSuccess => code >= 200 && code < 300;

  /// Check if client error (4xx)
  bool get isClientError => code >= 400 && code < 500;

  /// Check if server error (5xx)
  bool get isServerError => code >= 500 && code < 600;

  /// Get status from code
  static HttpStatusCode? fromCode(int code) {
    try {
      return HttpStatusCode.values.firstWhere((status) => status.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get human-readable status message
  String get message {
    switch (this) {
      case HttpStatusCode.ok:
        return 'OK';
      case HttpStatusCode.created:
        return 'Created';
      case HttpStatusCode.accepted:
        return 'Accepted';
      case HttpStatusCode.noContent:
        return 'No Content';
      case HttpStatusCode.movedPermanently:
        return 'Moved Permanently';
      case HttpStatusCode.found:
        return 'Found';
      case HttpStatusCode.notModified:
        return 'Not Modified';
      case HttpStatusCode.badRequest:
        return 'Bad Request';
      case HttpStatusCode.unauthorized:
        return 'Unauthorized';
      case HttpStatusCode.forbidden:
        return 'Forbidden';
      case HttpStatusCode.notFound:
        return 'Not Found';
      case HttpStatusCode.methodNotAllowed:
        return 'Method Not Allowed';
      case HttpStatusCode.conflict:
        return 'Conflict';
      case HttpStatusCode.unprocessableEntity:
        return 'Unprocessable Entity';
      case HttpStatusCode.internalServerError:
        return 'Internal Server Error';
      case HttpStatusCode.badGateway:
        return 'Bad Gateway';
      case HttpStatusCode.serviceUnavailable:
        return 'Service Unavailable';
      case HttpStatusCode.gatewayTimeout:
        return 'Gateway Timeout';
    }
  }
}

/// API Error codes
enum ApiErrorCode {
  networkError('network_error'),
  timeout('timeout'),
  invalidResponse('invalid_response'),
  authenticationFailed('authentication_failed'),
  authorizationFailed('authorization_failed'),
  notFound('not_found'),
  validationError('validation_error'),
  serverError('server_error'),
  unknownError('unknown_error');

  final String code;

  const ApiErrorCode(this.code);

  /// Get human-readable error message
  String get message {
    switch (this) {
      case ApiErrorCode.networkError:
        return 'Network connection error. Please check your internet connection.';
      case ApiErrorCode.timeout:
        return 'Request timed out. Please try again.';
      case ApiErrorCode.invalidResponse:
        return 'Invalid response from server.';
      case ApiErrorCode.authenticationFailed:
        return 'Authentication failed. Please login again.';
      case ApiErrorCode.authorizationFailed:
        return 'You do not have permission to perform this action.';
      case ApiErrorCode.notFound:
        return 'The requested resource was not found.';
      case ApiErrorCode.validationError:
        return 'Please check your input and try again.';
      case ApiErrorCode.serverError:
        return 'Server error. Please try again later.';
      case ApiErrorCode.unknownError:
        return 'An unknown error occurred.';
    }
  }
}
