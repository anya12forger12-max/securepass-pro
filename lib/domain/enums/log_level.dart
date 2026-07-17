enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  severe(4, 'SEVERE');

  const LogLevel(this.value, this.label);
  final int value;
  final String label;
}
