import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

class AdminInfoCard extends StatelessWidget {
  const AdminInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminAppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminAppColors.border),
        boxShadow: [AdminAppColors.cardShadow],
      ),
      child: child,
    );
  }
}
