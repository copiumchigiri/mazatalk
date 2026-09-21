import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/auth_repository.dart';

/// Real, persistent auth backed by SharedPreferences: accounts survive app
/// restarts and the signed-in session is restored on launch. This is the
/// local stand-in for Firebase Authentication — same repository interface,
/// so swapping in Firebase later is a data-layer-only change.
class LocalAuthRepository implements AuthRepository {
  static const _accountsKey = 'mazatalk_auth_accounts_v3';
  static const _sessionKey = 'mazatalk_auth_session_v3';

  // Legacy demo credentials, pre-seeded so existing manual testing keeps working.
  static const demoEmail = 'admin@gmail.com';
  static const _demoPassword = 'Password';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Salted with the account id so identical passwords hash differently.
  /// Not a security boundary (local device storage), just avoids keeping
  /// raw passwords around.
  String _hash(String password, String accountId) =>
      sha256.convert(utf8.encode('$password:$accountId')).toString();

  String _normalize(String id) => id.trim().toLowerCase();

  String _nameFor(String accountId) {
    final base = accountId.contains('@') ? accountId.split('@').first : accountId;
    return base.isEmpty ? 'parent' : base;
  }

  Future<Map<String, dynamic>> _loadAccounts(SharedPreferences prefs) async {
    final raw = prefs.getString(_accountsKey);
    final accounts = raw == null
        ? <String, dynamic>{}
        : (jsonDecode(raw) as Map<String, dynamic>);
    if (!accounts.containsKey(demoEmail)) {
      accounts[demoEmail] = {
        'passwordHash': _hash(_demoPassword, demoEmail),
        'parentName': 'admin',
      };
    }
    return accounts;
  }

  Future<void> _saveAccounts(
      SharedPreferences prefs, Map<String, dynamic> accounts) {
    return prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<void> _persistSession(SharedPreferences prefs, String accountId) {
    return prefs.setString(_sessionKey, accountId);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final id = _normalize(email);
    final account = accounts[id] as Map<String, dynamic>?;
    // Same message for unknown email and wrong password on purpose.
    const failure = AuthResult.failure('Email or password is incorrect.');
    if (account == null) return failure;
    final hash = account['passwordHash'] as String?;
    if (hash == null || hash != _hash(password, id)) return failure;
    await _persistSession(prefs, id);
    return AuthResult.success(
      accountId: id,
      parentName: account['parentName'] as String? ?? _nameFor(id),
    );
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final id = _normalize(email);
    if (!_emailPattern.hasMatch(id)) {
      return const AuthResult.failure('Please enter a valid email address.');
    }
    if (password.length < 6) {
      return const AuthResult.failure(
          'Password must be at least 6 characters.');
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    if (accounts.containsKey(id)) {
      return const AuthResult.failure(
          'An account with this email already exists. Try logging in.');
    }
    final name = _nameFor(id);
    accounts[id] = {'passwordHash': _hash(password, id), 'parentName': name};
    await _saveAccounts(prefs, accounts);
    await _persistSession(prefs, id);
    return AuthResult.success(accountId: id, parentName: name);
  }

  @override
  Future<AuthResult> signInWithProvider({
    required String accountId,
    String? parentName,
  }) async {
    final id = _normalize(accountId);
    if (id.isEmpty) return const AuthResult.failure('Invalid account.');
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final existing = accounts[id] as Map<String, dynamic>?;
    final name =
        existing?['parentName'] as String? ?? parentName ?? _nameFor(id);
    if (existing == null) {
      // Passwordless account: no hash, can only sign in via provider.
      accounts[id] = {'parentName': name};
      await _saveAccounts(prefs, accounts);
    }
    await _persistSession(prefs, id);
    return AuthResult.success(accountId: id, parentName: name);
  }

  @override
  Future<bool> accountExists(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    return accounts.containsKey(_normalize(accountId));
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final id = _normalize(email);
    final account = accounts[id] as Map<String, dynamic>?;
    if (account == null) return false;
    account['passwordHash'] = _hash(newPassword, id);
    accounts[id] = account;
    await _saveAccounts(prefs, accounts);
    return true;
  }

  @override
  Future<AuthResult?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionKey);
    if (id == null) return null;
    final accounts = await _loadAccounts(prefs);
    final account = accounts[id] as Map<String, dynamic>?;
    if (account == null) {
      await prefs.remove(_sessionKey);
      return null;
    }
    return AuthResult.success(
      accountId: id,
      parentName: account['parentName'] as String? ?? _nameFor(id),
    );
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
