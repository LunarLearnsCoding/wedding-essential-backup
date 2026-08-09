import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';

/// Displays the vendor reviews page and coordinates the actions available on it.
class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({super.key});

  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  final ReviewService _reviewService = ReviewService();

  double _averageRating(List<_ReviewItem> reviews) {
    if (reviews.isEmpty) return 0;

    final totalRating = reviews.fold<double>(
      0.0,
      (sum, review) => sum + review.rating,
    );

    return totalRating / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ReviewModel>>(
        stream: _reviewService.getReviewsForVendor(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load reviews: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews =
              (snapshot.data ?? []).map(_ReviewItem.fromModel).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              const _ReviewsHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RatingSummaryCard(
                        averageRating: _averageRating(reviews),
                        reviewCount: reviews.length,
                      ),

                      const SizedBox(height: 28),

                      _SectionHeader(
                        title: 'Customer Reviews',
                        actionText: '${reviews.length} reviews',
                      ),

                      const SizedBox(height: 14),

                      if (reviews.isEmpty)
                        const _EmptyReviewsCard()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final review = reviews[index];

                            return _ReviewCard(review: review);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Renders the reusable reviews header UI component.
class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader();

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
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Reviews',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable rating summary card UI component.
class _RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int reviewCount;

  const _RatingSummaryCard({
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 38,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: List.generate(5, (index) {
                    return const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 17,
                    );
                  }),
                ),

                const SizedBox(height: 5),

                Text(
                  '$reviewCount customer reviews',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable section header UI component.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

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
        Text(
          actionText,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Renders the reusable review card UI component.
class _ReviewCard extends StatelessWidget {
  final _ReviewItem review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(text: review.avatar),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          review.date,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      review.service,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 17,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            review.comment,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable avatar UI component.
class _Avatar extends StatelessWidget {
  final String text;

  const _Avatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.selectedSurface,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Renders the reusable empty reviews card UI component.
class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.star_border_rounded, color: AppColors.primary, size: 38),
          SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Customer feedback will appear here after completed bookings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Groups the data and behavior required by the review item component.
class _ReviewItem {
  final String customerName;
  final String service;
  final String comment;
  final double rating;
  final String date;
  final DateTime createdAt;
  final String avatar;

  const _ReviewItem({
    required this.customerName,
    required this.service,
    required this.comment,
    required this.rating,
    required this.date,
    required this.createdAt,
    required this.avatar,
  });

  factory _ReviewItem.fromModel(ReviewModel review) {
    final customerName = review.customerName.trim().isEmpty
        ? 'Customer'
        : review.customerName.trim();

    return _ReviewItem(
      customerName: customerName,
      service: review.serviceName.trim().isEmpty
          ? 'Service'
          : review.serviceName.trim(),
      comment: review.reviewText.trim().isEmpty
          ? 'No review text added.'
          : review.reviewText.trim(),
      rating: review.rating.clamp(0, 5),
      date: DateFormat('MMM dd').format(review.createdAt),
      createdAt: review.createdAt,
      avatar: customerName.substring(0, 1).toUpperCase(),
    );
  }
}
