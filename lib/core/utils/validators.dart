class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon raqamni kiriting';
    }
    if (value.length < 9) {
      return "Telefon raqam to'liq emas";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parolni kiriting';
    }
    if (value.length < 4) {
      return 'Parol kamida 6 belgidan iborat bo\'lishi kerak';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value != password) {
      return 'Parollar mos emas';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email kiriting';
    }
    // Simple email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Noto\'g\'ri email format';
    }
    return null;
  }
}
