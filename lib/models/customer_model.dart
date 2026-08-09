import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';
import 'user_model.dart';
import 'app_enums.dart';

/// Represents a customer record exchanged between Firestore and the app.
class CustomerModel extends UserModel {
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
    this.weddingDate,
  });

  factory CustomerModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: userRoleFromString(map['role'] ?? 'customer'),
      profileImageUrl: map['profileImageUrl'],
      isActive: boolFromFirestore(map['isActive'], fallback: true),
      weddingDate: dateTimeFromFirestore(map['weddingDate']),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'weddingDate': weddingDate == null
          ? null
          : Timestamp.fromDate(weddingDate!),
    };
  }
}
