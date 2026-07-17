import 'package:flutter/material.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class LifecycleService extends WidgetsBindingObserver {
  LifecycleService._();
  static final LifecycleService _instance = LifecycleService._();
  static LifecycleService get instance => _instance;

  bool _initialized = false;
  AppLifecycleState? _currentState;
  final List<void Function(AppLifecycleState)> _listeners = [];
  final List<Map<String, dynamic>> _stateChanges = [];
  DateTime? _startTime;

  void initialize() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _currentState = WidgetsBinding.instance.lifecycleState;
    _startTime = DateTime.now();
    _initialized = true;
    AppLogger.instance.info('Lifecycle service initialized: state=$_currentState', category: 'LIFECYCLE');
  }

  AppLifecycleState getState() => _currentState ?? AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _currentState;
    _currentState = state;

    _stateChanges.add({
      'from': previousState?.name ?? 'unknown',
      'to': state.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_stateChanges.length > 100) {
      _stateChanges.removeAt(0);
    }

    for (final listener in _listeners) {
      try {
        listener(state);
      } catch (e) {
        AppLogger.instance.error('Lifecycle listener error', category: 'LIFECYCLE');
      }
    }

    AppLogger.instance.debug('Lifecycle: ${previousState?.name} -> ${state.name}', category: 'LIFECYCLE');
  }

  @override
  void didChangeMetrics() {
    AppLogger.instance.debug('Metrics changed', category: 'LIFECYCLE');
  }

  @override
  void didChangeTextScaleFactor() {
    AppLogger.instance.debug('Text scale factor changed', category: 'LIFECYCLE');
  }

  void addListener(void Function(AppLifecycleState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AppLifecycleState) listener) {
    _listeners.remove(listener);
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'currentState': _currentState?.name ?? 'unknown',
      'listenerCount': _listeners.length,
      'stateChangeCount': _stateChanges.length,
      'uptime': getUptime().inSeconds,
      'startTime': _startTime?.toIso8601String(),
    };
  }

  Duration getUptime() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
    _stateChanges.clear();
    _initialized = false;
  }
}
