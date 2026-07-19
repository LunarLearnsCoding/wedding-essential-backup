import 'package:flutter/material.dart';

import '../../../core/widgets/app_information_sheet.dart';

class AdminHelpers {
  AdminHelpers._();

  static bool matchesSearch(Map<String, dynamic> data, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return data.values.any(
      (value) => value.toString().toLowerCase().contains(normalized),
    );
  }

  static bool matchesValues(String query, Iterable<Object?> values) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return values.any(
      (value) => value?.toString().toLowerCase().contains(normalized) ?? false,
    );
  }

  static void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool? isDestructive,
  }) async {
    final destructive =
        isDestructive ??
        const {'delete', 'remove'}.contains(confirmText.trim().toLowerCase());
    return showAppConfirmationSheet(
      context,
      title: title,
      message: message,
      confirmLabel: confirmText,
      isDestructive: destructive,
    );
  }
}
