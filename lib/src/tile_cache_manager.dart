import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';

import 'tile_store_io.dart' if (dart.library.js_interop) 'tile_store_web.dart';

/// Manages the tile cache store used by [MapTileLayer].
///
/// Provides static methods to initialize, access, and clear the tile cache.
///
/// On Android, iOS, Windows, macOS and Linux the cache is stored in the
/// system's temporary directory under a `MapTiles` subdirectory. On web there
/// is no temp directory, so tiles are cached in memory for the lifetime of the
/// tab instead. Check [isInMemory] if you need to know which one you got.
class TileCacheManager {
  TileCacheManager._();

  static Future<CacheStore>? _cacheStoreFuture;

  /// Default cache duration (30 days).
  static const Duration defaultCacheMaxAge = Duration(days: 30);

  /// Current cache max age. Can be changed via [setCacheMaxAge].
  static Duration _cacheMaxAge = defaultCacheMaxAge;

  /// Get the current cache max age.
  static Duration get cacheMaxAge => _cacheMaxAge;

  /// Whether tiles are cached in memory rather than on disk.
  ///
  /// `true` on web, `false` everywhere else. In memory caches do not survive
  /// a page reload.
  static bool get isInMemory => tileStoreIsInMemory;

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
  static Future<CacheStore> initCacheStore() async {
    _cacheStoreFuture ??= createTileStore();
    return _cacheStoreFuture!;
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
