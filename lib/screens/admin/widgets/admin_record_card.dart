import 'package:flutter/material.dart';

import '../../../core/constants/admin_app_colors.dart';

/// Renders the reusable admin record card UI component.
class AdminRecordCard extends StatelessWidget {
  const AdminRecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon = Icons.article_outlined,
    this.trailing,
    this.meta = const [],
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Widget? trailing;
  final List<Widget> meta;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminAppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminAppColors.border),
        boxShadow: [AdminAppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminAppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(leadingIcon, color: AdminAppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminAppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminAppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: meta),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Renders the reusable admin meta pill UI component.
class AdminMetaPill extends StatelessWidget {
  const AdminMetaPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AdminAppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminAppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AdminAppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AdminAppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
