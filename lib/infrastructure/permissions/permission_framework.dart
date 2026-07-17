enum PermissionStatus { granted, denied, revoked, pending }

class Permission {
  const Permission({
    required this.id,
    required this.name,
    this.description = '',
    this.isRevocable = true,
    this.requiresUserConsent = false,
  });

  final String id;
  final String name;
  final String description;
  final bool isRevocable;
  final bool requiresUserConsent;
}

class PermissionGrant {
  PermissionGrant({
    required this.permissionId,
    required this.moduleId,
    this.status = PermissionStatus.pending,
    this.grantedAt,
    this.revokedAt,
    this.reason = '',
  });

  final String permissionId;
  final String moduleId;
  PermissionStatus status;
  DateTime? grantedAt;
  DateTime? revokedAt;
  String reason;
}

class PermissionRegistry {
  PermissionRegistry._();
  static final PermissionRegistry instance = PermissionRegistry._();

  static const clipboard = Permission(id: 'clipboard', name: 'Clipboard', description: 'Access clipboard for copy/paste');
  static const export = Permission(id: 'export', name: 'Export', description: 'Export data from the application');
  static const import_ = Permission(id: 'import', name: 'Import', description: 'Import data into the application');
  static const vault = Permission(id: 'vault', name: 'Vault', description: 'Access vault storage');
  static const history = Permission(id: 'history', name: 'History', description: 'Access generation history');
  static const workspace = Permission(id: 'workspace', name: 'Workspace', description: 'Manage workspaces');
  static const automation = Permission(id: 'automation', name: 'Automation', description: 'Run automated tasks');
  static const diagnostics = Permission(id: 'diagnostics', name: 'Diagnostics', description: 'Access diagnostic data');
  static const notifications = Permission(id: 'notifications', name: 'Notifications', description: 'Send notifications');
  static const plugins = Permission(id: 'plugins', name: 'Plugins', description: 'Manage plugins');
  static const developer = Permission(id: 'developer', name: 'Developer', description: 'Access developer tools');

  static const allPermissions = [
    clipboard, export, import_, vault, history, workspace,
    automation, diagnostics, notifications, plugins, developer,
  ];

  final Map<String, Permission> _registeredPermissions = {};
  final List<PermissionGrant> _grants = [];

  void initialize() {
    for (final permission in allPermissions) {
      _registeredPermissions[permission.id] = permission;
    }
  }

  void registerPermission(Permission permission) {
    _registeredPermissions[permission.id] = permission;
  }

  void unregisterPermission(String permissionId) {
    _registeredPermissions.remove(permissionId);
    _grants.removeWhere((g) => g.permissionId == permissionId);
  }

  Future<bool> requestPermission(String moduleId, String permissionId) async {
    final permission = _registeredPermissions[permissionId];
    if (permission == null) return false;
    final existing = _grants.where(
      (g) => g.moduleId == moduleId && g.permissionId == permissionId,
    );
    if (existing.isNotEmpty) {
      final grant = existing.first;
      if (grant.status == PermissionStatus.granted) return true;
      grant.status = PermissionStatus.granted;
      grant.grantedAt = DateTime.now();
      grant.revokedAt = null;
      return true;
    }
    _grants.add(PermissionGrant(
      permissionId: permissionId,
      moduleId: moduleId,
      status: PermissionStatus.granted,
      grantedAt: DateTime.now(),
    ));
    return true;
  }

  void revokePermission(String moduleId, String permissionId) {
    final grant = _grants.firstWhere(
      (g) => g.moduleId == moduleId && g.permissionId == permissionId,
      orElse: () => PermissionGrant(permissionId: permissionId, moduleId: moduleId),
    );
    final permission = _registeredPermissions[permissionId];
    if (permission != null && permission.isRevocable) {
      grant.status = PermissionStatus.revoked;
      grant.revokedAt = DateTime.now();
    }
  }

  void revokeAllPermissions(String moduleId) {
    for (final grant in _grants.where((g) => g.moduleId == moduleId)) {
      final permission = _registeredPermissions[grant.permissionId];
      if (permission != null && permission.isRevocable) {
        grant.status = PermissionStatus.revoked;
        grant.revokedAt = DateTime.now();
      }
    }
  }

  bool hasPermission(String moduleId, String permissionId) {
    return _grants.any(
      (g) => g.moduleId == moduleId && g.permissionId == permissionId && g.status == PermissionStatus.granted,
    );
  }

  List<PermissionGrant> getGrantsForModule(String moduleId) {
    return List.unmodifiable(_grants.where((g) => g.moduleId == moduleId));
  }

  List<PermissionGrant> getGrantsForPermission(String permissionId) {
    return List.unmodifiable(_grants.where((g) => g.permissionId == permissionId));
  }

  List<Permission> getRegisteredPermissions() => List.unmodifiable(_registeredPermissions.values);

  Map<String, dynamic> getDiagnostics() {
    return {
      'registeredPermissions': _registeredPermissions.length,
      'totalGrants': _grants.length,
      'grantsByStatus': {
        for (final status in PermissionStatus.values)
          status.name: _grants.where((g) => g.status == status).length,
      },
      'grantsByModule': {
        for (final grant in _grants)
          grant.moduleId: _grants.where((g) => g.moduleId == grant.moduleId).length,
      },
    };
  }
}
