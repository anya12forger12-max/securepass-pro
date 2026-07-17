enum VaultEntryType {
  password('Password'),
  passphrase('Passphrase'),
  pin('PIN'),
  recoveryCode('Recovery Code'),
  apiToken('API Token'),
  other('Other');

  const VaultEntryType(this.label);
  final String label;
}
