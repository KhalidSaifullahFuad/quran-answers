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
}
