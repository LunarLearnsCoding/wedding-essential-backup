import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    return await _firestore
        .collection(collection)
        .doc(docId)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collection,
  }) async {
    return await _firestore.collection(collection).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collection,
  }) {
    return _firestore.collection(collection).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots();
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .update(data);
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .delete();
  }

  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final docRef =
        await _firestore.collection(collection).add(data);

    return docRef.id;
  }
}