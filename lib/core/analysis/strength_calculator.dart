import 'package:securepass_pro/core/analysis/entropy_calculator.dart';

enum StrengthLevel {
  veryStrong(97, 'Maximum Security', 'Meets or exceeds military-grade requirements. Virtually unbreakable.'),
  excellent(85, 'Enterprise Grade', 'Suitable for enterprise security. Exceptional resistance to attacks.'),
  strong(75, 'Very Strong', 'Strong password resistant to most attack methods.'),
  good(60, 'Strong', 'Good password that provides solid protection for most accounts.'),
  fair(45, 'Fair', 'Acceptable for low-risk accounts but should be improved.'),
  weak(30, 'Weak', 'Easily guessable. Use a stronger password.'),
  veryWeak(15, 'Very Weak', 'Extremely vulnerable. Change immediately.'),
  ;

  final int threshold;
  final String label;
  final String description;

  const StrengthLevel(this.threshold, this.label, this.description);
}

class StrengthResult {
  final int score;
  final StrengthLevel level;
  final String label;
  final String description;
  final Map<String, int> breakdown;

  const StrengthResult({
    required this.score,
    required this.level,
    required this.label,
    required this.description,
    required this.breakdown,
  });
}

class StrengthCalculator {
  static final StrengthCalculator instance = StrengthCalculator._();

  const StrengthCalculator._();

  StrengthResult calculate(String password) {
    if (password.isEmpty) {
      return const StrengthResult(
        score: 0,
        level: StrengthLevel.veryWeak,
        label: 'No Password',
        description: 'No password provided.',
        breakdown: {},
      );
    }

    final EntropyResult entropy = EntropyCalculator.instance.calculate(password);

    final int lengthScore = _scoreLength(password.length);
    final int diversityScore = _scoreDiversity(password);
    final int entropyScore = _scoreEntropy(entropy.bits);
    final int patternScore = _scorePatterns(password);
    final int balanceScore = _scoreBalance(password);

    final Map<String, int> breakdown = {
      'Length': lengthScore,
      'Diversity': diversityScore,
      'Entropy': entropyScore,
      'Patterns': patternScore,
      'Balance': balanceScore,
    };

    final int overallScore = ((lengthScore * 0.25) +
            (diversityScore * 0.20) +
            (entropyScore * 0.25) +
            (patternScore * 0.15) +
            (balanceScore * 0.15))
        .round()
        .clamp(0, 100);

    final StrengthLevel level = _determineLevel(overallScore);

    return StrengthResult(
      score: overallScore,
      level: level,
      label: level.label,
      description: level.description,
      breakdown: breakdown,
    );
  }

  int _scoreLength(int length) {
    if (length < 6) {
      return (length / 6.0 * 30).round();
    }
    if (length < 8) return 35;
    if (length < 12) return 50;
    if (length < 16) return 65;
    if (length < 20) return 75;
    if (length < 24) return 85;
    if (length < 32) return 92;
    return 100;
  }

