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
