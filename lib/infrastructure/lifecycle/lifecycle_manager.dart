import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum LifecycleState { created, initialized, active, suspending, suspended, resuming, reloading, shuttingDown, shutdown, failed }

class LifecycleEvent extends AppEvent {
  const LifecycleEvent({
    required this.targetId,
    required this.oldState,
    required this.newState,
    this.message = '',
    super.source,
    super.timestamp,
  });

  final String targetId;
  final LifecycleState oldState;
  final LifecycleState newState;
  final String message;
}

class LifecycleEntry {
  LifecycleEntry({
    required this.id,
    required this.state,
    this.parentId,
    this.description = '',
  });

  final String id;
  LifecycleState state;
  String? parentId;
  final String description;
  DateTime? createdAt;
  DateTime? lastStateChanged;
  List<String> children = [];
  Map<String, dynamic> metadata = {};

  Duration get uptime {
    if (createdAt == null) return Duration.zero;
    return DateTime.now().difference(createdAt!);
  }
}

class LifecycleManager {
  LifecycleManager._();
  static final LifecycleManager instance = LifecycleManager._();

  final Map<String, LifecycleEntry> _entries = {};
  final EventBus _eventBus = EventBus.instance;

  void register(String id, {String? parentId, String description = ''}) {
    if (_entries.containsKey(id)) return;
    final entry = LifecycleEntry(
      id: id,
      state: LifecycleState.created,
      parentId: parentId,
      description: description,
    )..createdAt = DateTime.now();
    _entries[id] = entry;
    if (parentId != null) {
      final parent = _entries[parentId];
      if (parent != null) {
        parent.children.add(id);
      }
    }
  }

  void unregister(String id) {
    final entry = _entries.remove(id);
    if (entry?.parentId != null) {
      final parent = _entries[entry!.parentId];
      parent?.children.remove(id);
    }
    for (final childId in entry?.children ?? []) {
      final child = _entries[childId];
      if (child != null) child.parentId = null;
    }
  }

  Future<bool> transition(String id, LifecycleState newState, {String? message}) async {
    final entry = _entries[id];
    if (entry == null) return false;
    if (!_isValidTransition(entry.state, newState)) return false;
    final oldState = entry.state;
    entry.state = newState;
    entry.lastStateChanged = DateTime.now();
    _eventBus.publish(LifecycleEvent(
      targetId: id,
      oldState: oldState,
      newState: newState,
      message: message ?? '',
      source: 'LifecycleManager',
    ));
    return true;
  }

  bool _isValidTransition(LifecycleState from, LifecycleState to) {
    const validTransitions = {
      LifecycleState.created: [LifecycleState.initialized, LifecycleState.failed],
      LifecycleState.initialized: [LifecycleState.active, LifecycleState.failed],
      LifecycleState.active: [LifecycleState.suspending, LifecycleState.reloading, LifecycleState.shuttingDown],
      LifecycleState.suspending: [LifecycleState.suspended, LifecycleState.failed],
      LifecycleState.suspended: [LifecycleState.resuming, LifecycleState.shuttingDown],
      LifecycleState.resuming: [LifecycleState.active, LifecycleState.failed],
      LifecycleState.reloading: [LifecycleState.active, LifecycleState.initialized, LifecycleState.failed],
      LifecycleState.shuttingDown: [LifecycleState.shutdown, LifecycleState.failed],
      LifecycleState.shutdown: [LifecycleState.created],
      LifecycleState.failed: [LifecycleState.created, LifecycleState.initialized],
    };
    return validTransitions[from]?.contains(to) ?? false;
  }

  LifecycleEntry? getEntry(String id) => _entries[id];
  LifecycleState? getState(String id) => _entries[id]?.state;
  List<LifecycleEntry> getAllEntries() => List.unmodifiable(_entries.values);
  List<String> getChildren(String id) => _entries[id]?.children ?? [];
  String? getParent(String id) => _entries[id]?.parentId;

  Duration getUptime(String id) => _entries[id]?.uptime ?? Duration.zero;

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalEntries': _entries.length,
      'states': {
        for (final state in LifecycleState.values)
          state.name: _entries.values.where((e) => e.state == state).length,
      },
      'entries': {
        for (final entry in _entries.entries)
          entry.key: {
            'state': entry.value.state.name,
            'parentId': entry.value.parentId,
            'uptimeMs': entry.value.uptime.inMilliseconds,
            'description': entry.value.description,
          },
      },
    };
  }
}
