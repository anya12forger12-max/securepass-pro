import 'dart:async';

import 'package:securepass_pro/core/security/clipboard_service.dart' as core;
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class ClipboardStatus {
  const ClipboardStatus({
    required this.isEmpty,
    required this.autoClearEnabled,
    required this.monitoringEnabled,
    this.autoClearDurationSeconds = 30,
  });

  final bool isEmpty;
  final bool autoClearEnabled;
  final bool monitoringEnabled;
  final int autoClearDurationSeconds;
}

class EnhancedClipboardService {
  EnhancedClipboardService._();
  static final EnhancedClipboardService _instance = EnhancedClipboardService._();
  static EnhancedClipboardService get instance => _instance;

  late core.ClipboardService _coreClipboard;
  bool _initialized = false;
  bool _monitoringEnabled = false;
  bool _autoClearEnabled = true;
  int _autoClearDurationSeconds = 30;
  Timer? _monitoringTimer;
  int _operationCount = 0;
  DateTime? _lastCopyTime;
  DateTime? _lastClearTime;

  Future<void> initialize({
    int autoClearDuration = 30,
    bool monitoring = false,
  }) async {
    if (_initialized) return;
    _autoClearDurationSeconds = autoClearDuration;
    _monitoringEnabled = monitoring;
    _coreClipboard = core.ClipboardService(
      defaultAutoClearDuration: Duration(seconds: autoClearDuration),
    );
    _initialized = true;
    AppLogger.instance.info('Enhanced clipboard service initialized', category: 'CLIPBOARD');
  }

  Future<bool> copy(String text, {bool autoClear = true}) async {
    final duration = autoClear
        ? Duration(seconds: _autoClearDurationSeconds)
        : null;
    final result = await _coreClipboard.copyToClipboard(text, autoClearDuration: duration);
    if (result) {
      _operationCount++;
      _lastCopyTime = DateTime.now();
      _autoClearEnabled = autoClear;
      AppLogger.instance.debug('Clipboard: text copied (autoClear: $autoClear)', category: 'CLIPBOARD');
    }
    return result;
  }

  Future<bool> copyWithAutoClear(String text, int durationSeconds) async {
    _autoClearDurationSeconds = durationSeconds;
    final result = await _coreClipboard.copyToClipboard(
      text,
      autoClearDuration: Duration(seconds: durationSeconds),
    );
    if (result) {
      _operationCount++;
      _lastCopyTime = DateTime.now();
      _autoClearEnabled = true;
    }
    return result;
  }

  Future<String?> getText() async {
    return _coreClipboard.getClipboardContent();
  }

  Future<bool> clear() async {
    final result = await _coreClipboard.clearClipboard();
    if (result) {
      _lastClearTime = DateTime.now();
      AppLogger.instance.debug('Clipboard cleared manually', category: 'CLIPBOARD');
    }
    return result;
  }

  Future<bool> clearManual() async {
    return clear();
  }

  ClipboardStatus getStatus() {
    return ClipboardStatus(
      isEmpty: !_coreClipboard.hasActiveContent,
      autoClearEnabled: _autoClearEnabled,
      monitoringEnabled: _monitoringEnabled,
      autoClearDurationSeconds: _autoClearDurationSeconds,
    );
  }

  void configure({int? autoClearDuration, bool? monitoring}) {
    if (autoClearDuration != null) {
      _autoClearDurationSeconds = autoClearDuration;
    }
    if (monitoring != null) {
      _monitoringEnabled = monitoring;
    }
    AppLogger.instance.debug('Clipboard configured: autoClear=${_autoClearDurationSeconds}s, monitoring=$_monitoringEnabled', category: 'CLIPBOARD');
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'hasActiveContent': _coreClipboard.hasActiveContent,
      'autoClearEnabled': _autoClearEnabled,
      'autoClearDurationSeconds': _autoClearDurationSeconds,
      'monitoringEnabled': _monitoringEnabled,
      'operationCount': _operationCount,
      'lastCopyTime': _lastCopyTime?.toIso8601String(),
      'lastClearTime': _lastClearTime?.toIso8601String(),
    };
  }

  void startMonitoring() {
    _monitoringEnabled = true;
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_coreClipboard.hasActiveContent) {
        _monitoringTimer?.cancel();
        _monitoringTimer = null;
        _monitoringEnabled = false;
      }
    });
  }

  void stopMonitoring() {
    _monitoringEnabled = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void dispose() {
    stopMonitoring();
  }
}
