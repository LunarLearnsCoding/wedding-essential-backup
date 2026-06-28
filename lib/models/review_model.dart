import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String serviceId;
  final String vendorId;
  final String customerId;
  final String customerName;
  final double rating;
  final String reviewText;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.serviceId,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      serviceId: map['serviceId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}