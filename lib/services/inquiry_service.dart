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

  Stream<InquiryModel?> watchInquiry(String inquiryId) {
    return _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return InquiryModel.fromMap(snapshot.id, data);
        });
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

  Stream<List<InquiryModel>> getCustomerInquiries(String customerId) {
    return _firestore
        .collection(FirestoreCollections.inquiries)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final inquiries = snapshot.docs
              .map((doc) => InquiryModel.fromMap(doc.id, doc.data()))
              .toList();
          inquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return inquiries;
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
    final inquiryReference = _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId);
    InquiryModel? currentInquiry;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inquiryReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('This inquiry no longer exists.');
      }

      final currentStatus = inquiryStatusFromString(
        data['status']?.toString() ?? '',
      );
      switch (currentStatus) {
        case InquiryStatus.cancelled:
          throw StateError(
            'This inquiry was cancelled by the customer and cannot be replied to.',
          );
        case InquiryStatus.closed:
          throw StateError('This inquiry is closed and cannot be replied to.');
        case InquiryStatus.replied:
          throw StateError('This inquiry has already been replied to.');
        case InquiryStatus.pending:
          break;
      }

      currentInquiry = InquiryModel.fromMap(snapshot.id, data);
      final now = Timestamp.now();
      transaction.update(inquiryReference, {
        'vendorReply': reply,
        'vendorReplyAt': now,
        'status': enumToString(InquiryStatus.replied),
        'updatedAt': now,
      });
    });

    await _createNotificationSafely(
      userId: currentInquiry!.customerId,
      title: 'Inquiry replied',
      message:
          'The vendor replied to your inquiry about ${currentInquiry!.serviceName}.',
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

  Future<void> cancelInquiry(InquiryModel inquiry) async {
    final inquiryReference = _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiry.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inquiryReference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw StateError('This inquiry no longer exists.');
      }

      final currentStatus = inquiryStatusFromString(
        data['status']?.toString() ?? '',
      );
      if (currentStatus == InquiryStatus.cancelled) {
        throw StateError('This inquiry has already been cancelled.');
      }
      if (currentStatus == InquiryStatus.replied) {
        throw StateError(
          'This inquiry has already been replied to and cannot be cancelled.',
        );
      }
      if (currentStatus == InquiryStatus.closed) {
        throw StateError('This inquiry is closed and cannot be cancelled.');
      }

      transaction.delete(inquiryReference);
    });
  }

  Future<void> deleteInquiry(String inquiryId) async {
    await _firestore
        .collection(FirestoreCollections.inquiries)
        .doc(inquiryId)
        .delete();
  }
}
