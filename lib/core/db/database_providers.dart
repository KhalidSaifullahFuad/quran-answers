import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'content_db.dart';
import 'content_store.dart';
import 'user_db.dart';

/// Application support, not the cache or documents directory: the databases are
/// app-managed state that must survive cache eviction and should stay out of any
/// user-visible file listing.
final appDirectoryProvider = FutureProvider<Directory>((ref) async {
  return getApplicationSupportDirectory();
});

/// Copies the shipped content database out of the bundle if needed.
final contentStoreProvider = FutureProvider<ContentStore>((ref) async {
  final directory = await ref.watch(appDirectoryProvider.future);
  return ContentStore(directory: directory);
});

/// How a database file is opened.
///
/// In the app this hands work to a background isolate: every screen reads
/// through the content database, FTS queries run over 6,236 ayat, and doing that
/// on the UI isolate would show up as dropped frames while typing in the search
/// field.
///
/// It is a provider so tests can substitute a direct connection. A widget test
/// drives a fake clock and never lets the isolate's messages through, so a test
/// against the background opener simply hangs.
final databaseOpenerProvider = Provider<QueryExecutor Function(File)>(
  (ref) => NativeDatabase.createInBackground,
);

/// The read-only content database: mushaf plus the published Q&A set.
final contentDatabaseProvider = FutureProvider<ContentDatabase>((ref) async {
  final store = await ref.watch(contentStoreProvider.future);
  final result = await store.ensureReady();
  if (result.copied) {
    debugPrint('Content database copied to ${result.file.path}');
  }

  final db = ContentDatabase(ref.watch(databaseOpenerProvider)(result.file));
  ref.onDispose(db.close);
  return db;
});

/// Bookmarks and reading history. Created on the device, never shipped.
final userDatabaseProvider = FutureProvider<UserDatabase>((ref) async {
  final directory = await ref.watch(appDirectoryProvider.future);
  final file = File(p.join(directory.path, 'user.db'));
  final db = UserDatabase(ref.watch(databaseOpenerProvider)(file));
  ref.onDispose(db.close);
  return db;
});

/// Build-time metadata: content version, translation credit, counts.
/// Used by the about screen and for the translator attribution.
final contentMetadataProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  final rows = await db.select(db.meta).get();
  return {for (final r in rows) r.key: r.value};
});
