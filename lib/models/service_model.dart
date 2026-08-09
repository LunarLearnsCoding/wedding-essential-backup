import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

/// Represents a service record exchanged between Firestore and the app.
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
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    final parsedImageUrls = stringListFromFirestore(map['imageUrls']);
    final legacyImageUrl = map['imageUrl']?.toString().trim() ?? '';
    return ServiceModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      price: doubleFromFirestore(map['price']),
      imageUrls: parsedImageUrls.isNotEmpty
          ? parsedImageUrls
          : legacyImageUrl.isEmpty
          ? const []
          : [legacyImageUrl],
      isActive: boolFromFirestore(map['isActive'], fallback: true),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  /// Converts this instance into values that can be persisted.
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
      'isActive': isActive,
      'status': isActive ? 'active' : 'inactive',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }
}
