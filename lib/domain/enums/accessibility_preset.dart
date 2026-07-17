enum AccessibilityPreset {
  defaultPreset('Default', 'Standard accessibility settings'),
  highContrast('High Contrast', 'Enhanced color contrast'),
  largeText('Large Text', 'Increased font sizes'),
  reducedMotion('Reduced Motion', 'Minimized animations'),
  dyslexiaFriendly('Dyslexia Friendly', 'Optimized for dyslexia'),
  screenReader('Screen Reader', 'Optimized for screen readers'),
  maximumAccessibility('Maximum Accessibility', 'All accessibility features enabled');

  const AccessibilityPreset(this.label, this.description);
  final String label;
  final String description;
}
