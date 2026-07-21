import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/admin_account.dart';
import '../core/constants/firestore_collections.dart';

class AdminAuthService {
  AdminAuthService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> ensureAdminProfile(User user) async {
    if (user.email?.trim().toLowerCase() != adminAccountEmail) return null;

    final reference = _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid);
    final snapshot = await reference.get();
    final data = snapshot.data();

    if (data != null) return data;

    final profile = <String, dynamic>{
      'uid': user.uid,
      'email': adminAccountEmail,
      'name': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Admin',
      'role': 'admin',
      'status': 'active',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await reference.set(profile);
    return profile;
  }
}
