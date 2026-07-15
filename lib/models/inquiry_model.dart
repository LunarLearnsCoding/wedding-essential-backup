import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

class InquiryModel {
  final String id;
  final String customerId;
  final String customerName;
  final String vendorId;
  final String serviceId;
  final String serviceName;
  final String message;
  final InquiryStatus status;
  final DateTime createdAt;

  InquiryModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.serviceId,
    required this.serviceName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory InquiryModel.fromMap(String id, Map<String, dynamic> map) {
    return InquiryModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      vendorId: map['vendorId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      message: map['message'] ?? '',
      status: inquiryStatusFromString(map['status'] ?? 'pending'),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'vendorId': vendorId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'message': message,
      'status': enumToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
