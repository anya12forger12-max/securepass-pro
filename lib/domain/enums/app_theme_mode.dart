enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  system('System'),
  highContrast('High Contrast'),
  ultraHighContrast('Ultra High Contrast');

  const AppThemeMode(this.label);
  final String label;
}
