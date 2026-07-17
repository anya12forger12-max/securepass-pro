import 'package:flutter/material.dart';

enum DiagnosticStatus {
  healthy('Healthy', Icons.check_circle),
  warning('Warning', Icons.warning),
  error('Error', Icons.error),
  unknown('Unknown', Icons.help_outline);

  const DiagnosticStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}
