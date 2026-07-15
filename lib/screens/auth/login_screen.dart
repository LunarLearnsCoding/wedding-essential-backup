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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
                  onPressed: () {},
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

              const SizedBox(height: 30),

              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 28),

              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 26),

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
