import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_queries.dart';
import '../../core/db/database_providers.dart';
import '../../core/db/user_db.dart';
import '../../shared/references.dart';

/// Read-model providers shared by the home, category and question screens.
///
/// Content never changes while the app runs, so these are plain futures that
/// stay cached. User data (history, bookmarks) is streamed, so screens update
/// the moment a question is opened or bookmarked.

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  return db.allCategories();
});

final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  return db.allQuestions();
});

final citationsProvider = FutureProvider<Map<String, List<int>>>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  return db.allCitations();
});

/// Everything a question list needs to render its rows, loaded once.
class QuestionIndex {
  QuestionIndex(this.questions, List<Category> categories, this.citations)
    : categories = {for (final c in categories) c.id: c};

  /// All published questions, in authored order.
  final List<Question> questions;

  /// Keyed by id, in authored order.
  final Map<String, Category> categories;

  /// `slug → cited ayah ids`.
  final Map<String, List<int>> citations;

  Question? bySlug(String slug) {
    for (final q in questions) {
      if (q.slug == slug) return q;
    }
    return null;
  }

  List<Question> inCategory(String id) => [
    for (final q in questions)
      if (q.category == id) q,
  ];

  List<int> citationsOf(Question q) => citations[q.slug] ?? const [];

  /// Row meta for a question: `শব্দ ও পরিভাষা • ৫৪:১৫, ৫৪:১৭, ৫৪:২২ +৩`.
  String rowMeta(Question q) {
    final category = categories[q.category]?.nameBn;
    final refs = refsSummary(citationsOf(q));
    return [?category, if (refs.isNotEmpty) refs].join(' • ');
  }

  /// The question after [q] in its category, wrapping to the first; null when
  /// [q] is alone in it.
  Question? nextInCategory(Question q) {
    final list = inCategory(q.category);
    final i = list.indexWhere((o) => o.slug == q.slug);
    if (list.length < 2 || i < 0) return null;
    return list[(i + 1) % list.length];
  }

  /// Up to [count] questions to read after [q], closest first: those citing
  /// the same ayah, then the same surah, then the rest of its category in
  /// order from just after it. [exclude] keeps out e.g. the "next" question
  /// already offered.
  List<Question> related(
    Question q, {
    int count = 3,
    Set<String> exclude = const {},
  }) {
    final ayat = citationsOf(q).toSet();
    final surahs = {for (final id in ayat) surahOfAyahId(id)};
    final skip = {q.slug, ...exclude};
    final picked = <Question>[];
    void take(Iterable<Question> from) {
      for (final o in from) {
        if (picked.length == count) return;
        if (skip.add(o.slug)) picked.add(o);
      }
    }

    take(questions.where((o) => citationsOf(o).any(ayat.contains)));
    take(
      questions.where(
        (o) => citationsOf(o).any((id) => surahs.contains(surahOfAyahId(id))),
      ),
    );
    final category = inCategory(q.category);
    final at = category.indexWhere((o) => o.slug == q.slug);
    take([...category.skip(at + 1), ...category.take(at)]);
    return picked;
  }

  /// A few questions to start reading on [today], one per category.
  ///
  /// Like the featured question, derived from the date alone: the same all
  /// day, different the next. The day picks which categories lead and which
  /// question each offers; [exclude] keeps out ones already on screen.
  List<Question> dailyPicks(
    DateTime today, {
    Set<String> exclude = const {},
    int count = 5,
  }) {
    final day = dayNumber(today);
    final ids = categories.keys.toList();
    final picks = <Question>[];
    for (var k = 0; k < ids.length && picks.length < count; k++) {
      final pool = [
        for (final q in inCategory(ids[(day + k) % ids.length]))
          if (!exclude.contains(q.slug)) q,
      ];
      if (pool.isNotEmpty) picks.add(pool[(day + k * 7) % pool.length]);
    }
    return picks;
  }

  /// Questions citing at least one ayah of [surah], in authored order.
  List<Question> citingSurah(int surah) => [
    for (final q in questions)
      if (citationsOf(q).any((id) => surahOfAyahId(id) == surah)) q,
  ];

  /// Surah numbers that some question cites, ascending, with how many
  /// questions cite each.
  Map<int, int> citedSurahs() {
    final counts = <int, int>{};
    for (final q in questions) {
      for (final s in {for (final id in citationsOf(q)) surahOfAyahId(id)}) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

final surahsProvider = FutureProvider<Map<int, Surah>>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  final rows = await db.allSurahs();
  return {for (final s in rows) s.number: s};
});

final questionIndexProvider = FutureProvider<QuestionIndex>((ref) async {
  final (questions, categories, citations) = await (
    ref.watch(allQuestionsProvider.future),
    ref.watch(categoriesProvider.future),
    ref.watch(citationsProvider.future),
  ).wait;
  return QuestionIndex(questions, categories, citations);
});

final questionDetailProvider =
    FutureProvider.family<QuestionWithAyahs?, String>((ref, slug) async {
      final db = await ref.watch(contentDatabaseProvider.future);
      return db.questionDetail(slug);
    });

/// Most recently opened question slugs, newest first.
final recentSlugsProvider = StreamProvider<List<String>>((ref) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchRecentSlugs(limit: 20);
});

/// Bookmarked question slugs, most recently added first.
final bookmarkedSlugsProvider = StreamProvider<List<String>>((ref) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchBookmarkedSlugs().map((slugs) => slugs.toList());
});

final isBookmarkedProvider = StreamProvider.family<bool, String>((
  ref,
  slug,
) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchIsBookmarked(slug);
});

/// Saved questions with their folder, most recently added first.
final bookmarksProvider = StreamProvider<List<Bookmark>>((ref) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchBookmarks();
});

/// Saved verses with their folder, most recently added first.
final ayahBookmarksProvider = StreamProvider<List<AyahBookmark>>((ref) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchAyahBookmarks();
});

final isAyahBookmarkedProvider = StreamProvider.family<bool, int>((
  ref,
  ayahId,
) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchIsAyahBookmarked(ayahId);
});

final foldersProvider = StreamProvider<List<Folder>>((ref) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchFolders();
});

/// The saved verses themselves, resolved from the content database.
///
/// Recomputed whenever the saved set changes: the two live in different
/// database files, so this cannot be a join.
final savedAyahsProvider = FutureProvider<Map<int, Ayah>>((ref) async {
  final saved = await ref.watch(ayahBookmarksProvider.future);
  final db = await ref.watch(contentDatabaseProvider.future);
  return db.ayahsByIds(saved.map((b) => b.ayahId));
});

/// Today's date. A provider so a test can pin the featured question.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// The featured question: the same one all day, a different one each day.
///
/// Derived from the calendar date alone, so it needs no stored state and every
/// launch on the same day agrees.
Question? questionOfTheDay(List<Question> questions, DateTime today) {
  if (questions.isEmpty) return null;
  return questions[dayNumber(today) % questions.length];
}

/// Days since the epoch for [today]'s calendar date, ignoring the time.
int dayNumber(DateTime today) =>
    DateTime.utc(today.year, today.month, today.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
