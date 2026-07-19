import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';

class AdminVendorReviewsScreen extends StatelessWidget {
  final String vendorId;
  final String vendorName;

  const AdminVendorReviewsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();
    return Scaffold(
      backgroundColor: AdminAppColors.background,
      appBar: AppBar(
        title: Text('$vendorName Reviews'),
        backgroundColor: AdminAppColors.surface,
        foregroundColor: AdminAppColors.textPrimary,
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: reviewService.getAllReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AdminEmptyState(
              title: 'Unable to load reviews',
              message: snapshot.error.toString(),
              icon: Icons.error_outline,
            );
          }
          final reviews =
              (snapshot.data ?? const <ReviewModel>[])
                  .where((review) => review.vendorId == vendorId)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (reviews.isEmpty) {
            return const AdminEmptyState(
              title: 'No reviews found',
              message: 'This vendor has no customer reviews.',
              icon: Icons.star_border_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(22),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(
                number: index + 1,
                review: review,
                onDelete: () => _deleteReview(context, reviewService, review),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteReview(
    BuildContext context,
    ReviewService service,
    ReviewModel review,
  ) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Delete review?',
      message: 'This will permanently delete this customer review.',
      confirmText: 'Delete',
    );
    if (!context.mounted || !confirmed) return;
    try {
      await service.deleteReviewById(review.id, review);
      if (!context.mounted) return;
      AdminHelpers.showSnack(context, 'Review deleted');
    } catch (error) {
      if (!context.mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final ReviewModel review;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.number,
    required this.review,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminAppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminAppColors.border),
        boxShadow: [AdminAppColors.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number.', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.serviceName.isEmpty
                      ? 'Vendor review'
                      : review.serviceName,
                  style: const TextStyle(
                    color: AdminAppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  review.reviewText.isEmpty
                      ? 'No written review'
                      : review.reviewText,
                  style: const TextStyle(
                    color: AdminAppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${review.rating.toStringAsFixed(1)} ★  •  ${review.customerName.isEmpty ? 'Anonymous customer' : review.customerName}  •  ${AdminFormatters.date(review.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete review',
            color: AdminAppColors.danger,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
