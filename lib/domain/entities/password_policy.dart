import 'dart:convert';

class PasswordPolicy {
  const PasswordPolicy({
    required this.id,
    required this.name,
    this.description = '',
    this.minLength = 8,
    this.maxLength = 128,
    this.minUppercase = 1,
    this.minLowercase = 1,
    this.minDigits = 1,
    this.minSymbols = 0,
    this.minUniqueChars = 0,
    this.maxRepeated = 0,
    this.maxConsecutive = 0,
    this.allowUppercase = true,
    this.allowLowercase = true,
    this.allowDigits = true,
    this.allowSymbols = true,
    this.allowSpaces = false,
    this.blockedChars = const {},
    this.requiredPrefix = '',
    this.requiredSuffix = '',
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final int minLength;
  final int maxLength;
  final int minUppercase;
  final int minLowercase;
  final int minDigits;
  final int minSymbols;
  final int minUniqueChars;
  final int maxRepeated;
  final int maxConsecutive;
  final bool allowUppercase;
  final bool allowLowercase;
  final bool allowDigits;
  final bool allowSymbols;
  final bool allowSpaces;
  final Set<String> blockedChars;
  final String requiredPrefix;
  final String requiredSuffix;
  final bool isCustom;

  PasswordPolicy copyWith({
    String? id,
    String? name,
    String? description,
    int? minLength,
    int? maxLength,
    int? minUppercase,
    int? minLowercase,
    int? minDigits,
    int? minSymbols,
    int? minUniqueChars,
    int? maxRepeated,
    int? maxConsecutive,
    bool? allowUppercase,
    bool? allowLowercase,
    bool? allowDigits,
    bool? allowSymbols,
    bool? allowSpaces,
    Set<String>? blockedChars,
    String? requiredPrefix,
    String? requiredSuffix,
    bool? isCustom,
  }) {
    return PasswordPolicy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      minUppercase: minUppercase ?? this.minUppercase,
      minLowercase: minLowercase ?? this.minLowercase,
      minDigits: minDigits ?? this.minDigits,
      minSymbols: minSymbols ?? this.minSymbols,
      minUniqueChars: minUniqueChars ?? this.minUniqueChars,
      maxRepeated: maxRepeated ?? this.maxRepeated,
      maxConsecutive: maxConsecutive ?? this.maxConsecutive,
      allowUppercase: allowUppercase ?? this.allowUppercase,
      allowLowercase: allowLowercase ?? this.allowLowercase,
      allowDigits: allowDigits ?? this.allowDigits,
      allowSymbols: allowSymbols ?? this.allowSymbols,
      allowSpaces: allowSpaces ?? this.allowSpaces,
      blockedChars: blockedChars ?? this.blockedChars,
      requiredPrefix: requiredPrefix ?? this.requiredPrefix,
      requiredSuffix: requiredSuffix ?? this.requiredSuffix,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minLength': minLength,
      'maxLength': maxLength,
      'minUppercase': minUppercase,
      'minLowercase': minLowercase,
      'minDigits': minDigits,
      'minSymbols': minSymbols,
      'minUniqueChars': minUniqueChars,
      'maxRepeated': maxRepeated,
      'maxConsecutive': maxConsecutive,
      'allowUppercase': allowUppercase,
      'allowLowercase': allowLowercase,
      'allowDigits': allowDigits,
      'allowSymbols': allowSymbols,
      'allowSpaces': allowSpaces,
      'blockedChars': blockedChars.toList(),
      'requiredPrefix': requiredPrefix,
      'requiredSuffix': requiredSuffix,
      'isCustom': isCustom,
    };
  }

  factory PasswordPolicy.fromMap(Map<String, dynamic> map) {
    return PasswordPolicy(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      minLength: map['minLength'] as int? ?? 8,
      maxLength: map['maxLength'] as int? ?? 128,
      minUppercase: map['minUppercase'] as int? ?? 1,
      minLowercase: map['minLowercase'] as int? ?? 1,
      minDigits: map['minDigits'] as int? ?? 1,
      minSymbols: map['minSymbols'] as int? ?? 0,
      minUniqueChars: map['minUniqueChars'] as int? ?? 0,
      maxRepeated: map['maxRepeated'] as int? ?? 0,
      maxConsecutive: map['maxConsecutive'] as int? ?? 0,
      allowUppercase: map['allowUppercase'] as bool? ?? true,
      allowLowercase: map['allowLowercase'] as bool? ?? true,
      allowDigits: map['allowDigits'] as bool? ?? true,
      allowSymbols: map['allowSymbols'] as bool? ?? true,
      allowSpaces: map['allowSpaces'] as bool? ?? false,
      blockedChars: (map['blockedChars'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      requiredPrefix: map['requiredPrefix'] as String? ?? '',
      requiredSuffix: map['requiredSuffix'] as String? ?? '',
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PasswordPolicy.fromJson(String source) =>
      PasswordPolicy.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordPolicy && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PasswordPolicy(id: $id, name: $name)';
}
