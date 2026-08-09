import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../core/utils/firestore_parsers.dart';
import '../models/app_enums.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';

/// Centralizes the Firebase operations used for review data.
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _serviceNameCache = {};

  /// Validates the form and submits its current values.
  Future<void> submitBookingReview({
    required BookingModel booking,
    required double rating,
    required String reviewText,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final trimmedReviewText = reviewText.trim();

    if (user == null) throw StateError('Please sign in to submit a review.');
    if (booking.id.trim().isEmpty) {
      throw StateError('This booking cannot be reviewed.');
    }
    if (user.uid != booking.customerId) {
      throw StateError('You can only review your own booking.');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('Please select a rating from 1 to 5.');
    }
    if (trimmedReviewText.length < 5) {
      throw StateError('Review text must be at least 5 characters.');
    }
    if (trimmedReviewText.length > 500) {
      throw StateError('Review text cannot exceed 500 characters.');
    }
    if (booking.status != BookingStatus.completed) {
      throw StateError('Only completed bookings can be reviewed.');
    }

    final bookingReference = _firestore
        .collection(FirestoreCollections.bookings)
        .doc(booking.id);
    final reviewReference = _firestore
        .collection(FirestoreCollections.reviews)
        .doc(booking.id);
    String vendorIdForRating = booking.vendorId;
    var serviceNameForReview = '';

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingReference);
      final bookingData = bookingSnapshot.data();
      if (!bookingSnapshot.exists || bookingData == null) {
        throw StateError('This booking no longer exists.');
      }

      final latestBooking = BookingModel.fromMap(
        bookingSnapshot.id,
        bookingData,
      );
      if (latestBooking.customerId != user.uid) {
        throw StateError('You can only review your own booking.');
      }
      if (latestBooking.status != BookingStatus.completed) {
        throw StateError('Only completed bookings can be reviewed.');
      }

      final reviewSnapshot = await transaction.get(reviewReference);
      if (reviewSnapshot.exists) {
        throw StateError('You have already reviewed this booking.');
      }

      var serviceName = latestBooking.serviceName.trim();
      if (serviceName.isEmpty && latestBooking.serviceId.trim().isNotEmpty) {
        final serviceReference = _firestore
            .collection(FirestoreCollections.services)
            .doc(latestBooking.serviceId);
        final serviceSnapshot = await transaction.get(serviceReference);
        serviceName = serviceSnapshot.data()?['name']?.toString().trim() ?? '';
      }
      serviceNameForReview = serviceName;
      vendorIdForRating = latestBooking.vendorId;

      transaction.set(reviewReference, {
        'bookingId': latestBooking.id,
        'serviceId': latestBooking.serviceId,
        'serviceName': serviceNameForReview,
        'vendorId': latestBooking.vendorId,
        'customerId': latestBooking.customerId,
        'customerName': latestBooking.customerName,
        'rating': rating,
        'reviewText': trimmedReviewText,
        'createdAt': Timestamp.now(),
      });
    });

    try {
      await _updateVendorRating(vendorIdForRating);
    } catch (error, stackTrace) {
      debugPrint('Failed to update vendor rating: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Stream<bool> hasReviewForBooking(String bookingId) {
    if (bookingId.trim().isEmpty) return Stream.value(false);
    return _firestore
        .collection(FirestoreCollections.reviews)
        .doc(bookingId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<ReviewModel>> getReviewsByService(String serviceId) {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .where('serviceId', isEqualTo: serviceId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
              .where((review) => review.isVisible)
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
              .where((review) => review.isVisible)
              .toList();
        });
  }

  Stream<List<ReviewModel>> getReviewsForVendor(String vendorId) {
    return getReviewsByVendor(vendorId).asyncMap((reviews) async {
      final resolvedReviews = <ReviewModel>[];
      for (final review in reviews) {
        if (review.serviceName.trim().isNotEmpty) {
          resolvedReviews.add(review);
          continue;
        }

        final serviceName = await _serviceNameForReview(review.serviceId);
        resolvedReviews.add(_reviewWithServiceName(review, serviceName));
      }
      return resolvedReviews;
    });
  }

  Future<String> _serviceNameForReview(String serviceId) async {
    final normalizedServiceId = serviceId.trim();
    if (normalizedServiceId.isEmpty) return 'Service';

    final cachedName = _serviceNameCache[normalizedServiceId];
    if (cachedName != null) return cachedName;

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.services)
          .doc(normalizedServiceId)
          .get();
      final name = snapshot.data()?['name']?.toString().trim() ?? '';
      final resolvedName = name.isEmpty ? 'Service' : name;
      _serviceNameCache[normalizedServiceId] = resolvedName;
      return resolvedName;
    } catch (error, stackTrace) {
      debugPrint('Failed to load service name for review: $error');
      debugPrintStack(stackTrace: stackTrace);
      _serviceNameCache[normalizedServiceId] = 'Service';
      return 'Service';
    }
  }

  Stream<List<ReviewModel>> getReviewsByCustomer(String customerId) {
    return _firestore
        .collection(FirestoreCollections.reviews)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
              .where((review) => review.isVisible)
              .toList();
        });
  }

  Stream<List<ReviewModel>> getAllReviews() {
    return _firestore.collection(FirestoreCollections.reviews).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteReview({
    required String reviewId,
    required String vendorId,
  }) async {
    await _firestore
        .collection(FirestoreCollections.reviews)
        .doc(reviewId)
        .delete();

    await _updateVendorRating(vendorId);
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteReviewById(String reviewId, ReviewModel review) async {
    await deleteReview(reviewId: reviewId, vendorId: review.vendorId);
  }

  /// Applies the requested vendor rating change and refreshes state.
  Future<void> _updateVendorRating(String vendorId) async {
    if (vendorId.trim().isEmpty) return;
    final snapshot = await _firestore
        .collection(FirestoreCollections.reviews)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    double totalRating = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status']?.toString().toLowerCase() == 'hidden') continue;
      totalRating += doubleFromFirestore(data['rating']);
    }

    final totalReviews = snapshot.docs
        .where(
          (doc) => doc.data()['status']?.toString().toLowerCase() != 'hidden',
        )
        .length;
    final averageRating = totalReviews == 0 ? 0.0 : totalRating / totalReviews;

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

ReviewModel _reviewWithServiceName(ReviewModel review, String serviceName) {
  return ReviewModel(
    id: review.id,
    bookingId: review.bookingId,
    serviceId: review.serviceId,
    vendorId: review.vendorId,
    customerId: review.customerId,
    customerName: review.customerName,
    serviceName: serviceName,
    rating: review.rating,
    reviewText: review.reviewText,
    vendorReplied: review.vendorReplied,
    status: review.status,
    createdAt: review.createdAt,
  );
}
