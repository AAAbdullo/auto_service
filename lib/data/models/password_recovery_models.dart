// Models for password recovery flow

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordResponse {
  final String message;
  final String maskedEmail;

  ForgotPasswordResponse({required this.message, required this.maskedEmail});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'] ?? '',
      maskedEmail: json['email'] ?? '',
    );
  }
}

class VerifyOTPRequest {
  final String email;
  final String otp;

  VerifyOTPRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class VerifyOTPResponse {
  final String message;
  final bool valid;

  VerifyOTPResponse({required this.message, required this.valid});

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      message: json['message'] ?? '',
      valid: json['valid'] ?? false,
    );
  }
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}

class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(message: json['message'] ?? '');
  }
}
