import 'package:flutter/material.dart';

enum NavigationSection {
  home('Home', Icons.home_outlined, Icons.home),
  passwordGenerator('Password Generator', Icons.password_outlined, Icons.password),
  passphraseGenerator('Passphrase Generator', Icons.chat_outlined, Icons.chat),
  pinGenerator('PIN Generator', Icons.pin_outlined, Icons.pin),
  randomGenerator('Random Generator', Icons.casino_outlined, Icons.casino),
  uuidGenerator('UUID Generator', Icons.fingerprint_outlined, Icons.fingerprint),
  apiTokens('API Tokens', Icons.vpn_key_outlined, Icons.vpn_key),
  recoveryCodes('Recovery Codes', Icons.replay_outlined, Icons.replay),
  randomStrings('Random Strings', Icons.abc_outlined, Icons.abc),
  workspace('Workspace', Icons.workspaces_outlined, Icons.workspaces),
  diagnostics('Diagnostics', Icons.analytics_outlined, Icons.analytics),
  settings('Settings', Icons.settings_outlined, Icons.settings),
  themeStudio('Theme Studio', Icons.palette_outlined, Icons.palette),
  help('Help', Icons.help_outline, Icons.help),
  about('About', Icons.info_outline, Icons.info);

  const NavigationSection(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
