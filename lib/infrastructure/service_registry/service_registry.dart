enum ServiceState { registered, initializing, active, suspended, failed, shutdown }

enum ServiceHealthStatus { healthy, degraded, unhealthy, unknown }

class ServiceHealth {
  const ServiceHealth({
    required this.status,
    this.message = '',
    this.lastCheck,
    this.responseTimeMs = 0,
  });

  final ServiceHealthStatus status;
  final String message;
  final DateTime? lastCheck;
  final double responseTimeMs;

  bool get isOperational => status == ServiceHealthStatus.healthy || status == ServiceHealthStatus.degraded;

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'message': message,
    'lastCheck': lastCheck?.toIso8601String(),
    'responseTimeMs': responseTimeMs,
  };
}

class ServiceMetrics {
  const ServiceMetrics({
    this.totalCalls = 0,
    this.failedCalls = 0,
    this.averageResponseTimeMs = 0,
    this.lastCallTime,
  });

  final int totalCalls;
  final int failedCalls;
  final double averageResponseTimeMs;
  final DateTime? lastCallTime;

  double get successRate =>
      totalCalls == 0 ? 1.0 : (totalCalls - failedCalls) / totalCalls;

  Map<String, dynamic> toMap() => {
    'totalCalls': totalCalls,
    'failedCalls': failedCalls,
    'successRate': successRate,
    'averageResponseTimeMs': averageResponseTimeMs,
    'lastCallTime': lastCallTime?.toIso8601String(),
  };
}

class ServiceEntry<T> {
  ServiceEntry({
    required this.id,
    required this.instance,
    required this.dependencies,
    this.version = '1.0.0',
    this.state = ServiceState.registered,
    this.description = '',
  });

  final String id;
  final T instance;
  final List<String> dependencies;
  final String version;
  ServiceState state;
  final String description;
  ServiceHealth health = const ServiceHealth(status: ServiceHealthStatus.unknown);
  ServiceMetrics metrics = const ServiceMetrics();
  DateTime? initializedAt;
  int startOrder = 0;
}

class ServiceRegistry {
  ServiceRegistry._();
  static final ServiceRegistry instance = ServiceRegistry._();

  final Map<String, ServiceEntry<dynamic>> _services = {};
  final List<String> _startOrder = [];
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void register<T>(String id, T serviceInstance, {
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) {
    if (_services.containsKey(id)) return;
    final entry = ServiceEntry<T>(
      id: id,
      instance: serviceInstance,
      dependencies: dependencies,
      version: version,
      description: description,
    );
    _services[id] = entry;
    _resolveStartOrder();
  }

  void unregister(String serviceId) {
    _services.remove(serviceId);
    _startOrder.remove(serviceId);
  }

  T? getService<T>(String serviceId) {
    final entry = _services[serviceId];
    if (entry == null) return null;
    return entry.instance as T?;
  }

  Future<void> initializeService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null || entry.state == ServiceState.active) return;
    entry.state = ServiceState.initializing;
    for (final depId in entry.dependencies) {
      final dep = _services[depId];
      if (dep == null) {
        entry.state = ServiceState.failed;
        entry.health = const ServiceHealth(
          status: ServiceHealthStatus.unhealthy,
          message: 'Missing dependency',
        );
        return;
      }
      if (dep.state != ServiceState.active) {
        await initializeService(depId);
      }
    }
    entry.state = ServiceState.active;
    entry.initializedAt = DateTime.now();
    entry.health = ServiceHealth(
      status: ServiceHealthStatus.healthy,
      message: 'Active',
      lastCheck: DateTime.now(),
    );
  }

  Future<void> initializeAll() async {
    _resolveStartOrder();
    for (final serviceId in _startOrder) {
      final entry = _services[serviceId];
      if (entry != null && entry.state != ServiceState.active) {
        await initializeService(serviceId);
      }
    }
  }

  Future<void> restartService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) return;
    entry.state = ServiceState.shutdown;
    entry.state = ServiceState.registered;
    await initializeService(serviceId);
  }

  Future<void> shutdownService(String serviceId) async {
    final entry = _services[serviceId];
    if (entry == null) return;
    entry.state = ServiceState.shutdown;
    entry.health = const ServiceHealth(
      status: ServiceHealthStatus.unknown,
      message: 'Shutdown',
    );
  }

  Future<void> shutdownAll() async {
    for (final serviceId in _startOrder.reversed) {
      await shutdownService(serviceId);
    }
  }

  void updateHealth(String serviceId, ServiceHealth health) {
    final entry = _services[serviceId];
    if (entry != null) {
      entry.health = health;
    }
  }

  void recordCall(String serviceId, {required bool success, double responseTimeMs = 0}) {
    final entry = _services[serviceId];
    if (entry == null) return;
    entry.metrics = ServiceMetrics(
      totalCalls: entry.metrics.totalCalls + 1,
      failedCalls: entry.metrics.failedCalls + (success ? 0 : 1),
      averageResponseTimeMs: ((entry.metrics.averageResponseTimeMs * entry.metrics.totalCalls) + responseTimeMs) /
          (entry.metrics.totalCalls + 1),
      lastCallTime: DateTime.now(),
    );
  }

  ServiceEntry<dynamic>? getEntry(String serviceId) => _services[serviceId];
  List<ServiceEntry<dynamic>> getAllServices() => List.unmodifiable(_services.values);
  List<ServiceEntry<dynamic>> getActiveServices() =>
      _services.values.where((s) => s.state == ServiceState.active).toList();
  List<String> getStartOrder() => List.unmodifiable(_startOrder);
  bool hasService(String serviceId) => _services.containsKey(serviceId);

  List<String> getDependencies(String serviceId) {
    final entry = _services[serviceId];
    return entry != null ? List.unmodifiable(entry.dependencies) : [];
  }

  bool validateDependencies(String serviceId, [Set<String>? visited]) {
    visited = visited ?? {};
    if (visited.contains(serviceId)) return false;
    visited.add(serviceId);
    final entry = _services[serviceId];
    if (entry == null) return false;
    for (final depId in entry.dependencies) {
      if (!_services.containsKey(depId)) return false;
      if (!validateDependencies(depId, visited)) return false;
    }
    return true;
  }

  void _resolveStartOrder() {
    _startOrder.clear();
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
      _startOrder.add(id);
    }
    for (final id in _services.keys) {
      visit(id);
    }
    int order = 0;
    for (final id in _startOrder) {
      final entry = _services[id];
      if (entry != null) entry.startOrder = order++;
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'totalServices': _services.length,
      'activeServices': getActiveServices().length,
      'states': {
        for (final state in ServiceState.values)
          state.name: _services.values.where((s) => s.state == state).length,
      },
      'startOrder': _startOrder,
      'services': {
        for (final entry in _services.entries)
          entry.key: {
            'version': entry.value.version,
            'state': entry.value.state.name,
            'health': entry.value.health.toMap(),
            'metrics': entry.value.metrics.toMap(),
            'dependencies': entry.value.dependencies,
          },
      },
    };
  }
}
