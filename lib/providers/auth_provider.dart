import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Manages authentication state and operations.
class AuthProvider extends ChangeNotifier {
  static const _rememberKey = 'gs_remember_me';

  final AuthService _auth;
  bool _initialized = false;
  bool _loading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  AuthProvider(this._auth);

  bool get loading => _loading;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isOwner => _auth.currentUser?.isOwner ?? false;

  /// Must be called from main() before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberKey) ?? true;

    await _auth.init();
    _initialized = true;
    _auth.authStateChanges().listen((_) {
      if (_initialized) notifyListeners();
    });

    // If "Remember me" is off, don't keep the session across launches.
    if (!_rememberMe && _auth.currentUser != null) {
      await _auth.signOut();
    }
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, value);
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// Sends a password-reset email. Returns true on success.
  Future<bool> sendPasswordReset(String email) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email);
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not send the reset email.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Changes the signed-in user's password. Returns true on success.
  Future<bool> changePassword(String newPassword) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.updatePassword(newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not change the password.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}

