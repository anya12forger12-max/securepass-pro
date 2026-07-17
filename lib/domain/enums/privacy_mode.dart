enum PrivacyMode {
  standard('Standard', 'Normal privacy protections'),
  strict('Strict', 'Enhanced privacy protections'),
  lockdown('Lockdown', 'Maximum privacy - no data leaves device');

  const PrivacyMode(this.label, this.description);
  final String label;
  final String description;
}
