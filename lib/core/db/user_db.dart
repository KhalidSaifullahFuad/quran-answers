import 'package:drift/drift.dart';

import 'user_tables.dart';

part 'user_db.g.dart';

/// Bookmarks and reading history. Created on the device, never shipped.
@DriftDatabase(tables: [Bookmarks, ReadingHistory])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Stream<Set<String>> watchBookmarkedSlugs() {
    final query = select(bookmarks)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    return query.watch().map((rows) => {for (final r in rows) r.questionSlug});
  }

  /// Bookmarked slugs, most recently added first.
  Future<List<String>> bookmarkedSlugs() async {
    final query = select(bookmarks)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    final rows = await query.get();
    return [for (final r in rows) r.questionSlug];
  }

  Stream<bool> watchIsBookmarked(String slug) {
    final query = select(bookmarks)..where((b) => b.questionSlug.equals(slug));
    return query.watchSingleOrNull().map((row) => row != null);
  }

  /// Adds or removes the bookmark and reports the state it ended in.
  Future<bool> toggleBookmark(String slug) async {
    final existing = await (select(
      bookmarks,
    )..where((b) => b.questionSlug.equals(slug))).getSingleOrNull();
    if (existing != null) {
      await (delete(bookmarks)..where((b) => b.questionSlug.equals(slug))).go();
      return false;
    }
    await into(
      bookmarks,
    ).insert(Bookmark(questionSlug: slug, createdAt: DateTime.now()));
    return true;
  }

  /// Records that a question was opened, replacing any earlier visit.
  Future<void> recordView(String slug) =>
      into(readingHistory).insertOnConflictUpdate(
        HistoryEntry(questionSlug: slug, viewedAt: DateTime.now()),
      );

  /// Most recently viewed slugs first.
  Future<List<String>> recentSlugs({int limit = 20}) async {
    final query = select(readingHistory)
      ..orderBy([(h) => OrderingTerm.desc(h.viewedAt)])
      ..limit(limit);
    final rows = await query.get();
    return [for (final r in rows) r.questionSlug];
  }

  Stream<List<String>> watchRecentSlugs({int limit = 20}) {
    final query = select(readingHistory)
      ..orderBy([(h) => OrderingTerm.desc(h.viewedAt)])
      ..limit(limit);
    return query.watch().map((rows) => [for (final r in rows) r.questionSlug]);
  }

  Future<void> clearHistory() => delete(readingHistory).go();
}
