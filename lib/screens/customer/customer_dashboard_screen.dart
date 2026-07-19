import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/firestore_parsers.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../models/vendor_model.dart';
import '../../models/blog_model.dart';
import '../../models/review_model.dart';
import '../../services/blog_service.dart';
import '../../services/review_service.dart';
import 'blog_details_screen.dart';
import 'browse_services_screen.dart';
import 'checklist_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_inquiries_screen.dart';
import 'customer_profile_screen.dart';
import 'guest_list_screen.dart';
import 'notification_screen.dart';
import 'vendor_details_screen.dart';
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

    return _DashboardData(
      firstName: _firstName(profileData['name']),
      weddingDate: dateTimeFromFirestore(profileData['weddingDate']),
      weddingVenue: _stringValue(profileData['weddingVenue']),
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
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.35,
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
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 22),
                      _SectionHeader(
                        title: 'Featured Vendors',
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
                      const _FeaturedVendorsLive(),
                      const SizedBox(height: 24),
                      const Text(
                        'Wedding Tips & Blogs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _PublishedBlogsLive(),
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
  final VoidCallback onWeddingTap;

  const _FixedHeroHeader({required this.data, required this.onWeddingTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 48, 22, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${_timeGreeting()}, '),
                  TextSpan(
                    text: data.firstName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onWeddingTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WEDDING',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _compactWeddingCountdown(data.weddingDate),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
            fontSize: 19,
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
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth < 360 ? 1.3 : 1.55,
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 25),
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

class _FeaturedVendorsLive extends StatefulWidget {
  const _FeaturedVendorsLive();

  @override
  State<_FeaturedVendorsLive> createState() => _FeaturedVendorsLiveState();
}

class _FeaturedVendorsLiveState extends State<_FeaturedVendorsLive> {
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.vendors)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _FeaturedVendorCard(vendor: null);
        }
        final vendors =
            (snapshot.data?.docs ?? const [])
                .map((doc) => VendorModel.fromMap(doc.id, doc.data()))
                .where(
                  (vendor) =>
                      (vendor.isApproved ||
                          vendor.approvalStatus.toLowerCase() == 'approved') &&
                      vendor.isFeatured &&
                      (vendor.featuredUntil == null ||
                          vendor.featuredUntil!.isAfter(DateTime.now())),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (vendors.isEmpty) {
          return const _FeaturedVendorCard(vendor: null);
        }
        return Column(
          children: [
            for (var index = 0; index < vendors.length; index++) ...[
              _FeaturedVendorCard(vendor: vendors[index]),
              if (index != vendors.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedVendorCard extends StatelessWidget {
  const _FeaturedVendorCard({required this.vendor});

  final VendorModel? vendor;

  @override
  Widget build(BuildContext context) {
    final vendor = this.vendor;
    if (vendor == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No featured vendors yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    final name = vendor.businessName.trim().isNotEmpty
        ? vendor.businessName.trim()
        : vendor.name.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorDetailsScreen(vendorId: vendor.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: AppColors.selectedSurface,
              child: Text(
                name.isEmpty ? 'V' : name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Vendor' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor.category.trim().isEmpty
                        ? 'Wedding service provider'
                        : vendor.category.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 7),
                  _FeaturedVendorRating(
                    key: ValueKey(vendor.id),
                    vendorId: vendor.id,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedVendorRating extends StatefulWidget {
  const _FeaturedVendorRating({super.key, required this.vendorId});

  final String vendorId;

  @override
  State<_FeaturedVendorRating> createState() => _FeaturedVendorRatingState();
}

class _FeaturedVendorRatingState extends State<_FeaturedVendorRating> {
  static final ReviewService _reviewService = ReviewService();
  late Stream<List<ReviewModel>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = _reviewService.getReviewsByVendor(widget.vendorId);
  }

  @override
  void didUpdateWidget(covariant _FeaturedVendorRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendorId != widget.vendorId) {
      _reviews = _reviewService.getReviewsByVendor(widget.vendorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviews,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ReviewModel>[];
        final average = reviews.isEmpty
            ? 0.0
            : reviews.fold<double>(
                    0,
                    (total, review) => total + review.rating,
                  ) /
                  reviews.length;
        return Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 17),
            Flexible(
              child: Text(
                ' ${average.toStringAsFixed(1)} (${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PublishedBlogsLive extends StatelessWidget {
  const _PublishedBlogsLive();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BlogModel>>(
      stream: BlogService().getPublishedBlogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final blogs = snapshot.data ?? const <BlogModel>[];
        if (snapshot.hasError || blogs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No published wedding articles yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: [
            for (var index = 0; index < blogs.length; index++) ...[
              _BlogSummaryCard(blog: blogs[index]),
              if (index != blogs.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _BlogSummaryCard extends StatelessWidget {
  final BlogModel blog;

  const _BlogSummaryCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlogDetailsScreen(blog: blog)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.selectedSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: blog.imageUrl.trim().isEmpty
                  ? const Icon(Icons.article_outlined, color: AppColors.primary)
                  : Image.network(
                      blog.imageUrl.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.article_outlined,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.category,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    blog.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    blog.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  final String firstName;
  final DateTime? weddingDate;
  final String weddingVenue;

  const _DashboardData({
    required this.firstName,
    required this.weddingDate,
    required this.weddingVenue,
  });

  const _DashboardData.empty()
    : firstName = 'Customer',
      weddingDate = null,
      weddingVenue = '';
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

String _compactWeddingCountdown(DateTime? weddingDate) {
  if (weddingDate == null) return 'Set date';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weddingDay = DateTime(
    weddingDate.year,
    weddingDate.month,
    weddingDate.day,
  );
  final days = weddingDay.difference(today).inDays;

  if (days > 0) return '$days days';
  if (days == 0) return 'Today';
  return 'Date passed';
}
