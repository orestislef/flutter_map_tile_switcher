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
/// - **Built-in caching**: Tiles are cached to disk with a configurable max age
///   (default 30 days)
/// - **Widget caching**: Previously built tile layers are cached in memory to
///   avoid unnecessary rebuilds
/// - **Locale-aware**: Google Maps tiles use the device locale for labels
class MapTileLayer extends StatelessWidget {
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
    this.keepBuffer = 5,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode =
        isDarkMode ?? Theme.of(context).brightness == Brightness.dark;
    final lang = languageCode ?? Localizations.localeOf(context).languageCode;
    final country =
        countryCode ?? Localizations.localeOf(context).countryCode ?? 'US';
    final packageName = userAgentPackageName ?? 'flutter_map_tile_switcher';

    // Check widget cache
    final cacheKey = '${mapType}_${darkMode}_${lang}_$country';
    if (MapTileLayerCache.has(cacheKey)) {
      return MapTileLayerCache.get(cacheKey) as Widget;
    }

    final widget =
        _buildFutureLayer(darkMode, lang, country, packageName, cacheKey);
    MapTileLayerCache.set(cacheKey, widget);
    return widget;
  }

  Widget _buildFutureLayer(
    bool darkMode,
    String lang,
    String country,
    String packageName,
    String cacheKey,
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
            cacheStore: null,
          );
        }
        return _buildTileLayer(
          darkMode: darkMode,
          lang: lang,
          country: country,
          packageName: packageName,
          cacheStore: snapshot.data!,
        );
      },
    );
  }

  Widget _buildTileLayer({
    required bool darkMode,
    required String lang,
    required String country,
    required String packageName,
    required CacheStore? cacheStore,
  }) {
    TileLayer tileLayer;

    switch (mapType) {
      case MapTileType.osm:
        tileLayer = TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/{style}/{z}/{x}/{y}{scale}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          additionalOptions: {
            'style': darkMode ? 'dark_all' : 'light_all',
            'scale': '@2x',
          },
          userAgentPackageName: packageName,
          tileProvider: cacheStore != null
              ? CachedTileProvider(
                  store: cacheStore,
                  cachePolicy: CachePolicy.forceCache,
                )
              : null,
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
          tileProvider: cacheStore != null
              ? CachedTileProvider(
                  store: cacheStore,
                  cachePolicy: CachePolicy.forceCache,
                )
              : null,
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
          tileProvider: cacheStore != null
              ? CachedTileProvider(
                  store: cacheStore,
                  cachePolicy: CachePolicy.forceCache,
                )
              : null,
          keepBuffer: keepBuffer,
        );
        break;
    }

    return RepaintBoundary(child: tileLayer);
  }
}
