import 'package:securepass_pro/domain/enums/character_set_type.dart';

class GenerationConfig {
  const GenerationConfig({
    this.length = 24,
    this.charSets = const {CharacterSetType.uppercase, CharacterSetType.lowercase, CharacterSetType.numbers, CharacterSetType.symbols},
    this.exclusions = const {},
    this.customChars = '',
    this.minUppercase = 0,
    this.minLowercase = 0,
    this.minNumbers = 0,
    this.minSymbols = 0,
    this.minUniqueChars = 0,
    this.maxRepeated = 0,
    this.noConsecutive = false,
    this.noSequential = false,
    this.mustStartWith,
    this.mustEndWith,
  });

  final int length;
  final Set<CharacterSetType> charSets;
  final Set<String> exclusions;
  final String customChars;
  final int minUppercase;
  final int minLowercase;
  final int minNumbers;
  final int minSymbols;
  final int minUniqueChars;
  final int maxRepeated;
  final bool noConsecutive;
  final bool noSequential;
  final CharacterSetType? mustStartWith;
  final CharacterSetType? mustEndWith;

  GenerationConfig copyWith({
    int? length,
    Set<CharacterSetType>? charSets,
    Set<String>? exclusions,
    String? customChars,
    int? minUppercase,
    int? minLowercase,
    int? minNumbers,
    int? minSymbols,
    int? minUniqueChars,
    int? maxRepeated,
    bool? noConsecutive,
    bool? noSequential,
    CharacterSetType? mustStartWith,
    CharacterSetType? mustEndWith,
  }) {
    return GenerationConfig(
      length: length ?? this.length,
      charSets: charSets ?? this.charSets,
      exclusions: exclusions ?? this.exclusions,
      customChars: customChars ?? this.customChars,
      minUppercase: minUppercase ?? this.minUppercase,
      minLowercase: minLowercase ?? this.minLowercase,
      minNumbers: minNumbers ?? this.minNumbers,
      minSymbols: minSymbols ?? this.minSymbols,
      minUniqueChars: minUniqueChars ?? this.minUniqueChars,
      maxRepeated: maxRepeated ?? this.maxRepeated,
      noConsecutive: noConsecutive ?? this.noConsecutive,
      noSequential: noSequential ?? this.noSequential,
      mustStartWith: mustStartWith ?? this.mustStartWith,
      mustEndWith: mustEndWith ?? this.mustEndWith,
    );
  }
}
