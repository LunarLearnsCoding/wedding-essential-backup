import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

class InquiryModel {
  final String id;
  final String customerId;
  final String customerName;
  final String vendorId;
  final String vendorName;
  final String serviceId;
  final String serviceName;
  final String message;
  final String vendorReply;
  final InquiryStatus status;
  final DateTime createdAt;
  final DateTime? vendorReplyAt;
  final DateTime? updatedAt;

  InquiryModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    this.vendorName = '',
    required this.serviceId,
    required this.serviceName,
    required this.message,
    this.vendorReply = '',
    required this.status,
    required this.createdAt,
    this.vendorReplyAt,
    this.updatedAt,
  });

  factory InquiryModel.fromMap(String id, Map<String, dynamic> map) {
    return InquiryModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      message: map['message'] ?? '',
      vendorReply: (map['vendorReply'] ?? '').toString(),
      status: inquiryStatusFromString(map['status'] ?? 'pending'),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      vendorReplyAt: dateTimeFromFirestore(map['vendorReplyAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'message': message,
      'vendorReply': vendorReply,
      'status': enumToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'vendorReplyAt': vendorReplyAt == null
          ? null
          : Timestamp.fromDate(vendorReplyAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
