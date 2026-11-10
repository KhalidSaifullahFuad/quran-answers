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

  group('parseSurahNumber', () {
    test('a lone number in range is a surah', () {
      expect(parseSurahNumber('৩৬'), 36);
      expect(parseSurahNumber(' 114 '), 114);
      expect(parseSurahNumber('115'), isNull);
      expect(parseSurahNumber('0'), isNull);
      expect(parseSurahNumber('2:255'), isNull);
    });
  });

  group('SearchTerms.hits', () {
    test('marks prefixed, loosely spelled and synonym words', () {
      final t = SearchTerms.parse('নুহ নামাজ')!;
      expect(t.hits('নূহের'), isTrue, reason: 'loose ূ / ু, suffix');
      expect(t.hits('সালাত,'), isTrue, reason: 'synonym, punctuation');
      expect(t.hits('মালাইকা/নূহ'), isTrue, reason: 'split at the slash');
      expect(t.hits('পথ'), isFalse);
    });

    test('a short word takes suffixes but is not a prefix', () {
      final t = SearchTerms.parse('বার মাস')!;
      expect(t.hits('মাস'), isTrue);
      expect(t.hits('বারটি।'), isTrue, reason: 'classifier suffix');
      expect(t.hits('মাসের'), isTrue);
      expect(t.hits('মাসজিদুল'), isFalse);
      expect(t.hits('বারাকাতময়'), isFalse);
      expect(t.hits('বাড়ী'), isFalse, reason: 'loose ড় as র is not a prefix');
    });
  });

  group('ftsMatchExpression', () {
    test('quotes every word as a prefix and ANDs them', () {
      // নিদর্শন also goes in loose form: hasanta dropped, শ as স.
      expect(
        ftsMatchExpression('  নিদর্শন   উপদেশ '),
        '("নিদর্শন"* OR "নিদরসন"*) AND ("উপদেশ"* OR "উপদেস"*)',
      );
    });

    test('ORs the words when asked to', () {
      expect(
        ftsMatchExpression('কিতাব উম্মাত', any: true),
        '"কিতাব"* OR ("উম্মাত"* OR "উমমাত"*)',
      );
    });

    test('one-letter words are dropped', () {
      expect(ftsMatchExpression('ক কিতাব'), '"কিতাব"*');
      expect(ftsMatchExpression('ক'), isNull);
      expect(SearchTerms.tooShort('ক'), isTrue);
      expect(SearchTerms.tooShort(' ?! '), isFalse);
    });

    test('a word brings its synonyms', () {
      final e = ftsMatchExpression('নামাজ')!;
      expect(e, contains('"সালাত"*'));
      expect(e, contains('"নামায"*'));
    });

    test('nothing left after normalization gives null', () {
      expect(ftsMatchExpression(''), isNull);
      expect(ftsMatchExpression(' ?! '), isNull);
    });

    test('FTS operators typed by the user stay literal', () {
      expect(ftsMatchExpression('NEAR OR "x*"'), '"near"* AND "or"* AND "x*"*');
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
      // Past the first page: whole-word hits rank above suffixed ones.
      final r = await db.search('নিদর্শন', ayahLimit: 1000);
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

    test('the plain Arabic spelling reaches the Uthmani verse', () async {
      // 2:2 — ذلك الكتاب, written ٱلْكِتَـٰبُ in Uthmani rasm.
      final r = await db.search('الكتاب');
      expect(r.ayahs.map((a) => a.id), contains(ayahId(2, 2)));
    });

    test('a loose Bengali spelling finds the standard one', () async {
      final strict = await db.search('নূহ');
      final loose = await db.search('নুহ');
      expect(strict.ayahTotal, greaterThan(0));
      expect(loose.ayahTotal, greaterThanOrEqualTo(strict.ayahTotal));
    });

    test("an everyday word finds the translation's term", () async {
      final r = await db.search('নামাজ');
      expect(r.ayahTotal, greaterThan(50), reason: 'সালাত is used 87 times');
    });

    test('a loose spelling also reaches the common one', () async {
      // The translation writes মূসা 176 times and মুসা 5 times.
      final r = await db.search('মুসা');
      expect(r.ayahTotal, greaterThan(100));
    });

    test('short words match whole, and whole matches rank first', () async {
      final r = await db.search('বার মাস');
      expect(r.questions.first.slug, 'ku-040');
      expect(r.ayahs.first.id, ayahId(9, 36));
      final ids = r.ayahs.map((a) => a.id);
      expect(ids, isNot(contains(ayahId(17, 1))), reason: 'মাসজিদুল');
      expect(ids, isNot(contains(ayahId(22, 40))), reason: 'বাড়ী');
    });

    test('a title hit ranks above an answer hit', () async {
      final r = await db.search('মুদ্দাক্কির');
      expect(r.questions.first.slug, 'muddakkir-al-qamar');
    });

    test('a surah number opens the surah', () async {
      final r = await db.search('৩৬');
      expect(r.matchedSurahs.map((s) => s.number), [36]);
      expect(r.ayahs, isEmpty);
    });

    test('a surah name is matched, with or without the article', () async {
      for (final q in ['Al-Qamar', 'qamar', 'সূরা চাঁদ']) {
        final r = await db.search(q);
        expect(r.matchedSurahs.map((s) => s.number), contains(54), reason: q);
      }
    });

    test('a surah name and a number go to the verse', () async {
      final r = await db.search('baqarah ২৫৫');
      expect(r.refAyah?.id, ayahId(2, 255));
    });

    test('no verse has every word, so any word is enough', () async {
      final r = await db.search('নূহ zzzzqqq');
      expect(r.relaxed, isTrue);
      expect(r.ayahs, isNotEmpty);
    });

    test('a one-letter query is not searched', () async {
      final r = await db.search('ক');
      expect(r.tooShort, isTrue);
      expect(r.isEmpty, isTrue);
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
