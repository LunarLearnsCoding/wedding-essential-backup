import 'package:cloud_firestore/cloud_firestore.dart';

class GuestModel {
  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String relation;
  final int numberOfGuests;
  final bool isInvited;
  final bool isAttending;
  final DateTime createdAt;

  GuestModel({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.relation,
    required this.numberOfGuests,
    required this.isInvited,
    required this.isAttending,
    required this.createdAt,
  });

  factory GuestModel.fromMap(String id, Map<String, dynamic> map) {
    return GuestModel(
      id: id,
      customerId: map['customerId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
      numberOfGuests: map['numberOfGuests'] ?? 1,
      isInvited: map['isInvited'] ?? false,
      isAttending: map['isAttending'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'name': name,
      'phone': phone,
      'relation': relation,
      'numberOfGuests': numberOfGuests,
      'isInvited': isInvited,
      'isAttending': isAttending,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}