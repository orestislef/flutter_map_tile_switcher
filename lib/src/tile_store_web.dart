import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// There is no temp directory to write to in a browser, so web caches in RAM.
const bool tileStoreIsInMemory = true;

/// Total tile cache size on web, in bytes.
const int _maxSize = 32 * 1024 * 1024;

/// Largest single tile that will be cached on web, in bytes.
///
/// `MemCacheStore` wants `maxEntrySize * 5 <= maxSize` or it starts evicting
/// everything, so keep these two in step if you change them.
const int _maxEntrySize = 2 * 1024 * 1024;

/// Creates the in memory tile store used on web.
///
/// Tiles live in an LRU map for the lifetime of the tab, so panning back over
/// ground you have already seen stays instant, but a page reload starts cold.
/// The browser's own HTTP cache still works on top of this.
Future<CacheStore> createTileStore() async => MemCacheStore(
      maxSize: _maxSize,
      maxEntrySize: _maxEntrySize,
    );
