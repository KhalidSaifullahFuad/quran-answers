import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/db/content_search.dart';

void main() {
  group('parseAyahRef', () {
    test('accepts ASCII, Bengali and Arabic-Indic digits', () {
      expect(parseAyahRef('54:15'), (surah: 54, ayah: 15));
      expect(parseAyahRef('৫৪:১৫'), (surah: 54, ayah: 15));
      expect(parseAyahRef('٥٤:١٥'), (surah: 54, ayah: 15));
    });

    test('accepts space, dot and the Bengali visarga as separators', () {
      expect(parseAyahRef(' 9 36 '), (surah: 9, ayah: 36));
      expect(parseAyahRef('9.36'), (surah: 9, ayah: 36));
      expect(parseAyahRef('৯ঃ৩৬'), (surah: 9, ayah: 36));
    });

    test('rejects text, a lone number and out-of-range surahs', () {
      expect(parseAyahRef('মুদ্দাক্কির'), isNull);
      expect(parseAyahRef('54'), isNull);
      expect(parseAyahRef('115:1'), isNull);
      expect(parseAyahRef('0:1'), isNull);
      expect(parseAyahRef('2:0'), isNull);
    });
  });

  group('ftsMatchExpression', () {
    test('quotes every word as a prefix and ANDs them', () {
      expect(ftsMatchExpression('  নিদর্শন   সহজ '), '"নিদর্শন"* "সহজ"*');
    });

    test('nothing left after normalization gives null', () {
      expect(ftsMatchExpression(''), isNull);
      expect(ftsMatchExpression(' ?! '), isNull);
    });

    test('FTS operators typed by the user stay literal', () {
      expect(ftsMatchExpression('NEAR OR *'), '"near"* "or"* "*"*');
    });

    test('a bare Arabic word also tries the article', () {
      expect(ftsMatchExpression('قمر'), '("قمر"* OR "القمر"*)');
      expect(ftsMatchExpression('القمر'), '"القمر"*');
    });
  });

  group('search against the built database', () {
    late ContentDatabase db;

    setUpAll(() {
      final file = File('assets/db/content.db');
      if (!file.existsSync()) {
        fail('assets/db/content.db missing - run: dart run tool/build_db.dart');
      }
      db = ContentDatabase(NativeDatabase(file));
    });

    tearDownAll(() => db.close());

    test(
      'a reference returns that verse and the questions citing it',
      () async {
        final r = await db.search('৫৪:১৫');
        expect(r.refAyah?.id, ayahId(54, 15));
        expect(r.citingRef.map((q) => q.slug), contains('muddakkir-al-qamar'));
        expect(r.surahs[54], isNotNull);
        expect(r.questions, isEmpty, reason: 'a reference skips full text');
      },
    );

    test('a reference past the end of the surah finds nothing', () async {
      final r = await db.search('1:8');
      expect(r.ref, (surah: 1, ayah: 8));
      expect(r.refAyah, isNull);
      expect(r.isEmpty, isTrue);
    });

    test('a Bengali word finds its question', () async {
      final r = await db.search('মুদ্দাক্কির');
      expect(r.questions.map((q) => q.slug), contains('muddakkir-al-qamar'));
    });

    test('a Bengali stem reaches the suffixed form in 54:15', () async {
      final r = await db.search('নিদর্শন');
      expect(r.ayahs.map((a) => a.id), contains(ayahId(54, 15)));
      expect(r.ayahTotal, greaterThanOrEqualTo(r.ayahs.length));
    });

    test('undiacritized Arabic finds the Uthmani verse', () async {
      final r = await db.search('مدكر');
      expect(r.ayahs.map((a) => a.id), contains(ayahId(54, 15)));
      expect(r.surahs[54], isNotNull);
    });

    test(
      'an Arabic word without the article reaches the one with it',
      () async {
        // 54:1 — اقتربت الساعة وانشق القمر.
        final r = await db.search('قمر');
        expect(r.ayahs.map((a) => a.id), contains(ayahId(54, 1)));
      },
    );

    test('verse results are capped but the total is not', () async {
      final r = await db.search('الله', ayahLimit: 10);
      expect(r.ayahs, hasLength(10));
      expect(r.ayahTotal, greaterThan(10));
    });

    test('text matching nothing is empty rather than an error', () async {
      final r = await db.search('zzzzqqq');
      expect(r.isEmpty, isTrue);
    });

    test('stray symbols never reach FTS as syntax', () async {
      // Each becomes a quoted phrase with no tokens in it; SQLite must accept
      // that rather than raise a syntax error while the user is typing.
      for (final input in ['*', ':', '^', '#', 'AND', 'NOT', "'", '+']) {
        expect((await db.search(input)).isEmpty, isTrue, reason: input);
      }
    });
  });
}
