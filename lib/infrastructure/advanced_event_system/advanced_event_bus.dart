import 'dart:async';

import 'package:securepass_pro/infrastructure/event_bus/event_bus.dart';

enum EventDeliveryMode { immediate, queued, async }

class CancelableEvent extends AppEvent {
  CancelableEvent({super.source, super.timestamp});
  bool _isCanceled = false;
  bool get isCanceled => _isCanceled;
  void cancel() => _isCanceled = true;
}

class AsyncEvent extends AppEvent {
  const AsyncEvent({this.completer, super.source, super.timestamp});
  final Completer<void>? completer;
}

class _SubscriptionEntry {
  _SubscriptionEntry({
    required this.handler,
    required this.priority,
    required this.filter,
    required this.streamController,
  });
  final dynamic Function(AppEvent) handler;
  final EventPriority priority;
  final bool Function(AppEvent)? filter;
  final StreamController<AppEvent> streamController;
  bool isActive = true;
}

class _EventMetrics {
  int published = 0;
  int delivered = 0;
  int canceled = 0;
  int filtered = 0;
  int errored = 0;
  final Map<String, int> byType = {};
  final List<double> _deliveryTimesMs = [];
  double get avgDeliveryTimeMs =>
      _deliveryTimesMs.isEmpty ? 0 : _deliveryTimesMs.reduce((a, b) => a + b) / _deliveryTimesMs.length;
  void recordDelivery(double ms) {
    _deliveryTimesMs.add(ms);
    if (_deliveryTimesMs.length > 200) _deliveryTimesMs.removeAt(0);
  }
}

class AdvancedEventBus {
  AdvancedEventBus._();
  static final AdvancedEventBus instance = AdvancedEventBus._();

  final Map<Type, List<_SubscriptionEntry>> _subscriptions = {};
  final List<AppEvent> _history = [];
  final List<AppEvent> _replayBuffer = [];
  final _EventMetrics _metrics = _EventMetrics();
  final int _maxHistory = 1000;
  final int _maxReplayBuffer = 200;
  bool enabled = true;
  EventDeliveryMode _deliveryMode = EventDeliveryMode.immediate;

  StreamSubscription<T> on<T extends AppEvent>(
    void Function(T event) handler, {
    EventPriority priority = EventPriority.normal,
    bool Function(T event)? filter,
  }) {
    final controller = StreamController<AppEvent>.broadcast();
    final entry = _SubscriptionEntry(
      handler: (e) => handler(e as T),
      priority: priority,
      filter: filter != null ? (e) => filter(e as T) : null,
      streamController: controller,
    );
    _subscriptions.putIfAbsent(T, () => []).add(entry);
    return controller.stream.where((e) => e is T).cast<T>().listen((_) {});
  }

  void publish(AppEvent event) {
    if (!enabled) return;
    _metrics.published++;
    final typeName = event.runtimeType.toString();
    _metrics.byType[typeName] = (_metrics.byType[typeName] ?? 0) + 1;
    _recordHistory(event);
    _replayBuffer.add(event);
    if (_replayBuffer.length > _maxReplayBuffer) _replayBuffer.removeAt(0);

    if (_deliveryMode == EventDeliveryMode.async) {
      _deliverAsync(event);
    } else {
      _deliverSync(event);
    }
  }

  Future<void> publishAsync(AppEvent event) async {
    if (!enabled) return;
    _metrics.published++;
    _recordHistory(event);
    _replayBuffer.add(event);
    if (_replayBuffer.length > _maxReplayBuffer) _replayBuffer.removeAt(0);
    _deliverSync(event);
  }

  void _deliverSync(AppEvent event) {
    final subs = _subscriptions[event.runtimeType] ?? [];
    final sorted = List<_SubscriptionEntry>.from(subs)
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    for (final sub in sorted) {
      if (!sub.isActive) continue;
      if (sub.filter != null && !sub.filter!(event)) {
        _metrics.filtered++;
        continue;
      }
      if (event is CancelableEvent && event.isCanceled) {
        _metrics.canceled++;
        return;
      }
      final sw = Stopwatch()..start();
      try {
        sub.handler(event);
        _metrics.delivered++;
      } catch (_) {
        _metrics.errored++;
      }
      sw.stop();
      _metrics.recordDelivery(sw.elapsedMicroseconds / 1000.0);
    }
  }

  Future<void> _deliverAsync(AppEvent event) async {
    final subs = _subscriptions[event.runtimeType] ?? [];
    final sorted = List<_SubscriptionEntry>.from(subs)
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    for (final sub in sorted) {
      if (!sub.isActive) continue;
      if (sub.filter != null && !sub.filter!(event)) {
        _metrics.filtered++;
        continue;
      }
      if (event is CancelableEvent && event.isCanceled) {
        _metrics.canceled++;
        return;
      }
      final sw = Stopwatch()..start();
      try {
        await Future.microtask(() => sub.handler(event));
        _metrics.delivered++;
      } catch (_) {
        _metrics.errored++;
      }
      sw.stop();
      _metrics.recordDelivery(sw.elapsedMicroseconds / 1000.0);
    }
    if (event is AsyncEvent && event.completer != null && !event.completer!.isCompleted) {
      event.completer!.complete();
    }
  }

  void off<T extends AppEvent>() {
    final subs = _subscriptions.remove(T) ?? [];
    for (final sub in subs) {
      sub.isActive = false;
      sub.streamController.close();
    }
  }

  bool isListening<T extends AppEvent>() {
    return _subscriptions[T]?.any((s) => s.isActive) ?? false;
  }

  int listenerCount<T extends AppEvent>() {
    return _subscriptions[T]?.where((s) => s.isActive).length ?? 0;
  }

  List<AppEvent> replay({Type? eventType, int? limit}) {
    var events = List<AppEvent>.from(_replayBuffer);
    if (eventType != null) events = events.where((e) => e.runtimeType == eventType).toList();
    if (limit != null && events.length > limit) events = events.sublist(events.length - limit);
    return events;
  }

  void _recordHistory(AppEvent event) {
    _history.add(event);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  List<AppEvent> getHistory({Type? eventType, int? limit}) {
    var events = List<AppEvent>.from(_history);
    if (eventType != null) events = events.where((e) => e.runtimeType == eventType).toList();
    if (limit != null && events.length > limit) events = events.sublist(events.length - limit);
    return events;
  }

  Map<String, dynamic> getMetrics() {
    return {
      'published': _metrics.published,
      'delivered': _metrics.delivered,
      'canceled': _metrics.canceled,
      'filtered': _metrics.filtered,
      'errored': _metrics.errored,
      'avgDeliveryTimeMs': _metrics.avgDeliveryTimeMs.toStringAsFixed(3),
      'byType': Map<String, int>.from(_metrics.byType),
    };
  }

  set deliveryMode(EventDeliveryMode mode) => _deliveryMode = mode;

  void clearHistory() {
    _history.clear();
    _replayBuffer.clear();
    _metrics.published = 0;
    _metrics.delivered = 0;
    _metrics.canceled = 0;
    _metrics.filtered = 0;
    _metrics.errored = 0;
    _metrics.byType.clear();
  }

  void dispose() {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.isActive = false;
        sub.streamController.close();
      }
    }
    _subscriptions.clear();
    clearHistory();
  }
}
