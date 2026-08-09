import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_parsers.dart';

/// Represents a inquiry message record exchanged between Firestore and the app.
class InquiryMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String text;
  final String serviceId;
  final String serviceName;
  final DateTime createdAt;

  const InquiryMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    this.serviceId = '',
    this.serviceName = '',
    required this.createdAt,
  });

  factory InquiryMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return InquiryMessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderEmail: map['senderEmail']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      serviceId: map['serviceId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  /// Converts this instance into values that can be persisted.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
