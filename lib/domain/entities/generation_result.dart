import 'package:securepass_pro/domain/enums/generator_type.dart';

class GenerationResult {
  const GenerationResult({
    required this.value,
    required this.type,
    this.label,
    this.isFavorite = false,
    this.metadata = const {},
  });

  final String value;
  final GeneratorType type;
  final String? label;
  final bool isFavorite;
  final Map<String, dynamic> metadata;

  GenerationResult copyWith({String? value, String? label, bool? isFavorite, Map<String, dynamic>? metadata}) {
    return GenerationResult(
      value: value ?? this.value,
      type: type,
      label: label ?? this.label,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }
}

class BatchGenerationResult {
  const BatchGenerationResult({
    required this.results,
    required this.type,
    required this.generationTimeMs,
  });

  final List<GenerationResult> results;
  final GeneratorType type;
  final double generationTimeMs;

  int get count => results.length;
}
