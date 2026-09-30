import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Mock auth service — simulates Firebase Auth for the 2 pre-created accounts.
class MockAuthService implements AuthService {
  static const _sessionKey = 'gs_current_uid';
  static const _biometricsKey = 'gs_biometrics_enabled';

  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  final LocalAuthentication _localAuth = LocalAuthentication();
  SharedPreferences? _prefs;

  /// Pre-created accounts — no sign-up allowed.
  static final _knownUsers = <String, UserModel>{
    GSUsers.founderUid: UserModel(
      uid: GSUsers.founderUid,
      name: 'Mr. Jayrajsinh S. Umat',
      nameGu: 'જયરાજસિંહ ઉમટ',
      role: 'owner',
      phone: '8488807797',
      email: GSUsers.founderEmail,
    ),
    GSUsers.coFounderUid: UserModel(
      uid: GSUsers.coFounderUid,
      name: 'Mr. Gopalsinh J. Parmar',
      nameGu: 'ગોપાલસિંહ પરમાર',
      role: 'coowner',
      phone: '8866568543',
      email: GSUsers.coFounderEmail,
    ),
  };

  @override
  Stream<UserModel?> authStateChanges() => _authStateController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  /// Loads the persisted session on app start.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final uid = _prefs?.getString(_sessionKey);
    if (uid != null && _knownUsers.containsKey(uid)) {
      _currentUser = _knownUsers[uid];
      _authStateController.add(_currentUser);
    } else {
      _authStateController.add(null);
    }
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    UserModel? user;
    for (final u in _knownUsers.values) {
      if (u.email.toLowerCase() == email.toLowerCase()) {
        user = u;
        break;
      }
    }

    if (user == null) {
      throw AuthException('No account found for this email.');
    }

    if (password != GSUsers.appPassword) {
      throw AuthException('Incorrect password. Please try again.');
    }

    _currentUser = user;
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    await _prefs?.setString(_sessionKey, user.uid);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    await _prefs?.remove(_sessionKey);
    _authStateController.add(null);
  }

  // ── Biometrics ───────────────────────────────────────────────

  @override
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  bool get biometricsEnabled => _prefs?.getBool(_biometricsKey) ?? false;

  @override
  Future<void> setBiometricsEnabled(bool value) async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    await _prefs?.setBool(_biometricsKey, value);
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    final enabled = biometricsEnabled;
    if (!enabled || _currentUser == null) return false;

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to access Global Solar 2.0',
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Unlock the app for an existing user via biometrics.
  Future<bool> tryBiometricUnlock() async {
    final enabled = biometricsEnabled;
    if (!enabled) return false;

    final available = await canUseBiometrics();
    if (!available) return false;

    final didAuth = await authenticateWithBiometrics();
    if (didAuth && _currentUser != null) {
      _authStateController.add(_currentUser);
      return true;
    }
    return false;
  }

  /// Clean up resources.
  void dispose() {
    _authStateController.close();
  }
}
