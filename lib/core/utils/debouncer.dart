import 'dart:async';

class Debouncer {
  Debouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;
  Timer? _timer;

  bool get isActive => _timer?.isActive == true;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class Throttle {
  Throttle({
    this.interval = const Duration(milliseconds: 300),
  });

  final Duration interval;
  DateTime? _lastExecution;
  Timer? _pendingTimer;

  bool get isActive => _pendingTimer?.isActive == true;

  void call(void Function() action) {
    final now = DateTime.now();

    if (_lastExecution == null || now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      action();
      return;
    }

    _pendingTimer?.cancel();
    final remaining = interval - now.difference(_lastExecution!);
    _pendingTimer = Timer(remaining, () {
      _lastExecution = DateTime.now();
      action();
    });
  }

  void cancel() {
    _pendingTimer?.cancel();
  }

  void dispose() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }
}

class AsyncDebouncer<T> {
  AsyncDebouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;
  Timer? _timer;
  Completer<T>? _completer;

  bool get isActive => _timer?.isActive == true;

  Future<T?> call(Future<T> Function() action) async {
    _timer?.cancel();
    _completer?.complete(null);

    _completer = Completer<T>();
    final completer = _completer!;

    _timer = Timer(delay, () async {
      try {
        final result = await action();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  void cancel() {
    _timer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(null);
    }
  }

  void dispose() {
    cancel();
    _timer = null;
    _completer = null;
  }
}
