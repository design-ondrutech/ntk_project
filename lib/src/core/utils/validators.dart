class Validators {
  static final RegExp _nameRegExp = RegExp(r'^[a-zA-Z\u0B80-\u0BFF\s.]+$');

  /// Validates a name/surname string. Returns true if it contains only
  /// English letters, Tamil letters, and spaces, and is not empty.
  static bool isValidName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    return _nameRegExp.hasMatch(trimmed);
  }

  /// Validates an optional name/surname string. Returns true if it is
  /// empty, or contains only English letters, Tamil letters, and spaces.
  static bool isValidOptionalName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    return _nameRegExp.hasMatch(trimmed);
  }
}
