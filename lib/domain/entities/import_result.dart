class ImportedItem {
  const ImportedItem({
    required this.type,
    required this.name,
    this.success = true,
    this.message = '',
  });

  final String type;
  final String name;
  final bool success;
  final String message;
}

class ImportResult {
  const ImportResult({
    required this.success,
    required this.totalItems,
    required this.successfulItems,
    required this.failedItems,
    required this.importedItems,
    this.errorMessage,
  });

  final bool success;
  final int totalItems;
  final int successfulItems;
  final int failedItems;
  final List<ImportedItem> importedItems;
  final String? errorMessage;
}
