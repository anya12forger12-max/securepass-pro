import 'dart:math';

import 'package:securepass_pro/core/analysis/entropy_calculator.dart';
import 'package:securepass_pro/core/analysis/strength_calculator.dart';
import 'package:securepass_pro/core/analysis/quality_metrics.dart';
import 'package:securepass_pro/core/analysis/pattern_detector.dart';
import 'package:securepass_pro/core/analysis/character_distribution.dart';
import 'package:securepass_pro/services/password_policy_service.dart';
import 'package:securepass_pro/domain/entities/aging_estimate.dart';
import 'package:securepass_pro/domain/entities/comparison_result.dart';
import 'package:securepass_pro/domain/entities/analysis_report.dart';
import 'package:securepass_pro/domain/entities/policy_violation.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class PasswordAnalysisService {
  PasswordAnalysisService._();
  static final PasswordAnalysisService _instance = PasswordAnalysisService._();
  static PasswordAnalysisService get instance => _instance;

  void initialize() {
    AppLogger.instance.info(
      'Password analysis service initialized',
      category: 'ANALYSIS',
    );
  }

  AnalysisReport analyzePassword(String password) {
    final entropy = EntropyCalculator.instance.calculate(password);
    final strength = StrengthCalculator.instance.calculate(password);
    final quality = QualityMetricsCalculator.instance.calculate(password);
    final patterns = PatternDetector.instance.detect(password);
    final distribution = CharacterDistributionAnalyzer.instance.analyze(password);

    final policyResult =
        PasswordPolicyService.instance.validatePasswordAgainstActive(password);

    final suggestions = getSuggestionsForData(
      password: password,
      entropy: entropy,
      strength: strength,
      quality: quality,
      patterns: patterns,
      distribution: distribution,
      policyResult: policyResult,
    );

    final report = AnalysisReport(
      overallScore: strength.score,
      entropy: entropy,
      strength: strength,
      quality: quality,
      patterns: patterns,
      distribution: distribution,
      policyResult: policyResult,
      suggestions: suggestions,
      explanation: '',
    );

    final explanation = generateExplanation(report);

    return AnalysisReport(
      overallScore: report.overallScore,
      entropy: report.entropy,
      strength: report.strength,
      quality: report.quality,
      patterns: report.patterns,
      distribution: report.distribution,
      policyResult: report.policyResult,
      suggestions: report.suggestions,
      explanation: explanation,
      analyzedAt: report.analyzedAt,
    );
  }

  AnalysisReport analyzePassphrase(String passphrase) {
    final entropy = EntropyCalculator.instance.calculate(passphrase);
    final strength = StrengthCalculator.instance.calculate(passphrase);
    final quality = QualityMetricsCalculator.instance.calculate(passphrase);
    final patterns = PatternDetector.instance.detect(passphrase);
    final distribution =
        CharacterDistributionAnalyzer.instance.analyze(passphrase);

    final policyResult =
        PasswordPolicyService.instance.validatePasswordAgainstActive(passphrase);

    final wordCount = _countWords(passphrase);
    final hasMixedCase = _hasMixedCase(passphrase);
    final hasDigits = _hasDigits(passphrase);
    final hasSymbols = _hasSymbols(passphrase);

    final suggestions = <String>[];

    if (wordCount < 4) {
      suggestions.add(
        'Add more words to your passphrase for greater entropy (aim for 4-6 words)',
      );
    }

    if (!hasMixedCase) {
      suggestions.add(
        'Consider mixing uppercase and lowercase across words',
      );
    }

    if (!hasDigits && passphrase.length < 20) {
      suggestions.add(
        'Adding numbers between words can increase strength',
      );
    }

    if (!hasSymbols && passphrase.length < 24) {
      suggestions.add(
        'Adding symbols as word separators increases entropy',
      );
    }

    if (patterns.isNotEmpty) {
      final highSeverity =
          patterns.where((p) => p.severity == 'high').length;
      if (highSeverity > 0) {
        suggestions.add(
          'Strong patterns detected: avoid predictable word sequences',
        );
      }
    }

    if (policyResult != null && !policyResult.isValid) {
      for (final v in policyResult.violations) {
        suggestions.add(v.message);
      }
    }

    final report = AnalysisReport(
      overallScore: strength.score,
      entropy: entropy,
      strength: strength,
      quality: quality,
      patterns: patterns,
      distribution: distribution,
      policyResult: policyResult,
      suggestions: suggestions,
      explanation: '',
    );

    final explanation = generateExplanation(report);

    return AnalysisReport(
      overallScore: report.overallScore,
      entropy: report.entropy,
      strength: report.strength,
      quality: report.quality,
      patterns: report.patterns,
      distribution: report.distribution,
      policyResult: report.policyResult,
      suggestions: report.suggestions,
      explanation: explanation,
      analyzedAt: report.analyzedAt,
    );
  }

  ComparisonResult comparePasswords(String pw1, String pw2) {
    final entropy1 = EntropyCalculator.instance.calculate(pw1);
    final entropy2 = EntropyCalculator.instance.calculate(pw2);
    final strength1 = StrengthCalculator.instance.calculate(pw1);
    final strength2 = StrengthCalculator.instance.calculate(pw2);
    final dist1 = CharacterDistributionAnalyzer.instance.analyze(pw1);
    final dist2 = CharacterDistributionAnalyzer.instance.analyze(pw2);

    final unique1 = pw1.split('').toSet().length;
    final unique2 = pw2.split('').toSet().length;

    final classes1 = _countCharClasses(pw1);
    final classes2 = _countCharClasses(pw2);

    final int score1 = strength1.score;
    final int score2 = strength2.score;

    int winner;
    if (score1 > score2) {
      winner = 1;
    } else if (score2 > score1) {
      winner = -1;
    } else {
      if (entropy1.bits > entropy2.bits) {
        winner = 1;
      } else if (entropy2.bits > entropy1.bits) {
        winner = -1;
      } else {
        winner = 0;
      }
    }

    final items = <ComparisonItem>[
      ComparisonItem(
        label: 'Length',
        value1: '${pw1.length}',
        value2: '${pw2.length}',
        isIdentical: pw1.length == pw2.length,
      ),
      ComparisonItem(
        label: 'Entropy (bits)',
        value1: entropy1.bits.toStringAsFixed(1),
        value2: entropy2.bits.toStringAsFixed(1),
        isIdentical: entropy1.bits == entropy2.bits,
      ),
      ComparisonItem(
        label: 'Strength Score',
        value1: '${strength1.score}',
        value2: '${strength2.score}',
        isIdentical: strength1.score == strength2.score,
      ),
      ComparisonItem(
        label: 'Strength Level',
        value1: strength1.label,
        value2: strength2.label,
        isIdentical: strength1.level == strength2.level,
      ),
      ComparisonItem(
        label: 'Unique Characters',
        value1: '$unique1',
        value2: '$unique2',
        isIdentical: unique1 == unique2,
      ),
      ComparisonItem(
        label: 'Character Classes',
        value1: '$classes1',
        value2: '$classes2',
        isIdentical: classes1 == classes2,
      ),
      ComparisonItem(
        label: 'Distribution Balance',
        value1: dist1.distributionBalance.toStringAsFixed(2),
        value2: dist2.distributionBalance.toStringAsFixed(2),
        isIdentical:
            dist1.distributionBalance == dist2.distributionBalance,
      ),
      ComparisonItem(
        label: 'Randomness',
        value1: entropy1.randomnessEstimate.toStringAsFixed(3),
        value2: entropy2.randomnessEstimate.toStringAsFixed(3),
        isIdentical:
            entropy1.randomnessEstimate == entropy2.randomnessEstimate,
      ),
    ];

    String summary;
    if (winner == 1) {
      summary = 'Password 1 is stronger with a score of ${strength1.score} '
          'vs ${strength2.score}';
    } else if (winner == -1) {
      summary = 'Password 2 is stronger with a score of ${strength2.score} '
          'vs ${strength1.score}';
    } else {
      summary = 'Both passwords have equal strength with a score of '
          '${strength1.score}';
    }

    return ComparisonResult(
      items: items,
      password1Entropy: entropy1.bits,
      password2Entropy: entropy2.bits,
      password1Strength: strength1.score,
      password2Strength: strength2.score,
      winner: winner,
      summary: summary,
    );
  }

  AgingEstimate estimateAging(String password) {
    final entropy = EntropyCalculator.instance.calculate(password);
    final bits = entropy.bits;

    final String rating = entropy.rating;

    final String classicalYears = _estimateClassicalCrackTime(bits);
    final String quantumYears = _estimateQuantumCrackTime(bits);
    final String quantumResistance =
        _assessQuantumResistance(bits);

    final recommendations = <String>[];

    if (bits < 40) {
      recommendations.add(
        'This password can be cracked almost instantly. Choose a much longer password',
      );
    } else if (bits < 60) {
      recommendations.add(
        'This password provides weak protection. Increase length and character diversity',
      );
    } else if (bits < 80) {
      recommendations.add(
        'This password is moderately secure. Consider adding more unique characters',
      );
    } else if (bits < 100) {
      recommendations.add(
        'This password is strong but could benefit from additional length',
      );
    }

    final uniqueRatio =
        password.split('').toSet().length / max(password.length, 1);
    if (uniqueRatio < 0.6) {
      recommendations.add(
        'Low character diversity detected. Use more unique characters',
      );
    }

    final bool hasAllClasses = _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigits(password) &&
        _hasSymbols(password);
    if (!hasAllClasses) {
      recommendations.add(
        'Mix uppercase, lowercase, digits, and symbols for maximum entropy',
      );
    }

    if (password.length < 16) {
      recommendations.add(
        'Aim for at least 16 characters to future-proof against advancing hardware',
      );
    }

    if (bits < 80) {
      recommendations.add(
        'Consider using a passphrase with 4-6 random words for better security and memorability',
      );
    }

    return AgingEstimate(
      currentBits: bits,
      currentRating: rating,
      estimatedYearsToCrack: classicalYears,
      quantumResistance: quantumResistance,
      quantumYearsToCrack: quantumYears,
      recommendations: recommendations,
    );
  }

  PolicyValidationResult? validateAgainstPolicy(
    String password,
    String? policyId,
  ) {
    if (policyId == null) {
      return PasswordPolicyService.instance
          .validatePasswordAgainstActive(password);
    }
    final policy =
        PasswordPolicyService.instance.getPolicyById(policyId);
    if (policy == null) return null;
    return PasswordPolicyService.instance.validatePassword(password, policy);
  }

  int getQuickScore(String password) {
    if (password.isEmpty) return 0;
    final strength = StrengthCalculator.instance.calculate(password);
    return strength.score;
  }

  String generateExplanation(AnalysisReport report) {
    final buffer = StringBuffer();
    final score = report.overallScore;

    buffer.write('Overall Score: $score/100. ');

    if (score >= 85) {
      buffer.write(
        'This password is excellent. ',
      );
    } else if (score >= 70) {
      buffer.write(
        'This password is strong. ',
      );
    } else if (score >= 50) {
      buffer.write(
        'This password provides moderate protection. ',
      );
    } else if (score >= 30) {
      buffer.write(
        'This password is weak and should be improved. ',
      );
    } else {
      buffer.write(
        'This password is very weak and should be changed immediately. ',
      );
    }

    buffer.write(
      'Entropy is ${report.entropy.bits.toStringAsFixed(1)} bits '
      '(${report.entropy.rating}). ',
    );

    buffer.write(
      'Character distribution: '
      '${report.distribution.uppercasePercent.toStringAsFixed(0)}% uppercase, '
      '${report.distribution.lowercasePercent.toStringAsFixed(0)}% lowercase, '
      '${report.distribution.numbersPercent.toStringAsFixed(0)}% digits, '
      '${report.distribution.symbolsPercent.toStringAsFixed(0)}% symbols. ',
    );

    if (report.patterns.isNotEmpty) {
      final highPatterns =
          report.patterns.where((p) => p.severity == 'high').length;
      final medPatterns =
          report.patterns.where((p) => p.severity == 'medium').length;
      buffer.write(
        '${report.patterns.length} pattern(s) detected '
        '($highPatterns high, $medPatterns medium severity). ',
      );
    }

    if (report.policyResult != null && !report.policyResult!.isValid) {
      buffer.write(
        '${report.policyResult!.violations.length} policy violation(s) found. ',
      );
    }

    return buffer.toString();
  }

  List<String> getSuggestions(AnalysisReport report) {
    return report.suggestions;
  }

  void clearSensitiveData() {
    AppLogger.instance.info(
      'Sensitive analysis data cleared',
      category: 'ANALYSIS',
    );
  }

  List<String> getSuggestionsForData({
    required String password,
    required EntropyResult entropy,
    required StrengthResult strength,
    required QualityMetrics quality,
    required List<DetectedPattern> patterns,
    required CharacterDistribution distribution,
    required PolicyValidationResult? policyResult,
  }) {
    final suggestions = <String>[];

    if (password.length < 12) {
      suggestions.add(
        'Increase password length to at least 12 characters for better security',
      );
    }

    if (entropy.bits < 50) {
      suggestions.add(
        'Entropy is low (${entropy.bits.toStringAsFixed(1)} bits). '
        'Add more character variety to increase randomness',
      );
    }

    final classes = _countCharClasses(password);
    if (classes < 3) {
      suggestions.add(
        'Use at least 3 different character classes '
        '(uppercase, lowercase, digits, symbols)',
      );
    }

    final uniqueRatio =
        password.split('').toSet().length / max(password.length, 1);
    if (uniqueRatio < 0.5) {
      suggestions.add(
        'Character diversity is low. Use more unique characters and reduce repetition',
      );
    }

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
    if (maxRun >= 3) {
      suggestions.add(
        'Avoid repeating the same character $maxRun times in a row',
      );
    }

    if (patterns.isNotEmpty) {
      final highSeverity =
          patterns.where((p) => p.severity == 'high').toList();
      for (final p in highSeverity) {
        suggestions.add('Pattern detected: ${p.description}');
      }
    }

    if (quality.randomnessScore < 50) {
      suggestions.add(
        'Randomness score is low. A password manager can generate truly random passwords',
      );
    }

    if (password.length >= 8 &&
        password.length < 16 &&
        classes >= 3 &&
        uniqueRatio > 0.7) {
      suggestions.add(
        'Good foundation. Consider extending to 16+ characters for future-proofing',
      );
    }

    if (policyResult != null && !policyResult.isValid) {
      for (final v in policyResult.violations) {
        if (!suggestions.contains(v.message)) {
          suggestions.add(v.message);
        }
      }
    }

    if (password.length > 20 && classes >= 3 && uniqueRatio > 0.6) {
      if (suggestions.isEmpty) {
        suggestions.add(
          'This is a strong password. Keep it stored securely',
        );
      }
    }

    return suggestions;
  }

  String _estimateClassicalCrackTime(double bits) {
    const guessesPerSecond = 1e10;
    final totalGuesses = pow(2, bits);
    final seconds = totalGuesses / guessesPerSecond;

    if (seconds < 1) return 'Instant';
    if (seconds < 60) return '${seconds.toStringAsFixed(1)} seconds';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)} minutes';
    if (seconds < 86400) return '${(seconds / 3600).toStringAsFixed(1)} hours';
    if (seconds < 86400 * 30) {
      return '${(seconds / 86400).toStringAsFixed(1)} days';
    }
    if (seconds < 86400 * 365) {
      return '${(seconds / (86400 * 30)).toStringAsFixed(1)} months';
    }
    if (seconds < 86400 * 365 * 1000) {
      return '${(seconds / (86400 * 365)).toStringAsFixed(1)} years';
    }
    if (seconds < 86400 * 365 * 1e6) {
      return '${(seconds / (86400 * 365 * 1000)).toStringAsFixed(1)} thousand years';
    }
    if (seconds < 86400 * 365 * 1e9) {
      return '${(seconds / (86400 * 365 * 1e6)).toStringAsFixed(1)} million years';
    }
    if (seconds < 86400 * 365 * 1e12) {
      return '${(seconds / (86400 * 365 * 1e9)).toStringAsFixed(1)} billion years';
    }
    return 'Beyond measurable time';
  }

  String _estimateQuantumCrackTime(double bits) {
    final quantumBits = bits / 2.0;
    const guessesPerSecond = 1e10;
    final totalGuesses = pow(2, quantumBits);
    final seconds = totalGuesses / guessesPerSecond;

    if (seconds < 1) return 'Instant';
    if (seconds < 60) return '${seconds.toStringAsFixed(1)} seconds';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)} minutes';
    if (seconds < 86400) return '${(seconds / 3600).toStringAsFixed(1)} hours';
    if (seconds < 86400 * 30) {
      return '${(seconds / 86400).toStringAsFixed(1)} days';
    }
    if (seconds < 86400 * 365) {
      return '${(seconds / (86400 * 30)).toStringAsFixed(1)} months';
    }
    if (seconds < 86400 * 365 * 1000) {
      return '${(seconds / (86400 * 365)).toStringAsFixed(1)} years';
    }
    if (seconds < 86400 * 365 * 1e6) {
      return '${(seconds / (86400 * 365 * 1000)).toStringAsFixed(1)} thousand years';
    }
    if (seconds < 86400 * 365 * 1e9) {
      return '${(seconds / (86400 * 365 * 1e6)).toStringAsFixed(1)} million years';
    }
    if (seconds < 86400 * 365 * 1e12) {
      return '${(seconds / (86400 * 365 * 1e9)).toStringAsFixed(1)} billion years';
    }
    return 'Beyond measurable time';
  }

  String _assessQuantumResistance(double bits) {
    final quantumBits = bits / 2.0;
    if (quantumBits < 40) return 'Vulnerable to quantum attacks';
    if (quantumBits < 60) return 'Weak quantum resistance';
    if (quantumBits < 80) return 'Moderate quantum resistance';
    if (quantumBits < 100) return 'Strong quantum resistance';
    return 'Excellent quantum resistance';
  }

  int _countCharClasses(String password) {
    int classes = 0;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSymbol = false;

    for (final codeUnit in password.codeUnits) {
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

    if (hasLower) classes++;
    if (hasUpper) classes++;
    if (hasDigit) classes++;
    if (hasSymbol) classes++;
    return classes;
  }

  bool _hasUppercase(String password) {
    for (final codeUnit in password.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) return true;
    }
    return false;
  }

  bool _hasLowercase(String password) {
    for (final codeUnit in password.codeUnits) {
      if (codeUnit >= 97 && codeUnit <= 122) return true;
    }
    return false;
  }

  bool _hasDigits(String password) {
    for (final codeUnit in password.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) return true;
    }
    return false;
  }

  bool _hasSymbols(String password) {
    for (final codeUnit in password.codeUnits) {
      if ((codeUnit >= 32 && codeUnit <= 47) ||
          (codeUnit >= 58 && codeUnit <= 64) ||
          (codeUnit >= 91 && codeUnit <= 96) ||
          (codeUnit >= 123 && codeUnit <= 126)) {
        return true;
      }
    }
    return false;
  }

  bool _hasMixedCase(String password) {
    return _hasUppercase(password) && _hasLowercase(password);
  }

  int _countWords(String passphrase) {
    final trimmed = passphrase.trim();
    if (trimmed.isEmpty) return 0;
    final separators = RegExp(r'[\s_\-.,;:]+');
    return trimmed.split(separators).where((w) => w.isNotEmpty).length;
  }
}
