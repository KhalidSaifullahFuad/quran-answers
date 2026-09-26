import 'package:drift/drift.dart';

import 'content_db.dart';

/// A question together with the ayat it cites, in the authored order.
class QuestionWithAyahs {
  const QuestionWithAyahs(this.question, this.ayahs, this.surahs);

  final Question question;
  final List<Ayah> ayahs;

  /// Surah rows for the cited ayat, keyed by surah number, so a citation can be
  /// labelled without a second round trip.
  final Map<int, Surah> surahs;

  Surah surahOf(Ayah ayah) => surahs[ayah.surah]!;
}

/// Reads of the content database.
///
/// An extension rather than a repository class wrapping the database: Drift's
/// generated API already is the data layer, and a passthrough over it would add
/// a file to maintain without adding a decision.
extension ContentQueries on ContentDatabase {
  Future<List<Category>> allCategories() {
    final query = select(categories)
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.get();
  }

  Future<List<Question>> allQuestions() {
    final query = select(questions)
      ..orderBy([(q) => OrderingTerm.asc(q.sortOrder)]);
    return query.get();
  }

  Future<List<Question>> questionsInCategory(String categoryId) {
    final query = select(questions)
      ..where((q) => q.category.equals(categoryId))
      ..orderBy([(q) => OrderingTerm.asc(q.sortOrder)]);
    return query.get();
  }

  /// Questions for the given slugs, in the order the slugs were given.
  ///
  /// Used by bookmarks and history, which hold slugs in their own order and live
  /// in a different database file, so this cannot be a join. Slugs with no
  /// matching question are dropped: a content update may have removed a question
  /// a user had bookmarked, and that is not an error.
  Future<List<Question>> questionsBySlugs(List<String> slugs) async {
    if (slugs.isEmpty) return const [];
    final rows = await (select(
      questions,
    )..where((q) => q.slug.isIn(slugs))).get();
    final bySlug = {for (final r in rows) r.slug: r};
    return [for (final slug in slugs) ?bySlug[slug]];
  }

  /// Every citation as `slug → ayah ids`, each list in the authored order.
  ///
  /// Lets a list screen label every row with its references in one query
  /// instead of one per row.
  Future<Map<String, List<int>>> allCitations() async {
    final rows =
        await (select(questionAyahs)..orderBy([
              (qa) => OrderingTerm.asc(qa.questionSlug),
              (qa) => OrderingTerm.asc(qa.sortOrder),
            ]))
            .get();
    final bySlug = <String, List<int>>{};
    for (final r in rows) {
      (bySlug[r.questionSlug] ??= []).add(r.ayahId);
    }
    return bySlug;
  }

  Future<Question?> questionBySlug(String slug) =>
      (select(questions)..where((q) => q.slug.equals(slug))).getSingleOrNull();

  /// A question with its cited ayat resolved from the mushaf.
  Future<QuestionWithAyahs?> questionDetail(String slug) async {
    final question = await questionBySlug(slug);
    if (question == null) return null;

    final rows =
        await (select(questionAyahs)
              ..where((qa) => qa.questionSlug.equals(slug))
              ..orderBy([(qa) => OrderingTerm.asc(qa.sortOrder)]))
            .get();
    final ids = [for (final r in rows) r.ayahId];
    final ayahRows = await (select(ayahs)..where((a) => a.id.isIn(ids))).get();
    final byId = {for (final a in ayahRows) a.id: a};
    final ordered = [for (final id in ids) ?byId[id]];

    return QuestionWithAyahs(
      question,
      ordered,
      await _surahsFor(ordered.map((a) => a.surah)),
    );
  }

  Future<Ayah?> ayahAt(int surah, int ayah) => (select(
    ayahs,
  )..where((a) => a.id.equals(ayahId(surah, ayah)))).getSingleOrNull();

  /// An ayah with up to [context] verses either side, for the ayah screen.
  ///
  /// Clamped to the surah, so the window never runs into the previous or next
  /// chapter.
  Future<List<Ayah>> ayahWindow(int surah, int ayah, {int context = 2}) {
    final from = ayah - context < 1 ? 1 : ayah - context;
    final query = select(ayahs)
      ..where(
        (a) =>
            a.surah.equals(surah) &
            a.ayah.isBetweenValues(from, ayah + context),
      )
      ..orderBy([(a) => OrderingTerm.asc(a.ayah)]);
    return query.get();
  }

  /// Questions citing a given ayah, shown on the ayah screen.
  Future<List<Question>> questionsCiting(int surah, int ayah) async {
    final links = await (select(
      questionAyahs,
    )..where((qa) => qa.ayahId.equals(ayahId(surah, ayah)))).get();
    return questionsBySlugs([for (final l in links) l.questionSlug]);
  }

  Future<Surah?> surah(int number) =>
      (select(surahs)..where((s) => s.number.equals(number))).getSingleOrNull();

  Future<List<Surah>> allSurahs() {
    final query = select(surahs)..orderBy([(s) => OrderingTerm.asc(s.number)]);
    return query.get();
  }

  Future<Map<int, Surah>> _surahsFor(Iterable<int> numbers) async {
    final wanted = numbers.toSet().toList();
    if (wanted.isEmpty) return const {};
    final rows = await (select(
      surahs,
    )..where((s) => s.number.isIn(wanted))).get();
    return {for (final r in rows) r.number: r};
  }

  /// Content version, translation credit and counts recorded at build time.
  Future<Map<String, String>> metadata() async {
    final rows = await select(meta).get();
    return {for (final r in rows) r.key: r.value};
  }
}
