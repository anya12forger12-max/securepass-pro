enum CharacterSetType {
  uppercase('Uppercase', 'A-Z'),
  lowercase('Lowercase', 'a-z'),
  numbers('Numbers', '0-9'),
  symbols('Symbols', '!@#\$%^&*...'),
  extendedSymbols('Extended Symbols', '~`\'"\\/...'),
  spaces('Spaces', 'Space character');

  const CharacterSetType(this.label, this.example);
  final String label;
  final String example;
}
