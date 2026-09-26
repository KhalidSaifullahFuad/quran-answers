import 'package:drift/drift.dart';

import '../text/normalize.dart';
import 'content_db.dart';
import 'content_queries.dart';

/// A verse address typed by the user, e.g. `54:15`.
typedef AyahRef = ({int surah, int ayah});

/// `54:15`, `৫৪:১৫`, `54 15`, `54.15`, and `৫৪ঃ১৫` — Bengali keyboards put the
/// visarga where a colon would be, and users type it as one.
final _refPattern = RegExp(r'^\s*(\d{1,3})\s*[:.\sঃ]\s*(\d{1,3})\s*$');

/// Parses a verse reference, or returns null when [input] is not one.
///
/// Only the shape and the surah range are checked here; whether the ayah
/// exists is left to the lookup, which knows each surah's length.
AyahRef? parseAyahRef(String input) {
  final m = _refPattern.firstMatch(foldDigits(input));
  if (m == null) return null;
  final surah = int.parse(m[1]!);
  final ayah = int.parse(m[2]!);
  if (surah < 1 || surah > 114 || ayah < 1) return null;
  return (surah: surah, ayah: ayah);
}

final _arabicLetter = RegExp(r'[ء-ي]');

/// The definite article, as the index stores it after normalization.
const _al = 'ال';

/// Turns free text into an FTS5 MATCH expression, or null if nothing is left.
///
/// Every word becomes a quoted prefix query, and the words are ANDed. Quoting
/// means no user input is ever read as FTS syntax. Prefix matching is required
/// for Bengali, where suffixes attach to the word (নিদর্শন must reach
/// নিদর্শনরূপে). An Arabic word typed without the article also tries the
/// article-prefixed form, since the index keeps `ال` attached: قمر finds القمر.
String? ftsMatchExpression(String input) {
  final words = normalizeForSearch(
    input,
  ).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return null;

  String prefix(String w) => '"${w.replaceAll('"', '""')}"*';

  return words
      .map((w) {
        if (!_arabicLetter.hasMatch(w) || w.startsWith(_al)) return prefix(w);
        return '(${prefix(w)} OR ${prefix('$_al$w')})';
      })
      .join(' ');
}

/// Everything the search screen shows for one query.
class SearchResults {
  const SearchResults({
    this.ref,
    this.refAyah,
    this.citingRef = const [],
    this.questions = const [],
    this.ayahs = const [],
    this.ayahTotal = 0,
    this.surahs = const {},
  });

  static const empty = SearchResults();

  /// Set when the query was a verse reference, whether or not it exists.
  final AyahRef? ref;

  /// The referenced verse, or null when the surah has no such ayah.
  final Ayah? refAyah;

  /// Questions that cite [refAyah].
  final List<Question> citingRef;

  /// Questions matching the text, best first.
  final List<Question> questions;

  /// Verses matching the text, best first, at most the search limit.
  final List<Ayah> ayahs;

  /// How many verses matched in all, which can exceed [ayahs].
  final int ayahTotal;

  /// Surah rows for every verse above, keyed by number.
  final Map<int, Surah> surahs;

  bool get isEmpty => refAyah == null && questions.isEmpty && ayahs.isEmpty;
}

/// Full-text and reference search over the content database.
extension ContentSearch on ContentDatabase {
  /// A reference goes straight to the verse; anything else goes to FTS.
  Future<SearchResults> search(String input, {int ayahLimit = 50}) async {
    final ref = parseAyahRef(input);
    if (ref != null) {
      final ayah = await ayahAt(ref.surah, ref.ayah);
      if (ayah == null) return SearchResults(ref: ref);
      final (citing, surah) = await (
        questionsCiting(ref.surah, ref.ayah),
        this.surah(ref.surah),
      ).wait;
      return SearchResults(
        ref: ref,
        refAyah: ayah,
        citingRef: citing,
        surahs: {ref.surah: ?surah},
      );
    }

    final match = ftsMatchExpression(input);
    if (match == null) return SearchResults.empty;

    final (questions, ayahs, total) = await (
      searchQuestions(match),
      searchAyahs(match, limit: ayahLimit),
      countAyahs(match),
    ).wait;
    final numbers = {for (final a in ayahs) a.surah}.toList();
    final surahRows = numbers.isEmpty
        ? const <Surah>[]
        : await (select(surahs)..where((s) => s.number.isIn(numbers))).get();
    return SearchResults(
      questions: questions,
      ayahs: ayahs,
      ayahTotal: total,
      surahs: {for (final s in surahRows) s.number: s},
    );
  }

  /// Questions for a MATCH expression from [ftsMatchExpression], best first.
  Future<List<Question>> searchQuestions(String match) async {
    final rows = await customSelect(
      'SELECT slug FROM ${Fts.questions} '
      'WHERE ${Fts.questions} MATCH ? ORDER BY rank',
      variables: [Variable(match)],
    ).get();
    return questionsBySlugs([for (final r in rows) r.read<String>('slug')]);
  }

  /// Verses for a MATCH expression, best first.
  ///
  /// The ayah index is contentless, so it yields rowids, which are ayah ids.
  Future<List<Ayah>> searchAyahs(String match, {int limit = 50}) async {
    final rows = await customSelect(
      'SELECT rowid AS id FROM ${Fts.ayahs} '
      'WHERE ${Fts.ayahs} MATCH ? ORDER BY rank LIMIT ?',
      variables: [Variable(match), Variable(limit)],
    ).get();
    final ids = [for (final r in rows) r.read<int>('id')];
    if (ids.isEmpty) return const [];
    final found = await (select(ayahs)..where((a) => a.id.isIn(ids))).get();
    final byId = {for (final a in found) a.id: a};
    return [for (final id in ids) ?byId[id]];
  }

  Future<int> countAyahs(String match) async {
    final row = await customSelect(
      'SELECT count(*) AS n FROM ${Fts.ayahs} WHERE ${Fts.ayahs} MATCH ?',
      variables: [Variable(match)],
    ).getSingle();
    return row.read<int>('n');
  }
}
