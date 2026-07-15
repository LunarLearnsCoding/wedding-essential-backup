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
  final bool isApproved;
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
    required this.isApproved,
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
      isApproved: boolFromFirestore(map['isApproved']),
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
      'isApproved': isApproved,
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
    bool? isApproved,
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
      isApproved: isApproved ?? this.isApproved,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}
