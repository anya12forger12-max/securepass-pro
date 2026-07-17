import 'package:securepass_pro/infrastructure/versioning/semantic_version.dart';

enum ModuleState { discovered, registered, initializing, active, suspended, reloading, shutdown, failed }

class ModuleMetadata {
  const ModuleMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.author = '',
    this.dependencies = const [],
    this.capabilities = const [],
    this.permissions = const [],
    this.config = const {},
  });

  final String id;
  final String name;
  final SemanticVersion version;
  final String description;
  final String author;
  final List<String> dependencies;
  final List<String> capabilities;
  final List<String> permissions;
  final Map<String, dynamic> config;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'version': version.toString(),
    'description': description,
    'author': author,
    'dependencies': dependencies,
    'capabilities': capabilities,
    'permissions': permissions,
  };
}

class ModuleHealth {
  const ModuleHealth({
    required this.isHealthy,
    this.message = '',
    this.lastCheck,
    this.loadTimeMs = 0,
  });

  final bool isHealthy;
  final String message;
  final DateTime? lastCheck;
  final double loadTimeMs;

  Map<String, dynamic> toMap() => {
    'isHealthy': isHealthy,
    'message': message,
    'lastCheck': lastCheck?.toIso8601String(),
    'loadTimeMs': loadTimeMs,
  };
}

class ModuleEntry {
  ModuleEntry({
    required this.metadata,
    this.initializer,
    this.shutdownHandler,
    this.state = ModuleState.discovered,
  });

  final ModuleMetadata metadata;
  final Future<void> Function()? initializer;
  final Future<void> Function()? shutdownHandler;
  ModuleState state;
  ModuleHealth health = const ModuleHealth(isHealthy: true);
  DateTime? initializedAt;
  DateTime? lastHealthCheck;
}

class ModuleRegistry {
  ModuleRegistry._();
  static final ModuleRegistry instance = ModuleRegistry._();

  final Map<String, ModuleEntry> _modules = {};
  final List<String> _initializationOrder = [];
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> register(ModuleMetadata metadata, {
    Future<void> Function()? initializer,
    Future<void> Function()? shutdownHandler,
  }) async {
    if (_modules.containsKey(metadata.id)) return;
    final entry = ModuleEntry(
      metadata: metadata,
      initializer: initializer,
      shutdownHandler: shutdownHandler,
      state: ModuleState.registered,
    );
    _modules[metadata.id] = entry;
    _resolveInitializationOrder();
  }

  void unregister(String moduleId) {
    _modules.remove(moduleId);
    _initializationOrder.remove(moduleId);
  }

