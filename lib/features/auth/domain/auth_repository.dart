/// Outcome of an auth attempt: either a signed-in account or an error
/// message suitable for showing directly to the user.
class AuthResult {
  final String? accountId;
  final String? parentName;
  final String? error;

  const AuthResult.success({
    required String this.accountId,
    required String this.parentName,
  }) : error = null;

  const AuthResult.failure(String this.error)
      : accountId = null,
        parentName = null;

  bool get isSuccess => accountId != null;
}

abstract class AuthRepository {
  /// Signs in with email + password. Successful results persist the session.
  Future<AuthResult> login({required String email, required String password});

  /// Creates a new account and signs it in.
  Future<AuthResult> signUp({required String email, required String password});

  /// Creates-or-signs-in a passwordless account, used by the one-tap demo
  /// providers (Google/Facebook) and phone OTP.
  Future<AuthResult> signInWithProvider({
    required String accountId,
    String? parentName,
  });

  Future<bool> accountExists(String accountId);

  /// Sets a new password for [email]. Returns false if no such account.
  Future<bool> resetPassword({required String email, required String newPassword});

  /// Returns the persisted signed-in account from a previous run, or null.
  Future<AuthResult?> restoreSession();

  /// Clears the persisted session (accounts are kept).
  Future<void> logout();
}
