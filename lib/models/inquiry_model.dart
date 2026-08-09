import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

/// Represents a inquiry record exchanged between Firestore and the app.
class InquiryModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
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
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? closedAt;
  final bool isRealtimeChat;
  final bool unreadForCustomer;
  final bool unreadForVendor;

  InquiryModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerEmail = '',
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
    this.lastMessage = '',
    this.lastMessageAt,
    this.closedAt,
    this.isRealtimeChat = false,
    this.unreadForCustomer = false,
    this.unreadForVendor = false,
  });

  factory InquiryModel.fromMap(String id, Map<String, dynamic> map) {
    return InquiryModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
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
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: dateTimeFromFirestore(map['lastMessageAt']),
      closedAt: dateTimeFromFirestore(map['closedAt']),
      isRealtimeChat: map['isRealtimeChat'] == true,
      unreadForCustomer: map['unreadForCustomer'] == true,
      unreadForVendor: map['unreadForVendor'] == true,
    );
  }

  /// Converts this instance into values that can be persisted.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
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
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt == null
          ? null
          : Timestamp.fromDate(lastMessageAt!),
      'closedAt': closedAt == null ? null : Timestamp.fromDate(closedAt!),
      'isRealtimeChat': isRealtimeChat,
      'unreadForCustomer': unreadForCustomer,
      'unreadForVendor': unreadForVendor,
    };
  }
}
