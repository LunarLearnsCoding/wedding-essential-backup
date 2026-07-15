import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../customer/customer_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';
import '../vendor/vendor_pending_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _iconFade;
  late Animation<double> _titleFade;
  late Animation<double> _lineWidth;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _iconFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.55, curve: Curves.easeIn),
      ),
    );

    _lineWidth = Tween<double>(begin: 0, end: 120).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _startSplashFlow();
  }

  Future<void> _startSplashFlow() async {
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    await checkUserAndNavigate();
  }

  Future<void> checkUserAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final userData = userDoc.data() ?? {};

      final role = userData['role']?.toString().toLowerCase() ?? '';
      final userStatus =
          userData['status']?.toString().toLowerCase() ?? 'active';

      if (userStatus == 'suspended' || userStatus == 'blocked') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
        );
        return;
      }

      if (role == 'vendor') {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (!vendorDoc.exists) {
          await FirebaseAuth.instance.signOut();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check user role: $error')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _iconFade,
                  child: const Icon(
                    Icons.favorite_border,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 22),

                FadeTransition(
                  opacity: _titleFade,
                  child: const Text(
                    'Wedding Essentials',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: _lineWidth.value / 2,
                        height: 1.2,
                        color: AppColors.border,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: _lineWidth.value / 2,
                        height: 1.2,
                        color: AppColors.border,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                FadeTransition(
                  opacity: _subtitleFade,
                  child: const Text(
                    'Plan your perfect wedding',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
