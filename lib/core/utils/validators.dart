String? validateNepaliPhoneNumber(String? value) {
  final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';

  if (phone.isEmpty) {
    return 'Phone number is required';
  }

  if (!RegExp(r'^\+9779[678]\d{8}$').hasMatch(phone)) {
    return 'Enter a valid Nepali number (+977 9XXXXXXXXX)';
  }

  return null;
}

String normalizeNepaliPhoneNumber(String value) {
  return value.replaceAll(RegExp(r'\s+'), '');
}
