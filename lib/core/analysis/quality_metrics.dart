import 'package:securepass_pro/core/analysis/entropy_calculator.dart';

class QualityMetrics {
  final int lengthScore;
  final int uppercaseScore;
  final int lowercaseScore;
  final int numericScore;
  final int symbolScore;
  final int uniqueCharsScore;
  final int repeatedCharsScore;
  final int distributionScore;
  final int complexityScore;
  final int randomnessScore;
  final int readabilityScore;
  final int memorabilityScore;
  final int patternResistanceScore;

  const QualityMetrics({
    required this.lengthScore,
    required this.uppercaseScore,
    required this.lowercaseScore,
    required this.numericScore,
    required this.symbolScore,
    required this.uniqueCharsScore,
    required this.repeatedCharsScore,
    required this.distributionScore,
    required this.complexityScore,
    required this.randomnessScore,
    required this.readabilityScore,
    required this.memorabilityScore,
    required this.patternResistanceScore,
  });
}

class QualityMetricsCalculator {
  static final QualityMetricsCalculator instance = QualityMetricsCalculator._();

  const QualityMetricsCalculator._();

  QualityMetrics calculate(String password) {
    if (password.isEmpty) {
      return const QualityMetrics(
        lengthScore: 0,
        uppercaseScore: 0,
        lowercaseScore: 0,
        numericScore: 0,
        symbolScore: 0,
        uniqueCharsScore: 0,
        repeatedCharsScore: 0,
        distributionScore: 0,
        complexityScore: 0,
        randomnessScore: 0,
        readabilityScore: 0,
        memorabilityScore: 0,
        patternResistanceScore: 0,
      );
    }

    final int length = password.length;
    final int lengthScore = _calculateLengthScore(length);
    final int uppercaseScore = _calculateUppercaseScore(password);
    final int lowercaseScore = _calculateLowercaseScore(password);
    final int numericScore = _calculateNumericScore(password);
    final int symbolScore = _calculateSymbolScore(password);
    final int uniqueCharsScore = _calculateUniqueCharsScore(password);
    final int repeatedCharsScore = _calculateRepeatedCharsScore(password);
    final int distributionScore = _calculateDistributionScore(password);
    final int complexityScore = _calculateComplexityScore(
      lengthScore, uppercaseScore, lowercaseScore,
      numericScore, symbolScore, uniqueCharsScore,
    );
    final int randomnessScore = _calculateRandomnessScore(password);
    final int readabilityScore = _calculateReadabilityScore(password);
    final int memorabilityScore = _calculateMemorabilityScore(password);
    final int patternResistanceScore = _calculatePatternResistanceScore(password);

    return QualityMetrics(
      lengthScore: lengthScore,
      uppercaseScore: uppercaseScore,
      lowercaseScore: lowercaseScore,
      numericScore: numericScore,
      symbolScore: symbolScore,
      uniqueCharsScore: uniqueCharsScore,
      repeatedCharsScore: repeatedCharsScore,
      distributionScore: distributionScore,
      complexityScore: complexityScore,
      randomnessScore: randomnessScore,
      readabilityScore: readabilityScore,
      memorabilityScore: memorabilityScore,
      patternResistanceScore: patternResistanceScore,
    );
  }

  int _calculateLengthScore(int length) {
    final double normalized = length / 32.0;
    return (normalized * 100).round().clamp(0, 100);
  }

