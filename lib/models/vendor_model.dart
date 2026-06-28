import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'app_enums.dart';

class VendorModel extends UserModel {
  final String businessName;
  final String category;
  final List<String> locations;
  final String bio;
  final bool isApproved;
  final double averageRating;
  final int totalReviews;
  final Map<String, dynamic>? socialLinks;

  VendorModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.profileImageUrl,
    required super.createdAt,
    super.updatedAt,
    super.isActive,
    required this.businessName,
    required this.category,
    required this.locations,
    required this.bio,
    required this.isApproved,
    required this.averageRating,
    required this.totalReviews,
    this.socialLinks,
  });

  factory VendorModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return VendorModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: userRoleFromString(map['role'] ?? 'vendor'),
      profileImageUrl: map['profileImageUrl'],
      isActive: map['isActive'] ?? true,

      businessName: map['businessName'] ?? '',
      category: map['category'] ?? '',
      locations: List<String>.from(map['locations'] ?? []),
      bio: map['bio'] ?? '',
      isApproved: map['isApproved'] ?? false,
      averageRating:
          (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      socialLinks: map['socialLinks'],

      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'businessName': businessName,
      'category': category,
      'locations': locations,
      'bio': bio,
      'isApproved': isApproved,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'socialLinks': socialLinks,
    };
  }
}