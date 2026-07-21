import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../models/app_enums.dart';
import '../models/inquiry_message_model.dart';
import '../models/inquiry_model.dart';
import 'notification_service.dart';

class InquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _inquiries =>
      _firestore.collection(FirestoreCollections.inquiries);

  Future<String> createInquiry(
    InquiryModel inquiry, {
    Map<String, dynamic> additionalData = const {},
  }) async {
    final inquiryReference = _inquiries.doc();
    final messageReference = inquiryReference.collection('messages').doc();
    final now = Timestamp.now();
    final message = inquiry.message.trim();
    final batch = _firestore.batch();

    batch.set(inquiryReference, {
      ...inquiry.toMap(),
      ...additionalData,
      'status': enumToString(InquiryStatus.pending),
      'isRealtimeChat': true,
      'unreadForCustomer': false,
      'unreadForVendor': true,
      'lastMessage': message,
      'lastMessageAt': now,
      'updatedAt': now,
    });
    batch.set(messageReference, {
      'senderId': inquiry.customerId,
      'senderName': inquiry.customerName,
      'senderEmail': inquiry.customerEmail,
      'text': message,
      'createdAt': now,
    });

    await batch.commit();
    await _createNotificationSafely(
      userId: inquiry.vendorId,
      title: 'New inquiry chat',
      message:
          '${inquiry.customerName} started a chat about ${inquiry.serviceName}.',
    );
    return inquiryReference.id;
  }

  Stream<InquiryModel?> watchInquiry(String inquiryId) {
    return _inquiries.doc(inquiryId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return InquiryModel.fromMap(snapshot.id, data);
    });
  }

  Stream<List<InquiryMessageModel>> watchMessages(String inquiryId) {
    return _inquiries
        .doc(inquiryId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    InquiryMessageModel.fromMap(document.id, document.data()),
              )
              .toList(),
        );
  }

  Stream<List<InquiryModel>> getVendorInquiries(String vendorId) {
    return _inquiries
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => _sortedInquiries(snapshot.docs));
  }

  Stream<List<InquiryModel>> getCustomerInquiries(String customerId) {
    return _inquiries
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => _sortedInquiries(snapshot.docs));
  }

  List<InquiryModel> _sortedInquiries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final inquiries = documents
        .map((document) => InquiryModel.fromMap(document.id, document.data()))
        .where((inquiry) => inquiry.status != InquiryStatus.cancelled)
        .toList();
    inquiries.sort(
      (a, b) => (b.lastMessageAt ?? b.updatedAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.updatedAt ?? a.createdAt,
      ),
    );
    return inquiries;
  }

  Future<void> sendMessage({
    required String inquiryId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final inquiryReference = _inquiries.doc(inquiryId);
    final snapshot = await inquiryReference.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('This chat no longer exists.');
    }

    final inquiry = InquiryModel.fromMap(snapshot.id, data);
    if (senderId != inquiry.customerId && senderId != inquiry.vendorId) {
      throw StateError('You are not a participant in this chat.');
    }
    final now = Timestamp.now();
    final messageReference = inquiryReference.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(messageReference, {
      'senderId': senderId,
      'senderName': senderName.trim(),
      'senderEmail': senderEmail.trim(),
      'text': cleanText,
      'createdAt': now,
    });
    batch.update(inquiryReference, {
      'lastMessage': cleanText,
      'lastMessageAt': now,
      'updatedAt': now,
      'status': enumToString(InquiryStatus.pending),
      'closedAt': FieldValue.delete(),
      'unreadForCustomer': senderId == inquiry.vendorId,
      'unreadForVendor': senderId == inquiry.customerId,
    });
    await batch.commit();

    final recipientId = senderId == inquiry.customerId
        ? inquiry.vendorId
        : inquiry.customerId;
    await _createNotificationSafely(
      userId: recipientId,
      title: 'New chat message',
      message: '${senderName.trim()} sent you a message.',
    );
  }

  Future<void> markChatRead({
    required String inquiryId,
    required bool isVendor,
  }) async {
    await _inquiries.doc(inquiryId).update({
      isVendor ? 'unreadForVendor' : 'unreadForCustomer': false,
    });
  }

  Future<void> repairCustomerIdentity({
    required String customerId,
    required String customerName,
    required String customerEmail,
  }) async {
    final name = customerName.trim();
    if (name.isEmpty) return;

    try {
      final snapshot = await _inquiries
          .where('customerId', isEqualTo: customerId)
          .get();
      final batch = _firestore.batch();
      var hasUpdates = false;
      for (final document in snapshot.docs) {
        final data = document.data();
        final savedName = data['customerName']?.toString().trim() ?? '';
        final savedEmail = data['customerEmail']?.toString().trim() ?? '';
        final invalidName =
            savedName.isEmpty ||
            savedName.toLowerCase() == 'customer' ||
            savedName.contains('@');
        if (invalidName || savedEmail.isEmpty) {
          batch.update(document.reference, {
            'customerName': name,
            'customerEmail': customerEmail.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
        }
      }
      if (hasUpdates) await batch.commit();
    } on FirebaseException catch (error) {
      debugPrint('Failed to repair chat customer identity: $error');
    }
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
      debugPrint('Failed to create chat notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
