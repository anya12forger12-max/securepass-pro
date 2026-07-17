enum PasswordPreset {
  simple('Simple', 12, true, true, false, false, false),
  strong('Strong', 20, true, true, true, true, false),
  maximumSecurity('Maximum Security', 32, true, true, true, true, true),
  banking('Banking', 24, true, true, true, true, true),
  developer('Developer', 16, true, true, true, false, false),
  ssh('SSH Key', 32, true, true, true, true, false),
  api('API Key', 40, true, true, true, true, true),
  database('Database', 20, true, true, true, true, false),
  wifi('Wi-Fi', 16, true, true, true, false, false),
  enterprise('Enterprise', 28, true, true, true, true, true),
  gaming('Gaming', 14, true, true, true, false, false),
  email('Email', 16, true, true, true, false, false);

  const PasswordPreset(
    this.label,
    this.length,
    this.uppercase,
    this.lowercase,
    this.numbers,
    this.symbols,
    this.extendedSymbols,
  );

  final String label;
  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool numbers;
  final bool symbols;
  final bool extendedSymbols;
}
