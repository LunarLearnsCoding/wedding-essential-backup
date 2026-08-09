/// Lists the supported user role values used throughout the app.
enum UserRole { customer, vendor, admin }

/// Lists the supported booking status values used throughout the app.
enum BookingStatus { pending, confirmed, rejected, completed, cancelled }

/// Lists the supported inquiry status values used throughout the app.
enum InquiryStatus { pending, replied, closed, cancelled }

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
    return BookingStatus.cancelled;
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
  if (normalized == 'cancelled' || normalized == 'canceled') {
    return InquiryStatus.cancelled;
  }

  return InquiryStatus.values.firstWhere(
    (status) => enumToString(status) == normalized,
    orElse: () => InquiryStatus.pending,
  );
}
