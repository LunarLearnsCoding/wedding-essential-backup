import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(ReviewModel review) async {
    await _firestore
        .collection(FirestoreCollections.reviews)
        .add(review.toMap());

    await _updateServiceRating(review.serviceId);
    await _updateVendorRating(review.vendorId);
  }

  Future<void> addReviewFromFields({
    required String vendorId,
    required String serviceId,
    required String customerId,
    required String customerName,
    required double rating,
    required String reviewText,
  }) async {
    final review = ReviewModel(
      id: '',
      serviceId: serviceId,
      vendorId: vendorId,
      customerId: customerId,
      customerName: customerName,
      rating: rating,
      reviewText: reviewText,
      createdAt: DateTime.now(),
    );

    await addReview(review);
  }

  Stream<List<ReviewModel>> getReviewsByService(String serviceId) {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .where('serviceId', isEqualTo: serviceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<ReviewModel>> getReviewsByVendor(String vendorId) {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<ReviewModel>> getReviewsForVendor(String vendorId) {
    return getReviewsByVendor(vendorId);
  }

  Stream<List<ReviewModel>> getReviewsByCustomer(String customerId) {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<ReviewModel>> getAllReviews() {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> deleteReview({
    required String reviewId,
    required String serviceId,
    required String vendorId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.reviews)
        .doc(reviewId)
        .delete();

    await _updateServiceRating(serviceId);
    await _updateVendorRating(vendorId);
  }

  Future<void> deleteReviewById(
    String reviewId,
    ReviewModel review,
  ) async {
    await deleteReview(
      reviewId: reviewId,
      serviceId: review.serviceId,
      vendorId: review.vendorId,
    );
  }

  Future<void> _updateServiceRating(String serviceId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.reviews)
        .where('serviceId', isEqualTo: serviceId)
        .get();

    double totalRating = 0;

    for (final doc in snapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0).toDouble();
    }

    final totalReviews = snapshot.docs.length;
    final averageRating =
        totalReviews == 0 ? 0.0 : totalRating / totalReviews;

    await _firestore
        .collection(FirestoreCollections.services)
        .doc(serviceId)
        .update({
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _updateVendorRating(String vendorId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.reviews)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    double totalRating = 0;

    for (final doc in snapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0).toDouble();
    }

    final totalReviews = snapshot.docs.length;
    final averageRating =
        totalReviews == 0 ? 0.0 : totalRating / totalReviews;

    await _firestore
        .collection(FirestoreCollections.vendors)
        .doc(vendorId)
        .update({
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'updatedAt': Timestamp.now(),
    });
  }
}