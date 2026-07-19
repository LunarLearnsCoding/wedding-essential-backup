import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_parsers.dart';
import 'app_enums.dart';

class VendorModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String businessName;
  final String category;
  final List<String> locations;
  final String bio;
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
    required this.locations,
    required this.bio,
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
      locations: stringListFromFirestore(map['locations']),
      bio: map['bio'] ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': enumToString(role),
      'businessName': businessName,
      'category': category,
      'locations': locations,
      'bio': bio,
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
    List<String>? locations,
    String? bio,
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
      locations: locations ?? this.locations,
      bio: bio ?? this.bio,
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
