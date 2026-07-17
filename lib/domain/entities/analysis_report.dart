import 'package:securepass_pro/core/analysis/entropy_calculator.dart';
import 'package:securepass_pro/core/analysis/strength_calculator.dart';
import 'package:securepass_pro/core/analysis/quality_metrics.dart';
import 'package:securepass_pro/core/analysis/pattern_detector.dart';
import 'package:securepass_pro/core/analysis/character_distribution.dart';
import 'package:securepass_pro/domain/entities/policy_violation.dart';

class AnalysisReport {
  AnalysisReport({
    required this.overallScore,
    required this.entropy,
    required this.strength,
    required this.quality,
    required this.patterns,
    required this.distribution,
    this.policyResult,
    required this.suggestions,
    required this.explanation,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  final int overallScore;
  final EntropyResult entropy;
  final StrengthResult strength;
  final QualityMetrics quality;
  final List<DetectedPattern> patterns;
  final CharacterDistribution distribution;
  final PolicyValidationResult? policyResult;
  final List<String> suggestions;
  final String explanation;
  final DateTime analyzedAt;

  @override
  String toString() =>
      'AnalysisReport(score: $overallScore, strength: ${strength.label})';
}
