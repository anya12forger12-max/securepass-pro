enum ExportFormat {
  txt('Text File', 'txt'),
  csv('CSV', 'csv'),
  json('JSON', 'json'),
  markdown('Markdown', 'md'),
  html('HTML', 'html'),
  xml('XML', 'xml'),
  yaml('YAML', 'yaml'),
  encryptedJson('Encrypted JSON', 'enc.json');

  const ExportFormat(this.label, this.extension);
  final String label;
  final String extension;
}
