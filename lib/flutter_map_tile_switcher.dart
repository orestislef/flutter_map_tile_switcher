/// A flutter_map plugin for easy switching between map tile providers
/// with built-in caching and automatic dark mode support.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';
///
/// FlutterMap(
///   options: MapOptions(initialCenter: LatLng(37.9838, 23.7275), initialZoom: 13),
///   children: [
///     MapTileLayer(mapType: MapTileType.osm),
///   ],
/// )
/// ```
///
/// ## Features
/// - 3 built-in map providers: OpenStreetMap, Google Maps, Satellite
/// - Automatic dark mode detection and tile theming
/// - Built-in disk caching (default 30 days)
/// - Locale-aware map labels
library;

export 'src/map_tile_type.dart';
export 'src/map_tile_layer.dart';
export 'src/tile_cache_manager.dart';
