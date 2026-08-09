import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/vendor_model.dart';
import '../models/app_enums.dart';
import '../core/constants/firestore_collections.dart';

/// Centralizes the Firebase operations used for auth data.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // CUSTOMER REGISTER
  Future<UserCredential> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    try {
      await _firestore
          .collection(FirestoreCollections.pendingRegistrations)
          .doc(credential.user!.uid)
          .set({
            'name': name,
            'email': normalizedEmail,
            'phone': phone,
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
      await credential.user!.sendEmailVerification();
    } catch (_) {
      await _discardIncompleteRegistration(credential.user);
      rethrow;
    }
    await _auth.signOut();
    return credential;
  }

  // VENDOR REGISTER
  Future<UserCredential> registerVendor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String businessName,
    required String category,
    required String location,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    try {
      await _firestore
          .collection(FirestoreCollections.pendingRegistrations)
          .doc(credential.user!.uid)
          .set({
            'name': name,
            'email': normalizedEmail,
            'phone': phone,
            'role': 'vendor',
            'businessName': businessName,
            'category': category,
            'location': location,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await credential.user!.sendEmailVerification();
    } catch (_) {
      await _discardIncompleteRegistration(credential.user);
      rethrow;
    }
    await _auth.signOut();

    return credential;
  }

  Future<void> _discardIncompleteRegistration(User? user) async {
    if (user == null) return;
    try {
      await _firestore
          .collection(FirestoreCollections.pendingRegistrations)
          .doc(user.uid)
          .delete();
    } catch (_) {}
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // LOGIN
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await credential.user?.reload();
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'too-many-requests') rethrow;
      }
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Verify your email before signing in.',
      );
    }
    await finalizePendingRegistration();
    return credential;
  }

  Future<void> finalizePendingRegistration() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) return;
    await user.getIdToken(true);

    final pendingRef = _firestore
        .collection(FirestoreCollections.pendingRegistrations)
        .doc(user.uid);
    final pending = await pendingRef.get();
    if (!pending.exists) return;

    final data = pending.data()!;
    final role = data['role']?.toString();
    final name = data['name']?.toString() ?? '';
    final email = user.email ?? data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final appUser = UserModel(
      id: user.uid,
      name: name,
      email: email,
      phone: phone,
      role: role == 'vendor' ? UserRole.vendor : UserRole.customer,
      createdAt: createdAt,
    );
    final batch = _firestore.batch();
    batch.set(_firestore.collection(FirestoreCollections.users).doc(user.uid), {
      ...appUser.toMap(),
      'status': role == 'vendor' ? 'pending' : 'active',
    });

    if (role == 'customer') {
      final customer = CustomerModel(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: UserRole.customer,
        weddingDate: null,
        createdAt: createdAt,
      );
      batch.set(
        _firestore.collection(FirestoreCollections.customers).doc(user.uid),
        {...customer.toMap(), 'status': 'active'},
      );
    } else if (role == 'vendor') {
      final savedLocation = data['location']?.toString().trim() ?? '';
      final legacyLocations = data['locations'];
      final legacyLocation = legacyLocations is Iterable
          ? legacyLocations
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .firstOrNull
          : null;
      final vendor = VendorModel(
        id: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: UserRole.vendor,
        businessName: data['businessName']?.toString() ?? '',
        category: data['category']?.toString() ?? '',
        location: savedLocation.isNotEmpty
            ? savedLocation
            : legacyLocation ?? '',
        bio: '',
        isApproved: false,
        approvalStatus: 'pending',
        averageRating: 0,
        totalReviews: 0,
        createdAt: createdAt,
      );
      batch.set(
        _firestore.collection(FirestoreCollections.vendors).doc(user.uid),
        {...vendor.toMap(), 'isActive': true},
      );
    } else {
      throw StateError('Pending registration has an invalid role.');
    }

    batch.delete(pendingRef);
    await batch.commit();
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const FormatException('Enter the email address for your account.');
    }

    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  // GET USER ROLE
  Future<String?> getUserRole() async {
    if (currentUser == null) return null;

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return null;

    return doc.data()?['role'];
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  Future<bool> isVendor() async {
    final role = await getUserRole();
    return role == 'vendor';
  }
}
