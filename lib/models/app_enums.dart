enum UserRole {
  customer,
  vendor,
  admin,
}

enum BookingStatus {
  pending,
  confirmed,
  rejected,
  completed,
}

enum InquiryStatus {
  pending,
  replied,
  closed,
}

String enumToString(Object value) {
  return value.toString().split('.').last;
}

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (role) => enumToString(role) == value,
    orElse: () => UserRole.customer,
  );
}

BookingStatus bookingStatusFromString(String value) {
  return BookingStatus.values.firstWhere(
    (status) => enumToString(status) == value,
    orElse: () => BookingStatus.pending,
  );
}

InquiryStatus inquiryStatusFromString(String value) {
  return InquiryStatus.values.firstWhere(
    (status) => enumToString(status) == value,
    orElse: () => InquiryStatus.pending,
  );
}