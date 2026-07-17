import 'package:flutter/material.dart';

enum GeneratorType {
  password('Password', Icons.password, 'Generate secure passwords'),
  passphrase('Passphrase', Icons.chat, 'Generate memorable passphrases'),
  pin('PIN', Icons.pin, 'Generate numeric PINs'),
  recoveryCode('Recovery Code', Icons.replay, 'Generate recovery codes'),
  apiToken('API Token', Icons.vpn_key, 'Generate secure API tokens'),
  uuid('UUID', Icons.fingerprint, 'Generate UUID identifiers'),
  hex('Hex String', Icons.code, 'Generate hexadecimal strings'),
  binary('Binary String', Icons.looks_one, 'Generate binary strings'),
  base32('Base32', Icons.abc, 'Generate Base32 encoded strings'),
  base58('Base58', Icons.abc, 'Generate Base58 encoded strings'),
  base64('Base64', Icons.abc, 'Generate Base64 encoded strings'),
  urlSafeToken('URL Safe Token', Icons.link, 'Generate URL-safe tokens'),
  randomString('Random String', Icons.casino, 'Generate random alphanumeric strings'),
  wifiPassword('Wi-Fi Password', Icons.wifi, 'Generate Wi-Fi passwords'),
  username('Username', Icons.person, 'Generate username suggestions'),
  randomBytes('Random Bytes', Icons.scatter_plot, 'Generate random byte arrays');

  const GeneratorType(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}
