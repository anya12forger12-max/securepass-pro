enum SecurityProfile {
  maximum('Maximum Security', 'Strongest protection, maximum restrictions'),
  balanced('Balanced', 'Good protection with usability'),
  accessibility('Accessibility Priority', 'Optimized for accessibility'),
  privacyMaximum('Privacy Maximum', 'Maximum privacy protection'),
  paranoid('Paranoid Mode', 'Extreme security measures');

  const SecurityProfile(this.label, this.description);
  final String label;
  final String description;
}
