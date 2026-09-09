import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';

const _keylessOsmUrl =
    'https://{s}.basemaps.cartocdn.com/{style}/{z}/{x}/{y}{scale}.png';

void main() {
  group('MapTileType', () {
    test('fromId returns correct type', () {
      expect(MapTileType.fromId(0), MapTileType.osm);
      expect(MapTileType.fromId(1), MapTileType.google);
      expect(MapTileType.fromId(-1), MapTileType.satellite);
    });

    test('fromId returns google for unknown id', () {
      expect(MapTileType.fromId(99), MapTileType.google);
    });

    test('fromName returns correct type', () {
      expect(MapTileType.fromName('osm'), MapTileType.osm);
      expect(MapTileType.fromName('google'), MapTileType.google);
      expect(MapTileType.fromName('satellite'), MapTileType.satellite);
    });

    test('fromName returns google for unknown name', () {
      expect(MapTileType.fromName('unknown'), MapTileType.google);
    });

    test('id values are correct', () {
      expect(MapTileType.osm.id, 0);
      expect(MapTileType.google.id, 1);
      expect(MapTileType.satellite.id, -1);
    });
  });

  group('TileCacheManager', () {
    test('default cache max age is 30 days', () {
      expect(
        TileCacheManager.defaultCacheMaxAge,
        const Duration(days: 30),
      );
    });

    test('setCacheMaxAge updates cache duration', () {
      final original = TileCacheManager.cacheMaxAge;
      TileCacheManager.setCacheMaxAge(const Duration(days: 7));
      expect(TileCacheManager.cacheMaxAge, const Duration(days: 7));
      // Reset
      TileCacheManager.setCacheMaxAge(original);
    });

    test('uses the disk store off the web', () {
      // These tests run on the VM, so the io branch of the conditional
      // import is the one that got compiled in.
      expect(TileCacheManager.isInMemory, isFalse);
    });
  });

  group('MapTileLayer.resolveApiKey', () {
    tearDown(() => MapTileLayer.defaultApiKey = null);

    test('returns null when nothing is set', () {
      expect(MapTileLayer.resolveApiKey(null), isNull);
    });

    test('returns the key that was passed in', () {
      expect(MapTileLayer.resolveApiKey('abc123'), 'abc123');
    });

    test('treats an empty key as no key', () {
      expect(MapTileLayer.resolveApiKey(''), isNull);
    });

    test('falls back to defaultApiKey', () {
      MapTileLayer.defaultApiKey = 'global123';
      expect(MapTileLayer.resolveApiKey(null), 'global123');
    });

    test('per layer key wins over defaultApiKey', () {
      MapTileLayer.defaultApiKey = 'global123';
      expect(MapTileLayer.resolveApiKey('local456'), 'local456');
    });

    test('empty defaultApiKey is ignored', () {
      MapTileLayer.defaultApiKey = '';
      expect(MapTileLayer.resolveApiKey(null), isNull);
    });
  });

  group('MapTileLayer.osmTileUrl', () {
    test('without a key the url is unchanged', () {
      final (url, options) =
          MapTileLayer.osmTileUrl(darkMode: false, apiKey: null);
      expect(url, _keylessOsmUrl);
      expect(options.containsKey('apiKey'), isFalse);
      expect(options['style'], 'light_all');
      expect(options['scale'], '@2x');
    });

    test('with a key the url gets the key placeholder', () {
      final (url, options) =
          MapTileLayer.osmTileUrl(darkMode: false, apiKey: 'abc123');
      expect(url, '$_keylessOsmUrl?key={apiKey}');
      expect(options['apiKey'], 'abc123');
    });

    test('dark mode still picks the dark style', () {
      final (_, options) =
          MapTileLayer.osmTileUrl(darkMode: true, apiKey: 'abc123');
      expect(options['style'], 'dark_all');
    });

    test('every placeholder in the url has a value', () {
      final (url, options) =
          MapTileLayer.osmTileUrl(darkMode: false, apiKey: 'abc123');
      // {s}, {z}, {x}, {y} are filled in by flutter_map itself.
      const providedByFlutterMap = {'s', 'z', 'x', 'y'};
      final placeholders = RegExp(r'\{(\w+)\}')
          .allMatches(url)
          .map((m) => m.group(1)!)
          .where((p) => !providedByFlutterMap.contains(p));
      for (final p in placeholders) {
        expect(options.containsKey(p), isTrue, reason: 'missing value for {$p}');
      }
    });
  });
}
