import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

/// Local account gate for SecurePass Pro.
///
/// The app is a fully local password manager: there is no server, so the
/// "account" is a credential digest derived from the email + password with
/// PBKDF2-HMAC-SHA256, a random per-account salt, and 210k iterations, stored
/// in app-private preferences. The stored value cannot be reversed into the
/// password. Deliberately kept in SharedPreferences (not encrypted storage)
/// because the redirect gate must be able to read whether an account exists
/// synchronously on every route change; the value itself is a one-way digest.
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  factory AuthService() => _instance;

  static const int _pbkdf2Iterations = 210000;
  static const int _pbkdf2Bits = 256;
  static const String _pbkdf2Prefix = 'pbkdf2:';

  /// Test seam mirroring [VaultService.pbkdf2IterationsOverride]; never set in
  /// production code.
  int? pbkdf2IterationsOverride;

  bool get hasAccount =>
      PreferencesStorage.instance.getString(AppConstants.loginPinKey) != null;

  String? get signedInEmail =>
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey);

  /// Creates (or replaces) the local account and persists its salted
  /// PBKDF2-HMAC-SHA256 credential digest plus the onboarding marker.
  Future<void> createAccount(String email, String password) async {
    final stored = await _deriveStoredValue(email.trim(), password);
    await PreferencesStorage.instance
        .setString(AppConstants.loginPinKey, stored);
    await PreferencesStorage.instance
        .setString(AppConstants.loginEmailKey, email.trim());
    await PreferencesStorage.instance
        .setBool(AppConstants.onboardingCompleteKey, true);
    AppLogger.instance.info('Local account created', category: 'AUTH');
  }

  /// Verifies an email/password pair against the stored credential.
  ///
  /// Legacy installs (pre-2.2.30) stored
  /// `base64('securepass_login:<email>:<password>')` — recoverable plaintext.
  /// Those still verify, and are transparently migrated to the PBKDF2 form on
  /// first successful sign-in.
  Future<bool> verify(String email, String password) async {
    final stored =
        PreferencesStorage.instance.getString(AppConstants.loginPinKey);
    if (stored == null) return false;
    final trimmedEmail = email.trim();

    if (stored.startsWith(_pbkdf2Prefix)) {
      final parts = stored.substring(_pbkdf2Prefix.length).split(':');
      if (parts.length != 3) return false;
      final iterations = int.tryParse(parts[0]);
      if (iterations == null || iterations <= 0) return false;
      final List<int> salt;
      try {
        salt = base64Decode(parts[1]);
      } on FormatException {
        return false;
      }
      final expectedB64 = parts[2];
      final derivedB64 =
          await _derive(trimmedEmail, password, salt, iterations);
      if (!_constantTimeEquals(expectedB64, derivedB64)) return false;
      await PreferencesStorage.instance
          .setString(AppConstants.loginEmailKey, trimmedEmail);
      return true;
    }

    final String legacyStored;
    try {
      legacyStored = utf8.decode(base64Decode(stored));
    } on FormatException {
      return false;
    }
    final candidate = 'securepass_login:$trimmedEmail:$password';
    if (!_constantTimeEquals(legacyStored, candidate)) return false;
    await _migrateLegacy(trimmedEmail, password);
    return true;
  }

  Future<String> _deriveStoredValue(String email, String password) async {
    final salt = _randomSalt();
    final iterations = pbkdf2IterationsOverride ?? _pbkdf2Iterations;
    final hashB64 = await _derive(email, password, salt, iterations);
    return '$_pbkdf2Prefix$iterations:${base64Encode(salt)}:$hashB64';
  }

  Future<void> _migrateLegacy(String email, String password) async {
    final stored = await _deriveStoredValue(email, password);
    await PreferencesStorage.instance
        .setString(AppConstants.loginPinKey, stored);
    await PreferencesStorage.instance
        .setString(AppConstants.loginEmailKey, email);
    AppLogger.instance.info('Legacy login credential migrated to PBKDF2',
        category: 'AUTH');
  }

  Future<String> _derive(
    String email,
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _pbkdf2Bits,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode('$email:$password')),
      nonce: salt,
    );
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }

  List<int> _randomSalt() {
    final rng = Random.secure();
    return List<int>.generate(16, (_) => rng.nextInt(256));
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}