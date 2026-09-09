import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

/// Tiles go to disk on every platform that has one.
const bool tileStoreIsInMemory = false;

/// Creates the disk backed tile store used on Android, iOS, Windows, macOS
/// and Linux. Tiles land in a `MapTiles` folder inside the temp directory.
Future<CacheStore> createTileStore() async {
  final dir = await getTemporaryDirectory();
  return FileCacheStore('${dir.path}${Platform.pathSeparator}MapTiles');
}
