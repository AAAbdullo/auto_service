/// Utilities for data validation
class DataValidator {
  /// Validate required field
  static T validateRequired<T>(T? value, String fieldName) {
    if (value == null) {
      throw ValidationError('$fieldName is required');
    }
    return value;
  }

  /// Validate string is not empty
  static String validateNonEmptyString(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      throw ValidationError('$fieldName cannot be empty');
    }
    return value;
  }

  /// Validate number is positive
  static num validatePositiveNumber(num? value, String fieldName) {
    if (value == null || value <= 0) {
      throw ValidationError('$fieldName must be positive');
    }
    return value;
  }

  /// Validate number is in range
  static num validateNumberRange(
    num? value,
    String fieldName, {
    required num min,
    required num max,
  }) {
    if (value == null) {
      throw ValidationError('$fieldName is required');
    }
    if (value < min || value > max) {
      throw ValidationError('$fieldName must be between $min and $max');
    }
    return value;
  }

  /// Validate ID is positive
  static int validateId(int? value, String fieldName) {
    if (value == null || value <= 0) {
      throw ValidationError('$fieldName must be a positive integer');
    }
    return value;
  }

  /// Validate date is not null and valid
  static DateTime validateDate(dynamic value, String fieldName) {
    if (value == null) {
      throw ValidationError('$fieldName is required');
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw ValidationError('$fieldName has invalid date format');
      }
    }

    throw ValidationError('$fieldName must be a valid date');
  }

  /// Validate list is not empty
  static List<T> validateNonEmptyList<T>(List<T>? value, String fieldName) {
    if (value == null || value.isEmpty) {
      throw ValidationError('$fieldName cannot be empty');
    }
    return value;
  }

  /// Validate email format
  static String validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      throw ValidationError('Email is required');
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      throw ValidationError('Invalid email format');
    }

    return value;
  }

  /// Validate phone number format
  static String validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      throw ValidationError('Phone number is required');
    }

    // Basic validation for phone numbers
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s'), ''))) {
      throw ValidationError('Invalid phone number format');
    }

    return value;
  }

  /// Validate URL format
  static String validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      throw ValidationError('URL is required');
    }

    try {
      Uri.parse(value);
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        throw ValidationError('URL must start with http:// or https://');
      }
      return value;
    } catch (e) {
      throw ValidationError('Invalid URL format');
    }
  }

  /// Validate rating is in valid range (1-5)
  static int validateRating(int? value) {
    return validateNumberRange(value, 'rating', min: 1, max: 5).toInt();
  }
}

/// Custom validation error
class ValidationError implements Exception {
  final String message;

  ValidationError(this.message);

  @override
  String toString() => 'ValidationError: $message';
}
