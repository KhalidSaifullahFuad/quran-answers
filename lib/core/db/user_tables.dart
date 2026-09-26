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

  @override
  Set<Column> get primaryKey => {questionSlug};
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
