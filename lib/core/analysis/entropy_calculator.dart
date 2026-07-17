import 'dart:math';

class EntropyResult {
  final double bits;
  final String rating;
  final int poolSize;
  final int length;
  final double entropyPerChar;
  final int charsetSize;
  final double randomnessEstimate;
  final String resistanceToOnlineAttack;
  final String resistanceToOfflineAttack;

  const EntropyResult({
    required this.bits,
    required this.rating,
    required this.poolSize,
    required this.length,
    required this.entropyPerChar,
    required this.charsetSize,
    required this.randomnessEstimate,
    required this.resistanceToOnlineAttack,
    required this.resistanceToOfflineAttack,
  });
}

class EntropyCalculator {
  static final EntropyCalculator instance = EntropyCalculator._();

  const EntropyCalculator._();

  EntropyResult calculate(String password) {
    if (password.isEmpty) {
      return const EntropyResult(
        bits: 0,
        rating: 'None',
        poolSize: 0,
        length: 0,
        entropyPerChar: 0,
        charsetSize: 0,
        randomnessEstimate: 0,
        resistanceToOnlineAttack: 'Instant',
        resistanceToOfflineAttack: 'Instant',
      );
    }

    final int length = password.length;
    final int charsetSize = _detectCharsetSize(password);
    final double ln2 = _ln2();
    final double entropyPerChar = log(charsetSize) / ln2;
    final double bits = length * entropyPerChar;
    final double randomnessEstimate = _estimateRandomness(password);
    final String rating = _rateEntropy(bits);
    final String onlineResistance = _onlineAttackResistance(bits);
    final String offlineResistance = _offlineAttackResistance(bits);

    return EntropyResult(
      bits: double.parse(bits.toStringAsFixed(2)),
      rating: rating,
      poolSize: charsetSize,
      length: length,
      entropyPerChar: double.parse(entropyPerChar.toStringAsFixed(2)),
      charsetSize: charsetSize,
      randomnessEstimate: double.parse(randomnessEstimate.toStringAsFixed(3)),
      resistanceToOnlineAttack: onlineResistance,
      resistanceToOfflineAttack: offlineResistance,
    );
  }

  int _detectCharsetSize(String password) {
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSymbol = false;
    bool hasOther = false;

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) {
        hasLower = true;
      } else if (codeUnit >= 65 && codeUnit <= 90) {
        hasUpper = true;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        hasDigit = true;
      } else if ((codeUnit >= 32 && codeUnit <= 47) ||
          (codeUnit >= 58 && codeUnit <= 64) ||
          (codeUnit >= 91 && codeUnit <= 96) ||
          (codeUnit >= 123 && codeUnit <= 126)) {
        hasSymbol = true;
      } else {
        hasOther = true;
      }
    }

    int size = 0;
    if (hasLower) size += 26;
    if (hasUpper) size += 26;
    if (hasDigit) size += 10;
    if (hasSymbol) size += 33;
    if (hasOther) size += 50;

    return size > 0 ? size : 1;
  }

  double _ln2() {
    return 0.6931471805599453;
  }

  double _estimateRandomness(String password) {
    if (password.length <= 1) return 0.5;

    final int uniqueCount = password.split('').toSet().length;
    final double uniqueRatio = uniqueCount / password.length;

    double runPenalty = _detectRuns(password);
    double sequentialPenalty = _detectSequential(password);

    double estimate = uniqueRatio * 0.6 + (1.0 - runPenalty) * 0.2 + (1.0 - sequentialPenalty) * 0.2;
    return estimate.clamp(0.0, 1.0);
  }

  double _detectRuns(String password) {
    if (password.length < 2) return 0.0;

    int maxRun = 1;
    int currentRun = 1;

    for (int i = 1; i < password.length; i++) {
      if (password.codeUnitAt(i) == password.codeUnitAt(i - 1)) {
        currentRun++;
        if (currentRun > maxRun) {
          maxRun = currentRun;
        }
      } else {
        currentRun = 1;
      }
    }

    return (maxRun / password.length).clamp(0.0, 1.0);
  }

  double _detectSequential(String password) {
    if (password.length < 3) return 0.0;

    int sequentialCount = 0;

    for (int i = 2; i < password.length; i++) {
      int a = password.codeUnitAt(i - 2);
      int b = password.codeUnitAt(i - 1);
      int c = password.codeUnitAt(i);

      int delta1 = b - a;
      int delta2 = c - b;

      if ((delta1 == 1 && delta2 == 1) ||
          (delta1 == -1 && delta2 == -1) ||
          (delta1 == 1 && delta2 == 1)) {
        sequentialCount++;
      }
    }

    return (sequentialCount / (password.length - 2)).clamp(0.0, 1.0);
  }

  String _rateEntropy(double bits) {
    if (bits < 20) return 'Very Low';
    if (bits < 35) return 'Low';
    if (bits < 50) return 'Moderate';
    if (bits < 75) return 'High';
    if (bits < 100) return 'Very High';
    return 'Extremely High';
  }

  String _onlineAttackResistance(double bits) {
    if (bits < 20) return 'Instant - seconds';
    if (bits < 35) return 'Minutes to hours';
    if (bits < 50) return 'Hours to days';
    if (bits < 65) return 'Weeks to months';
    if (bits < 80) return 'Years';
    if (bits < 100) return 'Centuries';
    return 'Millennia';
  }

  String _offlineAttackResistance(double bits) {
    if (bits < 20) return 'Instant - microseconds';
    if (bits < 35) return 'Seconds to minutes';
    if (bits < 50) return 'Hours';
    if (bits < 65) return 'Days to weeks';
    if (bits < 80) return 'Months to years';
    if (bits < 100) return 'Thousands of years';
    if (bits < 128) return 'Billions of years';
    return 'Heat death of the universe';
  }
}
