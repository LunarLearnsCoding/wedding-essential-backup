String? validateEmailAddress(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Email is required';
  }

  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }

  return null;
}

String? validateNepaliPhoneNumber(String? value) {
  final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';

  if (phone.isEmpty) {
    return 'Phone number is required';
  }

  if (!RegExp(r'^9[678]\d{8}$').hasMatch(phone)) {
    return 'Enter a valid 10-digit Nepali mobile number';
  }

  return null;
}

String normalizeNepaliPhoneNumber(String value) {
  final phone = value.replaceAll(RegExp(r'\s+'), '');
  return phone.startsWith('+977') ? phone : '+977$phone';
}
