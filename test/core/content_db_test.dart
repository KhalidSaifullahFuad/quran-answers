import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/text/normalize.dart';

/// Exercises the built asset, not a fixture.
///
/// The point is the FTS index: `unicode61` decides token boundaries by Unicode
/// category, and whether Bengali survives that depends on the tokenchars option
/// rather than on anything the Dart code can assert about itself.
void main() {
  late ContentDatabase db;

  setUpAll(() {
    final file = File('assets/db/content.db');
    if (!file.existsSync()) {
      fail('assets/db/content.db missing - run: dart run tool/build_db.dart');
    }
    db = ContentDatabase(NativeDatabase(file));
  });

  tearDownAll(() => db.close());

  Future<List<QueryRow>> query(String sql, [List<Variable> vars = const []]) =>
      db.customSelect(sql, variables: vars).get();

  /// Runs an FTS match the way the app will: normalize, then quote the phrase.
  Future<List<QueryRow>> ftsAyahs(String userInput, String column) => query(
    'SELECT rowid FROM ${Fts.ayahs} '
    "WHERE ${Fts.ayahs} MATCH ? ORDER BY rowid",
    [Variable('$column : "${normalizeForSearch(userInput)}"')],
  );

  group('schema and contents', () {
    test('Drift opened the shipped file without migrating it', () async {
      final rows = await query('PRAGMA user_version');
      expect(rows.single.read<int>('user_version'), 1);
    });

    test('carries the whole mushaf', () async {
      final rows = await query('SELECT COUNT(*) AS c FROM ayahs');
      expect(rows.single.read<int>('c'), 6236);
      final surahs = await query('SELECT COUNT(*) AS c FROM surahs');
      expect(surahs.single.read<int>('c'), 114);
    });

    test('every published question was compiled, in author order', () async {
      final rows = await query(
        'SELECT slug FROM questions ORDER BY sort_order',
      );
      final slugs = rows.map((r) => r.read<String>('slug')).toList();
      expect(slugs, [
        'muddakkir-al-qamar',
        'naba-azeem',
        'haqqa-tilawatihi',
        'amana-ar-rasul',
        'hudna-ilayk',
      ]);
    });

    test('every citation resolves to a real ayah', () async {
      final orphans = await query(
        'SELECT qa.question_slug, qa.ayah_id FROM question_ayahs qa '
        'LEFT JOIN ayahs a ON a.id = qa.ayah_id WHERE a.id IS NULL',
      );
      expect(orphans, isEmpty);
    });

    test('no published question lacks a citation', () async {
      final bare = await query(
        'SELECT q.slug FROM questions q '
        'LEFT JOIN question_ayahs qa ON qa.question_slug = q.slug '
        'WHERE qa.question_slug IS NULL',
      );
      expect(bare, isEmpty);
    });

    test('ayah ids are the documented arithmetic', () async {
      final rows = await query(
        'SELECT id, surah, ayah FROM ayahs WHERE surah = 54 AND ayah = 15',
      );
      expect(rows.single.read<int>('id'), ayahId(54, 15));
      expect(surahOfAyahId(ayahId(54, 15)), 54);
      expect(ayahOfAyahId(ayahId(54, 15)), 15);
    });
  });

  group('Arabic full-text search', () {
    test('a bare query finds every occurrence of muddakkir', () async {
      final rows = await ftsAyahs('\u0645\u062F\u0643\u0631', 'search_ar');
      final ids = rows.map((r) => r.read<int>('rowid')).toList();
      expect(ids, [
        for (final a in [15, 17, 22, 32, 40, 51]) ayahId(54, a),
      ]);
    });

    test('hamza typed on an alef reaches the hamza-on-waw spelling', () async {
      // نبأ عظيم -> must reach 38:67
      final rows = await ftsAyahs(
        '\u0646\u0628\u0623 \u0639\u0638\u064A\u0645',
        'search_ar',
      );
      expect(rows.map((r) => r.read<int>('rowid')), contains(ayahId(38, 67)));
    });
  });

  group('Bengali full-text search', () {
    test(
      'a Bengali word is indexed whole, not split at its vowel signs',
      () async {
        // If the tokenizer treated matras as separators, কোন would be stored as
        // the fragments ক and ন, and this exact-phrase match would fail while a
        // search for the bare consonant would wrongly succeed.
        final whole = await query(
          'SELECT slug FROM ${Fts.questions} WHERE ${Fts.questions} MATCH ?',
          [
            Variable(
              'search_bn : "${normalizeForSearch('\u0995\u09CB\u09A8')}"',
            ),
          ],
        );
        expect(whole, isNotEmpty, reason: 'কোন not indexed as one token');

        final fragment = await query(
          'SELECT slug FROM ${Fts.questions} WHERE ${Fts.questions} MATCH ?',
          [Variable('search_bn : "\u0995"')],
        );
        expect(
          fragment,
          isEmpty,
          reason: 'bare ক matched, so words are being split at vowel signs',
        );
      },
    );

    test('finds a question by a distinctive Bengali word', () async {
      final rows = await query(
        'SELECT slug FROM ${Fts.questions} WHERE ${Fts.questions} MATCH ?',
        [Variable('search_bn : "${normalizeForSearch('মুদ্দাক্কির')}"')],
      );
      expect(rows.map((r) => r.read<String>('slug')), ['muddakkir-al-qamar']);
    });

    test(
      'an exact-token query misses suffixed forms of the same word',
      () async {
        // 54:15 renders the word with a suffix attached, so the bare token does
        // not match it. Bengali suffixes join directly onto the word, which is
        // why the search layer has to issue prefix queries rather than exact
        // ones. Asserted here so the behaviour is a decision, not a surprise.
        final exact = await ftsAyahs('নিদর্শন', 'search_bn');
        expect(
          exact,
          isNotEmpty,
          reason: 'the bare token does occur elsewhere',
        );
        expect(
          exact.map((r) => r.read<int>('rowid')),
          isNot(contains(ayahId(54, 15))),
        );
      },
    );

    test('a prefix query reaches suffixed forms', () async {
      final rows = await query(
        'SELECT rowid FROM ${Fts.ayahs} WHERE ${Fts.ayahs} MATCH ? '
        'ORDER BY rowid',
        [Variable('search_bn : "${normalizeForSearch('নিদর্শন')}" * ')],
      );
      expect(
        rows.map((r) => r.read<int>('rowid')),
        contains(ayahId(54, 15)),
        reason: 'prefix search must reach the suffixed form in 54:15',
      );
    });
  });
}
