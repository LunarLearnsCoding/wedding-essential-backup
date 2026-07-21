import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_parsers.dart';

class InquiryMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String text;
  final DateTime createdAt;

  const InquiryMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.createdAt,
  });

  factory InquiryMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return InquiryMessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderEmail: map['senderEmail']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
