import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_auth_service.dart';

/// Centralizes the Firebase operations used for admin data.
class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String name) {
    return _firestore.collection(name);
  }

  Stream<int> countStream(
    String collection, {
    String? field,
    Object? isEqualTo,
  }) {
    Query<Map<String, dynamic>> query = _collection(collection);
    if (field != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    return query.snapshots().map((snapshot) => snapshot.size);
  }

  Stream<int> customerCountStream() {
    return _collection('users').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final role = (doc.data()['role'] ?? '').toString().toLowerCase();
        return role.isEmpty || role == 'customer' || role == 'user';
      }).length;
    });
  }

  Future<int> removeLegacyCustomerAddresses() async {
    final snapshot = await _collection('customers').get();
    final documents = snapshot.docs
        .where((document) => document.data().containsKey('address'))
        .toList();
    for (var start = 0; start < documents.length; start += 400) {
      final batch = _firestore.batch();
      final end = start + 400 < documents.length
          ? start + 400
          : documents.length;
      for (final document in documents.sublist(start, end)) {
        batch.update(document.reference, {'address': FieldValue.delete()});
      }
      await batch.commit();
    }
    return documents.length;
  }

  Stream<int> approvedVendorCountStream() {
    return _collection('vendors').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final status = (data['approvalStatus'] ?? data['status'] ?? '')
            .toString()
            .toLowerCase();
        return data['isApproved'] == true || status == 'approved';
      }).length;
    });
  }

  Stream<int> pendingVendorCountStream() {
    return _collection('vendors').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final status = (data['approvalStatus'] ?? data['status'] ?? '')
            .toString()
            .toLowerCase();
        return data['isApproved'] != true &&
            (status.isEmpty || status == 'pending');
      }).length;
    });
  }

  Stream<int> activeServiceCountStream() {
    return _collection('services').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        return data['isActive'] != false &&
            status != 'inactive' &&
            status != 'hidden';
      }).length;
    });
  }

  Stream<int> publishedBlogCountStream() {
    return _collection('blogs').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        return (doc.data()['status'] ?? '').toString().toLowerCase() ==
            'published';
      }).length;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(
    String collection, {
    String orderBy = 'createdAt',
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _collection(
      collection,
    ).orderBy(orderBy, descending: descending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Use this fallback when a collection does not have createdAt/orderBy yet.
  Stream<QuerySnapshot<Map<String, dynamic>>> plainCollectionStream(
    String collection,
  ) {
    return _collection(collection).snapshots();
  }

  /// Applies the requested document change and refreshes state.
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    return _collection(
      collection,
    ).doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> approveVendor(String vendorId) async {
    final batch = _firestore.batch();
    final vendorRef = _collection('vendors').doc(vendorId);
    final userRef = _collection('users').doc(vendorId);
    batch.set(vendorRef, {
      'isApproved': true,
      'approvalStatus': 'approved',
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'status': 'active',
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> rejectVendor(String vendorId) async {
    final batch = _firestore.batch();
    final vendorRef = _collection('vendors').doc(vendorId);
    final userRef = _collection('users').doc(vendorId);
    batch.set(vendorRef, {
      'isApproved': false,
      'approvalStatus': 'rejected',
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'approvedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'status': 'inactive',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> suspendUser(String userId) async {
    final batch = _firestore.batch();
    final values = {
      'status': 'suspended',
      'isActive': false,
      'suspendedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(
      _collection('users').doc(userId),
      values,
      SetOptions(merge: true),
    );
    batch.set(
      _collection('customers').doc(userId),
      values,
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> activateUser(String userId) async {
    final batch = _firestore.batch();
    final values = {
      'status': 'active',
      'isActive': true,
      'suspendedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(
      _collection('users').doc(userId),
      values,
      SetOptions(merge: true),
    );
    batch.set(
      _collection('customers').doc(userId),
      values,
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteUserData(String userId) async {
    final inquirySnapshots = await Future.wait([
      _collection('inquiries').where('customerId', isEqualTo: userId).get(),
      _collection('inquiries').where('vendorId', isEqualTo: userId).get(),
    ]);
    final inquiryReferences =
        <String, DocumentReference<Map<String, dynamic>>>{};
    for (final snapshot in inquirySnapshots) {
      for (final inquiry in snapshot.docs) {
        inquiryReferences[inquiry.reference.path] = inquiry.reference;
      }
    }

    for (final inquiryReference in inquiryReferences.values) {
      await _deleteInquiryWithMessages(inquiryReference);
    }

    final profileImages = await _collection(
      'profile_images',
    ).where('userId', isEqualTo: userId).get();
    for (final image in profileImages.docs) {
      await image.reference.delete();
    }

    final batch = _firestore.batch();
    batch.delete(_collection('users').doc(userId));
    batch.delete(_collection('customers').doc(userId));
    batch.delete(_collection('vendors').doc(userId));
    batch.delete(_collection('public_profiles').doc(userId));
    await batch.commit();
  }

  Future<int> cleanupOrphanedInquiries() async {
    final snapshots = await Future.wait([
      _collection('users').get(),
      _collection('inquiries').get(),
    ]);
    final userIds = snapshots.first.docs.map((document) => document.id).toSet();
    final orphanedInquiries = snapshots.last.docs.where((inquiry) {
      final data = inquiry.data();
      final customerId = data['customerId']?.toString().trim() ?? '';
      final vendorId = data['vendorId']?.toString().trim() ?? '';
      return customerId.isEmpty ||
          vendorId.isEmpty ||
          !userIds.contains(customerId) ||
          !userIds.contains(vendorId);
    }).toList();

    for (final inquiry in orphanedInquiries) {
      await _deleteInquiryWithMessages(inquiry.reference);
    }
    return orphanedInquiries.length;
  }

  Future<int> cleanupOrphanedProfileImages() async {
    final snapshots = await Future.wait([
      _collection('users').get(),
      _collection('profile_images').get(),
    ]);
    final userIds = snapshots.first.docs.map((document) => document.id).toSet();
    final orphanedImages = snapshots.last.docs.where((image) {
      final ownerId = image.data()['userId']?.toString().trim() ?? '';
      return ownerId.isEmpty || !userIds.contains(ownerId);
    }).toList();

    for (final image in orphanedImages) {
      await image.reference.delete();
    }
    return orphanedImages.length;
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> _deleteInquiryWithMessages(
    DocumentReference<Map<String, dynamic>> inquiryReference,
  ) async {
    final messages = await inquiryReference.collection('messages').get();
    for (final message in messages.docs) {
      await message.reference.delete();
    }
    await inquiryReference.delete();
  }

  /// Applies the requested service status change and refreshes state.
  Future<void> updateServiceStatus(String serviceId, bool isActive) {
    return updateDocument('services', serviceId, {
      'isActive': isActive,
      'status': isActive ? 'active' : 'hidden',
      'averageRating': FieldValue.delete(),
      'totalReviews': FieldValue.delete(),
      'isFeatured': FieldValue.delete(),
      'hiddenAt': FieldValue.delete(),
    });
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteService(String serviceId) async {
    final serviceRef = _collection('services').doc(serviceId);
    final snapshot = await serviceRef.get();
    final batch = _firestore.batch();
    batch.delete(serviceRef);

    final imageUrls = snapshot.data()?['imageUrls'];
    if (imageUrls is Iterable) {
      for (final value in imageUrls) {
        final source = value.toString().trim();
        const prefix = 'firestore-image://';
        if (!source.startsWith(prefix)) continue;
        final imageId = source.substring(prefix.length).trim();
        if (imageId.isEmpty || imageId.contains('/')) continue;
        batch.delete(_collection('service_images').doc(imageId));
      }
    }

    await batch.commit();
  }

  Future<void> featureVendorUntil(
    String vendorId,
    DateTime featuredUntil,
  ) async {
    final batch = _firestore.batch();
    final vendorRef = _collection('vendors').doc(vendorId);
    final notificationRef = _collection('notifications').doc();
    batch.update(vendorRef, {
      'isFeatured': true,
      'featuredAt': FieldValue.serverTimestamp(),
      'featuredUntil': Timestamp.fromDate(featuredUntil),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(notificationRef, {
      'userId': vendorId,
      'title': 'Your business is now featured',
      'message':
          'Your vendor profile will appear in Featured Vendors until ${featuredUntil.year}-${featuredUntil.month.toString().padLeft(2, '0')}-${featuredUntil.day.toString().padLeft(2, '0')}.',
      'type': 'featured',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> extendFeaturedVendorTime(String vendorId, int days) async {
    if (days < 1 || days > 30) {
      throw RangeError.range(days, 1, 30, 'days');
    }

    final vendorRef = _collection('vendors').doc(vendorId);
    final notificationRef = _collection('notifications').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(vendorRef);
      final data = snapshot.data();
      if (data == null || data['isFeatured'] != true) {
        throw StateError('This vendor is no longer featured.');
      }

      final now = DateTime.now();
      final currentValue = data['featuredUntil'];
      final currentExpiration = currentValue is Timestamp
          ? currentValue.toDate()
          : null;
      final extensionStart =
          currentExpiration != null && currentExpiration.isAfter(now)
          ? currentExpiration
          : now;
      final featuredUntil = extensionStart.add(Duration(days: days));

      transaction.update(vendorRef, {
        'featuredUntil': Timestamp.fromDate(featuredUntil),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notificationRef, {
        'userId': vendorId,
        'title': 'Featured placement updated',
        'message':
            'Your Featured Vendors placement was extended by $days ${days == 1 ? 'day' : 'days'} and will remain active until ${featuredUntil.year}-${featuredUntil.month.toString().padLeft(2, '0')}-${featuredUntil.day.toString().padLeft(2, '0')}.',
        'type': 'featured',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> removeFeaturedVendor(String vendorId) async {
    final batch = _firestore.batch();
    final vendorRef = _collection('vendors').doc(vendorId);
    final notificationRef = _collection('notifications').doc();
    batch.update(vendorRef, {
      'isFeatured': false,
      'featuredAt': null,
      'featuredUntil': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(notificationRef, {
      'userId': vendorId,
      'title': 'Featured placement removed',
      'message':
          'Your Featured Vendors placement was removed by the admin. Contact the admin if you need more information.',
      'type': 'featured',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> expireFeaturedVendor(String vendorId) async {
    final vendorRef = _collection('vendors').doc(vendorId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(vendorRef);
      final data = snapshot.data();
      if (data == null || data['isFeatured'] != true) return;
      final untilValue = data['featuredUntil'];
      if (untilValue is! Timestamp) return;
      final until = untilValue.toDate();
      if (until.isAfter(DateTime.now())) return;

      final notificationRef = _collection(
        'notifications',
      ).doc('featured-expired-$vendorId-${until.millisecondsSinceEpoch}');
      transaction.update(vendorRef, {
        'isFeatured': false,
        'featuredAt': null,
        'featuredUntil': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notificationRef, {
        'userId': vendorId,
        'title': 'Featured placement ended',
        'message':
            'Your Featured Vendors placement has expired. Contact the admin if you would like to schedule another period.',
        'type': 'featured',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Applies the requested booking status change and refreshes state.
  Future<void> updateBookingStatus(String bookingId, String status) {
    return updateDocument('bookings', bookingId, {'status': status});
  }

  /// Applies the requested blog status change and refreshes state.
  Future<void> updateBlogStatus(String blogId, String status) {
    return updateBlog(blogId, {'status': status});
  }

  /// Creates a new item from the supplied or entered values.
  Future<String> createBlog(Map<String, dynamic> data) async {
    await _ensureAdminProfile();
    final document = await _collection('blogs').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  /// Applies the requested blog change and refreshes state.
  Future<void> updateBlog(String blogId, Map<String, dynamic> data) async {
    await _ensureAdminProfile();
    await _collection('blogs').doc(blogId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteBlog(String blogId) async {
    await _ensureAdminProfile();
    final blogReference = _collection('blogs').doc(blogId);
    final snapshot = await blogReference.get();
    final imageUrl = snapshot.data()?['imageUrl']?.toString() ?? '';
    final batch = _firestore.batch()..delete(blogReference);
    final imageReference = _blogImageReference(imageUrl);
    if (imageReference != null) batch.delete(imageReference);
    await batch.commit();
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> deleteBlogImage(String source) async {
    final imageReference = _blogImageReference(source);
    if (imageReference != null) await imageReference.delete();
  }

  DocumentReference<Map<String, dynamic>>? _blogImageReference(String source) {
    const prefix = 'firestore-blog-image://';
    final value = source.trim();
    if (!value.startsWith(prefix)) return null;
    final imageId = value.substring(prefix.length).trim();
    if (imageId.isEmpty || imageId.contains('/')) return null;
    return _collection('blog_images').doc(imageId);
  }

  Future<void> _ensureAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Your admin session has expired. Please sign in again.');
    }
    await AdminAuthService(firestore: _firestore).ensureAdminProfile(user);
  }
}
