import 'package:cloud_firestore/cloud_firestore.dart';

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

  Stream<double> revenueStream() {
    return _collection('bookings').snapshots().map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final isCompleted = status == 'completed' || status == 'paid';
        if (!isCompleted) continue;

        final rawAmount =
            data['totalAmount'] ?? data['amount'] ?? data['price'];
        if (rawAmount is num) {
          total += rawAmount.toDouble();
        } else if (rawAmount is String) {
          total += double.tryParse(rawAmount) ?? 0;
        }
      }
      return total;
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

  Future<void> featureVendorUntil(String vendorId, DateTime featuredUntil) {
    return updateDocument('vendors', vendorId, {
      'isFeatured': true,
      'featuredAt': FieldValue.serverTimestamp(),
      'featuredUntil': Timestamp.fromDate(featuredUntil),
    });
  }

  Future<void> removeFeaturedVendor(String vendorId) {
    return updateDocument('vendors', vendorId, {
      'isFeatured': false,
      'featuredAt': null,
      'featuredUntil': null,
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) {
    return updateDocument('bookings', bookingId, {'status': status});
  }

  Future<void> updateInquiryStatus(String inquiryId, String status) {
    return updateDocument('inquiries', inquiryId, {'status': status});
  }

  Future<void> updateBlogStatus(String blogId, String status) {
    return updateDocument('blogs', blogId, {'status': status});
  }

  Future<void> createBlog(Map<String, dynamic> data) async {
    await _collection('blogs').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBlog(String blogId, Map<String, dynamic> data) {
    return updateDocument('blogs', blogId, data);
  }
}
