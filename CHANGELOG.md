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
