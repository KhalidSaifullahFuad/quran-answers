import 'package:drift/drift.dart';

import '../text/normalize.dart';
import '../text/synonyms.dart';
import 'content_db.dart';
import 'content_queries.dart';

/// A verse address typed by the user, e.g. `54:15`.
typedef AyahRef = ({int surah, int ayah});

/// `54:15`, `৫৪:১৫`, `54 15`, `54.15`, and `৫৪ঃ১৫` — Bengali keyboards put the
/// visarga where a colon would be, and users type it as one.
final _refPattern = RegExp(r'^\s*(\d{1,3})\s*[:.\sঃ]\s*(\d{1,3})\s*$');

/// A surah number on its own: `36`, `৩৬`.
final _numberPattern = RegExp(r'^\s*(\d{1,3})\s*$');

/// A surah name followed by an ayah number: `বকনা বাছুর ২৫৫`, `yasin 1`.
final _namedRefPattern = RegExp(r'^\s*(.*\D)\s*[:.\sঃ]\s*(\d{1,3})\s*$');

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

/// A lone surah number in range, or null.
int? parseSurahNumber(String input) {
  final m = _numberPattern.firstMatch(foldDigits(input));
  if (m == null) return null;
  final n = int.parse(m[1]!);
  return n >= 1 && n <= 114 ? n : null;
}

final _arabicLetter = RegExp(r'[ء-ي]');

/// The definite article, as the index stores it after normalization.
const _al = 'ال';

/// Words shorter than this are dropped: one letter prefix-matches most of the
/// corpus, and as a whole query it would run on every keystroke.
const _minWordLength = 2;

/// Splits a normalized token where the FTS tokenizer would: `/`, `।`, and any
/// other mark that is neither a letter nor a number.
final _subTokens = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// Bengali words this short are not prefix-matched: বার would reach
/// বারাকাতময় and মাস মাসজিদুল. They match themselves and [_bengaliSuffixes].
const _shortWord = 3;

/// Endings that attach to a Bengali word without changing it: case, plural,
/// classifier, emphasis.
const _suffixesAsTyped = [
  'ের',
  'এর',
  'র',
  'ে',
  'এ',
  'য়',
  'তে',
  'কে',
  'টি',
  'টা',
  'টির',
  'টিতে',
  'গুলো',
  'গুলি',
  'দের',
  'রা',
  'ও',
  'ই',
  'সমূহ',
  'খানা',
];

/// [_suffixesAsTyped] plus their loose forms, for the loose column.
final _bengaliSuffixes = {
  for (final s in _suffixesAsTyped) ...[s, looseFold(s)],
}.toList();

final _bengaliLetter = RegExp('[ঀ-৿]');

/// Whether [w] is a short Bengali word, matched only whole or suffixed.
bool _isShort(String w) =>
    _bengaliLetter.hasMatch(w) && w.runes.length <= _shortWord;

/// A query broken into words, each with every form that may stand for it.
///
/// One user word becomes a group: the word itself, its article-prefixed form
/// for Arabic, and its synonyms. Each form is searched both as typed and in
/// [looseFold] form. The same object decides which words of a result to
/// highlight, so what is marked is exactly what matched.
class SearchTerms {
  SearchTerms._(this.groups)
    : _loose = [
        for (final g in groups) [for (final w in g) looseFold(w)],
      ];

  /// Normalized forms per user word; the first of each is the word itself.
  final List<List<String>> groups;
  final List<List<String>> _loose;

  /// Null when nothing usable is left. [tooShort] tells the two apart.
  static SearchTerms? parse(String input) {
    final words = _words(input);
    if (words.isEmpty) return null;
    return SearchTerms._([
      for (final w in words)
        {
          w,
          if (_arabicLetter.hasMatch(w) && !w.startsWith(_al)) '$_al$w',
          ...synonymsOf(w),
        }.toList(),
    ]);
  }

  /// Whether [input] has words, but all of them under the minimum length.
  static bool tooShort(String input) =>
      _words(input).isEmpty && normalizeForSearch(input).isNotEmpty;

  static List<String> _words(String input) => [
    for (final w in normalizeForSearch(input).split(' '))
      if (w.runes.length >= _minWordLength) w,
  ];

  /// The FTS5 MATCH expression: groups ANDed, or ORed when [any].
  ///
  /// Every form is a quoted prefix query, so no user input is ever read as
  /// FTS syntax. Prefix matching is required for Bengali, where suffixes
  /// attach to the word (নিদর্শন must reach নিদর্শনরূপে). Arabic forms try the
  /// article because the index keeps `ال` attached: قمر finds القمر.
  ///
  /// Short Bengali words ([_isShort]) are the exception: they match whole or
  /// with a known suffix, never as a bare prefix, in both the exact and the
  /// loose columns.
  String matchExpression({bool any = false}) => _expression(any, exact: false);

  /// Like [matchExpression], but with no open prefixes: only whole words
  /// (and short words with their suffixes). Results it matches rank first.
  String exactExpression({bool any = false}) => _expression(any, exact: true);

