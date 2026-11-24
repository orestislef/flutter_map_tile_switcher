import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');

/// What the layer built: the flutter_map [TileLayer] and whether the dark
/// colour filter sits above it.
typedef _Built = ({TileLayer layer, bool darkFilter});

/// Builds [layer] in a material_ui [MaterialApp] with [theme], with nothing
/// from `package:flutter/material.dart` anywhere in the tree, and reports
/// what it built.
Future<_Built> _build(
  WidgetTester tester,
  ThemeData theme,
  MapTileLayer layer,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(37.9838, 23.7275),
          initialZoom: 13,
        ),
        children: [layer],
      ),
    ),
  );
  // Let the tile store future settle so the TileLayer is built.
  await tester.pump();
  await tester.pump();

  // Every widget called Theme in the tree is material_ui's, so the only
  // brightness the layer could have read is the one of this ThemeData.
  final themes = tester.allWidgets
      .where((w) => w.runtimeType.toString() == 'Theme')
      .toList();
  expect(themes, isNotEmpty);
  expect(themes.every((w) => w is Theme), isTrue);

  final built = (
    layer: tester.widget<TileLayer>(find.byType(TileLayer)),
    darkFilter: find
        .ancestor(
          of: find.byType(TileLayer),
          matching: find.byType(ColorFiltered),
        )
        .evaluate()
        .isNotEmpty,
  );

  // The tiles started loading. Take the map down and let their timers run
  // out so the test ends clean.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  return built;
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // path_provider has no platform side in tests. Hand it a temp folder so
    // the tile store comes up the way it does in an app.
    tempDir = Directory.systemTemp.createTempSync('tile_switcher_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, (call) async => tempDir.path);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, null);
    tempDir.deleteSync(recursive: true);
  });

  setUp(MapTileLayerCache.clear);

  final dark = ThemeData(brightness: Brightness.dark);
  final light = ThemeData(brightness: Brightness.light);

  group('dark mode from the material_ui Theme', () {
    testWidgets('a dark ThemeData gets the dark OSM tiles', (tester) async {
      final built = await _build(
        tester,
        dark,
        const MapTileLayer(mapType: MapTileType.osm),
      );
      expect(built.layer.additionalOptions['style'], 'dark_all');
    });

    testWidgets('a light ThemeData gets the light OSM tiles', (tester) async {
      final built = await _build(
        tester,
        light,
        const MapTileLayer(mapType: MapTileType.osm),
      );
      expect(built.layer.additionalOptions['style'], 'light_all');
    });

    testWidgets('a dark ThemeData puts the dark filter on Google tiles', (
      tester,
    ) async {
      final built = await _build(
        tester,
        dark,
        const MapTileLayer(mapType: MapTileType.google),
      );
      expect(built.darkFilter, isTrue);
    });

    testWidgets('a light ThemeData leaves Google tiles as they are', (
      tester,
    ) async {
      final built = await _build(
        tester,
        light,
        const MapTileLayer(mapType: MapTileType.google),
      );
      expect(built.darkFilter, isFalse);
    });

    testWidgets('isDarkMode still wins over the theme', (tester) async {
      final built = await _build(
        tester,
        dark,
        const MapTileLayer(mapType: MapTileType.osm, isDarkMode: false),
      );
      expect(built.layer.additionalOptions['style'], 'light_all');
    });
  });
}
