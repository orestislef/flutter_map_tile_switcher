/// Enum representing the available map tile providers.
///
/// Each type maps to a different tile server:
/// - [osm]: OpenStreetMap via CartoDB (supports light/dark themes)
/// - [google]: Google Maps road map
/// - [satellite]: Satellite imagery via ArcGIS
enum MapTileType {
  /// OpenStreetMap tiles served via CartoDB.
  /// Supports automatic light/dark theme switching.
  osm(0),

  /// Google Maps road map tiles.
  /// Supports dark mode via color matrix inversion.
  google(1),

  /// Satellite imagery tiles via ArcGIS World Imagery.
  /// No theme variations (satellite is satellite).
  satellite(-1);

  /// Numeric identifier for persistence/serialization.
  final int id;

  const MapTileType(this.id);

  /// Create a [MapTileType] from its numeric [id].
  /// Returns [google] if no match is found.
  static MapTileType fromId(int id) {
    return MapTileType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => google,
    );
  }

  /// Create a [MapTileType] from its [name] string.
  /// Returns [google] if no match is found.
  static MapTileType fromName(String name) {
    return MapTileType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => google,
    );
  }
}
