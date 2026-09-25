import 'package:drift/drift.dart';

/// Schema of the read-only content database shipped as an asset.
///
/// Defined once here and used by both `tool/build_db.dart`, which creates and
/// fills the file, and the app, which reads it. A second hand-written copy of
/// this schema in the build tool would be free to drift out of sync.
///
/// Nothing in this database is user data. Bookmarks and history live in a
/// separate file (see user_tables.dart) so that replacing the content on every
/// app update cannot touch them.
@DataClassName('Surah')
class Surahs extends Table {
  IntColumn get number => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameBn => text()();
  TextColumn get nameEn => text()();
  IntColumn get ayahCount => integer()();
  TextColumn get revelationPlace => text()();

  @override
  Set<Column> get primaryKey => {number};
}

@DataClassName('Ayah')
class Ayahs extends Table {
  /// `surah * 1000 + ayah`. Deterministic rather than autoincrement, so the id
  /// of a verse is the same in every rebuild of the database and is readable in
  /// a query. The longest surah has 286 ayat, well inside the multiplier.
  IntColumn get id => integer()();
  IntColumn get surah => integer().references(Surahs, #number)();
  IntColumn get ayah => integer()();

  /// Uthmani script, as fetched. Displayed text — never normalized in place.
  TextColumn get textUthmani => text()();

  /// Imlaei (simple) script, kept as a fallback for renderers that handle
  /// Uthmani diacritics badly.
  TextColumn get textPlain => text()();
  TextColumn get translationBn => text()();

  /// Normalized copies used only for the FTS index. See core/text/normalize.dart.
  TextColumn get searchAr => text()();
  TextColumn get searchBn => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Category')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get nameBn => text()();
  TextColumn get nameEn => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Question')
class Questions extends Table {
  /// A human-authored slug, not an integer.
  ///
  /// Bookmarks and reading history in the user database reference questions by
  /// this value. Integer ids would be reassigned whenever the content database
  /// is regenerated, silently repointing every saved bookmark at a different
  /// question; a slug is stable across rebuilds.
  TextColumn get slug => text()();
  TextColumn get questionBn => text()();
  TextColumn get answerBn => text()();
  TextColumn get category => text().references(Categories, #id)();
  TextColumn get searchBn => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {slug};
}

/// Which ayat a question cites, in the order they should be shown.
///
/// Ayah text is never copied into the question row; a question points at the
/// mushaf so there is exactly one copy of every verse.
@DataClassName('QuestionAyah')
class QuestionAyahs extends Table {
  TextColumn get questionSlug => text().references(Questions, #slug)();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {questionSlug, ayahId};
}

/// Content version, generation timestamp, translation credit.
@DataClassName('MetaEntry')
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
