import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingVendors() {
    return _firestore
        .collection(FirestoreCollections.vendors)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getApprovedVendors() {
    return _firestore
        .collection(FirestoreCollections.vendors)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  Stream<QuerySnapshot> getRejectedVendors() {
    return _firestore
        .collection(FirestoreCollections.vendors)
        .where('approvalStatus', isEqualTo: 'rejected')
        .snapshots();
  }

  Future<void> approveVendor(String vendorId, String adminId) async {
    final batch = _firestore.batch();

    final vendorRef = _firestore
        .collection(FirestoreCollections.vendors)
        .doc(vendorId);

    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(vendorId);

    batch.update(vendorRef, {
      'isApproved': true,
      'approvalStatus': 'approved',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectVendor(String vendorId, String adminId) async {
    final batch = _firestore.batch();

    final vendorRef = _firestore
        .collection(FirestoreCollections.vendors)
        .doc(vendorId);

    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(vendorId);

    batch.update(vendorRef, {
      'isApproved': false,
      'approvalStatus': 'rejected',
      'rejectedBy': adminId,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
