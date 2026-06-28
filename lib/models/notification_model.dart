import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  booking,
  inquiry,
 guest,
  checklist,
  payment,
}

class NotificationModel {
  final String id;
  final String title;

  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
  });

  factory NotificationModel.fromMap(
      String id,
      Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today_outlined;

      case NotificationType.inquiry:
        return Icons.notifications_active_outlined;

      case NotificationType.guest:
        return Icons.people_outline;

      case NotificationType.checklist:
        return Icons.check_box_outlined;

      case NotificationType.payment:
        return Icons.payments_outlined;
    }
  }

  Color get iconBackground {
    switch (type) {
      case NotificationType.booking:
        return const Color(0xffE8F5E9);

      case NotificationType.inquiry:
        return const Color(0xffFFF3E0);

      case NotificationType.guest:
        return const Color(0xffF3E8FF);

      case NotificationType.checklist:
        return const Color(0xffE3F2FD);

      case NotificationType.payment:
        return const Color(0xffE8F5E9);
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.booking:
        return Colors.green;

      case NotificationType.inquiry:
        return Colors.orange;

      case NotificationType.guest:
        return Colors.deepPurple;

      case NotificationType.checklist:
        return Colors.blue;

      case NotificationType.payment:
        return Colors.green;
    }
  }
}