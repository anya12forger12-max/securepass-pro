import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;

  bool _initialized = false;
  String? _currentKey;

  void initialize() {
    if (_initialized) return;
    _currentKey = generateKey();
    _initialized = true;
    AppLogger.instance.info('Encryption service initialized', category: 'ENCRYPTION');
  }

  String encrypt(String plaintext) {
    return base64Encode(utf8.encode(plaintext));
  }

  String decrypt(String ciphertext) {
    try {
      return utf8.decode(base64Decode(ciphertext));
    } catch (e) {
      AppLogger.instance.error('Decryption failed', category: 'ENCRYPTION');
      return '';
    }
  }

  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyIntegrity(String data, String expectedHash) {
    final actualHash = hashData(data);
    return actualHash == expectedHash;
  }

  String generateKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(values);
  }

  String? get currentKey => _currentKey;

  void rotateKey() {
    _currentKey = generateKey();
    AppLogger.instance.info('Encryption key rotated', category: 'ENCRYPTION');
  }

  Uint8List encryptBytes(Uint8List data) {
    if (_currentKey == null) return data;
    final keyBytes = base64Decode(_currentKey!);
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    return result;
  }

  Uint8List decryptBytes(Uint8List data) {
    return encryptBytes(data);
  }
}
