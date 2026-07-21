import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_parsers.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_information_sheet.dart';
import '../../core/widgets/support_contact_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'browse_services_screen.dart';
import 'checklist_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_dashboard_screen.dart';
import 'guest_list_screen.dart';
import 'notification_screen.dart';
import 'wishlist_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Future<_CustomerProfileData>? _profileFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileFuture = _loadProfile(currentUser.uid);
    }
  }

  Future<_CustomerProfileData> _loadProfile(String customerId) async {
    final firestore = FirebaseFirestore.instance;

    final customerDoc = await firestore
        .collection(FirestoreCollections.customers)
        .doc(customerId)
        .get();

    final profileData = customerDoc.exists
        ? customerDoc.data() ?? {}
        : (await firestore
                      .collection(FirestoreCollections.users)
                      .doc(customerId)
                      .get())
                  .data() ??
              {};

    final counts = await _loadProfileCounts(customerId);

    return _CustomerProfileData.fromMap(
      profileData,
      fallbackEmail: FirebaseAuth.instance.currentUser?.email ?? '',
      stats: counts,
    );
  }

  Future<_CustomerProfileStats> _loadProfileCounts(String customerId) async {
    final checklistCounts = await _loadChecklistCounts(customerId);

    return _CustomerProfileStats(
      bookings: await _loadBookingCount(customerId),
      guests: await _loadGuestCount(customerId),
      completedTasks: checklistCounts.completed,
      totalTasks: checklistCounts.total,
    );
  }

  Future<int> _loadBookingCount(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.bookings)
          .where('customerId', isEqualTo: customerId)
          .get();

      return snapshot.docs.length;
    } on FirebaseException {
      return 0;
    }
  }

  Future<int> _loadGuestCount(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.guests)
          .where('customerId', isEqualTo: customerId)
          .get();

      return snapshot.docs.fold<int>(
        0,
        (total, doc) =>
            total + intFromFirestore(doc.data()['numberOfGuests'], fallback: 1),
      );
    } on FirebaseException {
      return 0;
    }
  }

  Future<_ChecklistCounts> _loadChecklistCounts(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.checklistTasks)
          .where('customerId', isEqualTo: customerId)
          .get();
      final completed = snapshot.docs
          .where((doc) => boolFromFirestore(doc.data()['isCompleted']))
          .length;

      return _ChecklistCounts(
        completed: completed,
        total: snapshot.docs.length,
      );
    } on FirebaseException {
      return const _ChecklistCounts(completed: 0, total: 0);
    }
  }

  void _refreshProfile(String customerId) {
    setState(() {
      _profileFuture = _loadProfile(customerId);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showAppConfirmationSheet(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to sign out of your customer account?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;

    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    _CustomerProfileData profile,
    String customerId,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );

    if (!context.mounted || saved != true) return;

    _refreshProfile(customerId);
  }

  Future<void> _confirmPasswordReset(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email address found.')));
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primaryDark,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change your password',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We’ll email you a secure link to choose a new password.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Send reset link',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || confirmed != true) return;

    try {
      await context.read<AuthProvider>().authService.resetPassword(email);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      final message = switch (error.code) {
        'too-many-requests' =>
          'Too many reset attempts. Please wait and try again.',
        'network-request-failed' =>
          'Could not connect. Check your internet connection and try again.',
        _ => 'Could not send the reset email. Please try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_CustomerProfileData>(
          future: _profileFuture ??= _loadProfile(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load profile: ${snapshot.error}'),
                ),
              );
            }

            final profile = snapshot.data ?? _CustomerProfileData.empty();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileHeaderCard(
                    profile: profile,
                    onEdit: () {
                      _openEditProfile(context, profile, currentUser.uid);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: profile.stats.bookings.toString(),
                          label: 'Bookings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerBookingsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: profile.stats.guests.toString(),
                          label: 'Guests',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GuestListScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value:
                              '${profile.stats.completedTasks}/${profile.stats.totalTasks}',
                          label: 'Tasks Done',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChecklistScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Account'),
                  const SizedBox(height: 12),
                  _ProfileMenuCard(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: 'Favorites',
                        subtitle: 'View your saved services',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WishlistScreen(),
                            ),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Privacy & Security',
                        subtitle: 'Send a password reset email',
                        onTap: () {
                          _confirmPasswordReset(context);
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        isDanger: true,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SupportContactCard(),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerDashboardScreen(),
              ),
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BrowseServicesScreen()),
            );
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }
        },
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final _CustomerProfileData profile;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone.isEmpty ? 'Phone not provided' : profile.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final _CustomerProfileData profile;

  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    _phoneController.text = widget.profile.phone;
    _addressController.text = widget.profile.address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sharedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final customerData = {
        ...sharedData,
        'address': _addressController.text.trim(),
      };
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.set(
        firestore
            .collection(FirestoreCollections.customers)
            .doc(currentUser.uid),
        customerData,
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection(FirestoreCollections.users).doc(currentUser.uid),
        sharedData,
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileTextField(
                  label: 'Name',
                  controller: _nameController,
                  enabled: !_isSaving,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _ProfileTextField(
                  label: 'Phone',
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _ProfileTextField(
                  label: 'Address',
                  controller: _addressController,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _CustomerProfileData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final _CustomerProfileStats stats;

  const _CustomerProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.stats,
  });

  factory _CustomerProfileData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackEmail,
    required _CustomerProfileStats stats,
  }) {
    return _CustomerProfileData(
      name: _stringValue(map['name'], fallback: 'Customer'),
      email: _stringValue(map['email'], fallback: fallbackEmail),
      phone: _stringValue(map['phone']),
      address: _stringValue(map['address']),
      stats: stats,
    );
  }

  factory _CustomerProfileData.empty() {
    return const _CustomerProfileData(
      name: 'Customer',
      email: '',
      phone: '',
      address: '',
      stats: _CustomerProfileStats.empty(),
    );
  }
}

class _CustomerProfileStats {
  final int bookings;
  final int guests;
  final int completedTasks;
  final int totalTasks;

  const _CustomerProfileStats({
    required this.bookings,
    required this.guests,
    required this.completedTasks,
    required this.totalTasks,
  });

  const _CustomerProfileStats.empty()
    : bookings = 0,
      guests = 0,
      completedTasks = 0,
      totalTasks = 0;
}

class _ChecklistCounts {
  final int completed;
  final int total;

  const _ChecklistCounts({required this.completed, required this.total});
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 84,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.error : AppColors.primary;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.selectedSurface,
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
