# flutter_map_tile_switcher

A [flutter_map](https://pub.dev/packages/flutter_map) plugin that makes it dead simple to switch between map tile providers with **built-in caching** and **automatic dark mode** support.

## Features

- **3 map providers out of the box**: OpenStreetMap (CartoDB), Google Maps, Satellite (ArcGIS)
- **Automatic dark mode**: Detects your app's theme and applies the appropriate tile style
  - OSM: Switches between CartoDB light/dark themes
  - Google Maps: Applies a color matrix filter for a proper dark appearance
  - Satellite: No change needed (it's satellite imagery!)
- **Built-in disk caching**: Tiles are cached for 30 days by default (configurable)
- **Widget caching**: Previously built tile layers are cached in memory to avoid rebuilds
- **Locale-aware**: Google Maps tiles automatically use your app's locale for labels
- **Cross-platform**: Works on Android, iOS, Web, macOS, Windows, Linux

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_map_tile_switcher: ^0.0.1
```

## Usage

### Basic Usage

Just drop `MapTileLayer` into your `FlutterMap` children:

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';
import 'package:latlong2/latlong.dart';

FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(37.9838, 23.7275),
    initialZoom: 13,
  ),
  children: [
    MapTileLayer(mapType: MapTileType.osm),
  ],
)
```

### Switching Map Types

Use the `MapTileType` enum to switch providers:

```dart
MapTileType.osm       // OpenStreetMap via CartoDB (light/dark themes)
MapTileType.google    // Google Maps road map
MapTileType.satellite // Satellite imagery via ArcGIS
```

Build a simple map type selector:

```dart
class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapTileType _currentType = MapTileType.osm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(37.9838, 23.7275),
          initialZoom: 13,
        ),
        children: [
          MapTileLayer(mapType: _currentType),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Cycle through map types
            final types = MapTileType.values;
            final nextIndex = (types.indexOf(_currentType) + 1) % types.length;
            _currentType = types[nextIndex];
          });
        },
        child: Icon(Icons.layers),
      ),
    );
  }
}
```

### Dark Mode

Dark mode is **automatic** — it reads your app's `ThemeData` brightness. You can also force it:

```dart
// Auto-detect from theme (default)
MapTileLayer(mapType: MapTileType.osm)

// Force dark mode
MapTileLayer(mapType: MapTileType.google, isDarkMode: true)

// Force light mode
MapTileLayer(mapType: MapTileType.google, isDarkMode: false)
```

### Custom Options

```dart
MapTileLayer(
  mapType: MapTileType.google,
  languageCode: 'el',          // Greek labels
  countryCode: 'GR',           // Greece region bias
  userAgentPackageName: 'com.example.myapp',
  keepBuffer: 8,               // More tile buffer (default 5)
)
```

### Cache Management

```dart
// Change cache duration (before building any MapTileLayer)
TileCacheManager.setCacheMaxAge(Duration(days: 7));

// Clear all cached tiles
await TileCacheManager.clearCache();

// Check current cache max age
final maxAge = TileCacheManager.cacheMaxAge;
```

### Persisting Map Type Selection

Use `MapTileType.fromId()` or `MapTileType.fromName()` to restore from storage:

```dart
// Save
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('mapType', currentType.id);

// Restore
final savedId = prefs.getInt('mapType') ?? MapTileType.google.id;
final mapType = MapTileType.fromId(savedId);
```

## All Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mapType` | `MapTileType` | **required** | Which tile provider to use |
| `isDarkMode` | `bool?` | `null` (auto) | Force dark/light mode, or auto-detect from theme |
| `languageCode` | `String?` | `null` (auto) | Language for map labels (Google Maps) |
| `countryCode` | `String?` | `null` (auto) | Country for region bias (Google Maps) |
| `userAgentPackageName` | `String?` | `'flutter_map_tile_switcher'` | User-Agent for tile requests |
| `keepBuffer` | `int` | `5` | Tile buffer size around visible area |

## License

MIT License - see [LICENSE](LICENSE) for details.
