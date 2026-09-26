// Compiles content/questions.json + content/quran.json into the read-only
// database the app ships as an asset.
//
//   dart run tool/build_db.dart
//
// JSON is the reviewable source of truth; this file is the build artifact. Both
// are committed, but only the JSON is ever edited by hand.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:drift/native.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/text/normalize.dart';

import 'content_source.dart';

const outputPath = 'assets/db/content.db';

Future<void> main() async {
  final questions = Questions.load();
  final mushaf = Mushaf.load();

  final errors = validate(questions, mushaf);
  if (errors.isNotEmpty) {
    stderr.writeln('Refusing to build, ${errors.length} problem(s):');
    for (final e in errors) {
      stderr.writeln('  $e');
    }
    exitCode = 1;
    return;
  }

  final file = File(outputPath);
  await file.parent.create(recursive: true);
  if (file.existsSync()) file.deleteSync();

  // Opening a fresh file lets Drift create the schema and stamp user_version,
  // so the app opens the shipped database without trying to migrate it.
  final db = ContentDatabase(NativeDatabase(file));

  await db.batch((b) {
    b.insertAll(db.surahs, [
      for (final s in mushaf.surahs)
        Surah(
          number: s['number'] as int,
          nameAr: s['nameAr'] as String,
          nameBn: s['nameBn'] as String,
          nameEn: s['nameEn'] as String,
          ayahCount: s['ayahCount'] as int,
          revelationPlace: s['revelationPlace'] as String,
        ),
    ]);
  });

  final ayahRows = <Ayah>[];
  for (final entry in mushaf.ayahs.values) {
    final surah = entry['surah'] as int;
    final ayah = entry['ayah'] as int;
    final uthmani = entry['textUthmani'] as String;
    final translation = entry['translationBn'] as String;
    ayahRows.add(
      Ayah(
        id: ayahId(surah, ayah),
        surah: surah,
        ayah: ayah,
        textUthmani: uthmani,
        textPlain: entry['textPlain'] as String,
        translationBn: translation,
        searchAr: normalizeForSearch(uthmani),
        searchBn: normalizeForSearch(translation),
      ),
    );
  }
  await db.batch((b) => b.insertAll(db.ayahs, ayahRows));

  await db.batch((b) {
    b.insertAll(db.categories, [
      for (final c in questions.categories)
        Category(
          id: c['id'] as String,
          nameBn: c['nameBn'] as String,
          nameEn: c['nameEn'] as String,
          sortOrder: c['sortOrder'] as int,
        ),
    ]);
  });

  final published = questions.published;
  await db.batch((b) {
    b.insertAll(db.questions, [
      for (final q in published)
        Question(
          slug: q['slug'] as String,
          questionBn: q['questionBn'] as String,
          answerBn: q['answerBn'] as String,
          category: q['category'] as String,
          searchBn: normalizeForSearch('${q['questionBn']} ${q['answerBn']}'),
          sortOrder: q['sortOrder'] as int,
        ),
    ]);
  });

  final links = <QuestionAyah>[];
  for (final q in published) {
    final refs = (q['refs'] as List).cast<String>();
    for (final (i, ref) in refs.indexed) {
      final parsed = parseRef(ref)!;
      links.add(
        QuestionAyah(
          questionSlug: q['slug'] as String,
          ayahId: ayahId(parsed.surah, parsed.ayah),
          sortOrder: i,
        ),
      );
    }
  }
  await db.batch((b) => b.insertAll(db.questionAyahs, links));

  await db.batch((b) {
    b.insertAll(db.meta, [
      MetaEntry(key: 'contentVersion', value: '${questions.contentVersion}'),
      MetaEntry(key: 'translationName', value: mushaf.translationName),
      MetaEntry(key: 'translationAuthor', value: mushaf.translationAuthor),
      MetaEntry(key: 'ayahCount', value: '${ayahRows.length}'),
      MetaEntry(key: 'questionCount', value: '${published.length}'),
      MetaEntry(
        key: 'builtAt',
        value: DateTime.now().toUtc().toIso8601String(),
      ),
    ]);
  });

  for (final statement in createFtsStatements) {
    await db.customStatement(statement);
  }
  await db.customStatement(
    'INSERT INTO ${Fts.ayahs}(rowid, search_ar, search_bn) '
    'SELECT id, search_ar, search_bn FROM ayahs',
  );
  await db.customStatement(
    'INSERT INTO ${Fts.questions}(slug, search_bn) '
    'SELECT slug, search_bn FROM questions',
  );

  // Compacts the file and rebuilds the b-trees; the asset is written once and
  // only ever read, so the tradeoff is entirely in the app's favour.
  await db.customStatement('VACUUM');
  await db.close();

  // A fingerprint of the finished file, written beside it as a tiny asset.
  //
  // The app copies the database out of its bundle on first launch and has no
  // way to tell a new bundled database from the copy it already made. Comparing
  // this marker is that signal. It is a digest of the content rather than a
  // build timestamp, so rebuilding unchanged content does not force every
  // installed app to rewrite 10 MB after an unrelated release.
  final digest = sha256.convert(file.readAsBytesSync());
  final marker = File('$outputPath.version');
  marker.writeAsStringSync('''
contentVersion=${questions.contentVersion}
schemaVersion=${db.schemaVersion}
sha256=$digest
''', encoding: utf8);

  final kb = file.lengthSync() / 1024;
  stdout.writeln(
    'Wrote $outputPath: ${mushaf.surahs.length} surahs, '
    '${ayahRows.length} ayat, ${published.length} questions, '
    '${links.length} citations, ${(kb / 1024).toStringAsFixed(1)} MB.',
  );
  stdout.writeln(
    'Wrote ${marker.path}: sha256 ${digest.toString().substring(0, 16)}...',
  );
}
