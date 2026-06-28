import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ServiceModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ServiceModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      averageRating:
          (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate(),
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }
}