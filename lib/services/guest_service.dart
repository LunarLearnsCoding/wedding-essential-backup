import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/guest_model.dart';

class GuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addGuest(GuestModel guest) async {
    await _firestore.collection(FirestoreCollections.guests).add(guest.toMap());
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

  Stream<List<String>> getGroupsByCustomer(String customerId) {
    return _firestore
        .collection(FirestoreCollections.customers)
        .doc(customerId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.data()?['guestGroups'];
          if (groups is! Iterable) return const <String>[];
          return groups
              .map((group) => group.toString().trim())
              .where((group) => group.isNotEmpty)
              .toList();
        });
  }

  Future<void> addGroup({
    required String customerId,
    required String groupName,
  }) async {
    await _firestore
        .collection(FirestoreCollections.customers)
        .doc(customerId)
        .set({
          'guestGroups': FieldValue.arrayUnion([groupName.trim()]),
        }, SetOptions(merge: true));
  }

  Future<void> deleteGroup({
    required String customerId,
    required String groupName,
  }) async {
    final guests = await _firestore
        .collection(FirestoreCollections.guests)
        .where('customerId', isEqualTo: customerId)
        .where('relation', isEqualTo: groupName)
        .get();
    final batch = _firestore.batch();
    for (final guest in guests.docs) {
      batch.delete(guest.reference);
    }
    batch.set(
      _firestore.collection(FirestoreCollections.customers).doc(customerId),
      {
        'guestGroups': FieldValue.arrayRemove([groupName]),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
