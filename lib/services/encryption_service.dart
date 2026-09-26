import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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

    String? storedKey;
    try {
      storedKey = await EncryptedStorage.instance.retrieve(_keyStorageKey);
    } catch (e) {
      // Fail closed. Silently generating a replacement key here would
      // overwrite the only key able to decrypt the existing vault, making
      // every stored credential permanently unreadable. Leave the service
      // uninitialized instead: encrypt/decrypt then raise a clear error and
      // the next launch retries reading the real key.
      AppLogger.instance.error(
        'Could not read the encryption key; keeping the stored key intact '
        'instead of generating a new one: $e',
        category: 'ENCRYPTION',
      );
      return;
    }

    if (storedKey != null && storedKey.isNotEmpty) {
      try {
        _currentKey = SecretKey(base64Decode(storedKey));
      } on FormatException catch (e) {
        // A corrupt stored value is equally irreplaceable: overwriting it
        // would destroy the data it was protecting.
        AppLogger.instance.error(
          'Stored encryption key is unreadable; refusing to replace it: $e',
          category: 'ENCRYPTION',
        );
        return;
      }
    } else {
      // Genuinely first run: there is no key to lose. A write failure here
      // must still fail closed: initialize() callers (main.dart) do not
      // catch, so letting it propagate would crash startup instead of
      // retrying on the next launch.
      try {
        await _createAndPersistKey();
      } catch (e) {
        AppLogger.instance.error(
          'Could not persist the new encryption key; will retry on next '
          'launch: $e',
          category: 'ENCRYPTION',
        );
        return;
      }
    }

    _initialized = true;
    AppLogger.instance.info(
      'Encryption service initialized (AES-256-GCM)',
      category: 'ENCRYPTION',
    );
  }

  /// Clears the in-memory state so a test can exercise a fresh startup.
  ///
  /// The stored key is deliberately untouched, so tests still have to mock
  /// the key store to control what [initialize] reads.
  @visibleForTesting
  void resetForTest() {
    _initialized = false;
    _currentKey = null;
  }

  Future<void> _createAndPersistKey() async {
    final key = await _aesGcm.newSecretKey();
    await EncryptedStorage.instance.store(
      _keyStorageKey,
      base64Encode(await key.extractBytes()),
    );
    // Adopt the key only after it is durably stored: a key that encrypts
    // in-memory but was never persisted would produce data that is
    // unreadable after the next restart.
    _currentKey = key;
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
  /// Throws [EncryptionException] when authentication fails, the ciphertext is
  /// malformed, the service is not initialized, or decryption errors in any
  /// other way. Failures are never reported as an empty string: a legitimately
  /// empty plaintext would be indistinguishable from a corrupt or
  /// wrong-key payload, and callers that treated it as valid could silently
  /// act on a failed decrypt.
  Future<String> decrypt(String ciphertext) async {
    final SecretKey key;
    try {
      key = _requireKey();
    } on EncryptionException {
      rethrow;
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }

    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(ciphertext),
        nonceLength: 12,
        macLength: 16,
      );
      final clearText = await _aesGcm.decrypt(box, secretKey: key);
      return utf8.decode(clearText);
    } on EncryptionException {
      rethrow;
    } catch (e) {
      AppLogger.instance.error(
        'Decryption failed (authentication tag, malformed input, or wrong key): $e',
        category: 'ENCRYPTION',
      );
      throw const EncryptionException(
        'Decryption failed: the data is corrupt, was encrypted with a '
        'different key, or has been tampered with.',
      );
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