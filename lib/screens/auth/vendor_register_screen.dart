import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/service_categories.dart';
import '../../core/constants/vendor_locations.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/legal_agreement.dart';
import '../../providers/auth_provider.dart';
import 'customer_register_screen.dart';
import 'login_screen.dart';

/// Displays the vendor register page and coordinates the actions available on it.
class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final ownerNameController = TextEditingController();
  final businessNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool agreeToTerms = false;

  String selectedCategory = 'Photography';
  String? selectedLocation;

  Future<void> _registerVendor() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms and Privacy Policy'),
        ),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().authService.registerVendor(
        name: ownerNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: normalizeNepaliPhoneNumber(phoneController.text),
        businessName: businessNameController.text.trim(),
        category: selectedCategory,
        location: selectedLocation!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check your email and verify it to finish creating your vendor account.',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_registrationErrorMessage(error))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Navigates to the destination associated with this action.
  void _goToCustomerRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
    );
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    businessNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),

                const SizedBox(height: 18),

                Row(
                  children: const [
                    _LogoMark(),
                    SizedBox(width: 12),
                    Text(
                      'Wedding Essentials',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Create Vendor Account',
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Showcase your wedding services and reach more couples',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'I am a...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 14),

                _RoleCard(
                  title: 'Customer',
                  subtitle: 'Plan & book wedding services',
                  selected: false,
                  onTap: _goToCustomerRegister,
                ),

                _RoleCard(
                  title: 'Vendor',
                  subtitle: 'Offer wedding services',
                  selected: true,
                  onTap: () {},
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Owner Name',
                  hint: 'Enter owner name',
                  controller: ownerNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Owner name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Business Name',
                  hint: 'Enter business name',
                  controller: businessNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Business name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Service Category',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: serviceCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  validator: (value) => value == null
                      ? 'Please choose a service category.'
                      : null,
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: selectedLocation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Choose a location',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: AppColors.surface,
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
                  onChanged: (value) =>
                      setState(() => selectedLocation = value),
                  validator: (value) =>
                      value == null ? 'Please choose a location.' : null,
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Email',
                  hint: 'business@example.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmailAddress,
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Phone Number',
                  hint: '98XXXXXXXX',
                  prefixText: '+977 ',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: validateNepaliPhoneNumber,
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: passwordController,
                  obscureText: hidePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                LegalAgreement(
                  value: agreeToTerms,
                  onChanged: (value) {
                    setState(() => agreeToTerms = value);
                  },
                ),

                const SizedBox(height: 18),

                CustomButton(
                  text: 'Create Vendor Account',
                  isLoading: isLoading,
                  onPressed: isLoading || !agreeToTerms
                      ? null
                      : _registerVendor,
                ),

                const SizedBox(height: 22),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

String _registrationErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' =>
      'The email address is already in use by another account.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password and try again.',
    'too-many-requests' =>
      'Too many registration attempts. Please wait and try again.',
    'network-request-failed' =>
      'Could not connect. Check your internet connection and try again.',
    _ => error.message ?? 'Could not create the account. Please try again.',
  };
}

/// Renders the reusable logo mark UI component.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 22),
    );
  }
}

/// Renders the reusable role card UI component.
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.selectedSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.primary : AppColors.hint,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
