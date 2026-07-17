enum HistoryEntryType {
  password('Password'),
  passphrase('Passphrase'),
  pin('PIN'),
  recoveryCode('Recovery Code'),
  apiToken('API Token'),
  uuid('UUID'),
  hex('Hex String'),
  binary('Binary String'),
  base32('Base32'),
  base58('Base58'),
  base64('Base64'),
  urlSafeToken('URL Safe Token'),
  randomString('Random String'),
  wifiPassword('Wi-Fi Password'),
  username('Username'),
  randomBytes('Random Bytes');

  const HistoryEntryType(this.label);
  final String label;
}
