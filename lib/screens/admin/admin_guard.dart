import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../core/constants/admin_account.dart';
import '../../services/admin_auth_service.dart';
import 'package:wedding_essentialsapp/screens/admin/admin_login_screen.dart';
import 'package:wedding_essentialsapp/screens/admin/admin_dashboard_screen.dart';

class AdminGuard extends StatefulWidget {
  const AdminGuard({super.key});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  Future<Map<String, dynamic>?>? _recovery;

  Future<Map<String, dynamic>?> _recoverAdminProfile(User user) {
    return _recovery ??= AdminAuthService().ensureAdminProfile(user);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return AdminLoginScreen();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AdminAppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        if (data == null &&
            user.email?.trim().toLowerCase() == adminAccountEmail) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _recoverAdminProfile(user),
            builder: (context, recoverySnapshot) {
              if (recoverySnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  backgroundColor: AdminAppColors.background,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (recoverySnapshot.hasError) {
                return _AdminAccessMessage(
                  icon: Icons.error_outline,
                  title: 'Admin profile recovery failed',
                  message: recoverySnapshot.error.toString(),
                );
              }
              return const Scaffold(
                backgroundColor: AdminAppColors.background,
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }
        final role = (data?['role'] ?? '').toString().toLowerCase();
        final isAdmin =
            role == 'admin' &&
            user.email?.trim().toLowerCase() == adminAccountEmail;

        if (!isAdmin) {
          return const _AdminAccessMessage(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Access denied',
            message: 'This page is only available to admin users.',
          );
        }

        return AdminDashboardScreen();
      },
    );
  }
}

class _AdminAccessMessage extends StatelessWidget {
  const _AdminAccessMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminAppColors.background,
      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AdminAppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AdminAppColors.border),
            boxShadow: [AdminAppColors.cardShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AdminAppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(icon, color: AdminAppColors.primary, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AdminAppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminAppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
