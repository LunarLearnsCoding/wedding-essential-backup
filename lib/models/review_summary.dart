import 'review_model.dart';

/// Groups the data and behavior required by the review summary component.
class ReviewSummary {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  const ReviewSummary.empty() : averageRating = 0, totalReviews = 0;

  final double averageRating;
  final int totalReviews;

  factory ReviewSummary.fromReviews(Iterable<ReviewModel> reviews) {
    var totalRating = 0.0;
    var count = 0;
    for (final review in reviews) {
      if (!review.isVisible) continue;
      totalRating += review.rating;
      count++;
    }
    return ReviewSummary(
      averageRating: count == 0 ? 0 : totalRating / count,
      totalReviews: count,
    );
  }
}
