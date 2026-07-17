import 'package:securepass_pro/core/analysis/entropy_calculator.dart';
import 'package:securepass_pro/core/analysis/strength_calculator.dart';
import 'package:securepass_pro/core/analysis/quality_metrics.dart';
import 'package:securepass_pro/core/analysis/pattern_detector.dart';
import 'package:securepass_pro/core/analysis/character_distribution.dart';

class PasswordAnalysis {
  final EntropyResult entropy;
  final StrengthResult strength;
  final QualityMetrics quality;
  final List<DetectedPattern> patterns;
  final CharacterDistribution distribution;
  final int overallScore;
  final List<String> suggestions;
  final String explanation;

  const PasswordAnalysis({
    required this.entropy,
    required this.strength,
    required this.quality,
    required this.patterns,
    required this.distribution,
    required this.overallScore,
    required this.suggestions,
    required this.explanation,
  });
}

class PasswordAnalyzer {
  static final PasswordAnalyzer instance = PasswordAnalyzer._();

  const PasswordAnalyzer._();

  PasswordAnalysis analyze(String password) {
    final EntropyResult entropy =
        EntropyCalculator.instance.calculate(password);
    final StrengthResult strength =
        StrengthCalculator.instance.calculate(password);
    final QualityMetrics quality =
        QualityMetricsCalculator.instance.calculate(password);
    final List<DetectedPattern> patterns =
        PatternDetector.instance.detect(password);
    final CharacterDistribution distribution =
        CharacterDistributionAnalyzer.instance.analyze(password);

    final int overallScore =
        _calculateOverallScore(strength, quality, patterns);
    final List<String> suggestions =
        _generateSuggestions(password, entropy, strength, quality, patterns, distribution);
    final String explanation =
        _generateExplanation(password, entropy, strength, quality, patterns, distribution, overallScore);

    return PasswordAnalysis(
      entropy: entropy,
      strength: strength,
      quality: quality,
      patterns: patterns,
      distribution: distribution,
      overallScore: overallScore,
      suggestions: suggestions,
      explanation: explanation,
    );
  }

  int _calculateOverallScore(
    StrengthResult strength,
    QualityMetrics quality,
    List<DetectedPattern> patterns,
  ) {
    final int qualityComposite = (
      quality.lengthScore * 0.10 +
      quality.complexityScore * 0.20 +
      quality.randomnessScore * 0.20 +
      quality.uniqueCharsScore * 0.15 +
      quality.repeatedCharsScore * 0.10 +
      quality.distributionScore * 0.10 +
      quality.patternResistanceScore * 0.15
    ).round();

    int patternPenalty = 0;
    for (final DetectedPattern pattern in patterns) {
      switch (pattern.severity) {
        case 'high':
          patternPenalty += 15;
          break;
        case 'medium':
          patternPenalty += 8;
          break;
        case 'low':
          patternPenalty += 3;
          break;
      }
    }
    patternPenalty = patternPenalty.clamp(0, 40);

    final int rawScore = ((strength.score * 0.50) +
            (qualityComposite * 0.35) -
            (patternPenalty * 0.15 * 100 / 40))
        .round();

    return rawScore.clamp(0, 100);
  }