  String _expression(bool any, {required bool exact}) {
    String quote(String w) => '"${w.replaceAll('"', '""')}"';
    List<String> phrases(String w) => _isShort(w)
        ? [quote(w), for (final s in _bengaliSuffixes) quote('$w$s')]
        : exact
        // A long word with a plain suffix still counts as whole.
        ? [quote(w), for (final s in _bengaliSuffixes) quote('$w$s')]
        : ['${quote(w)}*'];
    final parts = [
      for (final (i, g) in groups.indexed)
        {...g, ..._loose[i]}.expand(phrases).toSet().toList(),
    ];
    String group(List<String> forms) =>
        forms.length == 1 ? forms.single : '(${forms.join(' OR ')})';
    // Explicit AND: FTS5 accepts implicit AND between phrases only, not
    // between parenthesized groups.
    return parts.map(group).join(any ? ' OR ' : ' AND ');
  }

  /// Whether [token] is matched by [form] under the rule FTS applies.
  static bool _formHits(String token, String form) {
    if (!_isShort(form)) return token.startsWith(form);
    if (token == form) return true;
    if (!token.startsWith(form)) return false;
    return _bengaliSuffixes.contains(token.substring(form.length));
  }

  /// Splits text into the tokens [matchesAll] takes: normalized, loose, and
  /// cut where the FTS tokenizer would cut.
  static List<String> looseTokens(String text) => [
    for (final t in looseFold(normalizeForSearch(text)).split(_subTokens))
      if (t.isNotEmpty) t,
  ];

  /// Whether every word group has a form some token starts with: the same
  /// rule FTS applies, run in memory over [looseTokens].
  bool matchesAll(List<String> tokens) {
    for (final forms in _loose) {
      if (!tokens.any((t) => forms.any((f) => _formHits(t, f)))) return false;
    }
    return true;
  }

