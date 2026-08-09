import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_parsers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_information_sheet.dart';
import '../../core/widgets/support_contact_card.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/password_reset_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import 'browse_services_screen.dart';
import 'checklist_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_dashboard_screen.dart';
import 'guest_list_screen.dart';
import 'notification_screen.dart';
import 'wishlist_screen.dart';

/// Displays the customer profile page and coordinates the actions available on it.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Future<_CustomerProfileData>? _profileFuture;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileFuture = _loadProfile(currentUser.uid);
    }
  }

  /// Loads profile and updates the visible state.
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

  /// Loads profile counts and updates the visible state.
  Future<_CustomerProfileStats> _loadProfileCounts(String customerId) async {
    final checklistCounts = await _loadChecklistCounts(customerId);

    return _CustomerProfileStats(
      bookings: await _loadBookingCount(customerId),
      guests: await _loadGuestCount(customerId),
      completedTasks: checklistCounts.completed,
      totalTasks: checklistCounts.total,
    );
  }

  /// Loads booking count and updates the visible state.
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

  /// Loads guest count and updates the visible state.
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

  /// Loads checklist counts and updates the visible state.
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

  Future<void> _uploadProfileImage(
    String customerId,
    String displayName,
  ) async {
    if (_isUploadingImage) return;
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 55,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await StorageService().uploadProfileImage(
        userId: customerId,
        role: 'customer',
        image: image,
      );
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final data = {
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(
        firestore.collection(FirestoreCollections.customers).doc(customerId),
        data,
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection(FirestoreCollections.users).doc(customerId),
        data,
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('public_profiles').doc(customerId),
        {'displayName': displayName, 'role': 'customer', ...data},
        SetOptions(merge: true),
      );
      await batch.commit();
      if (!mounted) return;
      _refreshProfile(customerId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile picture: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
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

  /// Opens the edit profile interface for the user.
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
      builder: (_) => PasswordResetSheet(email: email),
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
                    userId: currentUser.uid,
                    isUploadingImage: _isUploadingImage,
                    onImageTap: () =>
                        _uploadProfileImage(currentUser.uid, profile.name),
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
                        title: 'Change Password',
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

/// Renders the reusable profile header card UI component.
class _ProfileHeaderCard extends StatelessWidget {
  final _CustomerProfileData profile;
  final String userId;
  final bool isUploadingImage;
  final VoidCallback onImageTap;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.profile,
    required this.userId,
    required this.isUploadingImage,
    required this.onImageTap,
    required this.onEdit,
  });

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
          Semantics(
            button: true,
            label: 'Change profile picture',
            child: GestureDetector(
              onTap: isUploadingImage ? null : onImageTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    userId: userId,
                    fallbackName: initial,
                    imageUrl: profile.profileImageUrl,
                    radius: 34,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.surface,
                      child: isUploadingImage
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ],
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

/// Renders the reusable edit profile sheet UI component.
class _EditProfileSheet extends StatefulWidget {
  final _CustomerProfileData profile;

  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    final savedPhone = widget.profile.phone.replaceAll(RegExp(r'\s+'), '');
    _phoneController.text = savedPhone.startsWith('+977')
        ? savedPhone.substring(4)
        : savedPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validates and saves the current save values.
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
        'phone': normalizeNepaliPhoneNumber(_phoneController.text),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.set(
        firestore
            .collection(FirestoreCollections.customers)
            .doc(currentUser.uid),
        {...sharedData, 'address': FieldValue.delete()},
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('public_profiles').doc(currentUser.uid),
        {
          'displayName': _nameController.text.trim(),
          'role': 'customer',
          'profileImageUrl': widget.profile.profileImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
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
                  prefixText: '+977 ',
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: validateNepaliPhoneNumber,
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

/// Renders the reusable profile text field UI component.
class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.prefixText,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixText == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    prefixText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
        prefixIconConstraints: prefixText == null
            ? null
            : const BoxConstraints(minWidth: 0, minHeight: 0),
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

/// Groups the data and behavior required by the customer profile data component.
class _CustomerProfileData {
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final _CustomerProfileStats stats;

  const _CustomerProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
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
      profileImageUrl: _stringValue(map['profileImageUrl']),
      stats: stats,
    );
  }

  factory _CustomerProfileData.empty() {
    return const _CustomerProfileData(
      name: 'Customer',
      email: '',
      phone: '',
      profileImageUrl: '',
      stats: _CustomerProfileStats.empty(),
    );
  }
}

/// Groups the data and behavior required by the customer profile stats component.
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

/// Groups the data and behavior required by the checklist counts component.
class _ChecklistCounts {
  final int completed;
  final int total;

  const _ChecklistCounts({required this.completed, required this.total});
}

/// Renders the reusable stat card UI component.
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

/// Renders the reusable section title UI component.
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

/// Renders the reusable profile menu card UI component.
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

/// Renders the reusable profile menu item UI component.
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
