import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'app_enums.dart';

class CustomerModel extends UserModel {
  final String? address;
  final DateTime? weddingDate;

  CustomerModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.profileImageUrl,
    required super.createdAt,
    super.updatedAt,
    super.isActive,
    this.address,
    this.weddingDate,
  });

  factory CustomerModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: userRoleFromString(map['role'] ?? 'customer'),
      profileImageUrl: map['profileImageUrl'],
      isActive: map['isActive'] ?? true,
      address: map['address'],
      weddingDate: (map['weddingDate'] as Timestamp?)?.toDate(),
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
      'address': address,
      'weddingDate': weddingDate == null
          ? null
          : Timestamp.fromDate(weddingDate!),
    };
  }
}