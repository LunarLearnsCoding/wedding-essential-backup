import 'dart:async';
import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  StreamSubscription? _reviewSubscription;

  List<ReviewModel> _reviews = [];

  List<ReviewModel> get reviews => _reviews;

  void loadServiceReviews(String serviceId) {
    _reviewSubscription?.cancel();
    _reviewSubscription = _reviewService.getReviewsByService(serviceId).listen((
      data,
    ) {
      _reviews = data;
      notifyListeners();
    });
  }

  Future<void> deleteReview(String reviewId, ReviewModel review) async {
    await _reviewService.deleteReview(
      reviewId: reviewId,
      serviceId: review.serviceId,
      vendorId: review.vendorId,
    );
  }

  @override
  void dispose() {
    _reviewSubscription?.cancel();
    super.dispose();
  }
}
