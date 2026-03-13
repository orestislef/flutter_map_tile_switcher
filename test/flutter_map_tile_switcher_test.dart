import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';

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
  });
}
