import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_collections.dart';

import '../customer/customer_dashboard_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';
import '../vendor/vendor_pending_screen.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import 'customer_register_screen.dart';
import 'vendor_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  String selectedRole = 'Customer';

  Future<void> _forgotPassword() async {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    String? validationMessage;

    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset your password',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the email linked to your account and we’ll send you a reset link.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: validationMessage,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
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
                      onPressed: () {
                        final value = resetEmailController.text
                            .trim()
                            .toLowerCase();
                        final isValid = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value);
                        if (!isValid) {
                          setSheetState(() {
                            validationMessage = 'Enter a valid email address.';
                          });
                          return;
                        }
                        Navigator.pop(sheetContext, value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Send link'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    resetEmailController.dispose();

    if (!mounted || email == null) return;

    try {
      await context.read<AuthProvider>().authService.resetPassword(email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset request sent for $email. Check your inbox and spam folder.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
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

  Future<void> _login() async {
    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile not found. Please register again.'),
          ),
        );
        return;
      }

      final userData = userDoc.data() ?? {};
      final role = userData['role']?.toString().toLowerCase() ?? '';
      final status = userData['status']?.toString().toLowerCase() ?? 'active';
      final isActive = userData['isActive'] == true;

      if (!isActive || status == 'blocked' || status == 'suspended') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is not active. Please contact admin.'),
          ),
        );
        return;
      }

      if (role == 'customer') {
        final customerDoc = await FirebaseFirestore.instance
            .collection(FirestoreCollections.customers)
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (!customerDoc.exists) {
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Customer profile not found. Please contact support.',
              ),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
        );
        return;
      }

      if (role == 'vendor') {
        final vendorDoc = await FirebaseFirestore.instance
            .collection(FirestoreCollections.vendors)
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (!vendorDoc.exists) {
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor profile not found. Please contact admin.'),
            ),
          );
          return;
        }

        final vendorData = vendorDoc.data() ?? {};

        final isApproved = vendorData['isApproved'] == true;
        final approvalStatus =
            vendorData['approvalStatus']?.toString().toLowerCase() ?? 'pending';

        if (isApproved && approvalStatus == 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VendorPendingScreen()),
          );
        }

        return;
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user role. Please contact support.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-not-verified' =>
          'Verify your email first. We sent a new verification link if allowed.',
        'user-not-found' ||
        'invalid-credential' => 'No account matches that email and password.',
        'wrong-password' => 'The password is incorrect.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' =>
          'Too many sign-in attempts. Please wait and try again.',
        'network-request-failed' =>
          'Could not connect. Check your internet connection and try again.',
        _ => error.message ?? 'Could not sign in. Please try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _goToRegister() {
    if (selectedRole == 'Vendor') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VendorRegisterScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

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
                'Welcome back',
                style: TextStyle(
                  fontSize: 31,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sign in to continue planning your perfect day',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 28),

              _RoleTabs(
                selectedRole: selectedRole,
                onChanged: (role) {
                  setState(() {
                    selectedRole = role;
                  });
                },
              ),

              const SizedBox(height: 26),

              CustomTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'Password',
                hint: '••••••••',
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
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              CustomButton(
                text: 'Sign In',
                isLoading: isLoading,
                onPressed: isLoading ? null : _login,
              ),

              const SizedBox(height: 22),

              Center(
                child: TextButton(
                  onPressed: _goToRegister,
                  child: const Text.rich(
                    TextSpan(
                      text: 'New here? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Create account',
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
    );
  }
}

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

class _RoleTabs extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleTabs({required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final roles = ['Customer', 'Vendor'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: roles.map((role) {
          final selected = selectedRole == role;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
