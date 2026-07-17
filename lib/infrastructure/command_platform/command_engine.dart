import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum CommandState { idle, executing, completed, failed, undone, redone }

class CommandEvent extends AppEvent {
  const CommandEvent({required this.commandId, required this.state, this.error, super.source, super.timestamp});
  final String commandId;
  final CommandState state;
  final String? error;
}

class CommandResult {
  const CommandResult({required this.success, this.data, this.error});
  final bool success;
  final dynamic data;
  final String? error;
}

class Command {
  Command({
    required this.id,
    required this.description,
    required this.execute,
    this.undo,
    this.permissions = const [],
    this.metadata = const {},
  });

  final String id;
  final String description;
  final Future<CommandResult> Function() execute;
  final Future<void> Function()? undo;
  final List<String> permissions;
  final Map<String, dynamic> metadata;

  CommandState state = CommandState.idle;
  CommandResult? lastResult;
  DateTime? executedAt;
}

class CommandEngine {
  CommandEngine._();
  static final CommandEngine instance = CommandEngine._();

  final Map<String, Command> _commands = {};
  final List<String> _executionHistory = [];
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  int _maxHistory = 100;
  int _totalExecuted = 0;
  int _totalFailed = 0;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void register(Command command) {
    _commands[command.id] = command;
  }

  void unregister(String commandId) {
    _commands.remove(commandId);
    _executionHistory.remove(commandId);
    _undoStack.remove(commandId);
    _redoStack.remove(commandId);
  }

  Future<CommandResult> execute(String commandId, {Map<String, dynamic>? grantedPermissions}) async {
    final command = _commands[commandId];
    if (command == null) {
      return const CommandResult(success: false, error: 'Command not found');
    }

    if (command.permissions.isNotEmpty && grantedPermissions != null) {
      for (final perm in command.permissions) {
        if (!grantedPermissions.containsKey(perm)) {
          return CommandResult(success: false, error: 'Missing permission: $perm');
        }
      }
    }

    command.state = CommandState.executing;
    final sw = Stopwatch()..start();
    try {
      final result = await command.execute();
      sw.stop();
      command.state = result.success ? CommandState.completed : CommandState.failed;
      command.lastResult = result;
      command.executedAt = DateTime.now();
      _totalExecuted++;
      if (!result.success) _totalFailed++;

      _executionHistory.add(commandId);
      if (_executionHistory.length > _maxHistory) _executionHistory.removeAt(0);
      if (command.undo != null) {
        _undoStack.add(commandId);
        _redoStack.clear();
      }

      return result;
    } catch (e) {
      sw.stop();
      command.state = CommandState.failed;
      _totalFailed++;
      return CommandResult(success: false, error: e.toString());
    }
  }

  Future<bool> undo() async {
    if (_undoStack.isEmpty) return false;
    final commandId = _undoStack.removeLast();
    final command = _commands[commandId];
    if (command?.undo == null) return false;
    try {
      await command!.undo!();
      command.state = CommandState.undone;
      _redoStack.add(commandId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> redo() async {
    if (_redoStack.isEmpty) return false;
    final commandId = _redoStack.removeLast();
    final result = await execute(commandId);
    if (result.success) {
      final command = _commands[commandId];
      if (command != null) command.state = CommandState.redone;
      return true;
    }
    return false;
  }

  Command? getCommand(String commandId) => _commands[commandId];
  List<Command> getAllCommands() => List.unmodifiable(_commands.values);
  List<String> getExecutionHistory() => List.unmodifiable(_executionHistory);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoStackSize => _undoStack.length;
  int get redoStackSize => _redoStack.length;

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalCommands': _commands.length,
      'totalExecuted': _totalExecuted,
      'totalFailed': _totalFailed,
      'undoStackSize': _undoStack.length,
      'redoStackSize': _redoStack.length,
      'historySize': _executionHistory.length,
    };
  }
}