  int _scoreDiversity(String password) {
    int classCount = 0;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSymbol = false;

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) {
        hasLower = true;
      } else if (codeUnit >= 65 && codeUnit <= 90) {
        hasUpper = true;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        hasDigit = true;
      } else if (codeUnit >= 32 && codeUnit <= 126) {
        hasSymbol = true;
      }
    }

    if (hasLower) classCount++;
    if (hasUpper) classCount++;
    if (hasDigit) classCount++;
    if (hasSymbol) classCount++;

    final int uniqueCount = password.split('').toSet().length;
    final double uniqueRatio = uniqueCount / password.length;

    final int classScore = ((classCount / 4.0) * 60).round();
    final int uniqueScore = (uniqueRatio * 40).round();

    return (classScore + uniqueScore).clamp(0, 100);
  }

  int _scoreEntropy(double bits) {
    if (bits < 20) return (bits / 20.0 * 25).round();
    if (bits < 35) return 25 + ((bits - 20) / 15.0 * 20).round();
    if (bits < 50) return 45 + ((bits - 35) / 15.0 * 15).round();
    if (bits < 75) return 60 + ((bits - 50) / 25.0 * 20).round();
    if (bits < 100) return 80 + ((bits - 75) / 25.0 * 15).round();
    if (bits < 128) return 95 + ((bits - 100) / 28.0 * 5).round();
    return 100;
  }

  int _scorePatterns(String password) {
    int penalty = 0;

    penalty += _repeatedCharPenalty(password);
    penalty += _sequentialCharPenalty(password);
    penalty += _commonPatternPenalty(password);

    return (100 - penalty).clamp(0, 100);
  }

  int _repeatedCharPenalty(String password) {
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

    if (maxRun >= 5) return 40;
    if (maxRun >= 4) return 30;
    if (maxRun >= 3) return 20;
    if (maxRun >= 2) return 10;
    return 0;
  }

  int _sequentialCharPenalty(String password) {
    int seqCount = 0;

    for (int i = 2; i < password.length; i++) {
      int a = password.codeUnitAt(i - 2);
      int b = password.codeUnitAt(i - 1);
      int c = password.codeUnitAt(i);

      int d1 = b - a;
      int d2 = c - b;

      if (d1 == d2 && (d1 == 1 || d1 == -1)) {
        seqCount++;
      }
    }

    if (seqCount >= 3) return 35;
    if (seqCount >= 2) return 25;
    if (seqCount >= 1) return 15;
    return 0;
  }

  int _commonPatternPenalty(String password) {
    final List<String> commonPatterns = [
      'password', 'qwerty', 'abc123', 'letmein', 'admin', 'welcome',
      'master', 'dragon', 'login', 'princess', 'football', 'shadow',
      'sunshine', 'trustno1', 'iloveyou', 'batman', 'access', 'hello',
      'charlie', 'donald', 'password1', '12345678', '123456789',
      '1234567890', 'qwerty123', 'admin123', 'passw0rd',
    ];

    final String lower = password.toLowerCase();

    for (final String pattern in commonPatterns) {
      if (lower == pattern || lower.contains(pattern)) {
        return 50;
      }
    }

    return 0;
  }

  int _scoreBalance(String password) {
    if (password.length < 2) return 50;

    int lowerCount = 0;
    int upperCount = 0;
    int digitCount = 0;
    int symbolCount = 0;

    for (final int codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) {
        lowerCount++;
      } else if (codeUnit >= 65 && codeUnit <= 90) {
        upperCount++;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        digitCount++;
      } else {
        symbolCount++;
      }
    }

    final int total = password.length;
    final double lowerRatio = lowerCount / total;
    final double upperRatio = upperCount / total;
    final double digitRatio = digitCount / total;
    final double symbolRatio = symbolCount / total;

    final double mean = (lowerRatio + upperRatio + digitRatio + symbolRatio) / 4.0;

    final double variance = _sqrt(
            _pow(lowerRatio - mean) +
                _pow(upperRatio - mean) +
                _pow(digitRatio - mean) +
                _pow(symbolRatio - mean)) /
        4.0;

    final double deviation = _sqrt(variance);

    if (deviation < 0.05) return 100;
    if (deviation < 0.10) return 90;
    if (deviation < 0.15) return 80;
    if (deviation < 0.20) return 70;
    if (deviation < 0.30) return 55;
    if (deviation < 0.40) return 40;
    return 25;
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

  double _pow(double value) {
    return value * value;
  }

  StrengthLevel _determineLevel(int score) {
    if (score >= 97) return StrengthLevel.veryStrong;
    if (score >= 85) return StrengthLevel.excellent;
    if (score >= 75) return StrengthLevel.strong;
    if (score >= 60) return StrengthLevel.good;
    if (score >= 45) return StrengthLevel.fair;
    if (score >= 30) return StrengthLevel.weak;
    return StrengthLevel.veryWeak;
  }
}
