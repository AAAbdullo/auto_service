import 'package:easy_localization/easy_localization.dart';

class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'val_phone_req'.tr();
    }
    if (value.length < 9) {
      return 'val_phone_inc'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'val_pass_req'.tr();
    }
    if (value.length < 4) {
      return 'val_pass_len'.tr();
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value != password) {
      return 'val_pass_match'.tr();
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'val_email_req'.tr();
    }
    // Simple email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'val_email_inv'.tr();
    }
    return null;
  }
}
