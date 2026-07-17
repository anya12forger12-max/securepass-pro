import 'package:securepass_pro/core/crypto/secure_random.dart';

/// Character set definitions for password generation.
class CharSet {
  const CharSet._();

  static const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String digits = '0123456789';
  static const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String extendedSymbols = '~`\'"\\/\\';
  static const String hexChars = '0123456789abcdef';
  static const String hexCharsUpper = '0123456789ABCDEF';
  static const String binaryChars = '01';
  static const String base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String base58Chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static const String base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  static const String urlSafeBase64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  static const String alphanumeric = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static const String space = ' ';

  /// Common ambiguous characters that can be excluded.
  static const String ambiguousChars = 'O0Il1|\'"`~,.;:/\\';
}

class CharGenerator {
  const CharGenerator._();

  static final SecureRandom _random = SecureRandom.instance;

  /// Generates a random character from the given charset.
  static String fromCharset(String charset) {
    if (charset.isEmpty) throw ArgumentError('Charset must not be empty');
    return _random.unbiasedElement(charset.split(''));
  }

  /// Generates a random string of the given length from the charset.
  static String string(int length, String charset) {
    if (length < 0) throw ArgumentError('Length must be non-negative');
    if (charset.isEmpty) throw ArgumentError('Charset must not be empty');
    if (length == 0) return '';
    final chars = charset.split('');
    return List<String>.generate(
      length,
      (_) => _random.unbiasedElement(chars),
    ).join();
  }

  /// Generates a random string from multiple charsets, ensuring at least one
  /// character from each charset is included.
  static String fromMultipleCharsets(int length, List<String> charsets) {
    if (length < 0) throw ArgumentError('Length must be non-negative');
    if (charsets.isEmpty) throw ArgumentError('Charsets must not be empty');
    if (length == 0) return '';

    final mandatoryChars = <String>[];
    final combined = StringBuffer();

    for (final charset in charsets) {
      if (charset.isNotEmpty) {
        mandatoryChars.add(fromCharset(charset));
        combined.write(charset);
      }
    }

    if (combined.isEmpty) throw ArgumentError('All charsets are empty');

    final remaining = length - mandatoryChars.length;
    if (remaining < 0) {
      throw ArgumentError(
        'Length $length is too short for ${charsets.length} required charset groups',
      );
    }

    final rest = string(remaining, combined.toString());
    final result = [...mandatoryChars, ...rest.split('')];
    _random.shuffle(result);
    return result.join();
  }

  /// Removes ambiguous characters from a charset.
  static String removeAmbiguous(String charset) {
    return charset.split('').where((c) => !CharSet.ambiguousChars.contains(c)).join();
  }

  /// Excludes specific characters from a charset.
  static String exclude(String charset, Set<String> exclusions) {
    return charset.split('').where((c) => !exclusions.contains(c)).join();
  }
}
