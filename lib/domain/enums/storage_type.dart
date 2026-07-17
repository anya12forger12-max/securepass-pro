enum StorageType {
  preferences('Preferences'),
  cache('Cache'),
  session('Session'),
  encrypted('Encrypted');

  const StorageType(this.label);
  final String label;
}
