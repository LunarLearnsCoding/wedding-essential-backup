import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/inquiry_model.dart';

class InquiryService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> createInquiry(
    InquiryModel inquiry,
  ) async {
    await _firestore
        .collection(FirestoreCollections.inquiries)
        .add(inquiry.toMap());
  }

  Stream<List<InquiryModel>> getVendorInquiries(
    String vendorId,
  ) {
    return _firestore
        .collection(FirestoreCollections.inquiries)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return InquiryModel.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  Future<void> updateInquiryStatus({
    required String inquiryId,
    required InquiryStatus status,
  }) async {
    await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .update({
      'status': enumToString(status),
    });
  }

  Future<void> deleteInquiry(
    String inquiryId,
  ) async {
    await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .delete();
  }
}