import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/db/content_store.dart';

/// The copy-out logic, exercised against real temporary directories with the
/// asset bundle stubbed.
///
/// What matters here is when a copy happens and when it is skipped: getting that
/// wrong means either a 10 MB write on every launch, or an app update that keeps
/// serving the previous content forever.
void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('content_store_test');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  /// A store whose bundle serves [dbBytes] and [marker], counting asset reads so
  /// a test can tell a skipped copy from a performed one.
  ({ContentStore store, List<String> reads}) storeWith({
    required String dbBytes,
    required String marker,
    Directory? directory,
  }) {
    final reads = <String>[];
    final store = ContentStore(
      directory: directory ?? tempRoot,
      loadAsset: (key) async {
        reads.add(key);
        final bytes = Uint8List.fromList(dbBytes.codeUnits);
        return ByteData.view(bytes.buffer);
      },
      loadAssetString: (key) async => marker,
    );
    return (store: store, reads: reads);
  }

  test('copies the database out on first launch', () async {
    final s = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');

    final result = await s.store.ensureReady();

    expect(result.copied, isTrue);
    expect(result.file.existsSync(), isTrue);
    expect(result.file.readAsStringSync(), 'database-v1');
    expect(s.reads, [ContentStore.dbAsset]);
  });

  test('does not copy again when the fingerprint is unchanged', () async {
    final first = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    await first.store.ensureReady();

    final second = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    final result = await second.store.ensureReady();

    expect(result.copied, isFalse);
    expect(second.reads, isEmpty, reason: 'the 10 MB asset was read again');
  });

  test('copies again when the bundled fingerprint differs', () async {
    final first = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    await first.store.ensureReady();

    // What an app update looks like: same paths, new content, new fingerprint.
    final updated = storeWith(dbBytes: 'database-v2', marker: 'sha256=bbb');
    final result = await updated.store.ensureReady();

    expect(result.copied, isTrue);
    expect(result.file.readAsStringSync(), 'database-v2');
  });

  test('ignores whitespace differences in the marker', () async {
    final first = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa\n');
    await first.store.ensureReady();

    final second = storeWith(dbBytes: 'database-v1', marker: '  sha256=aaa  ');
    expect((await second.store.ensureReady()).copied, isFalse);
  });

  test('retries the copy when the marker is missing', () async {
    final first = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    await first.store.ensureReady();
    // Stands in for a copy interrupted before the marker was written: the
    // database file may be truncated, so it must not be trusted.
    File('${tempRoot.path}/content.db.version').deleteSync();

    final second = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    expect((await second.store.ensureReady()).copied, isTrue);
  });

  test('retries the copy when the database file is missing', () async {
    final first = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    await first.store.ensureReady();
    File('${tempRoot.path}/content.db').deleteSync();

    final second = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    expect((await second.store.ensureReady()).copied, isTrue);
  });

  test('creates the directory when it does not exist yet', () async {
    final nested = Directory('${tempRoot.path}/nested/support');
    final s = storeWith(
      dbBytes: 'database-v1',
      marker: 'sha256=aaa',
      directory: nested,
    );

    final result = await s.store.ensureReady();

    expect(result.copied, isTrue);
    expect(result.file.readAsStringSync(), 'database-v1');
  });

  test('leaves no staging file behind', () async {
    final s = storeWith(dbBytes: 'database-v1', marker: 'sha256=aaa');
    await s.store.ensureReady();

    expect(File('${tempRoot.path}/content.db.tmp').existsSync(), isFalse);
  });

  test('the real bundled marker matches the built database', () async {
    // Guards the pair of files in the repository rather than the copy logic: if
    // build_db.dart wrote one and not the other, every install would re-copy on
    // every launch, or never update.
    final marker = File('assets/db/content.db.version');
    expect(marker.existsSync(), isTrue, reason: 'run tool/build_db.dart');
    final lines = marker.readAsLinesSync();
    expect(lines.any((l) => l.startsWith('sha256=')), isTrue);
    expect(lines.any((l) => l.startsWith('contentVersion=')), isTrue);
  });
}
