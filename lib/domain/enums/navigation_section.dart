import 'package:flutter/material.dart';

enum NavigationSection {
  home('Home', Icons.home_outlined, Icons.home, 'home'),
  passwordGenerator(
    'Password Generator',
    Icons.password_outlined,
    Icons.password,
    'password-generator',
  ),
  passphraseGenerator(
    'Passphrase Generator',
    Icons.chat_outlined,
    Icons.chat,
    'passphrase-generator',
  ),
  pinGenerator('PIN Generator', Icons.pin_outlined, Icons.pin, 'pin-generator'),
  randomGenerator(
    'Random Generator',
    Icons.casino_outlined,
    Icons.casino,
    'random-generator',
  ),
  uuidGenerator(
    'UUID Generator',
    Icons.fingerprint_outlined,
    Icons.fingerprint,
    'uuid-generator',
  ),
  apiTokens('API Tokens', Icons.vpn_key_outlined, Icons.vpn_key, 'api-tokens'),
  recoveryCodes(
    'Recovery Codes',
    Icons.replay_outlined,
    Icons.replay,
    'recovery-codes',
  ),
  randomStrings('Random Strings', Icons.abc_outlined, Icons.abc, 'random-strings'),
  workspace('Workspace', Icons.workspaces_outlined, Icons.workspaces, 'workspace'),
  diagnostics('Diagnostics', Icons.analytics_outlined, Icons.analytics, 'diagnostics'),
  settings('Settings', Icons.settings_outlined, Icons.settings, 'settings'),
  themeStudio('Theme Studio', Icons.palette_outlined, Icons.palette, 'theme-studio'),
  help('Help', Icons.help_outline, Icons.help, 'help'),
  about('About', Icons.info_outline, Icons.info, 'about');

  const NavigationSection(this.label, this.icon, this.activeIcon, this.path);
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
