import 'package:securepass_pro/domain/entities/command_item.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class CommandService {
  CommandService._();
  static final CommandService _instance = CommandService._();
  static CommandService get instance => _instance;

  bool _initialized = false;
  final Map<String, CommandItem> _commands = {};
  final List<String> _history = [];
  final Set<String> _favorites = {};
  static const int _maxHistory = 50;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Command service initialized', category: 'COMMAND');
  }

  void registerCommand(CommandItem command) {
    _commands[command.id] = command;
    AppLogger.instance.debug('Command registered: ${command.label}', category: 'COMMAND');
  }

  void unregisterCommand(String id) {
    _commands.remove(id);
    _history.remove(id);
    _favorites.remove(id);
  }

  List<CommandItem> getCommands() => List.unmodifiable(_commands.values);

  List<CommandItem> getCommandsByCategory(CommandCategory category) {
    return _commands.values.where((c) => c.category == category).toList();
  }

  void executeCommand(String id) {
    final command = _commands[id];
    if (command == null) {
      AppLogger.instance.warning('Command not found: $id', category: 'COMMAND');
      return;
    }
    addToHistory(id);
    command.onExecute?.call();
    AppLogger.instance.debug('Command executed: ${command.label}', category: 'COMMAND');
  }

  List<CommandItem> searchCommands(String query) {
    if (query.isEmpty) return getCommands();
    final lowerQuery = query.toLowerCase();
    final results = <CommandItem>[];

    for (final cmd in _commands.values) {
      final score = _scoreCommand(cmd, lowerQuery);
      if (score > 0) results.add(cmd);
    }

    results.sort((a, b) => _scoreCommand(b, lowerQuery).compareTo(_scoreCommand(a, lowerQuery)));
    return results;
  }

  double _scoreCommand(CommandItem cmd, String query) {
    final labelLower = cmd.label.toLowerCase();
    final descLower = cmd.description?.toLowerCase() ?? '';

    if (labelLower == query) return 100;
    if (labelLower.startsWith(query)) return 80;
    if (labelLower.contains(query)) return 60;
    if (descLower.contains(query)) return 30;
    return 0;
  }

  List<CommandItem> getRecentCommands() {
    return _history
        .where(_commands.containsKey)
        .take(10)
        .map((id) => _commands[id]!)
        .toList();
  }

  void addToHistory(String id) {
    _history.remove(id);
    _history.insert(0, id);
    if (_history.length > _maxHistory) {
      _history.removeLast();
    }
  }

  List<String> getHistory() => List.unmodifiable(_history);

  void clearHistory() {
    _history.clear();
    AppLogger.instance.info('Command history cleared', category: 'COMMAND');
  }

  void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
  }

  bool isFavorite(String id) => _favorites.contains(id);

  Set<String> get favorites => Set.unmodifiable(_favorites);
}
