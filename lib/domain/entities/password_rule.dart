import 'package:securepass_pro/domain/enums/character_set_type.dart';

enum PasswordRuleType {
  minLength,
  maxLength,
  minUppercase,
  minLowercase,
  minNumbers,
  minSymbols,
  minUniqueChars,
  maxRepeated,
  noConsecutive,
  noSequential,
  mustStartWith,
  mustEndWith,
  noRepeatingWords,
  noKeyboardPatterns,
}

class PasswordRule {
  const PasswordRule({
    required this.type,
    required this.value,
    this.characterSetType,
  });

  final PasswordRuleType type;
  final dynamic value;
  final CharacterSetType? characterSetType;

  @override
  String toString() => '${type.name}=$value';
}
