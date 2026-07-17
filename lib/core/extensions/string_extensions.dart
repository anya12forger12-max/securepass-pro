extension StringExtensions on String {
  bool get isNullOrEmpty => isEmpty;

  bool get isNotNullOrEmpty => isNotEmpty;

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  bool get isValidEmail {
    if (isEmpty) return false;
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    return emailRegex.hasMatch(this);
  }

  String maskMiddle({int visibleStart = 3, int visibleEnd = 2, String maskChar = '\u2022'}) {
    if (length <= visibleStart + visibleEnd) return this;
    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final maskedLength = length - visibleStart - visibleEnd;
    return '$start${maskChar * maskedLength}$end';
  }

  String get maskPassword => maskMiddle(visibleStart: 0, visibleEnd: 0, maskChar: '\u2022');

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    final truncateLength = maxLength - suffix.length;
    if (truncateLength <= 0) return suffix;
    return '${substring(0, truncateLength)}$suffix';
  }

  String get trimAll => replaceAll(RegExp(r'\s+'), ' ').trim();

  bool get isNumeric => double.tryParse(this) != null;

  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  String get reverse => split('').reversed.join();

  int countMatch(RegExp pattern) => pattern.allMatches(this).length;

  String ensureEndsWith(String suffix) {
    if (endsWith(suffix)) return this;
    return '$this$suffix';
  }

  String ensureStartsWith(String prefix) {
    if (startsWith(prefix)) return this;
    return '$prefix$this';
  }

  String removeDiacritics() {
    const diacritics = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'æ': 'ae',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ñ': 'n', 'ç': 'c', 'ß': 'ss',
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O', 'Ø': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
      'Ý': 'Y', 'Ñ': 'N', 'Ç': 'C',
    };
    var result = this;
    for (final entry in diacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  bool get hasUppercase => contains(RegExp(r'[A-Z]'));

  bool get hasLowercase => contains(RegExp(r'[a-z]'));

  bool get hasDigit => contains(RegExp(r'[0-9]'));

  bool get hasSpecialCharacter => contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
}
