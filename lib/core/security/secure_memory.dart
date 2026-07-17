abstract final class SecureMemory {
  SecureMemory._();

  static void wipe(String? data) {
    if (data == null || data.isEmpty) return;
    final chars = List<String>.filled(data.length, '\x00');
    for (var i = 0; i < chars.length; i++) {
      chars[i] = '\x00';
    }
    chars.clear();
  }

  static void wipeBytes(List<int>? data) {
    if (data == null || data.isEmpty) return;
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  static void wipeList(List<String>? data) {
    if (data == null) return;
    for (var i = 0; i < data.length; i++) {
      wipe(data[i]);
      data[i] = '';
    }
    data.clear();
  }

  static void wipeMap(Map<String, String>? data) {
    if (data == null) return;
    for (final key in data.keys.toList()) {
      wipe(data[key]);
    }
    data.clear();
  }

  static bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    for (var i = 0; i < b.length; i++) {
      result |= a.codeUnitAt(i.clamp(0, a.length - 1)) ^
          b.codeUnitAt(i.clamp(0, b.length - 1));
    }

    return result == 0 && a.length == b.length;
  }

  static bool secureCompareBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }

  static String generateRandomString(int length) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List<String>.generate(
      length,
      (_) => charset[DateTime.now().microsecondsSinceEpoch % charset.length],
    );
    final result = random.join();
    wipeList(random);
    return result;
  }

  static List<int> toSecureBytes(String data) {
    final bytes = List<int>.from(data.codeUnits);
    return bytes;
  }

  static bool isNullOrEmpty(String? data) {
    return data == null || data.isEmpty;
  }
}
