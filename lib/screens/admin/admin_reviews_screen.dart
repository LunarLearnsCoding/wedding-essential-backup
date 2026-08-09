import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/review_model.dart';
import '../../services/admin_service.dart';
import 'admin_vendor_reviews_screen.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_search_bar.dart';

/// Displays the admin reviews page and coordinates the actions available on it.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search vendors by business name',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('reviews'),
            builder: (context, reviewSnapshot) {
              if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (reviewSnapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load reviews',
                  message: reviewSnapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              return StreamBuilder(
                stream: widget.service.plainCollectionStream('vendors'),
                builder: (context, vendorSnapshot) {
                  if (vendorSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final vendorInfo = <String, _VendorInfo>{};
                  for (final doc in vendorSnapshot.data?.docs ?? []) {
                    final data = doc.data();
                    final fallbackName = data['name']?.toString().trim() ?? '';
                    final businessName =
                        data['businessName']?.toString().trim() ?? '';
                    vendorInfo[doc.id] = _VendorInfo(
                      id: doc.id,
                      name: businessName.isNotEmpty
                          ? businessName
                          : fallbackName.isNotEmpty
                          ? fallbackName
                          : 'Vendor',
                    );
                  }

                  final reviewsByVendor = <String, List<ReviewModel>>{};
                  for (final doc in reviewSnapshot.data?.docs ?? []) {
                    final review = ReviewModel.fromMap(doc.id, doc.data());
                    if (review.vendorId.isEmpty) continue;
                    reviewsByVendor
                        .putIfAbsent(review.vendorId, () => [])
                        .add(review);
                  }

                  final cards =
                      reviewsByVendor.entries
                          .map((entry) {
                            final info =
                                vendorInfo[entry.key] ??
                                _VendorInfo(
                                  id: entry.key,
                                  name: 'Unknown vendor',
                                );
                            return _VendorReviewSummary(
                              info: info,
                              reviews: entry.value,
                            );
                          })
                          .where((summary) {
                            return AdminHelpers.matchesValues(_search, [
                              summary.info.name,
                            ]);
                          })
                          .toList()
                        ..sort(
                          (a, b) => a.info.name.toLowerCase().compareTo(
                            b.info.name.toLowerCase(),
                          ),
                        );

                  if (cards.isEmpty) {
                    return const AdminEmptyState(
                      title: 'No vendor reviews found',
                      message: 'Vendors with customer reviews appear here.',
                      icon: Icons.star_border_rounded,
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisExtent: 132,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final summary = cards[index];
                      return _VendorReviewCard(
                        summary: summary,
                        onTap: () => _openVendorReviews(summary),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Opens the vendor reviews interface for the user.
  void _openVendorReviews(_VendorReviewSummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVendorReviewsScreen(
          vendorId: summary.info.id,
          vendorName: summary.info.name,
        ),
      ),
    );
  }
}

/// Groups the data and behavior required by the vendor info component.
class _VendorInfo {
  final String id;
  final String name;

  const _VendorInfo({required this.id, required this.name});
}

/// Groups the data and behavior required by the vendor review summary component.
class _VendorReviewSummary {
  final _VendorInfo info;
  final List<ReviewModel> reviews;

  const _VendorReviewSummary({required this.info, required this.reviews});

  double get average => reviews.isEmpty
      ? 0
      : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
            reviews.length;
}

/// Renders the reusable vendor review card UI component.
class _VendorReviewCard extends StatelessWidget {
  const _VendorReviewCard({required this.summary, required this.onTap});

  final _VendorReviewSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminAppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminAppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminAppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  summary.info.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AdminAppColors.primaryDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminAppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AdminAppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          summary.average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AdminAppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          '|',
                          style: TextStyle(color: AdminAppColors.border),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            '${summary.reviews.length} ${summary.reviews.length == 1 ? 'review' : 'reviews'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminAppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminAppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
