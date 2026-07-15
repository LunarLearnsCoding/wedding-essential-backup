import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

class ServiceModel {
  final String id;
  final String vendorId;
  final String vendorName;

  final String name;
  final String description;
  final String category;
  final String location;

  final double price;

  final List<String> imageUrls;

  final double averageRating;
  final int totalReviews;

  final bool isActive;

  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.price,
    required this.imageUrls,
    required this.averageRating,
    required this.totalReviews,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      price: doubleFromFirestore(map['price']),
      imageUrls: stringListFromFirestore(map['imageUrls']),
      averageRating: doubleFromFirestore(map['averageRating']),
      totalReviews: intFromFirestore(map['totalReviews']),
      isActive: boolFromFirestore(map['isActive'], fallback: true),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'name': name,
      'description': description,
      'category': category,
      'location': location,
      'price': price,
      'imageUrls': imageUrls,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isActive': isActive,
      'status': isActive ? 'active' : 'inactive',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
