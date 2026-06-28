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

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // CUSTOMER REGISTER
  Future<UserCredential> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    final customer = CustomerModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.customer,
      address: address,
      weddingDate: null,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toMap());

    await _firestore
        .collection(FirestoreCollections.customers)
        .doc(uid)
        .set(customer.toMap());

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
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.vendor,
      createdAt: DateTime.now(),
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
      averageRating: 0,
      totalReviews: 0,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toMap());

    await _firestore
        .collection(FirestoreCollections.vendors)
        .doc(uid)
        .set(vendor.toMap());

    return credential;
  }

  // LOGIN
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
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

  Future<bool> isCustomer() async {
    final role = await getUserRole();
    return role == 'customer';
  }
}