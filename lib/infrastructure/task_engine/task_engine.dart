import 'dart:async';

enum TaskState { pending, running, completed, failed, canceled, retrying }

enum TaskPriority { low, normal, high, critical }

class TaskProgress {
  const TaskProgress({this.current = 0, this.total = 100, this.message = ''});
  final int current;
  final int total;
  final String message;
  double get fraction => total > 0 ? current / total : 0;
  int get percent => (fraction * 100).round();
}

class RetryPolicy {
  const RetryPolicy({this.maxRetries = 3, this.delay = const Duration(seconds: 1), this.backoffMultiplier = 2.0});
  final int maxRetries;
  final Duration delay;
  final double backoffMultiplier;
  Duration getDelay(int attempt) {
    return Duration(milliseconds: (delay.inMilliseconds * (backoffMultiplier * attempt)).round());
  }
}

class Task<T> {
  Task({
    required this.id,
    required this.name,
    required this.execute,
    this.priority = TaskPriority.normal,
    this.retryPolicy = const RetryPolicy(),
    this.timeout,
    this.onProgress,
    this.onCompleted,
    this.onFailed,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final Future<T> Function(TaskProgressCallback) execute;
  final TaskPriority priority;
  final RetryPolicy retryPolicy;
  final Duration? timeout;
  final void Function(TaskProgress)? onProgress;
  final void Function(T result)? onCompleted;
  final void Function(Object error)? onFailed;
  final Map<String, dynamic> metadata;

  TaskState state = TaskState.pending;
  int _attempt = 0;
  int get attempt => _attempt;
  T? result;
  Object? error;
  TaskProgress progress = const TaskProgress();
  DateTime? createdAt;
  DateTime? startedAt;
  DateTime? completedAt;
  Duration? get duration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}

typedef TaskProgressCallback = void Function(TaskProgress progress);

class TaskHandle<T> {
  TaskHandle._(this._task, this._engine);
  final Task<T> _task;
  final TaskEngine _engine;
  String get id => _task.id;
  String get name => _task.name;
  TaskState get state => _task.state;
  TaskProgress get progress => _task.progress;
  Future<T>? _future;
  Future<T> get result async {
    if (_future != null) return _future!;
    throw StateError('Task not yet started');
  }
  void cancel() => _engine.cancelTask(_task.id);
}

class _TaskQueue {
  final List<Task<dynamic>> _queue = [];
  void add(Task<dynamic> task) {
    _queue.add(task);
    _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }
  Task<dynamic>? next() => _queue.isEmpty ? null : _queue.removeAt(0);
  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;
  List<Task<dynamic>> get all => List.unmodifiable(_queue);
  void remove(String id) => _queue.removeWhere((t) => t.id == id);
}

class TaskEngine {
  TaskEngine._();
  static final TaskEngine instance = TaskEngine._();

  final _TaskQueue _queue = _TaskQueue();
  final Map<String, Task<dynamic>> _running = {};
  final Map<String, Task<dynamic>> _completed = {};
  final List<Task<dynamic>> _history = [];
  int _maxConcurrent = 4;
  final int _maxHistory = 200;
  bool _initialized = false;
  int _totalExecuted = 0;
  int _totalFailed = 0;
  int _totalCanceled = 0;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  Future<TaskHandle<dynamic>> submit<T>(Task<T> task) async {
    task.createdAt = DateTime.now();
    _queue.add(task);
    final handle = TaskHandle._(task, this);
    _processQueue();
    return handle;
  }

  Future<T> execute<T>(String name, Future<T> Function(TaskProgressCallback) execute, {
    TaskPriority priority = TaskPriority.normal,
    RetryPolicy retryPolicy = const RetryPolicy(),
    Duration? timeout,
  }) async {
    final task = Task<T>(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}_$_totalExecuted',
      name: name,
      execute: execute,
      priority: priority,
      retryPolicy: retryPolicy,
      timeout: timeout,
    );
    await submit(task);
    await _awaitTask(task);
    if (task.state == TaskState.failed) {
      throw task.error ?? Exception('Task failed');
    }
    return task.result as T;
  }

  Future<void> _awaitTask(Task<dynamic> task) async {
    while (task.state == TaskState.pending || task.state == TaskState.running || task.state == TaskState.retrying) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _processQueue() {
    while (_running.length < _maxConcurrent && !_queue.isEmpty) {
      final task = _queue.next();
      if (task == null) break;
      _runTask(task);
    }
  }

  void _runTask(Task<dynamic> task) {
    task.state = TaskState.running;
    task.startedAt = DateTime.now();
    _running[task.id] = task;
    _totalExecuted++;

    () async {
      try {
        final result = await _executeWithTimeout(task);
        if (task.state == TaskState.canceled) return;
        task.result = result;
        task.state = TaskState.completed;
        task.completedAt = DateTime.now();
        task.onCompleted?.call(result);
      } catch (e) {
        if (task.state == TaskState.canceled) return;
        task.error = e;
        if (task._attempt < task.retryPolicy.maxRetries) {
          task._attempt++;
          task.state = TaskState.retrying;
          _running.remove(task.id);
          final delay = task.retryPolicy.getDelay(task._attempt);
          Future.delayed(delay, () {
            if (task.state == TaskState.retrying) {
              task.state = TaskState.pending;
              _queue.add(task);
              _processQueue();
            }
          });
          return;
        }
        task.state = TaskState.failed;
        task.completedAt = DateTime.now();
        _totalFailed++;
        task.onFailed?.call(e);
      } finally {
        _running.remove(task.id);
        _recordHistory(task);
        _processQueue();
      }
    }();
  }

  Future<dynamic> _executeWithTimeout(Task<dynamic> task) async {
    void progressCallback(TaskProgress p) {
      task.progress = p;
      task.onProgress?.call(p);
    }
    if (task.timeout != null) {
      return task.execute(progressCallback).timeout(task.timeout!);
    }
    return task.execute(progressCallback);
  }

  void cancelTask(String taskId) {
    final task = _running[taskId] ?? _queue.all.where((t) => t.id == taskId).firstOrNull;
    if (task != null) {
      task.state = TaskState.canceled;
      task.completedAt = DateTime.now();
      _running.remove(taskId);
      _queue.remove(taskId);
      _totalCanceled++;
      _recordHistory(task);
      _processQueue();
    }
  }

  void cancelAll() {
    for (final task in _running.values.toList()) {
      cancelTask(task.id);
    }
    while (!_queue.isEmpty) {
      final task = _queue.next();
      if (task != null) cancelTask(task.id);
    }
  }

  void _recordHistory(Task<dynamic> task) {
    _history.add(task);
    _completed[task.id] = task;
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  Task<dynamic>? getTask(String taskId) => _completed[taskId] ?? _running[taskId];
  List<Task<dynamic>> getRunningTasks() => List.unmodifiable(_running.values);
  List<Task<dynamic>> getPendingTasks() => _queue.all;
  List<Task<dynamic>> getHistory() => List.unmodifiable(_history);

  set maxConcurrent(int value) => _maxConcurrent = value;
  int get queueLength => _queue.length;
  int get runningCount => _running.length;

  Map<String, dynamic> getDiagnostics() {
    return {
      'queueLength': _queue.length,
      'running': _running.length,
      'completed': _completed.length,
      'totalExecuted': _totalExecuted,
      'totalFailed': _totalFailed,
      'totalCanceled': _totalCanceled,
      'historySize': _history.length,
      'runningTasks': _running.values.map((t) => {
        'id': t.id,
        'name': t.name,
        'priority': t.priority.name,
        'state': t.state.name,
        'progress': '${t.progress.percent}%',
      }).toList(),
    };
  }
}
