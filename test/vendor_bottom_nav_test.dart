import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_essentialsapp/core/widgets/vendor_bottom_nav.dart';

void main() {
  testWidgets('tapping a vendor nav item switches to the matching route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/vendor/home',
        routes: {
          '/vendor/home': (_) => const _HomeScreen(),
          '/vendor/services': (_) => const _ServicesScreen(),
          '/vendor/bookings': (_) => const _BookingsScreen(),
          '/vendor/inquiries': (_) => const _InquiriesScreen(),
          '/vendor/reviews': (_) => const _ReviewsScreen(),
          '/vendor/profile': (_) => const _ProfileScreen(),
        },
        home: const Scaffold(),
      ),
    );

    expect(find.text('Vendor Home'), findsOneWidget);

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('Vendor Services'), findsOneWidget);
    expect(find.text('Vendor Home'), findsNothing);
  });
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Vendor Home')),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 0),
    );
  }
}

class _ServicesScreen extends StatelessWidget {
  const _ServicesScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Vendor Services')));
  }
}

class _BookingsScreen extends StatelessWidget {
  const _BookingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Vendor Bookings')));
  }
}

class _InquiriesScreen extends StatelessWidget {
  const _InquiriesScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Vendor Inquiries')));
  }
}

class _ReviewsScreen extends StatelessWidget {
  const _ReviewsScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Vendor Reviews')));
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Vendor Profile')));
  }
}
