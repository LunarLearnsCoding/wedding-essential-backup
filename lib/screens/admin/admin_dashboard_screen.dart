import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../services/admin_service.dart';
import 'admin_blogs_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_inquiries_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_services_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'admin_vendors_screen.dart';
import 'widgets/admin_info_card.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminPanelPage(
        title: 'Overview',
        subtitle: 'Track users, vendors, services, bookings, and revenue.',
        icon: Icons.dashboard_rounded,
        child: _AdminOverview(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Users',
        subtitle: 'Manage customers, admins, and account status.',
        icon: Icons.people_alt_outlined,
        child: AdminUsersScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Vendors',
        subtitle: 'Review vendor registrations and approvals.',
        icon: Icons.storefront_outlined,
        child: AdminVendorsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Services',
        subtitle: 'Moderate wedding services listed by vendors.',
        icon: Icons.room_service_outlined,
        child: AdminServicesScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Bookings',
        subtitle: 'Monitor booking requests and booking progress.',
        icon: Icons.calendar_month_outlined,
        child: AdminBookingsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Inquiries',
        subtitle: 'Track customer inquiries and vendor responses.',
        icon: Icons.mark_email_unread_outlined,
        child: AdminInquiriesScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Reviews',
        subtitle: 'Moderate ratings, reviews, and customer feedback.',
        icon: Icons.star_border_rounded,
        child: AdminReviewsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Blogs',
        subtitle: 'Publish, unpublish, and manage app content.',
        icon: Icons.article_outlined,
        child: AdminBlogsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Settings',
        subtitle: 'Admin setup notes and Firestore collection mapping.',
        icon: Icons.settings_outlined,
        child: const AdminSettingsScreen(),
      ),
    ];

    return AdminShell(
      pages: pages,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.service});

  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AdminAppColors.heroGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [AdminAppColors.cardShadow],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your wedding marketplace control center is ready.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100
                  ? 4
                  : width >= 760
                      ? 3
                      : width >= 520
                          ? 2
                          : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: width >= 760 ? 1.45 : 1.75,
                children: [
                  AdminStatCard(
                    title: 'Total Users',
                    subtitle: 'Customers + admins',
                    icon: Icons.people_alt_outlined,
                    color: AdminAppColors.primary,
                    stream: service.countStream('users'),
                  ),
                  AdminStatCard(
                    title: 'Approved Vendors',
                    subtitle: 'Verified vendor accounts',
                    icon: Icons.verified_outlined,
                    color: AdminAppColors.success,
                    stream: service.countStream(
                      'vendors',
                      field: 'status',
                      isEqualTo: 'approved',
                    ),
                  ),
                  AdminStatCard(
                    title: 'Pending Vendors',
                    subtitle: 'Need review',
                    icon: Icons.pending_actions_outlined,
                    color: AdminAppColors.warning,
                    stream: service.countStream(
                      'vendors',
                      field: 'status',
                      isEqualTo: 'pending',
                    ),
                  ),
                  AdminStatCard(
                    title: 'Services',
                    subtitle: 'Marketplace listings',
                    icon: Icons.room_service_outlined,
                    color: AdminAppColors.secondary,
                    stream: service.countStream('services'),
                  ),
                  AdminStatCard(
                    title: 'Bookings',
                    subtitle: 'All booking requests',
                    icon: Icons.calendar_month_outlined,
                    color: AdminAppColors.info,
                    stream: service.countStream('bookings'),
                  ),
                  AdminStatCard(
                    title: 'Pending Inquiries',
                    subtitle: 'Customer messages',
                    icon: Icons.mark_email_unread_outlined,
                    color: AdminAppColors.warning,
                    stream: service.countStream(
                      'inquiries',
                      field: 'status',
                      isEqualTo: 'pending',
                    ),
                  ),
                  AdminStatCard(
                    title: 'Reviews',
                    subtitle: 'Customer feedback',
                    icon: Icons.star_border_rounded,
                    color: AdminAppColors.primaryDark,
                    stream: service.countStream('reviews'),
                  ),
                  AdminStatCard(
                    title: 'Revenue',
                    subtitle: 'Completed bookings',
                    icon: Icons.payments_outlined,
                    color: AdminAppColors.success,
                    prefix: 'Rs. ',
                    stream: service.revenueStream(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 900;
              final children = [
                _QuickActions(service: service),
                const _AdminTips(),
              ];

              if (!twoColumns) {
                return Column(
                  children: [
                    children[0],
                    const SizedBox(height: 14),
                    children[1],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 14),
                  Expanded(child: children[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.service});

  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return AdminInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick admin actions',
            style: TextStyle(
              color: AdminAppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _ActionRow(
            icon: Icons.verified_user_outlined,
            title: 'Review vendors',
            subtitle: 'Approve or reject new vendor applications.',
          ),
          const Divider(height: 24),
          _ActionRow(
            icon: Icons.room_service_outlined,
            title: 'Moderate services',
            subtitle: 'Hide incorrect or inactive service listings.',
          ),
          const Divider(height: 24),
          _ActionRow(
            icon: Icons.rate_review_outlined,
            title: 'Check reviews',
            subtitle: 'Remove abusive or fake customer reviews.',
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AdminAppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AdminAppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminAppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminAppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminTips extends StatelessWidget {
  const _AdminTips();

  @override
  Widget build(BuildContext context) {
    return const AdminInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Firestore collections used',
            style: TextStyle(
              color: AdminAppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'users, vendors, services, bookings, inquiries, reviews, blogs',
            style: TextStyle(
              color: AdminAppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Keep the field names status, createdAt, isApproved, isActive, totalAmount, role, name, email and title consistent for best results.',
            style: TextStyle(
              color: AdminAppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
