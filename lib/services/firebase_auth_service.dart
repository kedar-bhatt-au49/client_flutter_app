import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../core/constants.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Firebase-backed authentication.
///
/// - Uses Firebase Auth (email/password). Accounts are created by an admin
///   in the Firebase console â€” there is no public sign-up.
/// - Roles/display data come from the Firestore `users/{uid}` document,
///   created automatically on first sign-in.
/// - Session persistence is handled by Firebase (long-lived refresh token),
///   so users stay signed in across restarts.
class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  UserModel? _currentUser;

  @override
  Future<void> init() async {
    final u = _auth.currentUser;
    if (u != null) {
      _currentUser = await _toUser(u);
    }
  }

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _currentUser;
    await for (final u in _auth.authStateChanges()) {
      _currentUser = u == null ? null : await _toUser(u);
      yield _currentUser;
    }
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = await _toUser(cred.user!);
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final u = _auth.currentUser;
    if (u == null) throw AuthException('You are not signed in.');
    try {
      await u.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  // â”€â”€ Map a Firebase user to the app's UserModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<UserModel> _toUser(fb.User u) async {
    final email = (u.email ?? '').toLowerCase();
    final isCoFounder = email == GSUsers.coFounderEmail.toLowerCase();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        return UserModel(
          uid: u.uid,
          name: (d['name'] as String?) ?? _fallbackName(isCoFounder),
          nameGu: (d['nameGu'] as String?) ?? _fallbackNameGu(isCoFounder),
          role: (d['role'] as String?) ?? (isCoFounder ? 'coowner' : 'owner'),
          phone: (d['phone'] as String?) ?? _fallbackPhone(isCoFounder),
          email: email,
        );
      }
    } catch (_) {
      // Offline or rules issue â€” fall through to defaults.
    }

    final model = UserModel(
      uid: u.uid,
      name: _fallbackName(isCoFounder),
      nameGu: _fallbackNameGu(isCoFounder),
      role: isCoFounder ? 'coowner' : 'owner',
      phone: _fallbackPhone(isCoFounder),
      email: email,
    );
    // Create the profile document on first sign-in.
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .set(model.toJson());
    } catch (_) {}
    return model;
  }

  String _fallbackName(bool co) =>
      co ? 'Mr. Gopalsinh J. Parmar' : 'Mr. Jayrajsinh S. Umat';
  String _fallbackNameGu(bool co) =>
      co ? 'àª—à«‹àªªàª¾àª²àª¸àª¿àª‚àª¹ àªªàª°àª®àª¾àª°' : 'àªœàª¯àª°àª¾àªœàª¸àª¿àª‚àª¹ àª‰àª®àªŸ';
  String _fallbackPhone(bool co) =>
      co ? GSUsers.coFounderPhone : GSUsers.founderPhone;

  String _mapError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }
}
