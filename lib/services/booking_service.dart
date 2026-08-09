import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

/// Centralizes the Firebase operations used for booking data.
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Creates a new item from the supplied or entered values.
  Future<void> createBooking(
    BookingModel booking, {
    Map<String, dynamic> additionalData = const {},
  }) async {
    await _firestore.collection(FirestoreCollections.bookings).add({
      ...booking.toMap(),
      ...additionalData,
    });

    await _createNotificationSafely(
      userId: booking.vendorId,
      title: 'New booking request',
      message:
          '${booking.customerName} requested a booking for ${booking.serviceName}.',
      type: 'booking',
    );
    await _createNotificationSafely(
      userId: booking.customerId,
      title: 'Booking request submitted',
      message:
          'Your booking request for ${booking.serviceName} has been submitted. Please wait for the vendor\'s response.',
      type: 'booking',
    );
  }

  Future<bool> hasActiveBookingForSlot({
    required String serviceId,
    required DateTime eventDate,
  }) async {
    final normalizedEventDate = _normalizeBookingDateTime(eventDate);

    final snapshot = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('serviceId', isEqualTo: serviceId)
        .where('eventDate', isEqualTo: Timestamp.fromDate(normalizedEventDate))
        .where(
          'status',
          whereIn: [
            enumToString(BookingStatus.pending),
            enumToString(BookingStatus.confirmed),
          ],
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return BookingModel.fromMap(doc.id, data);
  }

  Stream<List<BookingModel>> getCustomerBookings(String customerId) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .asyncMap(_removeOrphanedBookings);
  }

  Stream<List<BookingModel>> getVendorBookings(String vendorId) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .asyncMap(_removeOrphanedBookings);
  }

  Stream<List<BookingModel>> getVendorBookingsByStatus({
    required String vendorId,
    required BookingStatus status,
  }) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: enumToString(status))
        .snapshots()
        .asyncMap(_removeOrphanedBookings);
  }

  Future<List<BookingModel>> _removeOrphanedBookings(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (snapshot.docs.isEmpty) return const [];

    final serviceIds = snapshot.docs
        .map((doc) => (doc.data()['serviceId'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final vendorIds = snapshot.docs
        .map((doc) => (doc.data()['vendorId'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    try {
      final serviceSnapshots = await Future.wait(
        serviceIds.map(
          (id) => _firestore
              .collection(FirestoreCollections.services)
              .doc(id)
              .get(),
        ),
      );
      final vendorSnapshots = await Future.wait(
        vendorIds.map(
          (id) =>
              _firestore.collection(FirestoreCollections.vendors).doc(id).get(),
        ),
      );
      final existingServices = serviceSnapshots
          .where((doc) => doc.exists)
          .map((doc) => doc.id)
          .toSet();
      final existingVendors = vendorSnapshots
          .where((doc) => doc.exists)
          .map((doc) => doc.id)
          .toSet();

      final valid = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final orphaned = <DocumentReference<Map<String, dynamic>>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final serviceId = (data['serviceId'] ?? '').toString().trim();
        final vendorId = (data['vendorId'] ?? '').toString().trim();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        final vendorExists = existingVendors.contains(vendorId);
        final serviceExists = existingServices.contains(serviceId);
        final preserveCompletedHistory =
            status == enumToString(BookingStatus.completed) && vendorExists;
        if (vendorExists && (serviceExists || preserveCompletedHistory)) {
          valid.add(doc);
        } else {
          orphaned.add(doc.reference);
        }
      }

      if (orphaned.isNotEmpty) {
        try {
          await _deleteBookingReferences(orphaned);
        } catch (error, stackTrace) {
          debugPrint('Could not delete orphaned booking documents: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      return valid
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('Could not clean orphaned bookings: $error');
      debugPrintStack(stackTrace: stackTrace);
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList();
    }
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> _deleteBookingReferences(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    for (var offset = 0; offset < references.length; offset += 500) {
      final end = (offset + 500).clamp(0, references.length);
      final batch = _firestore.batch();
      for (final reference in references.sublist(offset, end)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.confirmed,
    );
  }

  Future<void> rejectBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.rejected,
    );
  }

  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.completed,
    );
  }

  /// Applies the requested booking status change and refreshes state.
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final bookingReference = _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId);
    BookingModel? booking;

    final statusChanged = await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('Booking not found.');
      }

      booking = BookingModel.fromMap(snapshot.id, data);
      if (booking!.status == status) {
        return false;
      }

      transaction.update(bookingReference, {
        'status': enumToString(status),
        'updatedAt': Timestamp.now(),
      });
      return true;
    });

    if (!statusChanged || booking == null) return;

    final notification = switch (status) {
      BookingStatus.confirmed => (
        title: 'Booking confirmed',
        message: 'Your booking for ${booking!.serviceName} has been confirmed.',
      ),
      BookingStatus.rejected => (
        title: 'Booking rejected',
        message: 'Your booking for ${booking!.serviceName} has been rejected.',
      ),
      BookingStatus.completed => (
        title: 'Booking completed',
        message:
            'Your booking for ${booking!.serviceName} has been marked as completed.',
      ),
      _ => null,
    };

    if (notification != null) {
      await _createNotificationSafely(
        userId: booking!.customerId,
        title: notification.title,
        message: notification.message,
        type: 'booking',
      );
    }
  }

  Future<void> cancelBooking(BookingModel booking) async {
    final bookingReference = _firestore
        .collection(FirestoreCollections.bookings)
        .doc(booking.id);
    BookingModel? currentBooking;

    final statusChanged = await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('Booking not found.');
      }

      currentBooking = BookingModel.fromMap(snapshot.id, data);
      if (currentBooking!.status == BookingStatus.cancelled) {
        return false;
      }
      if (currentBooking!.status != BookingStatus.pending) {
        return false;
      }

      transaction.update(bookingReference, {
        'status': enumToString(BookingStatus.cancelled),
        'updatedAt': Timestamp.now(),
      });
      return true;
    });

    if (!statusChanged || currentBooking == null) return;

    await _createNotificationSafely(
      userId: currentBooking!.vendorId,
      title: 'Booking cancelled',
      message:
          '${currentBooking!.customerName} cancelled ${currentBooking!.serviceName}.',
      type: 'booking',
    );
  }

  /// Creates a new item from the supplied or entered values.
  Future<void> _createNotificationSafely({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    if (userId.trim().isEmpty) return;

    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to create booking notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

DateTime _normalizeBookingDateTime(DateTime dateTime) {
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    dateTime.minute,
  );
}