  Future<void> initializeModule(String moduleId) async {
    final entry = _modules[moduleId];
    if (entry == null || entry.state == ModuleState.active) return;
    entry.state = ModuleState.initializing;
    final stopwatch = Stopwatch()..start();
    try {
      for (final depId in entry.metadata.dependencies) {
        final dep = _modules[depId];
        if (dep == null) {
          entry.state = ModuleState.failed;
          entry.health = ModuleHealth(isHealthy: false, message: 'Missing dependency: $depId');
          return;
        }
        if (dep.state != ModuleState.active) {
          await initializeModule(depId);
        }
      }
      if (entry.initializer != null) {
        await entry.initializer!();
      }
      stopwatch.stop();
      entry.state = ModuleState.active;
      entry.initializedAt = DateTime.now();
      entry.health = ModuleHealth(
        isHealthy: true,
        message: 'Active',
        lastCheck: DateTime.now(),
        loadTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } catch (e) {
      stopwatch.stop();
      entry.state = ModuleState.failed;
      entry.health = ModuleHealth(
        isHealthy: false,
        message: 'Initialization failed: $e',
        lastCheck: DateTime.now(),
        loadTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    }
  }

  Future<void> initializeAll() async {
    _resolveInitializationOrder();
    for (final moduleId in _initializationOrder) {
      final entry = _modules[moduleId];
      if (entry != null && entry.state != ModuleState.active) {
        await initializeModule(moduleId);
      }
    }
  }

  Future<void> suspendModule(String moduleId) async {
    final entry = _modules[moduleId];
    if (entry == null || entry.state != ModuleState.active) return;
    entry.state = ModuleState.suspended;
  }

  Future<void> resumeModule(String moduleId) async {
    final entry = _modules[moduleId];
    if (entry == null || entry.state != ModuleState.suspended) return;
    entry.state = ModuleState.active;
  }

  Future<void> reloadModule(String moduleId) async {
    final entry = _modules[moduleId];
    if (entry == null) return;
    entry.state = ModuleState.reloading;
    if (entry.shutdownHandler != null) {
      await entry.shutdownHandler!();
    }
    entry.state = ModuleState.discovered;
    await initializeModule(moduleId);
  }

  Future<void> shutdownModule(String moduleId) async {
    final entry = _modules[moduleId];
    if (entry == null) return;
    if (entry.shutdownHandler != null) {
      await entry.shutdownHandler!();
    }
    entry.state = ModuleState.shutdown;
  }

  Future<void> shutdownAll() async {
    final reversedOrder = List<String>.from(_initializationOrder).reversed;
    for (final moduleId in reversedOrder) {
      await shutdownModule(moduleId);
    }
  }

  ModuleEntry? getModule(String moduleId) => _modules[moduleId];
  List<ModuleEntry> getAllModules() => List.unmodifiable(_modules.values);
  List<ModuleEntry> getActiveModules() =>
      _modules.values.where((m) => m.state == ModuleState.active).toList();
  List<String> getInitializationOrder() => List.unmodifiable(_initializationOrder);
  bool hasModule(String moduleId) => _modules.containsKey(moduleId);

  List<String> getDependencies(String moduleId) {
    final entry = _modules[moduleId];
    if (entry == null) return [];
    return List.unmodifiable(entry.metadata.dependencies);
  }

  List<String> getDependents(String moduleId) {
    return _modules.values
        .where((e) => e.metadata.dependencies.contains(moduleId))
        .map((e) => e.metadata.id)
        .toList();
  }

  bool validateDependencies(String moduleId, [Set<String>? visited]) {
    visited = visited ?? {};
    if (visited.contains(moduleId)) return false;
    visited.add(moduleId);
    final entry = _modules[moduleId];
    if (entry == null) return false;
    for (final depId in entry.metadata.dependencies) {
      if (!_modules.containsKey(depId)) return false;
      if (!validateDependencies(depId, visited)) return false;
    }
    return true;
  }

  List<String> detectCircularDependencies() {
    final cycles = <String>[];
    final visited = <String>{};
    final inStack = <String>{};

    void dfs(String id, List<String> path) {
      if (inStack.contains(id)) {
        final cycleStart = path.indexOf(id);
        cycles.add('${path.sublist(cycleStart).join(' -> ')} -> $id');
        return;
      }
      if (visited.contains(id)) return;
      visited.add(id);
      inStack.add(id);
      path.add(id);
      final entry = _modules[id];
      if (entry != null) {
        for (final depId in entry.metadata.dependencies) {
          dfs(depId, path);
        }
      }
      path.removeLast();
      inStack.remove(id);
    }

    for (final id in _modules.keys) {
      dfs(id, []);
    }
    return cycles;
  }

  void _resolveInitializationOrder() {
    _initializationOrder.clear();
    final visited = <String>{};
    void visit(String id) {
      if (visited.contains(id)) return;
      visited.add(id);
      final entry = _modules[id];
      if (entry != null) {
        for (final depId in entry.metadata.dependencies) {
          visit(depId);
        }
      }
      _initializationOrder.add(id);
    }
    for (final id in _modules.keys) {
      visit(id);
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalModules': _modules.length,
      'activeModules': getActiveModules().length,
      'states': {
        for (final state in ModuleState.values)
          state.name: _modules.values.where((m) => m.state == state).length,
      },
      'circularDependencies': detectCircularDependencies(),
      'initializationOrder': _initializationOrder,
      'modules': {
        for (final entry in _modules.entries)
          entry.key: {
            'version': entry.value.metadata.version.toString(),
            'state': entry.value.state.name,
            'health': entry.value.health.toMap(),
            'dependencies': entry.value.metadata.dependencies,
          },
      },
    };
  }
}
