class Validators {
  static String? validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName required';
    }
    return null;
  }
}
