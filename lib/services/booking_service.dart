import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking(BookingModel booking) async {
    await _firestore
        .collection(FirestoreCollections.bookings)
        .add(booking.toMap());
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
    await _updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.confirmed,
    );
  }

  Future<void> rejectBooking(String bookingId) async {
    await _updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.rejected,
    );
  }

  Future<void> completeBooking(String bookingId) async {
    await _updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.completed,
    );
  }

  Future<void> _updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .update({
      'status': enumToString(status),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteBooking(String bookingId) async {
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .delete();
  }
}