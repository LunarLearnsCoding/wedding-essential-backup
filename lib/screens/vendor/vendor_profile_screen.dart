import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/admin_account.dart';
import '../../core/constants/service_categories.dart';
import '../../core/constants/vendor_locations.dart';
import '../../core/utils/firestore_parsers.dart';
import '../../core/widgets/app_information_sheet.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/password_reset_sheet.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/widgets/support_contact_card.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';

/// Displays the vendor profile page and coordinates the actions available on it.
class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorProfileScreenState extends State<VendorProfileScreen> {
  bool _isUploadingImage = false;

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
              _ProfileHeader(
                profile: profile,
                vendorId: currentUser.uid,
                isUploadingImage: _isUploadingImage,
                onImageTap: () =>
                    _uploadProfileImage(currentUser.uid, profile.businessName),
              ),

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
                        subtitle: 'Edit your business details and bio',
                        onTap: () => _showBusinessInformationSheet(
                          context,
                          currentUser.uid,
                          profile,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.link,
                        title: 'Social Media Links',
                        subtitle:
                            'Edit Facebook, Instagram, TikTok and website',
                        onTap: () => _showSocialLinksDialog(
                          context,
                          currentUser.uid,
                          profile,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.star_outline_rounded,
                        title: 'Promote Your Business',
                        subtitle:
                            profile.isFeatured && profile.featuredUntil != null
                            ? 'Featured until ${_formatDate(profile.featuredUntil!)}'
                            : 'Explore featured placement plans and contact the admin team',
                        onTap: () => _showFeaturedOptionsSheet(context),
                      ),

                      const SizedBox(height: 12),

                      _ProfileOptionCard(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Send a password reset email',
                        onTap: () => _sendPasswordReset(context),
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
                      const SizedBox(height: 20),
                      const SupportContactCard(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
    );
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address found for this account.'),
        ),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PasswordResetSheet(email: email),
    );
    if (!context.mounted || confirmed != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

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

  Future<void> _uploadProfileImage(String vendorId, String displayName) async {
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
        userId: vendorId,
        role: 'vendor',
        image: image,
      );
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final data = {
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(
        firestore.collection('vendors').doc(vendorId),
        data,
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('users').doc(vendorId),
        data,
        SetOptions(merge: true),
      );
      batch.set(
        firestore.collection('public_profiles').doc(vendorId),
        {'displayName': displayName, 'role': 'vendor', ...data},
        SetOptions(merge: true),
      );
      await batch.commit();
      if (!mounted) return;
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

  /// Opens the business information sheet interface for the user.
  Future<void> _showBusinessInformationSheet(
    BuildContext context,
    String vendorId,
    _VendorProfileData profile,
  ) async {
    final values = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessInformationSheet(profile: profile),
    );
    if (!context.mounted || values == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .update(values);
      await FirebaseFirestore.instance.collection('users').doc(vendorId).set({
        'name': values['name'],
        'phone': values['phone'],
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('public_profiles')
          .doc(vendorId)
          .set({
            'displayName': values['businessName'],
            'role': 'vendor',
            'profileImageUrl': profile.profileImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business information updated.')),
      );
    } on FirebaseException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update business information.')),
      );
    }
  }

  /// Opens the featured options sheet interface for the user.
  Future<void> _showFeaturedOptionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeaturedOptionsSheet(),
    );
  }

  /// Opens the social links dialog interface for the user.
  Future<void> _showSocialLinksDialog(
    BuildContext context,
    String vendorId,
    _VendorProfileData profile,
  ) async {
    final facebook = TextEditingController(text: profile.facebookUrl);
    final instagram = TextEditingController(text: profile.instagramUrl);
    final tiktok = TextEditingController(text: profile.tiktokUrl);
    final website = TextEditingController(text: profile.websiteUrl);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(dialogContext).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 22),
              const Text(
                'Social media links',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add the pages customers can use to discover your business.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              _VendorTextField(
                controller: facebook,
                label: 'Facebook link',
                icon: Icons.facebook,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: instagram,
                label: 'Instagram link',
                icon: Icons.camera_alt_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: tiktok,
                label: 'TikTok link',
                icon: Icons.music_note_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: website,
                label: 'Website link',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('vendors')
                          .doc(vendorId)
                          .update({
                            'facebookUrl': facebook.text.trim(),
                            'instagramUrl': instagram.text.trim(),
                            'tiktokUrl': tiktok.text.trim(),
                            'websiteUrl': website.text.trim(),
                          });
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Social links updated.')),
                      );
                    } on FirebaseException {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Could not update social links.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save links'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    facebook.dispose();
    instagram.dispose();
    tiktok.dispose();
    website.dispose();
  }

