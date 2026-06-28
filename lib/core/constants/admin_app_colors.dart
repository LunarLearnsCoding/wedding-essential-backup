import 'package:flutter/material.dart';

/// Standalone admin color tokens adapted from the Figma/shadcn export.
/// You can replace these values with your existing AppColors if needed.
class AdminAppColors {
  AdminAppColors._();

  static const Color background = Color(0xFFFAF7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4EEF7);
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF4C1D95);
  static const Color secondary = Color(0xFFF472B6);
  static const Color accent = Color(0xFFFFE4EF);
  static const Color textPrimary = Color(0xFF1F1726);
  static const Color textSecondary = Color(0xFF74677C);
  static const Color border = Color(0xFFE8DDEA);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static LinearGradient heroGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFF472B6)],
  );

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withAlpha(15),
    blurRadius: 24,
    offset: const Offset(0, 12),
  );
}
