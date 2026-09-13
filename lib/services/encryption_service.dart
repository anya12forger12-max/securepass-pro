import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/encrypted_storage.dart';

class EncryptionException implements Exception {
  const EncryptionException(this.message);

  final String message;

  @override
  String toString() => 'EncryptionException: $message';
}

class EncryptionService {
  EncryptionService._();
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;

  static const String _keyStorageKey = 'aes_master_key_v1';

  final AesGcm _aesGcm = AesGcm.with256bits();

  bool _initialized = false;
  SecretKey? _currentKey;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final storedKey = await EncryptedStorage.instance.retrieve(_keyStorageKey);
      if (storedKey != null && storedKey.isNotEmpty) {
        _currentKey = SecretKey(base64Decode(storedKey));
      } else {
        await _createAndPersistKey();
      }
    } catch (e) {
      AppLogger.instance.warning(
        'Failed to restore encryption key, regenerating: $e',
        category: 'ENCRYPTION',
      );
      _currentKey = null;
      try {
        await _createAndPersistKey();
      } catch (writeError) {
        AppLogger.instance.error(
          'Failed to persist a new encryption key: $writeError',
          category: 'ENCRYPTION',
        );
      }
    }

    _initialized = true;
    AppLogger.instance.info(
      'Encryption service initialized (AES-256-GCM)',
      category: 'ENCRYPTION',
    );
  }

  Future<void> _createAndPersistKey() async {
    final key = await _aesGcm.newSecretKey();
    _currentKey = key;
    await EncryptedStorage.instance.store(
      _keyStorageKey,
      base64Encode(await key.extractBytes()),
    );
  }

  Future<String> encrypt(String plaintext) async {
    final key = _requireKey();
    try {
      final box = await _aesGcm.encrypt(utf8.encode(plaintext), secretKey: key);
      return base64Encode(box.concatenation());
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypts [ciphertext] and returns the plaintext.
  ///
  /// Returns an empty string when authentication fails, the ciphertext is
  /// malformed, or decryption errors in any other way — this is
  /// indistinguishable from a legitimately empty plaintext. Callers must
  /// treat an empty result as a failure signal.
  Future<String> decrypt(String ciphertext) async {
    try {
      final key = _requireKey();
      final box = SecretBox.fromConcatenation(
        base64Decode(ciphertext),
        nonceLength: 12,
        macLength: 16,
      );
      final clearText = await _aesGcm.decrypt(box, secretKey: key);
      return utf8.decode(clearText);
    } catch (e) {
      AppLogger.instance.error('Decryption failed', category: 'ENCRYPTION');
      return '';
    }
  }

  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  bool verifyIntegrity(String data, String expectedHash) {
    return hashData(data) == expectedHash;
  }

  String generateKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(values);
  }

  SecretKey _requireKey() {
    final key = _currentKey;
    if (key == null) {
      throw const EncryptionException(
        'Encryption service not initialized. Call initialize() first.',
      );
    }
    return key;
  }
}