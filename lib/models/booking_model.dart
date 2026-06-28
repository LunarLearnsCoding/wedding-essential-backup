import 'package:cloud_firestore/cloud_firestore.dart';
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
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
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
      servicePrice: (map['servicePrice'] ?? 0).toDouble(),
      eventDate:
          (map['eventDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      status: bookingStatusFromString(
        map['status'] ?? 'pending',
      ),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate(),
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
      'status': enumToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }
}