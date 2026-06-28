import 'package:cloud_firestore/cloud_firestore.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingVendors() {
    return _firestore
        .collection('vendors')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> approveVendor(String vendorId, String adminId) async {
    await _firestore.collection('vendors').doc(vendorId).update({
      'approvalStatus': 'approved',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectVendor(String vendorId, String adminId) async {
    await _firestore.collection('vendors').doc(vendorId).update({
      'approvalStatus': 'rejected',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }
}