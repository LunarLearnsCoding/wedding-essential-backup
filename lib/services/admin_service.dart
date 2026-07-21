import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_auth_service.dart';

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

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    return _collection(
      collection,
    ).doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteDocument(String collection, String id) {
    return _collection(collection).doc(id).delete();
  }

  Future<void> approveVendor(String vendorId) async {
    final batch = _firestore.batch();

    final vendorRef = _firestore.collection('vendors').doc(vendorId);

    final userRef = _firestore.collection('users').doc(vendorId);

    batch.set(vendorRef, {
      'isApproved': true,
      'approvalStatus': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> rejectVendor(String vendorId) async {
    final batch = _firestore.batch();

    final vendorRef = _firestore.collection('vendors').doc(vendorId);

    final userRef = _firestore.collection('users').doc(vendorId);

    batch.set(vendorRef, {
      'isApproved': false,
      'approvalStatus': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> suspendUser(String userId) {
    return updateDocument('users', userId, {'status': 'suspended'});
  }

  Future<void> activateUser(String userId) {
    return updateDocument('users', userId, {'status': 'active'});
  }

  Future<void> updateServiceStatus(String serviceId, bool isActive) {
    return updateDocument('services', serviceId, {
      'isActive': isActive,
      'status': isActive ? 'active' : 'inactive',
    });
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

  Future<void> updateBookingStatus(String bookingId, String status) {
    return updateDocument('bookings', bookingId, {'status': status});
  }

  Future<void> updateBlogStatus(String blogId, String status) {
    return updateBlog(blogId, {'status': status});
  }

  Future<String> createBlog(Map<String, dynamic> data) async {
    await _ensureAdminProfile();
    final document = await _collection('blogs').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateBlog(String blogId, Map<String, dynamic> data) async {
    await _ensureAdminProfile();
    await _collection('blogs').doc(blogId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Your admin session has expired. Please sign in again.');
    }
    await AdminAuthService(firestore: _firestore).ensureAdminProfile(user);
  }
}
