import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

/// Renders the reusable admin status chip UI component.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase().trim();
    final color = _colorForStatus(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label.isEmpty ? 'unknown' : label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorForStatus(String value) {
    if (value.contains('approved') ||
        value.contains('active') ||
        value.contains('completed') ||
        value.contains('paid') ||
        value.contains('confirmed')) {
      return AdminAppColors.success;
    }

    if (value.contains('pending') ||
        value.contains('review') ||
        value.contains('progress')) {
      return AdminAppColors.warning;
    }

    if (value.contains('reject') ||
        value.contains('cancel') ||
        value.contains('suspend') ||
        value.contains('inactive')) {
      return AdminAppColors.danger;
    }

    return AdminAppColors.info;
  }
}
