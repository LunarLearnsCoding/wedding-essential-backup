import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/inquiry_model.dart';
import 'notification_service.dart';

class InquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> createInquiry(
    InquiryModel inquiry, {
    Map<String, dynamic> additionalData = const {},
  }) async {
    await _firestore.collection(FirestoreCollections.inquiries).add({
      ...inquiry.toMap(),
      ...additionalData,
    });

    await _createNotificationSafely(
      userId: inquiry.vendorId,
      title: 'New inquiry',
      message:
          '${inquiry.customerName} sent an inquiry about ${inquiry.serviceName}.',
    );
  }

  Future<InquiryModel?> getInquiry(String inquiryId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return InquiryModel.fromMap(doc.id, data);
  }

  Stream<List<InquiryModel>> getVendorInquiries(String vendorId) {
    return _firestore
        .collection(FirestoreCollections.inquiries)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return InquiryModel.fromMap(doc.id, doc.data());
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> replyToInquiry({
    required String inquiryId,
    required String reply,
  }) async {
    final inquiry = await getInquiry(inquiryId);
    if (inquiry == null) {
      throw StateError('Inquiry not found.');
    }

    await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .update({
          'vendorReply': reply,
          'vendorReplyAt': FieldValue.serverTimestamp(),
          'status': enumToString(InquiryStatus.replied),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    await _createNotificationSafely(
      userId: inquiry.customerId,
      title: 'Inquiry replied',
      message:
          'The vendor replied to your inquiry about ${inquiry.serviceName}.',
    );
  }

  Future<void> _createNotificationSafely({
    required String userId,
    required String title,
    required String message,
  }) async {
    if (userId.trim().isEmpty) return;

    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'inquiry',
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to create inquiry notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> closeInquiry(String inquiryId) async {
    await updateInquiryStatus(
      inquiryId: inquiryId,
      status: InquiryStatus.closed,
    );
  }

  Future<void> deleteInquiry(String inquiryId) async {
    await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .delete();
  }
}
