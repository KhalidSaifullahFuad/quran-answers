import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_answers/app.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/db/content_search.dart';
import 'package:quran_answers/core/db/database_providers.dart';
import 'package:quran_answers/core/strings.dart';
import 'package:quran_answers/core/text/normalize.dart';
import 'package:quran_answers/core/text/numerals.dart';
import 'package:quran_answers/core/theme/theme.dart';
import 'package:quran_answers/core/theme/typography.dart';
import 'package:quran_answers/features/about/about_screen.dart';
import 'package:quran_answers/features/ayah/ayah_screen.dart';
import 'package:quran_answers/features/history/history_screen.dart';
import 'package:quran_answers/features/home/home_screen.dart';
import 'package:quran_answers/features/questions/all_questions_screen.dart';
import 'package:quran_answers/features/questions/question_providers.dart';
import 'package:quran_answers/features/search/search_screen.dart';
import 'package:quran_answers/features/settings/settings_provider.dart';
import 'package:quran_answers/features/settings/settings_screen.dart';
import 'package:quran_answers/shared/ayah_card.dart';
import 'package:quran_answers/shared/navigation.dart';
import 'package:quran_answers/shared/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/authored_content.dart';

/// Boots the app the way a device does: the real asset is copied out of the
/// bundle, opened, and queried. Only the target directory, the opener and the
/// date are substituted — path_provider has no implementation in a test, a
/// background isolate cannot deliver messages through a fake clock, and a fixed
/// date pins the featured question.
///
/// Every provider a screen watches is resolved inside [WidgetTester.runAsync]
/// *before* that screen is pumped. A widget test fakes async: a future started
/// while the fake clock is in charge has its continuations queued in that zone,
/// so a screen that starts its own query simply never finishes loading.
void main() {
  late Directory directory;
  late ProviderContainer container;
  late SharedPreferences prefs;
  final today = DateTime(2026, 9, 23);

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('app_test');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDirectoryProvider.overrideWith((ref) async => directory),
        databaseOpenerProvider.overrideWithValue(NativeDatabase.new),
        todayProvider.overrideWithValue(today),
      ],
    );
  });

  tearDown(() async {
    // Closed explicitly before the directory goes: on Windows an open database
    // file keeps a handle that makes the delete fail.
    await (await container.read(contentDatabaseProvider.future)).close();
    // Idempotent: a test that opened a question has already closed it.
    await (await container.read(userDatabaseProvider.future)).close();
    container.dispose();
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Disposable temp directory; a lingering handle is not worth a failure.
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QuranAnswersApp(),
      ),
    );
    // Not pumpAndSettle: a loading state is an indeterminate spinner, which
    // animates forever. One frame is enough once providers are resolved.
    await tester.pump();
  }

  /// Navigates the home tab to [path], as a tap on a link there would.
  Future<void> goTo(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(HomeScreen))).go(path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Resolves what the home screen watches, so the app boots straight to it.
  Future<QuestionIndex> resolveHome() async {
    final index = await container.read(questionIndexProvider.future);
    await container.read(recentSlugsProvider.future);
    final featured = questionOfTheDay(index.questions, today)!;
    await container.read(questionDetailProvider(featured.slug).future);
    return index;
  }

  /// Runs fake frames and real-time slices alternately until [done] holds.
  ///
  /// Opening a question records it in history. That write is started on the
  /// fake clock, while Drift work already in flight from provider setup belongs
  /// to the real zone, and Drift's lock orders the two — so each can end up
  /// waiting on the other's queue, and neither pump() nor runAsync() alone
  /// advances both.
  Future<void> drain(WidgetTester tester, Future<bool> Function() done) async {
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final finished = await tester.runAsync(done);
      if (finished ?? false) return;
    }
    fail('background database work did not finish');
  }

  /// Unmounts the app and closes the user database inside the test, where
  /// both zones can still be driven. Closing it from tearDown would wait on
  /// fake-clock work that nothing advances any more.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    var closed = false;
    container.read(userDatabaseProvider).value!.close().then((_) {
      closed = true;
    });
    await drain(tester, () async => closed);
  }

  testWidgets('home features a question and leads to the full list', (
    tester,
  ) async {
    late QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
      await container.read(recentSlugsProvider.future);
      final featured = questionOfTheDay(index.questions, today)!;
      await container.read(questionDetailProvider(featured.slug).future);
    });
    expect([
      for (final q in index.questions) q.slug,
    ], AuthoredContent.load().publishedSlugs);

    await pumpApp(tester);

    expect(find.text('QURAN ANSWERS'), findsOne);
    expect(find.text(bnDayMonth(today)), findsOne);
    // A few topic shortcuts, then the way to all of them.
    final categories = index.categories.values.toList();
    for (final c in categories.take(5)) {
      expect(
        find.descendant(
          of: find.byType(TopicChip),
          matching: find.text(c.nameBn),
        ),
        findsOne,
        reason: 'topic chip ${c.id}',
      );
    }
    // A row's meta may name the category, so look only inside the chips.
    expect(
      find.descendant(
        of: find.byType(TopicChip, skipOffstage: false),
        matching: find.text(categories.last.nameBn, skipOffstage: false),
      ),
      findsNothing,
    );
    expect(find.text(Strings.allTopics, skipOffstage: false), findsOne);
    // With no history, home offers a few questions to start with: one per
    // category, never the featured one. The full list sits behind a link.
    final featured = questionOfTheDay(index.questions, today)!;
    final picks = index.dailyPicks(today, exclude: {featured.slug});
    expect(picks, hasLength(5));
    expect(picks.map((q) => q.category).toSet(), hasLength(5));
    expect(find.text(Strings.startReading, skipOffstage: false), findsOne);
    expect(find.byType(QuestionTile, skipOffstage: false), findsNWidgets(5));
    for (final q in picks) {
      expect(
        find.descendant(
          of: find.byType(QuestionTile, skipOffstage: false),
          matching: find.text(q.questionBn, skipOffstage: false),
        ),
        findsOne,
        reason: 'pick ${q.slug}',
      );
    }
    // "সব দেখুন" switches to the questions tab, which lists every question.
    final seeAll = find.text(Strings.seeAll);
    await tester.ensureVisible(seeAll);
    await tester.pump();
    await tester.tap(seeAll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final screen = find.byType(AllQuestionsScreen);
    expect(screen, findsOne);
    // The list builds lazily, so how many are shown is read from the header
    // count rather than by counting rows.
    Finder shown(int n) => find.descendant(
      of: screen,
      matching: find.text(Strings.questionCount(bnDigits(n))),
    );
    expect(shown(index.questions.length), findsOne);

    // Typing narrows the list, through the same normalizer as the database.
    const word = 'মুসা';
    bool matches(Question q) => normalizeForSearch(
      '${q.questionBn} ${q.answerBn}',
    ).contains(normalizeForSearch(word));
    final field = find.descendant(of: screen, matching: find.byType(TextField));
    await tester.enterText(field, word);
    await tester.pump(const Duration(milliseconds: 200));
    final hits = index.questions.where(matches).toList();
    expect(hits, isNotEmpty);
    expect(shown(hits.length), findsOne);

    // A category chip and the words combine.
    final prophets = index.categories['prophets']!;
    await tester.tap(
      find.descendant(of: screen, matching: find.text(prophets.nameBn)),
    );
    await tester.pump();
    expect(shown(index.inCategory('prophets').where(matches).length), findsOne);

    // Nothing matching offers the whole-Qur'an search.
    await tester.enterText(field, 'কখগঘঙ');
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown(0), findsOne);
    expect(
      find.descendant(of: screen, matching: find.byType(QuestionTile)),
      findsNothing,
    );
    expect(find.text(Strings.noResults), findsOne);
    expect(find.text(Strings.searchWholeQuran), findsOne);
  });

  test('daily picks hold for a day and respect exclusions', () async {
    final index = await container.read(questionIndexProvider.future);
    final day = DateTime(2026, 10, 18, 9);
    final picks = index.dailyPicks(day);
    expect(
      index.dailyPicks(DateTime(2026, 10, 18, 23)).map((q) => q.slug),
      picks.map((q) => q.slug),
    );
    expect(
      index.dailyPicks(DateTime(2026, 10, 19)).map((q) => q.slug),
      isNot(picks.map((q) => q.slug)),
    );
    final first = picks.first.slug;
    expect(
      index.dailyPicks(day, exclude: {first}).map((q) => q.slug),
      isNot(contains(first)),
    );
  });

  test('related questions and the next one come from the index', () async {
    final index = await container.read(questionIndexProvider.future);
    for (final q in index.questions) {
      final related = index.related(q);
      expect(related.map((r) => r.slug), isNot(contains(q.slug)));
      expect(related.length, lessThanOrEqualTo(3));
      expect(related.map((r) => r.slug).toSet(), hasLength(related.length));
    }
    // Not the same first three for every question in a category.
    final prophets = index.inCategory('prophets');
    expect({
      for (final q in prophets) index.related(q).map((r) => r.slug).join(),
    }, hasLength(greaterThan(1)));
    // Next walks the category in order and wraps at its end.
    expect(index.nextInCategory(prophets.first)!.slug, prophets[1].slug);
    expect(index.nextInCategory(prophets.last)!.slug, prophets.first.slug);
    final next = index.nextInCategory(prophets.first)!;
    expect(
      index.related(prophets.first, exclude: {next.slug}).map((r) => r.slug),
      isNot(contains(next.slug)),
    );
  });

  testWidgets('a question shows its answer and every cited ayah in full', (
    tester,
  ) async {
    const slug = 'muddakkir-al-qamar';
    late QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
      await container.read(recentSlugsProvider.future);
      final featured = questionOfTheDay(index.questions, today)!;
      await container.read(questionDetailProvider(featured.slug).future);
      await container.read(questionDetailProvider(slug).future);
      await container.read(isBookmarkedProvider(slug).future);
    });

    await pumpApp(tester);
    final question = index.bySlug(slug)!;
    await goTo(tester, '/question/$slug');

    expect(find.text(question.answerBn), findsOne);

    final detail = container.read(questionDetailProvider(slug)).value!;
    expect(detail.ayahs, hasLength(6));
    for (final a in detail.ayahs) {
      expect(
        find.text(a.translationBn, skipOffstage: false),
        findsOne,
        reason: 'translation of 54:${a.ayah}',
      );
      expect(
        find.text(
          '${a.textUthmani} ${ayahEndMark(a.ayah)}',
          skipOffstage: false,
        ),
        findsOne,
        reason: 'Arabic of 54:${a.ayah}, closed with its ornament',
      );
    }
    // Six ayat: a row of citations jumps to each card.
    expect(find.text(Strings.evidence), findsOne);
    // And a way on to the next question of the topic.
    expect(find.text(Strings.nextQuestion, skipOffstage: false), findsOne);

    // Opening the question put it at the top of the reading history.
    final userDb = container.read(userDatabaseProvider).value!;
    await drain(
      tester,
      () async => (await userDb.recentSlugs()).firstOrNull == slug,
    );

    await unmount(tester);
  });

  testWidgets('a "not in the Qur\'an" answer shows no empty evidence', (
    tester,
  ) async {
    const slug = 'ku-173';
    await tester.runAsync(() async {
      await resolveHome();
      await container.read(questionDetailProvider(slug).future);
      await container.read(isBookmarkedProvider(slug).future);
    });

    await pumpApp(tester);
    await goTo(tester, '/question/$slug');

    final detail = container.read(questionDetailProvider(slug)).value!;
    expect(detail.ayahs, isEmpty);
    expect(find.text(detail.question.answerBn), findsOne);
    expect(find.text(Strings.evidence), findsNothing);
    expect(find.text(Strings.quranEvidence), findsNothing);

    // Let the history write land before the databases close.
    final userDb = container.read(userDatabaseProvider).value!;
    await drain(
      tester,
      () async => (await userDb.recentSlugs()).firstOrNull == slug,
    );
    await unmount(tester);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('five tab labels fit a 360dp phone at text scale $scale', (
      tester,
    ) async {
      // The real Bengali font, not the test font's square glyphs, or the
      // widths measured here would mean nothing.
      await tester.runAsync(() async {
        final loader = FontLoader(Fonts.bengali);
        for (final w in ['Regular', 'Medium', 'SemiBold']) {
          loader.addFont(
            File(
              'assets/fonts/NotoSansBengali-$w.ttf',
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        }
        await loader.load();
      });
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              bottomNavigationBar: AppBottomNav(current: 0, onTap: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      for (final tab in AppTab.values) {
        final label = tester.renderObject<RenderParagraph>(
          find.text(tab.label),
        );
        expect(
          label.didExceedMaxLines,
          isFalse,
          reason: '${tab.label} is cut off',
        );
      }
    });
  }

  testWidgets('the bottom bar switches between the five tabs', (tester) async {
    late QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
      await container.read(surahsProvider.future);
      await container.read(recentSlugsProvider.future);
      await container.read(bookmarkedSlugsProvider.future);
      await container.read(bookmarksProvider.future);
      await container.read(foldersProvider.future);
      await container.read(savedAyahsProvider.future);
      final featured = questionOfTheDay(index.questions, today)!;
      await container.read(questionDetailProvider(featured.slug).future);
    });

    await pumpApp(tester);
    final nav = find.byType(AppBottomNav);
    expect(nav, findsOne);
    for (final tab in AppTab.values) {
      expect(
        find.descendant(of: nav, matching: find.text(tab.label)),
        findsOne,
      );
    }

    Future<void> openTab(AppTab tab) async {
      await tester.tap(
        find.descendant(of: nav, matching: find.text(tab.label)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await openTab(AppTab.questions);
    expect(find.byType(AllQuestionsScreen), findsOne);

    await openTab(AppTab.topics);
    for (final c in index.categories.values) {
      expect(find.text(c.nameBn), findsOne, reason: 'topic card ${c.id}');
    }

    await openTab(AppTab.surahs);
    expect(find.text(Strings.surahsTitle), findsOne);
    // 54 (Al-Qamar) is cited, so it is listed, badge in Bengali digits.
    expect(find.text(bnDigits(54)), findsOne);

    await openTab(AppTab.saved);
    // One empty state, and no history: that has its own screen.
    expect(find.text(Strings.nothingSaved), findsOne);
    expect(find.text(Strings.readingHistory), findsNothing);
    expect(find.byTooltip(Strings.readingHistory), findsOne);
  });

  testWidgets('a one-ayah answer has no citation row to jump from', (
    tester,
  ) async {
    late String slug;
    await tester.runAsync(() async {
      final index = await resolveHome();
      slug = index.questions
          .firstWhere((q) => index.citationsOf(q).length == 1)
          .slug;
      await container.read(questionDetailProvider(slug).future);
      await container.read(isBookmarkedProvider(slug).future);
    });

    await pumpApp(tester);
    await goTo(tester, '/question/$slug');

    expect(find.text(Strings.quranEvidence), findsOne);
    expect(find.text(Strings.evidence), findsNothing);

    final userDb = container.read(userDatabaseProvider).value!;
    await drain(
      tester,
      () async => (await userDb.recentSlugs()).firstOrNull == slug,
    );
    await unmount(tester);
  });

  testWidgets('reading history has its own screen', (tester) async {
    late QuestionIndex index;
    await tester.runAsync(() async {
      final db = await container.read(userDatabaseProvider.future);
      await db.recordView('naba-azeem');
      index = await resolveHome();
    });

    await pumpApp(tester);
    // Home shows it as last read, with the way to the whole history. The
    // first "সব দেখুন" is last read's; the start-reading section has another.
    final seeAll = find.text(Strings.seeAll).first;
    await tester.ensureVisible(seeAll);
    await tester.pump();
    await tester.tap(seeAll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HistoryScreen), findsOne);
    expect(
      find.descendant(
        of: find.byType(HistoryScreen),
        matching: find.text(index.bySlug('naba-azeem')!.questionBn),
      ),
      findsOne,
    );
    expect(find.byTooltip(Strings.clearHistory), findsOne);
  });

  testWidgets('the home search pill finds a verse by reference', (
    tester,
  ) async {
    const query = '৫৪:১৫';
    late QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
      await container.read(recentSlugsProvider.future);
      final featured = questionOfTheDay(index.questions, today)!;
      await container.read(questionDetailProvider(featured.slug).future);
    });
    // Auto-disposed: held open by a listener so the screen finds it resolved.
    // Subscribed inside runAsync, or the query starts on the fake clock.
    late ProviderSubscription<AsyncValue<SearchResults>> results;
    await tester.runAsync(() async {
      results = container.listen(searchResultsProvider(query), (_, _) {});
      await container.read(searchResultsProvider(query).future);
      final ayah = (await container.read(
        searchResultsProvider(query).future,
      )).refAyah!;
      await container.read(isAyahBookmarkedProvider(ayah.id).future);
    });
    addTearDown(() => results.close());

    await pumpApp(tester);
    // The pill and the field it opens are the same height, the 48dp touch
    // minimum, so the search bar doesn't jump when search opens.
    expect(tester.getSize(find.byType(SearchFieldButton)).height, 48);
    await tester.tap(find.byType(SearchFieldButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getSize(find.byType(TextField)).height, 48);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    // Still 48 once the clear button shows.
    expect(tester.getSize(find.byType(TextField)).height, 48);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Strings.searchPrompt), findsOne);
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    final r = results.read().value!;
    expect(find.byType(AyahCard), findsOne);
    expect(find.text(r.refAyah!.translationBn), findsOne);
    expect(find.text(Strings.citingThisAyah), findsOne);
    expect(find.text(index.bySlug('muddakkir-al-qamar')!.questionBn), findsOne);
  });

  testWidgets(
    'the saved tab lists questions and verses and filters by folder',
    (tester) async {
      late QuestionIndex index;
      late int folder;
      await tester.runAsync(() async {
        final db = await container.read(userDatabaseProvider.future);
        await db.toggleBookmark('naba-azeem');
        await db.toggleBookmark('muddakkir-al-qamar');
        await db.toggleAyahBookmark(ayahId(54, 15));
        folder = await db.createFolder('ফোল্ডার ক');
        await db.moveAyahBookmark(ayahId(54, 15), folder);

        index = await container.read(questionIndexProvider.future);
        await container.read(surahsProvider.future);
        await container.read(recentSlugsProvider.future);
        await container.read(bookmarkedSlugsProvider.future);
        await container.read(bookmarksProvider.future);
        await container.read(foldersProvider.future);
        await container.read(savedAyahsProvider.future);
        await container.read(isAyahBookmarkedProvider(ayahId(54, 15)).future);
        final featured = questionOfTheDay(index.questions, today)!;
        await container.read(questionDetailProvider(featured.slug).future);
      });

      await pumpApp(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(AppTab.saved.label),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final naba = index.bySlug('naba-azeem')!.questionBn;
      // Saved verses are compact rows leading to the verse, not full cards.
      final verse = find.text(
        container
            .read(savedAyahsProvider)
            .value![ayahId(54, 15)]!
            .translationBn,
      );
      expect(find.text(naba), findsOne);
      expect(verse, findsOne);
      expect(find.byType(AyahCard), findsNothing);
      expect(find.text(Strings.savedQuestions), findsOne);

      // Only the verse is in the folder.
      await tester.tap(find.text('ফোল্ডার ক'));
      await tester.pump();
      expect(find.text(naba), findsNothing);
      expect(verse, findsOne);
      // A folder holding no questions shows no empty questions section.
      expect(find.text(Strings.savedQuestions), findsNothing);

      await tester.tap(find.text(Strings.allFolders));
      await tester.pump();

      expect(find.text(naba), findsOne);

      // File the unfiled question into the folder through the picker.
      final row = find.ancestor(
        of: find.text(index.bySlug('muddakkir-al-qamar')!.questionBn),
        matching: find.byType(QuestionTile),
      );
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byTooltip(Strings.moveToFolder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(Strings.noFolder), findsOne);
      await tester.tap(find.text('ফোল্ডার ক').last);
      await tester.pump(const Duration(milliseconds: 600));
      final db = container.read(userDatabaseProvider).value!;
      await drain(tester, () async {
        final marks = await db.watchBookmarks().first;
        return marks.any(
          (b) => b.questionSlug == 'muddakkir-al-qamar' && b.folderId == folder,
        );
      });
      await unmount(tester);
    },
  );

  testWidgets(
    'an ayah opens with its context, neighbours and citing questions',
    (tester) async {
      late QuestionIndex index;
      late AyahPage page;
      late AyahPage next;
      await tester.runAsync(() async {
        index = await resolveHome();
        page = (await container.read(
          ayahPageProvider((surah: 54, ayah: 15)).future,
        ))!;
        next = (await container.read(
          ayahPageProvider((surah: 54, ayah: 16)).future,
        ))!;
        for (final id in [ayahId(54, 15), ayahId(54, 16)]) {
          await container.read(isAyahBookmarkedProvider(id).future);
        }
      });
      expect(page.before.map((a) => a.ayah), [13, 14]);
      expect(page.after.map((a) => a.ayah), [16, 17]);
      expect(page.previous, (surah: 54, ayah: 14));
      expect(page.next, (surah: 54, ayah: 16));

      await pumpApp(tester);
      await goTo(tester, '/ayah/54/15');

      // The verse itself is a full card; its neighbours are shown around it.
      final card = find.byType(AyahCard);
      expect(card, findsOne);
      expect(
        find.descendant(of: card, matching: find.text(page.ayah.translationBn)),
        findsOne,
      );
      for (final a in [...page.before, ...page.after]) {
        expect(
          find.text(a.translationBn, skipOffstage: false),
          findsOne,
          reason: 'context verse 54:${a.ayah}',
        );
      }
      expect(find.text(Strings.citingThisAyah, skipOffstage: false), findsOne);
      // Scoped to the ayah screen: home, beneath it, lists the same question.
      expect(
        find.descendant(
          of: find.byType(AyahScreen),
          matching: find.text(
            index.bySlug('muddakkir-al-qamar')!.questionBn,
            skipOffstage: false,
          ),
          skipOffstage: false,
        ),
        findsOne,
      );

      final nextButton = find.text(Strings.nextAyah, skipOffstage: false);
      await tester.ensureVisible(nextButton);
      await tester.pump();
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.descendant(
          of: find.byType(AyahCard),
          matching: find.text(next.ayah.translationBn),
        ),
        findsOne,
      );
    },
  );

  test('the first and last verses of the mushaf have one neighbour', () async {
    final first = (await container.read(
      ayahPageProvider((surah: 1, ayah: 1)).future,
    ))!;
    expect(first.previous, isNull);
    expect(first.next, (surah: 1, ayah: 2));

    final opening = (await container.read(
      ayahPageProvider((surah: 2, ayah: 1)).future,
    ))!;
    expect(opening.previous, (surah: 1, ayah: 7));

    final last = (await container.read(
      ayahPageProvider((surah: 114, ayah: 6)).future,
    ))!;
    expect(last.next, isNull);
    expect(last.before.map((a) => a.ayah), [4, 5]);
    expect(last.after, isEmpty);

    expect(
      await container.read(ayahPageProvider((surah: 1, ayah: 8)).future),
      isNull,
    );
  });

  testWidgets('settings change the theme and text size, and are kept', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await resolveHome();
      await container.read(previewAyahProvider.future);
    });

    await pumpApp(tester);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SettingsScreen), findsOne);

    await tester.tap(find.text(Strings.themeDark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    expect(prefs.getString('themeMode'), 'dark');

    await container.read(settingsProvider.notifier).setArabicScale(1.4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final arabic = tester.widget<Text>(
      find.descendant(
        of: find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(ArabicText),
        ),
        matching: find.byType(Text),
      ),
    );
    expect(arabic.style!.fontSize, closeTo(26 * 1.4, .001));
    expect(prefs.getDouble('arabicScale'), 1.4);
    // Reading text is untouched by the Arabic size.
    expect(
      AppText.of(tester.element(find.byType(SettingsScreen))).answer.fontSize,
      17,
    );
  });

  testWidgets('about credits the translation from the database', (
    tester,
  ) async {
    late Map<String, String> meta;
    await tester.runAsync(() async {
      await resolveHome();
      meta = await container.read(contentMetadataProvider.future);
    });

    await pumpApp(tester);
    await goTo(tester, '/about');
    expect(find.byType(AboutScreen), findsOne);
    expect(
      find.text('${meta['translationName']} · ${meta['translationAuthor']}'),
      findsOne,
    );
    expect(find.textContaining('SIL Open Font License'), findsNWidgets(3));

    await tester.ensureVisible(find.text(Strings.methodology));
    await tester.pump();
    await tester.tap(find.text(Strings.methodology));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(Strings.methodologyPoints.first), findsOne);
  });
}
