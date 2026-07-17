import 'dart:async';

enum EventPriority { low, normal, high, critical }

abstract class AppEvent {
  const AppEvent({this.timestamp, this.source = ''});
  final DateTime? timestamp;
  final String source;
  DateTime get eventTime => timestamp ?? DateTime.now();
  String get eventType => runtimeType.toString();
}

class TypedEvent<T> extends AppEvent {
  const TypedEvent(this.payload, {super.source, super.timestamp});
  final T payload;
}

class _EventSubscription {
  _EventSubscription({
    required this.handler,
    required this.priority,
    required this.streamController,
  });
  final dynamic Function(AppEvent) handler;
  final EventPriority priority;
  final StreamController<AppEvent> streamController;
  bool isActive = true;
}

class EventBus {
  EventBus._();
  static final EventBus instance = EventBus._();

  final Map<Type, List<_EventSubscription>> _subscriptions = {};
  final List<AppEvent> _eventHistory = [];
  final Map<Type, int> _eventCounts = {};
  int _maxHistorySize = 500;
  bool isEnabled = true;
  int _eventsPublished = 0;
  int _eventsDelivered = 0;

  StreamSubscription<T> on<T extends AppEvent>(
    void Function(T event) handler, {
    EventPriority priority = EventPriority.normal,
  }) {
    final controller = StreamController<AppEvent>.broadcast();
    final subscription = _EventSubscription(
      handler: (event) => handler(event as T),
      priority: priority,
      streamController: controller,
    );
    _subscriptions.putIfAbsent(T, () => []).add(subscription);
    return controller.stream.where((e) => e is T).cast<T>().listen((_) {});
  }

  Stream<T> subscribe<T extends AppEvent>({
    EventPriority priority = EventPriority.normal,
  }) {
    final controller = StreamController<AppEvent>.broadcast();
    final subscription = _EventSubscription(
      handler: (event) {},
      priority: priority,
      streamController: controller,
    );
    _subscriptions.putIfAbsent(T, () => []).add(subscription);
    return controller.stream.where((e) => e is T).cast<T>();
  }

  void publish(AppEvent event) {
    if (!isEnabled) return;
    _eventsPublished++;
    _eventCounts[event.runtimeType] = (_eventCounts[event.runtimeType] ?? 0) + 1;
    _recordHistory(event);
    final subscriptions = _subscriptions[event.runtimeType] ?? [];
    final sorted = List<_EventSubscription>.from(subscriptions)
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    for (final sub in sorted) {
      if (!sub.isActive) continue;
      try {
        sub.handler(event);
        sub.streamController.add(event);
        _eventsDelivered++;
      } catch (_) {}
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
    final subs = _subscriptions[T];
    return subs != null && subs.any((s) => s.isActive);
  }

  int listenerCount<T extends AppEvent>() {
    return _subscriptions[T]?.where((s) => s.isActive).length ?? 0;
  }

  void _recordHistory(AppEvent event) {
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }
  }

  List<AppEvent> getHistory({Type? eventType, int? limit}) {
    var events = List<AppEvent>.from(_eventHistory);
    if (eventType != null) {
      events = events.where((e) => e.runtimeType == eventType).toList();
    }
    if (limit != null && events.length > limit) {
      events = events.sublist(events.length - limit);
    }
    return List.unmodifiable(events);
  }

  Map<Type, int> getEventCounts() => Map.unmodifiable(_eventCounts);
  int get totalEventsPublished => _eventsPublished;
  int get totalEventsDelivered => _eventsDelivered;
  set maxHistorySize(int value) => _maxHistorySize = value;

  void clearHistory() {
    _eventHistory.clear();
    _eventCounts.clear();
    _eventsPublished = 0;
    _eventsDelivered = 0;
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
