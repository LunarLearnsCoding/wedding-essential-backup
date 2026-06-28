import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import 'widgets/admin_info_card.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SettingsCard(
            icon: Icons.collections_bookmark_outlined,
            title: 'Firestore collections expected',
            body:
                'users, vendors, services, bookings, inquiries, reviews, blogs. If your project uses slightly different names, update lib/services/admin_service.dart and the screen field mappings.',
          ),
          SizedBox(height: 14),
          _SettingsCard(
            icon: Icons.security_outlined,
            title: 'Admin access rule',
            body:
                'AdminGuard checks users/{uid}.role and allows role = admin or super_admin. Set that field manually in Firestore for your admin account.',
          ),
          SizedBox(height: 14),
          _SettingsCard(
            icon: Icons.design_services_outlined,
            title: 'Design system',
            body:
                'Colors and spacing are isolated in admin_app_colors.dart so this panel does not break the rest of your Wedding App theme.',
          ),
          SizedBox(height: 14),
          _SettingsCard(
            icon: Icons.warning_amber_outlined,
            title: 'Before production',
            body:
                'Add strict Firestore security rules so only admin users can read/write admin-level collections and update vendor/user status.',
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AdminInfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminAppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AdminAppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminAppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: AdminAppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