  List<String> _generateSuggestions(
    String password,
    EntropyResult entropy,
    StrengthResult strength,
    QualityMetrics quality,
    List<DetectedPattern> patterns,
    CharacterDistribution distribution,
  ) {
    final List<String> suggestions = [];

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

    if (password.length < 8) {
      suggestions.add(
          'Increase password length to at least 8 characters (currently ${password.length}).');
    } else if (password.length < 12) {
      suggestions.add(
          'Consider making the password longer. 12+ characters recommended.');
    }

    if (!hasLower) {
      suggestions.add('Add lowercase letters (a-z) to increase complexity.');
    }
    if (!hasUpper) {
      suggestions.add('Add uppercase letters (A-Z) to increase complexity.');
    }
    if (!hasDigit) {
      suggestions.add('Add numbers (0-9) to increase complexity.');
    }
    if (!hasSymbol) {
      suggestions.add(
          'Add special characters (!@#\$%^&*) to increase complexity.');
    }

    int repeatedPenalties = 0;
    for (final DetectedPattern pattern in patterns) {
      if (pattern.type == PatternType.repeatedChars) {
        repeatedPenalties++;
      }
    }
    if (repeatedPenalties > 0) {
      suggestions.add(
          'Avoid repeating characters. Replace repeated characters with different ones.');
    }

    int sequentialPenalties = 0;
    for (final DetectedPattern pattern in patterns) {
      if (pattern.type == PatternType.sequentialChars) {
        sequentialPenalties++;
      }
    }
    if (sequentialPenalties > 0) {
      suggestions.add(
          'Avoid sequential characters like "abc" or "123". Use random characters instead.');
    }

    int commonPatternCount = 0;
    for (final DetectedPattern pattern in patterns) {
      if (pattern.type == PatternType.dictionaryWord ||
          pattern.type == PatternType.keyboardPattern ||
          pattern.type == PatternType.commonSubstitution) {
        commonPatternCount++;
      }
    }
    if (commonPatternCount > 0) {
      suggestions.add(
          'Avoid common words and keyboard patterns. Use a unique combination of characters.');
    }

    if (entropy.bits < 40) {
      suggestions.add(
          'Password entropy is low (${entropy.bits.toStringAsFixed(1)} bits). Add more character variety.');
    }

    if (distribution.distributionBalance < 0.5) {
      suggestions.add(
          'Character distribution is uneven. Try to use all character types more equally.');
    }

    if (quality.repeatedCharsScore < 60) {
      suggestions.add(
          'Reduce character repetition. Each character should ideally appear only once.');
    }

    int wordPatternCount = 0;
    for (final DetectedPattern pattern in patterns) {
      if (pattern.type == PatternType.repeatedWords ||
          pattern.type == PatternType.repeatedGroups) {
        wordPatternCount++;
      }
    }
    if (wordPatternCount > 0) {
      suggestions.add(
          'Avoid repeating words or groups of characters. Use varied content throughout.');
    }

    int weakRepetitionCount = 0;
    for (final DetectedPattern pattern in patterns) {
      if (pattern.type == PatternType.weakRepetition) {
        weakRepetitionCount++;
      }
    }
    if (weakRepetitionCount > 0) {
      suggestions.add(
          'Avoid simple repeating patterns like "abab". Use more complex structures.');
    }

    if (suggestions.isEmpty && password.isNotEmpty) {
      suggestions.add(
          'Password looks good! Consider adding more length or special characters for maximum security.');
    }

    return suggestions;
  }

  String _generateExplanation(
    String password,
    EntropyResult entropy,
    StrengthResult strength,
    QualityMetrics quality,
    List<DetectedPattern> patterns,
    CharacterDistribution distribution,
    int overallScore,
  ) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('Password Security Analysis');
    buffer.writeln('========================');
    buffer.writeln();
    buffer.writeln(
        'This password is ${password.length} characters long and uses a character pool of ${entropy.poolSize} possible characters.');
    buffer.writeln(
        'The estimated entropy is ${entropy.bits.toStringAsFixed(1)} bits, rated as "${entropy.rating}".');
    buffer.writeln();

    buffer.writeln('Strength Assessment:');
    buffer.writeln(
        '  Score: ${strength.score}/100 - ${strength.label}');
    buffer.writeln('  ${strength.description}');
    buffer.writeln();

    buffer.writeln('Character Distribution:');
    buffer.writeln(
        '  Uppercase: ${distribution.uppercasePercent.toStringAsFixed(1)}%');
    buffer.writeln(
        '  Lowercase: ${distribution.lowercasePercent.toStringAsFixed(1)}%');
    buffer.writeln(
        '  Numbers: ${distribution.numbersPercent.toStringAsFixed(1)}%');
    buffer.writeln(
        '  Symbols: ${distribution.symbolsPercent.toStringAsFixed(1)}%');
    buffer.writeln(
        '  Unique characters: ${distribution.uniqueCharCount}/${distribution.totalLength}');
    buffer.writeln(
        '  Distribution balance: ${(distribution.distributionBalance * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    if (patterns.isNotEmpty) {
      buffer.writeln('Detected Weaknesses:');
      for (final DetectedPattern pattern in patterns) {
        buffer.writeln(
            '  [${pattern.severity.toUpperCase()}] ${pattern.description}');
      }
      buffer.writeln();
    } else {
      buffer.writeln('No significant patterns or weaknesses detected.');
      buffer.writeln();
    }

    buffer.writeln(
        'Attack Resistance:');
    buffer.writeln(
        '  Online attacks: ${entropy.resistanceToOnlineAttack}');
    buffer.writeln(
        '  Offline attacks: ${entropy.resistanceToOfflineAttack}');
    buffer.writeln();

    buffer.writeln('Overall Security Score: $overallScore/100');

    if (overallScore >= 85) {
      buffer.writeln(
          'This is an excellent password providing strong security protection.');
    } else if (overallScore >= 70) {
      buffer.writeln(
          'This is a good password with reasonable security properties.');
    } else if (overallScore >= 50) {
      buffer.writeln(
          'This password provides moderate security. Consider improving it.');
    } else if (overallScore >= 30) {
      buffer.writeln(
          'This password has weak security characteristics. Improvement recommended.');
    } else {
      buffer.writeln(
          'This password has very weak security. It should be replaced immediately.');
    }

    return buffer.toString();
  }
}
