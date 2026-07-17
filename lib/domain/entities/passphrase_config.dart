class PassphraseConfig {
  const PassphraseConfig({
    this.wordCount = 6,
    this.separator = '-',
    this.capitalize = false,
    this.includeNumber = false,
    this.includeSymbol = false,
    this.prefix = '',
    this.suffix = '',
    this.wordListLanguage = 'en',
  });

  final int wordCount;
  final String separator;
  final bool capitalize;
  final bool includeNumber;
  final bool includeSymbol;
  final String prefix;
  final String suffix;
  final String wordListLanguage;

  PassphraseConfig copyWith({
    int? wordCount,
    String? separator,
    bool? capitalize,
    bool? includeNumber,
    bool? includeSymbol,
    String? prefix,
    String? suffix,
    String? wordListLanguage,
  }) {
    return PassphraseConfig(
      wordCount: wordCount ?? this.wordCount,
      separator: separator ?? this.separator,
      capitalize: capitalize ?? this.capitalize,
      includeNumber: includeNumber ?? this.includeNumber,
      includeSymbol: includeSymbol ?? this.includeSymbol,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      wordListLanguage: wordListLanguage ?? this.wordListLanguage,
    );
  }
}
