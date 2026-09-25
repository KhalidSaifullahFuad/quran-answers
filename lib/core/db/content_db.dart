import 'package:drift/drift.dart';

import 'content_tables.dart';

part 'content_db.g.dart';

/// Stable row id for a verse: `surah * 1000 + ayah`.
///
/// Used by the build tool and by every lookup, so the arithmetic lives in one
/// place. The longest surah has 286 ayat, well inside the multiplier.
int ayahId(int surah, int ayah) => surah * 1000 + ayah;

int surahOfAyahId(int id) => id ~/ 1000;

int ayahOfAyahId(int id) => id % 1000;

/// Names of the FTS5 tables that sit beside the Drift-managed tables.
///
/// Drift has no typed representation for a virtual table, so these are created
/// with raw statements at build time and queried with raw statements at
/// runtime. Keeping the names in one place stops the two ends disagreeing.
abstract final class Fts {
  static const ayahs = 'ayahs_fts';
  static const questions = 'questions_fts';
}

/// Bengali combining marks, declared to the tokenizer as token characters.
///
/// `unicode61` only treats letters and numbers as part of a token, so Bengali
/// vowel signs and hasanta would otherwise act as separators and shred every
/// word into consonant fragments — কোন would index as ক and ন. Listing them
/// here keeps Bengali words whole.
const _bengaliMarks =
    '\u0981\u0982\u0983' // candrabindu, anusvara, visarga
    '\u09BC' // nukta
    '\u09BE\u09BF\u09C0\u09C1\u09C2\u09C3\u09C4' // aa..vocalic rr
    '\u09C7\u09C8\u09CB\u09CC' // e, ai, o, au
    '\u09CD' // hasanta (conjuncts)
    '\u09D7' // au length mark
    '\u09E2\u09E3'; // vocalic l, ll

/// `remove_diacritics 0` is deliberate: normalize.dart already decides what a
/// diacritic means for each script. Letting SQLite strip marks as well would
/// silently erase Bengali vowel signs, merging distinct words.
const _tokenizer = "unicode61 remove_diacritics 0 tokenchars '$_bengaliMarks'";

/// The statements that create the FTS index.
///
/// Ayat use a contentless index keyed by rowid, because [ayahId] is already a
/// stable integer, so the index costs nothing beyond the terms themselves.
/// Questions store their slug as an UNINDEXED column instead: a contentless
/// table can only return rowids, questions are keyed by slug rather than by an
/// integer, and there are only hundreds of them, so the duplication is
/// negligible and it avoids inventing a second id purely for FTS plumbing.
const createFtsStatements = <String>[
  '''
  CREATE VIRTUAL TABLE ${Fts.ayahs} USING fts5(
    search_ar,
    search_bn,
    content='',
    tokenize="$_tokenizer"
  )
  ''',
  '''
  CREATE VIRTUAL TABLE ${Fts.questions} USING fts5(
    slug UNINDEXED,
    search_bn,
    tokenize="$_tokenizer"
  )
  ''',
];

@DriftDatabase(
  tables: [Surahs, Ayahs, Categories, Questions, QuestionAyahs, Meta],
)
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase(super.e);

  /// Bumped only when the table structure changes, never when content changes.
  ///
  /// The shipped file already carries this in `user_version`, so Drift opens it
  /// without running onCreate. A content update replaces the whole file and
  /// leaves this number alone.
  @override
  int get schemaVersion => 1;
}
