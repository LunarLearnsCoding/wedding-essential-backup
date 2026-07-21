import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/vendor_model.dart';
import '../models/app_enums.dart';
import '../core/constants/firestore_collections.dart';

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
    String? address,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final now = DateTime.now();
    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.customer,
      createdAt: now,
    );

    final customer = CustomerModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.customer,
      address: address,
      weddingDate: null,
      createdAt: now,
    );

    final batch = _firestore.batch();

    final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);

    final customerRef = _firestore
        .collection(FirestoreCollections.customers)
        .doc(uid);

    batch.set(userRef, {...user.toMap(), 'status': 'active'});

    batch.set(customerRef, {...customer.toMap(), 'status': 'active'});

    await batch.commit();
    await credential.user?.sendEmailVerification();
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
    required List<String> locations,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final now = DateTime.now();

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.vendor,
      createdAt: now,
    );

    final vendor = VendorModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.vendor,
      businessName: businessName,
      category: category,
      locations: locations,
      bio: '',
      isApproved: false,
      approvalStatus: 'pending',
      averageRating: 0,
      totalReviews: 0,
      createdAt: now,
    );

    final batch = _firestore.batch();

    final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);

    final vendorRef = _firestore
        .collection(FirestoreCollections.vendors)
        .doc(uid);

    batch.set(userRef, {...user.toMap(), 'status': 'pending'});

    batch.set(vendorRef, {...vendor.toMap(), 'isActive': true});

    await batch.commit();

    await credential.user?.sendEmailVerification();
    await _auth.signOut();

    return credential;
  }

  // LOGIN
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
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
    return credential;
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
