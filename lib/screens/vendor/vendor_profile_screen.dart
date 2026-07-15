import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import '../auth/login_screen.dart';
import 'vendor_inquiries_screen.dart';
import 'vendor_services_screen.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load profile: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final profile = _VendorProfileData.fromMap(
            data,
            fallbackEmail: currentUser.email ?? '',
          );

          return Column(
            children: [
              _ProfileHeader(profile: profile),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileInfoCard(profile: profile),

                      const SizedBox(height: 24),

                      _ProfileOptionCard(
                        icon: Icons.storefront_outlined,
                        title: 'Business Information',
                        subtitle: 'Profile updates are managed by admin review',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contact admin to update verified business details.',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.design_services_outlined,
                        title: 'My Services',
                        subtitle: 'View and update your services',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VendorServicesScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.message_outlined,
                        title: 'Inquiries',
                        subtitle: 'View customer messages',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VendorInquiriesScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Send a password reset email',
                        onTap: () => _sendPasswordReset(context, profile.email),
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out from vendor account',
                        isDanger: true,
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 5),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address found for this account.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $error')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to sign out from your vendor account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _VendorProfileData profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendor Profile',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.businessName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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

class _ProfileInfoCard extends StatelessWidget {
  final _VendorProfileData profile;

  const _ProfileInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          _ProfileDetailRow(
            icon: Icons.person_outline,
            title: 'Owner',
            value: profile.name,
          ),

          const SizedBox(height: 12),

          _ProfileDetailRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: profile.email,
          ),

          const SizedBox(height: 12),

          _ProfileDetailRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: profile.phone,
          ),

          const SizedBox(height: 12),

          _ProfileDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: profile.locationsText,
          ),
        ],
      ),
    );
  }
}

class _VendorProfileData {
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String locationsText;

  const _VendorProfileData({
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.locationsText,
  });

  factory _VendorProfileData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackEmail,
  }) {
    final name = _cleanText(map['name'], fallback: 'Vendor');
    final businessName = _cleanText(map['businessName'], fallback: name);
    final email = _cleanText(map['email'], fallback: fallbackEmail);
    final phone = _cleanText(map['phone'], fallback: 'Not provided');
    final locations = map['locations'];
    final locationsText = locations is Iterable
        ? locations.map((item) => item.toString()).join(', ')
        : _cleanText(map['location'], fallback: 'Not provided');

    return _VendorProfileData(
      name: name,
      businessName: businessName,
      email: email.isEmpty ? 'Not provided' : email,
      phone: phone,
      locationsText: locationsText.trim().isEmpty
          ? 'Not provided'
          : locationsText,
    );
  }
}

String _cleanText(dynamic value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _ProfileOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? Colors.red : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
