# flutter_map_tile_switcher

A [flutter_map](https://pub.dev/packages/flutter_map) plugin that makes it dead simple to switch between map tile providers with **built-in caching** and **automatic dark mode** support.

## Heads up: OSM tiles now want a CARTO API key

Since late August 2026 CARTO requires an API key on `basemaps.cartocdn.com`. Nothing is blocked, tiles still load, but without a key they come back with an **"API KEY REQUIRED"** watermark baked into the image.

This is not a breaking change, `MapTileType.osm` keeps working exactly as before. It is a good-to-add though, and it takes about a minute:

1. Get a free key at [carto.com/basemaps/apikey](https://carto.com/basemaps/apikey). No CARTO account needed.
2. Pass it to the layer:

```dart
MapTileLayer(
  mapType: MapTileType.osm,
  apiKey: 'YOUR_CARTO_KEY',
)
```

Or set it once at app startup and forget about it:

```dart
void main() {
  MapTileLayer.defaultApiKey = const String.fromEnvironment('CARTO_API_KEY');
  runApp(const MyApp());
}
```

```bash
flutter run --dart-define=CARTO_API_KEY=your_key_here
```

Free tier is 5 million tile requests per calendar month. Google and Satellite tiles are unaffected and ignore `apiKey`.

If you already have watermarked tiles sitting in the disk cache, clear them once after adding the key:

```dart
await TileCacheManager.clearCache();
```

## Features

- **3 map providers out of the box**: OpenStreetMap (CartoDB), Google Maps, Satellite (ArcGIS)
- **Automatic dark mode**: Detects your app's theme and applies the appropriate tile style
  - OSM: Switches between CartoDB light/dark themes
  - Google Maps: Applies a color matrix filter for a proper dark appearance
  - Satellite: No change needed (it's satellite imagery)
- **Built-in caching**: Tiles are cached for 30 days by default (configurable). Disk on mobile and desktop, memory on web
- **Widget caching**: Previously built tile layers are cached in memory to avoid rebuilds
- **Locale-aware**: Google Maps tiles automatically use your app's locale for labels
- **Optional API key**: Drop in a CARTO key for clean, unwatermarked OSM tiles
- **Cross-platform**: Android, iOS, Web, macOS, Windows, Linux

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_map_tile_switcher: ^0.0.4
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

### API Key

`apiKey` is optional and only used by `MapTileType.osm`. Per-layer value wins, otherwise it falls back to `MapTileLayer.defaultApiKey`. An empty string counts as no key, so a missing `--dart-define` will not break anything, you just get the watermark back.

```dart
// Per layer
MapTileLayer(mapType: MapTileType.osm, apiKey: 'YOUR_CARTO_KEY')

// Global default, set once in main()
MapTileLayer.defaultApiKey = 'YOUR_CARTO_KEY';
```

Do not hardcode the key in source you push to a public repo. Use `--dart-define` or pull it from your remote config.

### Dark Mode

Dark mode is **automatic**, it reads your app's `ThemeData` brightness. You can also force it:

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

// true on web, false everywhere else
final inMemory = TileCacheManager.isInMemory;
```

Where tiles actually land depends on the platform:

| Platform | Store | Survives a restart |
|----------|-------|--------------------|
| Android, iOS, Windows, macOS, Linux | Disk, in a `MapTiles` folder under the temp directory | Yes |
| Web | Memory, 32 MB LRU for the lifetime of the tab | No |

There is no temp directory to write to in a browser, so web falls back to an
in-memory store. Panning back over ground you have already seen stays instant,
but a page reload starts cold. The browser's own HTTP cache still works on top
of that.

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
| `apiKey` | `String?` | `null` (falls back to `MapTileLayer.defaultApiKey`) | CARTO API key, removes the watermark on OSM tiles |
| `keepBuffer` | `int` | `5` | Tile buffer size around visible area |

## License

MIT License - see [LICENSE](LICENSE) for details.
