import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/services/clipboard_service.dart';

class ProductivityAction {
  const ProductivityAction({
    required this.type,
    required this.description,
    this.data = const {},
    this.undoData,
    required this.timestamp,
  });

  final String type;
  final String description;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? undoData;
  final DateTime timestamp;
}

class ProductivityService {
  ProductivityService._();
  static final ProductivityService _instance = ProductivityService._();
  static ProductivityService get instance => _instance;

  final List<ProductivityAction> _undoStack = [];
  final List<ProductivityAction> _redoStack = [];
  final List<ProductivityAction> _recentActions = [];
  final int _maxUndo = 50;
  static const int _maxRecent = 200;

  Future<void> initialize() async {
    AppLogger.instance.info(
      'ProductivityService initialized',
      category: 'ProductivityService',
    );
  }

  void recordAction(ProductivityAction action) {
    _undoStack.add(action);

    while (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();

    _recentActions.insert(0, action);
    while (_recentActions.length > _maxRecent) {
      _recentActions.removeLast();
    }

    AppLogger.instance.debug(
      'Recorded action: ${action.type} - ${action.description}',
      category: 'ProductivityService',
    );
  }

  ProductivityAction? undo() {
    if (_undoStack.isEmpty) {
      AppLogger.instance.debug(
        'Undo stack empty',
        category: 'ProductivityService',
      );
      return null;
    }

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    AppLogger.instance.debug(
      'Undo: ${action.description}',
      category: 'ProductivityService',
    );

    return action;
  }

  ProductivityAction? redo() {
    if (_redoStack.isEmpty) {
      AppLogger.instance.debug(
        'Redo stack empty',
        category: 'ProductivityService',
      );
      return null;
    }

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    AppLogger.instance.debug(
      'Redo: ${action.description}',
      category: 'ProductivityService',
    );

    return action;
  }

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  List<ProductivityAction> getRecentActions({int limit = 20}) {
    final effectiveLimit = limit.clamp(0, _recentActions.length);
    return List.unmodifiable(_recentActions.take(effectiveLimit));
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _recentActions.clear();
    AppLogger.instance.info(
      'Cleared all productivity history',
      category: 'ProductivityService',
    );
  }

  int batchCopy(
    List<String> values,
    EnhancedClipboardService clipboard,
  ) {
    var copiedCount = 0;

    for (final value in values) {
      try {
        clipboard.copy(value);
        copiedCount++;
      } catch (e) {
        AppLogger.instance.warning(
          'Failed to copy value: $e',
          category: 'ProductivityService',
        );
      }
    }

    recordAction(ProductivityAction(
      type: 'batch_copy',
      description: 'Copied $copiedCount items to clipboard',
      data: {'count': copiedCount, 'totalCount': values.length},
      timestamp: DateTime.now(),
    ));

    AppLogger.instance.debug(
      'Batch copy: $copiedCount/${values.length} items',
      category: 'ProductivityService',
    );

    return copiedCount;
  }

  int batchDelete(
    List<String> ids,
    void Function(String) deleteFn,
  ) {
    var deletedCount = 0;

    for (final id in ids) {
      try {
        deleteFn(id);
        deletedCount++;
      } catch (e) {
        AppLogger.instance.warning(
          'Failed to delete item $id: $e',
          category: 'ProductivityService',
        );
      }
    }

    recordAction(ProductivityAction(
      type: 'batch_delete',
      description: 'Deleted $deletedCount items',
      data: {'count': deletedCount, 'totalCount': ids.length},
      undoData: {'deletedIds': ids},
      timestamp: DateTime.now(),
    ));

    AppLogger.instance.debug(
      'Batch delete: $deletedCount/${ids.length} items',
      category: 'ProductivityService',
    );

    return deletedCount;
  }

  List<T> quickSearch<T>(
    String query,
    List<T> items,
    bool Function(String, T) matcher,
  ) {
    if (query.isEmpty) return List.unmodifiable(items);

    final lowerQuery = query.toLowerCase();
    return items.where((item) => matcher(lowerQuery, item)).toList();
  }
}
