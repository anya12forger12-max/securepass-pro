enum DependencyType { service, module, plugin, featureFlag, extension, config }

class DependencyNode {
  const DependencyNode({
    required this.id,
    required this.type,
    this.description = '',
    this.version = '1.0.0',
  });

  final String id;
  final DependencyType type;
  final String description;
  final String version;
}

class DependencyEdge {
  const DependencyEdge({
    required this.from,
    required this.to,
    this.optional = false,
    this.description = '',
  });

  final String from;
  final String to;
  final bool optional;
  final String description;
}

class DependencyIssue {
  const DependencyIssue({
    required this.type,
    required this.message,
    this.nodeIds = const [],
    this.severity = 'error',
  });

  final String type;
  final String message;
  final List<String> nodeIds;
  final String severity;
}

class DependencyGraph {
  DependencyGraph._();
  static final DependencyGraph instance = DependencyGraph._();

  final Map<String, DependencyNode> _nodes = {};
  final List<DependencyEdge> _edges = [];

  void addNode(DependencyNode node) {
    _nodes[node.id] = node;
  }

  void removeNode(String nodeId) {
    _nodes.remove(nodeId);
    _edges.removeWhere((e) => e.from == nodeId || e.to == nodeId);
  }

  void addEdge(DependencyEdge edge) {
    _edges.add(edge);
  }

  void removeEdge(String from, String to) {
    _edges.removeWhere((e) => e.from == from && e.to == to);
  }

  List<String> getDependencies(String nodeId) {
    return _edges.where((e) => e.from == nodeId).map((e) => e.to).toList();
  }

  List<String> getDependents(String nodeId) {
    return _edges.where((e) => e.to == nodeId).map((e) => e.from).toList();
  }

  List<String> getTopologicalOrder() {
    final visited = <String>{};
    final order = <String>[];
    void visit(String id) {
      if (visited.contains(id)) return;
      visited.add(id);
      for (final depId in getDependencies(id)) {
        visit(depId);
      }
      order.add(id);
    }
    for (final nodeId in _nodes.keys) {
      visit(nodeId);
    }
    return order;
  }

  List<DependencyIssue> detectCircularDependencies() {
    final issues = <DependencyIssue>[];
    final visited = <String>{};
    final inStack = <String>{};

    void dfs(String id, List<String> path) {
      if (inStack.contains(id)) {
        final cycleStart = path.indexOf(id);
        final cycle = path.sublist(cycleStart)..add(id);
        issues.add(DependencyIssue(
          type: 'circular_dependency',
          message: 'Circular dependency detected: ${cycle.join(' -> ')}',
          nodeIds: cycle,
        ));
        return;
      }
      if (visited.contains(id)) return;
      visited.add(id);
      inStack.add(id);
      path.add(id);
      for (final depId in getDependencies(id)) {
        dfs(depId, path);
      }
      path.removeLast();
      inStack.remove(id);
    }

    for (final nodeId in _nodes.keys) {
      dfs(nodeId, []);
    }
    return issues;
  }

  List<DependencyIssue> detectMissingDependencies() {
    final issues = <DependencyIssue>[];
    for (final edge in _edges) {
      if (!_nodes.containsKey(edge.to) && !edge.optional) {
        issues.add(DependencyIssue(
          type: 'missing_dependency',
          message: 'Node "${edge.from}" depends on missing node "${edge.to}"',
          nodeIds: [edge.from, edge.to],
        ));
      }
    }
    return issues;
  }

  List<DependencyIssue> detectUnusedNodes() {
    final issues = <DependencyIssue>[];
    final hasIncoming = <String>{};
    final hasOutgoing = <String>{};
    for (final edge in _edges) {
      hasOutgoing.add(edge.from);
      hasIncoming.add(edge.to);
    }
    for (final nodeId in _nodes.keys) {
      if (!hasIncoming.contains(nodeId) && !hasOutgoing.contains(nodeId)) {
        issues.add(DependencyIssue(
          type: 'unused_node',
          message: 'Node "$nodeId" has no connections',
          nodeIds: [nodeId],
          severity: 'warning',
        ));
      }
    }
    return issues;
  }

  List<DependencyIssue> detectDuplicateRegistrations() {
    final issues = <DependencyIssue>[];
    final counts = <String, int>{};
    for (final edge in _edges) {
      final key = '${edge.from}->${edge.to}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value > 1) {
        issues.add(DependencyIssue(
          type: 'duplicate_registration',
          message: 'Duplicate dependency: ${entry.key} (${entry.value} times)',
          severity: 'warning',
        ));
      }
    }
    return issues;
  }

  List<DependencyIssue> validateAll() {
    return [
      ...detectCircularDependencies(),
      ...detectMissingDependencies(),
      ...detectUnusedNodes(),
      ...detectDuplicateRegistrations(),
    ];
  }

  Map<String, dynamic> getGraphMetrics() {
    final nodeCount = _nodes.length;
    final edgeCount = _edges.length;
    final maxEdges = nodeCount * (nodeCount - 1);
    return {
      'nodeCount': nodeCount,
      'edgeCount': edgeCount,
      'density': maxEdges > 0 ? edgeCount / maxEdges : 0.0,
      'nodesByType': {
        for (final type in DependencyType.values)
          type.name: _nodes.values.where((n) => n.type == type).length,
      },
      'issues': validateAll().length,
    };
  }

  void clear() {
    _nodes.clear();
    _edges.clear();
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      ...getGraphMetrics(),
      'issues': validateAll().map((i) => {'type': i.type, 'message': i.message, 'severity': i.severity}).toList(),
      'topologicalOrder': getTopologicalOrder(),
    };
  }
}
