import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistTaskModel {
  final String id;
  final String customerId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;

  ChecklistTaskModel({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.dueDate,
    required this.createdAt,
  });

  factory ChecklistTaskModel.fromMap(String id, Map<String, dynamic> map) {
    return ChecklistTaskModel(
      id: id,
      customerId: map['customerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}