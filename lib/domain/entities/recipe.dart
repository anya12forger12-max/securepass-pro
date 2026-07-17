import 'package:securepass_pro/domain/enums/generator_type.dart';
import 'package:securepass_pro/domain/entities/generation_config.dart';
import 'package:securepass_pro/domain/entities/passphrase_config.dart';
import 'package:securepass_pro/domain/entities/pin_config.dart';

class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required this.generatorType,
    this.description = '',
    this.passwordConfig,
    this.passphraseConfig,
    this.pinConfig,
    this.batchSize = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final GeneratorType generatorType;
  final String description;
  final GenerationConfig? passwordConfig;
  final PassphraseConfig? passphraseConfig;
  final PinConfig? pinConfig;
  final int batchSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe copyWith({
    String? name,
    String? description,
    GenerationConfig? passwordConfig,
    PassphraseConfig? passphraseConfig,
    PinConfig? pinConfig,
    int? batchSize,
  }) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      generatorType: generatorType,
      description: description ?? this.description,
      passwordConfig: passwordConfig ?? this.passwordConfig,
      passphraseConfig: passphraseConfig ?? this.passphraseConfig,
      pinConfig: pinConfig ?? this.pinConfig,
      batchSize: batchSize ?? this.batchSize,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
