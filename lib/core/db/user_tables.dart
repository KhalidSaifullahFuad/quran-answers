import 'package:drift/drift.dart';

/// Schema of the writable per-device database.
///
/// Deliberately separate from the content database. Content ships as an asset
/// and is replaced wholesale on every app update; if bookmarks lived in that
/// same file, every content release would either destroy them or force a
/// migration that buys nothing. Questions are referenced by slug, which is
/// stable across content rebuilds, rather than by a row id that is not.
///
/// A slug here may point at a question that a later content update removed.
/// That is tolerated: lookups drop rows they cannot resolve rather than
/// treating them as corruption.
@DataClassName('Bookmark')
class Bookmarks extends Table {
  TextColumn get questionSlug => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// The folder it is filed in, or null for unfiled. Added in schema 2.
  IntColumn get folderId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {questionSlug};
}

/// A saved verse, keyed by `surah * 1000 + ayah` (see `ayahId`).
///
/// Unlike a question slug, a verse address never changes between content
/// releases, so the integer id is safe to keep here.
@DataClassName('AyahBookmark')
class AyahBookmarks extends Table {
  IntColumn get ayahId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get folderId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {ayahId};
}

/// A user-named folder. Each saved question or verse sits in at most one.
///
/// No foreign key from the bookmark tables: SQLite enforces them only with a
/// per-connection pragma, and deleting a folder unfiles its items explicitly
/// in the same transaction instead.
@DataClassName('Folder')
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// One row per question, updated in place — the interesting thing is the order
/// questions were last opened in, not an append-only log of every view.
@DataClassName('HistoryEntry')
class ReadingHistory extends Table {
  TextColumn get questionSlug => text()();
  DateTimeColumn get viewedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {questionSlug};
}
