import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';
import 'vendor_dashboard_screen.dart';

/// Displays the vendor pending page and coordinates the actions available on it.
class VendorPendingScreen extends StatefulWidget {
  const VendorPendingScreen({super.key});

  @override
  State<VendorPendingScreen> createState() => _VendorPendingScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorPendingScreenState extends State<VendorPendingScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isChecking = false;
  String status = 'pending';
  String rejectionReason = '';

  @override
  void initState() {
    super.initState();
    _loadVendorStatus();
  }

  /// Loads vendor status and updates the visible state.
  Future<void> _loadVendorStatus() async {
    final user = auth.currentUser;

    if (user == null) return;

    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final vendorDoc = await firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final userData = userDoc.data() ?? {};
      final vendorData = vendorDoc.data() ?? {};

      setState(() {
        status =
            vendorData['approvalStatus']?.toString().toLowerCase() ??
            userData['status']?.toString().toLowerCase() ??
            'pending';
        rejectionReason =
            vendorData['rejectionReason']?.toString() ??
            userData['rejectionReason']?.toString() ??
            '';
      });
    } catch (_) {}
  }

  Future<void> _checkStatus() async {
    final user = auth.currentUser;

    if (user == null) {
      _goToLogin();
      return;
    }

    setState(() {
      isChecking = true;
    });

    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final vendorDoc = await firestore
          .collection('vendors')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final vendorData = vendorDoc.data() ?? {};

      final latestStatus =
          vendorData['approvalStatus']?.toString().toLowerCase() ??
          userData['status']?.toString().toLowerCase() ??
          'pending';
      final isApproved = vendorData['isApproved'] == true;

      if (!mounted) return;

      setState(() {
        status = latestStatus;
        rejectionReason =
            vendorData['rejectionReason']?.toString() ??
            userData['rejectionReason']?.toString() ??
            '';
        isChecking = false;
      });

      if (isApproved ||
          latestStatus == 'active' ||
          latestStatus == 'approved') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
        );
        return;
      }

      if (latestStatus == 'rejected') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your vendor account was rejected.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is still waiting for admin approval.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isChecking = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to check status: $error')));
    }
  }

  Future<void> _signOut() async {
    await auth.signOut();

    if (!mounted) return;

    _goToLogin();
  }

  /// Navigates to the destination associated with this action.
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                ),
              ),

              const Spacer(),

              Container(
                height: 112,
                width: 112,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red.shade50
                      : AppColors.selectedSurface,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 56,
                  color: isRejected ? Colors.red : AppColors.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                isRejected ? 'Vendor Account Rejected' : 'Approval Pending',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                isRejected
                    ? 'Your vendor account was not approved by the admin.'
                    : 'Your vendor account has been created successfully. Please wait until the admin reviews and approves your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              if (isRejected && rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rejectionReason,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      title: 'Admin Review',
                      subtitle: 'Your account is checked by the admin.',
                    ),
                    SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.storefront_outlined,
                      title: 'Vendor Dashboard',
                      subtitle: 'You can access it after approval.',
                    ),
                    SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.notifications_none_outlined,
                      title: 'Check Again',
                      subtitle: 'Tap the button below to refresh status.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isChecking ? null : _checkStatus,
                  icon: isChecking
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    isChecking ? 'Checking...' : 'Check Approval Status',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the reusable info row UI component.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.selectedSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
