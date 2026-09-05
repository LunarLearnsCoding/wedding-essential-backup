import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/review_rating_summary.dart';
import '../../core/widgets/firebase_storage_image.dart';
import '../../core/constants/service_categories.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../models/service_model.dart';
import '../../models/vendor_model.dart';
import '../../models/review_model.dart';
import '../../models/review_summary.dart';
import '../../providers/service_provider.dart';
import '../../services/review_service.dart';
import '../../services/vendor_service.dart';
import 'customer_dashboard_screen.dart';
import 'customer_profile_screen.dart';
import 'notification_screen.dart';
import 'service_details_screen.dart';
import 'vendor_details_screen.dart';

/// Lists the supported browse mode values used throughout the app.
enum BrowseMode { featured, vendors, services }

/// Displays the browse services page and coordinates the actions available on it.
class BrowseServicesScreen extends StatefulWidget {
  final String initialCategory;
  final BrowseMode initialMode;

  const BrowseServicesScreen({
    super.key,
    this.initialCategory = 'All',
    this.initialMode = BrowseMode.services,
  });

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _BrowseServicesScreenState extends State<BrowseServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VendorService _vendorService = VendorService();
  final ReviewService _reviewService = ReviewService();

  late BrowseMode _mode;
  late String _selectedCategory;
  String _serviceSort = 'Price';
  String _vendorSort = 'Top Rated';

