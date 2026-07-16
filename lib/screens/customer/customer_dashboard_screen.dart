import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_parsers.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../models/service_model.dart';
import 'browse_services_screen.dart';
import 'checklist_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_inquiries_screen.dart';
import 'customer_profile_screen.dart';
import 'guest_list_screen.dart';
import 'notification_screen.dart';
import 'service_details_screen.dart';
import 'wedding_details_editor.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  Future<_DashboardData>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _dashboardFuture = _loadDashboardData(currentUser.uid);
    }
  }

  void _refreshDashboard(String customerId) {
    setState(() {
      _dashboardFuture = _loadDashboardData(customerId);
    });
  }

  Future<_DashboardData> _loadDashboardData(String customerId) async {
    final firestore = FirebaseFirestore.instance;

    final customerDoc = await firestore
        .collection(FirestoreCollections.customers)
        .doc(customerId)
        .get();
    final userDoc = customerDoc.exists
        ? null
        : await firestore
              .collection(FirestoreCollections.users)
              .doc(customerId)
              .get();
    final profileData = customerDoc.data() ?? userDoc?.data() ?? {};

    final servicesSnapshot = await firestore
        .collection(FirestoreCollections.services)
        .where('isActive', isEqualTo: true)
        .get();
    final services = servicesSnapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
        .toList();

    services.sort((a, b) {
      final ratingCompare = b.averageRating.compareTo(a.averageRating);
      if (ratingCompare != 0) return ratingCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return _DashboardData(
      firstName: _firstName(profileData['name']),
      weddingDate: dateTimeFromFirestore(profileData['weddingDate']),
      weddingVenue: _stringValue(profileData['weddingVenue']),
      featuredService: services.isEmpty ? null : services.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final categories = [
      _CategoryItem('Photography', Icons.camera_alt_outlined),
      _CategoryItem('Venue', Icons.location_city_outlined),
      _CategoryItem('Decoration', Icons.celebration_outlined),
      _CategoryItem('Makeup', Icons.face_retouching_natural_outlined),
      _CategoryItem('Catering', Icons.restaurant_outlined),
      _CategoryItem('Music', Icons.music_note_outlined),
    ];

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_DashboardData>(
        future: _dashboardFuture ??= _loadDashboardData(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DashboardError(message: snapshot.error.toString());
          }

          final data = snapshot.data ?? const _DashboardData.empty();

          return Column(
            children: [
              _FixedHeroHeader(
                data: data,
                onNotificationsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                onWeddingTap: () async {
                  final saved = await showWeddingDetailsEditor(
                    context: context,
                    initialWeddingDate: data.weddingDate,
                    initialVenue: data.weddingVenue,
                  );

                  if (!context.mounted || !saved) return;

                  _refreshDashboard(currentUser.uid);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Categories',
                        actionText: 'View all',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BrowseServicesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 720
                              ? 6
                              : constraints.maxWidth >= 420
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.95,
                                ),
                            itemBuilder: (context, index) {
                              final category = categories[index];

                              return _CategoryCard(
                                title: category.title,
                                icon: category.icon,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BrowseServicesScreen(
                                        initialCategory: category.title,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Wedding Planning',
                        actionText: 'View all',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BrowseServicesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _PlanningGrid(),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Featured Services',
                        actionText: 'Browse',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BrowseServicesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _FeaturedServiceCard(service: data.featuredService),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrowseServicesScreen()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
        },
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  const _DashboardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.primary,
                size: 38,
              ),
              const SizedBox(height: 10),
              const Text(
                'Failed to load dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixedHeroHeader extends StatelessWidget {
  final _DashboardData data;
  final VoidCallback onNotificationsTap;
  final VoidCallback onWeddingTap;

  const _FixedHeroHeader({
    required this.data,
    required this.onNotificationsTap,
    required this.onWeddingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeGreeting(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onNotificationsTap,
                child: Stack(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 9,
                      top: 9,
                      child: Container(
                        height: 9,
                        width: 9,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onWeddingTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wedding Countdown',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weddingCountdownText(data.weddingDate),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (data.weddingVenue.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.weddingVenue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String title;
  final IconData icon;

  _CategoryItem(this.title, this.icon);
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 360 ? 1.0 : 1.15,
          padding: EdgeInsets.zero,
          children: [
            _PlanningCard(
              title: 'My Bookings',
              subtitle: 'Track booking status',
              icon: Icons.calendar_month_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerBookingsScreen(),
                  ),
                );
              },
            ),
            _PlanningCard(
              title: 'Checklist',
              subtitle: 'Manage wedding tasks',
              icon: Icons.checklist_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChecklistScreen()),
                );
              },
            ),
            _PlanningCard(
              title: 'My Inquiries',
              subtitle: 'Track inquiry status',
              icon: Icons.message_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerInquiriesScreen(),
                  ),
                );
              },
            ),
            _PlanningCard(
              title: 'Guest List',
              subtitle: 'Manage wedding guests',
              icon: Icons.people_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuestListScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PlanningCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedServiceCard extends StatelessWidget {
  final ServiceModel? service;

  const _FeaturedServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final service = this.service;
    if (service == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_outlined, color: AppColors.primary, size: 34),
            SizedBox(height: 10),
            Text(
              'No active services yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Featured services will appear here once vendors publish them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(serviceId: service.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _FeaturedServiceImage(service: service),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    service.vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedServiceImage extends StatelessWidget {
  final ServiceModel service;

  const _FeaturedServiceImage({required this.service});

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.imageUrls.isEmpty ? '' : service.imageUrls.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 96,
        width: 96,
        child: imageUrl.trim().isEmpty
            ? const _FeaturedImagePlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _FeaturedImagePlaceholder();
                },
              ),
      ),
    );
  }
}

class _FeaturedImagePlaceholder extends StatelessWidget {
  const _FeaturedImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.selectedSurface,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }
}

class _DashboardData {
  final String firstName;
  final DateTime? weddingDate;
  final String weddingVenue;
  final ServiceModel? featuredService;

  const _DashboardData({
    required this.firstName,
    required this.weddingDate,
    required this.weddingVenue,
    required this.featuredService,
  });

  const _DashboardData.empty()
    : firstName = 'Customer',
      weddingDate = null,
      weddingVenue = '',
      featuredService = null;
}

String _firstName(dynamic rawName) {
  final name = rawName?.toString().trim() ?? '';
  if (name.isEmpty) return 'Customer';
  return name.split(RegExp(r'\s+')).first;
}

String _stringValue(dynamic value) {
  return value?.toString().trim() ?? '';
}

String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _weddingCountdownText(DateTime? weddingDate) {
  if (weddingDate == null) {
    return 'Add your wedding date to start planning';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weddingDay = DateTime(
    weddingDate.year,
    weddingDate.month,
    weddingDate.day,
  );
  final days = weddingDay.difference(today).inDays;

  if (days > 0) return '$days days to your wedding';
  if (days == 0) return 'Your wedding is today';
  return 'Wedding date has passed';
}
