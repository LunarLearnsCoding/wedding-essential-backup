import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/guest_model.dart';

class GuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addGuest(GuestModel guest) async {
    await _firestore
        .collection(FirestoreCollections.guests)
        .add(guest.toMap());
  }

  Future<void> updateGuest(GuestModel guest) async {
    await _firestore
        .collection(FirestoreCollections.guests)
        .doc(guest.id)
        .update(guest.toMap());
  }

  Future<void> deleteGuest(String guestId) async {
    await _firestore
        .collection(FirestoreCollections.guests)
        .doc(guestId)
        .delete();
  }

  Stream<List<GuestModel>> getGuestsByCustomer(String customerId) {
    return _firestore
        .collection(FirestoreCollections.guests)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GuestModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}