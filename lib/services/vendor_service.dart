import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';

/// Centralizes the Firebase operations used for vendor data.
class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getApprovedVendors() {
    return _firestore
        .collection(FirestoreCollections.vendors)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }
}
