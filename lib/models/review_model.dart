import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

class ReviewModel {
  final String id;
  final String serviceId;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String serviceName;
  final double rating;
  final String reviewText;
  final bool vendorReplied;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.serviceId,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    this.serviceName = '',
    required this.rating,
    required this.reviewText,
    this.vendorReplied = false,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      serviceId: map['serviceId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      serviceName: map['serviceName'] ?? '',
      rating: doubleFromFirestore(map['rating']),
      reviewText: map['reviewText'] ?? '',
      vendorReplied: boolFromFirestore(map['vendorReplied']),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'serviceName': serviceName,
      'rating': rating,
      'reviewText': reviewText,
      'vendorReplied': vendorReplied,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
