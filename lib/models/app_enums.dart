enum UserRole { customer, vendor, admin }

enum BookingStatus { pending, confirmed, rejected, completed }

enum InquiryStatus { pending, replied, closed }

String enumToString(Object value) {
  return value.toString().split('.').last;
}

UserRole userRoleFromString(String value) {
  final normalized = value.toLowerCase().trim();
  return UserRole.values.firstWhere(
    (role) => enumToString(role) == normalized,
    orElse: () => UserRole.customer,
  );
}

BookingStatus bookingStatusFromString(String value) {
  final normalized = value.toLowerCase().trim();
  if (normalized == 'cancelled' || normalized == 'canceled') {
    return BookingStatus.rejected;
  }

  return BookingStatus.values.firstWhere(
    (status) => enumToString(status) == normalized,
    orElse: () => BookingStatus.pending,
  );
}

InquiryStatus inquiryStatusFromString(String value) {
  final normalized = value.toLowerCase().trim();
  if (normalized == 'new') {
    return InquiryStatus.pending;
  }

  return InquiryStatus.values.firstWhere(
    (status) => enumToString(status) == normalized,
    orElse: () => InquiryStatus.pending,
  );
}
