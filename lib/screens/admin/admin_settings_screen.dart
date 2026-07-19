import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import 'admin_login_screen.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_info_card.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminAccountCard(user: user),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: const _SettingsCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin responsibilities',
                      items: [
                        'Review vendor applications before approval.',
                        'Moderate services, reviews, and published content.',
                        'Suspend customer accounts only when necessary.',
                        'Confirm destructive actions before deleting records.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _SettingsCard(
                      icon: Icons.article_outlined,
                      title: 'Content publishing',
                      items: [
                        'Draft blogs are visible to administrators only.',
                        'Published blogs appear on customer dashboards.',
                        'Use accurate titles, categories, authors, and images.',
                        'Review article content before publishing.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _SettingsCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy and security',
                      items: [
                        'Never share admin credentials or verification links.',
                        'Customer and vendor information is confidential.',
                        'Do not export personal information without authorization.',
                        'Sign out when using a shared device.',
                      ],
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _SettingsCard(
                      icon: Icons.storage_outlined,
                      title: 'Managed data',
                      items: [
                        'Customers: users and customers',
                        'Marketplace: vendors and services',
                        'Content: reviews, blogs, and featured services',
                        'Operations remain protected by Firebase access rules.',
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AdminInfoCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End admin session',
                        style: TextStyle(
                          color: AdminAppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Securely sign out of the administration panel.',
                        style: TextStyle(color: AdminAppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminAppColors.danger,
                    side: const BorderSide(color: AdminAppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Log out of admin?',
      message: 'You will need to enter your admin credentials again.',
      confirmText: 'Log out',
    );
    if (!context.mounted || !confirmed) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }
}

class _AdminAccountCard extends StatelessWidget {
  final User? user;

  const _AdminAccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = data['name']?.toString().trim() ?? '';
        final role = data['role']?.toString().trim() ?? 'admin';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AdminAppColors.heroGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [AdminAppColors.cardShadow],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AdminAppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Administrator' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user!.email ?? 'Email unavailable',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  role.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AdminInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AdminAppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AdminAppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AdminAppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AdminAppColors.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AdminAppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}
