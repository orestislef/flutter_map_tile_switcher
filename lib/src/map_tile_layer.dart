import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';

import 'map_tile_type.dart';
import 'tile_cache_manager.dart';

/// A drop-in [TileLayer] widget for [FlutterMap] that supports multiple
/// map providers, built-in file caching, and automatic dark mode.
///
/// Simply add it as a child of [FlutterMap]:
///
/// ```dart
/// FlutterMap(
///   options: MapOptions(...),
///   children: [
///     MapTileLayer(mapType: MapTileType.osm),
///   ],
/// )
/// ```
///
/// ## Features
/// - **3 map providers**: OpenStreetMap (CartoDB), Google Maps, Satellite (ArcGIS)
/// - **Automatic dark mode**: Detects theme brightness and applies appropriate
///   tile styles or color filters
/// - **Built-in caching**: Tiles are cached with a configurable max age
///   (default 30 days), to disk on mobile and desktop, in memory on web
/// - **Widget caching**: Previously built tile layers are cached in memory to
///   avoid unnecessary rebuilds
/// - **Locale-aware**: Google Maps tiles use the device locale for labels
/// - **Optional API key**: Pass a CARTO API key to get unwatermarked OSM tiles
class MapTileLayer extends StatelessWidget {
  /// Fallback API key used when [apiKey] is not passed to the constructor.
  ///
  /// Set it once during app startup so you do not have to repeat the key at
  /// every call site:
  ///
  /// ```dart
  /// void main() {
  ///   MapTileLayer.defaultApiKey = const String.fromEnvironment('CARTO_API_KEY');
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Prefer `--dart-define` or remote config over hardcoding the key in source.
  static String? defaultApiKey;

  /// The map tile provider to use.
  final MapTileType mapType;

  /// Whether to use dark mode tiles.
  ///
  /// If `null` (default), automatically detected from [Theme.of(context).brightness].
  final bool? isDarkMode;

  /// Language code for map labels (e.g. `'en'`, `'el'`, `'de'`).
  ///
  /// If `null` (default), automatically detected from [Localizations.localeOf(context)].
  /// Currently only affects Google Maps tiles.
  final String? languageCode;

  /// Country code for map region bias (e.g. `'US'`, `'GR'`, `'DE'`).
  ///
  /// If `null` (default), automatically detected from [Localizations.localeOf(context)].
  /// Currently only affects Google Maps tiles.
  final String? countryCode;

  /// Package name used as the User-Agent for tile requests.
  ///
  /// If `null`, defaults to `'flutter_map_tile_switcher'`.
  /// Recommended to set this to your app's package name.
  final String? userAgentPackageName;

  /// Optional CARTO API key for [MapTileType.osm] tiles.
  ///
  /// Not required. Since late August 2026 CARTO still serves the basemaps
  /// without a key, but the tiles come back with an "API KEY REQUIRED"
  /// watermark burned in. Grab a free key at
  /// https://carto.com/basemaps/apikey and pass it here to get clean tiles.
  /// Free up to 5 million tile requests per calendar month.
  ///
  /// The key is appended to the tile URL as `key`.
  ///
  /// Falls back to [defaultApiKey] when `null`. An empty string is treated the
  /// same as `null`, so the layer keeps working without a key.
  ///
  /// [MapTileType.google] and [MapTileType.satellite] ignore this value, they
  /// use endpoints that take no key.
  final String? apiKey;

  /// Number of tiles to keep in the buffer around the visible area.
  /// Higher values use more memory but reduce flashing when panning.
  /// Defaults to `5`.
  final int keepBuffer;

  /// Creates a [MapTileLayer] widget.
  ///
  /// [mapType] is required and determines which tile provider to use.
  /// All other parameters are optional with sensible defaults.
  const MapTileLayer({
    super.key,
    required this.mapType,
    this.isDarkMode,
    this.languageCode,
    this.countryCode,
    this.userAgentPackageName,
    this.apiKey,
    this.keepBuffer = 5,
  });

  /// Resolves the key to actually use: the one passed to the constructor,
  /// then [defaultApiKey], then nothing. An empty string counts as nothing so
  /// a missing `--dart-define` falls back to the keyless url instead of
  /// sending `key=` with no value.
  @visibleForTesting
  static String? resolveApiKey(String? apiKey) {
    final key = apiKey ?? defaultApiKey;
    return (key != null && key.isNotEmpty) ? key : null;
  }

