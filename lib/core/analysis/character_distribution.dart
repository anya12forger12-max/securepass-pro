class CharacterDistribution {
  final double uppercasePercent;
  final double lowercasePercent;
  final double numbersPercent;
  final double symbolsPercent;
  final int uniqueCharCount;
  final int totalLength;
  final Map<String, int> frequencyMap;
  final double distributionBalance;
  final double entropyPerChar;

  const CharacterDistribution({
    required this.uppercasePercent,
    required this.lowercasePercent,
    required this.numbersPercent,
    required this.symbolsPercent,
    required this.uniqueCharCount,
    required this.totalLength,
    required this.frequencyMap,
    required this.distributionBalance,
    required this.entropyPerChar,
  });
}

class CharacterDistributionAnalyzer {
  static final CharacterDistributionAnalyzer instance =
      CharacterDistributionAnalyzer._();

  const CharacterDistributionAnalyzer._();

  CharacterDistribution analyze(String password) {
    if (password.isEmpty) {
      return const CharacterDistribution(
        uppercasePercent: 0,
        lowercasePercent: 0,
        numbersPercent: 0,
        symbolsPercent: 0,
        uniqueCharCount: 0,
        totalLength: 0,
        frequencyMap: {},
        distributionBalance: 0,
        entropyPerChar: 0,
      );
    }

    final int length = password.length;
    int upperCount = 0;
    int lowerCount = 0;
    int digitCount = 0;
    int symbolCount = 0;

    final Map<String, int> frequencyMap = {};

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        upperCount++;
      } else if (codeUnit >= 97 && codeUnit <= 122) {
        lowerCount++;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        digitCount++;
      } else {
        symbolCount++;
      }

      final String char = String.fromCharCode(codeUnit);
      frequencyMap[char] = (frequencyMap[char] ?? 0) + 1;
    }

    final double uppercasePercent = (upperCount / length) * 100;
    final double lowercasePercent = (lowerCount / length) * 100;
    final double numbersPercent = (digitCount / length) * 100;
    final double symbolsPercent = (symbolCount / length) * 100;
    final int uniqueCharCount = frequencyMap.length;

    final double distributionBalance =
        _calculateDistributionBalance(frequencyMap, length);
    final double entropyPerChar =
        _calculateShannonEntropy(frequencyMap, length);

    return CharacterDistribution(
      uppercasePercent: double.parse(uppercasePercent.toStringAsFixed(2)),
      lowercasePercent: double.parse(lowercasePercent.toStringAsFixed(2)),
      numbersPercent: double.parse(numbersPercent.toStringAsFixed(2)),
      symbolsPercent: double.parse(symbolsPercent.toStringAsFixed(2)),
      uniqueCharCount: uniqueCharCount,
      totalLength: length,
      frequencyMap: Map.unmodifiable(frequencyMap),
      distributionBalance:
          double.parse(distributionBalance.toStringAsFixed(4)),
      entropyPerChar: double.parse(entropyPerChar.toStringAsFixed(4)),
    );
  }

  double _calculateDistributionBalance(
      Map<String, int> frequencyMap, int totalLength) {
    if (frequencyMap.isEmpty || totalLength == 0) return 0;

    final double expected = totalLength / frequencyMap.length;
    if (expected == 0) return 0;

    double sumSquaredDiffs = 0;
    for (final int count in frequencyMap.values) {
      final double diff = count - expected;
      sumSquaredDiffs += diff * diff;
    }

    final double variance = sumSquaredDiffs / frequencyMap.length;
    final double stdDev = _sqrt(variance);
    final double coefficientOfVariation =
        expected > 0 ? stdDev / expected : 1.0;

    final double balance = 1.0 - coefficientOfVariation.clamp(0.0, 1.0);

    return balance.clamp(0.0, 1.0);
  }

  double _calculateShannonEntropy(
      Map<String, int> frequencyMap, int totalLength) {
    if (frequencyMap.isEmpty || totalLength == 0) return 0;

    double entropy = 0;
    for (final int count in frequencyMap.values) {
      final double probability = count / totalLength;
      if (probability > 0) {
        entropy -= probability * (_log2(probability));
      }
    }

    return entropy.clamp(0.0, 10.0);
  }

  double _log2(double value) {
    if (value <= 0) return 0;
    final double ln2 = 0.6931471805599453;
    return _ln(value) / ln2;
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    if (x == 1) return 0;

    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    int n = 1;

    while (currentTerm.abs() > 1e-15) {
      result += currentTerm / n;
      currentTerm *= termSquared;
      n += 2;
    }

    return result * 2.0;
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
