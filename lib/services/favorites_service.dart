import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_collections.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addToFavorites({
    required String serviceId,
    required String vendorId,
  }) async {
    final uid = _requireUser().uid;
    final normalizedServiceId = serviceId.trim();
    await _firestore
        .collection(FirestoreCollections.favorites)
        .doc('${uid}_$normalizedServiceId')
        .set({
          'customerId': uid,
          'serviceId': normalizedServiceId,
          'vendorId': vendorId,
          'createdAt': FieldValue.serverTimestamp(),
        });
    await _mirrorFavorite(uid, normalizedServiceId, isSaved: true);
  }

  Future<void> removeFromFavorites(String serviceId) async {
    final uid = _requireUser().uid;
    final normalizedServiceId = serviceId.trim();
    try {
      await _firestore
          .collection(FirestoreCollections.favorites)
          .doc('${uid}_$normalizedServiceId')
          .delete();
      await _mirrorFavorite(uid, normalizedServiceId, isSaved: false);
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      await _customerReference(uid).set({
        'favoriteServiceIds': FieldValue.arrayRemove([normalizedServiceId]),
      }, SetOptions(merge: true));
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to manage favorites.');
    return user;
  }

  Stream<bool> isFavorite(String serviceId) {
    if (serviceId.trim().isEmpty) return Stream.value(false);
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(false);
      return _favoriteDocumentStream(user.uid, serviceId.trim());
    });
  }

  Stream<bool> _favoriteDocumentStream(String uid, String serviceId) async* {
    try {
      await for (final snapshot
          in _firestore
              .collection(FirestoreCollections.favorites)
              .doc('${uid}_$serviceId')
              .snapshots()) {
        yield snapshot.exists;
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      yield* _customerReference(uid).snapshots().map((snapshot) {
        final ids = snapshot.data()?['favoriteServiceIds'];
        return ids is Iterable &&
            ids.map((id) => id.toString()).contains(serviceId);
      });
    }
  }

  Stream<List<String>> favoriteServiceIds() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(const <String>[]);
      return _favoriteIdsForUser(user.uid);
    });
  }

  Stream<List<String>> _favoriteIdsForUser(String uid) async* {
    try {
      await for (final snapshot
          in _firestore
              .collection(FirestoreCollections.favorites)
              .where('customerId', isEqualTo: uid)
              .snapshots()) {
        final documents = [...snapshot.docs]
          ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
        yield documents
            .map((doc) => doc.data()['serviceId']?.toString().trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      yield* _customerReference(uid).snapshots().map((snapshot) {
        final ids = snapshot.data()?['favoriteServiceIds'];
        if (ids is! Iterable) return const <String>[];
        return ids
            .map((id) => id.toString().trim())
            .where((id) => id.isNotEmpty)
            .toList()
            .reversed
            .toList();
      });
    }
  }

  Future<void> toggleFavorite({
    required String serviceId,
    required String vendorId,
  }) async {
    final uid = _requireUser().uid;
    final normalizedServiceId = serviceId.trim();
    final reference = _firestore
        .collection(FirestoreCollections.favorites)
        .doc('${uid}_$normalizedServiceId');
    try {
      final snapshot = await reference.get();
      if (snapshot.exists) {
        await reference.delete();
        await _mirrorFavorite(uid, normalizedServiceId, isSaved: false);
        return;
      }
      await reference.set({
        'customerId': uid,
        'serviceId': normalizedServiceId,
        'vendorId': vendorId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _mirrorFavorite(uid, normalizedServiceId, isSaved: true);
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      final customerReference = _customerReference(uid);
      final customer = await customerReference.get();
      final existing = customer.data()?['favoriteServiceIds'];
      final isSaved =
          existing is Iterable &&
          existing.map((id) => id.toString()).contains(normalizedServiceId);
      await customerReference.set({
        'favoriteServiceIds': isSaved
            ? FieldValue.arrayRemove([normalizedServiceId])
            : FieldValue.arrayUnion([normalizedServiceId]),
      }, SetOptions(merge: true));
    }
  }

  DocumentReference<Map<String, dynamic>> _customerReference(String uid) {
    return _firestore.collection(FirestoreCollections.customers).doc(uid);
  }

  Future<void> _mirrorFavorite(
    String uid,
    String serviceId, {
    required bool isSaved,
  }) async {
    try {
      await _customerReference(uid).set({
        'favoriteServiceIds': isSaved
            ? FieldValue.arrayUnion([serviceId])
            : FieldValue.arrayRemove([serviceId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  DateTime _createdAt(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final value = document.data()['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
