import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/encrypted_storage.dart';

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

    final storedKey = await EncryptedStorage.instance.retrieve(_keyStorageKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      _currentKey = SecretKey(base64Decode(storedKey));
    } else {
      final key = await _aesGcm.newSecretKey();
      _currentKey = key;
      await EncryptedStorage.instance.store(
        _keyStorageKey,
        base64Encode(await key.extractBytes()),
      );
    }

    _initialized = true;
    AppLogger.instance.info(
      'Encryption service initialized (AES-256-GCM)',
      category: 'ENCRYPTION',
    );
  }

  Future<String> encrypt(String plaintext) async {
    final key = _requireKey();
    final box = await _aesGcm.encrypt(utf8.encode(plaintext), secretKey: key);
    return base64Encode(box.concatenation());
  }

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
    if (_currentKey == null) {
      throw StateError(
        'Encryption service not initialized. Call initialize() first.',
      );
    }
    return _currentKey!;
  }
}