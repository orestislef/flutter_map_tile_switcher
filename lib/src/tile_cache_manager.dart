import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the tile cache store used by [MapTileLayer].
///
/// Provides static methods to initialize, access, and clear the tile cache.
/// The cache is stored in the system's temporary directory under a `MapTiles`
/// subdirectory.
class TileCacheManager {
  TileCacheManager._();

  static Future<FileCacheStore>? _cacheStoreFuture;

  /// Default cache duration (30 days).
  static const Duration defaultCacheMaxAge = Duration(days: 30);

  /// Current cache max age. Can be changed via [setCacheMaxAge].
  static Duration _cacheMaxAge = defaultCacheMaxAge;

  /// Get the current cache max age.
  static Duration get cacheMaxAge => _cacheMaxAge;

  /// Set a custom cache max age. Call this before building any [MapTileLayer].
  ///
  /// If the cache store has already been initialized, it will be
  /// reinitialized with the new max age on the next access.
  static void setCacheMaxAge(Duration duration) {
    if (_cacheMaxAge != duration) {
      _cacheMaxAge = duration;
      _cacheStoreFuture = null; // Force reinitialization
    }
  }

  /// Initialize or return the shared cache store.
  static Future<FileCacheStore> initCacheStore() async {
    _cacheStoreFuture ??= _createCacheStore();
    return _cacheStoreFuture!;
  }

  static Future<FileCacheStore> _createCacheStore() async {
    final dir = await getTemporaryDirectory();
    final cacheOptions = CacheOptions(
      store: FileCacheStore('${dir.path}${Platform.pathSeparator}MapTiles'),
      policy: CachePolicy.forceCache,
      maxStale: _cacheMaxAge,
      priority: CachePriority.high,
    );
    return cacheOptions.store as FileCacheStore;
  }

  /// Clears all cached map tiles and resets the internal widget cache.
  static Future<void> clearCache() async {
    try {
      final store = await initCacheStore();
      await store.clean();
      _cacheStoreFuture = null;
      MapTileLayerCache.clear();
    } catch (e) {
      debugPrint('Error clearing map tile cache: $e');
    }
  }
}

/// Internal widget cache to prevent unnecessary rebuilds when the
/// same map configuration is requested multiple times.
class MapTileLayerCache {
  MapTileLayerCache._();

  static final Map<String, dynamic> _cache = {};

  /// Get a cached widget by key, or null if not cached.
  static dynamic get(String key) => _cache[key];

  /// Store a widget in the cache.
  static void set(String key, dynamic widget) => _cache[key] = widget;

  /// Check if a key exists in the cache.
  static bool has(String key) => _cache.containsKey(key);

  /// Clear all cached widgets.
  static void clear() => _cache.clear();
}
