import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum MigrationStatus { pending, running, completed, failed, rolledBack }

enum MigrationType { configuration, workspace, plugin, theme, accessibility, policy, recipe, backup, database }

class MigrationStep {
  const MigrationStep({
    required this.id,
    required this.fromVersion,
    required this.toVersion,
    required this.type,
    required this.description,
    required this.up,
    this.down,
  });

  final String id;
  final int fromVersion;
  final int toVersion;
  final MigrationType type;
  final String description;
  final Future<void> Function() up;
  final Future<void> Function()? down;
}

class MigrationRecord {
  MigrationRecord({
    required this.stepId,
    required this.type,
    required this.status,
    required this.fromVersion,
    required this.toVersion,
    this.startedAt,
    this.completedAt,
    this.error,
  });

  final String stepId;
  final MigrationType type;
  MigrationStatus status;
  final int fromVersion;
  final int toVersion;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;

  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }
}

class MigrationEvent extends AppEvent {
  const MigrationEvent({
    required this.stepId,
    required this.status,
    this.error,
    super.source,
    super.timestamp,
  });

  final String stepId;
  final MigrationStatus status;
  final String? error;
}

class MigrationEngine {
  MigrationEngine._();
  static final MigrationEngine instance = MigrationEngine._();

  final Map<String, MigrationStep> _steps = {};
  final List<MigrationRecord> _history = [];
  int _currentVersion = 1;
  final EventBus _eventBus = EventBus.instance;

  int get currentVersion => _currentVersion;

  void registerStep(MigrationStep step) {
    _steps[step.id] = step;
  }

  void unregisterStep(String stepId) {
    _steps.remove(stepId);
  }

  List<MigrationStep> getStepsForType(MigrationType type) {
    return _steps.values.where((s) => s.type == type).toList()
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
  }

  List<MigrationStep> getPendingSteps({MigrationType? type, int? fromVersion}) {
    fromVersion ??= _currentVersion;
    return _steps.values.where((s) {
      if (type != null && s.type != type) return false;
      if (s.fromVersion < fromVersion!) return false;
      final alreadyRun = _history.any((h) => h.stepId == s.id && h.status == MigrationStatus.completed);
      return !alreadyRun;
    }).toList()
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
  }

  Future<bool> migrateToVersion(int targetVersion, {MigrationType? type}) async {
    final pendingSteps = getPendingSteps(type: type).where((s) => s.toVersion <= targetVersion);
    for (final step in pendingSteps) {
      final success = await runStep(step.id);
      if (!success) return false;
    }
    return true;
  }

  Future<bool> runStep(String stepId) async {
    final step = _steps[stepId];
    if (step == null) return false;
    final existingRecord = _history.where(
      (h) => h.stepId == stepId && h.status == MigrationStatus.completed,
    );
    if (existingRecord.isNotEmpty) return true;

    final record = MigrationRecord(
      stepId: stepId,
      type: step.type,
      status: MigrationStatus.running,
      fromVersion: step.fromVersion,
      toVersion: step.toVersion,
      startedAt: DateTime.now(),
    );
    _history.add(record);

    _eventBus.publish(MigrationEvent(
      stepId: stepId,
      status: MigrationStatus.running,
      source: 'MigrationEngine',
    ));

    try {
      await step.up();
      record.status = MigrationStatus.completed;
      record.completedAt = DateTime.now();
      if (step.toVersion > _currentVersion) {
        _currentVersion = step.toVersion;
      }
      _eventBus.publish(MigrationEvent(
        stepId: stepId,
        status: MigrationStatus.completed,
        source: 'MigrationEngine',
      ));
      return true;
    } catch (e) {
      record.status = MigrationStatus.failed;
      record.error = e.toString();
      record.completedAt = DateTime.now();
      _eventBus.publish(MigrationEvent(
        stepId: stepId,
        status: MigrationStatus.failed,
        error: e.toString(),
        source: 'MigrationEngine',
      ));
      return false;
    }
  }

  Future<bool> rollbackStep(String stepId) async {
    final step = _steps[stepId];
    if (step?.down == null) return false;
    final record = MigrationRecord(
      stepId: stepId,
      type: step!.type,
      status: MigrationStatus.running,
      fromVersion: step.toVersion,
      toVersion: step.fromVersion,
      startedAt: DateTime.now(),
    );
    _history.add(record);
    try {
      await step.down!();
      record.status = MigrationStatus.completed;
      record.completedAt = DateTime.now();
      if (step.fromVersion < _currentVersion) {
        _currentVersion = step.fromVersion;
      }
      return true;
    } catch (e) {
      record.status = MigrationStatus.failed;
      record.error = e.toString();
      record.completedAt = DateTime.now();
      return false;
    }
  }

  List<MigrationRecord> getHistory({MigrationType? type}) {
    if (type == null) return List.unmodifiable(_history);
    return List.unmodifiable(_history.where((h) => h.type == type));
  }

  MigrationRecord? getLastRecordForStep(String stepId) {
    final records = _history.where((h) => h.stepId == stepId).toList();
    return records.isNotEmpty ? records.last : null;
  }

  bool validateMigration({MigrationType? type}) {
    final pending = getPendingSteps(type: type);
    final failed = _history.where((h) => h.status == MigrationStatus.failed);
    return pending.isEmpty && failed.isEmpty;
  }

  Map<String, dynamic> getDiagnostics() {
    final stepsByType = <String, int>{};
    for (final type in MigrationType.values) {
      stepsByType[type.name] = getStepsForType(type).length;
    }
    return {
      'currentVersion': _currentVersion,
      'totalSteps': _steps.length,
      'stepsByType': stepsByType,
      'completedMigrations': _history.where((h) => h.status == MigrationStatus.completed).length,
      'failedMigrations': _history.where((h) => h.status == MigrationStatus.failed).length,
      'pendingMigrations': getPendingSteps().length,
    };
  }
}
