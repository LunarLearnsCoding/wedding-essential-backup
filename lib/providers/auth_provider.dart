import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_collections.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  UserModel? _currentUser;
  bool _isLoading = true; // Start loading true until auth state is resolved

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  AuthService get authService => _authService;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((
      User? user,
    ) async {
      if (user == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      } else {
        await _fetchUserProfile(user.uid);
      }
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      _setLoading(true);
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.id, doc.data()!);
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _setLoading(true);

      await _authService.login(email: email, password: password);
    } catch (_) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // _authSubscription will set _currentUser = null and notify
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
