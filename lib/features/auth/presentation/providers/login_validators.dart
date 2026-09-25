class LoginValidators {
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Enter a valid name';
    return null;
  }

  static String? postalCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Postal code is required';
    if (v.length < 4) return 'Enter a valid postal code';
    return null;
  }
}
