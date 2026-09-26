import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/db/user_db.dart';

/// Bookmarks and history, against an in-memory database.
void main() {
  late UserDatabase db;

  setUp(() => db = UserDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('bookmarks', () {
    test(
      'toggling adds, then removes, and reports the resulting state',
      () async {
        expect(await db.toggleBookmark('naba-azeem'), isTrue);
        expect(await db.bookmarkedSlugs(), ['naba-azeem']);

        expect(await db.toggleBookmark('naba-azeem'), isFalse);
        expect(await db.bookmarkedSlugs(), isEmpty);
      },
    );

    test('most recently bookmarked comes first', () async {
      await db.toggleBookmark('first');
      // Timestamps come from DateTime.now(), so without a gap the ordering of
      // two inserts in the same millisecond is not defined.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.toggleBookmark('second');

      expect(await db.bookmarkedSlugs(), ['second', 'first']);
    });

    test('watchIsBookmarked reflects a later toggle', () async {
      final states = <bool>[];
      final sub = db.watchIsBookmarked('naba-azeem').listen(states.add);

      await pumpEventQueue();
      await db.toggleBookmark('naba-azeem');
      await pumpEventQueue();
      await db.toggleBookmark('naba-azeem');
      await pumpEventQueue();

      expect(states, [false, true, false]);
      await sub.cancel();
    });

    test('bookmarking twice does not create a duplicate row', () async {
      await db.toggleBookmark('naba-azeem');
      await db.toggleBookmark('naba-azeem');
      await db.toggleBookmark('naba-azeem');
      expect(await db.bookmarkedSlugs(), ['naba-azeem']);
    });
  });

  group('reading history', () {
    test('records a view', () async {
      await db.recordView('naba-azeem');
      expect(await db.recentSlugs(), ['naba-azeem']);
    });

    test(
      're-opening a question moves it to the front without duplicating it',
      () async {
        await db.recordView('first');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await db.recordView('second');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await db.recordView('first');

        // One row per question: the interesting thing is the order questions were
        // last opened in, not every visit ever made.
        expect(await db.recentSlugs(), ['first', 'second']);
      },
    );

    test('honours the limit', () async {
      for (var i = 0; i < 5; i++) {
        await db.recordView('q$i');
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
      expect(await db.recentSlugs(limit: 2), ['q4', 'q3']);
    });

    test('clearing removes everything but leaves bookmarks alone', () async {
      await db.recordView('naba-azeem');
      await db.toggleBookmark('naba-azeem');

      await db.clearHistory();

      expect(await db.recentSlugs(), isEmpty);
      expect(await db.bookmarkedSlugs(), ['naba-azeem']);
    });
  });

  group('verse bookmarks', () {
    test('toggling adds, then removes, newest first', () async {
      expect(await db.toggleAyahBookmark(54015), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(await db.toggleAyahBookmark(78002), isTrue);
      expect((await db.watchAyahBookmarks().first).map((b) => b.ayahId), [
        78002,
        54015,
      ]);

      expect(await db.toggleAyahBookmark(54015), isFalse);
      expect((await db.watchAyahBookmarks().first).map((b) => b.ayahId), [
        78002,
      ]);
    });

    test('watchIsAyahBookmarked follows toggles', () async {
      final states = <bool>[];
      final sub = db.watchIsAyahBookmarked(54015).listen(states.add);
      await pumpEventQueue();
      await db.toggleAyahBookmark(54015);
      await pumpEventQueue();
      expect(states, [false, true]);
      await sub.cancel();
    });
  });

  group('folders', () {
    test('items are filed, moved and unfiled', () async {
      final a = await db.createFolder('A');
      final b = await db.createFolder('B');
      await db.toggleBookmark('naba-azeem');
      await db.toggleAyahBookmark(54015);

      await db.moveBookmark('naba-azeem', a);
      await db.moveAyahBookmark(54015, b);
      expect((await db.watchBookmarks().first).single.folderId, a);
      expect((await db.watchAyahBookmarks().first).single.folderId, b);

      await db.moveBookmark('naba-azeem', null);
      expect((await db.watchBookmarks().first).single.folderId, isNull);
    });

    test('renaming keeps the order folders were made in', () async {
      final a = await db.createFolder('A');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.createFolder('B');
      await db.renameFolder(a, 'Z');
      expect((await db.watchFolders().first).map((f) => f.name), ['Z', 'B']);
    });

    test(
      'deleting a folder unfiles its items instead of losing them',
      () async {
        final a = await db.createFolder('A');
        await db.toggleBookmark('naba-azeem');
        await db.toggleAyahBookmark(54015);
        await db.moveBookmark('naba-azeem', a);
        await db.moveAyahBookmark(54015, a);

        await db.deleteFolder(a);

        expect(await db.watchFolders().first, isEmpty);
        expect((await db.watchBookmarks().first).single.folderId, isNull);
        expect((await db.watchAyahBookmarks().first).single.folderId, isNull);
      },
    );
  });

  test(
    'a schema 1 file upgrades and keeps its bookmarks and history',
    () async {
      // A second database beside setUp's, on its own executor: drift's warning
      // about duplicate instances does not apply.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );
      // The exact tables schema 1 created, as already on the author's device.
      final old = UserDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE bookmarks (question_slug TEXT NOT NULL, '
              'created_at TEXT NOT NULL, PRIMARY KEY (question_slug))',
            );
            raw.execute(
              'CREATE TABLE reading_history (question_slug TEXT NOT NULL, '
              'viewed_at TEXT NOT NULL, PRIMARY KEY (question_slug))',
            );
            raw.execute(
              "INSERT INTO bookmarks VALUES ('naba-azeem', "
              "'2026-09-20T10:00:00.000')",
            );
            raw.execute(
              "INSERT INTO reading_history VALUES ('naba-azeem', "
              "'2026-09-20T10:00:00.000')",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(old.close);

      expect(await old.bookmarkedSlugs(), ['naba-azeem']);
      expect(await old.recentSlugs(), ['naba-azeem']);
      final folder = await old.createFolder('A');
      await old.moveBookmark('naba-azeem', folder);
      expect((await old.watchBookmarks().first).single.folderId, folder);
      expect(await old.toggleAyahBookmark(54015), isTrue);
      final version = await old.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 2);
    },
  );
}
