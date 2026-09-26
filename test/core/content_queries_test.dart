import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/db/content_queries.dart';

/// Reads against the built database asset.
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

  test('categories come back in the authored order', () async {
    final rows = await db.allCategories();
    expect(rows.map((c) => c.id), ['words', 'quran-itself', 'worship']);
  });

  test(
    'allCitations groups ayah ids per question in the cited order',
    () async {
      final citations = await db.allCitations();
      expect(citations['muddakkir-al-qamar'], [
        for (final a in [15, 17, 22, 32, 40, 51]) ayahId(54, a),
      ]);
      expect(citations['naba-azeem'], [ayahId(78, 2), ayahId(38, 67)]);
      expect(citations.length, (await db.allQuestions()).length);
    },
  );

  test('a question detail resolves its ayat in the cited order', () async {
    final detail = await db.questionDetail('muddakkir-al-qamar');
    expect(detail, isNotNull);
    expect(
      detail!.ayahs.map((a) => a.ayah),
      [15, 17, 22, 32, 40, 51],
      reason: 'citation order is authored, not numeric by accident',
    );
    // The Arabic must arrive from the mushaf with its diacritics intact, not
    // from the question row: a stripped or normalized form here would mean the
    // display path is reading the search column.
    final marks = RegExp(r'[ً-ٟ]');
    expect(marks.hasMatch(detail.ayahs.first.textUthmani), isTrue);
    expect(detail.surahOf(detail.ayahs.first).number, 54);
    expect(detail.surahOf(detail.ayahs.first).nameBn, isNotEmpty);
  });

  test('a question citing two surahs labels each one', () async {
    final detail = await db.questionDetail('naba-azeem');
    expect(detail!.ayahs.map((a) => '${a.surah}:${a.ayah}'), ['78:2', '38:67']);
    expect(detail.surahs.keys.toSet(), {78, 38});
  });

  test('an unknown slug returns null rather than throwing', () async {
    expect(await db.questionDetail('not-a-question'), isNull);
  });

  test('questionsBySlugs preserves the order it was given', () async {
    final rows = await db.questionsBySlugs([
      'amana-ar-rasul',
      'muddakkir-al-qamar',
      'haqqa-tilawatihi',
    ]);
    expect(rows.map((q) => q.slug), [
      'amana-ar-rasul',
      'muddakkir-al-qamar',
      'haqqa-tilawatihi',
    ]);
  });

  test('questionsBySlugs drops slugs that no longer exist', () async {
    // A bookmark surviving a content update that removed its question.
    final rows = await db.questionsBySlugs(['removed-question', 'naba-azeem']);
    expect(rows.map((q) => q.slug), ['naba-azeem']);
  });

  test('questionsBySlugs on an empty list does not hit the database', () async {
    expect(await db.questionsBySlugs([]), isEmpty);
  });

  test('ayahWindow centres the verse and clamps to the surah', () async {
    final middle = await db.ayahWindow(54, 15);
    expect(middle.map((a) => a.ayah), [13, 14, 15, 16, 17]);

    // First verse of a surah: the window cannot reach into the previous one.
    final atStart = await db.ayahWindow(54, 1);
    expect(atStart.map((a) => a.ayah), [1, 2, 3]);
    expect(atStart.every((a) => a.surah == 54), isTrue);

    // Last verse of al-Qamar (55 ayat): must not spill into ar-Rahman.
    final atEnd = await db.ayahWindow(54, 55);
    expect(atEnd.map((a) => a.ayah), [53, 54, 55]);
    expect(atEnd.every((a) => a.surah == 54), isTrue);
  });

  test('questionsCiting finds the questions pointing at an ayah', () async {
    expect(
      (await db.questionsCiting(54, 15)).map((q) => q.slug),
      contains('muddakkir-al-qamar'),
    );
    expect(await db.questionsCiting(1, 1), isEmpty);
  });

  test('ayahAt returns the verse, or null outside the surah', () async {
    final ayah = await db.ayahAt(2, 285);
    expect(ayah!.translationBn, isNotEmpty);
    expect(ayah.id, ayahId(2, 285));
    // Al-Baqarah has 286 ayat.
    expect(await db.ayahAt(2, 287), isNull);
  });

  test('surah lookups carry Bengali and Arabic names', () async {
    final surah = await db.surah(54);
    expect(surah!.nameBn, isNotEmpty);
    expect(surah.nameAr, isNotEmpty);
    expect(surah.ayahCount, 55);
    expect((await db.allSurahs()).length, 114);
  });

  test('metadata records the translation credit', () async {
    final meta = await db.metadata();
    expect(meta['translationName'], 'Sheikh Mujibur Rahman');
    expect(meta['translationAuthor'], isNotEmpty);
    expect(meta['contentVersion'], '1');
    expect(meta['ayahCount'], '6236');
  });
}
