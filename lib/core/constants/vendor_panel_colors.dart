// Vendor panel colors and text styles.
// Placed in core/constants to match the Wedding Essentials repo structure.

import 'package:flutter/material.dart';

class VendorColors {
  static const Color background = Color(0xFFFAF6F2);
  static const Color primary = Color(0xFFB87080);
  static const Color primaryLight = Color(0xFFC08090);
  static const Color primaryDark = Color(0xFF805060);
  static const Color text = Color(0xFF2C1B1B);
  static const Color muted = Color(0xFF9B7070);
  static const Color mutedLight = Color(0xFFC4B0B0);
  static const Color border = Color(0x22B87080);
  static const Color card = Colors.white;
  static const Color blush = Color(0xFFF5E8EB);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color gold = Color(0xFFC8A665);
  static const Color green = Color(0xFF508050);
  static const Color blue = Color(0xFF7080B8);
  static const Color danger = Color(0xFFD4183D);
}

class VendorGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [VendorColors.primaryLight, VendorColors.primaryDark],
  );

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA06880), VendorColors.primaryDark],
  );
}

class VendorTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: VendorColors.text,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: VendorColors.text,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: VendorColors.muted,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: VendorColors.muted,
    height: 1.35,
  );
}

BoxDecoration vendorCardDecoration({double radius = 18}) {
  return BoxDecoration(
    color: VendorColors.card,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 4)),
    ],
  );
}
