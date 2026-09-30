import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/auth_service_impl.dart';

/// Manages authentication state and operations.
class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  bool _initialized = false;
  bool _loading = false;
  String? _errorMessage;

  AuthProvider(this._auth);

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isOwner => _auth.currentUser?.isOwner ?? false;

  /// Must be called from main() before runApp.
  Future<void> init() async {
    if (_auth is MockAuthService) {
      await _auth.init();
    }
    _initialized = true;
    _auth.authStateChanges().listen((user) {
      if (_initialized) notifyListeners();
    });
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
    } catch (e) {
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

  Future<bool> tryBiometricUnlock() async {
    return await _auth.authenticateWithBiometrics();
  }

  Future<bool> canUseBiometrics() => _auth.canUseBiometrics();
  bool get biometricsEnabled => _auth.biometricsEnabled;
  Future<void> setBiometricsEnabled(bool value) =>
      _auth.setBiometricsEnabled(value);
}
