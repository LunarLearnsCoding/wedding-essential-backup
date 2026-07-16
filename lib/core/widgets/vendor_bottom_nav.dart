import 'package:flutter/material.dart';

class VendorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const VendorBottomNav({super.key, required this.currentIndex, this.onTap});

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    final routes = <String>[
      '/vendor/home',
      '/vendor/services',
      '/vendor/bookings',
      '/vendor/profile',
    ];

    if (index < 0 || index >= routes.length) {
      return;
    }

    final targetRoute = routes[index];
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == targetRoute) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _handleTap(context, index),
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFF5E7E7),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
