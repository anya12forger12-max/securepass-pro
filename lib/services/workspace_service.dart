import 'dart:convert';

import 'package:securepass_pro/domain/entities/workspace_metadata.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:uuid/uuid.dart';

class WorkspaceService {
  WorkspaceService._();
  static final WorkspaceService _instance = WorkspaceService._();
  static WorkspaceService get instance => _instance;

  bool _initialized = false;
  final List<WorkspaceMetadata> _workspaces = [];
  String? _currentWorkspaceId;
  static const String _storageKey = 'workspaces_data';
  static const String _currentKey = 'current_workspace_id';

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromStorage();
    _initialized = true;
    AppLogger.instance.info('Workspace service initialized with ${_workspaces.length} workspaces', category: 'WORKSPACE');
  }

  Future<void> _loadFromStorage() async {
    final data = PreferencesStorage.instance.getString(_storageKey);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          _workspaces.add(WorkspaceMetadata(
            id: map['id'] as String,
            name: map['name'] as String,
            description: map['description'] as String? ?? '',
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
            isActive: map['isActive'] as bool? ?? false,
          ));
        }
      } catch (e) {
        AppLogger.instance.error('Failed to load workspaces', category: 'WORKSPACE');
      }
    }
    _currentWorkspaceId = PreferencesStorage.instance.getString(_currentKey);
  }

  Future<void> _saveToStorage() async {
    final data = _workspaces.map((w) => w.toMap()).toList();
    await PreferencesStorage.instance.setString(_storageKey, jsonEncode(data));
    if (_currentWorkspaceId != null) {
      await PreferencesStorage.instance.setString(_currentKey, _currentWorkspaceId!);
    }
  }

  Future<WorkspaceMetadata> createWorkspace(String name, String description) async {
    final workspace = WorkspaceMetadata(
      id: const Uuid().v4(),
      name: name,
      description: description,
      isActive: _workspaces.isEmpty,
    );
    _workspaces.add(workspace);
    if (_workspaces.length == 1) {
      _currentWorkspaceId = workspace.id;
    }
    await _saveToStorage();
    AppLogger.instance.info('Workspace created: $name', category: 'WORKSPACE');
    return workspace;
  }

  Future<void> switchWorkspace(String id) async {
    final exists = _workspaces.any((w) => w.id == id);
    if (!exists) {
      AppLogger.instance.warning('Workspace not found: $id', category: 'WORKSPACE');
      return;
    }
    _currentWorkspaceId = id;
    for (var i = 0; i < _workspaces.length; i++) {
      final w = _workspaces[i];
      _workspaces[i] = w.copyWith(isActive: w.id == id);
    }
    await _saveToStorage();
    AppLogger.instance.info('Switched to workspace: $id', category: 'WORKSPACE');
  }

  Future<void> deleteWorkspace(String id) async {
    if (_workspaces.length <= 1) {
      AppLogger.instance.warning('Cannot delete last workspace', category: 'WORKSPACE');
      return;
    }
    _workspaces.removeWhere((w) => w.id == id);
    if (_currentWorkspaceId == id) {
      _currentWorkspaceId = _workspaces.first.id;
      _workspaces[0] = _workspaces[0].copyWith(isActive: true);
    }
    await _saveToStorage();
    AppLogger.instance.info('Workspace deleted: $id', category: 'WORKSPACE');
  }

  WorkspaceMetadata? getCurrentWorkspace() {
    if (_currentWorkspaceId == null) return null;
    try {
      return _workspaces.firstWhere((w) => w.id == _currentWorkspaceId);
    } catch (_) {
      return _workspaces.isNotEmpty ? _workspaces.first : null;
    }
  }

  List<WorkspaceMetadata> getWorkspaces() => List.unmodifiable(_workspaces);

  Future<void> renameWorkspace(String id, String name) async {
    for (var i = 0; i < _workspaces.length; i++) {
      if (_workspaces[i].id == id) {
        _workspaces[i] = _workspaces[i].copyWith(name: name);
        break;
      }
    }
    await _saveToStorage();
    AppLogger.instance.debug('Workspace renamed: $id -> $name', category: 'WORKSPACE');
  }

  Future<Map<String, dynamic>> exportWorkspace(String id) async {
    final workspace = _workspaces.firstWhere((w) => w.id == id);
    return {
      'workspace': workspace.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  Future<WorkspaceMetadata?> importWorkspace(Map<String, dynamic> data) async {
    try {
      final wsData = data['workspace'] as Map<String, dynamic>;
      final workspace = WorkspaceMetadata(
        id: const Uuid().v4(),
        name: wsData['name'] as String,
        description: wsData['description'] as String? ?? '',
        isActive: false,
      );
      _workspaces.add(workspace);
      await _saveToStorage();
      AppLogger.instance.info('Workspace imported: ${workspace.name}', category: 'WORKSPACE');
      return workspace;
    } catch (e) {
      AppLogger.instance.error('Failed to import workspace', category: 'WORKSPACE');
      return null;
    }
  }

  Map<String, dynamic> getWorkspaceDiagnostics() {
    return {
      'totalWorkspaces': _workspaces.length,
      'currentWorkspaceId': _currentWorkspaceId,
      'workspaceNames': _workspaces.map((w) => w.name).toList(),
    };
  }
}
