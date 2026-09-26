import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/app.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/db/content_search.dart';
import 'package:quran_answers/core/db/database_providers.dart';
import 'package:quran_answers/core/strings.dart';
import 'package:quran_answers/core/text/numerals.dart';
import 'package:quran_answers/features/questions/question_providers.dart';
import 'package:quran_answers/features/search/search_screen.dart';
import 'package:quran_answers/shared/ayah_card.dart';
import 'package:quran_answers/shared/navigation.dart';
import 'package:quran_answers/shared/widgets.dart';

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
  final today = DateTime(2026, 9, 23);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('app_test');
    container = ProviderContainer(
      overrides: [
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

  testWidgets('home lists every question and features one from the database', (
    tester,
  ) async {
    late QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
      await container.read(recentSlugsProvider.future);
      final featured = questionOfTheDay(index.questions, today)!;
      await container.read(questionDetailProvider(featured.slug).future);
    });
    expect(index.questions, hasLength(5));

    await pumpApp(tester);

    expect(find.text('QURAN ANSWERS'), findsOne);
    expect(find.text(bnDayMonth(today)), findsOne);
    for (final c in index.categories.values) {
      expect(find.text(c.nameBn), findsOne, reason: 'topic chip ${c.id}');
    }
    for (final q in index.questions) {
      expect(
        find.text(q.questionBn, skipOffstage: false),
        findsAtLeast(1),
        reason: 'row for ${q.slug}',
      );
    }
    // The featured card shows its first cited ayah as Qur'anic text, laid out
    // right to left.
    final arabic = tester.widget<Text>(
      find.descendant(of: find.byType(ArabicText), matching: find.byType(Text)),
    );
    expect(arabic.textDirection, TextDirection.rtl);
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
    // The list row, not the featured card, which may show the same question.
    final row = find.descendant(
      of: find.byType(QuestionTile),
      matching: find.text(question.questionBn, skipOffstage: false),
    );
    await tester.ensureVisible(row.first);
    await tester.pump();
    await tester.tap(row.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

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
    // Six citations in one surah: the position grid marks each of them.
    expect(find.text(bnDigits(51)), findsAtLeast(1));

    // Opening the question put it at the top of the reading history.
    final userDb = container.read(userDatabaseProvider).value!;
    await drain(
      tester,
      () async => (await userDb.recentSlugs()).firstOrNull == slug,
    );

    await unmount(tester);
  });

  testWidgets('the bottom bar switches between the four tabs', (tester) async {
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

    await openTab(AppTab.topics);
    for (final c in index.categories.values) {
      expect(find.text(c.nameBn), findsOne, reason: 'topic card ${c.id}');
    }

    await openTab(AppTab.surahs);
    expect(find.text(Strings.surahsTitle), findsOne);
    // 54 (Al-Qamar) is cited, so it is listed, badge in Bengali digits.
    expect(find.text(bnDigits(54)), findsOne);

    await openTab(AppTab.saved);
    expect(find.text(Strings.savedEmpty), findsOne);
    expect(find.text(Strings.historyEmpty), findsOne);
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
    await tester.tap(find.byType(SearchFieldButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

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
      expect(find.text(naba), findsOne);
      expect(find.byType(AyahCard), findsOne);
      expect(find.text(Strings.savedQuestions), findsOne);

      // Only the verse is in the folder.
      await tester.tap(find.text('ফোল্ডার ক'));
      await tester.pump();
      expect(find.text(naba), findsNothing);
      expect(find.byType(AyahCard), findsOne);
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
}
