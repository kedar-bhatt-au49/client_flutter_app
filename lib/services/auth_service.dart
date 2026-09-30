import '../models/user.dart';

/// Abstract auth service — mirrors Firebase Auth contract.
/// A real implementation would swap this for FirebaseAuth.
abstract class AuthService {
  /// Stream of auth state changes.
  Stream<UserModel?> authStateChanges();

  /// Current logged-in user, or null.
  UserModel? get currentUser;

  /// Sign in with email + password.
  /// Throws [AuthException] on invalid credentials.
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password);

  /// Sign out and clear session.
  Future<void> signOut();

  /// Try biometric / device unlock.
  Future<bool> authenticateWithBiometrics();

  /// Check if biometric is available on this device.
  Future<bool> canUseBiometrics();

  /// Whether the user has enabled biometric unlock.
  bool get biometricsEnabled;

  /// Enable or disable biometric unlock.
  Future<void> setBiometricsEnabled(bool value);
}

/// Simple exception for auth errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