  /// Builds the CARTO url template and its placeholder values for
  /// [MapTileType.osm]. [apiKey] must already be normalized by
  /// [resolveApiKey]. With no key this returns the exact url the layer used
  /// before API keys were supported.
  @visibleForTesting
  static (String, Map<String, String>) osmTileUrl({
    required bool darkMode,
    required String? apiKey,
  }) {
    const base =
        'https://{s}.basemaps.cartocdn.com/{style}/{z}/{x}/{y}{scale}.png';
    return (
      apiKey == null ? base : '$base?key={apiKey}',
      {
        'style': darkMode ? 'dark_all' : 'light_all',
        'scale': '@2x',
        if (apiKey != null) 'apiKey': apiKey,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode =
        isDarkMode ?? Theme.of(context).brightness == Brightness.dark;
    final lang = languageCode ?? Localizations.localeOf(context).languageCode;
    final country =
        countryCode ?? Localizations.localeOf(context).countryCode ?? 'US';
    final packageName = userAgentPackageName ?? 'flutter_map_tile_switcher';

    final key = resolveApiKey(apiKey);

    // Check widget cache. Only the hash of the key goes into the cache key so
    // the key itself cannot leak through debug output.
    final cacheKey =
        '${mapType}_${darkMode}_${lang}_${country}_${key?.hashCode ?? 0}';
    if (MapTileLayerCache.has(cacheKey)) {
      return MapTileLayerCache.get(cacheKey) as Widget;
    }

    final widget = _buildFutureLayer(darkMode, lang, country, packageName, key);
    MapTileLayerCache.set(cacheKey, widget);
    return widget;
  }

  Widget _buildFutureLayer(
    bool darkMode,
    String lang,
    String country,
    String packageName,
    String? key,
  ) {
    return FutureBuilder<CacheStore>(
      future: TileCacheManager.initCacheStore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.transparent);
        }
        if (snapshot.hasError) {
          return _buildTileLayer(
            darkMode: darkMode,
            lang: lang,
            country: country,
            packageName: packageName,
            key: key,
            cacheStore: null,
          );
        }
        return _buildTileLayer(
          darkMode: darkMode,
          lang: lang,
          country: country,
          packageName: packageName,
          key: key,
          cacheStore: snapshot.data!,
        );
      },
    );
  }

  /// Wraps the cache store in a tile provider, honouring
  /// [TileCacheManager.cacheMaxAge]. Returns `null` when the store failed to
  /// initialize, which makes flutter_map fall back to uncached tiles.
  TileProvider? _tileProvider(CacheStore? cacheStore) {
    if (cacheStore == null) return null;
    return CachedTileProvider(
      store: cacheStore,
      cachePolicy: CachePolicy.forceCache,
      maxStale: TileCacheManager.cacheMaxAge,
    );
  }

  Widget _buildTileLayer({
    required bool darkMode,
    required String lang,
    required String country,
    required String packageName,
    required String? key,
    required CacheStore? cacheStore,
  }) {
    TileLayer tileLayer;

    switch (mapType) {
      case MapTileType.osm:
        final (url, options) = osmTileUrl(darkMode: darkMode, apiKey: key);
        tileLayer = TileLayer(
          urlTemplate: url,
          subdomains: const ['a', 'b', 'c', 'd'],
          additionalOptions: options,
          userAgentPackageName: packageName,
          tileProvider: _tileProvider(cacheStore),
          keepBuffer: keepBuffer,
        );
        break;

      case MapTileType.google:
        tileLayer = TileLayer(
          urlTemplate:
              'https://mt{s}.google.com/vt/lyrs=m@221097000&hl={hl}&gl={gl}&x={x}&y={y}&z={z}',
          subdomains: const ['0', '1', '2', '3'],
          additionalOptions: {
            'userAgent': packageName,
            'hl': lang,
            'gl': country,
          },
          tileProvider: _tileProvider(cacheStore),
          keepBuffer: keepBuffer,
        );
        if (darkMode) {
          return RepaintBoundary(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.2,
                -0.5,
                -0.3,
                0,
                255,
                -0.3,
                -0.5,
                -0.2,
                0,
                255,
                -0.3,
                -0.2,
                -0.5,
                0,
                255,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: tileLayer,
            ),
          );
        }
        break;

      case MapTileType.satellite:
        tileLayer = TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          tileProvider: _tileProvider(cacheStore),
          keepBuffer: keepBuffer,
        );
        break;
    }

    return RepaintBoundary(child: tileLayer);
  }
}
