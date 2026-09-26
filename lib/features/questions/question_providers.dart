import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_queries.dart';
import '../../core/db/database_providers.dart';
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

/// Today's date. A provider so a test can pin the featured question.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// The featured question: the same one all day, a different one each day.
///
/// Derived from the calendar date alone, so it needs no stored state and every
/// launch on the same day agrees.
Question? questionOfTheDay(List<Question> questions, DateTime today) {
  if (questions.isEmpty) return null;
  final day = DateTime.utc(today.year, today.month, today.day);
  final index = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  return questions[index % questions.length];
}
