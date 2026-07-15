import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stream,
    this.subtitle,
    this.prefix = '',
    this.suffix = '',
    this.color = AdminAppColors.primary,
  });

  final String title;
  final IconData icon;
  final Stream<dynamic> stream;
  final String? subtitle;
  final String prefix;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data;
        final valueText = value == null
            ? '—'
            : value is double
            ? value.toStringAsFixed(0)
            : value.toString();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AdminAppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminAppColors.border),
            boxShadow: [AdminAppColors.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$prefix$valueText$suffix',
                style: const TextStyle(
                  color: AdminAppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: AdminAppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AdminAppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