  /// Whether [token], a word of displayed text, is one the query matched.
  bool hits(String token) {
    for (final part in normalizeForSearch(token).split(_subTokens)) {
      if (part.isEmpty) continue;
      final loose = looseFold(part);
      for (final (i, g) in groups.indexed) {
        for (final (j, form) in g.indexed) {
          if (_formHits(part, form) || _formHits(loose, _loose[i][j])) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

/// Turns free text into an FTS5 MATCH expression, or null if nothing is left.
String? ftsMatchExpression(String input, {bool any = false}) =>
    SearchTerms.parse(input)?.matchExpression(any: any);

/// Words that may open a surah query and say nothing about which surah.
final _surahWord = RegExp(r'^(সূরা|সুরা|surah|sura|surat)\s+');

/// Every key a surah's names can be matched by.
///
/// Bengali names are the meaning (চাঁদ for Al-Qamar), English names the Latin
/// transliteration, both with and without the article.
List<String> _surahKeys(Surah s) {
  final latin = s.nameEn.toLowerCase();
  final bare = latin.replaceFirst(RegExp(r'^a[a-z]{1,2}-'), '');
  final arabic = normalizeForSearch(s.nameAr);
  return {
    looseFold(normalizeForSearch(s.nameBn)),
    ...looseFold(normalizeForSearch(s.nameBn)).split(' '),
    latin.replaceAll(RegExp('[^a-z]'), ''),
    bare.replaceAll(RegExp('[^a-z]'), ''),
    arabic,
    if (arabic.startsWith(_al)) arabic.substring(_al.length),
  }.where((k) => k.isNotEmpty).toList();
}

/// The query as a surah key: loose, article-free, Latin squeezed together.
String _surahQuery(String input) {
  var q = normalizeForSearch(input).replaceFirst(_surahWord, '');
  if (RegExp('[a-z]').hasMatch(q)) return q.replaceAll(RegExp('[^a-z]'), '');
  if (q.startsWith(_al) && q.length > _al.length + 1) {
    q = q.substring(_al.length);
  }
  return looseFold(q);
}

/// Surahs whose name [input] is, or begins, best first.
List<Surah> matchSurahs(List<Surah> all, String input, {int limit = 3}) {
  final q = _surahQuery(input);
  if (q.runes.length < _minWordLength) return const [];
  final scored = <(int, Surah)>[];
  for (final s in all) {
    var best = 0;
    for (final k in _surahKeys(s)) {
      if (k == q) {
        best = 2;
      } else if (best == 0 && k.startsWith(q)) {
        best = 1;
      }
    }
    if (best > 0) scored.add((best, s));
  }
  scored.sort((a, b) {
    final byScore = b.$1.compareTo(a.$1);
    return byScore != 0 ? byScore : a.$2.number.compareTo(b.$2.number);
  });
  return [for (final (_, s) in scored.take(limit)) s];
}

/// Everything the search screen shows for one query.
class SearchResults {
  const SearchResults({
    this.ref,
    this.refAyah,
    this.citingRef = const [],
    this.matchedSurahs = const [],
    this.questions = const [],
    this.ayahs = const [],
    this.ayahTotal = 0,
    this.surahs = const {},
    this.terms,
    this.relaxed = false,
    this.tooShort = false,
  });

  static const empty = SearchResults();

  /// Set when the query was a verse reference, whether or not it exists.
  final AyahRef? ref;

  /// The referenced verse, or null when the surah has no such ayah.
  final Ayah? refAyah;

  /// Questions that cite [refAyah].
  final List<Question> citingRef;

  /// Surahs the query names, or the one it numbers.
  final List<Surah> matchedSurahs;

  /// Questions matching the text, best first.
  final List<Question> questions;

  /// Verses matching the text, best first, at most the search limit.
  final List<Ayah> ayahs;

  /// How many verses matched in all, which can exceed [ayahs].
  final int ayahTotal;

  /// Surah rows for every verse above, keyed by number.
  final Map<int, Surah> surahs;

  /// What the text matched, for highlighting. Null for reference queries.
  final SearchTerms? terms;

  /// No result had every word, so these have any of them.
  final bool relaxed;

  /// Only one-letter words were typed, so nothing was searched.
  final bool tooShort;

  bool get isEmpty =>
      refAyah == null &&
      matchedSurahs.isEmpty &&
      questions.isEmpty &&
      ayahs.isEmpty;
}

/// Full-text and reference search over the content database.
extension ContentSearch on ContentDatabase {
  /// A reference goes straight to the verse; a number to its surah; anything
  /// else to the surah names and FTS.
  Future<SearchResults> search(String input, {int ayahLimit = 50}) async {
    // `সূরা ৩৬` and `surah 2:255` mean the same as without the word.
    final core = normalizeForSearch(input).replaceFirst(_surahWord, '');

    final ref = parseAyahRef(core);
    if (ref != null) return _reference(ref);

    if (parseSurahNumber(core) case final n?) {
      final s = await surah(n);
      return SearchResults(matchedSurahs: [?s]);
    }

    final all = await allSurahs();
    if (_namedRefPattern.firstMatch(core) case final m?) {
      final named = matchSurahs(all, m[1]!, limit: 1);
      final ayah = int.parse(m[2]!);
      if (named.isNotEmpty && ayah >= 1) {
        return _reference((surah: named.single.number, ayah: ayah));
      }
    }

    final terms = SearchTerms.parse(input);
    if (terms == null) {
      return SearchResults(tooShort: SearchTerms.tooShort(input));
    }
    final matched = matchSurahs(all, input);

    var (questions, ayahs, total) = await _text(terms, false, ayahLimit);
    var relaxed = false;
    if (terms.groups.length > 1 && questions.isEmpty && ayahs.isEmpty) {
      (questions, ayahs, total) = await _text(terms, true, ayahLimit);
      relaxed = questions.isNotEmpty || ayahs.isNotEmpty;
    }

    final byNumber = {for (final s in all) s.number: s};
    return SearchResults(
      matchedSurahs: matched,
      questions: questions,
      ayahs: ayahs,
      ayahTotal: total,
      // All of them: question rows cite surahs no matched ayah is in.
      surahs: byNumber,
      terms: terms,
      relaxed: relaxed,
    );
  }

  Future<SearchResults> _reference(AyahRef ref) async {
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

  Future<(List<Question>, List<Ayah>, int)> _text(
    SearchTerms terms,
    bool any,
    int limit,
  ) {
    final match = terms.matchExpression(any: any);
    final exact = terms.exactExpression(any: any);
    return (
      searchQuestions(match, exact: exact),
      searchAyahs(match, limit: limit, exact: exact),
      countAyahs(match),
    ).wait;
  }

  /// `ORDER BY` putting rows that also match [exact] first, then by [rank].
  /// Adds [exact]'s variable to [vars] when given.
  static String _order(
    String table,
    String rank,
    String? exact,
    List<Variable> vars,
  ) {
    if (exact == null) return rank;
    vars.add(Variable(exact));
    return 'rowid IN (SELECT rowid FROM $table WHERE $table MATCH ?) DESC, $rank';
  }

  /// Questions for a MATCH expression from [ftsMatchExpression], best first.
  ///
  /// With [exact], rows matching it come first: whole words before prefixes.
  Future<List<Question>> searchQuestions(String match, {String? exact}) async {
    final vars = <Variable>[Variable(match)];
    final order = _order(Fts.questions, FtsRank.questions, exact, vars);
    final rows = await customSelect(
      'SELECT slug FROM ${Fts.questions} '
      'WHERE ${Fts.questions} MATCH ? ORDER BY $order',
      variables: vars,
    ).get();
    return questionsBySlugs([for (final r in rows) r.read<String>('slug')]);
  }

  /// Verses for a MATCH expression, best first.
  ///
  /// The ayah index is contentless, so it yields rowids, which are ayah ids.
  Future<List<Ayah>> searchAyahs(
    String match, {
    int limit = 50,
    String? exact,
  }) async {
    final vars = <Variable>[Variable(match)];
    final order = _order(Fts.ayahs, FtsRank.ayahs, exact, vars);
    final rows = await customSelect(
      'SELECT rowid AS id FROM ${Fts.ayahs} '
      'WHERE ${Fts.ayahs} MATCH ? ORDER BY $order LIMIT ?',
      variables: [...vars, Variable(limit)],
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
