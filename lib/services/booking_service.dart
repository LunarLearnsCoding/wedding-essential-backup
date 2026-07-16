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
    await _firestore
        .collection(FirestoreCollections.bookings)
        .doc(bookingId)
        .update({'status': enumToString(status), 'updatedAt': Timestamp.now()});
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