  int _calculateUppercaseScore(String password) {
    int count = 0;
    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) count++;
    }
    return ((count / password.length) * 100).round().clamp(0, 100);
  }

  int _calculateLowercaseScore(String password) {
    int count = 0;
    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) count++;
    }
    return ((count / password.length) * 100).round().clamp(0, 100);
  }

  int _calculateNumericScore(String password) {
    int count = 0;
    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) count++;
    }
    final double ratio = count / password.length;
    final double score = ratio * 100;
    if (ratio > 0.7) return (70 - (ratio - 0.7) * 100).round().clamp(0, 100);
    return score.round().clamp(0, 100);
  }

  int _calculateSymbolScore(String password) {
    int count = 0;
    for (final int codeUnit in password.codeUnits) {
      if ((codeUnit >= 32 && codeUnit <= 47) ||
          (codeUnit >= 58 && codeUnit <= 64) ||
          (codeUnit >= 91 && codeUnit <= 96) ||
          (codeUnit >= 123 && codeUnit <= 126)) {
        count++;
      }
    }
    final double ratio = count / password.length;
    final double score = ratio * 100;
    if (ratio > 0.5) return (80 - (ratio - 0.5) * 100).round().clamp(0, 100);
    return score.round().clamp(0, 100);
  }

  int _calculateUniqueCharsScore(String password) {
    final int uniqueCount = password.split('').toSet().length;
    return ((uniqueCount / password.length) * 100).round().clamp(0, 100);
  }

  int _calculateRepeatedCharsScore(String password) {
    int maxRun = 1;
    int currentRun = 1;

    for (int i = 1; i < password.length; i++) {
      if (password.codeUnitAt(i) == password.codeUnitAt(i - 1)) {
        currentRun++;
        if (currentRun > maxRun) maxRun = currentRun;
      } else {
        currentRun = 1;
      }
    }

    if (maxRun <= 1) return 100;
    if (maxRun == 2) return 85;
    if (maxRun == 3) return 65;
    if (maxRun == 4) return 45;
    if (maxRun == 5) return 25;
    return 10;
  }

  int _calculateDistributionScore(String password) {
    if (password.length < 2) return 50;

    final Map<String, int> frequency = {};
    for (final String char in password.split('')) {
      frequency[char] = (frequency[char] ?? 0) + 1;
    }

    final double expected = password.length / frequency.length;
    double variance = 0;

    for (final int count in frequency.values) {
      final double diff = count - expected;
      variance += diff * diff;
    }

    variance /= frequency.length;
    final double stdDev = _sqrt(variance);
    final double cv = expected > 0 ? stdDev / expected : 0;

    if (cv < 0.1) return 100;
    if (cv < 0.3) return 85;
    if (cv < 0.5) return 70;
    if (cv < 0.8) return 55;
    if (cv < 1.2) return 40;
    return 25;
  }

  int _calculateComplexityScore(
    int lengthScore,
    int uppercaseScore,
    int lowercaseScore,
    int numericScore,
    int symbolScore,
    int uniqueCharsScore,
  ) {
    final double average = lengthScore * 0.15 +
            uppercaseScore * 0.15 +
            lowercaseScore * 0.15 +
            numericScore * 0.15 +
            symbolScore * 0.20 +
            uniqueCharsScore * 0.20;
    return average.round().clamp(0, 100);
  }

  int _calculateRandomnessScore(String password) {
    final EntropyResult entropy = EntropyCalculator.instance.calculate(password);
    final double bits = entropy.bits;
    final double maxBits = password.length * 8.0;
    if (maxBits == 0) return 0;
    final double normalized = bits / maxBits;
    return (normalized * 100).round().clamp(0, 100);
  }

  int _calculateReadabilityScore(String password) {
    int penalty = 0;

    bool lastUpper = false;
    bool lastLower = false;
    int alternations = 0;

    for (final int codeUnit in password.codeUnits) {
      bool isUpper = codeUnit >= 65 && codeUnit <= 90;
      bool isLower = codeUnit >= 97 && codeUnit <= 122;

      if (isUpper && lastLower) alternations++;
      if (isLower && lastUpper) alternations++;

      if (isUpper) {
        lastUpper = true;
        lastLower = false;
      } else if (isLower) {
        lastLower = true;
        lastUpper = false;
      }
    }

    if (password.length > 1) {
      final double altRatio = alternations / (password.length - 1);
      if (altRatio > 0.8) penalty += 30;
      else if (altRatio > 0.6) penalty += 20;
    }

    bool hasMixedSymbols = false;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSymbol = false;

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) hasLower = true;
      else if (codeUnit >= 65 && codeUnit <= 90) hasUpper = true;
      else if (codeUnit >= 48 && codeUnit <= 57) hasDigit = true;
      else if (codeUnit >= 32 && codeUnit <= 126) hasSymbol = true;
    }

    int classCount = 0;
    if (hasLower) classCount++;
    if (hasUpper) classCount++;
    if (hasDigit) classCount++;
    if (hasSymbol) classCount++;

    if (classCount >= 4) hasMixedSymbols = true;

    if (hasMixedSymbols) penalty += 15;

    int score = 100 - penalty;
    return score.clamp(0, 100);
  }

  int _calculateMemorabilityScore(String password) {
    int score = 50;

    if (password.length <= 8) score += 20;
    else if (password.length <= 12) score += 10;
    else if (password.length <= 16) score += 0;
    else if (password.length <= 20) score -= 10;
    else score -= 20;

    int classCount = 0;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSymbol = false;

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) hasLower = true;
      else if (codeUnit >= 65 && codeUnit <= 90) hasUpper = true;
      else if (codeUnit >= 48 && codeUnit <= 57) hasDigit = true;
      else if (codeUnit >= 32 && codeUnit <= 126) hasSymbol = true;
    }

    if (hasLower) classCount++;
    if (hasUpper) classCount++;
    if (hasDigit) classCount++;
    if (hasSymbol) classCount++;

    if (classCount <= 2) score += 15;
    if (classCount >= 4) score -= 10;

    int maxRun = 1;
    int currentRun = 1;
    for (int i = 1; i < password.length; i++) {
      if (password.codeUnitAt(i) == password.codeUnitAt(i - 1)) {
        currentRun++;
        if (currentRun > maxRun) maxRun = currentRun;
      } else {
        currentRun = 1;
      }
    }

    if (maxRun >= 3) score += 10;

    return score.clamp(0, 100);
  }

  int _calculatePatternResistanceScore(String password) {
    int patternCount = 0;

    int maxRun = 1;
    int currentRun = 1;
    for (int i = 1; i < password.length; i++) {
      if (password.codeUnitAt(i) == password.codeUnitAt(i - 1)) {
        currentRun++;
        if (currentRun > maxRun) maxRun = currentRun;
      } else {
        currentRun = 1;
      }
    }
    if (maxRun >= 3) patternCount++;

    for (int i = 2; i < password.length; i++) {
      int a = password.codeUnitAt(i - 2);
      int b = password.codeUnitAt(i - 1);
      int c = password.codeUnitAt(i);
      int d1 = b - a;
      int d2 = c - b;
      if (d1 == d2 && (d1 == 1 || d1 == -1)) {
        patternCount++;
        break;
      }
    }

    final String lower = password.toLowerCase();
    final List<String> commonWords = [
      'password', 'qwerty', 'abc123', 'letmein', 'admin', 'welcome',
      'master', 'dragon', 'login', 'shadow', 'sunshine',
    ];
    for (final String word in commonWords) {
      if (lower.contains(word)) {
        patternCount += 2;
        break;
      }
    }

    if (password.length >= 4) {
      String firstHalf = password.substring(0, password.length ~/ 2);
      String secondHalf = password.substring(password.length ~/ 2);
      if (firstHalf == secondHalf) patternCount++;
    }

    if (password.length >= 4) {
      for (int i = 0; i <= password.length - 4; i++) {
        String chunk = password.substring(i, i + 2);
        String rest = password.substring(i + 2);
        if (rest.contains(chunk)) {
          patternCount++;
          break;
        }
      }
    }

    if (patternCount == 0) return 100;
    if (patternCount == 1) return 80;
    if (patternCount == 2) return 60;
    if (patternCount == 3) return 40;
    return 20;
  }

  double _sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;

    double x = value;
    double prev = 0;

    for (int i = 0; i < 50; i++) {
      prev = x;
      x = (x + value / x) / 2.0;
      if ((x - prev).abs() < 1e-10) break;
    }

    return x;
  }
}
