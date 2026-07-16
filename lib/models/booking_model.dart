import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

class BookingModel {
  final String id;

  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  final String vendorId;
  final String vendorName;

  final String serviceId;
  final String serviceName;
  final double servicePrice;

  final DateTime eventDate;
  final DateTime eventTime;
  final String note;

  final BookingStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.vendorId,
    required this.vendorName,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.eventDate,
    DateTime? eventTime,
    this.note = '',
    required this.status,
    required this.createdAt,
    this.updatedAt,
  }) : eventTime = eventTime ?? eventDate;

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: doubleFromFirestore(map['servicePrice'] ?? map['price']),
      eventDate: dateTimeFromFirestoreOrNow(
        map['eventDate'] ?? map['requestedDateTime'],
      ),
      eventTime: dateTimeFromFirestore(
        map['eventTime'] ?? map['requestedDateTime'] ?? map['eventDate'],
      ),
      note: (map['note'] ?? map['notes'] ?? '').toString(),
      status: bookingStatusFromString(map['status'] ?? 'pending'),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventTime': Timestamp.fromDate(eventTime),
      'note': note,
      'status': enumToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
