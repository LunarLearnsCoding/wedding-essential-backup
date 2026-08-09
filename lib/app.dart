import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
import 'screens/vendor/vendor_services_screen.dart';
import 'screens/vendor/vendor_bookings_screen.dart';
import 'screens/vendor/vendor_inquiries_screen.dart';
import 'screens/vendor/vendor_reviews_screen.dart';
import 'screens/vendor/vendor_profile_screen.dart';

/// Defines the root application widget and its shared navigation routes.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wedding Essentials',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/vendor/home': (_) => const VendorDashboardScreen(),
        '/vendor/services': (_) => const VendorServicesScreen(),
        '/vendor/bookings': (_) => const VendorBookingsScreen(),
        '/vendor/inquiries': (_) => const VendorInquiriesScreen(),
        '/vendor/reviews': (_) => const VendorReviewsScreen(),
        '/vendor/profile': (_) => const VendorProfileScreen(),
      },
    );
  }
}
