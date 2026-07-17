import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum ServiceLifecycleState { registered, initializing, ready, active, suspending, suspended, resuming, shuttingDown, shutdown, failed, recovered }

class ServiceLifecycleEvent extends AppEvent {
  const ServiceLifecycleEvent({
    required this.serviceId,
    required this.oldState,
    required this.newState,
    this.error,
    super.source,
    super.timestamp,
  });

  final String serviceId;
  final ServiceLifecycleState oldState;
  final ServiceLifecycleState newState;
  final String? error;
}

class ServiceHealthCheck {
  const ServiceHealthCheck({
    required this.isHealthy,
    this.message = '',
    this.responseTimeMs = 0,
    this.checkedAt,
  });

  final bool isHealthy;
  final String message;
  final double responseTimeMs;
  final DateTime? checkedAt;

  Map<String, dynamic> toMap() => {
    'isHealthy': isHealthy,
    'message': message,
    'responseTimeMs': responseTimeMs,
    'checkedAt': (checkedAt ?? DateTime.now()).toIso8601String(),
  };
}

class ServiceLifecycleEntry {
  ServiceLifecycleEntry({
    required this.id,
    this.description = '',
    this.dependencies = const [],
  });

  final String id;
  final String description;
  final List<String> dependencies;
  ServiceLifecycleState state = ServiceLifecycleState.registered;
  DateTime? initializedAt;
  DateTime? lastHealthCheck;
  DateTime? lastStateChanged;
  ServiceHealthCheck health = const ServiceHealthCheck(isHealthy: true);
  final List<String> recoveryLog = [];
  int _restartCount = 0;
  int get restartCount => _restartCount;
  Map<String, dynamic> performanceMetrics = {};
}

class ServiceLifecycleManager {
  ServiceLifecycleManager._();
  static final ServiceLifecycleManager instance = ServiceLifecycleManager._();

  final Map<String, ServiceLifecycleEntry> _services = {};
  final EventBus _eventBus = EventBus.instance;
  final Map<String, Future<void> Function()> _initializers = {};
  final Map<String, Future<void> Function()> _shutdownHandlers = {};
  final Map<String, Future<void> Function()> _healthChecks = {};
  final Map<String, Future<void> Function()> _recoveryHandlers = {};

  void register(
    String serviceId, {
    String description = '',
    List<String> dependencies = const [],
    Future<void> Function()? initializer,
    Future<void> Function()? shutdownHandler,
    Future<void> Function()? healthCheck,
    Future<void> Function()? recoveryHandler,
  }) {
    if (_services.containsKey(serviceId)) return;
    _services[serviceId] = ServiceLifecycleEntry(
      id: serviceId,
      description: description,
      dependencies: dependencies,
    );
    if (initializer != null) _initializers[serviceId] = initializer;
    if (shutdownHandler != null) _shutdownHandlers[serviceId] = shutdownHandler;
    if (healthCheck != null) _healthChecks[serviceId] = healthCheck;
    if (recoveryHandler != null) _recoveryHandlers[serviceId] = recoveryHandler;
  }

  void unregister(String serviceId) {
    _services.remove(serviceId);
    _initializers.remove(serviceId);
    _shutdownHandlers.remove(serviceId);
    _healthChecks.remove(serviceId);
    _recoveryHandlers.remove(serviceId);
  }

