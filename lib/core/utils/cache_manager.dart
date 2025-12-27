import 'dart:async';

/// Simple in-memory cache with TTL support
class CacheManager<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration defaultTTL;
  Timer? _cleanupTimer;

  CacheManager({
    this.defaultTTL = const Duration(minutes: 5),
  }) {
    _startCleanupTimer();
  }

  /// Put value in cache with optional TTL
  void put(K key, V value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value,
      DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// Get value from cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Check if key exists and is not expired
  bool contains(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove key from cache
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Get all valid entries
  Map<K, V> getAll() {
    final result = <K, V>{};
    _cache.removeWhere((key, entry) {
      if (entry.isExpired) {
        return true;
      }
      result[key] = entry.value;
      return false;
    });
    return result;
  }

  /// Start cleanup timer to remove expired entries
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(defaultTTL, (_) {
      _cache.removeWhere((_, entry) => entry.isExpired);
    });
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  /// Get cache size
  int get size => _cache.length;
}

/// Internal cache entry with expiry
class _CacheEntry<T> {
  final T value;
  final DateTime expiryTime;

  _CacheEntry(this.value, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

/// Token cache specifically
class TokenCacheManager {
  static final TokenCacheManager _instance = TokenCacheManager._internal();
  late String? _cachedAccessToken;
  late DateTime _cacheTime;
  final Duration _cacheDuration = const Duration(minutes: 4); // Token expires in 5 min, cache for 4

  factory TokenCacheManager() => _instance;

  TokenCacheManager._internal() {
    _cachedAccessToken = null;
    _cacheTime = DateTime.fromMicrosecondsSinceEpoch(0);
  }

  /// Cache access token
  void cacheToken(String token) {
    _cachedAccessToken = token;
    _cacheTime = DateTime.now();
  }

  /// Get cached token if still valid
  String? getCachedToken() {
    if (_cachedAccessToken == null) return null;

    final now = DateTime.now();
    if (now.difference(_cacheTime) > _cacheDuration) {
      _cachedAccessToken = null;
      return null;
    }

    return _cachedAccessToken;
  }

  /// Clear cache
  void clearCache() {
    _cachedAccessToken = null;
    _cacheTime = DateTime.fromMicrosecondsSinceEpoch(0);
  }

  /// Check if token is still cached
  bool hasValidCache() {
    if (_cachedAccessToken == null) return false;
    return DateTime.now().difference(_cacheTime) <= _cacheDuration;
  }
}
