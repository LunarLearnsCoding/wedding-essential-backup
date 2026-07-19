import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String serviceId;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String serviceName;
  final double rating;
  final String reviewText;
  final bool vendorReplied;
  final String status;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    this.bookingId = '',
    required this.serviceId,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    this.serviceName = '',
    required this.rating,
    required this.reviewText,
    this.vendorReplied = false,
    this.status = 'published',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      serviceName: map['serviceName'] ?? '',
      rating: doubleFromFirestore(map['rating']),
      reviewText: map['reviewText'] ?? '',
      vendorReplied: boolFromFirestore(map['vendorReplied']),
      status: map['status']?.toString() ?? 'published',
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'serviceId': serviceId,
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'serviceName': serviceName,
      'rating': rating,
      'reviewText': reviewText,
      'vendorReplied': vendorReplied,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isVisible => status.toLowerCase().trim() != 'hidden';
}
