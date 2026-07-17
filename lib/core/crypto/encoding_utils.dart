import 'dart:convert';
import 'package:securepass_pro/core/crypto/secure_random.dart';

class EncodingUtils {
  EncodingUtils._();

  static final SecureRandom _random = SecureRandom.instance;

  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String _base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  /// Encodes bytes to Base32 (RFC 4648).
  static String toBase32(List<int> bytes) {
    if (bytes.isEmpty) return '';
    int bits = 0;
    int value = 0;
    final output = StringBuffer();
    for (final byte in bytes) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        output.write(_base32Alphabet[(value >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) {
      output.write(_base32Alphabet[(value << (5 - bits)) & 31]);
    }
    return output.toString();
  }

  /// Decodes Base32 to bytes.
  static List<int> fromBase32(String encoded) {
    if (encoded.isEmpty) return [];
    int bits = 0;
    int value = 0;
    final output = <int>[];
    for (final char in encoded.toUpperCase().split('')) {
      final index = _base32Alphabet.indexOf(char);
      if (index == -1) throw ArgumentError('Invalid Base32 character: $char');
      value = (value << 5) | index;
      bits += 5;
      if (bits >= 8) {
        output.add((value >> (bits - 8)) & 255);
        bits -= 8;
      }
    }
    return output;
  }

  /// Encodes bytes to Base58 (Bitcoin alphabet).
  static String toBase58(List<int> bytes) {
    if (bytes.isEmpty) return '';
    int num = 0;
    for (final byte in bytes) {
      num = num * 256 + byte;
    }
    final result = StringBuffer();
    while (num > 0) {
      final remainder = num % 58;
      num ~/= 58;
      result.write(_base58Alphabet[remainder]);
    }
    for (final byte in bytes) {
      if (byte != 0) break;
      result.write(_base58Alphabet[0]);
    }
    return result.toString().split('').reversed.join();
  }

  /// Decodes Base58 to bytes.
  static List<int> fromBase58(String encoded) {
    if (encoded.isEmpty) return [];
    int num = 0;
    for (final char in encoded.split('')) {
      final index = _base58Alphabet.indexOf(char);
      if (index == -1) throw ArgumentError('Invalid Base58 character: $char');
      num = num * 58 + index;
    }
    final bytes = <int>[];
    while (num > 0) {
      bytes.add(num % 256);
      num ~/= 256;
    }
    for (final char in encoded.split('')) {
      if (char != _base58Alphabet[0]) break;
      bytes.add(0);
    }
    return bytes.reversed.toList();
  }

  /// Generates a random hex string of the given byte length.
  static String randomHex(int byteLength) {
    final bytes = _random.nextBytes(byteLength);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a random binary string of the given bit count.
  static String randomBinary(int bitCount) {
    final buffer = StringBuffer();
    for (int i = 0; i < bitCount; i++) {
      buffer.write(_random.nextBool() ? '1' : '0');
      if ((i + 1) % 8 == 0 && i + 1 < bitCount) buffer.write(' ');
    }
    return buffer.toString();
  }

  /// Generates a random Base64 string.
  static String randomBase64(int byteLength) {
    final bytes = _random.nextBytes(byteLength);
    return base64Encode(bytes);
  }

  /// Generates a random URL-safe Base64 string.
  static String randomUrlSafeBase64(int byteLength) {
    final bytes = _random.nextBytes(byteLength);
    return base64Url.encode(bytes);
  }

  /// Generates a random Base32 string of given output character length.
  static String randomBase32(int charLength) {
    final byteLength = (charLength * 5 / 8).ceil();
    final bytes = _random.nextBytes(byteLength);
    return toBase32(bytes).substring(0, charLength.clamp(0, toBase32(bytes).length));
  }

  /// Generates a random Base58 string of given length.
  static String randomBase58(int length) {
    if (length <= 0) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_base58Alphabet[_random.nextInt(0, _base58Alphabet.length - 1)]);
    }
    return buffer.toString();
  }

  /// Generates a UUID v4 (random).
  static String generateUuidV4() {
    final bytes = _random.nextBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 1
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
