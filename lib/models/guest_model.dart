import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

/// Represents a guest record exchanged between Firestore and the app.
class GuestModel {
  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String relation;
  final int numberOfGuests;
  final DateTime createdAt;

  GuestModel({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.relation,
    required this.numberOfGuests,
    required this.createdAt,
  });

  factory GuestModel.fromMap(String id, Map<String, dynamic> map) {
    return GuestModel(
      id: id,
      customerId: map['customerId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
      numberOfGuests: intFromFirestore(map['numberOfGuests'], fallback: 1),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  /// Converts this instance into values that can be persisted.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'name': name,
      'phone': phone,
      'relation': relation,
      'numberOfGuests': numberOfGuests,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
