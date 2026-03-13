import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_switcher/flutter_map_tile_switcher.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Switcher Example',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapTileType _currentType = MapTileType.osm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Switcher Example'),
        actions: [
          // Map type selector
          PopupMenuButton<MapTileType>(
            icon: const Icon(Icons.layers),
            onSelected: (type) => setState(() => _currentType = type),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MapTileType.osm,
                child: Text('OpenStreetMap'),
              ),
              const PopupMenuItem(
                value: MapTileType.google,
                child: Text('Google Maps'),
              ),
              const PopupMenuItem(
                value: MapTileType.satellite,
                child: Text('Satellite'),
              ),
            ],
          ),
          // Clear cache button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear tile cache',
            onPressed: () async {
              await TileCacheManager.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tile cache cleared')),
                );
              }
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(37.9838, 23.7275), // Athens, Greece
          initialZoom: 13,
        ),
        children: [
          MapTileLayer(mapType: _currentType),
        ],
      ),
    );
  }
}
