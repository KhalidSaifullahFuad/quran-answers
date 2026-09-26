import 'package:drift/drift.dart';

import 'user_tables.dart';

part 'user_db.g.dart';

/// Bookmarks, folders and reading history. Created on the device, never
/// shipped.
@DriftDatabase(tables: [Bookmarks, AyahBookmarks, Folders, ReadingHistory])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  /// 1: question bookmarks and history. 2: verse bookmarks and folders.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(ayahBookmarks);
        await m.createTable(folders);
        await m.addColumn(bookmarks, bookmarks.folderId);
      }
    },
  );

  /// Saved questions with their folder, most recently added first.
  Stream<List<Bookmark>> watchBookmarks() {
    final query = select(bookmarks)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    return query.watch();
  }

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

  /// Saved verses with their folder, most recently added first.
  Stream<List<AyahBookmark>> watchAyahBookmarks() {
    final query = select(ayahBookmarks)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    return query.watch();
  }

  Stream<bool> watchIsAyahBookmarked(int ayahId) {
    final query = select(ayahBookmarks)..where((b) => b.ayahId.equals(ayahId));
    return query.watchSingleOrNull().map((row) => row != null);
  }

  /// Adds or removes the verse bookmark and reports the state it ended in.
  Future<bool> toggleAyahBookmark(int ayahId) => transaction(() async {
    final removed = await (delete(
      ayahBookmarks,
    )..where((b) => b.ayahId.equals(ayahId))).go();
    if (removed > 0) return false;
    await into(ayahBookmarks).insert(
      AyahBookmarksCompanion.insert(
        ayahId: Value(ayahId),
        createdAt: DateTime.now(),
      ),
    );
    return true;
  });

  /// Folders in the order they were made.
  Stream<List<Folder>> watchFolders() {
    final query = select(folders)
      ..orderBy([
        (f) => OrderingTerm.asc(f.createdAt),
        (f) => OrderingTerm.asc(f.id),
      ]);
    return query.watch();
  }

  Future<int> createFolder(String name) => into(
    folders,
  ).insert(FoldersCompanion.insert(name: name, createdAt: DateTime.now()));

  Future<void> renameFolder(int id, String name) => (update(
    folders,
  )..where((f) => f.id.equals(id))).write(FoldersCompanion(name: Value(name)));

  /// Deletes the folder; what was filed in it goes back to unfiled, never away.
  Future<void> deleteFolder(int id) => transaction(() async {
    const unfiled = Value<int?>(null);
    await (update(bookmarks)..where((b) => b.folderId.equals(id))).write(
      const BookmarksCompanion(folderId: unfiled),
    );
    await (update(ayahBookmarks)..where((b) => b.folderId.equals(id))).write(
      const AyahBookmarksCompanion(folderId: unfiled),
    );
    await (delete(folders)..where((f) => f.id.equals(id))).go();
  });

  /// Files a saved question in [folderId], or unfiles it when null.
  Future<void> moveBookmark(String slug, int? folderId) =>
      (update(bookmarks)..where((b) => b.questionSlug.equals(slug))).write(
        BookmarksCompanion(folderId: Value(folderId)),
      );

  /// Files a saved verse in [folderId], or unfiles it when null.
  Future<void> moveAyahBookmark(int ayahId, int? folderId) =>
      (update(ayahBookmarks)..where((b) => b.ayahId.equals(ayahId))).write(
        AyahBookmarksCompanion(folderId: Value(folderId)),
      );
}
