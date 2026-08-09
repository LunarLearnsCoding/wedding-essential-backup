import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Groups the data and behavior required by the admin summary item component.
class AdminSummaryItem {
  const AdminSummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
}

/// Groups the data and behavior required by the admin collection item component.
class AdminCollectionItem {
  const AdminCollectionItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  factory AdminCollectionItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AdminCollectionItem(id: doc.id, data: doc.data());
  }

  String stringValue(List<String> keys, {String fallback = 'Not provided'}) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  num numberValue(List<String> keys, {num fallback = 0}) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  bool boolValue(List<String> keys, {bool fallback = false}) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return fallback;
  }

  DateTime? dateValue(List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
    }
    return null;
  }
}