  static const _categories = ['All', ...serviceCategories];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedCategory = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ServiceProvider>().services.isEmpty) {
        context.read<ServiceProvider>().loadServices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceModel> _services(List<ServiceModel> allServices) {
    final query = _searchController.text.toLowerCase().trim();
    final services = allServices.where((service) {
      final matchesCategory =
          _selectedCategory == 'All' || service.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.vendorName.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query) ||
          service.location.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    if (_serviceSort == 'Price') {
      services.sort((a, b) => a.price.compareTo(b.price));
    } else {
      services.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    return services;
  }

  List<VendorModel> _vendors(
    QuerySnapshot snapshot, {
    bool featuredOnly = false,
    Map<String, ReviewSummary> reviewSummaries = const {},
  }) {
    final query = _searchController.text.toLowerCase().trim();
    final now = DateTime.now();
    final vendors = snapshot.docs
        .where((doc) => doc.data() is Map<String, dynamic>)
        .map((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          return VendorModel.fromMap(doc.id, data);
        })
        .where(
          (vendor) =>
              vendor.isApproved &&
              vendor.approvalStatus.toLowerCase() == 'approved',
        )
        .where(
          (vendor) =>
              !featuredOnly ||
              (vendor.isFeatured &&
                  vendor.featuredUntil != null &&
                  vendor.featuredUntil!.isAfter(now)),
        )
        .where((vendor) {
          return query.isEmpty ||
              vendor.businessName.toLowerCase().contains(query) ||
              vendor.name.toLowerCase().contains(query) ||
              vendor.category.toLowerCase().contains(query) ||
              vendor.location.toLowerCase().contains(query);
        })
        .toList();

    if (_vendorSort == 'Top Rated') {
      vendors.sort((a, b) {
        final aSummary = reviewSummaries[a.id] ?? const ReviewSummary.empty();
        final bSummary = reviewSummaries[b.id] ?? const ReviewSummary.empty();
        final ratingComparison = bSummary.averageRating.compareTo(
          aSummary.averageRating,
        );
        if (ratingComparison != 0) return ratingComparison;
        final reviewCountComparison = bSummary.totalReviews.compareTo(
          aSummary.totalReviews,
        );
        if (reviewCountComparison != 0) return reviewCountComparison;
        return _vendorDisplayName(
          a,
        ).toLowerCase().compareTo(_vendorDisplayName(b).toLowerCase());
      });
    } else {
      vendors.sort(
        (a, b) => _vendorDisplayName(
          a,
        ).toLowerCase().compareTo(_vendorDisplayName(b).toLowerCase()),
      );
    }
    return vendors;
  }

  Map<String, ReviewSummary> _reviewSummaries(List<ReviewModel> reviews) {
    final groupedReviews = <String, List<ReviewModel>>{};
    for (final review in reviews) {
      if (!review.isVisible || review.vendorId.trim().isEmpty) continue;
      groupedReviews.putIfAbsent(review.vendorId, () => []).add(review);
    }
    return groupedReviews.map(
      (vendorId, vendorReviews) =>
          MapEntry(vendorId, ReviewSummary.fromReviews(vendorReviews)),
    );
  }

  /// Handles the bottom nav user action.
  void _handleBottomNav(int index) {
    final destination = switch (index) {
      0 => const CustomerDashboardScreen(),
      2 => const NotificationsScreen(),
      3 => const CustomerProfileScreen(),
      _ => null,
    };
    if (destination != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _BrowseHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: SegmentedButton<BrowseMode>(
                segments: const [
                  ButtonSegment(
                    value: BrowseMode.featured,
                    label: Text('Featured'),
                  ),
                  ButtonSegment(
                    value: BrowseMode.vendors,
                    label: Text('Browse'),
                  ),
                  ButtonSegment(
                    value: BrowseMode.services,
                    label: Text('Services'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _mode == BrowseMode.services
                      ? 'Search services...'
                      : _mode == BrowseMode.featured
                      ? 'Search featured vendors...'
                      : 'Search vendors...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _mode == BrowseMode.services
                  ? _ServicesView(
                      services: _services(
                        context.watch<ServiceProvider>().services,
                      ),
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      sort: _serviceSort,
                      sortOptions: const ['Price', 'Name'],
                      onCategoryChanged: (category) {
                        setState(() => _selectedCategory = category);
                      },
                      onSortChanged: (sort) {
                        setState(() => _serviceSort = sort);
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _vendorService.getApprovedVendors(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load vendors: ${snapshot.error}',
                            ),
                          );
                        }
                        return StreamBuilder<List<ReviewModel>>(
                          stream: _reviewService.getAllReviews(),
                          builder: (context, reviewSnapshot) {
                            if (reviewSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !reviewSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (reviewSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Failed to load ratings: '
                                  '${reviewSnapshot.error}',
                                ),
                              );
                            }
                            return _VendorsView(
                              vendors: _vendors(
                                snapshot.data!,
                                featuredOnly: _mode == BrowseMode.featured,
                                reviewSummaries: _reviewSummaries(
                                  reviewSnapshot.data ?? const [],
                                ),
                              ),
                              sort: _vendorSort,
                              sortOptions: const ['Top Rated', 'Name'],
                              onSortChanged: (sort) {
                                setState(() => _vendorSort = sort);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: _handleBottomNav,
      ),
    );
  }
}

/// Renders the reusable browse header UI component.
class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          const SizedBox(width: 6),
          const Text(
            'Browse',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable services view UI component.
class _ServicesView extends StatelessWidget {
  final List<ServiceModel> services;
  final List<String> categories;
  final String selectedCategory;
  final String sort;
  final List<String> sortOptions;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;

  const _ServicesView({
    required this.services,
    required this.categories,
    required this.selectedCategory,
    required this.sort,
    required this.sortOptions,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResultsHeader(
          text: '${services.length} services found',
          sort: sort,
          sortOptions: sortOptions,
          onSortChanged: onSortChanged,
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => onCategoryChanged(category),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                side: const BorderSide(color: AppColors.border),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: services.isEmpty
              ? const Center(child: Text('No matching services'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ServiceDetailsScreen(serviceId: service.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Renders the reusable vendors view UI component.
class _VendorsView extends StatelessWidget {
  final List<VendorModel> vendors;
  final String sort;
  final List<String> sortOptions;
  final ValueChanged<String> onSortChanged;

  const _VendorsView({
    required this.vendors,
    required this.sort,
    required this.sortOptions,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResultsHeader(
          text: '${vendors.length} vendors found',
          sort: sort,
          sortOptions: sortOptions,
          onSortChanged: onSortChanged,
        ),
        Expanded(
          child: vendors.isEmpty
              ? const Center(child: Text('No matching vendors'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    return _VendorCard(
                      vendor: vendor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VendorDetailsScreen(vendorId: vendor.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Renders the reusable results header UI component.
class _ResultsHeader extends StatelessWidget {
  final String text;
  final String sort;
  final List<String> sortOptions;
  final ValueChanged<String> onSortChanged;

  const _ResultsHeader({
    required this.text,
    required this.sort,
    required this.sortOptions,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: sort,
            onSelected: onSortChanged,
            itemBuilder: (context) => sortOptions
                .map(
                  (option) => PopupMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
            child: IgnorePointer(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune, size: 17),
                label: Text('Sort: $sort'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable service card UI component.
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _BrowseCard(
      onTap: onTap,
      imageUrl: service.imageUrls.isEmpty ? '' : service.imageUrls.first,
      title: service.name,
      subtitle: service.vendorName,
      details: '${service.category} | ${service.location}',
      trailing: 'From Rs. ${service.price.toStringAsFixed(0)}',
    );
  }
}

/// Renders the reusable vendor card UI component.
class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;

  const _VendorCard({required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = _vendorDisplayName(vendor);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(
                userId: vendor.id,
                fallbackName: name,
                imageUrl: vendor.profileImageUrl,
                radius: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vendor.category,
                      style: const TextStyle(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      vendor.location.isEmpty
                          ? 'Location not provided'
                          : vendor.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: ReviewRatingSummary.vendor(
                            vendorId: vendor.id,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'View Profile',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the reusable browse card UI component.
class _BrowseCard extends StatelessWidget {
  final VoidCallback onTap;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String details;
  final String trailing;

  const _BrowseCard({
    required this.onTap,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 96,
                  width: 104,
                  child: imageUrl.isEmpty
                      ? const ColoredBox(
                          color: AppColors.selectedSurface,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.primary,
                          ),
                        )
                      : FirebaseStorageImage(
                          source: imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => const ColoredBox(
                            color: AppColors.selectedSurface,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 6),
                    Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(
                      trailing,
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
      ),
    );
  }
}

String _vendorDisplayName(VendorModel vendor) {
  final businessName = vendor.businessName.trim();
  if (businessName.isNotEmpty) return businessName;
  final name = vendor.name.trim();
  return name.isEmpty ? 'Vendor' : name;
}
