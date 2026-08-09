import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../services/admin_service.dart';
import 'admin_blogs_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_services_screen.dart';
import 'admin_login_screen.dart';
import 'admin_customer_screen.dart';
import 'admin_featured_services_screen.dart';
import 'admin_vendor_screen.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_stat_card.dart';

/// Displays the admin dashboard page and coordinates the actions available on it.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_cleanupOrphanedChats());
  }

  Future<void> _cleanupOrphanedChats() async {
    try {
      await Future.wait([
        _adminService.cleanupOrphanedInquiries(),
        _adminService.cleanupOrphanedProfileImages(),
        _adminService.removeLegacyCustomerAddresses(),
      ]);
    } catch (error) {
      debugPrint('Could not clean up orphaned account data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminPanelPage(
        title: 'Overview',
        subtitle: 'Track customers, vendors, services, and reviews.',
        icon: Icons.dashboard_rounded,
        child: _AdminOverview(
          service: _adminService,
          onPageSelected: (index) => setState(() => _selectedIndex = index),
        ),
      ),
      AdminPanelPage(
        title: 'Customers',
        subtitle: 'Manage customer accounts and account status.',
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
        title: 'Featured',
        subtitle: 'Schedule vendors for the customer dashboard.',
        icon: Icons.star_outline_rounded,
        child: AdminFeaturedVendorsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Reviews',
        subtitle: 'Moderate ratings, reviews, and customer feedback.',
        icon: Icons.rate_review_outlined,
        child: AdminReviewsScreen(service: _adminService),
      ),
      AdminPanelPage(
        title: 'Blogs',
        subtitle: 'Publish, unpublish, and manage app content.',
        icon: Icons.article_outlined,
        child: AdminBlogsScreen(service: _adminService),
      ),
    ];

    return AdminShell(
      pages: pages,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      onLogout: _logout,
    );
  }

  Future<void> _logout() async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Log out of admin?',
      message: 'You will need to enter your admin credentials again.',
      confirmText: 'Log out',
    );
    if (!mounted || !confirmed) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }
}

/// Renders the reusable admin overview UI component.
class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.service, required this.onPageSelected});

  final AdminService service;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1050
            ? 3
            : width >= 650
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: width >= 650 ? 1.75 : 2,
          children: [
            AdminStatCard(
              title: 'Customers',
              subtitle: 'Registered customer accounts',
              icon: Icons.people_alt_outlined,
              color: AdminAppColors.primary,
              stream: service.customerCountStream(),
              onTap: () => onPageSelected(1),
            ),
            AdminStatCard(
              title: 'Approved Vendors',
              subtitle: 'Approved marketplace vendors',
              icon: Icons.verified_outlined,
              color: AdminAppColors.success,
              stream: service.approvedVendorCountStream(),
              onTap: () => onPageSelected(2),
            ),
            AdminStatCard(
              title: 'Pending Vendors',
              subtitle: 'Applications awaiting review',
              icon: Icons.pending_actions_outlined,
              color: AdminAppColors.warning,
              stream: service.pendingVendorCountStream(),
              onTap: () => onPageSelected(2),
            ),
            AdminStatCard(
              title: 'Active Services',
              subtitle: 'Services visible in the marketplace',
              icon: Icons.room_service_outlined,
              color: AdminAppColors.secondary,
              stream: service.activeServiceCountStream(),
              onTap: () => onPageSelected(3),
            ),
            AdminStatCard(
              title: 'Reviews',
              subtitle: 'Submitted customer reviews',
              icon: Icons.rate_review_outlined,
              color: AdminAppColors.primaryDark,
              stream: service.countStream('reviews'),
              onTap: () => onPageSelected(5),
            ),
            AdminStatCard(
              title: 'Published Blogs',
              subtitle: 'Articles visible to customers',
              icon: Icons.article_outlined,
              color: AdminAppColors.primary,
              stream: service.publishedBlogCountStream(),
              onTap: () => onPageSelected(6),
            ),
          ],
        );
      },
    );
  }
}