  Future<bool> initializeService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) return false;
    if (entry.state == ServiceLifecycleState.active) return true;

    for (final depId in entry.dependencies) {
      final dep = _services[depId];
      if (dep == null) {
        await _transition(serviceId, ServiceLifecycleState.failed, error: 'Missing dependency: $depId');
        return false;
      }
      if (dep.state != ServiceLifecycleState.active) {
        final success = await initializeService(depId);
        if (!success) {
          await _transition(serviceId, ServiceLifecycleState.failed, error: 'Dependency failed: $depId');
          return false;
        }
      }
    }

    await _transition(serviceId, ServiceLifecycleState.initializing);
    try {
      final initializer = _initializers[serviceId];
      if (initializer != null) {
        await initializer();
      }
      entry.initializedAt = DateTime.now();
      await _transition(serviceId, ServiceLifecycleState.ready);
      await _transition(serviceId, ServiceLifecycleState.active);
      return true;
    } catch (e) {
      await _transition(serviceId, ServiceLifecycleState.failed, error: e.toString());
      return false;
    }
  }

  Future<void> initializeAll() async {
    final order = _resolveDependencies();
    for (final serviceId in order) {
      final entry = _services[serviceId];
      if (entry != null && entry.state != ServiceLifecycleState.active) {
        await initializeService(serviceId);
      }
    }
  }

  Future<void> suspendService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null || entry.state != ServiceLifecycleState.active) return;
    await _transition(serviceId, ServiceLifecycleState.suspending);
    await _transition(serviceId, ServiceLifecycleState.suspended);
  }

  Future<void> resumeService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null || entry.state != ServiceLifecycleState.suspended) return;
    await _transition(serviceId, ServiceLifecycleState.resuming);
    await _transition(serviceId, ServiceLifecycleState.active);
  }

  Future<void> restartService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) return;
    entry._restartCount++;
    await shutdownService(serviceId);
    entry.state = ServiceLifecycleState.registered;
    await initializeService(serviceId);
  }

  Future<void> shutdownService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) return;
    await _transition(serviceId, ServiceLifecycleState.shuttingDown);
    try {
      final handler = _shutdownHandlers[serviceId];
      if (handler != null) await handler();
      await _transition(serviceId, ServiceLifecycleState.shutdown);
    } catch (e) {
      await _transition(serviceId, ServiceLifecycleState.failed, error: 'Shutdown failed: $e');
    }
  }

  Future<void> shutdownAll() async {
    final order = _resolveDependencies().reversed;
    for (final serviceId in order) {
      await shutdownService(serviceId);
    }
  }

  Future<bool> recoverService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null || entry.state != ServiceLifecycleState.failed) return false;
    entry.recoveryLog.add('Recovery attempted at ${DateTime.now().toIso8601String()}');
    final recoveryHandler = _recoveryHandlers[serviceId];
    if (recoveryHandler != null) {
      try {
        await recoveryHandler();
        entry.state = ServiceLifecycleState.registered;
        return await initializeService(serviceId);
      } catch (_) {}
    }
    entry.state = ServiceLifecycleState.registered;
    return await initializeService(serviceId);
  }

  Future<ServiceHealthCheck> checkHealth(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) {
      return const ServiceHealthCheck(isHealthy: false, message: 'Service not found');
    }
    final healthChecker = _healthChecks[serviceId];
    if (healthChecker != null) {
      try {
        final stopwatch = Stopwatch()..start();
        await healthChecker();
        stopwatch.stop();
        entry.health = ServiceHealthCheck(
          isHealthy: true,
          message: 'Healthy',
          responseTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
          checkedAt: DateTime.now(),
        );
      } catch (e) {
        entry.health = ServiceHealthCheck(
          isHealthy: false,
          message: 'Health check failed: $e',
          checkedAt: DateTime.now(),
        );
      }
    } else {
      entry.health = ServiceHealthCheck(
        isHealthy: entry.state == ServiceLifecycleState.active,
        message: entry.state == ServiceLifecycleState.active ? 'Active' : 'Not active',
        checkedAt: DateTime.now(),
      );
    }
    entry.lastHealthCheck = DateTime.now();
    return entry.health;
  }

  Future<void> checkAllHealth() async {
    for (final serviceId in _services.keys) {
      await checkHealth(serviceId);
    }
  }

  Future<bool> _transition(String serviceId, ServiceLifecycleState newState, {String? error}) async {
    final entry = _services[serviceId];
    if (entry == null) return false;
    final oldState = entry.state;
    entry.state = newState;
    entry.lastStateChanged = DateTime.now();
    _eventBus.publish(ServiceLifecycleEvent(
      serviceId: serviceId,
      oldState: oldState,
      newState: newState,
      error: error,
      source: 'ServiceLifecycleManager',
    ));
    return true;
  }

  List<String> _resolveDependencies() {
    final order = <String>[];
    final visited = <String>{};
    void visit(String id) {
      if (visited.contains(id)) return;
      visited.add(id);
      final entry = _services[id];
      if (entry != null) {
        for (final depId in entry.dependencies) {
          visit(depId);
        }
      }
      order.add(id);
    }
    for (final id in _services.keys) {
      visit(id);
    }
    return order;
  }

  ServiceLifecycleEntry? getEntry(String serviceId) => _services[serviceId];
  List<ServiceLifecycleEntry> getAllServices() => List.unmodifiable(_services.values);

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalServices': _services.length,
      'states': {
        for (final state in ServiceLifecycleState.values)
          state.name: _services.values.where((s) => s.state == state).length,
      },
      'services': {
        for (final entry in _services.entries)
          entry.key: {
            'state': entry.value.state.name,
            'health': entry.value.health.toMap(),
            'restartCount': entry.value.restartCount,
            'uptimeMs': entry.value.initializedAt != null
                ? DateTime.now().difference(entry.value.initializedAt!).inMilliseconds
                : 0,
          },
      },
    };
  }
}
