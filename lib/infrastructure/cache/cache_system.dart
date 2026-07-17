import 'dart:collection';

class CacheEntry<T> {
  CacheEntry({required this.key, required this.value, this.ttl, this.tags = const []});
  final String key;
  final T value;
  final DateTime createdAt = DateTime.now();
  final Duration? ttl;
  final List<String> tags;
  int accessCount = 0;
  DateTime lastAccessed = DateTime.now();
  bool get isExpired => ttl != null && DateTime.now().difference(createdAt) > ttl!;
}

class CacheStats {
  const CacheStats({this.hits = 0, this.misses = 0, this.evictions = 0, this.size = 0});
  final int hits;
  final int misses;
  final int evictions;
  final int size;
  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0;
}

class MemoryCache {
  MemoryCache({this.maxSize = 1000, this.defaultTtl});
  final int maxSize;
  final Duration? defaultTtl;
  final LinkedHashMap<String, CacheEntry<dynamic>> _entries = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) { _misses++; return null; }
    if (entry.isExpired) { _entries.remove(key); _misses++; return null; }
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();
    _hits++;
    return entry.value as T?;
  }

  void put<T>(String key, T value, {Duration? ttl, List<String> tags = const []}) {
    if (_entries.length >= maxSize && !_entries.containsKey(key)) {
      _evictOldest();
    }
    _entries[key] = CacheEntry(key: key, value: value, ttl: ttl ?? defaultTtl, tags: tags);
  }

  bool remove(String key) => _entries.remove(key) != null;

  void removeByTag(String tag) {
    _entries.removeWhere((_, entry) => entry.tags.contains(tag));
  }

  void clear() { _entries.clear(); }

  bool contains(String key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired) { _entries.remove(key); return false; }
    return true;
  }

  int get size => _entries.length;

  void _evictOldest() {
    if (_entries.isEmpty) return;
    final oldest = _entries.keys.first;
    _entries.remove(oldest);
    _evictions++;
  }

  void cleanup() {
    _entries.removeWhere((_, entry) => entry.isExpired);
  }

  CacheStats get stats => CacheStats(hits: _hits, misses: _misses, evictions: _evictions, size: size);

  Map<String, dynamic> getDiagnostics() {
    return {
      'size': size,
      'maxSize': maxSize,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hitRate': '${(stats.hitRate * 100).toStringAsFixed(1)}%',
    };
  }
}

class DiskCache {
  DiskCache({this.maxSizeBytes = 10 * 1024 * 1024});
  final int maxSizeBytes;
  final Map<String, CacheEntry<String>> _entries = {};
  int _currentSizeBytes = 0;
  int _hits = 0;
  int _misses = 0;

  String? get(String key) {
    final entry = _entries[key];
    if (entry == null) { _misses++; return null; }
    if (entry.isExpired) { _entries.remove(key); _misses++; return null; }
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();
    _hits++;
    return entry.value;
  }

  void put(String key, String value, {Duration? ttl}) {
    final sizeBytes = value.length * 2;
    if (_currentSizeBytes + sizeBytes > maxSizeBytes) _evictOldest();
    _entries[key] = CacheEntry(key: key, value: value, ttl: ttl);
    _currentSizeBytes += sizeBytes;
  }

  bool remove(String key) {
    final entry = _entries.remove(key);
    if (entry != null) { _currentSizeBytes -= entry.value.length * 2; return true; }
    return false;
  }

  void clear() { _entries.clear(); _currentSizeBytes = 0; }
  bool contains(String key) => _entries.containsKey(key) && !(_entries[key]?.isExpired ?? true);
  int get size => _entries.length;

  void _evictOldest() {
    if (_entries.isEmpty) return;
    final oldest = _entries.keys.first;
    final entry = _entries.remove(oldest);
    if (entry != null) _currentSizeBytes -= entry.value.length * 2;
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'size': size,
      'sizeBytes': _currentSizeBytes,
      'maxSizeBytes': maxSizeBytes,
      'hits': _hits,
      'misses': _misses,
      'hitRate': (_hits + _misses) > 0 ? '${(_hits / (_hits + _misses) * 100).toStringAsFixed(1)}%' : 'N/A',
    };
  }
}

class CacheSystem {
  CacheSystem._();
  static final CacheSystem instance = CacheSystem._();

  late final MemoryCache _memory;
  late final DiskCache _disk;
  bool _initialized = false;

  void initialize({int memoryMaxSize = 1000, int diskMaxSizeBytes = 10 * 1024 * 1024}) {
    if (_initialized) return;
    _memory = MemoryCache(maxSize: memoryMaxSize);
    _disk = DiskCache(maxSizeBytes: diskMaxSizeBytes);
    _initialized = true;
  }

  T? get<T>(String key) {
    final fromMemory = _memory.get<T>(key);
    if (fromMemory != null) return fromMemory;
    if (T == String) {
      final fromDisk = _disk.get(key);
      if (fromDisk != null) {
        _memory.put(key, fromDisk as T);
        return fromDisk as T?;
      }
    }
    return null;
  }

  void put<T>(String key, T value, {Duration? ttl, List<String> tags = const [], bool persistToDisk = false}) {
    _memory.put(key, value, ttl: ttl, tags: tags);
    if (persistToDisk && value is String) {
      _disk.put(key, value, ttl: ttl);
    }
  }

  bool remove(String key) {
    final memRemoved = _memory.remove(key);
    final diskRemoved = _disk.remove(key);
    return memRemoved || diskRemoved;
  }

  void removeByTag(String tag) => _memory.removeByTag(tag);
  void clear() { _memory.clear(); _disk.clear(); }
  bool contains(String key) => _memory.contains(key) || _disk.contains(key);
  void cleanup() => _memory.cleanup();

  Map<String, dynamic> getDiagnostics() => {
    'memory': _memory.getDiagnostics(),
    'disk': _disk.getDiagnostics(),
  };
}