  /// Opens the logout dialog interface for the user.
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showAppConfirmationSheet(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to sign out of your vendor account?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

/// Renders the reusable featured options sheet UI component.
class _FeaturedOptionsSheet extends StatelessWidget {
  const _FeaturedOptionsSheet();

  static const _plans = <int, int>{1: 100, 3: 250, 7: 500, 14: 900, 30: 1500};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 22),
              const Text(
                'Featured Vendor Placement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              for (final plan in _plans.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          '${plan.key} ${plan.key == 1 ? 'day' : 'days'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Rs. ${plan.value}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              SupportContactCard(
                title: 'Arrange your featured placement',
                message:
                    'Email $adminAccountEmail to confirm your preferred plan, payment, and schedule.',
                emailSubject: 'Featured vendor request',
                emailBody:
                    'I would like to arrange featured vendor placement. Please share the payment and scheduling details.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the reusable business information sheet UI component.
class _BusinessInformationSheet extends StatefulWidget {
  final _VendorProfileData profile;

  const _BusinessInformationSheet({required this.profile});

  @override
  State<_BusinessInformationSheet> createState() =>
      _BusinessInformationSheetState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _BusinessInformationSheetState extends State<_BusinessInformationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _owner;
  late final TextEditingController _business;
  late final TextEditingController _phone;
  String? _selectedCategory;
  String? _selectedLocation;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _owner = TextEditingController(text: widget.profile.name);
    _business = TextEditingController(text: widget.profile.businessName);
    _phone = TextEditingController(text: widget.profile.phone);
    _selectedCategory = serviceCategories.contains(widget.profile.category)
        ? widget.profile.category
        : null;
    _selectedLocation = locations.contains(widget.profile.location)
        ? widget.profile.location
        : null;
    _bio = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _owner.dispose();
    _business.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Validates and saves the current save values.
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'name': _owner.text.trim(),
      'businessName': _business.text.trim(),
      'phone': _phone.text.trim(),
      'category': _selectedCategory!,
      'location': _selectedLocation!,
      'locations': FieldValue.delete(),
      'bio': _bio.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 22),
              const Text(
                'Business information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep the details customers see on your vendor profile up to date.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              _VendorTextField(
                controller: _owner,
                label: 'Owner name',
                icon: Icons.person_outline,
                requiredField: true,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: _business,
                label: 'Business name',
                icon: Icons.storefront_outlined,
                requiredField: true,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: _phone,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Service category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: serviceCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null ? 'Please choose a service category.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: locations
                    .map(
                      (location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedLocation = value),
                validator: (value) =>
                    value == null ? 'Please choose a location.' : null,
              ),
              const SizedBox(height: 14),
              _VendorTextField(
                controller: _bio,
                label: 'Business bio',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save information'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the reusable vendor text field UI component.
class _VendorTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool requiredField;

  const _VendorTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: requiredField
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required.'
                : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

/// Renders the reusable profile header UI component.
class _ProfileHeader extends StatelessWidget {
  final _VendorProfileData profile;
  final String vendorId;
  final bool isUploadingImage;
  final VoidCallback onImageTap;

  const _ProfileHeader({
    required this.profile,
    required this.vendorId,
    required this.isUploadingImage,
    required this.onImageTap,
  });

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
          GestureDetector(
            onTap: isUploadingImage ? null : onImageTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  userId: vendorId,
                  fallbackName: profile.businessName,
                  imageUrl: profile.profileImageUrl,
                  radius: 34,
                  backgroundColor: Colors.white,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: isUploadingImage
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 14,
                          ),
                  ),
                ),
              ],
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

/// Renders the reusable profile info card UI component.
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
            value: profile.location,
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            const Text('About', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              profile.bio,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Groups the data and behavior required by the vendor profile data component.
class _VendorProfileData {
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String category;
  final String location;
  final String bio;
  final String profileImageUrl;
  final String facebookUrl;
  final String instagramUrl;
  final String tiktokUrl;
  final String websiteUrl;
  final bool isFeatured;
  final DateTime? featuredUntil;

  const _VendorProfileData({
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.category,
    required this.location,
    required this.bio,
    required this.profileImageUrl,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.tiktokUrl,
    required this.websiteUrl,
    required this.isFeatured,
    required this.featuredUntil,
  });

  factory _VendorProfileData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackEmail,
  }) {
    final name = _cleanText(map['name'], fallback: 'Vendor');
    final businessName = _cleanText(map['businessName'], fallback: name);
    final email = _cleanText(map['email'], fallback: fallbackEmail);
    final phone = _cleanText(map['phone'], fallback: 'Not provided');
    final savedLocation = _cleanText(map['location'], fallback: '');
    final legacyLocations = map['locations'];
    final legacyLocation = legacyLocations is Iterable
        ? legacyLocations
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .firstOrNull
        : null;
    final location = savedLocation.isNotEmpty
        ? savedLocation
        : legacyLocation ?? 'Not provided';

    return _VendorProfileData(
      name: name,
      businessName: businessName,
      email: email.isEmpty ? 'Not provided' : email,
      phone: phone,
      category: _cleanText(map['category'], fallback: ''),
      location: location,
      bio: _cleanText(map['bio'], fallback: ''),
      profileImageUrl: _cleanText(map['profileImageUrl'], fallback: ''),
      facebookUrl: _cleanText(map['facebookUrl'], fallback: ''),
      instagramUrl: _cleanText(map['instagramUrl'], fallback: ''),
      tiktokUrl: _cleanText(map['tiktokUrl'], fallback: ''),
      websiteUrl: _cleanText(map['websiteUrl'], fallback: ''),
      isFeatured: boolFromFirestore(map['isFeatured']),
      featuredUntil: dateTimeFromFirestore(map['featuredUntil']),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _cleanText(dynamic value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

/// Renders the reusable profile detail row UI component.
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

/// Renders the reusable profile option card UI component.
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
