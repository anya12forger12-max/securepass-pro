import 'dart:math';

class SecureRandom {
  SecureRandom._();
  static final SecureRandom _instance = SecureRandom._();
  static SecureRandom get instance => _instance;

  final Random _random = Random.secure();

  /// Returns a cryptographically secure random integer in [min, max] (inclusive).
  int nextInt(int min, int max) {
    if (min > max) throw ArgumentError('min must be <= max');
    if (min == max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// Returns a random boolean.
  bool nextBool() => _random.nextBool();

  /// Returns a random double in [0.0, 1.0).
  double nextDouble() => _random.nextDouble();

  /// Returns a list of cryptographically secure random bytes.
  List<int> nextBytes(int count) {
    return List<int>.generate(count, (_) => _random.nextInt(256));
  }

  /// Returns a random element from the given list.
  T nextElement<T>(List<T> elements) {
    if (elements.isEmpty) throw ArgumentError('List must not be empty');
    return elements[_random.nextInt(elements.length)];
  }

  /// Returns a random index for the given list length.
  int nextIndex(int length) {
    if (length <= 0) throw ArgumentError('Length must be positive');
    return _random.nextInt(length);
  }

  /// Performs unbiased selection from a list by rejection sampling.
  /// For character selection where the charset size doesn't evenly divide 256.
  T unbiasedElement<T>(List<T> elements) {
    if (elements.isEmpty) throw ArgumentError('List must not be empty');
    if (elements.length == 256) return elements[_random.nextInt(256)];
    final limit = 256 - (256 % elements.length);
    int candidate;
    do {
      candidate = _random.nextInt(256);
    } while (candidate >= limit);
    return elements[candidate % elements.length];
  }

  /// Shuffles a list in place using Fisher-Yates with secure random.
  void shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
