import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addToFavorites({
    required String serviceId,
    required String vendorId,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('favorites').doc('${uid}_$serviceId').set({
      'customerId': uid,
      'serviceId': serviceId,
      'vendorId': vendorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromFavorites(String serviceId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('favorites').doc('${uid}_$serviceId').delete();
  }
}