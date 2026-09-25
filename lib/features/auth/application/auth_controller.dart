import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

class AuthState {
  /// True while the persisted session is being read on app launch; the
  /// router shows a splash screen instead of flashing the welcome screen.
  final bool isRestoring;
  final String? accountId;
  final String? parentName;

  const AuthState({this.isRestoring = false, this.accountId, this.parentName});

  bool get isLoggedIn => accountId != null;
}

/// Session state on top of [AuthRepository]. The repository owns account
/// storage and session persistence; this controller owns the in-memory
/// state the router and screens react to.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState(isRestoring: true);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final session = await _repository.restoreSession();
    state = session == null
        ? const AuthState()
        : AuthState(
            accountId: session.accountId,
            parentName: session.parentName,
          );
  }

  void _apply(AuthResult result) {
    if (!result.isSuccess) return;
    state = AuthState(
      accountId: result.accountId,
      parentName: result.parentName,
    );
  }

  /// Returns null on success, otherwise a user-facing error message.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);
    _apply(result);
    return result.error;
  }

  /// Returns null on success, otherwise a user-facing error message.
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    final result = await _repository.signUp(email: email, password: password);
    _apply(result);
    return result.error;
  }

  /// One-tap providers (Google/Facebook demo buttons) and phone OTP.
  Future<void> signInWithProvider({
    required String accountId,
    String? parentName,
  }) async {
    final result = await _repository.signInWithProvider(
      accountId: accountId,
      parentName: parentName,
    );
    _apply(result);
  }

  Future<bool> accountExists(String email) => _repository.accountExists(email);

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) {
    return _repository.resetPassword(email: email, newPassword: newPassword);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
