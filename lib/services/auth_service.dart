import '../models/user.dart';

/// Abstract auth service — mirrors Firebase Auth contract.
/// A real implementation would swap this for FirebaseAuth.
abstract class AuthService {
  /// Initialise the service (load persisted session).
  Future<void> init();

  /// Stream of auth state changes.
  Stream<UserModel?> authStateChanges();

  /// Current logged-in user, or null.
  UserModel? get currentUser;

  /// Sign in with email + password.
  /// Throws [AuthException] on invalid credentials.
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password);

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Change the current user's password.
  Future<void> updatePassword(String newPassword);

  /// Sign out and clear session.
  Future<void> signOut();
}

/// Simple exception for auth errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
