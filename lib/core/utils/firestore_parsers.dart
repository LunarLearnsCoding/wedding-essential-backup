import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromFirestore(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime dateTimeFromFirestoreOrNow(dynamic value) {
  return dateTimeFromFirestore(value) ?? DateTime.now();
}

double doubleFromFirestore(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
}

int intFromFirestore(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().replaceAll(',', '').trim()) ?? fallback;
}

bool boolFromFirestore(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;

  final normalized = value.toString().toLowerCase().trim();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return fallback;
}

List<String> stringListFromFirestore(dynamic value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }
  return const [];
}
