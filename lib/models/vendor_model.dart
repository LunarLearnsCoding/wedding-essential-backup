import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

/// Represents a vendor record exchanged between Firestore and the app.
class VendorModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String businessName;
  final String category;
  final String location;
  final String bio;
  final String? profileImageUrl;
  final String facebookUrl;
  final String instagramUrl;
  final String tiktokUrl;
  final String websiteUrl;
  final bool isApproved;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final String approvalStatus; // New field for approval status

  VendorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.businessName,
    required this.category,
    required this.location,
    required this.bio,
    this.profileImageUrl,
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.tiktokUrl = '',
    this.websiteUrl = '',
    required this.isApproved,
    this.isFeatured = false,
    this.featuredUntil,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
    required this.approvalStatus,
  });

  factory VendorModel.fromMap(String id, Map<String, dynamic> map) {
    return VendorModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: userRoleFromString(map['role'] ?? 'vendor'),
      businessName: map['businessName'] ?? '',
      category: map['category'] ?? '',
      location: _vendorLocationFromMap(map),
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl']?.toString(),
      facebookUrl: map['facebookUrl']?.toString() ?? '',
      instagramUrl: map['instagramUrl']?.toString() ?? '',
      tiktokUrl: map['tiktokUrl']?.toString() ?? '',
      websiteUrl: map['websiteUrl']?.toString() ?? '',
      isApproved: boolFromFirestore(map['isApproved']),
      isFeatured: boolFromFirestore(map['isFeatured']),
      featuredUntil: dateTimeFromFirestore(map['featuredUntil']),
      averageRating: doubleFromFirestore(map['averageRating']),
      totalReviews: intFromFirestore(map['totalReviews']),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      approvalStatus: map['approvalStatus'] ?? 'pending',
    );
  }

  /// Converts this instance into values that can be persisted.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': enumToString(role),
      'businessName': businessName,
      'category': category,
      'location': location,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'websiteUrl': websiteUrl,
      'isApproved': isApproved,
      'isFeatured': isFeatured,
      'featuredUntil': featuredUntil == null
          ? null
          : Timestamp.fromDate(featuredUntil!),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvalStatus': approvalStatus,
    };
  }

  VendorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? businessName,
    String? category,
    String? location,
    String? bio,
    String? profileImageUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? tiktokUrl,
    String? websiteUrl,
    bool? isApproved,
    bool? isFeatured,
    DateTime? featuredUntil,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    String? approvalStatus,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isApproved: isApproved ?? this.isApproved,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}

String _vendorLocationFromMap(Map<String, dynamic> map) {
  final location = map['location']?.toString().trim() ?? '';
  if (location.isNotEmpty) return location;
  return stringListFromFirestore(map['locations']).firstOrNull ?? '';
}
