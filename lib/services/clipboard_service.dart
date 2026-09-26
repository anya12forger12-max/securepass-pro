import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:securepass_pro/core/security/clipboard_service.dart' as core;
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/services/lifecycle_service.dart';

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

  /// Persisted so an auto-clear deadline survives a process kill.
  static const String _deadlineKey = 'clipboard_auto_clear_deadline';

  core.ClipboardService? _lazyCoreClipboard;
  bool _initialized = false;
  bool _monitoringEnabled = false;
  bool _autoClearEnabled = true;
  int _autoClearDurationSeconds = 30;
  Timer? _monitoringTimer;
  int _operationCount = 0;
  DateTime? _lastCopyTime;
  DateTime? _lastClearTime;
  DateTime? _autoClearDeadline;

  core.ClipboardService get _coreClipboard => _lazyCoreClipboard ??= core.ClipboardService(
        defaultAutoClearDuration: Duration(seconds: _autoClearDurationSeconds),
      );

  Future<void> initialize({
    int autoClearDuration = 30,
    bool monitoring = false,
  }) async {
    if (_initialized) return;
    _autoClearDurationSeconds = autoClearDuration;
    _monitoringEnabled = monitoring;
    LifecycleService.instance.addListener(_handleLifecycleChange);
    _initialized = true;
    await clearStaleClipboardOnStartup();
    AppLogger.instance.info('Enhanced clipboard service initialized', category: 'CLIPBOARD');
  }

  /// Clears a secret left on the clipboard by a previous process.
  ///
  /// The in-memory auto-clear timer cannot survive a process kill, so the
  /// deadline is persisted. On the next launch, an already-overdue deadline
  /// means a secret would otherwise sit on the clipboard indefinitely.
  @visibleForTesting
  Future<bool> clearStaleClipboardOnStartup() async {
    final stored = PreferencesStorage.instance.getString(_deadlineKey);
    if (stored == null) return false;
    await PreferencesStorage.instance.remove(_deadlineKey);
    final deadline = DateTime.tryParse(stored);
    if (deadline == null) return false;
    if (DateTime.now().isBefore(deadline)) return false;
    await _coreClipboard.clearClipboard();
    AppLogger.instance.info(
      'Cleared a clipboard secret left over from a previous session',
      category: 'CLIPBOARD',
    );
    return true;
  }

  void _persistDeadline() {
    final deadline = _autoClearDeadline;
    if (deadline == null) {
      unawaited(PreferencesStorage.instance.remove(_deadlineKey));
    } else {
      unawaited(
        PreferencesStorage.instance.setString(
          _deadlineKey,
          deadline.toIso8601String(),
        ),
      );
    }
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
      _autoClearDeadline = duration != null ? DateTime.now().add(duration) : null;
      _persistDeadline();
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
      _autoClearDeadline = DateTime.now().add(Duration(seconds: durationSeconds));
      _persistDeadline();
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
      _autoClearDeadline = null;
      _persistDeadline();
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

  void _handleLifecycleChange(AppLifecycleState state) {
    if (!_coreClipboard.hasActiveContent || _autoClearDeadline == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        final remaining = _autoClearDeadline!.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          unawaited(clear());
        } else {
          _coreClipboard.rearmAutoClear(remaining);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        unawaited(clear());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
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
    LifecycleService.instance.removeListener(_handleLifecycleChange);
    _lazyCoreClipboard?.cancelAutoClear();
    _autoClearDeadline = null;
  }
}
