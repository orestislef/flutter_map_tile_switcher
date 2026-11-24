## 0.1.0

**Breaking for apps still on `package:flutter/material.dart`.** Flutter 3.47
deprecated the framework's own Material library in favour of the
[material_ui](https://pub.dev/packages/material_ui) package, and the two have
separate `Theme` types. The package now uses material_ui, so the automatic dark
mode reads material_ui's `Theme.of(context).brightness`. In an app that moved
to material_ui the right tiles now come up without any bridge. In an app still
on the old Material the layer no longer sees the app's theme and always
picks the light tiles.

* `lib/` and the example import `package:material_ui/material_ui.dart` instead
  of `package:flutter/material.dart`, and the example runs on material_ui's
  `MaterialApp`
* Needs Dart 3.13 and Flutter 3.47 or newer
* Dependencies on their latest versions
* No other change in behaviour or API

If your app is still on `package:flutter/material.dart`, either stay on 0.0.x
or pass the brightness yourself:

```dart
MapTileLayer(
  mapType: MapTileType.osm,
  isDarkMode: Theme.of(context).brightness == Brightness.dark,
)
```

## 0.0.6

* License holder name updated

Nothing to change on your side.

## 0.0.5

* Fix: two `MapTileLayer`s with the same map type, theme and language shared
  one cached widget even when their `keepBuffer` or `userAgentPackageName`
  differed, so the second one quietly got the first one's settings. Both are
  now part of the widget cache key (`MapTileLayer.cacheKeyFor`)

Nothing to change on your side.

## 0.0.4

Web works now. The README always claimed it did, but `tile_cache_manager.dart`
imported `dart:io`, so pub.dev correctly refused to tag the package as
web compatible.

* Tile store is now picked with a conditional import. Disk (`FileCacheStore`)
  on mobile and desktop, memory (`MemCacheStore`, 32 MB LRU) on web
* New `TileCacheManager.isInMemory`, true on web, false everywhere else
* Fix: `setCacheMaxAge` did nothing. The duration was tracked but never passed
  to the tile provider, so tiles only expired when the server said so. It is
  now wired through as `maxStale`, which means the documented 30 day default
  actually applies
* Verified with a real `flutter build web --release`, wasm dry run passes too

Nothing to change on your side. If you were relying on tiles never expiring,
call `TileCacheManager.setCacheMaxAge()` with a longer duration.

## 0.0.3

Not a breaking change, but worth doing: CARTO started requiring an API key on
`basemaps.cartocdn.com` in late August 2026. Tiles still load without one, they
just come back with an "API KEY REQUIRED" watermark.

* Added optional `apiKey` on `MapTileLayer`, appended to the OSM tile URL as `key`
* Added `MapTileLayer.defaultApiKey` so you can set the key once in `main()`
* Empty or null key falls back to the old keyless URL, nothing breaks
* API key is hashed into the widget cache key instead of stored in plain text
* Bumped dependencies: flutter_map 8.3.2, flutter_map_cache 2.1.0,
  http_cache_file_store 2.0.2, path_provider 2.1.6, dio_cache_interceptor 4.0.7
* Example now uses latlong2 0.10.1 and flutter_lints 6.0.0

If you were already caching watermarked tiles, call `TileCacheManager.clearCache()`
once after adding your key.

## 0.0.2

* Fixed dependency compatibility: use CacheStore base type for broader version support
* Added pub.dev topics for better discoverability
* Improved compatibility with lower-bound dependency versions

## 0.0.1

* Initial release
* 3 map tile providers: OpenStreetMap (CartoDB), Google Maps, Satellite (ArcGIS)
* Built-in disk caching with configurable max age (default 30 days)
* Automatic dark mode support for OSM and Google Maps
* Locale-aware labels for Google Maps tiles
* Widget caching to prevent unnecessary rebuilds
* Fallback to non-cached tiles if cache initialization fails
