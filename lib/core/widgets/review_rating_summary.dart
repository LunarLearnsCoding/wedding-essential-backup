import 'package:flutter/material.dart';

import '../../models/review_model.dart';
import '../../models/review_summary.dart';
import '../../services/review_service.dart';
import '../constants/app_colors.dart';

/// Renders the reusable review rating summary UI component.
class ReviewRatingSummary extends StatefulWidget {
  const ReviewRatingSummary.vendor({
    super.key,
    required String vendorId,
    this.showReviewLabel = false,
    this.textStyle,
  }) : _id = vendorId,
       _isVendor = true;

  const ReviewRatingSummary.service({
    super.key,
    required String serviceId,
    this.showReviewLabel = false,
    this.textStyle,
  }) : _id = serviceId,
       _isVendor = false;

  final String _id;
  final bool _isVendor;
  final bool showReviewLabel;
  final TextStyle? textStyle;

  @override
  State<ReviewRatingSummary> createState() => _ReviewRatingSummaryState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _ReviewRatingSummaryState extends State<ReviewRatingSummary> {
  static final ReviewService _reviewService = ReviewService();
  late Stream<List<ReviewModel>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = _reviewStream();
  }

  @override
  void didUpdateWidget(covariant ReviewRatingSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._id != widget._id ||
        oldWidget._isVendor != widget._isVendor) {
      _reviews = _reviewStream();
    }
  }

  Stream<List<ReviewModel>> _reviewStream() {
    return widget._isVendor
        ? _reviewService.getReviewsByVendor(widget._id)
        : _reviewService.getReviewsByService(widget._id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviews,
      builder: (context, snapshot) {
        final summary = ReviewSummary.fromReviews(
          snapshot.data ?? const <ReviewModel>[],
        );
        final label = widget.showReviewLabel
            ? '${summary.totalReviews} '
                  '${summary.totalReviews == 1 ? 'review' : 'reviews'}'
            : summary.totalReviews.toString();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 17),
            Flexible(
              child: Text(
                ' ${summary.averageRating.toStringAsFixed(1)} ($label)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    widget.textStyle ??
                    const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}
