import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<BookingModel>> getVendorBookings(String vendorId) {
    return _firestore
        .collection(FirestoreCollections.bookings)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.id, doc.data());
          }).toList();
        });
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
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.id, doc.data());
          }).toList();
        });
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

  Future<void> deleteBooking(String bookingId) async {
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .delete();
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
