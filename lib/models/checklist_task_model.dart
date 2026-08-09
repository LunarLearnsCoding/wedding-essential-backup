import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

/// Represents a checklist task record exchanged between Firestore and the app.
class ChecklistTaskModel {
  final String id;
  final String customerId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  ChecklistTaskModel({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  factory ChecklistTaskModel.fromMap(String id, Map<String, dynamic> map) {
    return ChecklistTaskModel(
      id: id,
      customerId: map['customerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: boolFromFirestore(map['isCompleted']),
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
    );
  }

  /// Converts this instance into values that can be persisted.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
