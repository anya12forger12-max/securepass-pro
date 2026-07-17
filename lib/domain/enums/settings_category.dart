import 'package:flutter/material.dart';

enum SettingsCategory {
  general('General', Icons.tune),
  appearance('Appearance', Icons.palette),
  accessibility('Accessibility', Icons.accessibility_new),
  security('Security', Icons.shield),
  privacy('Privacy', Icons.privacy_tip),
  clipboard('Clipboard', Icons.content_paste),
  generation('Generation', Icons.password),
  workspace('Workspace', Icons.workspaces),
  export('Export', Icons.import_export),
  diagnostics('Diagnostics', Icons.analytics),
  performance('Performance', Icons.speed),
  developer('Developer', Icons.code),
  experimental('Experimental', Icons.science);

  const SettingsCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
