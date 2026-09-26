import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Gets the shipped content database onto the filesystem.
///
/// SQLite needs a real file, and on Android an asset lives inside the APK, so
/// the database is copied out on first launch. It is copied again whenever the
/// bundled fingerprint differs from the one recorded beside the existing copy,
/// which is how an app update delivers new content.
///
/// Reads of the bundle are injectable so this can be tested without a Flutter
/// asset bundle or a real app directory.
class ContentStore {
  ContentStore({
    required this.directory,
    Future<ByteData> Function(String key)? loadAsset,
    Future<String> Function(String key)? loadAssetString,
  }) : _loadAsset = loadAsset ?? rootBundle.load,
       _loadAssetString = loadAssetString ?? rootBundle.loadString;

  static const dbAsset = 'assets/db/content.db';
  static const versionAsset = 'assets/db/content.db.version';

  /// Where the usable copy lives. Not the cache directory: re-copying 10 MB
  /// because the system reclaimed the cache would be a poor trade.
  final Directory directory;

  final Future<ByteData> Function(String key) _loadAsset;
  final Future<String> Function(String key) _loadAssetString;

  File get databaseFile => File(p.join(directory.path, 'content.db'));

  File get _markerFile => File(p.join(directory.path, 'content.db.version'));

  /// Returns the database file, copying it out of the bundle if needed, and
  /// reports whether a copy happened.
  Future<({File file, bool copied})> ensureReady() async {
    final bundledMarker = await _loadAssetString(versionAsset);
    if (await _isUpToDate(bundledMarker)) {
      return (file: databaseFile, copied: false);
    }

    await directory.create(recursive: true);

    // Written under a temporary name and renamed into place, so an interrupted
    // copy leaves the previous database usable instead of a truncated file that
    // SQLite would reject on the next launch.
    final staging = File('${databaseFile.path}.tmp');
    final bytes = await _loadAsset(dbAsset);
    await staging.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    if (await databaseFile.exists()) await databaseFile.delete();
    await staging.rename(databaseFile.path);

    // The marker is written last. If anything above failed, the stale or missing
    // marker makes the next launch try the copy again.
    await _markerFile.writeAsString(bundledMarker, flush: true);

    return (file: databaseFile, copied: true);
  }

  Future<bool> _isUpToDate(String bundledMarker) async {
    if (!await databaseFile.exists()) return false;
    if (!await _markerFile.exists()) return false;
    final existing = await _markerFile.readAsString();
    return existing.trim() == bundledMarker.trim();
  }
}
